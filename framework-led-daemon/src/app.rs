use crate::config;
use crate::config::{RegionName, WidgetKind};
use crate::device::{MatrixPair, MatrixPaths};
use crate::notify::{self, Event};
use crate::render::{AppState, PowerMode, Preview, pulse_until, render_pair, target_brightness};
use crate::sys::SystemSampler;
use anyhow::{Context, Result};
use clap::Args;
use std::path::PathBuf;
use std::sync::mpsc;
use std::time::{Duration, Instant};
use tracing::{info, warn};

#[derive(Debug, Clone, Args)]
pub struct RunArgs {
    /// Config file path. Defaults to ~/.config/framework-led-daemon/config.toml.
    #[arg(long)]
    pub config: Option<PathBuf>,
    /// Print mock frame summaries instead of opening serial devices.
    #[arg(long)]
    pub mock: bool,
    /// Render one frame and exit. Useful for smoke tests.
    #[arg(long)]
    pub once: bool,
    /// Temporarily render a single widget in one region without editing config.
    #[arg(long, value_enum)]
    pub preview_widget: Option<WidgetKind>,
    /// Region used with --preview-widget.
    #[arg(long, value_enum, default_value = "bottom-right")]
    pub preview_region: RegionName,
}

impl Default for RunArgs {
    fn default() -> Self {
        Self {
            config: None,
            mock: false,
            once: false,
            preview_widget: None,
            preview_region: RegionName::BottomRight,
        }
    }
}

pub fn run(args: RunArgs) -> Result<()> {
    let (mut cfg, cfg_path, cfg_exists) = config::load(args.config.as_deref())?;
    if args.mock {
        cfg.display.mock = true;
    }

    if cfg_exists {
        info!("loaded config {}", cfg_path.display());
    } else {
        info!(
            "config {} does not exist; using defaults. Run `framework-led-daemon doctor --write-default-config` to create it.",
            cfg_path.display()
        );
    }

    let paths = MatrixPaths::resolve(cfg.devices.left.clone(), cfg.devices.right.clone())?;
    let mut matrices = MatrixPair::open(paths, cfg.display.mock, cfg.devices.swap)?;
    matrices.set_sleeping(false)?;
    let (tx, rx) = mpsc::channel::<Event>();
    let (shutdown_tx, shutdown_rx) = mpsc::channel::<()>();

    notify::spawn_manual_listener(tx.clone())?;
    notify::spawn_swaync_watcher(
        tx.clone(),
        cfg.notifications.swaync_client.clone(),
        cfg.notifications.poll_seconds,
    );
    if cfg.tmux.enabled {
        crate::tmux::spawn_watcher(tx.clone(), cfg.tmux.poll_millis);
    }
    if cfg.audio.enabled {
        crate::audio::spawn_cava(tx.clone(), cfg.audio.cava.clone());
    }

    ctrlc::set_handler(move || {
        let _ = shutdown_tx.send(());
    })
    .context("installing ctrl-c handler")?;

    let mut sampler = SystemSampler::default();
    let mut state = AppState::default();
    let preview = args.preview_widget.map(|widget| Preview {
        region: args.preview_region,
        widget,
    });
    let mut last_brightness = None;
    let mut was_sleeping = false;
    let frame_interval = Duration::from_millis((1000 / cfg.display.fps.max(1)).max(50));

    loop {
        if shutdown_rx.try_recv().is_ok() {
            info!("shutting down, clearing, and sleeping matrices");
            let _ = matrices.clear();
            let _ = matrices.set_sleeping(true);
            break;
        }

        state.system = sampler.sample();
        drain_events(&rx, &mut state, &cfg);
        seed_preview_state(preview, &cfg, &mut state);

        let (left, right, power_mode) =
            render_pair(&state, &cfg.battery, &cfg.layout, &cfg.animations, preview);
        match power_mode {
            PowerMode::Off => {
                if !was_sleeping {
                    matrices.set_sleeping(true)?;
                    was_sleeping = true;
                }
            }
            PowerMode::Normal | PowerMode::LowBattery => {
                if was_sleeping {
                    matrices.set_sleeping(false)?;
                    was_sleeping = false;
                }
                let brightness = target_brightness(&state, &cfg.display);
                if last_brightness != Some(brightness) {
                    matrices.set_brightness(brightness)?;
                    last_brightness = Some(brightness);
                }
                if let Err(err) = matrices.draw(&left, &right) {
                    warn!("draw failed: {err}");
                }
            }
        }

        if args.once {
            break;
        }
        std::thread::sleep(frame_interval);
    }

    Ok(())
}

fn seed_preview_state(preview: Option<Preview>, cfg: &config::Config, state: &mut AppState) {
    let Some(preview) = preview else {
        return;
    };
    seed_widget_state(preview.widget, cfg, state);
}

fn seed_widget_state(widget: WidgetKind, cfg: &config::Config, state: &mut AppState) {
    match widget {
        WidgetKind::Bell
        | WidgetKind::BellOrBars
        | WidgetKind::BellOrPenguin
        | WidgetKind::PenguinOnNotify => {
            state.notification_pulse_until = Some(pulse_until(Duration::from_millis(
                cfg.notifications.pulse_millis,
            )));
        }
        WidgetKind::AudioBars
        | WidgetKind::AudioWave
        | WidgetKind::AudioMirror
        | WidgetKind::NegativeBars
        | WidgetKind::DynamicStatus => {
            state.audio_bars = [1, 3, 5, 7, 9, 7, 5, 3, 1];
            state.audio_active_until = Some(Instant::now() + Duration::from_millis(2000));
        }
        WidgetKind::Penguin
        | WidgetKind::Blank
        | WidgetKind::Cpu
        | WidgetKind::Ram
        | WidgetKind::Bat => {}
    }
}

fn drain_events(rx: &mpsc::Receiver<Event>, state: &mut AppState, cfg: &config::Config) {
    while let Ok(event) = rx.try_recv() {
        match event {
            Event::NotificationCount(count) => state.notifications = count,
            Event::NotificationPulse => {
                state.notification_pulse_until = Some(pulse_until(Duration::from_millis(
                    cfg.notifications.pulse_millis,
                )));
            }
            Event::CodexPulse => {
                state.codex_pulse_until = Some(pulse_until(Duration::from_millis(
                    cfg.tmux.codex_pulse_millis,
                )));
            }
            Event::AudioBars(bars) => {
                state.audio_bars = bars;
                if bars.iter().any(|v| *v > 0) {
                    state.audio_active_until =
                        Some(Instant::now() + Duration::from_millis(cfg.audio.active_decay_millis));
                }
            }
        }
    }
}

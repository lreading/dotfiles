use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};

pub const APP_NAME: &str = "framework-led-daemon";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct Config {
    pub devices: DeviceConfig,
    pub display: DisplayConfig,
    pub layout: LayoutConfig,
    pub animations: AnimationConfig,
    pub battery: BatteryConfig,
    pub notifications: NotificationConfig,
    pub tmux: TmuxConfig,
    pub audio: AudioConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct DeviceConfig {
    pub left: Option<PathBuf>,
    pub right: Option<PathBuf>,
    pub swap: bool,
}

impl Default for DeviceConfig {
    fn default() -> Self {
        Self {
            left: None,
            right: None,
            swap: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct DisplayConfig {
    pub fps: u64,
    pub min_brightness: u8,
    pub max_brightness: u8,
    pub screen_brightness_scale_percent: u8,
    pub battery_dim_percent: u8,
    pub alert_brightness_boost: u8,
    pub mock: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct LayoutConfig {
    pub top_left: WidgetKind,
    pub bottom_left: WidgetKind,
    pub full_left: Option<WidgetKind>,
    pub top_right: WidgetKind,
    pub bottom_right: WidgetKind,
    pub full_right: Option<WidgetKind>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, clap::ValueEnum)]
#[value(rename_all = "kebab-case")]
#[serde(rename_all = "kebab-case")]
pub enum WidgetKind {
    Blank,
    Cpu,
    Ram,
    Bat,
    Bell,
    AudioBars,
    AudioWave,
    AudioMirror,
    NegativeBars,
    Penguin,
    PenguinOnNotify,
    BellOrBars,
    BellOrPenguin,
    DynamicStatus,
}

impl Default for WidgetKind {
    fn default() -> Self {
        Self::Blank
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
#[value(rename_all = "kebab-case")]
pub enum RegionName {
    TopLeft,
    BottomLeft,
    FullLeft,
    TopRight,
    BottomRight,
    FullRight,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct BatteryConfig {
    pub low_battery_percent: u8,
    pub off_battery_percent: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct AnimationConfig {
    pub penguin: PenguinAnimation,
    pub notification: NotificationAnimation,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, clap::ValueEnum)]
#[value(rename_all = "kebab-case")]
#[serde(rename_all = "kebab-case")]
pub enum PenguinAnimation {
    Reference,
    Waddle,
    Chubby,
    Tiny,
    Flipper,
    Skater,
    Jumper,
    Party,
    Sleepy,
    SideEye,
    Round,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, clap::ValueEnum)]
#[value(rename_all = "kebab-case")]
#[serde(rename_all = "kebab-case")]
pub enum NotificationAnimation {
    BellFlash,
    Spark,
    Ping,
    Ring,
    Badge,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct NotificationConfig {
    pub swaync_client: String,
    pub poll_seconds: u64,
    pub pulse_millis: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct TmuxConfig {
    pub enabled: bool,
    pub poll_millis: u64,
    pub codex_pulse_millis: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct AudioConfig {
    pub enabled: bool,
    pub cava: String,
    pub active_decay_millis: u64,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            devices: DeviceConfig::default(),
            display: DisplayConfig::default(),
            layout: LayoutConfig::default(),
            animations: AnimationConfig::default(),
            battery: BatteryConfig::default(),
            notifications: NotificationConfig::default(),
            tmux: TmuxConfig::default(),
            audio: AudioConfig::default(),
        }
    }
}

impl Default for DisplayConfig {
    fn default() -> Self {
        Self {
            fps: 5,
            min_brightness: 4,
            max_brightness: 42,
            screen_brightness_scale_percent: 45,
            battery_dim_percent: 70,
            alert_brightness_boost: 10,
            mock: false,
        }
    }
}

impl Default for LayoutConfig {
    fn default() -> Self {
        Self {
            top_left: WidgetKind::Cpu,
            bottom_left: WidgetKind::Ram,
            full_left: None,
            top_right: WidgetKind::Bat,
            bottom_right: WidgetKind::PenguinOnNotify,
            full_right: None,
        }
    }
}

impl Default for AnimationConfig {
    fn default() -> Self {
        Self {
            penguin: PenguinAnimation::Reference,
            notification: NotificationAnimation::BellFlash,
        }
    }
}

impl Default for PenguinAnimation {
    fn default() -> Self {
        Self::Reference
    }
}

impl Default for NotificationAnimation {
    fn default() -> Self {
        Self::BellFlash
    }
}

impl Default for BatteryConfig {
    fn default() -> Self {
        Self {
            low_battery_percent: 35,
            off_battery_percent: 20,
        }
    }
}

impl Default for NotificationConfig {
    fn default() -> Self {
        Self {
            swaync_client: "swaync-client".to_string(),
            poll_seconds: 5,
            pulse_millis: 5000,
        }
    }
}

impl Default for TmuxConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            poll_millis: 1500,
            codex_pulse_millis: 4500,
        }
    }
}

impl Default for AudioConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            cava: "cava".to_string(),
            active_decay_millis: 1200,
        }
    }
}

pub fn default_config_path() -> PathBuf {
    dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(APP_NAME)
        .join("config.toml")
}

pub fn load(path: Option<&Path>) -> Result<(Config, PathBuf, bool)> {
    let path = path.map(PathBuf::from).unwrap_or_else(default_config_path);
    if !path.exists() {
        return Ok((Config::default(), path, false));
    }
    let text = fs::read_to_string(&path).with_context(|| format!("reading {}", path.display()))?;
    let cfg = toml::from_str(&text).with_context(|| format!("parsing {}", path.display()))?;
    Ok((cfg, path, true))
}

pub fn write_config(path: &Path, cfg: &Config) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).with_context(|| format!("creating {}", parent.display()))?;
    }
    let text = toml::to_string_pretty(cfg)?;
    fs::write(path, text).with_context(|| format!("writing {}", path.display()))?;
    Ok(())
}

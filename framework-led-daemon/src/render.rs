use crate::config::{
    AnimationConfig, BatteryConfig, DisplayConfig, LayoutConfig, NotificationAnimation,
    PenguinAnimation, RegionName, WidgetKind,
};
use crate::font::{draw_tight_text, draw_vertical_text};
use crate::frame::{Frame, HEIGHT, WIDTH};
use crate::sys::{ChargeState, SystemSnapshot};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone)]
pub struct AppState {
    pub system: SystemSnapshot,
    pub notifications: u32,
    pub notification_pulse_until: Option<Instant>,
    pub codex_pulse_until: Option<Instant>,
    pub audio_bars: [u8; WIDTH],
    pub audio_active_until: Option<Instant>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            system: SystemSnapshot::default(),
            notifications: 0,
            notification_pulse_until: None,
            codex_pulse_until: None,
            audio_bars: [0; WIDTH],
            audio_active_until: None,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PowerMode {
    Normal,
    LowBattery,
    Off,
}

pub fn power_mode(system: &SystemSnapshot, battery: &BatteryConfig) -> PowerMode {
    let Some(percent) = system.battery_percent else {
        return PowerMode::Normal;
    };
    if !system.charge_state.is_discharging() {
        return PowerMode::Normal;
    }
    if percent < battery.off_battery_percent {
        PowerMode::Off
    } else if percent <= battery.low_battery_percent {
        PowerMode::LowBattery
    } else {
        PowerMode::Normal
    }
}

pub fn target_brightness(state: &AppState, display: &DisplayConfig) -> u8 {
    let screen = state
        .system
        .backlight_percent
        .unwrap_or(display.max_brightness)
        .min(100);
    let mut brightness = ((screen as u16 * display.screen_brightness_scale_percent as u16) / 100)
        .min(u8::MAX as u16) as u8;

    if state.system.charge_state == ChargeState::Discharging {
        brightness = ((brightness as u16 * display.battery_dim_percent as u16) / 100) as u8;
    }

    let now = Instant::now();
    if state
        .notification_pulse_until
        .is_some_and(|until| until > now)
        || state.codex_pulse_until.is_some_and(|until| until > now)
    {
        brightness = brightness.saturating_add(display.alert_brightness_boost);
    }

    brightness.clamp(display.min_brightness, display.max_brightness)
}

#[derive(Debug, Clone, Copy)]
pub struct Preview {
    pub region: RegionName,
    pub widget: WidgetKind,
}

pub fn render_pair(
    state: &AppState,
    battery: &BatteryConfig,
    layout: &LayoutConfig,
    animations: &AnimationConfig,
    preview: Option<Preview>,
) -> (Frame, Frame, PowerMode) {
    match power_mode(&state.system, battery) {
        PowerMode::Off => (Frame::new(), Frame::new(), PowerMode::Off),
        PowerMode::LowBattery => {
            let left = render_left(state, layout, animations, preview);
            let mut right = Frame::new();
            draw_vertical_text(&mut right, 0, 0, "LOW", 220);
            draw_vertical_text(&mut right, 5, 0, "BAT", 220);
            (left, right, PowerMode::LowBattery)
        }
        PowerMode::Normal => (
            render_left(state, layout, animations, preview),
            render_right(state, layout, animations, preview),
            PowerMode::Normal,
        ),
    }
}

fn render_left(
    state: &AppState,
    layout: &LayoutConfig,
    animations: &AnimationConfig,
    preview: Option<Preview>,
) -> Frame {
    let mut frame = Frame::new();
    if let Some(widget) = preview_widget(preview, RegionName::FullLeft).or(layout.full_left) {
        draw_widget(
            &mut frame,
            region(RegionName::FullLeft),
            widget,
            state,
            animations,
        );
        return frame;
    }
    draw_widget(
        &mut frame,
        region(RegionName::TopLeft),
        preview_widget(preview, RegionName::TopLeft).unwrap_or(layout.top_left),
        state,
        animations,
    );
    draw_widget(
        &mut frame,
        region(RegionName::BottomLeft),
        preview_widget(preview, RegionName::BottomLeft).unwrap_or(layout.bottom_left),
        state,
        animations,
    );
    frame
}

fn render_right(
    state: &AppState,
    layout: &LayoutConfig,
    animations: &AnimationConfig,
    preview: Option<Preview>,
) -> Frame {
    let mut frame = Frame::new();
    if let Some(widget) = preview_widget(preview, RegionName::FullRight).or(layout.full_right) {
        draw_widget(
            &mut frame,
            region(RegionName::FullRight),
            widget,
            state,
            animations,
        );
        return frame;
    }
    draw_widget(
        &mut frame,
        region(RegionName::TopRight),
        preview_widget(preview, RegionName::TopRight).unwrap_or(layout.top_right),
        state,
        animations,
    );
    draw_widget(
        &mut frame,
        region(RegionName::BottomRight),
        preview_widget(preview, RegionName::BottomRight).unwrap_or(layout.bottom_right),
        state,
        animations,
    );
    frame
}

fn preview_widget(preview: Option<Preview>, region: RegionName) -> Option<WidgetKind> {
    preview.and_then(|p| (p.region == region).then_some(p.widget))
}

#[derive(Debug, Clone, Copy)]
struct Region {
    y: usize,
    h: usize,
}

fn region(name: RegionName) -> Region {
    match name {
        RegionName::TopLeft | RegionName::TopRight => Region { y: 0, h: 17 },
        RegionName::BottomLeft | RegionName::BottomRight => Region { y: 17, h: 17 },
        RegionName::FullLeft | RegionName::FullRight => Region { y: 0, h: HEIGHT },
    }
}

fn draw_widget(
    frame: &mut Frame,
    region: Region,
    widget: WidgetKind,
    state: &AppState,
    animations: &AnimationConfig,
) {
    match widget {
        WidgetKind::Blank => {}
        WidgetKind::Cpu => percent_block(frame, region, "CPU", Some(state.system.cpu_percent), 210),
        WidgetKind::Ram => {
            percent_block(frame, region, "RAM", Some(state.system.memory_percent), 190)
        }
        WidgetKind::Bat => percent_block(frame, region, "BAT", state.system.battery_percent, 170),
        WidgetKind::AudioBars => draw_audio_bars(frame, region, &state.audio_bars, 190),
        WidgetKind::AudioWave => draw_audio_wave(frame, region, &state.audio_bars, 190),
        WidgetKind::AudioMirror => draw_audio_mirror(frame, region, &state.audio_bars, 190),
        WidgetKind::NegativeBars => draw_negative_bars(frame, region, &state.audio_bars, 170),
        WidgetKind::Penguin => draw_penguin(frame, region, animations.penguin, 190),
        WidgetKind::PenguinOnNotify => {
            if is_pulsing(state) {
                draw_penguin(frame, region, animations.penguin, 220);
            }
        }
        WidgetKind::Bell => draw_notification(frame, region, animations.notification, 210),
        WidgetKind::BellOrBars => {
            if is_pulsing(state) {
                draw_notification(frame, region, animations.notification, 220);
            } else {
                draw_audio_bars(frame, region, &state.audio_bars, 170);
            }
        }
        WidgetKind::BellOrPenguin => {
            if is_pulsing(state) {
                draw_notification(frame, region, animations.notification, 220);
            } else {
                draw_penguin(frame, region, animations.penguin, 170);
            }
        }
        WidgetKind::DynamicStatus => {
            if is_pulsing(state) {
                draw_notification(frame, region, animations.notification, 220);
            } else if is_audio_active(state) {
                draw_audio_bars(frame, region, &state.audio_bars, 180);
            } else {
                draw_penguin(frame, region, animations.penguin, 170);
            }
        }
    }
}

fn percent_block(frame: &mut Frame, region: Region, label: &str, percent: Option<u8>, value: u8) {
    let y = region.y + if region.h >= 17 { 1 } else { 0 };
    draw_tight_text(frame, 0, y, label, value);
    frame.fill_rect(0, y + 6, WIDTH, 1, value);
    let text = percent_text(percent);
    let x = if text.len() >= 3 { 0 } else { 1 };
    draw_tight_text(frame, x, y + 8, &text, value);
}

fn percent_text(percent: Option<u8>) -> String {
    match percent {
        Some(value) if value >= 100 => "100".to_string(),
        Some(value) => format!("{value:02}"),
        None => "---".to_string(),
    }
}

fn is_pulsing(state: &AppState) -> bool {
    let now = Instant::now();
    state
        .notification_pulse_until
        .is_some_and(|until| until > now)
        || state.codex_pulse_until.is_some_and(|until| until > now)
}

fn is_audio_active(state: &AppState) -> bool {
    state
        .audio_active_until
        .is_some_and(|until| until > Instant::now())
}

fn audio_level(value: u8, max_h: usize) -> usize {
    ((value.min(9) as usize * max_h) + 8) / 9
}

fn draw_audio_bars(frame: &mut Frame, region: Region, bars: &[u8; WIDTH], value: u8) {
    let baseline = region.y + region.h - 1;
    frame.fill_rect(0, baseline, WIDTH, 1, 35);
    for (x, raw) in bars.iter().enumerate() {
        let h = audio_level(*raw, region.h.saturating_sub(1));
        if h > 0 {
            frame.fill_rect(x, baseline + 1 - h, 1, h, value);
        }
    }
}

fn draw_audio_wave(frame: &mut Frame, region: Region, bars: &[u8; WIDTH], value: u8) {
    let mid = region.y + region.h / 2;
    for x in 0..WIDTH {
        frame.set(x, mid, 35);
        let y = region.y + region.h - 1 - audio_level(bars[x], region.h - 1);
        frame.set(x, y, value);
        if x > 0 {
            let prev = region.y + region.h - 1 - audio_level(bars[x - 1], region.h - 1);
            let start = prev.min(y);
            let end = prev.max(y);
            for py in start..=end {
                frame.set(x, py, value.saturating_sub(35));
            }
        }
    }
}

fn draw_audio_mirror(frame: &mut Frame, region: Region, bars: &[u8; WIDTH], value: u8) {
    let mid = region.y + region.h / 2;
    for (x, raw) in bars.iter().enumerate() {
        let h = audio_level(*raw, region.h / 2);
        frame.set(x, mid, 45);
        for offset in 0..h {
            frame.set(x, mid.saturating_sub(offset), value);
            frame.set(x, (mid + offset).min(region.y + region.h - 1), value);
        }
    }
}

fn draw_negative_bars(frame: &mut Frame, region: Region, bars: &[u8; WIDTH], value: u8) {
    frame.fill_rect(0, region.y, WIDTH, region.h, value);
    for (x, raw) in bars.iter().enumerate() {
        let h = audio_level(*raw, region.h);
        let empty = region.h.saturating_sub(h);
        if empty > 0 {
            frame.fill_rect(x, region.y, 1, empty, 0);
        }
    }
}

fn draw_notification(
    frame: &mut Frame,
    region: Region,
    animation: NotificationAnimation,
    value: u8,
) {
    let phase = phase_index(220, 4);
    match animation {
        NotificationAnimation::BellFlash => {
            let rows = if phase % 2 == 0 {
                [
                    "....#....",
                    "...###...",
                    "...#.#...",
                    "..#####..",
                    "..#####..",
                    "..#####..",
                    ".#######.",
                    "...###...",
                    "....#....",
                    "...###...",
                    ".........",
                ]
            } else {
                [
                    "#.......#",
                    "....#....",
                    "...###...",
                    "...#.#...",
                    "..#####..",
                    "..#####..",
                    ".#######.",
                    "..#...#..",
                    "....#....",
                    "...###...",
                    "#.......#",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        NotificationAnimation::Spark => {
            let rows = match phase {
                0 => [
                    ".........",
                    "....#....",
                    ".........",
                    "...+#+...",
                    "....#....",
                    ".........",
                    ".........",
                    ".........",
                    ".........",
                ],
                1 => [
                    "....+....",
                    "..+.#.+..",
                    "....#....",
                    ".+.###.+.",
                    "....#....",
                    "..+.#.+..",
                    "....+....",
                    ".........",
                    ".........",
                ],
                _ => [
                    "..+...+..",
                    "....#....",
                    ".+.###.+.",
                    "...###...",
                    ".+.###.+.",
                    "....#....",
                    "..+...+..",
                    ".........",
                    ".........",
                ],
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        NotificationAnimation::Ping => {
            let rows = match phase {
                0 => [
                    ".........",
                    "....#....",
                    "...###...",
                    "....#....",
                    ".........",
                    ".........",
                    ".........",
                ],
                1 => [
                    ".........",
                    "...+#+...",
                    "..#...#..",
                    "...+#+...",
                    ".........",
                    ".........",
                    ".........",
                ],
                _ => [
                    "..+...+..",
                    ".+.....+.",
                    "+...#...+",
                    ".+.....+.",
                    "..+...+..",
                    ".........",
                    ".........",
                ],
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        NotificationAnimation::Ring => {
            let rows = if phase % 2 == 0 {
                [
                    ".........",
                    "..+...+..",
                    ".+.....+.",
                    ".+..#..+.",
                    ".+.....+.",
                    "..+...+..",
                    ".........",
                ]
            } else {
                [
                    "+.......+",
                    ".........",
                    "..+...+..",
                    "...###...",
                    "..+...+..",
                    ".........",
                    "+.......+",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        NotificationAnimation::Badge => {
            let rows = if phase % 2 == 0 {
                [
                    ".........",
                    "...###...",
                    "..#...#..",
                    "..#.#.#..",
                    "..#...#..",
                    "...###...",
                    ".........",
                    "....+....",
                    ".........",
                ]
            } else {
                [
                    "....+....",
                    "...###...",
                    "..#####..",
                    "..#.#.#..",
                    "..#####..",
                    "...###...",
                    "....+....",
                    ".........",
                    ".........",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
    }
}

fn draw_penguin(frame: &mut Frame, region: Region, animation: PenguinAnimation, value: u8) {
    let phase = phase_index(330, 4);
    match animation {
        PenguinAnimation::Reference => {
            let rows = match phase {
                0 => [
                    ".........",
                    "...###...",
                    "..#####..",
                    ".##+.+##.",
                    ".##.#.##.",
                    ".###.###.",
                    "####.####",
                    "###...###",
                    "##.....##",
                    "##.....##",
                    ".###.###.",
                    ".##...##.",
                    "###...###",
                ],
                1 => [
                    ".........",
                    "...###...",
                    "..#####..",
                    ".##+.+##.",
                    ".##.#.##.",
                    ".###.###.",
                    "####.####",
                    "###...###",
                    "##.....##",
                    "##.....##",
                    ".###.###.",
                    ".##...##.",
                    ".###..##.",
                ],
                2 => [
                    "...###...",
                    "..#####..",
                    ".##+.+##.",
                    ".##.#.##.",
                    ".###.###.",
                    "####.####",
                    "###...###",
                    "##.....##",
                    "##.....##",
                    ".###.###.",
                    ".##...##.",
                    "###...###",
                    ".........",
                ],
                _ => [
                    ".........",
                    "...###...",
                    "..#####..",
                    ".##+.+##.",
                    ".##.#.##.",
                    ".###.###.",
                    "####.####",
                    "###...###",
                    "##.....##",
                    "##.....##",
                    ".###.###.",
                    ".##...##.",
                    ".##..###.",
                ],
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Waddle => {
            let rows = if phase % 2 == 0 {
                [
                    "..###..", ".#o#o#.", ".#####.", "..###..", ".##+##.", ".#####.", "..###..",
                    ".#...#.", "#.....#", ".......",
                ]
            } else {
                [
                    "..###..", ".#o#o#.", ".#####.", "..###..", ".##+##.", ".#####.", "..###..",
                    "#.....#", ".#...#.", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Chubby => {
            let rows = match phase {
                0 | 2 => [
                    ".#####.", "#o###o#", "#######", ".#####.", "###+###", "#######", ".#####.",
                    "..#.#..", ".#...#.", ".......",
                ],
                _ => [
                    ".#####.", "#o###o#", "#######", ".#####.", "###+###", "#######", ".#####.",
                    ".#...#.", "..#.#..", ".......",
                ],
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Tiny => {
            let rows = if phase % 2 == 0 {
                [
                    ".###.", "#o#o#", "#####", ".#+#.", "#####", ".###.", "#...#", ".....",
                ]
            } else {
                [
                    ".###.", "#o#o#", "#####", ".#+#.", "#####", ".###.", ".#.#.", ".....",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Flipper => {
            let rows = if phase % 2 == 0 {
                [
                    "..###..", ".#o#o#.", ".#####.", "#.###.#", ".##+##.", "..###..", ".#...#.",
                    ".......", ".......",
                ]
            } else {
                [
                    "..###..", ".#o#o#.", "######.", ".##+##.", ".#####.", "..###..", "..#.#..",
                    ".......", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Skater => {
            let rows = if phase % 2 == 0 {
                [
                    "...###.", "..#o#o#", "..#####", "...###.", "..##+##", ".#####.", "...###.",
                    ".#...#.", "####...", ".......",
                ]
            } else {
                [
                    ".###...", "#o#o#..", "#####..", ".###...", "##+##..", ".#####.", ".###...",
                    ".#...#.", "...####", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Jumper => {
            let rows = if phase % 2 == 0 {
                [
                    ".......", "..###..", ".#o#o#.", ".#####.", "..###..", ".##+##.", ".#####.",
                    ".#...#.", ".......", ".......",
                ]
            } else {
                [
                    "..###..", ".#o#o#.", ".#####.", "..###..", ".##+##.", ".#####.", "..###..",
                    ".......", ".#...#.", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Party => {
            let rows = if phase % 2 == 0 {
                [
                    "...+...", "..###..", ".#o#o#.", ".#####.", "..###..", ".##+##.", "#.###.#",
                    "..###..", ".#...#.", ".......",
                ]
            } else {
                [
                    ".+...+.", "..###..", ".#o#o#.", ".#####.", "..###..", "###+###", ".#####.",
                    "..###..", "#.....#", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Sleepy => {
            let rows = if phase % 2 == 0 {
                [
                    ".......", "..###..", ".#o#o#.", ".#####.", "..###..", ".##+##.", ".#####.",
                    "..###..", ".#...#.", ".......",
                ]
            } else {
                [
                    ".....+.", "..###..", ".#.#.#.", ".#####.", "..###..", ".##+##.", ".#####.",
                    "..###..", ".#...#.", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::SideEye => {
            let rows = if phase % 2 == 0 {
                [
                    "..###..", ".#oo##.", ".#####.", "..###..", ".##+##.", ".#####.", "..###..",
                    ".#...#.", ".......",
                ]
            } else {
                [
                    "..###..", ".##oo#.", ".#####.", "..###..", ".##+##.", ".#####.", "..###..",
                    "#.....#", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
        PenguinAnimation::Round => {
            let rows = if phase % 2 == 0 {
                [
                    "..###..", ".#o#o#.", "#######", "###+###", "#######", ".#####.", "..###..",
                    ".#...#.", ".......",
                ]
            } else {
                [
                    "..###..", ".#o#o#.", "#######", "###+###", "#######", ".#####.", "..###..",
                    "#.....#", ".......",
                ]
            };
            draw_centered_bitmap(frame, region, &rows, value);
        }
    }
}

fn draw_centered_bitmap(frame: &mut Frame, region: Region, rows: &[&str], value: u8) {
    let width = rows.iter().map(|row| row.len()).max().unwrap_or(0);
    let x = WIDTH.saturating_sub(width) / 2;
    let y = region.y + region.h.saturating_sub(rows.len()) / 2;
    draw_bitmap(frame, x, y, rows, value);
}

fn draw_bitmap(frame: &mut Frame, x: usize, y: usize, rows: &[&str], value: u8) {
    for (row_idx, row) in rows.iter().enumerate() {
        for (col_idx, ch) in row.chars().enumerate() {
            match ch {
                '#' => frame.set(x + col_idx, y + row_idx, value),
                '+' => frame.set(x + col_idx, y + row_idx, value.saturating_div(2).max(45)),
                'o' => frame.set(x + col_idx, y + row_idx, value.saturating_div(4).max(35)),
                _ => {}
            }
        }
    }
}

fn phase_index(period_millis: u128, frames: u128) -> u8 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| ((duration.as_millis() / period_millis) % frames) as u8)
        .unwrap_or(0)
}

pub fn pulse_until(duration: Duration) -> Instant {
    Instant::now() + duration
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{AnimationConfig, BatteryConfig, LayoutConfig};

    #[test]
    fn battery_policy_matches_thresholds() {
        let cfg = BatteryConfig::default();
        let mut system = SystemSnapshot {
            battery_percent: Some(36),
            charge_state: ChargeState::Discharging,
            ..SystemSnapshot::default()
        };
        assert_eq!(power_mode(&system, &cfg), PowerMode::Normal);
        system.battery_percent = Some(35);
        assert_eq!(power_mode(&system, &cfg), PowerMode::LowBattery);
        system.battery_percent = Some(20);
        assert_eq!(power_mode(&system, &cfg), PowerMode::LowBattery);
        system.battery_percent = Some(19);
        assert_eq!(power_mode(&system, &cfg), PowerMode::Off);
        system.charge_state = ChargeState::Charging;
        assert_eq!(power_mode(&system, &cfg), PowerMode::Normal);
    }

    #[test]
    fn target_brightness_dims_on_battery() {
        let display = DisplayConfig::default();
        let state = AppState {
            system: SystemSnapshot {
                backlight_percent: Some(50),
                charge_state: ChargeState::Discharging,
                ..SystemSnapshot::default()
            },
            ..AppState::default()
        };
        assert_eq!(target_brightness(&state, &display), 15);
    }

    #[test]
    fn left_matrix_contains_spaced_cpu_ram_blocks() {
        let system = SystemSnapshot {
            cpu_percent: 7,
            memory_percent: 42,
            battery_percent: Some(100),
            ..SystemSnapshot::default()
        };
        let state = AppState {
            system,
            ..AppState::default()
        };
        let frame = render_left(
            &state,
            &LayoutConfig::default(),
            &AnimationConfig::default(),
            None,
        );
        assert!(frame.count_lit() > 0);
        assert_eq!(percent_text(Some(7)), "07");
        assert_eq!(percent_text(Some(100)), "100");
        assert_eq!(percent_text(None), "---");

        for y in [0, 6, 17, 23, 33] {
            if y == 6 || y == 23 {
                continue;
            }
            for x in 0..WIDTH {
                assert_eq!(frame.get(x, y), 0);
            }
        }
        for x in 0..WIDTH {
            assert!(frame.get(x, 7) > 0);
            assert!(frame.get(x, 24) > 0);
        }
    }

    #[test]
    fn right_matrix_only_contains_battery_block() {
        let system = SystemSnapshot {
            battery_percent: Some(73),
            ..SystemSnapshot::default()
        };
        let state = AppState {
            system,
            ..AppState::default()
        };
        let frame = render_right(
            &state,
            &LayoutConfig::default(),
            &AnimationConfig::default(),
            None,
        );
        assert!(frame.count_lit() > 0);
        for y in 14..17 {
            for x in 0..WIDTH {
                assert_eq!(frame.get(x, y), 0);
            }
        }
    }

    #[test]
    fn preview_audio_widget_draws_bottom_right() {
        let state = AppState {
            audio_bars: [1, 3, 5, 7, 9, 7, 5, 3, 1],
            ..AppState::default()
        };
        let frame = render_right(
            &state,
            &LayoutConfig::default(),
            &AnimationConfig::default(),
            Some(Preview {
                region: RegionName::BottomRight,
                widget: WidgetKind::AudioMirror,
            }),
        );
        assert!(frame.count_lit() > 0);
        let mut bottom_lit = 0;
        for y in 17..HEIGHT {
            for x in 0..WIDTH {
                if frame.get(x, y) > 0 {
                    bottom_lit += 1;
                }
            }
        }
        assert!(bottom_lit > 0);
    }
}

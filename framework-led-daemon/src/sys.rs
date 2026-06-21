use std::fs;
use std::path::{Path, PathBuf};
use std::time::Instant;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChargeState {
    Charging,
    Discharging,
    Full,
    Unknown,
}

impl ChargeState {
    pub fn is_discharging(self) -> bool {
        matches!(self, Self::Discharging)
    }
}

#[derive(Debug, Clone)]
pub struct SystemSnapshot {
    pub cpu_percent: u8,
    pub memory_percent: u8,
    pub battery_percent: Option<u8>,
    pub charge_state: ChargeState,
    #[allow(dead_code)]
    pub temp_c: Option<u16>,
    pub backlight_percent: Option<u8>,
    #[allow(dead_code)]
    pub net_activity: u8,
}

impl Default for SystemSnapshot {
    fn default() -> Self {
        Self {
            cpu_percent: 0,
            memory_percent: 0,
            battery_percent: None,
            charge_state: ChargeState::Unknown,
            temp_c: None,
            backlight_percent: None,
            net_activity: 0,
        }
    }
}

#[derive(Debug, Clone, Copy)]
struct CpuTimes {
    idle: u64,
    total: u64,
}

#[derive(Debug, Clone)]
struct NetSample {
    bytes: u64,
    at: Instant,
}

#[derive(Debug, Default)]
pub struct SystemSampler {
    prev_cpu: Option<CpuTimes>,
    prev_net: Option<NetSample>,
}

impl SystemSampler {
    pub fn sample(&mut self) -> SystemSnapshot {
        let cpu_percent = self.sample_cpu().unwrap_or(0);
        let memory_percent = read_memory_percent().unwrap_or(0);
        let (battery_percent, charge_state) =
            read_battery().unwrap_or((None, ChargeState::Unknown));
        let temp_c = read_temp_c();
        let backlight_percent = read_backlight_percent();
        let net_activity = self.sample_net().unwrap_or(0);

        SystemSnapshot {
            cpu_percent,
            memory_percent,
            battery_percent,
            charge_state,
            temp_c,
            backlight_percent,
            net_activity,
        }
    }

    fn sample_cpu(&mut self) -> Option<u8> {
        let current = read_cpu_times()?;
        let Some(prev) = self.prev_cpu.replace(current) else {
            return Some(0);
        };
        let total_delta = current.total.saturating_sub(prev.total);
        let idle_delta = current.idle.saturating_sub(prev.idle);
        if total_delta == 0 {
            return Some(0);
        }
        Some((((total_delta - idle_delta) * 100) / total_delta).min(100) as u8)
    }

    fn sample_net(&mut self) -> Option<u8> {
        let bytes = read_net_bytes()?;
        let now = Instant::now();
        let Some(prev) = self.prev_net.replace(NetSample { bytes, at: now }) else {
            return Some(0);
        };
        let secs = now.duration_since(prev.at).as_secs_f64().max(0.001);
        let bytes_per_sec = bytes.saturating_sub(prev.bytes) as f64 / secs;
        let scaled = ((bytes_per_sec.log10().max(0.0) / 7.0) * 100.0).round();
        Some((scaled as u8).min(100))
    }
}

fn read_cpu_times() -> Option<CpuTimes> {
    let stat = fs::read_to_string("/proc/stat").ok()?;
    let line = stat.lines().next()?;
    let mut nums = line
        .split_whitespace()
        .skip(1)
        .filter_map(|n| n.parse::<u64>().ok());
    let user = nums.next()?;
    let nice = nums.next()?;
    let system = nums.next()?;
    let idle = nums.next()?;
    let iowait = nums.next().unwrap_or(0);
    let irq = nums.next().unwrap_or(0);
    let softirq = nums.next().unwrap_or(0);
    let steal = nums.next().unwrap_or(0);
    let idle_all = idle + iowait;
    let total = user + nice + system + idle + iowait + irq + softirq + steal;
    Some(CpuTimes {
        idle: idle_all,
        total,
    })
}

fn read_memory_percent() -> Option<u8> {
    let meminfo = fs::read_to_string("/proc/meminfo").ok()?;
    let mut values = std::collections::BTreeMap::<&str, u64>::new();
    for line in meminfo.lines() {
        let Some((key, rest)) = line.split_once(':') else {
            continue;
        };
        if matches!(
            key,
            "MemTotal" | "MemFree" | "Buffers" | "Cached" | "SReclaimable"
        ) {
            if let Some(value) = rest
                .split_whitespace()
                .next()
                .and_then(|v| v.parse::<u64>().ok())
            {
                values.insert(key, value);
            }
        }
    }
    let total = *values.get("MemTotal")?;
    if total == 0 {
        return Some(0);
    }
    let reclaimable = values.get("MemFree").copied().unwrap_or(0)
        + values.get("Buffers").copied().unwrap_or(0)
        + values.get("Cached").copied().unwrap_or(0)
        + values.get("SReclaimable").copied().unwrap_or(0);
    let mut used = total.saturating_sub(reclaimable);
    used = used.saturating_sub(read_zfs_arc_kb().unwrap_or(0));
    Some(((used * 100) / total).min(100) as u8)
}

fn read_zfs_arc_kb() -> Option<u64> {
    let text = fs::read_to_string("/proc/spl/kstat/zfs/arcstats").ok()?;
    for line in text.lines() {
        let mut fields = line.split_whitespace();
        if fields.next()? == "size" {
            let _ty = fields.next()?;
            let bytes = fields.next()?.parse::<u64>().ok()?;
            return Some(bytes / 1024);
        }
    }
    None
}

fn read_battery() -> Option<(Option<u8>, ChargeState)> {
    let base = Path::new("/sys/class/power_supply");
    let entries = fs::read_dir(base).ok()?;
    for entry in entries.flatten() {
        let path = entry.path();
        let ty = fs::read_to_string(path.join("type")).unwrap_or_default();
        if ty.trim() != "Battery" {
            continue;
        }
        let capacity = fs::read_to_string(path.join("capacity"))
            .ok()
            .and_then(|v| v.trim().parse::<u8>().ok())
            .map(|v| v.min(100));
        let status = fs::read_to_string(path.join("status")).unwrap_or_default();
        let state = match status.trim() {
            "Charging" => ChargeState::Charging,
            "Discharging" => ChargeState::Discharging,
            "Full" | "Not charging" => ChargeState::Full,
            _ => ChargeState::Unknown,
        };
        return Some((capacity, state));
    }
    None
}

fn read_temp_c() -> Option<u16> {
    for path in thermal_candidates() {
        let raw = fs::read_to_string(path).ok()?;
        let milli = raw.trim().parse::<u32>().ok()?;
        if milli > 0 {
            return Some((milli / 1000).min(u16::MAX as u32) as u16);
        }
    }
    None
}

fn thermal_candidates() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    if let Ok(entries) = fs::read_dir("/sys/class/thermal") {
        for entry in entries.flatten() {
            let path = entry.path().join("temp");
            if path.exists() {
                paths.push(path);
            }
        }
    }
    if let Ok(entries) = fs::read_dir("/sys/class/hwmon") {
        for entry in entries.flatten() {
            for idx in 1..=6 {
                let path = entry.path().join(format!("temp{idx}_input"));
                if path.exists() {
                    paths.push(path);
                }
            }
        }
    }
    paths
}

fn read_backlight_percent() -> Option<u8> {
    let entries = fs::read_dir("/sys/class/backlight").ok()?;
    for entry in entries.flatten() {
        let path = entry.path();
        let current = fs::read_to_string(path.join("brightness"))
            .ok()?
            .trim()
            .parse::<u64>()
            .ok()?;
        let max = fs::read_to_string(path.join("max_brightness"))
            .ok()?
            .trim()
            .parse::<u64>()
            .ok()?;
        if max > 0 {
            return Some(((current * 100) / max).min(100) as u8);
        }
    }
    None
}

fn read_net_bytes() -> Option<u64> {
    let text = fs::read_to_string("/proc/net/dev").ok()?;
    let mut total = 0_u64;
    for line in text.lines().skip(2) {
        let (iface, data) = line.split_once(':')?;
        if iface.trim() == "lo" {
            continue;
        }
        let fields: Vec<u64> = data
            .split_whitespace()
            .filter_map(|v| v.parse::<u64>().ok())
            .collect();
        if fields.len() >= 16 {
            total = total.saturating_add(fields[0]).saturating_add(fields[8]);
        }
    }
    Some(total)
}

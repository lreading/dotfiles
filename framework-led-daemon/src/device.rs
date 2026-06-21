use crate::frame::{Frame, HEIGHT, WIDTH};
use anyhow::{Context, Result, anyhow};
use serialport::SerialPort;
use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

const BAUD: u32 = 115_200;
const MAGIC: [u8; 2] = [0x32, 0xAC];
const CMD_BRIGHTNESS: u8 = 0x00;
const CMD_SLEEP: u8 = 0x03;
const CMD_STAGE_COL: u8 = 0x07;
const CMD_FLUSH_COLS: u8 = 0x08;
const VID: &str = "32ac";
const PID: &str = "0020";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeviceInfo {
    pub path: PathBuf,
    pub tty: Option<PathBuf>,
    pub by_path: bool,
    pub vendor_id: Option<String>,
    pub model_id: Option<String>,
    pub model: Option<String>,
}

impl DeviceInfo {
    pub fn describe(&self) -> String {
        let marker = if self.is_led_matrix() { "ok" } else { "skip" };
        format!(
            "[{marker}] {}{} vid={} pid={} model={}",
            self.path.display(),
            self.tty
                .as_ref()
                .map(|p| format!(" -> {}", p.display()))
                .unwrap_or_default(),
            self.vendor_id.as_deref().unwrap_or("?"),
            self.model_id.as_deref().unwrap_or("?"),
            self.model.as_deref().unwrap_or("?")
        )
    }

    pub fn is_led_matrix(&self) -> bool {
        self.vendor_id
            .as_deref()
            .is_some_and(|v| v.eq_ignore_ascii_case(VID))
            && self
                .model_id
                .as_deref()
                .is_some_and(|v| v.eq_ignore_ascii_case(PID))
    }
}

pub fn discover_devices() -> Result<Vec<DeviceInfo>> {
    let mut devices = BTreeMap::<PathBuf, DeviceInfo>::new();
    let mut seen_ttys = BTreeSet::<PathBuf>::new();

    if let Ok(entries) = fs::read_dir("/dev/serial/by-path") {
        let mut by_path_entries = entries.flatten().map(|e| e.path()).collect::<Vec<_>>();
        by_path_entries.sort();
        by_path_entries.sort_by_key(|p| p.to_string_lossy().contains("usbv2"));
        for path in by_path_entries {
            let Some(tty) = canonical_tty(&path) else {
                continue;
            };
            if seen_ttys.contains(&tty) {
                continue;
            }
            let mut info = inspect_device(&path)?;
            info.tty = Some(tty);
            info.by_path = true;
            if info.is_led_matrix() {
                if let Some(tty) = &info.tty {
                    seen_ttys.insert(tty.clone());
                }
                devices.insert(path, info);
            }
        }
    }

    for idx in 0..16 {
        let path = PathBuf::from(format!("/dev/ttyACM{idx}"));
        if !path.exists() {
            continue;
        }
        let info = inspect_device(&path)?;
        if info.is_led_matrix() && !seen_ttys.contains(&path) {
            seen_ttys.insert(path.clone());
            devices.insert(path, info);
        }
    }

    Ok(devices.into_values().collect())
}

fn canonical_tty(path: &Path) -> Option<PathBuf> {
    fs::canonicalize(path)
        .ok()
        .and_then(|p| p.file_name().map(|name| PathBuf::from("/dev").join(name)))
}

fn inspect_device(path: &Path) -> Result<DeviceInfo> {
    let props = udev_properties(path);
    Ok(DeviceInfo {
        path: path.to_path_buf(),
        tty: if path.starts_with("/dev/tty") {
            Some(path.to_path_buf())
        } else {
            canonical_tty(path)
        },
        by_path: path.starts_with("/dev/serial/by-path"),
        vendor_id: props.get("ID_VENDOR_ID").cloned(),
        model_id: props.get("ID_MODEL_ID").cloned(),
        model: props.get("ID_MODEL").cloned(),
    })
}

fn udev_properties(path: &Path) -> BTreeMap<String, String> {
    let output = Command::new("udevadm")
        .args(["info", "-q", "property", "-n"])
        .arg(path)
        .output();
    let Ok(output) = output else {
        return BTreeMap::new();
    };
    if !output.status.success() {
        return BTreeMap::new();
    }
    String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter_map(|line| {
            let (key, value) = line.split_once('=')?;
            Some((key.to_string(), value.to_string()))
        })
        .collect()
}

#[derive(Debug, Clone)]
pub struct MatrixPaths {
    pub left: Option<PathBuf>,
    pub right: Option<PathBuf>,
}

impl MatrixPaths {
    pub fn resolve(
        configured_left: Option<PathBuf>,
        configured_right: Option<PathBuf>,
    ) -> Result<Self> {
        if configured_left.is_some() || configured_right.is_some() {
            return Ok(Self {
                left: configured_left,
                right: configured_right,
            });
        }

        let devices = discover_devices()?;
        let mut paths = devices
            .into_iter()
            .filter(|d| d.is_led_matrix())
            .map(|d| d.path)
            .collect::<Vec<_>>();
        paths.sort();

        Ok(Self {
            left: paths.first().cloned(),
            right: paths.get(1).cloned(),
        })
    }
}

pub trait MatrixOutput {
    fn set_brightness(&mut self, brightness: u8) -> Result<()>;
    fn set_sleeping(&mut self, sleeping: bool) -> Result<()>;
    fn draw(&mut self, frame: &Frame) -> Result<()>;
}

pub struct SerialMatrix {
    path: PathBuf,
    port: Option<Box<dyn SerialPort>>,
}

impl SerialMatrix {
    pub fn new(path: PathBuf) -> Self {
        Self { path, port: None }
    }

    fn port(&mut self) -> Result<&mut dyn SerialPort> {
        if self.port.is_none() {
            let port = serialport::new(self.path.to_string_lossy(), BAUD)
                .timeout(Duration::from_millis(500))
                .open()
                .with_context(|| format!("opening {}", self.path.display()))?;
            self.port = Some(port);
        }
        Ok(self.port.as_deref_mut().expect("port just opened"))
    }

    fn command(&mut self, command: u8, payload: &[u8]) -> Result<()> {
        let mut bytes = Vec::with_capacity(MAGIC.len() + 1 + payload.len());
        bytes.extend_from_slice(&MAGIC);
        bytes.push(command);
        bytes.extend_from_slice(payload);
        let result = self.port()?.write_all(&bytes);
        if result.is_err() {
            self.port = None;
            self.port()?.write_all(&bytes)?;
        }
        Ok(())
    }
}

impl MatrixOutput for SerialMatrix {
    fn set_brightness(&mut self, brightness: u8) -> Result<()> {
        self.command(CMD_BRIGHTNESS, &[brightness])
    }

    fn set_sleeping(&mut self, sleeping: bool) -> Result<()> {
        self.command(CMD_SLEEP, &[u8::from(sleeping)])
    }

    fn draw(&mut self, frame: &Frame) -> Result<()> {
        for x in 0..WIDTH {
            let mut payload = [0_u8; HEIGHT + 1];
            payload[0] = x as u8;
            payload[1..].copy_from_slice(frame.col(x));
            self.command(CMD_STAGE_COL, &payload)?;
        }
        self.command(CMD_FLUSH_COLS, &[])
    }
}

pub struct MockMatrix {
    name: String,
    last_lit: usize,
}

impl MockMatrix {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            last_lit: 0,
        }
    }
}

impl MatrixOutput for MockMatrix {
    fn set_brightness(&mut self, brightness: u8) -> Result<()> {
        println!("{} brightness={brightness}", self.name);
        Ok(())
    }

    fn set_sleeping(&mut self, sleeping: bool) -> Result<()> {
        println!("{} sleeping={sleeping}", self.name);
        Ok(())
    }

    fn draw(&mut self, frame: &Frame) -> Result<()> {
        let lit = frame.count_lit();
        if lit != self.last_lit {
            println!("{} lit_pixels={lit}", self.name);
            self.last_lit = lit;
        }
        Ok(())
    }
}

pub struct MatrixPair {
    pub left: Box<dyn MatrixOutput + Send>,
    pub right: Box<dyn MatrixOutput + Send>,
    swap: bool,
}

impl MatrixPair {
    pub fn open(paths: MatrixPaths, mock: bool, swap: bool) -> Result<Self> {
        if mock {
            return Ok(Self {
                left: Box::new(MockMatrix::new("left")),
                right: Box::new(MockMatrix::new("right")),
                swap,
            });
        }
        let left = paths
            .left
            .ok_or_else(|| anyhow!("no left LED matrix configured or detected"))?;
        let right = paths
            .right
            .ok_or_else(|| anyhow!("no right LED matrix configured or detected"))?;
        Ok(Self {
            left: Box::new(SerialMatrix::new(left)),
            right: Box::new(SerialMatrix::new(right)),
            swap,
        })
    }

    pub fn set_brightness(&mut self, brightness: u8) -> Result<()> {
        self.left.set_brightness(brightness)?;
        self.right.set_brightness(brightness)?;
        Ok(())
    }

    pub fn set_sleeping(&mut self, sleeping: bool) -> Result<()> {
        self.left.set_sleeping(sleeping)?;
        self.right.set_sleeping(sleeping)?;
        Ok(())
    }

    pub fn clear(&mut self) -> Result<()> {
        self.draw(&Frame::new(), &Frame::new())
    }

    pub fn draw(&mut self, left: &Frame, right: &Frame) -> Result<()> {
        if self.swap {
            self.left.draw(right)?;
            self.right.draw(left)?;
        } else {
            self.left.draw(left)?;
            self.right.draw(right)?;
        }
        Ok(())
    }
}

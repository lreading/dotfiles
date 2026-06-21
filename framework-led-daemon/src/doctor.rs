use crate::config;
use crate::device::discover_devices;
use anyhow::Result;
use clap::Args;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Debug, Clone, Args)]
pub struct DoctorArgs {
    /// Config file path. Defaults to ~/.config/framework-led-daemon/config.toml.
    #[arg(long)]
    pub config: Option<PathBuf>,
    /// Create a default config file if one does not exist.
    #[arg(long)]
    pub write_default_config: bool,
}

pub fn run(args: DoctorArgs) -> Result<()> {
    let cfg_path = args.config.unwrap_or_else(config::default_config_path);
    if args.write_default_config && !cfg_path.exists() {
        let mut cfg = config::Config::default();
        let devices = discover_devices()?
            .into_iter()
            .filter(|d| d.is_led_matrix())
            .map(|d| d.path)
            .collect::<Vec<_>>();
        cfg.devices.left = devices.first().cloned();
        cfg.devices.right = devices.get(1).cloned();
        config::write_config(&cfg_path, &cfg)?;
        println!("ok  wrote default config: {}", cfg_path.display());
    }

    println!("Framework LED Matrix daemon doctor");
    println!();
    check_config(&cfg_path)?;
    check_commands();
    check_groups();
    check_devices()?;
    check_systemd();
    check_install();
    Ok(())
}

fn check_config(path: &Path) -> Result<()> {
    if path.exists() {
        let (cfg, _, _) = config::load(Some(path))?;
        println!("ok  config exists: {}", path.display());
        check_configured_path("left", cfg.devices.left.as_deref());
        check_configured_path("right", cfg.devices.right.as_deref());
    } else {
        println!("warn config missing: {}", path.display());
        println!("     run: framework-led-daemon doctor --write-default-config");
    }
    Ok(())
}

fn check_configured_path(name: &str, path: Option<&Path>) {
    match path {
        Some(path) if path.exists() => {
            println!("ok  configured {name} path exists: {}", path.display())
        }
        Some(path) => println!("warn configured {name} path missing: {}", path.display()),
        None => println!("info configured {name} path: auto-detect"),
    }
}

fn check_commands() {
    for command in [
        "udevadm",
        "swaync-client",
        "tmux",
        "cava",
        "playerctl",
        "systemctl",
    ] {
        if command_exists(command) {
            println!("ok  command available: {command}");
        } else {
            println!("warn command missing: {command}");
        }
    }
}

fn command_exists(command: &str) -> bool {
    Command::new("sh")
        .arg("-c")
        .arg(format!("command -v {command} >/dev/null 2>&1"))
        .status()
        .is_ok_and(|status| status.success())
}

fn check_groups() {
    let output = Command::new("id").arg("-nG").output();
    let Ok(output) = output else {
        println!("warn could not check user groups");
        return;
    };
    let groups = String::from_utf8_lossy(&output.stdout);
    if groups
        .split_whitespace()
        .any(|g| g == "uucp" || g == "dialout")
    {
        println!("ok  serial permissions group present: {}", groups.trim());
    } else {
        println!("warn user is not in uucp/dialout; serial devices may be inaccessible");
    }
}

fn check_devices() -> Result<()> {
    let devices = discover_devices()?;
    let led_devices = devices
        .iter()
        .filter(|d| d.is_led_matrix())
        .collect::<Vec<_>>();
    if led_devices.len() >= 2 {
        println!("ok  detected {} LED matrix devices", led_devices.len());
    } else {
        println!(
            "warn detected {} LED matrix devices; expected 2",
            led_devices.len()
        );
    }
    for device in devices {
        println!("     {}", device.describe());
        if device.is_led_matrix() {
            check_accessible(&device.path);
        }
    }
    Ok(())
}

fn check_accessible(path: &Path) {
    match fs::metadata(path) {
        Ok(metadata) => {
            let mode = metadata.permissions().mode();
            if mode & 0o060 != 0 {
                println!("ok  group read/write bits present: {}", path.display());
            } else {
                println!(
                    "warn serial device may not be group-accessible: {}",
                    path.display()
                );
            }
        }
        Err(err) => println!("warn cannot stat {}: {err}", path.display()),
    }
}

fn check_systemd() {
    let unit_path = dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("systemd/user/framework-led-daemon.service");
    if unit_path.exists() {
        println!("ok  user service file exists: {}", unit_path.display());
    } else {
        println!(
            "warn user service file not installed: {}",
            unit_path.display()
        );
    }

    let output = Command::new("systemctl")
        .args(["--user", "is-enabled", "framework-led-daemon.service"])
        .output();
    match output {
        Ok(output) if output.status.success() => println!("ok  systemd user service is enabled"),
        Ok(output) => println!(
            "warn systemd user service not enabled: {}",
            String::from_utf8_lossy(&output.stdout).trim()
        ),
        Err(err) => println!("warn could not query systemd user service: {err}"),
    }
}

fn check_install() {
    let bin = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".local/bin/framework-led-daemon");
    if bin.exists() {
        println!("ok  installed binary exists: {}", bin.display());
    } else {
        println!("warn installed binary missing: {}", bin.display());
    }
}

use anyhow::{Context, Result, anyhow};
use clap::ValueEnum;
use std::fs;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixDatagram;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::sync::mpsc::Sender;
use std::thread;
use std::time::Duration;
use tracing::{debug, warn};

#[derive(Debug, Clone)]
pub enum Event {
    NotificationCount(u32),
    NotificationPulse,
    CodexPulse,
    AudioBars([u8; crate::frame::WIDTH]),
}

#[derive(Debug, Clone, Copy, ValueEnum)]
pub enum ManualEvent {
    Notify,
    CodexDone,
}

pub fn send_manual_event(event: ManualEvent) -> Result<()> {
    let socket = runtime_socket_path();
    let client_path = runtime_dir().join(format!(
        "framework-led-daemon-client-{}.sock",
        std::process::id()
    ));
    let _ = fs::remove_file(&client_path);
    let client = UnixDatagram::bind(&client_path)
        .with_context(|| format!("binding {}", client_path.display()))?;
    let msg = match event {
        ManualEvent::Notify => "notify",
        ManualEvent::CodexDone => "codex-done",
    };
    client
        .send_to(msg.as_bytes(), &socket)
        .with_context(|| format!("sending to {}", socket.display()))?;
    let _ = fs::remove_file(client_path);
    Ok(())
}

pub fn spawn_manual_listener(tx: Sender<Event>) -> Result<PathBuf> {
    let path = runtime_socket_path();
    let _ = fs::remove_file(&path);
    let listener =
        UnixDatagram::bind(&path).with_context(|| format!("binding {}", path.display()))?;
    thread::spawn(move || {
        let mut buf = [0_u8; 64];
        loop {
            match listener.recv(&mut buf) {
                Ok(n) => match &buf[..n] {
                    b"notify" => {
                        let _ = tx.send(Event::NotificationPulse);
                    }
                    b"codex-done" => {
                        let _ = tx.send(Event::CodexPulse);
                    }
                    other => warn!("unknown manual event: {:?}", String::from_utf8_lossy(other)),
                },
                Err(err) => {
                    warn!("manual event socket failed: {err}");
                    thread::sleep(Duration::from_secs(1));
                }
            }
        }
    });
    Ok(path)
}

pub fn spawn_swaync_watcher(tx: Sender<Event>, swaync_client: String, poll_seconds: u64) {
    let count_tx = tx.clone();
    let count_client = swaync_client.clone();
    thread::spawn(move || {
        loop {
            if let Ok(count) = swaync_count(&count_client) {
                let _ = count_tx.send(Event::NotificationCount(count));
            }
            thread::sleep(Duration::from_secs(poll_seconds.max(1)));
        }
    });

    thread::spawn(move || {
        loop {
            let mut child = match Command::new(&swaync_client)
                .arg("--subscribe")
                .stdout(Stdio::piped())
                .stderr(Stdio::null())
                .spawn()
            {
                Ok(child) => child,
                Err(err) => {
                    warn!("failed to start swaync subscription: {err}");
                    thread::sleep(Duration::from_secs(5));
                    continue;
                }
            };

            let Some(stdout) = child.stdout.take() else {
                let _ = child.kill();
                thread::sleep(Duration::from_secs(5));
                continue;
            };

            let mut last_count = swaync_count(&swaync_client).ok();
            for line in BufReader::new(stdout).lines() {
                match line {
                    Ok(line) => {
                        debug!("swaync event: {line}");
                        let count = parse_swaync_subscribe_count(&line)
                            .or_else(|| swaync_count(&swaync_client).ok());
                        if let Some(count) = count {
                            if last_count.is_some_and(|previous| count > previous) {
                                let _ = tx.send(Event::NotificationPulse);
                            }
                            last_count = Some(count);
                            let _ = tx.send(Event::NotificationCount(count));
                        }
                    }
                    Err(err) => {
                        warn!("swaync subscription read failed: {err}");
                        break;
                    }
                }
            }
            let _ = child.kill();
            thread::sleep(Duration::from_secs(2));
        }
    });
}

pub fn swaync_count(swaync_client: &str) -> Result<u32> {
    let output = Command::new(swaync_client)
        .arg("--count")
        .output()
        .with_context(|| format!("running {swaync_client} --count"))?;
    if !output.status.success() {
        return Err(anyhow!("{swaync_client} --count failed"));
    }
    let text = String::from_utf8_lossy(&output.stdout);
    Ok(text.trim().parse::<u32>().unwrap_or(0))
}

fn parse_swaync_subscribe_count(line: &str) -> Option<u32> {
    let (_, after_key) = line.split_once("\"count\"")?;
    let (_, after_colon) = after_key.split_once(':')?;
    let digits = after_colon
        .trim_start()
        .chars()
        .take_while(|ch| ch.is_ascii_digit())
        .collect::<String>();
    digits.parse().ok()
}

pub fn runtime_socket_path() -> PathBuf {
    runtime_dir().join("framework-led-daemon.sock")
}

fn runtime_dir() -> PathBuf {
    std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/tmp"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_swaync_subscribe_count() {
        assert_eq!(
            parse_swaync_subscribe_count(
                r#"{ "count": 12, "dnd": false, "visible": true, "inhibited": false }"#
            ),
            Some(12)
        );
        assert_eq!(
            parse_swaync_subscribe_count(r#"["notification", "x"]"#),
            None
        );
    }
}

use crate::frame::WIDTH;
use crate::notify::Event;
use anyhow::Result;
use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use std::sync::mpsc::Sender;
use std::thread;
use std::time::Duration;
use tempfile::NamedTempFile;
use tracing::warn;

pub fn spawn_cava(tx: Sender<Event>, cava_bin: String) {
    thread::spawn(move || {
        loop {
            if let Err(err) = run_cava_once(&tx, &cava_bin) {
                warn!("cava visualizer unavailable: {err}");
            }
            thread::sleep(Duration::from_secs(5));
        }
    });
}

fn run_cava_once(tx: &Sender<Event>, cava_bin: &str) -> Result<()> {
    let mut config = NamedTempFile::new()?;
    write!(
        config,
        r#"[general]
framerate = 12
bars = 9
autosens = 1

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 9
channels = mono
"#
    )?;
    config.flush()?;

    let mut child = Command::new(cava_bin)
        .arg("-p")
        .arg(config.path())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()?;
    let stdout = child.stdout.take().expect("stdout was piped");
    for line in BufReader::new(stdout).lines() {
        let line = line?;
        if let Some(bars) = parse_cava_line(&line) {
            let _ = tx.send(Event::AudioBars(bars));
        }
    }
    let _ = child.kill();
    Ok(())
}

pub fn parse_cava_line(line: &str) -> Option<[u8; WIDTH]> {
    let nums = line
        .split([';', ' ', ',', '\t'])
        .filter(|s| !s.is_empty())
        .filter_map(|s| s.parse::<u8>().ok())
        .collect::<Vec<_>>();
    if nums.is_empty() {
        return None;
    }
    let mut bars = [0_u8; WIDTH];
    for (idx, value) in nums.into_iter().take(WIDTH).enumerate() {
        bars[idx] = value.min(9);
    }
    Some(bars)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_cava_ascii_rows() {
        let bars = parse_cava_line("1;2;3;4;5;6;7;8;9").unwrap();
        assert_eq!(bars, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }
}

use crate::notify::Event;
use std::collections::BTreeSet;
use std::process::Command;
use std::sync::mpsc::Sender;
use std::thread;
use std::time::Duration;
use tracing::warn;

pub fn spawn_watcher(tx: Sender<Event>, poll_millis: u64) {
    thread::spawn(move || {
        let mut previous_codex = BTreeSet::<String>::new();
        loop {
            match codex_panes() {
                Ok(current) => {
                    if !previous_codex.is_empty() {
                        for pane in previous_codex.difference(&current) {
                            warn!("codex pane no longer active: {pane}");
                            let _ = tx.send(Event::CodexPulse);
                        }
                    }
                    previous_codex = current;
                }
                Err(err) => {
                    warn!("tmux watcher failed: {err}");
                }
            }
            thread::sleep(Duration::from_millis(poll_millis.max(250)));
        }
    });
}

pub fn codex_panes() -> anyhow::Result<BTreeSet<String>> {
    let output = Command::new("tmux")
        .args([
            "list-panes",
            "-a",
            "-F",
            "#{pane_id}\t#{pane_current_command}\t#{pane_title}",
        ])
        .output()?;
    if !output.status.success() {
        return Ok(BTreeSet::new());
    }

    let mut panes = BTreeSet::new();
    for line in String::from_utf8_lossy(&output.stdout).lines() {
        let mut parts = line.split('\t');
        let pane_id = parts.next().unwrap_or_default();
        let command = parts.next().unwrap_or_default().to_ascii_lowercase();
        let title = parts.next().unwrap_or_default().to_ascii_lowercase();
        if command.contains("codex") || title.contains("codex") {
            panes.insert(pane_id.to_string());
        }
    }
    Ok(panes)
}

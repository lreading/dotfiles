# Framework LED Daemon

Rust status daemon for two Framework Laptop LED Matrix input modules.

## Local Testing

Run against hardware:

```sh
cargo run
```

Render one frame and exit:

```sh
cargo run -- run --once
```

Run without touching hardware:

```sh
cargo run -- run --mock
```

Preview a single widget without changing config:

```sh
cargo run -- run --once --preview-region bottom-right --preview-widget bell
cargo run -- run --once --preview-region bottom-right --preview-widget audio-bars
cargo run -- run --once --preview-region bottom-right --preview-widget audio-wave
cargo run -- run --once --preview-region bottom-right --preview-widget audio-mirror
cargo run -- run --once --preview-region bottom-right --preview-widget negative-bars
cargo run -- run --once --preview-region bottom-right --preview-widget penguin
```

Add `--mock` to any preview command to avoid writing to hardware.

Check config, permissions, hardware, commands, and systemd install state:

```sh
cargo run -- doctor
```

Create `~/.config/framework-led-daemon/config.toml` with detected module paths:

```sh
cargo run -- doctor --write-default-config
```

Local `cargo run` and the installed service both use the same config by default:

```text
~/.config/framework-led-daemon/config.toml
```

Use a temporary config during local testing:

```sh
cargo run -- run --config ./my-test-config.toml
```

Brightness is configured under `[display]`. The daemon computes LED brightness from the current screen brightness:

```toml
screen_brightness_scale_percent = 45
min_brightness = 4
max_brightness = 42
```

Lower `screen_brightness_scale_percent` first if the LEDs are too bright relative to the display. Lower `max_brightness` if you want a hard cap.

Widget layout is configured under `[layout]`:

```toml
top_left = "cpu"
bottom_left = "ram"
top_right = "bat"
bottom_right = "penguin-on-notify"
```

`penguin-on-notify` is blank until a notification pulse, then shows the selected penguin animation for `pulse_millis`.

Supported widgets: `blank`, `cpu`, `ram`, `bat`, `bell`, `audio-bars`, `audio-wave`, `audio-mirror`, `negative-bars`, `penguin`, `penguin-on-notify`, `bell-or-bars`, `bell-or-penguin`, `dynamic-status`.

Animation variants are configured separately:

```toml
[animations]
penguin = "waddle"
notification = "bell-flash"

[notifications]
pulse_millis = 5000
```

Penguin options: `reference`, `waddle`, `chubby`, `tiny`, `flipper`, `skater`, `jumper`, `party`, `sleepy`, `side-eye`, `round`.
Notification options: `bell-flash`, `spark`, `ping`, `ring`, `badge`.

Copy `config.example.toml` before installing if you want to tune defaults first:

```sh
mkdir -p ~/.config/framework-led-daemon
cp config.example.toml ~/.config/framework-led-daemon/config.toml
```

## Install

```sh
./scripts/install.sh
```

This builds the release binary, installs it to `~/.local/bin/framework-led-daemon`, installs a `systemd --user` service, creates config if needed, and enables the daemon.

Uninstall the binary and user service:

```sh
./scripts/uninstall.sh
```

The uninstall script leaves user config intact.

## Manual Events

Trigger a notification pulse:

```sh
framework-led-daemon notify notify
```

Trigger a Codex/tmux completion pulse:

```sh
framework-led-daemon notify codex-done
```

These commands send to the daemon's Unix socket in `$XDG_RUNTIME_DIR`.

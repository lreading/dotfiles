# Hyprland user layer

Install [LinuxBeginnings Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots) first. Its scripts and base configuration remain upstream-owned. This Stow package holds settings and helpers that the upstream user layer loads. The optional `work-laptop` package holds hardware-specific settings.

Keep changes in user configuration files. Do not edit or copy upstream scripts
into this repo. Leave files that upstream regenerates as live state. Do not
Stow them.

Waybar is upstream-owned at `~/.config/hypr/waybar`. Top-level
`hypridle.conf` is also rewritten by upstream patches. The personal source
files are in `../overlays`. Run `hypr-overlays-apply` after an upstream
upgrade. The command installs the user-owned `UserModules`, a named layout, a
named style, and the Hypridle override. It then selects the Waybar files
without replacing an unexpected regular file.

## Install or refresh

From `~/dev/dotfiles`, run `stow -nv hypr`. Check any conflicts before you run
`stow -R hypr`. On the work laptop, include `work-laptop` in both commands.
Upstream's `copy.sh` may replace live links. Re-stow after an upstream update.
Do not use `stow --adopt` or `git restore` as an update step. Either can hide
changes that need review.

Run `Hyprland --verify-config` and then `hyprctl reload config-only`. A new login is needed to test startup commands.

## Startup logs

Each user-owned launch writes its start, output, and exit status to the user
journal. Upstream starts Waybar after `WallpaperDaemon.sh` generates colors.
This repository does not provide a Waybar systemd unit.

Show startup logs for this boot with:

```bash
journalctl --user -b -t hypr-user-startup
journalctl --user -b -u waybar.service
```

Use `-b -1` for the previous boot. Upstream startup commands use upstream's own logging; this package does not replace it.

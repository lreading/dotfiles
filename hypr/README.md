# Hyprland user layer

Install [LinuxBeginnings Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots) first. Its scripts and base configuration remain upstream-owned. This Stow package holds settings and helpers that the upstream user layer loads. The optional `work-laptop` package holds hardware-specific settings.

Keep changes in user configuration files. Do not edit or copy upstream scripts into this repo. If upstream offers no user-level hook, keep the smallest required Stow-managed selector and document the exception.
Leave files that upstream regenerates as live state; do not Stow them.

## Install or refresh

From `~/dev/dotfiles`, run `stow -nv hypr waybar`. Check any conflicts before you run `stow -R hypr waybar`. On the work laptop, include `work-laptop` in both commands. Upstream's `copy.sh` may replace live links; re-stow after an upstream update. Do not use `stow --adopt` or `git restore` as an update step: either can hide changes that need review.

Run `Hyprland --verify-config` and then `hyprctl reload config-only`. A new login is needed to test startup commands.

## Startup logs

Each user-owned launch writes its start, output, and exit status to the user journal. Waybar uses a user service, started by upstream's `WaybarStartup.sh` after `WallpaperDaemon.sh` finishes generating colors. Enable it with its `hyprland-waybar.service` alias so the upstream helper recognizes systemd ownership. Do not attach it to `graphical-session.target`: that starts the bar before the colors are ready and causes an immediate reload at login.

When upgrading from the previously enabled unit, remove its automatic start and reload the unit definitions (the running bar stays up):

```bash
systemctl --user disable waybar.service
stow waybar
systemctl --user daemon-reload
systemctl --user enable waybar.service
```

Show startup logs for this boot with:

```bash
journalctl --user -b -t hypr-user-startup
journalctl --user -b -u waybar.service
```

Use `-b -1` for the previous boot. Upstream startup commands use upstream's own logging; this package does not replace it.

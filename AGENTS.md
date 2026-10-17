# Repository notes

This is a personal GNU Stow user layer. It extends, but does not fork, the
locally installed LinuxBeginnings Hyprland-Dots repository.

- Do not edit vendor files. Use this repository's Stow packages, `overlays`,
  and `UserConfigs` or `UserScripts` integration points.
- Do not read, print, or handle secrets. Stop and notify the user if one is
  encountered.
- Run `stow -nv <packages>` before Stow changes. Do not use `--adopt`.
- `work-laptop` is optional and must stay separate from personal-laptop config.
- Upstream regenerates `~/.config/hypr/waybar` and top-level `hypridle.conf`.
  After an upstream update, re-Stow and run `hypr-overlays-apply`.
- Waybar uses the user-owned static blue-gray palette. Do not restore its
  Wallust color import unless the user asks for wallpaper-driven colors.
- Verify Hyprland with `Hyprland --verify-config`. Use
  `hyprctl reload config-only`; do not use a broad reload for monitor changes.
- SDDM source is Stow-managed. Deploy it only with `deploy-sddm-theme`, which
  requires `sudo`; never Stow into `/usr/share`.
- Do not commit, push, or run privileged commands unless the user asks.

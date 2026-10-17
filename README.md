# Dotfiles

Personal dotfiles managed with GNU Stow.

The Hyprland setup is intentionally layered on top of LinuxBeginnings:

- Initial Arch setup: https://github.com/LinuxBeginnings/Arch-Hyprland
- Hyprland dots: https://github.com/LinuxBeginnings/Hyprland-Dots

Shout-out to [Jakoolit](https://github.com/jakoolit/) for creating and maintaining these wonderful resources for so long, and [LinuxBeginnings](https://github.com/LinuxBeginnings) for taking over ownership and making them into a community effort, led by [Don Williams](https://github.com/dwilliam62)! <3

The related configs in this repo are user-owned configs, not a complete fork or replication of the Hyprland-Dots.


## Packages

- `hypr`: user settings and helpers for Hyprland-Dots.
- `overlays`: source files for generated upstream settings and personal palette
  overrides. This is not a Stow package. Use `hypr-overlays-apply` after an
  upstream update.
- `swaync`: notification config and style.
- `kitty`, `nvim`, `tmux`: app-specific config.
- `local-bin`: user scripts in `~/.local/bin`, including git worktree helpers.
- `sddm`: source for the mutable `simple_sddm_2` theme settings and a deploy
  helper for its system-owned files.
- `work-laptop`: optional Framework dock, network, USB, audio, Hyprland, and
  shell customizations. Stow this package only on the work laptop.

The repo-level `.stowrc` targets `~`, so stow commands can be run from the repo root without passing `--target`.

## Bootstrap

Install Arch and the Hyprland base first:

```bash
git clone https://github.com/LinuxBeginnings/Arch-Hyprland.git
git clone https://github.com/LinuxBeginnings/Hyprland-Dots.git
```

Run the upstream installers according to those repos. After the upstream config exists, check for conflicts, then install this user layer:

```bash
cd ~/dev/dotfiles
stow -nv hypr swaync kitty nvim tmux local-bin sddm shell
stow hypr swaync kitty nvim tmux local-bin sddm shell
stow -nv work-laptop && stow work-laptop # Only on the work laptop.
```

If Stow reports a conflict, inspect the live file before moving it. Do not use `--adopt` and `git restore` as a routine install step: they can hide changes.

This user layer uses Hyprland's Lua configuration. If Hyprland-Dots installed
the Lua entrypoint as `hyprland.lua.disable`, enable and verify it while keeping
the old Hyprlang entrypoint as a rollback:

```bash
mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.disable
mv ~/.config/hypr/hyprland.lua.disable ~/.config/hypr/hyprland.lua
Hyprland --verify-config
```

Restart Hyprland or reboot after the verification succeeds. Do not use
`hyprctl reload` for this one-time switch: an already-running Hyprland process
keeps its original `.conf` path until the compositor restarts.

## Hyprland-Dots Updates

Use the update steps in [hypr/README.md](hypr/README.md).

## Add a Stow package

Use one package per app or concern. Mirror its path under `$HOME` in the package. Run `stow -nv <package>` before you stow it. If a live file conflicts, compare it with the package file and keep a backup before you move it. Do not use `--adopt` or `git restore` without reviewing each affected file.

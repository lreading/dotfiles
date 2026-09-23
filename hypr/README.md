# Hypr

Personal overrides for LinuxBeginnings Hyprland-Dots. See the [root README](../README.md) for the source and setup.

## Folders

- `UserConfigs`: personal Lua settings and startup commands.
- `UserScripts`: personal helper scripts.
- `UserPrefs`: generated theme files.
- `scripts`: one local override for a vendor script.

## Update upstream

Upstream uses `copy.sh` to copy files. It does not keep Stow links. This uses the installed vendor script's stash-and-pull flow.

1. Commit this repo. Then run:

```bash
arch_dir=$HOME/dev/arch-hyprland
dots_dir=$arch_dir/Hyprland-Dots
git -C "$dots_dir" stash push -m "before upstream refresh"
git -C "$arch_dir" pull --ff-only
git -C "$dots_dir" pull --ff-only
bash "$arch_dir/install-scripts/update-deps.sh"
bash "$dots_dir/copy.sh" --express-upgrade
cd "$HOME/dev/dotfiles"
stow --adopt hypr waybar swaync kitty
stow --adopt work-laptop # Only on the work laptop.
git restore .
bash ~/.config/hypr/UserScripts/ApplyUserPreferences.sh
hyprctl reload

```

## Debug startup

1. Show this boot's startup log:

   ```bash
   journalctl --user -b -t hypr-user-startup
   ```

2. Show the previous boot's startup log:

   ```bash
   journalctl --user -b -1 -t hypr-user-startup
   ```

The system journal limits and rotates these logs.

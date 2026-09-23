# Hypr

Personal overrides for LinuxBeginnings Hyprland-Dots. See the [root README](../README.md) for the source and setup.

## Folders

- `UserConfigs`: personal Lua settings and startup commands.
- `UserScripts`: personal helper scripts.
- `UserPrefs`: generated theme files.
- `scripts`: one local override for a vendor script.

## Update upstream

Upstream uses `copy.sh` to copy files. It does not keep Stow links. This follows the [official update guide](https://github.com/LinuxBeginnings/Hyprland-Dots/blob/main/docs/HOWTO-Upgrade-Dotfiles.md) and keeps the old clones as backups.

1. Commit this repo. Then run:

   ```bash
   update_stamp=$(date +%Y%m%d-%H%M%S)
   arch_dir=$HOME/Arch-Hyprland
   dots_dir=$HOME/Hyprland-Dots
   [[ ! -e "$arch_dir" ]] || mv "$arch_dir" "$arch_dir.before-$update_stamp"
   git clone --depth 1 https://github.com/LinuxBeginnings/Arch-Hyprland.git "$arch_dir"
   bash "$arch_dir/install-scripts/update-deps.sh"
   [[ ! -e "$dots_dir" ]] || mv "$dots_dir" "$dots_dir.before-$update_stamp"
   git clone --depth 1 https://github.com/LinuxBeginnings/Hyprland-Dots.git "$dots_dir"
   bash "$dots_dir/copy.sh" --express-upgrade
   cd "$HOME/dev/dotfiles"
   stow --adopt hypr waybar swaync kitty
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

# Dotfiles

Personal dotfiles managed with GNU Stow.

The Hyprland setup is intentionally layered on top of LinuxBeginnings:

- Initial Arch setup: https://github.com/LinuxBeginnings/Arch-Hyprland
- Hyprland dots: https://github.com/LinuxBeginnings/Hyprland-Dots

Shout-out to [Jakoolit](https://github.com/jakoolit/) for creating and maintaining these wonderful resources for so long, and [LinuxBeginnings](https://github.com/LinuxBeginnings) for taking over ownership and making them into a community effort, led by [Don Williams](https://github.com/dwilliam62)! <3

The related configs in this repo are user-owned configs, not a complete fork or replication of the Hyprland-Dots.


## Packages

- `hypr`: user override layer for Hyprland-Dots:
  - `~/.config/hypr/UserConfigs`
  - `~/.config/hypr/UserScripts`
  - `~/.config/hypr/UserPrefs`
- `waybar`: user Waybar override files and selected style/config files:
  - `~/.config/waybar/UserModules`
  - `~/.config/waybar/configs/[TOP] Default Laptop`
  - `~/.config/waybar/style/[Dark] Latte-Wallust combined.css`
- `swaync`: notification config and style.
- `kitty`, `nvim`, `tmux`: app-specific config.

The repo-level `.stowrc` targets `~`, so stow commands can be run from the repo root without passing `--target`.

## Bootstrap

Install Arch and the Hyprland base first:

```bash
git clone https://github.com/LinuxBeginnings/Arch-Hyprland.git
git clone https://github.com/LinuxBeginnings/Hyprland-Dots.git
```

Run the upstream installers according to those repos. After the upstream config exists, install this user layer:

```bash
cd ~/dev/dotfiles
stow --adopt hypr waybar swaync kitty nvim tmux
git restore .
```

`--adopt` is useful on a live machine because it moves existing matching files into the repo and replaces them with symlinks. `git restore .` then puts the repo contents back to the committed source of truth. On a fresh machine where the target files do not exist, plain stow is enough:

```bash
cd ~/dev/dotfiles
stow hypr waybar swaync kitty nvim tmux
```

After stowing the Hyprland layer, apply the local post-upstream preferences (or just reboot):

```bash
~/.config/hypr/UserScripts/ApplyUserPreferences.sh
hyprctl reload
pkill -SIGUSR2 waybar || hyprctl dispatch exec waybar
swaync-client --reload-css
```

## Hyprland-Dots Updates

Hyprland and Hyprland-Dots move quickly, especially on Arch. Treat updates as a rebase of this user layer onto upstream:

```bash
cd ~/Hyprland-Dots
git pull --ff-only
```

Run the upstream update process from `Hyprland-Dots`, then re-apply this dotfiles layer:

```bash
cd ~/dev/dotfiles
stow --adopt hypr waybar swaync kitty
git diff
git restore .
~/.config/hypr/UserScripts/ApplyUserPreferences.sh
hyprctl reload
pkill -SIGUSR2 waybar || hyprctl dispatch exec waybar
swaync-client --reload-css
```

## Add A New Stow Package

Use one package per app or concern. The package path must mirror the path under `$HOME`.

Add one `~/.local/bin` script:

```bash
cd ~/dev/dotfiles
mkdir -p local-bin/.local/bin
cp -a ~/.local/bin/git-worktree-helper.sh local-bin/.local/bin/
stow -nv local-bin
stow local-bin
git add local-bin README.md
git diff --cached
```

Add `~/.bash_aliases` as a stowed shell package:

```bash
cd ~/dev/dotfiles
mkdir -p shell
cp -a ~/.bash_aliases shell/.bash_aliases
stow -nv shell
stow --adopt shell
git diff
git restore shell/.bash_aliases
git add shell README.md
git diff --cached
```

Adopt an existing config directory:

```bash
cd ~/dev/dotfiles
mkdir -p rofi/.config
cp -a ~/.config/rofi rofi/.config/
stow -nv rofi
stow --adopt rofi
git diff
git restore rofi
git add rofi README.md
git diff --cached
```

Use `stow -nv <package>` before the real stow command. If the dry run shows files outside the package you expected, stop and fix the package layout first.

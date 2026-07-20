# SDDM

This package keeps the mutable settings for the upstream `simple_sddm_2` theme
in the dotfiles repository. SDDM loads its theme as a system service, so do not
Stow its files directly into `/usr/share`: the `sddm` user cannot traverse the
private home directory that contains this repository.

Stow the package to install the managed source and deploy helper:

```bash
stow sddm
```

Deploy the selected login background and theme settings to the installed SDDM
theme (requires `sudo`):

```bash
deploy-sddm-theme
```

The default background is `~/Pictures/wallpapers/Lofi-Cafe1.png`. To use a
different image for one deployment, pass its path:

```bash
deploy-sddm-theme /path/to/background.png
```

The theme is configured to use `Backgrounds/default`, which also restores
compatibility with Hyprland-Dots' SDDM wallpaper updater.

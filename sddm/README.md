# SDDM

This package keeps the mutable settings for the upstream `simple_sddm_2` theme
in the dotfiles repository. SDDM loads its theme as a system service, so do not
Stow its files directly into `/usr/share`: the `sddm` user cannot traverse the
private home directory that contains this repository.

Stow the package to install the managed source and deploy helper:

```bash
stow sddm
```

Deploy the theme settings to the installed SDDM theme (requires `sudo`):

```bash
deploy-sddm-theme
```

The preserved login background is the theme's `Backgrounds/mountain.png`.
The managed `theme.conf` pins that image explicitly.

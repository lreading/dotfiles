# Tmux Dotfiles

This package owns:

- `~/.tmux.conf`
- `~/.config/tmux/catppuccin-custom/*.sh` and `*.conf`

The local IP scripts and optional module definitions are kept under
`~/.config/tmux` so Stow does not write into the TPM-managed Catppuccin checkout.

## Fresh Install

Install tmux and TPM:

```bash
sudo pacman -S tmux inetutils
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Stow this package:

```bash
cd ~/dev/dotfiles
stow -nv tmux
stow tmux
```

Install the plugins listed in `.tmux.conf`, including `catppuccin/tmux#v2.3.0`:

```bash
~/.tmux/plugins/tpm/bin/install_plugins
```

This works before starting tmux. If tmux is already running, `prefix + I`
also installs missing plugins; the prefix here is `C-Space`. Installing TPM
alone does not install Catppuccin. Its files must exist at
`~/.tmux/plugins/tmux/catppuccin_options_tmux.conf` and
`~/.tmux/plugins/tmux/catppuccin_tmux.conf` before the theme can load.

Start tmux, or reload an existing server after installing plugins:

```bash
tmux source-file ~/.tmux.conf
```

The config uses `source-file -q` for the theme, so initial startup does not
fail while the plugin is still missing. If Catppuccin is not visible after
installation, check that both files above exist and reload again.

## IP scripts and optional modules

The `prefix + g` menu resolves both IP addresses with the Stowed scripts before
it opens, so the first display has their values. The `prefix + P`/`prefix + R`
bindings call those scripts when copying an address. The `pub_ip.conf` and
`priv_ip.conf` files are optional Catppuccin status modules; the current config
does not source or display them.
Catppuccin does not automatically load files from this directory.

Current scripts:

- `pub_ip`: public IP via `curl` or `wget`, with a short timeout.
- `priv_ip`: primary local IP from the default outbound route, with `hostname -I` and `ifconfig` fallbacks.

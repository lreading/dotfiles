# Tmux Dotfiles

This package owns:

- `~/.tmux.conf`
- `~/.config/tmux/catppuccin-custom/*.sh`

The Catppuccin modules are kept under `~/.config/tmux` instead of `~/.tmux/plugins/tmux/custom` so Stow does not write into a TPM-managed plugin checkout.

## Fresh Install

Install tmux and TPM:

```bash
sudo pacman -S tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Stow this package:

```bash
cd ~/dev/dotfiles
stow -nv tmux
stow tmux
```

Start tmux, then install plugins with `prefix + I`. The prefix here is `C-Space`.

Reload tmux after plugins install:

```bash
tmux source-file ~/.tmux.conf
```

## Catppuccin Custom Modules

`~/.tmux.conf` sets:

```tmux
set -gF @catppuccin_custom_plugin_dir "#{E:HOME}/.config/tmux/catppuccin-custom"
```

`set -gF` expands `$HOME` through tmux format expansion, so the config works across users and machines.

Current modules:

- `pub_ip`: public IP via `curl` or `wget`, with a short timeout.
- `priv_ip`: primary local IP from the default outbound route, with `hostname -I` and `ifconfig` fallbacks.

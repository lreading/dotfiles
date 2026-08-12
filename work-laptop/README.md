# work-laptop

Docked workstation behavior for this laptop:

- pins workspaces 1-10 and the scratchpad to the ASUS ultrawide by monitor
  description, not by transient `DP-*` name
- keeps the ultrawide at `3840x1080@143.855`, scale `1`
- keeps the laptop panel fallback at `preferred`, scale `1.33`
- disables `eDP-1` when the ultrawide is connected and AC/USB power is online
- blocks lid-switch sleep while external power is online, including during KVM
  switches when the monitor and USB devices briefly disappear
- restores normal lid behavior on battery
- disables Wi-Fi while Ethernet is connected, and re-enables Wi-Fi when
  Ethernet is disconnected
- provides a manual Astro MixAmp hub-port reset command

Install home-managed files from the repo root:

```bash
stow work-laptop
hyprctl reload
```

Install the optional manual Astro reset helper:

```bash
sudo install -Dm755 work-laptop/system/usr/local/sbin/work-laptop-reset-astro-usb /usr/local/sbin/work-laptop-reset-astro-usb
```

The shared Hyprland startup config loads `work_laptop.lua` when this package is
installed. Its helper scripts start automatically on the next Hyprland login.
The Turnkey aliases are loaded from the package-specific Bash alias fragment;
the shared `~/.bash_aliases` remains usable on non-work systems.

If the Astro MixAmp is missing after using the hub power button, run:

```bash
work-laptop-reset-astro
```

# work-laptop

Docked workstation behavior for this laptop:

- pins workspaces 1-10 and the scratchpad to the ASUS ultrawide by monitor
  description, not by transient `DP-*` name
- keeps the ultrawide at `3840x1080@143.855`, scale `1`
- keeps the laptop panel fallback at `preferred`, scale `1.33`
- disables `eDP-1` and blocks lid-switch sleep only when the ultrawide is
  connected and AC/USB power is online
- restores normal laptop-panel behavior when undocked or on battery
- disables Wi-Fi while Ethernet is connected, and re-enables Wi-Fi when
  Ethernet is disconnected

Install from the repo root:

```bash
stow work-laptop
hyprctl reload
```

The helper scripts are started by `exec-once` from `workspaces.conf`, so they
start automatically on the next Hyprland login.

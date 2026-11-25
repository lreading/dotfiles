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
- switches active audio streams to newly connected physical outputs, including
  the Framework Audio Expansion Card and the desktop USB audio adapter; the
  Astro MixAmp outputs remain available to apps but do not take the default
  when they connect
- provides a manual Astro MixAmp hub-port reset command

Install home-managed files from the repo root:

```bash
stow work-laptop
hyprctl reload
systemctl --user restart pipewire-pulse.service
```

Install the optional manual Astro reset helper:

```bash
sudo install -Dm755 work-laptop/system/usr/local/sbin/work-laptop-reset-astro-usb /usr/local/sbin/work-laptop-reset-astro-usb
```

The shared Hyprland startup config loads `work_laptop.lua` when this package is
installed. Its helper scripts start automatically on the next Hyprland login.
After stowing this package, run `hypr-overlays-apply` to select its Waybar
workspace wrapper. It shows workspaces 1-10 and includes the shared layout;
other laptops keep the shared workspace count and module-loading order.
The work-only startup helper detects the ASUS external display by its monitor
description and selects one of two application layouts:

- Desktop mode preserves the existing layout exactly: the Default/Work Vivaldi
  profile and `tkhq` Kitty share workspace 10, the Personal Vivaldi profile and
  `personal` Kitty share workspace 8, and Slack uses workspace 9.
- Laptop mode uses `tkhq` Kitty on workspace 1, Default/Work Vivaldi on
  workspace 2, Personal Vivaldi on workspace 4, `personal` Kitty on workspace
  5, and Slack on workspace 10.

The dock watcher reapplies these targets when the external display is connected
or removed. It moves Vivaldi windows only from their established workspace in
the previous profile; it never guesses profile identity from titles or closes a
browser window.

The `tkhq` session defaults new windows to `~/`, while its initial `notes`
window explicitly changes to `~/notes/` before starting Neovim. Pane splits
continue to inherit the active pane's working directory. The personal-laptop
workspace 1/2 and `~/TODO.md` startup does not apply.

At a clean login, the helper restores the Default/Work Vivaldi profile and then
the Personal (`Profile 1`) profile on the workspaces selected above. In desktop
mode, each Vivaldi window is placed left of its Kitty window. The launches are
sequential and start only when no Vivaldi window already exists, because Vivaldi
uses one process for multiple profiles and Hyprland cannot otherwise identify a
window's profile reliably. Existing browser windows are never reclassified or
moved.

The work package also installs `vivaldi-work.desktop`; startup registers it for
HTTP, HTTPS, and HTML so external links always target Vivaldi's Default/Work
profile rather than the most recently used profile.
The Turnkey aliases are loaded from the package-specific Bash alias fragment;
the shared `~/.bash_aliases` remains usable on non-work systems.

If the Astro MixAmp is missing after using the hub power button, run:

```bash
work-laptop-reset-astro
```

## Keychron Q11 macro keys

The work package maps the Q11's dedicated M1–M5 keys to F13–F17 and binds
their Linux XKB symbols: XF86Tools and XF86Launch5 through XF86Launch8:

- M1 restores the captured lighting: brightness 16/255, solid color, #01ff19
- M2 cycles brightness upward in roughly 5% steps, wrapping from maximum to off
- M3 cycles all 23 VIA effects, including off, and wraps to the first
- M4 cycles red, yellow, green, cyan, blue, and magenta, preserving
  saturation and brightness
- M5 runs the existing user LockScreen.sh helper
- Ctrl+M2, Ctrl+M3, and Ctrl+M4 cycle backward

`work-keychron` uses Python's standard library and the existing VIA hidraw
access. It matches only USB 3434:01e0 and the VIA interface; when the Q11 is
absent it exits quietly. No background service or additional USB permission
rule is needed. RGB changes are live, without writing EEPROM on every press.
M1 restores the saved preference whenever needed.

The dedicated macro keys were mapped on both Mac and Windows base layers.
The Fn layers remain transparent. These mappings live in keyboard memory and
travel with it. To apply them again after a firmware reset, run
`work-keychron setup`. Their previous keycodes were 0x7703 through 0x7707
(VIA macro slots 3 through 7); other keys and stored macro contents are intact.
The laptop's built-in keyboard bindings and shared configs are unchanged.

The firmware reports nonzero brightness one below the value written. The
helper compensates for this; the effective maximum reported value is 254.

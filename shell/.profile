# Source interactive Bash setup for login shells.
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# Source /etc/profile to ensure system paths (e.g. flatpak) are available
if [ -f /etc/profile ]; then
    source /etc/profile
fi

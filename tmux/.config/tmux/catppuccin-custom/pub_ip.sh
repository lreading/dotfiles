# If this module depends on an external Tmux plugin, say so in a comment.
# E.g.: Requires https://github.com/aaronpowell/tmux-weather

show_pub_ip() { # This function name must match the module name!
  local index icon color text module ip_addr

  if command -v curl >/dev/null 2>&1; then
    ip_addr=$(curl -fsS --max-time 2 https://icanhazip.com 2>/dev/null)
  elif command -v wget >/dev/null 2>&1; then
    ip_addr=$(wget -qO- -T 2 https://icanhazip.com 2>/dev/null)
  else
    ip_addr=""
  fi

  if [ -z "$ip_addr" ]; then
    ip_addr="offline"
  fi

  index=$1 # This variable is used internally by the module loader in order to know the position of this module
  icon="$(  get_tmux_option "@catppuccin_pub_ip_icon"  ""           )"
  color="$( get_tmux_option "@catppuccin_pub_ip_color" "$thm_red" )"
  text="$(  get_tmux_option "@catppuccin_pub_ip_text"  "$ip_addr" )"

  module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}

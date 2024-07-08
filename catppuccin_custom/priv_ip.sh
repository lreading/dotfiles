# If this module depends on an external Tmux plugin, say so in a comment.
# E.g.: Requires https://github.com/aaronpowell/tmux-weather

show_priv_ip() { # This function name must match the module name!
  local index icon color text module ip_addr

  ip_addr=$(ip addr show enp46s0f0 | grep -w inet | awk '{print $2}' | cut -d/ -f1)

  index=$1 # This variable is used internally by the module loader in order to know the position of this module
  icon="$(  get_tmux_option "@catppuccin_priv_ip_icon"  "󰱓"           )"
  color="$( get_tmux_option "@catppuccin_priv_ip_color" "$thm_blue" )"
  text="$(  get_tmux_option "@catppuccin_priv_ip_text"  "$ip_addr" )"

  module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}


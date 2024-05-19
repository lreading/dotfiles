# If this module depends on an external Tmux plugin, say so in a comment.
# E.g.: Requires https://github.com/aaronpowell/tmux-weather

show_pub_ip() { # This function name must match the module name!
  local index icon color text module ip_addr

  ip_addr=$(curl icanhazip.com)

  index=$1 # This variable is used internally by the module loader in order to know the position of this module
  icon="$(  get_tmux_option "@catppuccin_pub_ip_icon"  ""           )"
  color="$( get_tmux_option "@catppuccin_pub_ip_color" "$thm_red" )"
  text="$(  get_tmux_option "@catppuccin_pub_ip_text"  "$ip_addr" )"

  module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}


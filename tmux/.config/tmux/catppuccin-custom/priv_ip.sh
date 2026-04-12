# If this module depends on an external Tmux plugin, say so in a comment.
# E.g.: Requires https://github.com/aaronpowell/tmux-weather

show_priv_ip() { # This function name must match the module name!
  local index icon color text module ip_addr

  ip_addr=$(
    ip route get 1.1.1.1 2>/dev/null | awk '
      {
        for (i = 1; i <= NF; i++) {
          if ($i == "src") {
            print $(i + 1)
            exit
          }
        }
      }'
  )

  if [ -z "$ip_addr" ]; then
    ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi

  if [ -z "$ip_addr" ]; then
    ip_addr=$(
      ifconfig 2>/dev/null | awk '
        $1 == "inet" && $2 != "127.0.0.1" {
          print $2
          exit
        }'
    )
  fi

  if [ -z "$ip_addr" ]; then
    ip_addr="offline"
  fi

  index=$1 # This variable is used internally by the module loader in order to know the position of this module
  icon="$(  get_tmux_option "@catppuccin_priv_ip_icon"  "󰱓"           )"
  color="$( get_tmux_option "@catppuccin_priv_ip_color" "$thm_blue" )"
  text="$(  get_tmux_option "@catppuccin_priv_ip_text"  "$ip_addr" )"

  module=$( build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}

#!/bin/sh

# Function to get the default sink
get_default_sink() {
    pactl get-default-sink
}

USER="leo"
DISPLAY=:0
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USER)/bus"

#DBUS_SESSION_BUS_ADDRESS=$(dbus-launch | grep -E 'DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2-)

case "$1" in
    button/volumeup)
        DEFAULT_SINK=$(get_default_sink)
        pactl set-sink-volume "$DEFAULT_SINK" +10%
        killall -SIGUSR1 i3status
        ;;
    button/volumedown)
        DEFAULT_SINK=$(get_default_sink)
        pactl set-sink-volume "$DEFAULT_SINK" -10%
        killall -SIGUSR1 i3status
        ;;
    button/mute)
        DEFAULT_SINK=$(get_default_sink)
        pactl set-sink-mute "$DEFAULT_SINK" toggle
        killall -SIGUSR1 i3status
        ;;
    video/brightnessup)
	# Not working, not really needed tho
        xbacklight -inc 10
        ;;
    video/brightnessdown)
	# Not working, not really needed tho
        xbacklight -dec 10
        ;;
    cd/play)
	#su -1 leo -c "playerctl play-pause"
        sudo -u $USER DISPLAY=$DISPLAY DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS playerctl play-pause
	;;
    cd/prev)
        sudo -u $USER DISPLAY=$DISPLAY DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS playerctl previous
	;;
    cd/next)
        sudo -u $USER DISPLAY=$DISPLAY DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS playerctl next
	;;
    *)
        logger "ACPI action $1 is not defined"
        ;;
esac


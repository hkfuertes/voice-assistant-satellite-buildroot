#!/bin/sh

MAX_VOLUME=100

# Get current volume in %
current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')

if [ "$1" == "up" ]; then
    if [ "$current_vol" -lt "$MAX_VOLUME" ]; then
        pactl set-sink-volume @DEFAULT_SINK@ +5%
    else
        echo "Volume is already at maximum ($MAX_VOLUME%)"
    fi
elif [ "$1" == "down" ]; then
    pactl set-sink-volume @DEFAULT_SINK@ -5%
elif [ "$1" == "mute" ]; then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
else
    echo "Usage: $0 [up|down|mute]"
fi

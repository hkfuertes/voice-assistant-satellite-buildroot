#!/bin/sh
# ReSpeaker 2-Mic HAT v1 ALSA configuration

CARD="wm8960soundcard"

# Wait for card to be ready
sleep 2

# Check if card exists
if ! aplay -l | grep -q "$CARD"; then
    echo "Error: $CARD not found"
    exit 1
fi

amixer cset numid=1 30,30      # Capture Volume
amixer cset numid=9 3          # Left Input Boost (+29dB)
amixer cset numid=8 3          # Right Input Boost (+29dB)
amixer cset numid=36 195,195   # ADC PCM Capture
amixer cset numid=19 1         # High-Pass Filter ON

# Save state
alsactl store 2>/dev/null

echo "ReSpeaker 2-Mic HAT v1 configured"
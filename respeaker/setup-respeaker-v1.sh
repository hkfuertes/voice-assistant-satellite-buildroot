#!/bin/bash
# ReSpeaker 2-Mic HAT v1 ALSA configuration

CARD="wm8960soundcard"

# Wait for card to be ready
sleep 2

# Capture controls
amixer -c "$CARD" sset 'Capture' 100% unmute cap 2>/dev/null
amixer -c "$CARD" sset 'ADC PCM' 195 2>/dev/null

# Input boost
amixer -c "$CARD" sset 'Left Input Mixer Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Right Input Mixer Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Left Input PGA Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Right Input PGA Boost' on 2>/dev/null

# Input routing
amixer -c "$CARD" sset 'Left Input' 'MIC2' 2>/dev/null
amixer -c "$CARD" sset 'Right Input' 'MIC2' 2>/dev/null

# Playback
amixer -c "$CARD" sset 'Playback' 100% unmute 2>/dev/null
amixer -c "$CARD" sset 'Speaker' 100% unmute 2>/dev/null

# Save state
alsactl store 2>/dev/null

echo "ReSpeaker 2-Mic HAT v1 configured"

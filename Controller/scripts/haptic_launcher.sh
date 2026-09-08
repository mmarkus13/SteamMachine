#!/bin/bash

# Play the MIDI file in the background with a strict 10-second ceiling
timeout 10s /home/deck/Music/sounds/steam-haptics-singer1305 /home/deck/Music/sounds/controller_Mortal_Kombat.mid > /dev/null 2>&1 &
HAPTIC_PID=$!

# Launch the game immediately
"$@" &
GAME_PID=$!

# Wait for the game to close, then aggressively clean up any lingering haptic audio loop
wait $GAME_PID
kill -9 $HAPTIC_PID 2>/dev/null
pkill -f steam-haptics-singer1305 2>/dev/null
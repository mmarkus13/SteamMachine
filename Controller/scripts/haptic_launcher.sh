#!/bin/bash

# Default song path if no custom argument is passed
DEFAULT_MIDI="/home/deck/Music/sounds/controller_Mortal_Kombat.mid"
MIDI_FILE="$DEFAULT_MIDI"

# Parse arguments to look for a custom flag (e.g., --s "path/to/song.mid")
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --s) MIDI_FILE="$2"; shift ;;
    es:
    shift
done

# Play the selected MIDI file in the background with a 10-second timeout safeguard
timeout 10s /home/deck/Music/sounds/steam-haptics-singer1305 "$MIDI_FILE" > /dev/null 2>&1 &
HAPTIC_PID=$!

# Launch the actual game immediately via Steam's %command%
"$@" &
GAME_PID=$!

# Ensure cleanup happens when the game closes
wait $GAME_PID
kill -9 $HAPTIC_PID 2>/dev/null
pkill -f steam-haptics-singer1305 2>/dev/null

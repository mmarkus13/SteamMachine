#!/usr/bin/env python3
import subprocess
import sys
import os

# Paths to your binary and the default song passed via argument
BINARY_PATH = "/usr/local/bin/steam-haptics-singer"
DEFAULT_MIDI = "/usr/local/share/midi/slim_shady.mid"

def main():
    # Use the argument passed from Steam launch options if available, else default
    midi_file = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MIDI

    if not os.path.exists(BINARY_PATH):
        sys.exit(0) # Fail silently so game launch isn't disrupted
        
    if not os.path.exists(midi_file):
        sys.exit(0)

    try:
        # Run the binary. 
        # Using subprocess.Popen ensures it fires asynchronously and detaches.
        subprocess.Popen(
            [BINARY_PATH, midi_file],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        # Suppress any unexpected system execution errors
        pass

if __name__ == "__main__":
    main()
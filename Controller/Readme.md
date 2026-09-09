# Steam Controller Haptic Music & Launch Integration

A toolkit and automation pipeline designed to transform the Steam Controller into a polyphonic music player for boot-up sequences, game launch events, and haptic testing on SteamOS.

---

## Features

* **Haptic Sound Synthesis:** Utilize the Steam Controller's trackpads as a polyphonic haptic synthesizer via `steam-haptics-singer`.
* **Wireless Puck Support:** Native configuration support for the wireless Steam Controller Puck (`0x1305` receiver mapping) alongside direct USB-C connectivity.
* **MIDI Filtering & Auto-Transposition:** Python-based scanning tools to pre-filter and automatically shift MIDI files into the controller's optimal haptic sweet spot (**MIDI notes 48 to 72 / 100 Hz–800 Hz**).
* **Game Launch Automation:** Background wrapper scripts designed for Steam Launch Options to trigger haptic themes cleanly upon game startup without blocking game execution.

---

## Directory Structure

```text
Controller/
├── steam-haptics-singer1305   # Compiled haptic binary with Puck support
├── filter_midis.py            # MIDI range scanner and filtering utility
├── fix_midis.py               # Automated note transposition and clamping script
└── haptic_launcher.sh         # Background execution & timeout wrapper script
```

---

## Quick Start Guide

### 1. Filter and Optimize Your MIDI Files
Run the automated range checker and transposer to format MIDI files into the controller's safe frequency zone:
```bash
python3 fix_midis.py
```

### 2. Configure Game Launch Integration
To play a custom haptic track seamlessly on launch, use the background wrapper script (`haptic_launcher.sh`) inside your Steam Launch Options:

```bash
/home/deck/.local/bin/haptic_launcher.sh %command%
```
or you can also set different song via `--s` parameter:
```bash
/home/deck/.local/bin/haptic_launcher.sh --s slim_shady.mid %command%
```

---
#note:
```
The haptic_launcher.sh is set to play only the first 10 seconds of your midi file - feel free to change that.
To immediately cancel sounds hit 'Steam + B' buttons on your controller - which also closes the game.
```
---

## Requirements & Dependencies

* **Operating System:** SteamOS / Linux (Arch-based environment)
* **Libraries:** `mido` (Python), `libusb`, `hidapi` (for compilation)
* **Hardware:** Steam Controller (connected via USB-C or the official wireless Puck receiver)

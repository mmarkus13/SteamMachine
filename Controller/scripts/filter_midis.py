import os
import mido

# Define the Steam Controller's safe sweet spot (MIDI note numbers)
MIN_SAFE_NOTE = 48  # C3
MAX_SAFE_NOTE = 72  # C5

midi_folder = "./midi_files"  # Change to your folder path

print(f"Scanning folder: {midi_folder}\n")
print(f"{'File Name':<30} | {'Min Note':<10} | {'Max Note':<10} | {'Status'}")
print("-" * 70)

for filename in os.listdir(midi_folder):
    if filename.endswith(".mid") or filename.endswith(".midi"):
        filepath = os.path.join(midi_folder, filename)
        try:
            mid = mido.MidiFile(filepath)
            notes = []

            # Extract all note_on events across all tracks
            for track in mid.tracks:
                for msg in track:
                    if msg.type == 'note_on' and msg.velocity > 0:
                        notes.append(msg.note)

            if not notes:
                print(f"{filename[:30]:<30} | {'N/A':<10} | {'N/A':<10} | Empty / Drum track")
                continue

            min_note = min(notes)
            max_note = max(notes)

            # Evaluation criteria
            if min_note >= MIN_SAFE_NOTE and max_note <= MAX_SAFE_NOTE:
                status = "🟢 Perfect Sweet Spot"
            elif min_note < 36 or max_note > 84:
                status = "🔴 Out of Range (Too high/low)"
            else:
                status = "🟡 Marginally wide range"

            print(f"{filename[:30]:<30} | {min_note:<10} | {max_note:<10} | {status}")

        except Exception as e:
            print(f"{filename[:30]:<30} | Error parsing file")

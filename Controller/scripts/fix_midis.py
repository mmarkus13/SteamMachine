import os
import mido

MIN_SAFE = 48  # C3
MAX_SAFE = 72  # C5
input_dir = "./midi_files"
output_dir = "./midi_fixed"

os.makedirs(output_dir, exist_ok=True)

for filename in os.listdir(input_dir):
    if filename.endswith(".mid") or filename.endswith(".midi"):
        filepath = os.path.join(input_dir, filename)
        
        try:
            mid = mido.MidiFile(filepath)
            
            notes = [msg.note for track in mid.tracks for msg in track if msg.type == 'note_on' and msg.velocity > 0]
            if not notes:
                print(f"Skipping {filename}: No notes found or empty track.")
                continue
                
            min_note, max_note = min(notes), max(notes)
            
            # Calculate transposition shift needed to fit the sweet spot
            shift = 0
            if min_note < MIN_SAFE:
                shift = MIN_SAFE - min_note  # Shift up
            elif max_note > MAX_SAFE:
                shift = MAX_SAFE - max_note  # Shift down
                
            # If it's too wildly out of range (more than 24 semitones / 2 octaves), skip it
            if abs(shift) > 24:
                print(f"Skipping {filename}: Too wide to auto-fix (shift: {shift}).")
                continue
                
            # Apply transposition across all tracks
            for track in mid.tracks:
                for msg in track:
                    if hasattr(msg, 'note') and msg.type in ['note_on', 'note_off']:
                        msg.note += shift
                        # Clamp just in case a stray note slips past
                        msg.note = max(0, min(127, msg.note))
                        
            # Save the optimized file
            new_path = os.path.join(output_dir, f"controller_{filename}")
            mid.save(new_path)
            print(f"Optimized & Saved: {filename} (Shifted by {shift} semitones)")
            
        except Exception as e:
            print(f"⚠️ Skipping corrupted or incompatible file: {filename} ({e})")

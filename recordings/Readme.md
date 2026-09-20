# SteamOS "ShadowPlay" Instant Replay Setup

A complete guide to replicating Nvidia ShadowPlay's **Instant Replay** feature on SteamOS. This setup allows you to save the last X minutes of gameplay via a controller shortcut, automatically convert raw MPEG-DASH chunks into clean MP4 files named by game title, and run automated weekly cleanup/archiving.

---

## 1. Controller Trigger Setup (Steam Input)

Instead of complex keyboard combinations, use Steam Input's native clip action to trigger instant replays across any game.

1. Open **Controller Settings** for your target game or Desktop layout.
2. Select **Edit Layout** $\rightarrow$ **Buttons** (or **Extended Buttons** for back paddles like R4/L5).
3. Choose your desired button, add a command, and navigate to the **System** tab.
4. Select **Create Clip**.
5. Click the gear icon next to the command:
   * **Activation Type:** Long Press (e.g., 2000 ms)
   * **Haptics:** Medium or High (provides tactile feedback when the clip saves)

---

## 2. Export & Maintenance Script (`manage_clips.sh`)

Steam stores Game Recordings as fragmented MPEG-DASH files (`session.mpd`). This script locates finalized clips, resolves the game title from local Steam app manifests, converts them into single `.mp4` files in `~/Videos/`, and manages old recordings.

Create `~/.local/share/Steam/manage_clips.sh`:

```bash
#!/bin/bash
# manage_clips.sh - Batch export Steam clips and clean up old recordings

USERDATA_DIR="$HOME/.local/share/Steam/userdata"
VIDEOS_DIR="$HOME/Videos"
ARCHIVE_DIR="$VIDEOS_DIR/Archive"

mkdir -p "$VIDEOS_DIR" "$ARCHIVE_DIR"

notify-send "Steam Clip Exporter" "Processing saved clips..." -i video-x-generic

echo "=== [1/3] Processing Unexported Clips ==="
find "$USERDATA_DIR" -type f -name "session.mpd" 2>/dev/null | grep "/gamerecordings/clips/" | while read -r mpd_file; do
    clip_dir=$(dirname "$mpd_file")
    case "$clip_dir" in
        */video*) clip_root=$(dirname "$clip_dir") ;;
        *) clip_root="$clip_dir" ;;
    esac

    folder_name=$(basename "$clip_root")
    appid=$(echo "$folder_name" | cut -d'_' -f2)
    raw_date=$(echo "$folder_name" | cut -d'_' -f3)
    raw_time=$(echo "$folder_name" | cut -d'_' -f4)

    if [ -n "$appid" ] && [ -n "$raw_date" ]; then
        formatted_time="${raw_date:0:4}-${raw_date:4:2}-${raw_date:6:2}_${raw_time:0:2}-${raw_time:2:2}-${raw_time:4:2}"
    else
        formatted_time=$(date +"%Y-%m-%d_%H-%M-%S")
    fi

    game_name="App_${appid}"
    manifest=$(find "$HOME/.local/share/Steam/steamapps" /run/media/ -name "appmanifest_${appid}.acf" 2>/dev/null | head -n 1)
    if [ -n "$manifest" ] && [ -f "$manifest" ]; then
        found_name=$(grep -i '"name"' "$manifest" | head -n 1 | cut -d '"' -f 4)
        [ -n "$found_name" ] && game_name=$(echo "$found_name" | sed 's/[^a-zA-Z0-9 _-]/_/g')
    fi

    output_file="${VIDEOS_DIR}/${game_name}_${formatted_time}.mp4"

    if [ ! -f "$output_file" ]; then
        echo "Exporting: $game_name ($formatted_time)..."
        ffmpeg -hide_banner -loglevel error -i "$mpd_file" -c copy "$output_file"
    fi
done

echo "=== [2/3] Archiving Raw Clips Older Than 30 Days ==="
find "$USERDATA_DIR" -type d -name "clip_*" -mtime +30 2>/dev/null | while read -r old_clip; do
    echo "Archiving: $(basename "$old_clip")"
    mv "$old_clip" "$ARCHIVE_DIR/" 2>/dev/null
done

echo "=== [3/3] Deleting Archives Older Than 90 Days ==="
find "$ARCHIVE_DIR" -mindepth 1 -mtime +90 -exec rm -rf {} + 2>/dev/null

echo "=== Maintenance Complete ==="
notify-send "Steam Clip Exporter" "Maintenance complete! Videos exported to ~/Videos." -i video-x-generic
```

Make the script executable:

```bash
chmod +x ~/.local/share/Steam/manage_clips.sh
```

---

## 3. Automated Weekly Execution (Systemd Timer)

Since SteamOS lacks `crontab` by default, systemd user timers provide reliable background scheduling. The `Persistent=true` directive ensures that if the Steam Machine is powered off during the scheduled run time, the job executes automatically on the next boot.

### Step A: Worker Service
Create `~/.config/systemd/user/manage-clips.service`:

```ini
[Unit]
Description=Weekly Steam Clips Maintenance Worker

[Service]
Type=oneshot
ExecStart=/bin/bash %h/.local/share/Steam/manage_clips.sh
```

### Step B: Scheduled Timer
Create `~/.config/systemd/user/manage-clips.timer`:

```ini
[Unit]
Description=Run manage_clips.sh weekly

[Timer]
OnCalendar=Sun *-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### Step C: Enable Timer

```bash
systemctl --user daemon-reload
systemctl --user enable --now manage-clips.timer
```

---

## 4. On-Demand Desktop Shortcut

Create a double-clickable Desktop shortcut for manual export triggers in Desktop Mode.

Create `~/Desktop/Export_Clips.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Export Steam Clips
Comment=Export pending Steam clips to MP4 and clean up old recordings
Exec=/home/deck/.local/share/Steam/manage_clips.sh
Icon=video-x-generic
Terminal=false
Categories=Utility;AudioVideo;
```

Make the shortcut executable:

```bash
chmod +x ~/Desktop/Export_Clips.desktop
```

---

## Workflow Overview

1. **In-Game:** Hold your assigned controller button to trigger `System -> Create Clip`.
2. **Automatic Background Processing:** `manage-clips.timer` runs weekly (or immediately on next boot if missed), remuxes all saved clips into `/home/deck/Videos/`, archives clips over 30 days old, and purges archives over 90 days old.
3. **Manual Run:** Double-click **Export Steam Clips** on the Desktop at any time to export pending clips on demand with desktop notifications.

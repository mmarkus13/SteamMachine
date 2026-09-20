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
#!/bin/bash
# uninstall.sh - Clean removal of SteamOS Clip Exporter & Maintenance Setup

set -e

STEAM_DIR="$HOME/.local/share/Steam"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
DESKTOP_DIR="$HOME/Desktop"

echo "=== [1/3] Stopping and Disabling Systemd Timer ==="
systemctl --user stop manage-clips.timer manage-clips.service 2>/dev/null || true
systemctl --user disable manage-clips.timer 2>/dev/null || true

echo "=== [2/3] Removing Installed Files ==="
rm -f "${SYSTEMD_USER_DIR}/manage-clips.service"
rm -f "${SYSTEMD_USER_DIR}/manage-clips.timer"
rm -f "${STEAM_DIR}/manage_clips.sh"
rm -f "${DESKTOP_DIR}/Export_Clips.desktop"

echo "=== [3/3] Reloading Systemd Daemon ==="
systemctl --user daemon-reload

echo ""
echo "=== Uninstallation Complete! ==="
echo "All scripts, desktop shortcuts, and systemd timers have been removed."
echo "Note: Your exported video files in ~/Videos/ were left untouched."
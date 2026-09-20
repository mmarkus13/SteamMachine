#!/bin/bash
# install.sh - One-click installer for SteamOS Clip Exporter & Maintenance Setup

set -e

REPO_RAW_URL="https://raw.githubusercontent.com/mmarkus13/SteamMachine/tree/main/recordings/install.sh"

VIDEOS_DIR="$HOME/Videos"
STEAM_DIR="$HOME/.local/share/Steam"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
DESKTOP_DIR="$HOME/Desktop"

echo "=== [1/4] Creating Directory Structure ==="
mkdir -p "$VIDEOS_DIR" "$STEAM_DIR" "$SYSTEMD_USER_DIR" "$DESKTOP_DIR"

echo "=== [2/4] Downloading Scripts & Unit Files ==="
curl -sSL "${REPO_RAW_URL}/manage_clips.sh" -o "${STEAM_DIR}/manage_clips.sh"
curl -sSL "${REPO_RAW_URL}/manage-clips.service" -o "${SYSTEMD_USER_DIR}/manage-clips.service"
curl -sSL "${REPO_RAW_URL}/manage-clips.timer" -o "${SYSTEMD_USER_DIR}/manage-clips.timer"
curl -sSL "${REPO_RAW_URL}/Export_Clips.desktop" -o "${DESKTOP_DIR}/Export_Clips.desktop"

echo "=== [3/4] Configuring Executable Permissions ==="
chmod +x "${STEAM_DIR}/manage_clips.sh"
chmod +x "${DESKTOP_DIR}/Export_Clips.desktop"

echo "=== [4/4] Enabling Background Systemd Timer ==="
systemctl --user daemon-reload
systemctl --user enable --now manage-clips.timer

echo ""
echo "=== Installation Complete! ==="
echo "Desktop runner: ~/Desktop/Export_Clips.desktop"
echo "Weekly timer status: Active (systemctl --user list-timers manage-clips.timer)"
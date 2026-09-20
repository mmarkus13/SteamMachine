# SteamOS "ShadowPlay" Instant Replay Setup

A complete solution to replicate Nvidia ShadowPlay's **Instant Replay** feature on SteamOS. 

Save gameplay clips in-game with a custom controller shortcut, automatically batch-convert raw MPEG-DASH chunks (`session.mpd`) into single `.mp4` files with resolved Steam game titles, and manage storage with automated weekly archiving.

---

## 🚀 Quick Installation (One-Liner)

Open Konsole in Desktop Mode and run:

```bash
curl -sSL https://raw.githubusercontent.com/mmarkus13/SteamMachine/refs/heads/main/recordings/install.sh | bash
```

> **Note:** This installer runs entirely in user space—no root permissions (`sudo`) or disabling `steamos-readonly` required.

---

## 🎮 1. Controller Trigger Setup (Steam Input)

Configure Steam Input to map an in-game button or back paddle to trigger instant replay clips natively across games:

1. Open **Controller Settings** for your target game or Desktop Layout.
2. Select **Edit Layout** $\rightarrow$ **Buttons** (or **Extended Buttons** for back paddles like R4/L5).
3. Select your desired button, add a command, and navigate to the **System** tab.
4. Choose **Create Clip**.
5. Click the gear icon (Settings) next to the assigned command:
   * **Activation Type:** Set to `Long Press` (e.g., 2000 ms).
   * **Haptic Preference:** Set to `Medium` or `High` (provides tactile feedback when the clip saves).

---

## ⚙️ 2. How It Works

1. **In-Game Capture:** Pressing your mapped long-press shortcut causes Steam to finalize a raw clip directory inside `~/.local/share/Steam/userdata/<ID>/gamerecordings/clips/`.
2. **Automated Conversion:** The `manage_clips.sh` script scans for unexported clip manifests (`session.mpd`), parses the game's AppID against local Steam manifests (`appmanifest_<ID>.acf`) to find the actual game title, and losslessly remuxes them into `~/Videos/<Game_Name>_<Timestamp>.mp4`.
3. **Background Scheduling:** A systemd user timer (`manage-clips.timer`) executes weekly on Sundays at midnight. With `Persistent=true`, if the Steam Machine is powered off during that window, the job executes automatically upon next boot.
4. **Maintenance & Archiving:**
   * Raw clip folders older than **30 days** are moved to `~/Videos/Archive/`.
   * Archived clips older than **90 days** are automatically deleted to reclaim disk space.

---

## 🖥️ 3. On-Demand Desktop Runner

Double-click the **Export Steam Clips** shortcut on your Desktop at any time to run an immediate export scan. A system notification banner will notify you when processing begins and completes.

---

## 🗑️ Uninstallation

To remove all installed scripts, systemd units, and desktop shortcuts, run:

```bash
curl -sSL https://raw.githubusercontent.com/mmarkus13/SteamMachine/refs/heads/main/recordings/uninstall.sh | bash
```

*(Your exported `.mp4` video files in `~/Videos/` will remain untouched).*

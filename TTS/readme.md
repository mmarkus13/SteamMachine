# Piper TTS with Speech Dispatcher and Okular on SteamOS

This guide sets up local Piper text-to-speech voices on SteamOS using:

- [Pied](https://github.com/tschoonj/pied) — GUI for managing Piper voices
- Piper — local neural TTS engine
- Speech Dispatcher — system TTS interface
- Okular — PDF/ebook reader

The final setup allows Speech Dispatcher and Okular to use all installed Piper voices rather than being limited to a single voice.

---

# 1. Prerequisites

This guide assumes a **fresh SteamOS installation**.

You do not need to install Piper separately from the normal package repositories. We will use **Pied's bundled Piper installation and voice models**.

## 1.1 Install Pied

Pied is available as a Flatpak.

Open **Discover** on SteamOS and search for:

**Pied**

Install it.

Alternatively, if Flatpak is available from the terminal:

```bash
flatpak install flathub com.mikeasoft.pied
```

Start Pied once after installation.

---

# 2. Install Piper voices with Pied

Open Pied and install the voices you want.

For example, the following voices were used for this configuration:

### English

- `en_US-amy-low`
- `en_US-bryce-medium`
- `en_US-hfc_female-medium`
- `en_US-hfc_male-medium`
- `en_US-kristin-medium`

### Czech

- `cs_CZ-jirka-medium`

### Spanish

- `es_MX-claude-high`

### Hungarian

- `hu_HU-berta-medium`
- `hu_HU-imre-medium`

### Russian

- `ru_RU-ruslan-medium`

You do not need to install all of these.

The configuration below can be adapted to whatever voices are actually installed.

---

# 3. Verify that the Piper models exist

Pied normally stores its data under:

```text
~/.var/app/com.mikeasoft.pied/data/pied/
```

Check the installed models:

```bash
find ~/.var/app/com.mikeasoft.pied/data/pied/models \
  -maxdepth 1 -type f -name '*.onnx' \
  -printf '%f\n' | sort
```

You should see the voices you installed.

For example:

```text
en_US-amy-low.onnx
en_US-bryce-medium.onnx
en_US-hfc_female-medium.onnx
en_US-hfc_male-medium.onnx
en_US-kristin-medium.onnx
```

Also verify that the corresponding metadata files exist:

```bash
find ~/.var/app/com.mikeasoft.pied/data/pied/models \
  -maxdepth 1 -type f -name '*.onnx.json' \
  -printf '%f\n' | sort
```

---

# 4. Verify Speech Dispatcher

SteamOS normally already has Speech Dispatcher available.

Check:

```bash
speech-dispatcher --version
```

You should get a version number rather than `command not found`.

Also check:

```bash
spd-say --version
```

---

# 5. Create the Piper Speech Dispatcher helper

We use a small helper script instead of putting the complete Piper command directly into the Speech Dispatcher configuration.

This solves two important problems:

1. Speech Dispatcher can select the actual Piper model through `$VOICE`.
2. Different Piper models can use different sample rates.

For example, Amy uses 16000 Hz while the other models in this setup use 22050 Hz.

Create the helper:

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/piper-speechd <<'EOF'
#!/bin/bash

MODEL_DIR="$HOME/.var/app/com.mikeasoft.pied/data/pied/models"

case "$1" in
    en_US-amy-low)
        RATE=16000
        ;;
    *)
        RATE=22050
        ;;
esac

exec "$HOME/.var/app/com.mikeasoft.pied/data/pied/piper/piper" \
    --model "$MODEL_DIR/$1.onnx" \
    --output_raw |
    paplay --raw --rate="$RATE" --channels=1 --format=s16le
EOF

chmod +x ~/.local/bin/piper-speechd
```

---

# 6. Test the helper directly

Before involving Speech Dispatcher, test Piper itself through the helper.

For example:

```bash
~/.local/bin/piper-speechd en_US-amy-low <<< "This is Amy."
```

Then test another voice:

```bash
~/.local/bin/piper-speechd en_US-bryce-medium <<< "This is Bryce."
```

And:

```bash
~/.local/bin/piper-speechd en_US-kristin-medium <<< "This is Kristin."
```

The voices should sound distinctly different.

If this step does not work, do not continue to Speech Dispatcher yet.

---

# 7. Configure Speech Dispatcher

Create the Speech Dispatcher module directory:

```bash
mkdir -p ~/.config/speech-dispatcher/modules
```

Create the Piper module configuration:

```bash
cat > ~/.config/speech-dispatcher/modules/piper-pied.conf <<'EOF'
Debug 1

GenericExecuteSynth \
"printf '%s' \"$DATA\" | $HOME/.local/bin/piper-speechd \"$VOICE\""

GenericLanguage "en" "en_US" "utf-8"
GenericLanguage "en-us" "en_US" "utf-8"
GenericLanguage "cs" "cs_CZ" "utf-8"
GenericLanguage "es" "es_MX" "utf-8"
GenericLanguage "hu" "hu_HU" "utf-8"
GenericLanguage "ru" "ru_RU" "utf-8"

AddVoice "en" "FEMALE1" "en_US-amy-low"
AddVoice "en" "MALE1" "en_US-bryce-medium"
AddVoice "en" "FEMALE2" "en_US-hfc_female-medium"
AddVoice "en" "MALE2" "en_US-hfc_male-medium"
AddVoice "en" "FEMALE3" "en_US-kristin-medium"

AddVoice "cs" "MALE1" "cs_CZ-jirka-medium"

AddVoice "es" "MALE1" "es_MX-claude-high"

AddVoice "hu" "FEMALE1" "hu_HU-berta-medium"
AddVoice "hu" "MALE1" "hu_HU-imre-medium"

AddVoice "ru" "MALE1" "ru_RU-ruslan-medium"

DefaultVoice "en_US-amy-low"
EOF
```

## Important

The `AddVoice` entries must correspond to voices that actually exist in your Pied models directory.

If you did not install a particular voice, remove its `AddVoice` line.

---

# 8. Restart Speech Dispatcher

Restart the Speech Dispatcher process so that it reads the new configuration:

```bash
pkill -f '/usr/bin/speech-dispatcher' 2>/dev/null || true
speech-dispatcher -d
```

---

# 9. Verify that Speech Dispatcher sees the voices

Run:

```bash
spd-say -O
```

The output should include:

```text
piper-pied
```

Now list the voices:

```bash
spd-say -L
```

You should see the configured voices.

For example:

```text
NAME                         LANGUAGE       VARIANT
en_US-amy-low                en             FEMALE1
en_US-bryce-medium           en             MALE1
en_US-hfc_female-medium      en             FEMALE2
en_US-hfc_male-medium        en             MALE2
en_US-kristin-medium         en             FEMALE3
cs_CZ-jirka-medium           cs             MALE1
es_MX-claude-high            es             MALE1
hu_HU-berta-medium           hu             FEMALE1
hu_HU-imre-medium             hu             MALE1
ru_RU-ruslan-medium           ru             MALE1
```

---

# 10. Test Speech Dispatcher

Test Amy:

```bash
spd-say -o piper-pied -y en_US-amy-low "This is Amy."
```

Test Bryce:

```bash
spd-say -o piper-pied -y en_US-bryce-medium "This is Bryce."
```

Test Kristin:

```bash
spd-say -o piper-pied -y en_US-kristin-medium "This is Kristin."
```

The important thing is that these should actually sound like different voices.

---

# 11. Verify that the correct Piper model is being used

Speech Dispatcher writes a log here:

```text
/run/user/1000/speech-dispatcher/log/piper-pied.log
```

The UID may differ on another system, so `$XDG_RUNTIME_DIR` is preferable:

```bash
grep 'synth command' \
  "$XDG_RUNTIME_DIR/speech-dispatcher/log/piper-pied.log" | tail -5
```

For Bryce, the command should contain something similar to:

```text
piper-speechd "en_US-bryce-medium"
```

For Kristin:

```text
piper-speechd "en_US-kristin-medium"
```

This confirms that Speech Dispatcher is passing the requested voice to the helper.

---

# 12. Okular

Once `spd-say -L` shows the voices correctly, Okular should be able to see the Speech Dispatcher voices as well.

Open Okular and open its text-to-speech/accessibility settings.

Select Speech Dispatcher as the speech engine if necessary.

The available Piper voices should now include the voices configured above.

If Okular was already running while Speech Dispatcher was being configured, restart Okular.

---

# 13. Adding another Piper voice later

Install the model using Pied.

For example, if you install another English voice:

```text
en_US-example-medium.onnx
```

add a corresponding `AddVoice` entry to:

```text
~/.config/speech-dispatcher/modules/piper-pied.conf
```

For example:

```text
AddVoice "en" "MALE3" "en_US-example-medium"
```

Then restart Speech Dispatcher:

```bash
pkill -f '/usr/bin/speech-dispatcher' 2>/dev/null || true
speech-dispatcher -d
```

Verify:

```bash
spd-say -L
```

---

# 14. Backup

There are two useful levels of backup.

## 14.1 Minimal configuration backup

This is the important backup.

It is tiny compared with the Piper models:

```bash
tar -czf ~/piper-speechd-config-$(date +%Y-%m-%d).tar.gz \
  ~/.config/speech-dispatcher/modules/piper-pied.conf \
  ~/.local/bin/piper-speechd
```

This contains the custom configuration needed to recreate the setup.

Keep this somewhere outside the Steam Deck.

---

## 14.2 Full backup including Piper voices

The Piper models can take hundreds of megabytes.

To back up the configuration **and all installed voices**:

```bash
tar -czf ~/piper-speechd-full-$(date +%Y-%m-%d).tar.gz \
  ~/.config/speech-dispatcher/modules/piper-pied.conf \
  ~/.local/bin/piper-speechd \
  ~/.var/app/com.mikeasoft.pied/data/pied/models/
```

This can easily be around 600 MB depending on the installed voices.

You do not normally need this full backup if Pied can simply redownload the voices.

---

# 15. Recovery after a SteamOS update

SteamOS is an immutable operating system, and updates can replace system-level files.

The custom configuration in this guide is deliberately kept under the user's home directory:

```text
~/.config/
~/.local/
```

If the configuration is lost, restore:

```text
~/.config/speech-dispatcher/modules/piper-pied.conf
~/.local/bin/piper-speechd
```

Then make the helper executable:

```bash
chmod +x ~/.local/bin/piper-speechd
```

Restart Speech Dispatcher:

```bash
pkill -f '/usr/bin/speech-dispatcher' 2>/dev/null || true
speech-dispatcher -d
```

Verify:

```bash
spd-say -L
```

If the Piper models are still present, test a voice.

If the models are gone, reinstall the desired voices using Pied.

---

# 16. Quick diagnostic checklist

If only Amy is available:

```bash
spd-say -L
```

If only Amy appears, check:

```bash
cat ~/.config/speech-dispatcher/modules/piper-pied.conf
```

Make sure the other `AddVoice` entries exist.

---

If Speech Dispatcher sees the voice but it sounds extremely deep or slow:

Check the model sample rate:

```bash
for f in ~/.var/app/com.mikeasoft.pied/data/pied/models/*.onnx.json; do
    printf '%-40s ' "$(basename "$f")"
    jq -r '.audio.sample_rate // "NO SAMPLE RATE"' "$f"
done
```

The helper must use the model's actual sample rate.

---

If Speech Dispatcher cannot speak at all:

Test the helper directly:

```bash
~/.local/bin/piper-speechd en_US-bryce-medium <<< "This is Bryce."
```

If that works, inspect the Speech Dispatcher log:

```bash
tail -60 \
  "$XDG_RUNTIME_DIR/speech-dispatcher/log/piper-pied.log"
```

---

# 17. Final expected result

A successful installation has:

```text
Pied
  └── Piper models
        │
        ▼
~/.local/bin/piper-speechd
        │
        ▼
Speech Dispatcher
        │
        ├── Amy
        ├── Bryce
        ├── HFC Female
        ├── HFC Male
        ├── Kristin
        ├── Jirka
        ├── Claude
        ├── Berta
        ├── Imre
        └── Ruslan
        │
        ▼
Okular
```

The most important verification is:

```bash
spd-say -L
```

If the desired voices appear there and individual `spd-say` tests produce the correct voices, the Speech Dispatcher/Piper configuration is working.

---

# 18. Files created by this setup

The two custom files are:

```text
~/.local/bin/piper-speechd
~/.config/speech-dispatcher/modules/piper-pied.conf
```

Pied's Piper data is normally located at:

```text
~/.var/app/com.mikeasoft.pied/data/pied/
```

The Piper models are located at:

```text
~/.var/app/com.mikeasoft.pied/data/pied/models/
```

The two custom files are the **essential configuration backup**.

The Piper models are optional to back up because they can normally be reinstalled through Pied.

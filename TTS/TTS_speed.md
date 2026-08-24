# TTS Speed Control for Speech Dispatcher + Piper

A lightweight, application-independent TTS speed controller for a Linux desktop using **Speech Dispatcher** with a custom **Piper** backend.

The solution provides a single command, `ttspeed`, for controlling TTS speed globally without requiring application-specific keybindings or restarting applications.

---

## Overview

The TTS pipeline is:

```text
Application
    │
    │ Speech Dispatcher request
    │
    ▼
Speech Dispatcher
    │
    │ $RATE (-100 .. +100)
    ▼
piper-pied.conf
    │
    │ $VOICE $RATE
    ▼
piper-speechd
    │
    │ Speech Dispatcher rate → Piper length_scale
    ▼
Piper
    │
    ▼
Audio
```

The important design principle is that `ttspeed` does **not** modify Speech Dispatcher's global configuration.

Instead, it creates a small runtime override which `piper-speechd` checks whenever a new utterance is synthesized.

This means:

- No KWin scripting.
- No application-specific TTS configuration.
- No restarting applications.
- No modification of `speechd.conf`.
- Existing application-specific Speech Dispatcher rates remain usable.
- `reset` removes the override completely and returns control to the application/Speech Dispatcher.
- The controller is a simple standalone script and can be invoked from anywhere in `$PATH`.

---

## Files

The solution consists of three relevant files.

### 1. TTS speed controller

```text
/home/deck/scripts/ttspeed
```

This is the user-facing command.

It accepts:

```text
min
max
slower
faster
reset

s
S
f
F
r
R

speed
```

The script stores the current override in:

```text
~/.local/state/kwinctl/rate
```

The directory/file name is an implementation detail of the current version. The state contains only a single integer.

The state file is intentionally **not** considered permanent configuration.

---

### 2. Piper Speech Dispatcher bridge

```text
/home/deck/.local/bin/piper-speechd
```

This script receives:

```text
$1 = voice
$2 = Speech Dispatcher rate
```

For example:

```text
piper-speechd en_US-amy-low 50
```

The script checks whether `ttspeed` has created a global override.

If an override exists and is valid:

```text
-100 <= rate <= +100
```

the override replaces the rate supplied by Speech Dispatcher.

If no override exists, the rate supplied by Speech Dispatcher is used unchanged.

Therefore:

```text
ttspeed s
```

does not change the application itself.

Instead, the next invocation of `piper-speechd` sees the override and uses the requested speed.

---

### 3. Speech Dispatcher Piper module

```text
/home/deck/.config/speech-dispatcher/modules/piper-pied.conf
```

The important part is:

```text
GenericExecuteSynth \
"printf '%s' \"$DATA\" | /home/deck/.local/bin/piper-speechd \"$VOICE\" \"$RATE\""
```

This passes the Speech Dispatcher rate into `piper-speechd`.

This file is part of the custom TTS setup and should therefore be backed up, even though the final `ttspeed` implementation does not need to modify it.

---

# `ttspeed` Commands

## Maximum

```bash
ttspeed max
```

Sets the global TTS override to:

```text
+100
```

This corresponds to the maximum Speech Dispatcher rate.

---

## Minimum

```bash
ttspeed min
```

Sets:

```text
-100
```

---

## Slower

```bash
ttspeed slower
```

or:

```bash
ttspeed s
ttspeed S
```

Decreases the current override by 10.

For example:

```text
0
↓
-10
↓
-20
↓
-30
```

The value is clamped at:

```text
-100
```

---

## Faster

```bash
ttspeed faster
```

or:

```bash
ttspeed f
ttspeed F
```

Increases the current override by 10.

For example:

```text
0
↓
+10
↓
+20
↓
+30
```

The value is clamped at:

```text
+100
```

---

## Reset

```bash
ttspeed reset
```

or:

```bash
ttspeed r
ttspeed R
```

This is intentionally different from setting the rate to `0`.

It **removes the global override completely**.

After:

```bash
ttspeed reset
```

the next TTS request uses whatever rate the application/Speech Dispatcher supplies.

This makes `reset` a true:

> "Stop overriding TTS speed."

operation.

---

## Show current state

```bash
ttspeed speed
```

When an override exists:

```text
TTS override: +40
```

When no override exists:

```text
TTS override: off
```

---

# Rate Mapping

Speech Dispatcher uses:

```text
-100 .. +100
```

The custom Piper bridge converts this into Piper's `length_scale`.

The current conversion is:

```text
length_scale = 1.0 - (rate / 200.0)
```

with a safety clamp of:

```text
0.5 .. 1.5
```

Conceptually:

```text
Speech Dispatcher     Piper
rate                  length_scale
-----------------------------------
-100                  1.500
 -50                  1.250
   0                  1.000
 +50                  0.750
+100                  0.500
```

For Piper:

```text
smaller length_scale = faster speech
larger  length_scale = slower speech
```

The conversion is handled entirely by `piper-speechd`.

`ttspeed` only deals with the Speech Dispatcher-style rate.

---

# Runtime Behaviour

The override is checked when `piper-speechd` starts synthesizing an utterance.

For example:

```text
Okular
  │
  │ request speech
  ▼
Speech Dispatcher
  │
  │ rate = 0
  ▼
piper-speechd
  │
  │ ttspeed override = -40
  ▼
Piper
```

The Piper process therefore receives the overridden rate.

If the override is removed:

```bash
ttspeed reset
```

the flow becomes:

```text
Okular
  │
  ▼
Speech Dispatcher
  │
  │ rate supplied by application/default
  ▼
piper-speechd
  │
  │ no override
  ▼
Piper
```

---

# Important Runtime Limitation

The speed override is evaluated when a new synthesis process starts.

Therefore changing the speed while Piper is already synthesizing a sentence does **not** retroactively change that sentence.

For example:

```text
Current sentence
      │
      └── already being synthesized
                │
          ttspeed f
                │
                ▼
        current sentence unchanged

Next sentence
      │
      ▼
      new rate
```

This is intentional and keeps the implementation simple and reliable.

No application restart is required.

The next TTS chunk will use the new rate.

---

# Why This Design

Several approaches were considered.

## KWin scripting

Initially KWin's D-Bus and scripting interfaces were investigated.

This turned out to be unrelated to the actual problem.

KWin controls the desktop/window manager and is not necessary for controlling Speech Dispatcher/Piper TTS speed.

It was therefore removed from the final architecture.

---

## Changing `speechd.conf`

Speech Dispatcher has:

```text
DefaultRate
```

For example:

```text
DefaultRate 0
```

Changing this would alter the default rate, but it is not a true global runtime override.

Applications can have their own Speech Dispatcher settings or explicitly specify their own rate.

It would also mix temporary user interaction with permanent Speech Dispatcher configuration.

Therefore `ttspeed` does not modify `speechd.conf`.

---

## Application-specific configuration

Speech Dispatcher supports client-specific configuration.

That could be useful for something like:

```text
Okular → one rate
Emacs  → another rate
```

but it is unnecessary for the primary use case.

The current design provides a global override while still allowing the application to control the rate when the override is disabled.

---

# Application Independence

The main advantage is that applications do not need to know about `ttspeed`.

For example, Okular can continue using its normal Speech Dispatcher integration.

`ttspeed` operates underneath it:

```text
                ┌──────────────┐
                │    Okular    │
                └──────┬───────┘
                       │
                Speech Dispatcher
                       │
                       ▼
                piper-speechd
                       │
                 global override
                       │
                       ▼
                     Piper
```

The same mechanism can therefore work for other Speech Dispatcher clients without adding separate configuration for each application.

---

# Okular Integration

Okular has built-in TTS actions.

The current local shortcut setup is:

```text
r → Read from current page
s → Stop speaking
p → Pause / Resume
```

These shortcuts are scoped to Okular.

They are therefore independent from `ttspeed`.

The separation is:

```text
Okular
├── r → start reading
├── s → stop
└── p → pause/resume

ttspeed
├── slower
├── faster
├── min
├── max
└── reset
```

This avoids creating application-specific global speed shortcuts.

---

# Optional KDE Global Shortcuts

Because `ttspeed` is a normal executable, KDE can invoke it with an argument.

For example, a KDE custom shortcut can execute:

```bash
/home/deck/scripts/ttspeed s
```

Another shortcut can execute:

```bash
/home/deck/scripts/ttspeed f
```

And another:

```bash
/home/deck/scripts/ttspeed r
```

The same executable is therefore reused with different arguments.

It is recommended to use the absolute path in KDE shortcut commands:

```text
/home/deck/scripts/ttspeed s
```

rather than relying on the shell `$PATH`.

Choose keyboard combinations only after checking the existing KDE shortcut assignments to avoid conflicts.

---

# Installation / Restoration

The custom executable directory is:

```text
/home/deck/scripts
```

It is included in the user's `$PATH` through `.bashrc`:

```bash
export PATH="$PATH:$HOME/scripts"
```

The main custom files are:

```text
/home/deck/scripts/ttspeed
/home/deck/.local/bin/piper-speechd
/home/deck/.config/speech-dispatcher/modules/piper-pied.conf
```

After restoring them, ensure the scripts are executable:

```bash
chmod +x ~/scripts/ttspeed
chmod +x ~/.local/bin/piper-speechd
```

---

# Backup

A simple backup can be created with:

```bash
mkdir -p ~/backup/tts

cp ~/scripts/ttspeed \
   ~/backup/tts/

cp ~/.local/bin/piper-speechd \
   ~/backup/tts/

cp ~/.config/speech-dispatcher/modules/piper-pied.conf \
   ~/backup/tts/
```

Result:

```text
~/backup/tts/
├── ttspeed
├── piper-speechd
└── piper-pied.conf
```

The current runtime override does not need to be backed up:

```text
~/.local/state/kwinctl/rate
```

After an OS restoration, it is preferable to start with no override so that the application/Speech Dispatcher controls the rate normally.

---

# Piper Models

The custom `piper-speechd` script currently expects Piper models here:

```text
~/.var/app/com.mikeasoft.pied/data/pied/models/
```

The models are therefore also worth backing up if a complete TTS restoration is desired.

For example:

```bash
cp -a \
    ~/.var/app/com.mikeasoft.pied/data/pied/models \
    ~/backup/tts/
```

This is separate from the `ttspeed` logic itself.

---

# Current Architecture

The final solution can be summarized as:

```text
                       TTS application
                              │
                              ▼
                     Speech Dispatcher
                              │
                              │ $RATE
                              ▼
                    piper-pied.conf
                              │
                              ▼
                     piper-speechd
                              │
                    ┌─────────┴─────────┐
                    │                   │
              override exists      no override
                    │                   │
                    ▼                   ▼
               ttspeed rate        $RATE from SD
                    │                   │
                    └─────────┬─────────┘
                              ▼
                            Piper
                              │
                              ▼
                            Audio
```

The responsibilities are deliberately separated:

```text
ttspeed
    = What speed should be forced globally?

Speech Dispatcher
    = What rate did the application request?

piper-speechd
    = Which rate wins and how is it converted?

Piper
    = Synthesize the speech.
```

This makes the system easy to understand, modify, and restore after an OS update or reinstall.

---

# Quick Reference

```text
Command             Effect
------------------------------------------------
ttspeed min         Maximum slow-down (-100)
ttspeed max         Maximum speed (+100)

ttspeed slower      -10
ttspeed s           -10
ttspeed S           -10

ttspeed faster      +10
ttspeed f           +10
ttspeed F           +10

ttspeed reset       Remove global override
ttspeed r           Remove global override
ttspeed R           Remove global override

ttspeed speed       Show current override
```

The most frequently used commands are therefore simply:

```bash
ttspeed s
ttspeed f
ttspeed r
```

with:

```bash
ttspeed min
ttspeed max
```

available when an absolute speed is desired.

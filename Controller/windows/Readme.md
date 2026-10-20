# Steam Controller Haptic Music Launcher (Windows Pipeline)

A native, lightweight C# automation wrapper designed to run completely invisibly in the background. It intercepts your controller's input hooks to unblock game startup routines, provides an automatic 10-second timeout ceiling, and handles graceful memory buffer resets.

## Features
- **100% Invisible Execution:** Compiled as a Windows-GUI target so no console windows flash or steal window focus.
- **Hardware-Level Skip:** Intercepts your controller natively via XInput. Pressing the physical **"B" button** drops the music streams instantly.
- **No Stuck Vibrations:** Uses standard handle destruction sequences rather than hard process termination. This allows the haptic synthesizer to clear out memory channels naturally without locking your motors into an infinite vibration loop.

---

## Configuration & Launch Parameters

1. Open your Steam Library, right-click your game (e.g., **Vampire Survivors**), and select **Properties**.
2. Navigate down to the **Launch Options** text box.
3. Insert your fully qualified launcher file path, followed by a targeted custom `.mid` track parameter, and terminate the string with Steam's environment hook parameters:

```text
"C:\Program Files (x86)\Steam\steamapps\common\Vampire Survivors\haptic_launcher.exe" "C:\Projects\SM\SteamMachine-main\SteamMachine-main\Controller\midi_files\controller_Mortal_Kombat.mid" %command% --in-process-gpu
```

*Note: If you do not specify a target file path variable before `%command%`, the compiled executable engine will seamlessly fall back to your repository's baseline default (`controller_imperial.mid`).*

---

## Building from Source Code

If you prefer to compile this binary manually from the open-source blueprint file:

1. Open a standard **Windows PowerShell** terminal inside this folder:
   ```powershell
   cd "C:\Projects\SM\SteamMachine-main\SteamMachine-main\Controller\windows"
   ```
2. Run the native Windows .NET Framework backend compiler to build the optimized graphical executable file:
   ```powershell
   & "\$env:SystemRoot\Microsoft.NET\Framework64\v4.\(0.30319\csc.\)exe" /target:winexe /out:haptic_launcher.exe haptic_launcher.cs
   ```

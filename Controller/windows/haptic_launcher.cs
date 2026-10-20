using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using System.IO;

class HapticLauncher {
    [StructLayout(LayoutKind.Sequential)]
    public struct XINPUT_STATE { 
        public uint dwPacketNumber; 
        public ushort wButtons; 
    }
    
    [DllImport("xinput1_4.dll")]
    public static extern uint XInputGetState(uint dwUserIndex, ref XINPUT_STATE pState);

    static void Main(string[] args) {
        if (args.Length == 0) return;

        // Default MIDI path fallback
        string midiFile = @"C:\Projects\SM\SteamMachine-main\SteamMachine-main\Controller\midi_files\controller_imperial.mid";
        int gameStartIdx = 0;

        // Check if the first argument provided by Steam is a custom MIDI file path
        if (args[0].EndsWith(".mid", StringComparison.OrdinalIgnoreCase)) {
            midiFile = args[0];
            gameStartIdx = 1; // Shift index to ignore the MIDI path when launching the game
        }

        // Reconstruct the game binary executable and its flags cleanly
        string gameExe = args[gameStartIdx];
        string gameArgs = "";
        for (int i = gameStartIdx + 1; i < args.Length; i++) {
            gameArgs += (args[i].Contains(" ") ? "\"" + args[i] + "\"" : args[i]) + " ";
        }

        // Spin up the haptic music player inside a hidden window
        Process hapticProc = new Process();
        hapticProc.StartInfo.FileName = @"C:\Projects\SM\SteamMachine-main\SteamMachine-main\Controller\steam-haptics-singer.exe";
        hapticProc.StartInfo.Arguments = string.Format(" \"{0}\"", midiFile);
        hapticProc.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
        hapticProc.Start();

        // Launch the game engine client natively
        Process gameProc = new Process();
        gameProc.StartInfo.FileName = gameExe;
        gameProc.StartInfo.Arguments = gameArgs.Trim();
        gameProc.Start();

        XINPUT_STATE state = new XINPUT_STATE();
        ushort bButtonMask = 0x2000; // Physical "B" Button bitmask
        int elapsed = 0;
        bool cancelPressed = false;

        // Monitoring Loop: Polling loop runs until 10s ceiling is hit, B triggers, or game dies
        while (!gameProc.HasExited && elapsed < 10000 && !cancelPressed) {
            for (uint i = 0; i < 4; i++) {
                if (XInputGetState(i, ref state) == 0) {
                    if ((state.wButtons & bButtonMask) == bButtonMask) {
                        cancelPressed = true;
                        break;
                    }
                }
            }
            Thread.Sleep(50);
            elapsed += 50;
        }

        // Graceful Cleanup: Close the window normally to trigger the program's built-in reset sequence
        try {
            if (!hapticProc.HasExited) {
                hapticProc.CloseMainWindow();
                if (!hapticProc.WaitForExit(800)) {
                    hapticProc.Kill(); 
                }
            }
        } catch {}

        // Keep the launcher process lifetime linked directly with the game for Steam tracking
        gameProc.WaitForExit();
    }
}
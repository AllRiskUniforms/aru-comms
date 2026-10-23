# Plato — the always-on home laptop

**Plato** is the home laptop that stays on and plugged in, showing ARU 98.
**Ferdinand** is the other computer (the one LightBurn is already set up on).

## One-time setup on Plato

**Run this on Plato only.** On **Plato**, open **PowerShell** (Start → type `powershell` → Enter) and paste:

```powershell
irm https://raw.githubusercontent.com/AllRiskUniforms/aru-comms/main/laptop/setup-laptop.ps1 | iex
```

It:

1. Keeps the screen on, and stops sleep and hibernate, while plugged in. Closing the lid does nothing.
2. Installs Git, Node.js, Chrome, the Claude app, Claude Code and RetroBar, and downloads
   the ARU code to `C:\Users\<you>\ARU`.
3. Adds Desktop Commander to the Claude app and to Claude Code.
4. Dresses the desktop as Windows 98 (see below).
5. Adds an **ARU 98** shortcut to Startup and the Desktop. At every sign-in it pulls the
   latest code and starts the screen lock: the lock screen shows right away, and again
   after 5 minutes without keyboard or mouse.

It finishes with a short list of things only you can click: Chrome sign-in and sync (this
brings over Ferdinand's Chrome extensions), adding Claude in Chrome, signing in to the
Claude app (your claude.ai connectors come with the account), and stopping Windows from
asking for its own password. After that, ARU 98's lock screen is the only login.

## The lock screen (`lock.html`)

Matrix boot sequence → Windows 98 style logon → the password → the Windows 98 desktop.
A wrong password gets Nedry: *"Ah ah ah! You didn't say the magic word!"*

- **Locks itself after 5 idle minutes.** `lock-watch.ps1` runs hidden from sign-in and brings
  the lock screen back whenever nobody has touched the keyboard or mouse for 5 minutes.
  It only covers the screen: programs, downloads, music and laser jobs keep running, and
  unlocking shows everything exactly as you left it. To change the 5 minutes, edit
  `$IdleMinutes` at the top of `lock-watch.ps1`.
- **Lock now:** double-click **ARU 98** on the desktop. That also restarts the lock with the
  latest code.
- **Not locking after 5 minutes?** Restart the lock with the latest code from PowerShell:

  ```powershell
  cd ~\ARU\aru-comms; git pull; Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PWD\laptop\lock-watch.ps1"
  ```

  What the lock did is in `%LOCALAPPDATA%\ARU98\lock-watch.log`
  (`Get-Content $env:LOCALAPPDATA\ARU98\lock-watch.log -Tail 20` shows the end).
- **Forgot the password?** Click **Forgot...** and enter the ARU Comms passphrase plus the
  admin phone number instead. They're only asked for here; the app doesn't ask on Plato.
- **ARU Comms** opens from its desktop icon, already signed in as admin. Locking leaves it
  open and signed in.
- **Nedry:** the wagging Nedry and his looping "ah ah ah" live in `nedry/`. They come from
  the Jurassic Systems recreation of the movie scene (MIT license, see `nedry/LICENSE`).
  Turn the volume up.
- **Skip the intro:** press any key during the Matrix boot.
- **Close the lock without the password:** Alt+F4. It comes back after 5 idle minutes.
- **Change the password:** run this in PowerShell, with your new password in place of `newpass`:

  ```powershell
  $p='newpass'; -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('aru98:' + $p.Trim().ToLower())) | % { $_.ToString('x2') })
  ```

  Then paste the output into `PASS_HASH` in `lock.html`.

The lock is a fun gate, not real security: it's a web page, so Ctrl+Alt+Del or Alt+F4
gets past it, and the hash of a short dictionary word can be cracked. Don't rely on it
to protect anything sensitive on this laptop.

## The Windows 98 desktop (`win98-desktop.ps1`)

The real Windows desktop, dressed as Windows 98, so every icon opens the real program or folder:

- [RetroBar](https://github.com/dremin/RetroBar)'s Windows 98 taskbar and Start button
  (right-click the taskbar → Properties for other themes), and the classic teal background.
- **My Computer**, **My Documents**, **Recycle Bin**, **Network**, **ARU Comms**, and icons for
  Google Chrome, LightBurn, Claude, Spotify, Inkscape, PowerShell, Paint and Outlook.
- A little **fire axe** mouse pointer at the smallest pointer size (`cursors/fire-axe.cur`, drawn
  by `cursors/make-cursors.py`). To get the normal arrow back: Start → type `mouse pointer` →
  Additional mouse settings → Pointers → Use Default.
- A Windows 98 style **Search** box on the taskbar (`search-bar.ps1`): type, then pick a
  program, "Search files" or "Search the web" with the arrow keys and Enter. Drag the grip
  on its left to move it along the taskbar.
- Window borders and the Start menu itself stay Windows 10/11.

A program that isn't installed yet gets no icon. Install it, then run this again:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\ARU\aru-comms\laptop\win98-desktop.ps1"
```

## Ran the setup on the wrong computer?

On that computer, in PowerShell:

```powershell
Remove-Item "$([Environment]::GetFolderPath('Startup'))\ARU 98.lnk", "$([Environment]::GetFolderPath('Startup'))\RetroBar.lnk", "$([Environment]::GetFolderPath('Startup'))\ARU Search.lnk", "$([Environment]::GetFolderPath('Desktop'))\ARU 98.lnk" -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" | Where-Object { $_.CommandLine -like '*lock-watch*' -or $_.CommandLine -like '*search-bar*' } | ForEach-Object { Stop-Process -Id $_.ProcessId }
powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setactive SCHEME_CURRENT
```

Then set the screen and sleep times back in **Settings → System → Power**.

## LightBurn: copy Ferdinand's setup to Plato

A design file (`.lbrn` / `.lbrn2`) or material library (`.clb`) doesn't carry the device
profile, so LightBurn on Plato still asks you to set up a device. Copy the whole setup instead:

**On Ferdinand:**

1. In LightBurn, **File → Export Prefs**. Save the file (e.g. `Ferdinand.lbzip`).
2. In case Export Prefs leaves out the device, also open the **Laser** window → **Devices**,
   select your laser → **Export**, and save `Ferdinand.lbdev`.
3. If you use a material library: **Library** window → **Save As** → `Ferdinand.clb`.
4. Put the files on a USB stick or in Google Drive. Email works too: attach them as files.

**On Plato:**

1. Install LightBurn and sign in or activate your license.
2. When it asks you to set up a device, cancel. Then **File → Import Prefs** → pick
   `Ferdinand.lbzip` and let LightBurn restart.
3. If the laser doesn't appear: **Devices** → **Import** → `Ferdinand.lbdev`.
4. **Library** window → **Load** → `Ferdinand.clb`.
5. Plug in the laser and pick its port in the **Laser** window's connection drop-down.
   The port name (COM3, COM4…) can differ from Ferdinand's.

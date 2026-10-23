# Plato — the always-on home laptop

**Plato** is the home laptop that stays on and plugged in, showing ARU 98.
**Ferdinand** is the other computer (the one LightBurn is already set up on).

## One-time setup on Plato

Open **PowerShell** (Start → type `powershell` → Enter) and paste:

```powershell
irm https://raw.githubusercontent.com/AllRiskUniforms/aru-comms/main/laptop/setup-laptop.ps1 | iex
```

It:

1. Keeps the screen on, and stops sleep and hibernate, while plugged in. Closing the lid does nothing.
2. Installs Git and Claude Code, and downloads the ARU code to `C:\Users\<you>\ARU`.
3. Adds an **ARU 98** shortcut to Startup and the Desktop. At every sign-in it pulls the
   latest code and opens the lock screen full screen.

It finishes by printing two manual steps that stop Windows asking for its own password.
After that, ARU 98's lock screen is the only login.

## The lock screen (`lock.html`)

Matrix boot sequence → Windows 98 style logon → the password → the ARU Comms app.
A wrong password gets Nedry: *"Ah ah ah! You didn't say the magic word!"*

- **Nedry:** the wagging Nedry and his looping "ah ah ah" live in `nedry/`. They come from
  the Jurassic Systems recreation of the movie scene (MIT license, see `nedry/LICENSE`).
  Turn the volume up.
- **Skip the intro:** press any key during the Matrix boot.
- **Close the kiosk:** Alt+F4. Reopen it with the **ARU 98** Desktop shortcut.
- **Change the password:** run this in PowerShell, with your new password in place of `newpass`:

  ```powershell
  $p='newpass'; -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('aru98:' + $p.Trim().ToLower())) | % { $_.ToString('x2') })
  ```

  Then paste the output into `PASS_HASH` in `lock.html`.

The lock is a fun gate, not real security: it's a web page, so Ctrl+Alt+Del or Alt+F4
gets past it, and the hash of a short dictionary word can be cracked. Don't rely on it
to protect anything sensitive on this laptop.

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

# Plato's screen lock. start-kiosk.cmd starts this hidden at sign-in. It shows the ARU 98
# lock screen straight away, then again whenever the keyboard and mouse have been idle
# for $IdleMinutes. The lock only covers the screen: everything behind it keeps running,
# and unlocking uncovers the desktop exactly as it was.
# Starting it again (the desktop "ARU 98" icon) replaces the running copy and locks now.
# What it did is logged to %LOCALAPPDATA%\ARU98\lock-watch.log.
param([int]$IdleMinutes = 5)

$LockUrl = 'file:///' + ((Join-Path $PSScriptRoot 'lock.html') -replace '\\', '/')
# Its own Edge profile, so kiosk mode always applies and ARU Comms' window is left alone.
$LockProfile = Join-Path $env:LOCALAPPDATA 'ARU98\lock'
$Edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(default)'
if (-not $Edge) { $Edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe" }

$Log = Join-Path $env:LOCALAPPDATA 'ARU98\lock-watch.log'
New-Item -ItemType Directory -Force (Split-Path $Log) | Out-Null
if ((Test-Path $Log) -and (Get-Item $Log).Length -gt 1MB) { Remove-Item $Log }
function Log($msg) { try { Add-Content $Log "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" } catch {} }

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Idle {
  [StructLayout(LayoutKind.Sequential)]
  struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }

  [DllImport("user32.dll")]
  static extern bool GetLastInputInfo(ref LASTINPUTINFO info);

  // Milliseconds since the last keyboard or mouse input. Both are 32-bit tick counts,
  // so unsigned subtraction stays right when they wrap (every 49.7 days of uptime).
  public static uint Milliseconds() {
    LASTINPUTINFO info = new LASTINPUTINFO();
    info.cbSize = (uint)Marshal.SizeOf(info);
    GetLastInputInfo(ref info);
    return unchecked((uint)Environment.TickCount - info.dwTime);
  }
}

public static class LockWindow {
  [DllImport("user32.dll")]
  static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);

  [DllImport("user32.dll")]
  static extern bool SetForegroundWindow(IntPtr hwnd);

  // Above every normal window (HWND_TOPMOST), shown, and focused for typing.
  public static void BringToFront(IntPtr hwnd) {
    SetWindowPos(hwnd, new IntPtr(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0040);  // NOSIZE|NOMOVE|SHOWWINDOW
    SetForegroundWindow(hwnd);
  }
}
'@

# lock.html's title is "ARU 98", and "ARU 98 unlocked" once the password is right.
function Get-LockWindows { Get-Process msedge -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -like 'ARU 98*' }

function Close-Lock {
  Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -like "*$LockProfile*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Show-Lock($why) {
  Log "locking ($why)"
  Close-Lock  # a lock-profile Edge still running in the background would ignore --kiosk
  Start-Process $Edge -ArgumentList '--kiosk', "`"$LockUrl`"", '--edge-kiosk-type=fullscreen',
    "--user-data-dir=`"$LockProfile`"", '--no-first-run', '--no-default-browser-check',
    '--autoplay-policy=no-user-gesture-required'
  # Windows may open it behind whatever was in front, so pull it forward and keep it on top.
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    $win = Get-LockWindows | Where-Object MainWindowHandle -ne 0 | Select-Object -First 1
    if ($win) { [LockWindow]::BringToFront($win.MainWindowHandle); return }
  }
  Log 'lock window did not appear within 15 s'
}

# One watcher at a time, always the newest code: stop any copy already running.
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
  Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*lock-watch.ps1*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Log "watcher started (locks after $IdleMinutes idle minutes; Edge: $Edge)"
Show-Lock 'started'
$lastNote = Get-Date
while ($true) {
  Start-Sleep -Seconds 2
  try {
    $locks = @(Get-LockWindows)
    $idleMs = [Idle]::Milliseconds()
    if ($locks | Where-Object MainWindowTitle -like 'ARU 98 unlocked*') {
      Log 'unlocked'
      Close-Lock
    } elseif ($locks.Count -eq 0 -and $idleMs -ge $IdleMinutes * 60000) {
      Show-Lock "idle $([int]($idleMs / 1000)) s"
    }
    if (((Get-Date) - $lastNote).TotalMinutes -ge 15) {
      Log "still watching: idle $([int]($idleMs / 1000)) s, lock showing: $($locks.Count -gt 0)"
      $lastNote = Get-Date
    }
  } catch {
    Log "error: $_"
  }
}

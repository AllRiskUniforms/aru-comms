# Plato's screen lock. start-kiosk.cmd starts this hidden at sign-in. It shows the ARU 98
# lock screen straight away, then again whenever the keyboard and mouse have been idle
# for $IdleMinutes. The lock only covers the screen: everything behind it keeps running,
# and unlocking uncovers the desktop exactly as it was.
# If it's already running, starting it again (the desktop "ARU 98" icon) just locks now.
param([int]$IdleMinutes = 5)

$LockUrl = 'file:///' + ((Join-Path $PSScriptRoot 'lock.html') -replace '\\', '/')
# Its own Edge profile, so kiosk mode always applies and ARU Comms' window is left alone.
$LockProfile = Join-Path $env:LOCALAPPDATA 'ARU98\lock'
$Edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(default)'
if (-not $Edge) { $Edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe" }

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
'@

# lock.html's title is "ARU 98", and "ARU 98 unlocked" once the password is right.
function Get-LockWindows { Get-Process msedge -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -like 'ARU 98*' }

function Close-Lock {
  Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -like "*$LockProfile*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Show-Lock {
  Close-Lock  # a lock-profile Edge still running in the background would ignore --kiosk
  Start-Process $Edge -ArgumentList '--kiosk', "`"$LockUrl`"", '--edge-kiosk-type=fullscreen',
    "--user-data-dir=`"$LockProfile`"", '--no-first-run', '--no-default-browser-check',
    '--autoplay-policy=no-user-gesture-required'
}

$Mutex = New-Object System.Threading.Mutex($false, 'Local\ARU98-lock-watch')
if (-not $Mutex.WaitOne(0)) { Show-Lock; return }  # already watching: just lock now

Show-Lock
while ($true) {
  Start-Sleep -Seconds 2
  $locks = @(Get-LockWindows)
  if ($locks | Where-Object MainWindowTitle -like 'ARU 98 unlocked*') {
    Close-Lock
  } elseif ($locks.Count -eq 0 -and [Idle]::Milliseconds() -ge $IdleMinutes * 60000) {
    Show-Lock
    Start-Sleep -Seconds 10  # give the window time to appear before checking again
  }
}

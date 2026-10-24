# Dresses Plato's real Windows desktop as Windows 98: RetroBar's Windows 98 taskbar,
# the classic teal background, My Computer / My Documents / Recycle Bin, and icons for
# the programs below. The lock screen covers it until the password is typed.
# Safe to re-run, e.g. after installing LightBurn, to add icons that were missing.
# setup-laptop.ps1 runs this; to run it alone:
#   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\ARU\aru-comms\laptop\win98-desktop.ps1"

# Desktop icon name -> Start menu names to look for, best match first.
$Programs = [ordered]@{
  'Google Chrome' = @('Google Chrome')
  'LightBurn'     = @('LightBurn')
  'Claude'        = @('Claude')
  'Spotify'       = @('Spotify')
  'Inkscape'      = @('Inkscape')
  'PowerShell'    = @('Windows PowerShell', 'PowerShell 7 (x64)', 'PowerShell')
  'Paint'         = @('Paint')
  'Outlook'       = @('Outlook', 'Outlook (classic)', 'Outlook (new)')
}

$Desktop = [Environment]::GetFolderPath('Desktop')
$Comms = Split-Path $PSScriptRoot -Parent
$Shell = New-Object -ComObject WScript.Shell

# Shortcuts made the way dragging an app out of the Start menu makes them, so Store apps
# (Spotify, new Outlook, Paint, Claude) get their real icons too.
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;

public static class AppShortcut {
  [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
  class ShellLink {}

  [ComImport, Guid("000214F9-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  interface IShellLinkW {
    void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder file, int cch, IntPtr findData, uint flags);
    void GetIDList(out IntPtr pidl);
    void SetIDList(IntPtr pidl);
  }

  [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
  static extern int SHParseDisplayName(string name, IntPtr bindCtx, out IntPtr pidl, uint sfgaoIn, out uint sfgaoOut);

  [DllImport("shell32.dll")]
  static extern void ILFree(IntPtr pidl);

  public static void Create(string shellPath, string lnkPath) {
    IntPtr pidl;
    uint attrs;
    int hr = SHParseDisplayName(shellPath, IntPtr.Zero, out pidl, 0, out attrs);
    if (hr != 0) Marshal.ThrowExceptionForHR(hr);
    try {
      IShellLinkW link = (IShellLinkW)new ShellLink();
      link.SetIDList(pidl);
      ((IPersistFile)link).Save(lnkPath, true);
    } finally {
      ILFree(pidl);
    }
  }
}

public static class Desk {
  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  public static extern bool SystemParametersInfo(int action, int param, string value, int flags);

  [DllImport("user32.dll")]
  public static extern bool SetSysColors(int count, int[] elements, int[] colors);
}
'@

function Find-StartApp($names) {
  foreach ($n in $names) { $a = $StartApps | Where-Object Name -eq $n | Select-Object -First 1; if ($a) { return $a } }
  foreach ($n in $names) { $a = $StartApps | Where-Object Name -like "$n*" | Select-Object -First 1; if ($a) { return $a } }
}

function New-AppShortcut($app, $lnkPath) {
  try {
    [AppShortcut]::Create("shell:AppsFolder\$($app.AppID)", $lnkPath)
  } catch {
    $lnk = $Shell.CreateShortcut($lnkPath)
    $lnk.TargetPath = "$env:WINDIR\explorer.exe"
    $lnk.Arguments = "shell:AppsFolder\$($app.AppID)"
    $lnk.Save()
  }
}

$StartApps = Get-StartApps

Write-Host 'Teal background...'
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value ''
Set-ItemProperty 'HKCU:\Control Panel\Colors' -Name Background -Value '0 128 128'
$Wallpapers = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers'
if (-not (Test-Path $Wallpapers)) { New-Item $Wallpapers -Force | Out-Null }
Set-ItemProperty $Wallpapers -Name BackgroundType -Value 1 -Type DWord  # solid color
[Desk]::SystemParametersInfo(20, 0, '', 3) | Out-Null                     # SPI_SETDESKWALLPAPER: none
[Desk]::SetSysColors(1, @(1), @(0x808000)) | Out-Null                     # COLOR_DESKTOP = teal (0x00BBGGRR)

Write-Host 'New York hook pointer (fire axe over links), smallest size...'
Set-ItemProperty 'HKCU:\Control Panel\Cursors' -Name Arrow -Value (Join-Path $PSScriptRoot 'cursors\ny-hook.cur')
Set-ItemProperty 'HKCU:\Control Panel\Cursors' -Name Hand -Value (Join-Path $PSScriptRoot 'cursors\fire-axe.cur')
Set-ItemProperty 'HKCU:\Control Panel\Cursors' -Name CursorBaseSize -Value 32 -Type DWord
$Access = 'HKCU:\Software\Microsoft\Accessibility'
if (-not (Test-Path $Access)) { New-Item $Access -Force | Out-Null }
Set-ItemProperty $Access -Name CursorSize -Value 1 -Type DWord               # Settings' pointer size slider at 1
[Desk]::SystemParametersInfo(0x57, 0, $null, 3) | Out-Null                   # SPI_SETCURSORS: reload pointers now

Write-Host 'My Computer, Recycle Bin and Network on the desktop...'
$Icons = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
if (-not (Test-Path $Icons)) { New-Item $Icons -Force | Out-Null }
$ThisPC = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
foreach ($clsid in @($ThisPC, '{645FF040-5081-101B-9F08-00AA002F954E}', '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}')) {
  Set-ItemProperty $Icons -Name $clsid -Value 0 -Type DWord
}
$Rename = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\$ThisPC"
if (-not (Test-Path $Rename)) { New-Item $Rename -Force | Out-Null }
Set-Item $Rename -Value 'My Computer'

$lnk = $Shell.CreateShortcut((Join-Path $Desktop 'My Documents.lnk'))
$lnk.TargetPath = [Environment]::GetFolderPath('MyDocuments')
$lnk.Save()

Write-Host 'Program icons...'
$missing = @()
foreach ($label in $Programs.Keys) {
  $app = Find-StartApp $Programs[$label]
  if ($app) { New-AppShortcut $app (Join-Path $Desktop "$label.lnk"); Write-Host "  $label" }
  else { $missing += $label }
}
if ($missing) { Write-Warning "Not installed yet, so no icon: $($missing -join ', '). Re-run this after installing them." }

# ARU Comms in its own window; #plato signs it straight in, since the screen lock guards Plato.
$Edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(default)'
if (-not $Edge) { $Edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe" }
$lnk = $Shell.CreateShortcut((Join-Path $Desktop 'ARU Comms.lnk'))
$lnk.TargetPath = $Edge
$lnk.Arguments = "--app=`"file:///$((Join-Path $Comms 'index.html') -replace '\\', '/')#plato`" --user-data-dir=`"$env:LOCALAPPDATA\ARU98\edge`" --no-first-run"
$lnk.Save()

# Explorer picks up the desktop icon and My Computer changes when it restarts.
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process "$env:WINDIR\explorer.exe" }

Write-Host 'Windows 98 taskbar (RetroBar)...'
$retro = Find-StartApp @('RetroBar')
if ($retro) {
  New-AppShortcut $retro (Join-Path ([Environment]::GetFolderPath('Startup')) 'RetroBar.lnk')
  if (-not (Get-Process RetroBar -ErrorAction SilentlyContinue)) { Start-Process "$env:WINDIR\explorer.exe" "shell:AppsFolder\$($retro.AppID)" }
} else {
  Write-Warning 'RetroBar is not installed. Install it with: winget install --id dremin.RetroBar -e'
}

Write-Host 'Windows 98 search box on the taskbar...'
$lnk = $Shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) 'ARU Search.lnk'))
$lnk.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $PSScriptRoot 'search-bar.ps1')`""
$lnk.WindowStyle = 7
$lnk.Save()
Start-Process $lnk.TargetPath $lnk.Arguments -WindowStyle Hidden  # replaces any copy already running
Write-Host 'Done. Right-click the taskbar > Properties to pick a different RetroBar theme.'

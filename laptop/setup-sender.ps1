# Sets up "Send to Plato" on a computer that sends files to Plato, such as Ferdinand (not
# on Plato itself). Safe to re-run. Paste in PowerShell, with Plato's message channel (in
# laptop\messages-config.js on Plato; never commit it) and this computer's name:
#
#   $env:ARU_TOPIC='<channel>'; $env:ARU_FROM='Ferdinand'; irm https://raw.githubusercontent.com/AllRiskUniforms/aru-comms/main/laptop/setup-sender.ps1 | iex
#
# To install from a branch other than main, set $env:ARU_BRANCH too (and use it in the URL).
# It saves send-to-plato.ps1 and its settings in %LOCALAPPDATA%\ARU98, then adds "Plato"
# to the right-click Send to menu and a "Send to Plato" desktop icon to drop files on.
# Deliberately no `exit`: this runs through iex, where exit would close PowerShell.

$Branch = if ($env:ARU_BRANCH) { $env:ARU_BRANCH } else { 'main' }
$From = if ($env:ARU_FROM) { $env:ARU_FROM } else { $env:COMPUTERNAME }
$Dir = Join-Path $env:LOCALAPPDATA 'ARU98'
$Sender = Join-Path $Dir 'send-to-plato.ps1'

if ($env:ARU_TOPIC -notmatch '^[A-Za-z0-9_-]{1,64}$') {
  Write-Warning "Set `$env:ARU_TOPIC to Plato's message channel first (it's in laptop\messages-config.js on Plato)."
} else {
  try {
    New-Item -ItemType Directory -Force $Dir | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/AllRiskUniforms/aru-comms/$Branch/laptop/send-to-plato.ps1" -OutFile $Sender -ErrorAction Stop
    [pscustomobject]@{ topic = $env:ARU_TOPIC; from = $From } | ConvertTo-Json | Set-Content (Join-Path $Dir 'send-to-plato.json') -Encoding UTF8

    $Shell = New-Object -ComObject WScript.Shell
    $SendTo = Join-Path ([Environment]::GetFolderPath('SendTo')) 'Plato.lnk'
    $Icon = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Send to Plato.lnk'
    foreach ($path in @($SendTo, $Icon)) {
      $lnk = $Shell.CreateShortcut($path)
      $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
      $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$Sender`""
      $lnk.IconLocation = "$env:SystemRoot\System32\shell32.dll,15"
      $lnk.Save()
    }
    Write-Host "Send to Plato is ready (sending as '$From')." -ForegroundColor Green
    Write-Host 'Right-click a file > Send to > Plato (on Windows 11: Show more options first),'
    Write-Host 'or drop files on the "Send to Plato" desktop icon.'
  } catch {
    Write-Warning "Setup didn't finish: $($_.Exception.Message)"
  }
}

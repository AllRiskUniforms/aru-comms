# ARU 98 home laptop setup (Windows 10/11). Run once in PowerShell; safe to re-run.
#
#   irm https://raw.githubusercontent.com/AllRiskUniforms/aru-comms/main/laptop/setup-laptop.ps1 | iex
#
# To set up from a branch other than main, set $env:ARU_BRANCH first.
#
#   1. Keeps the screen on and the laptop awake whenever it's plugged in.
#   2. Installs Git and Claude Code, and clones the ARU repos to ~\ARU.
#   3. Opens the ARU 98 lock screen full screen at every sign-in.
# Deliberately no `exit` anywhere: this usually runs through iex, where exit
# would close the user's PowerShell window.

$Branch = if ($env:ARU_BRANCH) { $env:ARU_BRANCH } else { 'main' }
$Root = Join-Path $env:USERPROFILE 'ARU'
$Comms = Join-Path $Root 'aru-comms'
$Membership = Join-Path $Root 'aru-membership-app'

function Step($msg) { Write-Host "`n== $msg ==" -ForegroundColor Green }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

Step 'Keep the screen on while plugged in'
$PowerFailed = $false
function Power { powercfg @args; if ($LASTEXITCODE -ne 0) { $script:PowerFailed = $true } }
Power /change monitor-timeout-ac 0
Power /change standby-timeout-ac 0
Power /change hibernate-timeout-ac 0
Power /change disk-timeout-ac 0
# On AC power: closing the lid does nothing, and waking never asks for a sign-in.
Power /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
Power /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
Power /setactive SCHEME_CURRENT
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -Value '0'
if ($PowerFailed) { Write-Warning 'Some power settings did not apply. Re-run this from an Administrator PowerShell.' }
else { Write-Host 'Screen, sleep and hibernate set to Never on AC power; screensaver off.' }

Step 'Install Git and Claude Code'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    Refresh-Path
  } else {
    Write-Warning 'winget is missing. Install Git from https://git-scm.com/download/win, then re-run this script.'
  }
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  # Child process, so the installer can't end this script.
  powershell -NoProfile -ExecutionPolicy Bypass -Command 'irm https://claude.ai/install.ps1 | iex'
  $ClaudeBin = Join-Path $env:USERPROFILE '.local\bin'
  $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ((Test-Path $ClaudeBin) -and ($UserPath -notlike "*$ClaudeBin*")) {
    [Environment]::SetEnvironmentVariable('Path', "$UserPath;$ClaudeBin", 'User')
  }
  Refresh-Path
}
git --version
if (Get-Command claude -ErrorAction SilentlyContinue) { claude --version } else { Write-Warning 'Claude Code did not install; see https://code.claude.com/docs' }

Step "Download the ARU code to $Root ($Branch)"
New-Item -ItemType Directory -Force $Root | Out-Null
if (Test-Path (Join-Path $Comms '.git')) {
  git -C $Comms fetch origin $Branch
  git -C $Comms checkout $Branch
  git -C $Comms pull --ff-only origin $Branch
} else {
  git clone --branch $Branch https://github.com/AllRiskUniforms/aru-comms $Comms
}
if (-not (Test-Path (Join-Path $Membership '.git'))) {
  Write-Host 'Cloning the private aru-membership-app repo (a GitHub sign-in window may open)...'
  git clone https://github.com/AllRiskUniforms/aru-membership-app $Membership
  if ($LASTEXITCODE -ne 0) { Write-Warning 'Skipped aru-membership-app. Re-run this script after signing in to GitHub.' }
}

Step 'Open ARU 98 at every sign-in'
$Launcher = Join-Path $Comms 'laptop\start-kiosk.cmd'
if (Test-Path $Launcher) {
  $Shell = New-Object -ComObject WScript.Shell
  foreach ($dir in @([Environment]::GetFolderPath('Startup'), [Environment]::GetFolderPath('Desktop'))) {
    $lnk = $Shell.CreateShortcut((Join-Path $dir 'ARU 98.lnk'))
    $lnk.TargetPath = $Launcher
    $lnk.WorkingDirectory = $Comms
    $lnk.WindowStyle = 7  # minimized, so the launcher's console window doesn't pop up
    $lnk.Save()
  }
  Write-Host 'Added "ARU 98" to Startup and the Desktop. Starting it now (Alt+F4 closes it).'
  Start-Process $Launcher -WindowStyle Minimized
} else {
  Write-Warning "$Launcher not found. Is the '$Branch' branch missing the laptop folder?"
}

Step 'Done'
Write-Host @"
Last step, by hand, so Windows skips its own password and goes straight to ARU 98:
  1. Settings > Accounts > Sign-in options: turn OFF
     "For improved security, only allow Windows Hello sign-in".
  2. Press Win+R, type netplwiz, untick
     "Users must enter a user name and password to use this computer",
     click OK and type your Windows password once.

Claude Code: open PowerShell and run   cd ~\ARU\aru-comms; claude
"@

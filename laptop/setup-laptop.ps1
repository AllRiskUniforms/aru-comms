# ARU 98 setup for Plato, the always-on home laptop (Windows 10/11). Run once in
# PowerShell ON PLATO ONLY; safe to re-run.
#
#   irm https://raw.githubusercontent.com/AllRiskUniforms/aru-comms/main/laptop/setup-laptop.ps1 | iex
#
# To set up from a branch other than main, set $env:ARU_BRANCH first.
#
#   1. Keeps the screen on and the laptop awake whenever it's plugged in.
#   2. Installs Git, Node.js, Chrome, the Claude app, Claude Code and RetroBar, and
#      clones the ARU repos to ~\ARU.
#   3. Adds Desktop Commander to Claude, and dresses the desktop as Windows 98.
#   4. Starts the ARU 98 screen lock at every sign-in: it shows right away, and again
#      after 5 minutes without keyboard or mouse.
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
function Install-App($id, $name) {
  winget list --id $id -e --accept-source-agreements *> $null
  if ($LASTEXITCODE -eq 0) { Write-Host "${name}: already installed"; return }
  Write-Host "${name}: installing..."
  winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
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

Step 'Install apps'
if (Get-Command winget -ErrorAction SilentlyContinue) {
  Install-App Git.Git 'Git'
  Install-App OpenJS.NodeJS.LTS 'Node.js'
  Install-App Google.Chrome 'Google Chrome'
  Install-App Anthropic.Claude 'Claude app'
  Install-App dremin.RetroBar 'RetroBar (Windows 98 taskbar)'
  Refresh-Path
} else {
  Write-Warning 'winget is missing. Install "App Installer" from the Microsoft Store, then re-run this script.'
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

Step 'Messages to Plato'
# A private ntfy.sh topic: anything published to it pops up on screen (messages.ps1). It lives
# only in this gitignored file, since anyone who knows it can send.
$MsgConfig = Join-Path $Comms 'laptop\messages-config.js'
if (-not (Test-Path $MsgConfig)) {
  $topic = 'plato-' + [guid]::NewGuid().ToString('N').Substring(0, 20)
  Set-Content $MsgConfig "window.ARU98_MESSAGES = { topic: '$topic' };"
}
$MsgTopic = [regex]::Match((Get-Content $MsgConfig -Raw), "topic: '([^']+)'").Groups[1].Value
Write-Host "Send messages to Plato's lock screen at https://ntfy.sh/$MsgTopic (keep this link private)."

Step 'Desktop Commander for Claude'
# npx.cmd, not npx: the .ps1 shim is blocked by the default execution policy.
if (Get-Command npx.cmd -ErrorAction SilentlyContinue) {
  npx.cmd -y '@wonderwhy-er/desktop-commander@latest' setup  # the Claude app
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    claude mcp get desktop-commander *> $null
    if ($LASTEXITCODE -ne 0) { claude mcp add desktop-commander --scope user '--' cmd /c npx -y '@wonderwhy-er/desktop-commander@latest' }
  }
} else {
  Write-Warning 'Node.js is missing, so Desktop Commander was skipped. Re-run this script after installing Node.js.'
}

Step 'Windows 98 desktop'
$Win98 = Join-Path $Comms 'laptop\win98-desktop.ps1'
if (Test-Path $Win98) { powershell -NoProfile -ExecutionPolicy Bypass -File $Win98 }
else { Write-Warning "$Win98 not found." }

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
  Write-Host 'Added "ARU 98" (the screen lock; it also locks after 5 idle minutes) to Startup and the Desktop.'
} else {
  Write-Warning "$Launcher not found. Is the '$Branch' branch missing the laptop folder?"
}

Step 'Chrome'
if (Get-Command chrome -ErrorAction SilentlyContinue) {
  Start-Process chrome 'https://support.claude.com/en/articles/12012173-claude-in-chrome'
}

Step 'Done'
Write-Host @"
A few things only you can click:
  1. Chrome: sign in with the same Google account as Ferdinand and turn on sync.
     Ferdinand's extensions, bookmarks and passwords then come over by themselves.
  2. Claude in Chrome: on the page that just opened in Chrome, follow the
     Chrome Web Store link and click "Add to Chrome", then sign in to Claude.
  3. Claude app: sign in. Your claude.ai connectors come with your account.
  4. So Windows skips its own password and goes straight to ARU 98:
     a. Settings > Accounts > Sign-in options: turn OFF
        "For improved security, only allow Windows Hello sign-in".
     b. Press Win+R, type netplwiz, untick
        "Users must enter a user name and password to use this computer",
        click OK and type your Windows password once.

Send messages to Plato: https://ntfy.sh/$MsgTopic (keep it private).
Restart Plato (or double-click ARU 98 on the desktop) to see the lock screen.
Claude Code: open PowerShell and run   cd ~\ARU\aru-comms; claude
"@

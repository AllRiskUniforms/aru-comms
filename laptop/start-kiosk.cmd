@echo off
rem ARU 98 kiosk launcher. setup-laptop.ps1 puts a shortcut to this in the
rem Startup folder and on the Desktop. Pulls the latest code, then opens the
rem lock screen full screen in its own Edge profile (separate from normal Edge,
rem so kiosk mode always applies and the app's saved data stays put).
cd /d "%~dp0.."
git pull --ff-only >nul 2>&1
set "URL=file:///%CD:\=/%/laptop/lock.html"
start "" msedge --kiosk "%URL%" --edge-kiosk-type=fullscreen --user-data-dir="%LOCALAPPDATA%\ARU98\edge" --no-first-run --no-default-browser-check --autoplay-policy=no-user-gesture-required

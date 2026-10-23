@echo off
rem ARU 98 at sign-in. setup-laptop.ps1 puts a shortcut to this in the Startup folder
rem and on the Desktop. Pulls the latest code, then starts the screen lock, which shows
rem now and again after 5 idle minutes (lock-watch.ps1). Running this again while the
rem lock is already watching just locks the screen.
cd /d "%~dp0.."
git pull --ff-only >nul 2>&1
start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0lock-watch.ps1"

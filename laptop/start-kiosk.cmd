@echo off
rem ARU 98 at sign-in. setup-laptop.ps1 puts a shortcut to this in the Startup folder
rem and on the Desktop. Pulls the latest code, then starts the screen lock, which shows
rem now and again after 5 idle minutes (lock-watch.ps1), and the message pop-ups
rem (messages.ps1). Running this again restarts both with the latest code and locks.
rem cmd reads a block whole before running it, so the pull can safely update this file.
(
  cd /d "%~dp0.."
  git pull --ff-only >nul 2>&1
  start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0lock-watch.ps1"
  start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0messages.ps1"
  exit /b
)

@echo off
title Penpot Bridge - keep this window open while importing
cd /d "%~dp0"
echo Penpot Bridge connects Penpot to Roblox Studio on this PC.
echo Keep this window open while importing. Close it to stop the helper.
echo Status and image upload setup: http://127.0.0.1:43129/setup
echo.
if not exist "%~dp0runtime\node.exe" (
  echo The bundled runtime is missing. Extract the ENTIRE Windows helper ZIP first.
  pause
  exit /b 1
)
"%~dp0runtime\node.exe" "%~dp0bridge\server.mjs" --open
if "%errorlevel%"=="10" (
  echo.
  echo This was a duplicate launch. The original helper is still running.
  echo Close this window and continue in Penpot or Studio.
  pause
  exit /b 0
)
echo.
echo The helper stopped. See the message above for details.
pause

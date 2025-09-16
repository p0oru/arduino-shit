@echo off
setlocal

REM One-click uploader for Arduino Nano on COM6
REM Usage: RunSketch.cmd

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_sketch.ps1"

endlocal




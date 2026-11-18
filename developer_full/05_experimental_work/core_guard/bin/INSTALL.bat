@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_SAVE_CRASH_BYPASS_V3.ps1" -GameRoot "%~1"
pause

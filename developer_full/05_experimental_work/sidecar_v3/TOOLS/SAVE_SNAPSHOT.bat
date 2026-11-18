@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_SaveSafety.ps1" -SaveDir "%~1"
pause

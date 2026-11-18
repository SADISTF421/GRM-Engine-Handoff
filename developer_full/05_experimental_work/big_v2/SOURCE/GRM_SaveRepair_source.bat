@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_SaveRepair.ps1" "%~1"
pause

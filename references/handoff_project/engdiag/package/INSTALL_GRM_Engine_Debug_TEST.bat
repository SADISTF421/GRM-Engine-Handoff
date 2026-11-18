@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Engine_Debug_TEST.ps1"
pause

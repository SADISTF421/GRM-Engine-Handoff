@echo off
chcp 65001 >nul
if "%~1"=="" (
  echo Перетащите папку игры на этот файл. Проверка только для чтения.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CHECK_ONLY.ps1" -GameRoot "%~1"
pause

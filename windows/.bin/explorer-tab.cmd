@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    set "target=%cd%"
) else (
    set "target=%~f1"
)

if "!target:~-1!"=="\" set "target=!target:~0,-1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0explorer-tab.ps1" "!target!"

endlocal

@echo off
setlocal

:: Si aucun argument n'est fourni, on utilise le dossier courant
if "%~1"=="" (
    set "target=%cd%"
) else (
    set "target=%~f1"
)

:: Appel PowerShell pour forcer l'ouverture en onglet via l'objet COM Shell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$shell = New-Object -ComObject Shell.Application; $shell.Open('%target%')"

endlocal
@echo off
REM sync-herd-php.bat <project-path> <site.test>
setlocal enabledelayedexpansion
set "CONF=%USERPROFILE%\.config\herd\config\valet\Nginx\%~2.conf"
if not exist "%~1\.phpversion" exit /b 0
if not exist "%CONF%" exit /b 0
for /f "usebackq delims=" %%V in ("%~1\.phpversion") do set "V=%%V"
findstr /c:"ISOLATED_PHP_VERSION=%V%" "%CONF%" >nul 2>&1 && exit /b 0
set "S=%V:.=%"
powershell -NoProfile -Command "$c=Get-Content '%CONF%';$c=$c-replace'^# ISOLATED_PHP_VERSION=.*','# ISOLATED_PHP_VERSION=%V%';$c=$c-replace'\$herd_sock_\d+','$herd_sock_%S%';Set-Content '%CONF%' $c"
start "" /b cmd /d /c "herd restart nginx >nul 2>&1"
endlocal

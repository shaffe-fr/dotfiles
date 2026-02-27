@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ORIG_CD=%CD%"
set "HERD_HOME=%USERPROFILE%\.config\herd\bin"
set "TARGET_PHP="

if not exist "%HERD_HOME%\php.bat" exit /b 1
if not exist "%HERD_HOME%\herd.phar" exit /b 1

if exist "%ORIG_CD%\.phpversion" (
  set /p PHP_VER=<"%ORIG_CD%\.phpversion"
  rem Trim trailing spaces and CR
  for /f "tokens=* delims= " %%V in ("!PHP_VER!") do set "PHP_VER=%%V"
  rem Remove dot so both 8.1 and 81 work
  set "PHP_VER=!PHP_VER:.=!"
  set "TARGET_PHP=%HERD_HOME%\php!PHP_VER!\php.exe"
) else (
  pushd "%ORIG_CD%" || exit /b 1
  for /f "usebackq delims=" %%A in (`
    cmd /v:on /c ""%HERD_HOME%\php.bat" "%HERD_HOME%\herd.phar" which-php "%ORIG_CD%""
  `) do set "TARGET_PHP=%%A"
  popd
)

if not defined TARGET_PHP exit /b 1
if not exist "!TARGET_PHP!" exit /b 1

pushd "%ORIG_CD%" || exit /b 1
"!TARGET_PHP!" %*
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b !EXIT_CODE!

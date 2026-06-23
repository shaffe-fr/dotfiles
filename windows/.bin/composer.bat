@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ORIG_CD=%CD%"
set "HERD_HOME=%USERPROFILE%\.config\herd\bin"
set "TARGET_PHP="

if not exist "%HERD_HOME%\herd.phar" exit /b 1

if exist "%ORIG_CD%\.phpversion" (
  set /p PHP_VER=<"%ORIG_CD%\.phpversion"
  rem Trim trailing spaces and CR
  for /f "tokens=* delims= " %%V in ("!PHP_VER!") do set "PHP_VER=%%V"
  rem Remove dot so both 8.1 and 81 work
  set "PHP_VER=!PHP_VER:.=!"
  set "TARGET_PHP=%HERD_HOME%\php!PHP_VER!\php.exe"
) else (
  rem Find the most recent php.exe under Herd to run which-php (avoids recursion via PATH)
  set "BOOTSTRAP_PHP="
  for /d %%D in ("%HERD_HOME%\php*") do (
    if exist "%%D\php.exe" set "BOOTSTRAP_PHP=%%D\php.exe"
  )
  if not defined BOOTSTRAP_PHP exit /b 1
  for /f "usebackq delims=" %%A in (`
    "!BOOTSTRAP_PHP!" "%HERD_HOME%\herd.phar" which-php "%ORIG_CD%"
  `) do set "TARGET_PHP=%%A"
)

if not defined TARGET_PHP exit /b 1
if not exist "!TARGET_PHP!" exit /b 1

pushd "%ORIG_CD%" || exit /b 1
"!TARGET_PHP!" "%HERD_HOME%\composer.phar" %*
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b !EXIT_CODE!

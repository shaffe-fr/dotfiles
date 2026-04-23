@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ORIG_CD=%CD%"
set "HERD_HOME=%USERPROFILE%\.config\herd\bin"
set "XDEBUG_DIR=%PROGRAMFILES%\Herd\resources\app.asar.unpacked\resources\bin\xdebug"
set "TARGET_PHP="
set "PHP_VER="

if not exist "%HERD_HOME%\php.bat" exit /b 1
if not exist "%HERD_HOME%\herd.phar" exit /b 1

rem --- Resolve PHP version and executable ---
if exist "%ORIG_CD%\.phpversion" (
  set /p PHP_VER=<"%ORIG_CD%\.phpversion"
  for /f "tokens=* delims= " %%V in ("!PHP_VER!") do set "PHP_VER=%%V"
  set "PHP_VER_NODOT=!PHP_VER:.=!"
  set "TARGET_PHP=%HERD_HOME%\php!PHP_VER_NODOT!\php.exe"
) else (
  pushd "%ORIG_CD%" || exit /b 1
  for /f "usebackq delims=" %%A in (`
    cmd /v:on /c ""%HERD_HOME%\php.bat" "%HERD_HOME%\herd.phar" which-php "%ORIG_CD%""
  `) do set "TARGET_PHP=%%A"
  popd
  rem Extract version (e.g. php84 -> 8.4) from path like ...\php84\php.exe
  for %%F in ("!TARGET_PHP!") do set "PHP_DIR=%%~dpF"
  for %%D in ("!PHP_DIR:~0,-1!") do set "PHP_FOLDER=%%~nxD"
  set "PHP_FOLDER=!PHP_FOLDER:php=!"
  set "PHP_VER=!PHP_FOLDER:~0,1!.!PHP_FOLDER:~1!"
)

if not defined TARGET_PHP exit /b 1
if not exist "!TARGET_PHP!" exit /b 1

rem --- Resolve absolute extension_dir from php.exe location ---
for %%P in ("!TARGET_PHP!") do set "PHP_DIR=%%~dpP"
set "EXT_DIR=!PHP_DIR!ext"

rem --- Rewrite xdebug DLL path in arguments to match resolved PHP version ---
set "ALL_ARGS=%*"

if defined ALL_ARGS (
  rem --- Strip -n flag so our -d directives are not ignored ---
  set "ALL_ARGS=!ALL_ARGS: -n = !"
  if "!ALL_ARGS:~0,3!"=="-n " set "ALL_ARGS=!ALL_ARGS:~3!"
  if "!ALL_ARGS:~-3!"==" -n" set "ALL_ARGS=!ALL_ARGS:~0,-3!"
  if "!ALL_ARGS!"=="-n" set "ALL_ARGS="

  set "XDEBUG_REPLACEMENT=xdebug-!PHP_VER!.dll"
  for %%R in ("!XDEBUG_REPLACEMENT!") do (
    for %%F in ("%XDEBUG_DIR%\xdebug-*.dll") do (
      set "ALL_ARGS=!ALL_ARGS:%%~nxF=%%~R!"
    )
  )
)

pushd "%ORIG_CD%" || exit /b 1
"!TARGET_PHP!" -d "extension_dir=!EXT_DIR!" !ALL_ARGS!
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b !EXIT_CODE!

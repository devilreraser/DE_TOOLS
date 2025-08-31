@echo off
setlocal

rem HOME = folder of this .bat (your "used" folder)
set "HOME=%~dp0"
echo HOME:%HOME%
if "%HOME:~-1%"=="\" set "HOME=%HOME:~0,-1%"

rem Get the HOME folder name even if it starts with a dot
pushd "%HOME%" >nul 2>&1 || (echo ERROR: cannot cd to HOME & exit /b 1)
for %%A in (.) do set "USER_FROM_HOME=%%~nxA"
popd >nul 2>&1

rem Optional: strip a leading dot (".home_template" -> "home_template")
if "%USER_FROM_HOME:~0,1%"=="." set "USER_FROM_HOME=%USER_FROM_HOME:~1%"

rem If the HOME folder name is "home_template", use "guest" instead
if /I "%USER_FROM_HOME%"=="home_template" set "USER_FROM_HOME=guest"

echo Derived username: %USER_FROM_HOME%

rem expose it to Bash as $USER (and override Windows %USERNAME% locally if you want)
set "USER=%USER_FROM_HOME%"
set "USERNAME=%USER_FROM_HOME%"

rem --- launch MSYS2 Bash (msys64 located at ..\bin\msys64 relative to HOME)
set "MSYS=%HOME%\..\bin\msys64"
for %%I in ("%MSYS%") do set "MSYS=%%~fI"
if not exist "%MSYS%\usr\bin\bash.exe" (
  echo ERROR: "%MSYS%\usr\bin\bash.exe" not found.
  exit /b 1
)

rem ensure .bashrc is sourced
if not exist "%HOME%\.bash_profile" (
  >"%HOME%\.bash_profile" echo if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
  "%MSYS%\usr\bin\bash.exe" -lc "sed -i 's/\r$//' ~/.bash_profile"
)
::start "" "%MSYS%\usr\bin\bash.exe" --login -i

rem after HOME/USER/MSYS are set...

rem Prefer MSYS paths over Windows ones (or use STRICT to hide Windows PATH)
set "MSYS2_PATH_TYPE=prefer"
:: or inherit from windows
::set "MSYS2_PATH_TYPE=inherit"

rem Put your portable MSYS first on PATH (and you can omit %PATH% if you want fully isolated)
set "PATH=%MSYS%\usr\bin;%MSYS%\bin;"
:: or add also windows path
::set "PATH=%MSYS%\usr\bin;%MSYS%\bin;%PATH%"


set "PROMPT_TAG=DE Tools"
set "WINPORTABLE_USER=%USER_FROM_HOME%"
set "WINPORTABLE_HOST=DE_TOOLS"
::start "DE" "%MSYS%\usr\bin\mintty.exe" -t "MSYS2" /usr/bin/bash -li
start "%PROMPT_TAG%" "%MSYS%\usr\bin\mintty.exe" /usr/bin/bash -lc "echo User:$USER; echo Host:$WINPORTABLE_HOST; echo Home:$HOME; exec bash -li"

::pause
exit /b





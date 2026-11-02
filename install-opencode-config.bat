@echo off
setlocal EnableExtensions
rem ============================================================
rem  ArtCraftMCP - install-opencode-config.bat
rem  Copies the repo's opencode.json to the current user's
rem  global OpenCode config and relaunches OpenCode so the
rem  ArtCraft MCP servers are picked up.
rem
rem  Source : opencode.json next to this .bat (portable, uses
rem           "--allow-path" "." so no hardcoded username)
rem  Target : %USERPROFILE%\.config\opencode\opencode.json
rem           (OpenCode global config on Windows)
rem ============================================================

set "SRC_DIR=%~dp0"
set "SRC_FILE=%SRC_DIR%opencode.json"
set "DST_DIR=%USERPROFILE%\.config\opencode"
set "DST_FILE=%DST_DIR%\opencode.json"

echo [1/4] Checking source config...
if not exist "%SRC_FILE%" (
  echo ERROR: Source not found: "%SRC_FILE%"
  echo Put this .bat next to opencode.json from the ArtCraftMCP repo.
  exit /b 1
)
echo   Found: "%SRC_FILE%"

echo [2/4] Ensuring target dir exists...
if not exist "%DST_DIR%" (
  mkdir "%DST_DIR%"
  if errorlevel 1 (
    echo ERROR: Could not create "%DST_DIR%"
    exit /b 1
  )
)
echo   Target dir: "%DST_DIR%"

echo [3/4] Installing global config...
rem Keep a backup of any existing global config
if exist "%DST_FILE%" (
  copy /Y "%DST_FILE%" "%DST_FILE%.bak" >nul
  if errorlevel 1 (
    echo WARNING: Could not back up existing config, continuing anyway.
  ) else (
    echo   Backed up old config to "%DST_FILE%.bak"
  )
)
copy /Y "%SRC_FILE%" "%DST_FILE%" >nul
if errorlevel 1 (
  echo ERROR: Copy failed.
  exit /b 1
)
echo   Installed: "%DST_FILE%"

echo [4/4] Relaunching OpenCode...
where opencode >nul 2>&1
if errorlevel 1 (
  echo WARNING: 'opencode' not found on PATH.
  echo Install OpenCode first, then re-run this script.
  echo See README.md ^"Fix: opencode isn't installed or isn't on your PATH^".
  exit /b 2
)

rem Stop running OpenCode processes so they pick up the new config
taskkill /F /IM opencode.exe >nul 2>&1
timeout /t 2 /nobreak >nul

rem Verify MCP servers are registered (non-fatal if some ArtCraft apps are not installed)
echo   Running: opencode mcp list
call opencode mcp list
echo.
echo   Starting OpenCode TUI...
start "" opencode

echo Done. If a server shows FAILED, that ArtCraft app is probably
echo not installed at C:\Program Files\... - see README.md.
endlocal

@echo off
setlocal EnableExtensions
rem ============================================================
rem  ArtCraftMCP - install-opencode-config.bat
rem  Merges this repo's opencode.json into the current user's
rem  global OpenCode config and relaunches OpenCode.
rem
rem  Source : opencode.json next to this .bat (portable, "." roots,
rem           no hardcoded username)
rem  Target : %USERPROFILE%\.config\opencode\opencode.json
rem           (OpenCode global config on Windows)
rem
rem  MERGE behavior (does NOT overwrite):
rem   - every mcp.servers entry from the repo is added/updated
rem   - entries already in your global config but NOT in the repo
rem     (e.g. "blender") are KEPT
rem   - top-level keys already set globally (e.g. "model",
rem     "small_model") are KEPT; repo only fills gaps
rem   - a timestamped .bak is written before every change
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

echo [3/4] Merging repo config into global config...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SRC_DIR%merge-opencode-config.ps1" -Repo "%SRC_FILE%" -GlobalPath "%DST_FILE%"
if errorlevel 1 (
  echo ERROR: Merge failed. Your global config was NOT changed
  echo        (a .bak is written before any change).
  exit /b 1
)
echo   Merged OK: "%DST_FILE%"

echo [4/4] Relaunching OpenCode...
where opencode >nul 2>&1
if errorlevel 1 (
  echo WARNING: 'opencode' not found on PATH.
  echo Install OpenCode first, then re-run this script.
  echo See README.md section "opencode isn't installed or isn't on your PATH".
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

echo Done. 'failed' on exactly one server usually means that
echo ArtCraft app is not installed - see README.md section 4.
endlocal

@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title EGMIS School System - LAN Server

echo.
echo ==========================================
echo     EGMIS School System - LAN Mode
echo ==========================================
echo.
where py >nul 2>nul
if errorlevel 1 (echo ERROR: Python launcher not found. Install Python 3.11+ and enable PATH.& pause & exit /b 1)
REM Repair an interrupted or damaged virtual environment before installing.
if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" -c "import pip, pip._internal.utils" >nul 2>nul
  if errorlevel 1 (
    echo Existing .venv has a damaged pip installation. Recreating it...
    rmdir /s /q ".venv"
  )
)
if not exist ".venv\Scripts\python.exe" (
  echo Creating a fresh virtual environment...
  py -3 -m venv .venv
  if errorlevel 1 goto :error
)
echo Repairing pip and installing/checking dependencies...
".venv\Scripts\python.exe" -m ensurepip --upgrade
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -c "import pip, pip._internal.utils" >nul 2>nul
if errorlevel 1 (
  echo ERROR: pip is damaged. Delete .venv and repair/reinstall Python, then retry.
  goto :error
)
".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto :error
".venv\Scripts\python.exe" scripts\prepare_env.py
if errorlevel 1 goto :error
echo Applying database migrations and safe additive schema checks...
".venv\Scripts\python.exe" -m flask --app run.py db upgrade
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m flask --app run.py ensure-school-records-schema
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m flask --app run.py seed-grade-levels
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m flask --app run.py init-roles
if errorlevel 1 goto :error

echo.
echo Detecting LAN configuration from .env and this computer...
for /f "tokens=1,2 delims==" %%A in ('".venv\Scripts\python.exe" scripts\lan_config.py') do (
  if "%%A"=="LAN_PORT" set EGMIS_LAN_PORT=%%B
  if "%%A"=="LAN_HOSTNAME" set EGMIS_LAN_HOSTNAME=%%B
  if "%%A"=="LAN_IP" echo   http://%%B:!EGMIS_LAN_PORT!
)
if not defined EGMIS_LAN_PORT set EGMIS_LAN_PORT=8080
echo.
if defined EGMIS_LAN_HOSTNAME (echo Configured friendly hostname: %EGMIS_LAN_HOSTNAME% & echo   http://%EGMIS_LAN_HOSTNAME%:%EGMIS_LAN_PORT%) else (echo Optional: configure EGMIS_LAN_HOSTNAME in .env and create the matching local DNS record on your router.)
echo LAN listener: 0.0.0.0:%EGMIS_LAN_PORT% (all network interfaces)
echo.
echo Starting EGMIS with Waitress. Keep this window open. Press Ctrl+C to stop.
echo IMPORTANT: HTTP LAN access works for normal use, but PWA installation/service workers require HTTPS on phones.
echo Use a stable local DNS hostname plus a trusted HTTPS certificate for consistent PWA installation.
echo Allow inbound TCP %EGMIS_LAN_PORT% only on the Windows Private firewall profile and trusted school network.
echo Do NOT enable router port forwarding or expose this listener directly to the internet.
echo.
".venv\Scripts\waitress-serve.exe" --listen=0.0.0.0:%EGMIS_LAN_PORT% run:app
if errorlevel 1 goto :error
exit /b 0
:error
echo.
echo ERROR: LAN startup failed. Review the messages above and README.md.
pause
exit /b 1

@echo off
setlocal
cd /d "%~dp0"
title EGMIS School System

echo.
echo ==========================================
echo       EGMIS School System Launcher
echo ==========================================
echo.

where py >nul 2>nul
if errorlevel 1 (
    echo ERROR: Python launcher "py" was not found.
    echo Install Python 3.11 or newer from https://www.python.org/downloads/
    echo During installation, enable the Python launcher and PATH options.
    pause
    exit /b 1
)

REM Validate an existing environment before trusting it. A partially copied or
REM interrupted .venv can contain a broken pip package and must be recreated.
if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" -c "import pip, pip._internal.utils" >nul 2>nul
    if errorlevel 1 (
        echo Existing .venv has a damaged pip installation. Recreating it...
        rmdir /s /q ".venv"
    ) else (
        echo [1/5] Existing Python virtual environment and pip are valid.
    )
)

if not exist ".venv\Scripts\python.exe" (
    echo [1/5] Creating a fresh Python virtual environment...
    py -3 -m venv .venv
    if errorlevel 1 goto :error
)

echo.
echo [2/5] Repairing pip and installing dependencies...
".venv\Scripts\python.exe" -m ensurepip --upgrade
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -c "import pip, pip._internal.utils" >nul 2>nul
if errorlevel 1 (
    echo ERROR: pip is still damaged after environment creation.
    echo Delete the .venv folder and verify your Python installation, then retry.
    goto :error
)
".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto :error

echo.
echo [3/5] Preparing environment configuration...
".venv\Scripts\python.exe" scripts\prepare_env.py
if errorlevel 1 goto :error

if not exist "migrations\env.py" (
    echo.
    echo [4/5] Initializing database migrations and schema...
    ".venv\Scripts\python.exe" -m flask --app run.py db init
    if errorlevel 1 goto :error
    ".venv\Scripts\python.exe" -m flask --app run.py db migrate -m "initial schema"
    if errorlevel 1 goto :error
    ".venv\Scripts\python.exe" -m flask --app run.py db upgrade
    if errorlevel 1 goto :error
    ".venv\Scripts\python.exe" -m flask --app run.py init-roles
    if errorlevel 1 goto :error
) else (
    echo.
    echo [4/5] Applying pending database migrations...
    ".venv\Scripts\python.exe" -m flask --app run.py db upgrade
    if errorlevel 1 goto :error
    echo [5/5] Existing migration history detected.
)

echo.
echo Checking additive school-records schema (existing tables/data are retained)...
".venv\Scripts\python.exe" -m flask --app run.py ensure-school-records-schema
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m flask --app run.py seed-grade-levels
if errorlevel 1 goto :error
".venv\Scripts\python.exe" -m flask --app run.py init-roles
if errorlevel 1 goto :error


echo.
echo Starting EGMIS School System...
echo On a new installation, open http://127.0.0.1:5000/setup to complete the first-run wizard.
echo After setup, sign in at http://127.0.0.1:5000/auth/login.
echo Keep this window open while using the application.
echo Press Ctrl+C to stop the server.
echo.
".venv\Scripts\python.exe" run.py
if errorlevel 1 goto :error
exit /b 0

:error
echo.
echo ERROR: Setup or startup failed. Review the message above.
echo See README.md for troubleshooting and setup details.
pause
exit /b 1

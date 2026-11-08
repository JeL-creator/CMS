@echo off
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo EGMIS virtual environment not found. Run start.bat first.
  pause
  exit /b 1
)
echo Running database integrity checks...
".venv\Scripts\python.exe" -m flask --app run.py check-db-integrity
if errorlevel 1 goto :failed
echo.
echo Running application route registration check...
".venv\Scripts\python.exe" -m flask --app run.py routes > system-routes-check.txt
if errorlevel 1 goto :failed
echo Route listing written to system-routes-check.txt
 echo.
echo Basic checks passed. This is not a replacement for end-to-end acceptance tests or a restore drill.
pause
exit /b 0
:failed
echo A system check failed. Review the output above.
pause
exit /b 1

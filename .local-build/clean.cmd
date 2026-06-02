@echo off
CHCP 1252
setlocal

set "ROOT=%~dp0.."

call :run_clean "josyn-sandbox-demo-job"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call :run_clean "josyn-sandbox-dev-host"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo [OK] NuGet-Cache bereinigt.
exit /b 0

:run_clean
echo.
echo ======================================================
echo  %~1
echo ======================================================
call "%ROOT%\%~1\.local-build\clean.cmd" NOPAUSE
exit /b %ERRORLEVEL%

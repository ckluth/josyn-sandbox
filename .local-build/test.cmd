@echo off
CHCP 1252
setlocal

set "ROOT=%~dp0.."

call :run_test "josyn-playground-demo-job"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call :run_test "josyn-playground-dev-host"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo [OK] Alle Tests abgeschlossen.
exit /b 0

:run_test
echo.
echo ======================================================
echo  %~1
echo ======================================================
call "%ROOT%\%~1\.local-build\test.cmd"
exit /b %ERRORLEVEL%

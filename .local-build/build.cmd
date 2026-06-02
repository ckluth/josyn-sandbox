@echo off
CHCP 1252
setlocal

:: -------------------------------------------------------
:: Aufruf:  build.cmd [Release|Debug]
:: Default: Release
:: Fuehrt build.cmd in allen Sub-Repos in der
:: korrekten Abhaengigkeits-Reihenfolge aus.
:: -------------------------------------------------------
set "CONFIGURATION=%~1"
if not defined CONFIGURATION set "CONFIGURATION=Release"

if /i "%CONFIGURATION%" neq "Release" if /i "%CONFIGURATION%" neq "Debug" (
    echo [FEHLER] Unbekannte Konfiguration: "%CONFIGURATION%"
    echo          Erlaubt: Release, Debug
    exit /b 1
)

set "ROOT=%~dp0.."

call :run_build "josyn-sandbox-demo-job"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call :run_build "josyn-sandbox-dev-host"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo [OK] Alle Sub-Repos erfolgreich gebaut (%CONFIGURATION%).
exit /b 0

:run_build
echo.
echo ======================================================
echo  %~1
echo ======================================================
call "%ROOT%\%~1\.local-build\build.cmd" %CONFIGURATION%
exit /b %ERRORLEVEL%

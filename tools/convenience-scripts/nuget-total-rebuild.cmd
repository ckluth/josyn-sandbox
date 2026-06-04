@echo off
CHCP 1252
setlocal

CALL "%~dp0..\cfg\cfg-detect-root.cmd"
CALL "%~dp0..\cfg\cfg-repos-list.cmd"

echo.
echo ======================================================
echo  Clearing JOSYN packages from NuGet cache
echo ======================================================

set "NUGET_BASE=%USERPROFILE%\.nuget\packages"

for /d %%P in ("%NUGET_BASE%\josyn.*") do (
    echo Loesche: %%P
    rd /s /q "%%P"
    if errorlevel 1 ( echo   FEHLER ) else ( echo   OK )
)

echo.
echo ======================================================
echo  Clearing local-packages output folder
echo ======================================================

if exist "%ROOT%\local-packages" (
    echo   Folder to clear: %ROOT%\local-packages
    set /p "CONFIRM=  Press Enter to delete contents, Ctrl+C to abort: "
    del /q "%ROOT%\local-packages\*.*"
    if errorlevel 1 ( echo   FEHLER & pause & exit /b 1 ) else ( echo   OK )
) else (
    echo   (folder did not exist)
)

echo.
echo ======================================================
echo  Running pack.cmd for all repos
echo ======================================================

for %%R in (%REPOS%) do (
    if exist "%%R\.local-build\pack.cmd" (
        echo.
        echo ------------------------------------------------------
        echo  %%R
        echo ------------------------------------------------------
        call "%%R\.local-build\pack.cmd"
        if %ERRORLEVEL% neq 0 (
            echo [ERROR] pack.cmd failed for %%R
            pause
            exit /b %ERRORLEVEL%
        )
    )
)

echo.
echo [OK] JOSYN NuGet-Cache bereinigt und alle Pakete neu erstellt.
pause
@echo off
CHCP 1252
setlocal

set "LOCAL_BUILD=%~dp0"

echo.
echo === clean ===
call "%LOCAL_BUILD%clean.cmd"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo === build ===
call "%LOCAL_BUILD%build.cmd"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo === test ===
call "%LOCAL_BUILD%test.cmd"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo === pack ===
call "%LOCAL_BUILD%pack.cmd"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo.
echo [OK] Clean - Build - Test - Pack erfolgreich.

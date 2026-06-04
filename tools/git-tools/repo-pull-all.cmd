@echo off

CALL "%~dp0..\cfg\cfg-detect-root.cmd"

CALL "%~dp0..\cfg\cfg-repos-list.cmd"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.internal\repo-pull-all.ps1" %REPOS%

pause

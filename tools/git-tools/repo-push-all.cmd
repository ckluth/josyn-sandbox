chcp 1252
@echo off

CALL "%~dp0..\cfg\cfg-detect-root.cmd"

CALL "%~dp0..\cfg\cfg-repos-list.cmd"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.internal\repo-push-all.ps1" %REPOS%

pause

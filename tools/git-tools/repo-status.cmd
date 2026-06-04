@echo off
CHCP 1252

CALL "%~dp0.internal\cfg-detect-root.cmd"

CALL "%~dp0.internal\cfg-repos-list.cmd"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.internal\repo-status.ps1" %REPOS%

pause
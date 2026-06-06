@echo off
CHCP 1252
pwsh -ExecutionPolicy Bypass -File "%~dp0deploy-maintainer.ps1" -SkipNugets
pause

@echo off

REM ── Configuration ────────────────────────────────────────────────────────────

SET "SOURCE=%~dp0..\..\..\josyn-platform\solution-architecture"
SET "OUTPUT=C:\Temp\josyn-docs"
SET "TITLE=JOSYN Enterprise Architecture"

REM ─────────────────────────────────────────────────────────────────────────────

dotnet run --project "%~dp0DocGenerator.csproj" -- "%SOURCE%" "%OUTPUT%" "%TITLE%"

pause
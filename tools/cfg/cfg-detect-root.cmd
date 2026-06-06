@echo off

REM -- Machine -> ROOT mapping ------------------------------------------------
REM
REM  Add one block per machine class. FINDSTR /B = starts-with, /I = case-insensitive.
REM  First match wins. The final ELSE branch is the personal-machine fallback.
REM
REM  To add a new class:
REM    ECHO %COMPUTERNAME% | FINDSTR /B /I "PREFIX-" >NUL
REM    IF %ERRORLEVEL%==0 ( SET "ROOT=C:\YourPath" & GOTO :root_resolved )

ECHO %COMPUTERNAME% | FINDSTR /B /I "RZ-" >NUL
IF %ERRORLEVEL%==0 ( SET "ROOT=C:\DevGit" & GOTO :root_resolved )

REM Fallback - personal machine
REM SET "ROOT=C:\Users\chris\OneDrive\DevGit"
SET "ROOT=C:\DevGit"

:root_resolved

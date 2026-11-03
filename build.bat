@echo off
REM Build script for AimeeBugFixes mod
REM This script builds the mod DLL and outputs it to the Workshop directory

echo Building AimeeBugFixes mod...

REM Clean previous build
if exist bin rmdir /s /q bin

REM Build with Release configuration
dotnet build --configuration Release --no-restore

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build succeeded!
    echo Output: C:\Users\TJ\Desktop\StationeersServer\mods\Workshop_3674960841\AimeeBugFixes.dll
) else (
    echo.
    echo Build failed!
)

pause

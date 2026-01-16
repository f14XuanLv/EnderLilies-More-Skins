@echo off
rem Engine install path (UE 4.26.2)
set "UE4PATH=C:\Game\UE\UE_4.26"

rem Check if directory exists
if not exist "%UE4PATH%\*" (
    echo Error: UE4 directory not found: %UE4PATH%
    echo Please check the path in config.bat and set your actual UE4.26.2 path
    pause
    exit /b 1
)
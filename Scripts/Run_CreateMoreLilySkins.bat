@echo off
setlocal

rem 1. Get UE path from config
if not exist "%~dp0config.bat" (
    echo [ERROR] config.bat missing.
    pause
    exit /b 1
)
call "%~dp0config.bat"

rem 2. Set project and script paths
set "UPROJECT=%~dp0..\EnderLilies.uproject"
set "PYTHON_SCRIPT=%~dp0CreateMoreLilySkins.py"
set "UE4_CMD=%UE4PATH%\Engine\Binaries\Win64\UE4Editor-Cmd.exe"

:check_editor
rem --- Check if Unreal Editor is running ---
tasklist /FI "IMAGENAME eq UE4Editor.exe" 2>NUL | find /I /N "UE4Editor.exe">NUL
if errorlevel 1 (
    rem ERRORLEVEL 1 means UE4Editor.exe was NOT found - This is GOOD
    goto run_script
)

rem If we reach here, Editor is running
echo ============================================================
echo [WARNING] Unreal Editor is currently running!
echo ============================================================
echo.
echo The script may fail or crash because the Editor locks assets 
echo (like DataTables or Textures).
echo.
echo Options:
echo [1] I have closed the Editor. (Check again)
echo [2] Run Anyway. (Not recommended)
echo [3] Exit.
echo.

set /p choice="Please enter [1, 2, or 3]: "

if "%choice%"=="1" goto check_editor
if "%choice%"=="2" (
    echo [INFO] Proceeding anyway...
    goto run_script
)
if "%choice%"=="3" exit /b 1

echo [Invalid selection]
goto check_editor

:run_script
if not exist "%UE4_CMD%" (
    echo [ERROR] UE4Editor-Cmd.exe not found at %UE4_CMD%
    pause
    exit /b 1
)

rem 3. Execute Python script
echo [INFO] Running Python script via UE4Editor-Cmd...
"%UE4_CMD%" "%UPROJECT%" -run=pythonscript -script="%PYTHON_SCRIPT%" -unattended -nopause -nosplash -stdout -UTF8Output

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================
    echo [SUCCESS] Mod assets generated and chunked!
    echo Now you can run ".\Scripts\package.bat".
    echo ============================================================
) else (
    echo.
    echo [FAILED] Python script execution failed.
    echo If the Editor was open, please close it and try again.
)

pause
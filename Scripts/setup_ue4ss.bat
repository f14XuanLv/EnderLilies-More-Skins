@echo off
setlocal enabledelayedexpansion

rem Download and setup UE4SS v3.0.1
rem Downloads zip file, extracts to a specific folder, cleans up, and adds mods

set "ZIP_URL=https://github.com/UE4SS-RE/RE-UE4SS/releases/download/v3.0.1/UE4SS_v3.0.1.zip"
set "ZIP_FILE=%~dp0..\UE4SS_v3.0.1.zip"
set "EXTRACT_DIR=%~dp0..\UE4SS_For_More_Skins_Mod"
set "PROJECT_ROOT=%~dp0.."
set "LUAMODS_DIR=%~dp0..\LuaMods"

rem Check if zip file already exists
if exist "%ZIP_FILE%" (
    echo Found existing %ZIP_FILE%, skipping download
) else (
    echo Downloading UE4SS_v3.0.1.zip...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%'}"
    
    if errorlevel 1 (
        echo Error: Download failed
        exit /b 1
    )
    echo Download complete
)

rem Prepare extraction directory
if exist "%EXTRACT_DIR%" (
    echo Cleaning old extraction directory...
    rd /s /q "%EXTRACT_DIR%"
)
mkdir "%EXTRACT_DIR%"

rem Extract zip file directly into the target folder
echo Extracting %ZIP_FILE% to %EXTRACT_DIR%...
powershell -Command "& {Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force}"

if errorlevel 1 (
    echo Error: Extraction failed
    exit /b 1
)
echo Extraction complete

rem Remove unnecessary files and folders using a loop
echo Cleaning up unnecessary files...
set "TO_REMOVE=ActorDumperMod CheatManagerEnablerMod ConsoleCommandsMod ConsoleEnablerMod jsbLuaProfilerMod Keybinds LineTraceMod SplitScreenMod"

for %%G in (%TO_REMOVE%) do (
    if exist "%EXTRACT_DIR%\Mods\%%G" (
        rd /s /q "%EXTRACT_DIR%\Mods\%%G"
    )
)

if exist "%EXTRACT_DIR%\Changelog.md" del /f /q "%EXTRACT_DIR%\Changelog.md"
if exist "%EXTRACT_DIR%\README.md" del /f /q "%EXTRACT_DIR%\README.md"

echo Cleanup complete

rem Copy custom mod files
echo Copying custom mod files...

rem Ensure target Mods folder exists
if not exist "%EXTRACT_DIR%\Mods" mkdir "%EXTRACT_DIR%\Mods"

rem Copy SwitchSkinMod folder
if exist "%LUAMODS_DIR%\SwitchSkinMod" (
    echo Copying SwitchSkinMod...
    xcopy /s /e /y /i "%LUAMODS_DIR%\SwitchSkinMod" "%EXTRACT_DIR%\Mods\SwitchSkinMod" >nul
) else (
    echo Warning: LuaMods\SwitchSkinMod not found
)

rem Copy mods.txt file
if exist "%LUAMODS_DIR%\mods.txt" (
    echo Copying mods.txt...
    copy /y "%LUAMODS_DIR%\mods.txt" "%EXTRACT_DIR%\Mods\mods.txt" >nul
) else (
    echo Warning: LuaMods\mods.txt not found
)

echo.
echo UE4SS setup complete!
echo UE4SS installed to: %EXTRACT_DIR%
echo.

endlocal
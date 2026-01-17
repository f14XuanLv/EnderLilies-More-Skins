@echo off
setlocal

call "%~dp0config.bat"

set UPROJ=%~dp0..\EnderLilies.uproject
set STAGE_DIR=%~dp0..\Saved\StagedBuilds
set "BIN_DIR=%~dp0..\Binaries\Win64"
set "DUMMY_EXE=%BIN_DIR%\EnderLilies.exe"

if not exist "%UPROJ%" (
  echo Cannot find EnderLilies.uproject at "%UPROJ%".
  exit /b 1
)

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

set "CREATED_DUMMY=0"
if not exist "%DUMMY_EXE%" (
    echo [INFO] Creating dummy placeholder for UAT: %DUMMY_EXE%
    type nul > "%DUMMY_EXE%"
    set "CREATED_DUMMY=1"
)

echo Running BuildCookRun via RunUAT...
call "%UE4PATH%\\Engine\\Build\BatchFiles\\RunUAT.bat" BuildCookRun^
 -SkipCookingEditorContent -installed -nop4 -project="%UPROJ%"^
 -stagingdirectory="%STAGE_DIR%"^
 -prereqs -nodebuginfo -manifests -targetplatform=Win64 -clientconfig=Development -utf8output -iostore^
 -cook -stage -pak -package ^
 -nocompile -nocompileeditor ^
 -ddc=InstalledDerivedDataBackendGraph

if "%CREATED_DUMMY%"=="1" (
    if exist "%DUMMY_EXE%" (
        echo [CLEANUP] Removing dummy placeholder...
        del /f /q "%DUMMY_EXE%"
    )
)

echo Copying iostore pak to EnderLilies_Skin_Mod directory...
call "%~dp0copy.bat"

endlocal
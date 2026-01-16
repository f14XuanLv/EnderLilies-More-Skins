@echo off
setlocal

rem Build GameEditorTarget
rem Requires UE4PATH to be set in config.bat.

call "%~dp0config.bat"

rem Path to Build.bat
set "BUILD_BATCH_FILE=%UE4PATH%\Engine\Build\BatchFiles\Build.bat"

rem Path to the .uproject file
set "PROJECT_FILE=%~dp0..\EnderLilies.uproject"

rem Build the GameEditorTarget.
call "%BUILD_BATCH_FILE%" EnderLiliesEditor Win64 Development -Project="%PROJECT_FILE%" -WaitMutex
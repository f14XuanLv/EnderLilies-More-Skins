@echo off
setlocal

set SRC=%~dp0..\Saved\StagedBuilds\WindowsNoEditor\EnderLilies\Content\Paks
set DST=%~dp0..\LogicMods
set BASE2=pakchunk2-WindowsNoEditor
set BASE3=pakchunk3-WindowsNoEditor
set BASE4=pakchunk4-WindowsNoEditor

if not exist "%SRC%" (
  echo Source Paks folder not found: %SRC%
  exit /b 1
)

if not exist "%DST%" (
  mkdir "%DST%"
)

echo Copying Chunk2 files...
for %%E in (pak ucas utoc) do (
  if exist "%SRC%\%BASE2%.%%E" (
    copy /Y "%SRC%\%BASE2%.%%E" "%DST%\EnderLilies_More_Skins_Mod.%%E" >nul
    echo Copied %BASE2%.%%E to EnderLilies_More_Skins_Mod.%%E
  ) else (
    echo Missing file: %SRC%\%BASE2%.%%E
  )
)

echo.
echo Copying Chunk3 files...
for %%E in (pak ucas utoc) do (
  if exist "%SRC%\%BASE3%.%%E" (
    copy /Y "%SRC%\%BASE3%.%%E" "%DST%\EnderLilies_More_Skins_Mod_Chunk3_0_P.%%E" >nul
    echo Copied %BASE3%.%%E to EnderLilies_More_Skins_Mod_Chunk3_0_P.%%E
  ) else (
    echo Missing file: %SRC%\%BASE3%.%%E
  )
)

echo.
echo Copying Chunk4 files...
for %%E in (pak ucas utoc) do (
  if exist "%SRC%\%BASE4%.%%E" (
    copy /Y "%SRC%\%BASE4%.%%E" "%DST%\EnderLilies_More_Skins_Mod_Chunk4_0_P.%%E" >nul
    echo Copied %BASE4%.%%E to EnderLilies_More_Skins_Mod_Chunk4_0_P.%%E
  ) else (
    echo Missing file: %SRC%\%BASE4%.%%E
  )
)

endlocal
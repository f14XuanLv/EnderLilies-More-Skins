# SDK Environment Requirements and Configuration

This document will guide you through setting up the complete development environment for ENDER LILIES "More Skins" mod.

## I. Environment Requirements

### 1. Basic Development Environment (Required)
*   **Operating System**: Windows 10 or higher
*   **Unreal Engine**: UE 4.26.2

### 2. Core Toolchain (As Needed)
*   **Deep Development (if your work involves C++ source code modifications)**: 
    *   Visual Studio 2019 or 2022
    *   Workload: Desktop Development with C++
    *   Windows SDK: 10.0.18362 or higher
*   **Skin Creation (Art)**:
    *   Spine Pro: 3.8.99 (tested compatible with 3.8.75)
    *   Image Processing: Adobe Photoshop or similar software
*   **Version Control**: 
    *   Git

## II. Project Acquisition and Basic Configuration

### 1. Clone the Project
It's recommended to clone the project repository locally using Git:
```bash
git clone https://github.com/f14XuanLv/EnderLilies-More-Skins.git
```

### 2. Configure Engine Path
To enable automation scripts, you must associate your Unreal Engine installation path:
1.  Open [`Scripts/config.bat`](/Scripts/config.bat).
2.  Modify `UE4PATH` to your actual installation directory:
    ```bat
    set "UE4PATH=C:\Game\UE\UE_4.26"
    ```

## III. Quick Start: Build and Initialize

After configuring the engine path, please execute in the following order. This project has built-in customized UE4SS that fixes compatibility issues, no additional installation needed.

### 1. Verify Project Launch
*   **Action**: Double-click [`EnderLilies.uproject`](/EnderLilies.uproject) in the project root directory.
*   **Goal**: Ensure successful entry into Unreal Editor without error popups. If errors occur here, please check if UE 4.26.2 is correctly installed.

### 2. Execute Automated Build
Run the following two scripts in sequence to generate necessary mod files using sample assets in the project:

1.  **Generate Mod Assets**: Execute [`Scripts/Run_CreateMoreLilySkins.bat`](/Scripts/Run_CreateMoreLilySkins.bat)
    *   *Function: Scans the [`ExtendSkins`](/ExtendSkins/) directory, automatically completes asset conversion, skin classification, data table injection, and chunking configuration.*
2.  **Package Resources (Cook & Package)**: Execute [`Scripts/package.bat`](/Scripts/package.bat)
    *   *Function: Compiles and extracts assets, generating game-readable patch packages (LogicMods).*

## IV. Advanced Development: C++ Compilation

If you have modified the **C++ source code** in the `Source/` or `Plugins/` directories (e.g., similar to those described in [Source Code Modifications and Alignment](/docs/DEVELOPMENT_NOTES.md)), you must recompile the project for the changes to take effect.

*   **Prerequisites**: Ensure Visual Studio and C++ components are installed as per the [Core Toolchain](#2-core-toolchain-as-needed) section.
*   **Action**: Close Unreal Editor and execute [`Scripts/Build_GameEditorTarget.bat`](/Scripts/Build_GameEditorTarget.bat).
*   **Function**: This script invokes the Unreal Build Tool (UBT) to recompile C++ source code into editor binaries (.dll) for the Win64 platform.
*   **Goal**: Once the compilation is complete, restart [`EnderLilies.uproject`](/EnderLilies.uproject) to load the updated code logic.

## V. Completeness Checklist

After completing the above steps, if your project directory contains the following artifacts, the SDK development environment has been successfully set up.

### 1. Mod Artifacts (LogicMods)
*   [ ] `LogicMods/` folder has been generated.
*   [ ] Folder contains corresponding `.pak`, `.ucas`, and `.utoc` files.

### 2. Loader Environment (UE4SS)
*   [ ] `UE4SS_For_More_Skins_Mod/` folder exists immediately after cloning the project.
*   [ ] Contains core customized components: `dwmapi.dll`, `UE4SS.dll`, `UE4SS-settings.ini`.
*   [ ] See [`UE4SS_VERSION.md`](/UE4SS_For_More_Skins_Mod/UE4SS_VERSION.md) for specific version traceability information.

### 3. Data Validation (DataTable)
*   [ ] `Content/_Zenith/Gameplay/Data/DT_SpineData_p0000.uasset` has been automatically updated based on `ExtendSkins` content.
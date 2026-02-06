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

After configuring the engine path, please execute in the following order. This is not only the process of building the mod but also a comprehensive check of the development environment.

### 1. Verify Project Launch
*   **Action**: Double-click [`EnderLilies.uproject`](/EnderLilies.uproject) in the project root directory.
*   **Goal**: Ensure successful entry into Unreal Editor without error popups. If errors occur here, please check if UE 4.26.2 is correctly installed.

### 2. Execute Automated Build
Run the following three scripts in sequence to generate necessary mod files using sample assets in the project:

1.  **Generate Mod Assets**: Execute [`Scripts/Run_CreateMoreLilySkins.bat`](/Scripts/Run_CreateMoreLilySkins.bat)
    *   *Function: Scans the [`ExtendSkins`](/ExtendSkins/) directory, automatically performs asset conversion (PNG/Spine -> .uasset), skin classification (Simple/Advanced), data table injection, and chunking configuration.*
2.  **Package Resources (Cook & Package)**: Execute [`Scripts/package.bat`](/Scripts/package.bat)
    *   *Function: Compiles and extracts assets, generating game-readable patch packages.*
3.  **Configure Injection Tool (UE4SS)**: Execute [`Scripts/setup_ue4ss.bat`](/Scripts/setup_ue4ss.bat)
    *   *Function: Initializes the mod loader environment.*

## IV. Completeness Checklist

After completing the above steps, if your project directory contains the following artifacts, the SDK development environment has been successfully set up.

### 1. Mod Artifacts (LogicMods)
*   [ ] `LogicMods/` folder has been generated.
*   [ ] Folder contains corresponding `.pak`, `.ucas`, and `.utoc` files.

### 2. Loader Environment (UE4SS)
*   [ ] `UE4SS_For_More_Skins_Mod/` folder has been generated.
*   [ ] Contains core components: `dwmapi.dll`, `UE4SS.dll`, `UE4SS-settings.ini`.
*   [ ] `Mods/` folder has been properly initialized.

### 3. Data Validation (DataTable)
*   [ ] `Content/_Zenith/Gameplay/Data/DT_SpineData_p0000.uasset` has been automatically updated based on `ExtendSkins` content.
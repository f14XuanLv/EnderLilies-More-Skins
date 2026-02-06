# Skin Creation and Integration Guidelines

This document will guide you through understanding the skin classification standards and file structure requirements for this mod, and how to import your art assets into Unreal Engine via automation scripts.

## 📝 Prerequisites

Before creating skins, please ensure you have completed the following preparations:
1.  ✅ **Environment Ready**: You have successfully set up the full development environment and completed the packaging process following the **[Getting Started Guide (GETTING_STARTED.md)](GETTING_STARTED.md)**.
2.  ✅ **Understand the Toolbox**: We strongly recommend using the **[ENDER LILIES More Skins Modding Toolkit](https://f14xuanlv.github.io/EnderLilies-More-Skins-Modding-Toolkit/)** along with its **[Documentation](https://github.com/f14XuanLv/EnderLilies-More-Skins-Modding-Toolkit/blob/main/README.md)** for creation, which can save you 90% of the time for basic resource acquisition and configuration.

---

## 🎯 Core Concepts: Skin Types and Limitations

The engine automation import script (Python) automatically determines your skin type based on **folder names** and **file extensions**. This mod supports the following two forms:

### 1. Simple Skins
*   **Use Case**: Only modify character appearance colors and patterns, without changing model silhouette or actions.
*   **Naming Convention**: `p000x_y_Lily.png` (where $x \in [1, 6]$ is the original stage, $y \ge 1$ is your custom sequence number).
*   **Technical Limitations**:
    *   **Must** be `1024x256` pixels.
    *   Based on original texture modifications, cannot modify skeletal animations (`.skel`).
    *   *Note: You can use the online toolkit's "Simple Skin Texture Packer" to generate compliant textures with one click.*

### 2. Advanced Skins
*   **Use Case**: Add new accessories (cat ears, tails), completely change clothing structure, or reconstruct character action effects.
*   **Naming Convention**: Base version is `pzzzz_Lily.png` ($zzzz \ge 0007$); derived color variants are `pzzzz_y_Lily.png` ($y \ge 1$).
*   **Technical Limitations**:
    *   Requires complete Spine triple set (`.png`, `.atlas`, `.skel`).
    *   Texture maps must be exported in **RGBA8888** format.
    *   **Size Alignment**: The atlas size of the **Base version** is not strictly limited; however, the atlas dimensions of any **Derived variants** must be **identical** to the Base version to ensure proper texture overriding.
    *   **Spine Export Settings Recommendation**:
        To ensure automation scripts can properly align textures and variants can correctly overlay base version textures, please **uncheck** the following "region" settings in Spine's **Texture Packer Settings** (as shown below):
        *   [ ] Strip whitespace X
        *   [ ] Strip whitespace Y
        *   [ ] Rotation
        *   [ ] Alias
        *   [ ] Ignore blank images
        
        > [!IMPORTANT]
        > If you create advanced skin variants (color variants), please ensure their export settings are exactly the same as the base version.

    *   *Note: You can use the online toolkit's "Advanced Skin Template Generator" to generate base templates with aligned IDs and settings with one click.*

---

## 📁 Mandatory Directory Structure

To allow the `Run_CreateMoreLilySkins.bat` script to correctly identify and categorize your assets, all skin files **must** be placed in the `ExtendSkins/` folder in the project root directory following this structure:

```text
EnderLilies-More-Skins/
└── ExtendSkins/
      ├── p0001_Lily/          # (Simple Skin Group) Corresponds to original p0001
      │   ├── p0001_1_Lily.png # Your 1st color variant
      │   ├── p0001_2_Lily.png # Your 2nd color variant
      │   └── ...
      │
      ├── p000[2-6]_Lily/      # Same rules as p0001
      │   └── ...
      │
      └── p0007_Lily/            # (Advanced Skin Group) Independent new ID
          ├── p0007_Lily.png      # Base texture (required, RGBA8888)
          ├── p0007_Lily.atlas    # Spine atlas file (required)
          ├── p0007_Lily.skel     # Spine binary skeleton (required)
          ├── DefaultSkins.json   # Custom skin layers (optional, see advanced section)
          ├── p0007_1_Lily.png    # Advanced skin color variant (optional)
          └── ...
```

---

## 🚀 Complete Import and Packaging Process

### Step 1: Prepare Art Assets
Please visit the **[Modding Online Toolbox](https://f14xuanlv.github.io/EnderLilies-More-Skins-Modding-Toolkit/)** to get slices, pack atlases, or generate advanced skin templates.
If you're making advanced skins and have edited them in Spine, ensure the following when exporting:
*   **Version**: `3.8.99` (tested compatible with 3.8.75)
*   **Format**: Binary (`.skel`)
*   **Texture**: Enable packing, select RGBA8888 format.

### Step 2: Place in Designated Directory
Place the prepared `.png` or triple set files in the `ExtendSkins/` corresponding numbered folder according to the **[Mandatory Directory Structure](#mandatory-directory-structure)** specification in the previous section.

### Step 3: Execute Automated Import
> [!WARNING]
> **Before executing this step, make sure to completely close Unreal Engine (Unreal Editor)!** Otherwise, the engine will lock asset files causing import failures.

1. Navigate to the `Scripts` folder in the project root directory.
2. Double-click to run [`Run_CreateMoreLilySkins.bat`](/Scripts/Run_CreateMoreLilySkins.bat).
3. The script will automatically perform validation, asset injection, DataTable updates, and chunking configuration. If the command line finally outputs `[SUCCESS] Mod assets generated and chunked!`, the import was successful.

### Step 4: Package and Test
1. Double-click to run [`Scripts/package.bat`](/Scripts/package.bat) for asset packaging.
2. After packaging is complete, copy the `.pak`, `.ucas`, `.utoc` files from the generated `LogicMods` folder to the game's corresponding Paks directory (see main README installation steps).
3. Launch the game and use `Alt + Number Keys` to view your creations in real-time.

---

## 🔧 Advanced: Custom Skin Layers (DefaultSkins.json)

If you've created advanced skins (e.g., `p0008_Lily`) and want to activate the skin layers you created in Spine by default in the game, you can place a `DefaultSkins.json` file in that asset directory:

```json
{
  "DefaultSkins": [
    "_common",
    "p0008_Lily",
    "_Meat_Head_0",
    "_Your_New_Custom_Skin" 
  ]
}
```
*   `_common` and `_Meat_Head_0` are original shared layers, usually need to be retained.
*   Replace `_Your_New_Custom_Skin` with the actual Skin name you created in Spine editor.
*   After the import script reads this JSON, it will automatically overwrite these layers into UE4's data assets. Remember to re-run [`Run_CreateMoreLilySkins.bat`](/Scripts/Run_CreateMoreLilySkins.bat) after updating the JSON file to apply changes to the Unreal assets, then run [`package.bat`](/Scripts/package.bat) to finalize the mod.
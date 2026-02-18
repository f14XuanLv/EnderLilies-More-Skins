**English** | [**简体中文**](README.zh-CN.md)

# ENDER LILIES "More Skins" Mod

This mod provides a powerful skin switching system for ENDER LILIES: Quietus of the Knights. It not only includes multiple preset skins but also supports creators in quickly developing and importing custom Spine skins through the accompanying SDK.

---

## 🎮 In-Game Preview

<img src="docs/images/gif/switch_skin_while_atacking.gif" height="400">

<img src="docs/images/gif/Lily_Nekomimi.gif" height="300">

---

## ⬇️ Download and Installation

### 1. Get Resources
Go to the [Releases](https://github.com/f14XuanLv/EnderLilies-More-Skins/releases) page to download the following two archives:
*   `UE4SS_For_More_Skins_Mod.zip` (Core injection tool)
*   `LogicMods.zip` (Mod logic assets)

### 2. Installation Steps
1.  **Install UE4SS**:
    *   Extract `UE4SS_For_More_Skins_Mod.zip`.
    *   Place all extracted files (`Mods/`, `dwmapi.dll`, `UE4SS-settings.ini`, etc.) into the game's runtime directory:
        `ENDER LILIES/EnderLilies/Binaries/Win64/`
    *   Result shown below:
    *   ![UE4SS Installation Result](docs/images/install_ue4ss.png)
2.  **Install Logic Assets**:
    *   Create a new folder named `LogicMods` in the game content directory `ENDER LILIES/EnderLilies/Content/Paks/`.
    *   Extract `LogicMods.zip` and place all the `.pak`, `.ucas`, `.utoc` files into this `LogicMods` folder.
    *   Result shown below:
    *   ![LogicMods Installation Result](docs/images/install_paks.png)

---

## 🎭 Skin Preview & Controls

After installing the mod, you can switch skins in real-time using **`Alt + Number/Letter Keys`** at any time in the game.
> [!IMPORTANT]
> **Variant Cycling**: If a number contains multiple styles (variants), **pressing the same hotkey repeatedly** will cycle through the variants in that group (e.g., press `Alt+1` for base style, press `Alt+1` again for variant).

### 1. Original Blighted Stages
These skins are based on Lily's blighted progression in the game story.

| ID | Hotkey | Base Preview | Additional Variants |
| :--- | :--- | :---: | :--- |
| **p0001** | `Alt + 1` | <img src="docs/images/p0001_Lily/p0001_Lily-locomotion-idle_0.png" height="200"> | <img src="docs/images/p0001_Lily/p0001_1_Lily-locomotion-idle_0.png" height="200"> <img src="docs/images/p0001_Lily/p0001_2_Lily-locomotion-idle_0.png" height="200"> |
| **p0002** | `Alt + 2` | <img src="docs/images/p0002_Lily/p0002_Lily-locomotion-idle_0.png" height="200"> | `-` |
| **p0003** | `Alt + 3` | <img src="docs/images/p0003_Lily/p0003_Lily-locomotion-idle_0.png" height="200"> | `-` |
| **p0004** | `Alt + 4` | <img src="docs/images/p0004_Lily/p0004_Lily-locomotion-idle_0.png" height="200"> | `-` |
| **p0005** | `Alt + 5` | <img src="docs/images/p0005_Lily/p0005_Lily-locomotion-idle_0.png" height="200"> | `-` |
| **p0006** | `Alt + 6` | <img src="docs/images/p0006_Lily/p0006_Lily-locomotion-idle_0.png" height="200"> | `-` |

### 2. Advanced Custom Skins
Extended skins with independent skeletons and animation capabilities created through the SDK.

| ID | Hotkey | Base Preview | Additional Variants |
| :--- | :--- | :---: | :--- |
| **p0007** | `Alt + 7` | <img src="docs/images/p0007_Lily/p0007_Lily-locomotion-idle_0.png" height="200"> | <img src="docs/images/p0007_Lily/p0007_1_Lily-locomotion-idle_0.png" height="200"> <img src="docs/images/p0007_Lily/p0007_2_Lily-locomotion-idle_0.png" height="200"> |
| **p0008~**| `Alt + 8~` | (To be expanded) | `-` |

### 3. Special Mode

| Function | Hotkey | Base Preview | Effect Description |
| :--- | :--- | :--- | :--- |
| **Ghost Mode** | `Alt + 0` | <img src="docs/images/p0001_Lily/p0001_ghost_Lily-locomotion-idle_0.png" height="200"> | Lily will enter pure white state.<br>Press Alt + any other registered number key to restore. |

---

## Character Ability Modifications (Additional Content)

### Black Knight (Hotkey: Alt + X)

#### Basic Attack

**ELDEN RING · Golden Order Style · Holy Damage Enchantment**

<img src="docs/images/gif/S5000_Basic_Apply1_ABCDE_Ground.gif" height="450">

<img src="docs/images/s5000_Unknown/S5000_Basic_Apply1_B_Ground.png" height="250"> <img src="docs/images/s5000_Unknown/S5000_Basic_Apply1_C_Ground.png" height="250">

---

### Knight Captain Julius (Hotkey: Alt + Z to Cycle)

#### Ultimate Skill

**Touhou Project · Marisa · Love Sign "Master Spark"**

<img src="docs/images/s5030_Leader/S5030_Sp_Apply1.png" height="350">

---

**ELDEN RING · Night Sorcery Style · Night Comet Azur**

<img src="docs/images/s5030_Leader/S5030_Sp_Apply2.png" height="350">

---

**Laser Cannon · Azure Tone**

<img src="docs/images/s5030_Leader/S5030_Sp_Apply3.png" height="350">

---

## 🛠️ Mod Development (SDK & Development)

If you're a creator who wants to create and publish your own Lily skins, please refer to the following complete development kit and guides:

### Development Documentation
*   [**Getting Started Guide (Environment Setup & Build)**](docs/GETTING_STARTED.md) — Contains the complete process from setting up UE 4.26.2 development environment, obtaining project code, to running automation scripts to build the mod.
*   [**Skin Creation and Integration Guidelines**](docs/SKIN_CREATION.md) — Explains the concepts of the two types of skins supported by the mod (Simple/Advanced), file naming conventions, directory structure requirements, and how to inject them into the game engine.
*   [**Source Code Modifications and Alignment**](docs/DEVELOPMENT_NOTES.md) — **[Advanced]** Deep dive into how this SDK achieves "pixel-perfect" alignment with the original game's asset structure and logic through modifying Spine Runtime source code.

### Online Tools
> [!TIP]
> **[Ender Lilies More Skins Modding Toolkit](https://f14xuanlv.github.io/EnderLilies-More-Skins-Modding-Toolkit/)**
> This is a pure frontend online tool that supports pixel-perfect texture packing restoration, one-click advanced skin skeleton template generation, and automatic ID reference alignment.

---

## 🔮 Core Potential & Technical Ceiling

The significance of this project goes beyond just "changing outfits" - it establishes a complete Spine asset reconstruction workflow. By deeply understanding this project's SDK and alignment logic, you can reach the following technical ceilings:

### 1. Project Workflow Ceiling: Deep Reconstruction and Complete Conversion
This mod's build workflow supports **structural modifications beyond pixel-level changes** to Lily:
*   **External Parts and Decorations**: You can add bones and attachments that originally didn't exist on Lily (e.g., animated cat ears, wind-blown capes, or full-coverage long dresses).
*   **Action Effect Enhancement**: You can inject brand new visual effects for specific actions by modifying Spine bone logic. For example, completely porting Hollow Knight's **"Monarch Wings"** double jump effect to Lily, or adding afterimage bones to dodge actions.
*   **Total Character Conversion**: As long as you maintain animation state naming conventions and logical structure, you can **completely replace Lily with another character** (e.g., replacing with Lady Maria from Bloodborne or a completely original character) while retaining all the fluid combat feedback from the original.

### 2. Underlying Principle Ceiling: Complete Game Theme Reshaping
The asset alignment and injection principles adopted by this project theoretically apply to **any Spine-driven object** in the game:
*   **Full Object Coverage**: By referencing this project's logic, you can perform the same modifications and extensions to **regular enemies, bosses, NPCs**, and even environmentally animated objects in the game.
*   **Specific Thematic Transformations**: Since you can uniformly modify the bones and textures of all Spine objects, developers have the ability to launch "full game theme redraw projects". For example, converting all bosses to specific anime characters, or uniformly reshaping the entire game's art style to "cyberpunk" or "minimalist sketch" styles.
*   **Conclusion**: This solution actually provides an underlying framework for a **"game art patch pack"**, with the ultimate ceiling being to transform ENDER LILIES into a platform carrying completely different artistic expressions.

---

## 🤝 Contributions and Submissions

Community members are very welcome to share their created skins!

1.  **Submit Works**: If you've created quality skins, you can submit them through any of the following methods:
    *   **GitHub**: Submit a **Pull Request** or open a new **Issue**.
    *   **Discord**: Contact the author directly via private message to share your work.
2.  **Join the Project**: Excellent skin assets will be integrated into subsequent Release versions of this mod with author attribution.

#### Contact the Author
If you encounter technical difficulties during development or have any collaboration intentions, you can contact me through:

<a href="https://discord.com/users/1132873678389006386">
  <img src="https://img.shields.io/badge/Discord-f14xuanlv-7289DA?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
</a>

---

## 💖 Acknowledgments

*   [EnderLilies.DebugMod](https://github.com/Trexounay/EnderLilies.DebugMod)
*   [EnderLilies.DebugModExtended](https://github.com/EnderLiliesFans5040/EnderLilies.DebugModExtended)
*   [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)
*   [p0001_1_Lily Skin Source](https://github.com/DreamerArumia/Ender-Lilies-Reskin-Mod)

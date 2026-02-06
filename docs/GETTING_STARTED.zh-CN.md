# SDK 环境要求与配置

本文档将指导您搭建《终焉之莉莉》“更多皮肤” 模组的完整开发环境。

## 一、 环境要求

### 1. 基础开发环境 (必选)
*   **操作系统**: Windows 10 或更高版本
*   **虚幻引擎**: UE 4.26.2

### 2. 核心工具链 (按需)
*   **深度开发，如果你的工作涉及对 C++ 源码的修改，则你需要这些**: 
    *   Visual Studio 2019 或 2022
    *   工作负载：使用 C++ 的桌面开发
    *   Windows SDK: 10.0.18362 或更高
*   **皮肤制作 (美术)**:
    *   Spine Pro: 3.8.99 (实测 3.8.75 亦可兼容)
    *   图像处理: Adobe Photoshop 或同类软件
*   **版本控制**: 
    *   Git

## 二、 项目获取与基础配置

### 1. 克隆项目
推荐使用 Git 克隆项目仓库到本地：
```bash
git clone https://github.com/f14XuanLv/EnderLilies-More-Skins.git
```

### 2. 配置引擎路径
为了使自动化脚本生效，必须关联你的虚幻引擎安装路径：
1.  打开 [`Scripts/config.bat`](/Scripts/config.bat)。
2.  将 `UE4PATH` 修改为你的实际安装目录：
    ```bat
    set "UE4PATH=C:\Game\UE\UE_4.26"
    ```

## 三、 快速上手：构建与初始化

在配置好引擎路径后，请按照以下顺序执行。这不仅是构建模组的过程，也是对开发环境的全链路检查。

### 1. 验证工程开启
*   **动作**：双击项目根目录下的 [`EnderLilies.uproject`](/EnderLilies.uproject)。
*   **目标**：确保能成功进入虚幻编辑器且无报错弹窗。如果此处报错，请检查 UE 4.26.2 是否安装正确。

### 2. 执行自动化构建
依次运行以下三个脚本，利用项目内的示例资产生成模组必要文件：

1.  **生成模组资产**: 执行 [`Scripts/Run_CreateMoreLilySkins.bat`](/Scripts/Run_CreateMoreLilySkins.bat)
    *   *功能：扫描 [`ExtendSkins`](/ExtendSkins/) 目录，自动完成资产转换（PNG/Spine -> .uasset）、皮肤分类（Simple/Advanced）、数据表注入及分块(Chunking)配置。*
2.  **打包资源 (Cook & Package)**: 执行 [`Scripts/package.bat`](/Scripts/package.bat)
    *   *功能：编译并提取资产，生成游戏可读取的补丁包。*
3.  **配置注入工具 (UE4SS)**: 执行 [`Scripts/setup_ue4ss.bat`](/Scripts/setup_ue4ss.bat)
    *   *功能：初始化模组加载器环境。*

## 四、 进阶开发：C++ 源码编译

如果您修改了项目 `Source/` 或 `Plugins/` 目录下的 **C++ 源代码**（例如进行了类似 [源码修改与对齐说明](/docs/DEVELOPMENT_NOTES.zh-CN.md) 中的操作），必须重新编译项目以使更改生效。

*   **前提条件**：确保已安装 [核心工具链](#2-核心工具链-按需) 中的 Visual Studio 及 C++ 相关组件。
*   **动作**：关闭虚幻编辑器，执行 [`Scripts/Build_GameEditorTarget.bat`](/Scripts/Build_GameEditorTarget.bat)。
*   **功能**：该脚本会调用虚幻引擎编译工具（UBT），将 C++ 源码重新编译为 Win64 平台下的编辑器二进制文件（.dll）。
*   **目标**：执行完成后，重新打开 [`EnderLilies.uproject`](/EnderLilies.uproject)，编辑器将加载最新的代码逻辑。

## 五、 完备性检查清单

完成上述步骤后，若您的项目目录下已包含以下产物，则说明 SDK 开发环境已搭建成功。

### 1. 模组产物 (LogicMods)
*   [ ] `LogicMods/` 文件夹已生成。
*   [ ] 文件夹内包含对应的 `.pak`、`.ucas` 与 `.utoc` 文件。

### 2. 加载器环境 (UE4SS)
*   [ ] `UE4SS_For_More_Skins_Mod/` 文件夹已生成。
*   [ ] 内部包含核心组件：`dwmapi.dll`、`UE4SS.dll`、`UE4SS-settings.ini`。
*   [ ] `Mods/` 文件夹已正确初始化。

### 3. 数据校验 (DataTable)
*   [ ] `Content/_Zenith/Gameplay/Data/DT_SpineData_p0000.uasset` 已根据 `ExtendSkins` 内容完成自动更新。
# 源码修改与对齐说明 (Spine 核心逻辑)

本文档记录了本 SDK 对 Spine 官方 Runtime (C++) 源码进行的深度定制。这些修改确保了导出的资产能够与《终焉之莉莉》原版游戏的底层逻辑完美对齐。

## 1. 资产组织：多对象单 Package 结构
**关联提交**: [`c099e628`](https://github.com/f14XuanLv/EnderLilies-More-Skins/commit/c099e6285495ca406a28c50b730074519c18e3a9)

**修改文件**:
- [`SpineAtlasImportFactory.cpp`](/Plugins/SpinePlugin/Source/SpineEditorPlugin/Private/SpineAtlasImportFactory.cpp)
- [`SpineSkeletonImportFactory.cpp`](/Plugins/SpinePlugin/Source/SpineEditorPlugin/Private/SpineSkeletonImportFactory.cpp)
- [`SpineSkeletonDataAsset.h`](/Plugins/SpinePlugin/Source/SpinePlugin/Public/SpineSkeletonDataAsset.h)

*   **技术背景**：官方插件默认将 Atlas 和 Skeleton 分开存放在不同的 `.uasset` 文件中。但原版游戏将二者封装在同一个 Package 容器内。
*   **修改实现**：在 `FactoryCreateFile` 中强制获取 `InParent->GetOutermost()`（即共享包容器）。
*   **结果**：导入后生成的资产结构（如 `p0007_Lily.uasset` 内部包含 `-atlas` 和 `-data` 两个对象）与原版游戏完全一致，解决了引用路径偏离问题。

## 2. 数据结构扩展：Lily 专有属性
**关联提交**: [`c099e628`](https://github.com/f14XuanLv/EnderLilies-More-Skins/commit/c099e6285495ca406a28c50b730074519c18e3a9)

**修改文件**:
- [`SpineSkeletonDataAsset.h`](/Plugins/SpinePlugin/Source/SpinePlugin/Public/SpineSkeletonDataAsset.h)

*   **修改点**：在 `USpineSkeletonDataAsset.h` 类中手动追加了原版 C++ 层存在的变量：
    *   `float DefaultScale`: 默认为 `1.196f`，确保莉莉在场景中的物理尺寸正确。
    *   `TArray<FString> DefaultSkins`: 用于存储默认激活的 Spine 皮肤层。
*   **结果**：该 SDK 生成的资产可直接被游戏本体的 C++ 逻辑识别，无需在虚幻编辑器内手动二次设置。

## 3. 导入自动化：Lily 预设自动填充
**关联提交**: [`3ba0effb`](https://github.com/f14XuanLv/EnderLilies-More-Skins/commit/3ba0effb0ab81cfad77bd064ed099975205e2c60)

**修改文件**:
- [`SpineSkeletonImportFactory.cpp`](/Plugins/SpinePlugin/Source/SpineEditorPlugin/Private/SpineSkeletonImportFactory.cpp)

*   **技术实现**：新增 `SetupLilyDefaultProperties` 辅助函数。当系统识别到文件名符合 `p*_Lily` 规范时，自动执行：
    *   **26 组 MixData 映射**：自动填充包括 `jump_up` -> `jump_apex` 等在内的全套动画混合时间（0s ~ 0.5s 不等）。
    *   **皮肤层对齐**：自动设置默认皮肤数组为 `["_common", "MainSkinName", "_Meat_Head_0"]`。
*   **结果**：创作者只需导入原始 Spine 文件，即可瞬间获得与原版莉莉完全一致的动态手感与渲染层级。

## 4. 纹理导入优化与静默处理
**关联提交**: [`d3d874e0`](https://github.com/f14XuanLv/EnderLilies-More-Skins/commit/d3d874e0e6411b12e4c0af75077a1d026b069055)

**修改文件**:
- [`SpineAtlasImportFactory.cpp`](/Plugins/SpinePlugin/Source/SpineEditorPlugin/Private/SpineAtlasImportFactory.cpp)
- [`SpineSkeletonImportFactory.cpp`](/Plugins/SpinePlugin/Source/SpineEditorPlugin/Private/SpineSkeletonImportFactory.cpp)

*   **修改点**：重构 `resolveTexture` 函数。
    *   **强制渲染属性**：自动关闭 `Mipmaps` (TMGS_NoMipmaps) 并将 LOD 组设为 `TEXTUREGROUP_Character`，保证像素/手绘纹理的清晰度。
    *   **脚本支持**：引入 `UAssetImportTask` 并开启 `bAutomated`。
*   **结果**：支持通过 Python 脚本（Commandlet 模式）进行无弹窗的后台批量导入，极大提升了开发环境的构建速度。

## 5. 解除 3.8.75 版本硬限制 (兼容性补丁)
**关联提交**: [`2a940a78`](https://github.com/f14XuanLv/EnderLilies-More-Skins/commit/2a940a78a79f8c205c7068c38a75c7bb464aed28)

**修改文件**:
- [`SkeletonBinary.cpp`](/Plugins/SpinePlugin/Source/SpinePlugin/Public/spine-cpp/src/spine/SkeletonBinary.cpp)
- [`SkeletonJson.cpp`](/Plugins/SpinePlugin/Source/SpinePlugin/Public/spine-cpp/src/spine/SkeletonJson.cpp)

*   **修改背景**：Spine 官方在 3.8 版本的后期 Runtime 中，硬编码了对 `3.8.75` 资产的拒绝逻辑。
*   **解除原因**：虽然 `3.8.75` 存在广泛的破解版本导致官方封杀，但对于 Mod 社区而言，该版本拥有庞大的存量资产和成熟的工具链。
*   **修改实现**：在 `SkeletonBinary.cpp` 和 `SkeletonJson.cpp` 中注释掉了版本号校验逻辑。
*   **结果**：**实现了对 3.8.75 资产的向下兼容**。本 SDK 认为创作自由高于版本限制，创作者可以使用社区最普及的工具进行模组开发。

---

### 技术总结
通过上述对底层源码的定制，本 SDK 实现了从资产文件结构到运行时数据逻辑的“全路径对齐”。这使得开发者可以专注于美术创作，而复杂的引擎关联工作均由 SDK 底层自动完成。
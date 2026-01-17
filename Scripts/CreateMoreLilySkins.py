import os
import csv
import struct
import sys
import json
import unreal

# --- Configuration Paths ---
PROJ_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CONTENT_DIR = os.path.join(PROJ_DIR, "Content")
EXTEND_SKINS_ROOT = os.path.join(PROJ_DIR, "ExtendSkins")
CSV_PATH = os.path.join(PROJ_DIR, "DT_SpineData_p0000.csv")

"""
Skin Types Description:
1. Simple Skins: p000x_y_Lily.png (1<=x<=6, y>=1)
   - Skin extensions based on p000x_Lily
   - No modifications to skeleton or atlas
   - Cannot modify character animations in game
   - Do not occupy new rows in DT_SpineData_p0000
   - No CSV adjustments needed
   - Generated path: Content\_Zenith\Characters\p000x_Lily\Textures\p000x_y_Lily.uasset

2. Advanced Skins:
   2.1 Base Version: pzzzz_Lily.png (int(zzzz)>=7)
       - Has the ability to modify character animations
       - Occupies new rows in DT_SpineData_p0000
       - Requires creating independent spine assets (trinity files: .png, .atlas, .skel)
       - Generated path: Content\_Zenith\Characters\pzzzz_Lily\
   
   2.2 Extended Version: pzzzz_y_Lily.png (int(zzzz)>=7, y>=1)
       - Texture extension based on pzzzz_Lily
       - Does not create new spine assets
       - Does not occupy new rows in DT_SpineData_p0000
       - Generated path: Content\_Zenith\Characters\pzzzz_Lily\Textures\pzzzz_y_Lily.uasset

Folder Structure:
ExtendSkins/
├── p0001_Lily/      # Simple skin folder
│   ├── p0001_1_Lily.png
│   ├── p0001_2_Lily.png
│   └── ...          # p0001_x_Lily.png, etc.
├── p0007_Lily/      # Advanced skin folder
│   ├── p0007_Lily.png    # Base skin
│   ├── p0007_Lily.atlas  # Spine atlas file
│   ├── p0007_Lily.skel   # Spine skeleton file
│   ├── DefaultSkins.json # If the spine is not base on p0001_Lily or you have changed the DefaultSkins, it will be needed.
│   ├── p0007_1_Lily.png  # Extended version
│   ├── p0007_2_Lily.png  # Extended version
│   └── ...               # p0007_x_Lily.png, etc.
└── ...
"""

def get_png_info(file_path):
    """Parse PNG file header to get resolution and bit depth
    
    Returns:
        tuple: (info_dict, error_string)
        info_dict contains: w (width), h (height), bd (bit depth), ct (color type)
        Color types: 0=Grayscale, 2=RGB, 3=Palette, 4=GrayscaleAlpha, 6=RGBA
    """
    with open(file_path, 'rb') as f:
        # Read 33 bytes to ensure coverage of IHDR chunk
        data = f.read(33)
        if len(data) < 26 or data[:8] != b'\x89PNG\r\n\x1a\n':
            return None, "Invalid PNG"
        # IHDR chunk starts from byte 16: Width(4), Height(4), BitDepth(1), ColorType(1)
        width, height, bit_depth, color_type = struct.unpack('>IIBB', data[16:26])
        return {"w": width, "h": height, "bd": bit_depth, "ct": color_type}, ""

def validate_structure():
    """
    Scan ExtendSkins folder and validate structure
    Returns:
    - simple_extensions: { "p0001_Lily": [extension PNG list], ... }
    - advanced_bases: { 7: {"name": "p0007_Lily", "png": path, "atlas": path, "skel": path, "w": 0, "h": 0} }
    - advanced_extensions: { "p0007_Lily": [extension PNG list], ... }
    """
    if not os.path.exists(EXTEND_SKINS_ROOT):
        unreal.log_error("Missing dir: " + EXTEND_SKINS_ROOT)
        return {}, {}, {}

    simple_extensions = {}
    advanced_bases = {}
    advanced_extensions = {}

    for folder_name in os.listdir(EXTEND_SKINS_ROOT):
        folder_path = os.path.join(EXTEND_SKINS_ROOT, folder_name)
        if not os.path.isdir(folder_path): continue
        if not (folder_name.startswith("p") and folder_name.endswith("_Lily")): continue

        try:
            skin_id = int(folder_name[1:5])
        except: continue

        files = os.listdir(folder_path)
        
        # --- Case A: Simple skin extensions (1-6) ---
        if 1 <= skin_id <= 6:
            valid_exts = []
            base_prefix = folder_name[:5]  # Extract "p0001"
            for f in files:
                # Match p0001_x_Lily.png, exclude base png that might exist in folder
                if f.startswith(base_prefix + "_") and f.endswith("_Lily.png") and f != (folder_name + ".png"):
                    info, err = get_png_info(os.path.join(folder_path, f))
                    if not err and info['w'] == 1024 and info['h'] == 256:
                        valid_exts.append(f)
                    else:
                        unreal.log_error(f"Simple extension {f} must be 1024x256")
            if valid_exts: simple_extensions[folder_name] = valid_exts

        # --- Case B: Advanced skins (7+) ---
        elif skin_id >= 7:
            # Validate trinity files (required for advanced skins)
            png_file = folder_name + ".png"      # Texture file
            atlas_file = folder_name + ".atlas"  # Spine atlas data
            skel_file = folder_name + ".skel"    # Binary skeleton data

            if all(f in files for f in [png_file, atlas_file, skel_file]):
                base_png_path = os.path.join(folder_path, png_file)
                info, err = get_png_info(base_png_path)
                if err or info['ct'] != 6:  # ColorType 6 = RGBA
                    unreal.log_error(f"Advanced base {png_file} must be RGBA8888 (ColorType=6)")
                    continue
                
                advanced_bases[skin_id] = {
                    "name": folder_name,
                    "png": base_png_path,
                    "atlas": os.path.join(folder_path, atlas_file),
                    "skel": os.path.join(folder_path, skel_file),
                    "w": info['w'], "h": info['h']
                }

                # Find extensions for this advanced skin
                valid_exts = []
                base_prefix = folder_name[:5]  # Extract "p0007"
                for f in files:
                    # Match p0007_1_Lily.png, exclude p0007_Lily.png itself
                    if f.startswith(base_prefix + "_") and f.endswith("_Lily.png") and f != (folder_name + ".png"):
                        ext_info, err = get_png_info(os.path.join(folder_path, f))
                        # Validate if size matches this advanced skin's base image
                        if not err and ext_info['w'] == info['w'] and ext_info['h'] == info['h']:
                            valid_exts.append(f)
                        else:
                            unreal.log_error(f"Extension {f} size must match base {info['w']}x{info['h']}")
                if valid_exts: advanced_extensions[folder_name] = valid_exts
            else:
                unreal.log_error(f"Advanced folder {folder_name} missing Trinity files (.png, .atlas, .skel)")

    return simple_extensions, advanced_bases, advanced_extensions

def import_texture(png_path, dest_folder, asset_name):
    """General texture import function"""
    task = unreal.AssetImportTask()
    task.set_editor_property('filename', png_path)
    task.set_editor_property('destination_path', dest_folder)
    task.set_editor_property('destination_name', asset_name)
    task.set_editor_property('replace_existing', True)
    task.set_editor_property('automated', True)
    task.set_editor_property('save', True)

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    
    asset_path = dest_folder + asset_name
    texture = unreal.load_asset(asset_path)
    if texture:
        texture.set_editor_property("mip_gen_settings", unreal.TextureMipGenSettings.TMGS_NO_MIPMAPS)
        texture.set_editor_property("lod_group", unreal.TextureGroup.TEXTUREGROUP_CHARACTER)
        unreal.EditorAssetLibrary.save_asset(asset_path)
    return texture

def import_spine_assets(skel_path, atlas_path, dest_folder, asset_name):
    """
    Modified: Only import skel file
    Rely on modified C++ LoadAtlas to automatically and silently handle the corresponding atlas
    """
    task = unreal.AssetImportTask()
    task.set_editor_property('filename', skel_path) # Only handle skel
    task.set_editor_property('destination_path', dest_folder)
    task.set_editor_property('destination_name', asset_name)
    task.set_editor_property('replace_existing', True)
    task.set_editor_property('automated', True) # Ensure Python side also enables automation
    task.set_editor_property('save', True)

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    unreal.log(f"Spine Skeleton triggered for {asset_name}, Atlas will be auto-loaded by C++ Factory.")

def update_data_table(advanced_ids):
    """Update CSV records and generate DataTable for advanced skins
    Note: Simple skins do not need to add data rows in DT_SpineData_p0000"""
    rows = []
    header = ["---", "Notify", "Atlas", "Skeleton", "LightMaterial"]
    
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader)
            for row in reader:
                if row and int(row[0]) < 12: rows.append(row)

    current_row = 12
    for sid in sorted(advanced_ids):
        asset_id = f"p{sid:04d}_Lily"
        new_row = [
            str(current_row),
            "/Game/_Zenith/Characters/p0001_Lily/p0001_Lily-notify.p0001_Lily-notify",  # Shared notify file
            f"/Game/_Zenith/Characters/{asset_id}/{asset_id}.{asset_id}-atlas",         # Atlas reference
            f"/Game/_Zenith/Characters/{asset_id}/{asset_id}.{asset_id}-data",          # Skeleton data reference
            "MaterialInstanceConstant'/Game/_Zenith/Characters/p0000_Lily/MI_LilyLight1.MI_LilyLight1'"  # Light material
        ]
        rows.append(new_row)
        current_row += 1

    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', newline='', suffix='.csv', delete=False, encoding='utf-8') as tmp_file:
        writer = csv.writer(tmp_file)
        writer.writerow(header)
        writer.writerows(rows)
        temp_path = tmp_file.name

    # Ensure the destination directory exists
    data_dir_path = os.path.join(CONTENT_DIR, "_Zenith", "Gameplay", "Data")
    if not os.path.exists(data_dir_path):
        os.makedirs(data_dir_path)

    # Check if row struct exists
    struct_path = "/Game/_Zenith/Gameplay/Structures/FSpineDataGroup"
    row_struct = unreal.load_asset(struct_path)
    if not row_struct:
        unreal.log_error(f"Failed to load row struct from: {struct_path}")
        os.unlink(temp_path)
        return

    # Create import task
    try:
        dt_path = "/Game/_Zenith/Gameplay/Data/DT_SpineData_p0000"
        
        import_task = unreal.AssetImportTask()
        import_task.filename = temp_path
        import_task.destination_path = "/Game/_Zenith/Gameplay/Data/"
        import_task.destination_name = "DT_SpineData_p0000"
        import_task.replace_existing = True
        import_task.automated = True
        import_task.save = True  # Ensure the asset is saved after import
        
        factory = unreal.CSVImportFactory()
        factory.automated_import_settings.import_row_struct = row_struct
        import_task.factory = factory
        
        unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([import_task])
        
        # Verify the asset was created/updated and force save
        if unreal.EditorAssetLibrary.does_asset_exist(dt_path):
            # Load the asset to ensure it's in memory
            data_table = unreal.EditorAssetLibrary.load_asset(dt_path)
            if data_table:
                # Force save the loaded asset
                unreal.EditorAssetLibrary.save_loaded_asset(data_table)
            
    except Exception as e:
        unreal.log_error(f"Exception during DataTable import: {str(e)}")
    finally:
        os.unlink(temp_path)

def setup_chunk2_label(simple_skins, advanced_base_skins, advanced_extend_skins):
    """
    Configure PrimaryAssetLabel (Chunk2)
    1. Generated path: Content/Chunk2.uasset
    2. Priority: 1
    3. Recursive apply: False
    4. Included resources:
       - Advanced skins: All resources in p0007_Lily and above folders
       - Simple skins: Extended textures in p0001-p0006_Lily folders
       - Advanced skin extensions: Extended textures in p0007_Lily and above folders
    """
    label_name = "Chunk2"
    folder_path = "/Game/"
    label_path = f"{folder_path}{label_name}"
    
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    asset_lib = unreal.EditorAssetLibrary

    # 1. Ensure Label asset exists
    label = None
    if asset_lib.does_asset_exist(label_path):
        label = asset_lib.load_asset(label_path)
    if not label:
        label = asset_tools.create_asset(label_name, folder_path, unreal.PrimaryAssetLabel, None)

    if not label:
        unreal.log_error(f"Failed to create asset: {label_path}")
        return

    # 2. Configure rules
    rules = unreal.PrimaryAssetRules()
    rules.set_editor_property("chunk_id", 2)
    rules.set_editor_property("apply_recursively", False) # Disable recursive application
    rules.set_editor_property("priority", 1)              # Set priority to 1
    label.set_editor_property("rules", rules)

    # 3. Collect resources
    explicit_assets = []
    
    char_root = "/Game/_Zenith/Characters/"
    all_assets_in_char = asset_lib.list_assets(char_root, recursive=True)
    
    for a_path in all_assets_in_char:
        path_str = str(a_path)
        path_parts = path_str.split('/')
        
        is_advanced_folder = False
        for part in path_parts:
            # Check if it's an advanced skin folder
            if part.startswith("p") and part.endswith("_Lily") and len(part) == 10:
                try:
                    folder_id = int(part[1:5])
                    if folder_id >= 7:
                        is_advanced_folder = True
                        break
                except ValueError:
                    continue
        
        if is_advanced_folder:
            asset_obj = asset_lib.load_asset(path_str)
            if asset_obj:
                explicit_assets.append(asset_obj)
    
    # 3.2 Add simple skin texture resources
    for skin in simple_skins:
        # Simple skin format: p000x_y_Lily.png
        base_id = skin[:5] + "_Lily"  # p000x_Lily
        texture_name = skin.replace(".png", "")
        texture_path = f"/Game/_Zenith/Characters/{base_id}/Textures/{texture_name}"
        
        if asset_lib.does_asset_exist(texture_path):
            texture_obj = asset_lib.load_asset(texture_path)
            if texture_obj:
                explicit_assets.append(texture_obj)
                unreal.log(f"Added simple skin to Chunk2: {texture_path}")
    
    # 3.3 Add advanced skin extension texture resources
    for skin in advanced_extend_skins:
        # Advanced skin extension format: pzzzz_y_Lily.png
        base_id = skin[:5] + "_Lily"  # pzzzz_Lily
        texture_name = skin.replace(".png", "")
        texture_path = f"/Game/_Zenith/Characters/{base_id}/Textures/{texture_name}"
        
        if asset_lib.does_asset_exist(texture_path):
            texture_obj = asset_lib.load_asset(texture_path)
            if texture_obj:
                explicit_assets.append(texture_obj)
                unreal.log(f"Added advanced extend skin to Chunk2: {texture_path}")
    
    # 3.4 Add Mod specific resources
    mod_assets = [
        "/Game/Mods/EnderLilies_More_Skins_Mod/BP_ExtendSkinAssets",
        "/Game/Mods/EnderLilies_More_Skins_Mod/ExtendSkinAssets",
        "/Game/Mods/EnderLilies_More_Skins_Mod/ModActor"
    ]
    
    for mod_asset_path in mod_assets:
        if asset_lib.does_asset_exist(mod_asset_path):
            mod_obj = asset_lib.load_asset(mod_asset_path)
            if mod_obj:
                explicit_assets.append(mod_obj)
                unreal.log(f"Added Mod asset to Chunk2: {mod_asset_path}")
        else:
            unreal.log_warning(f"Mod asset not found: {mod_asset_path}")

    # 4. Write explicit asset list and save
    label.set_editor_property("explicit_assets", explicit_assets)
    asset_lib.save_loaded_asset(label)
    
    unreal.log(f"--- [Success] Chunk2 configuration updated ---")
    unreal.log(f"Label location: {label_path}")
    unreal.log(f"Settings: Priority=1, Recursive=False")
    unreal.log(f"Total included assets: {len(explicit_assets)}")
    unreal.log(f"- Simple skins: {len(simple_skins)}")
    unreal.log(f"- Advanced base skins (full folders): {len(advanced_base_skins)}")
    unreal.log(f"- Advanced extend skins: {len(advanced_extend_skins)}")
    unreal.log(f"- Mod assets: {len([a for a in mod_assets if asset_lib.does_asset_exist(a)])}")

def setup_chunk3_label():
    """
    Configure PrimaryAssetLabel (Chunk3) - Specifically for DT_SpineData_p0000
    1. Generated path: Content/Chunk3.uasset
    2. Priority: 2
    3. Recursive apply: False
    4. Included resources: Only DT_SpineData_p0000
    """
    label_name = "Chunk3"
    folder_path = "/Game/"
    label_path = f"{folder_path}{label_name}"
    
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    asset_lib = unreal.EditorAssetLibrary

    # 1. Ensure Label asset exists
    label = None
    if asset_lib.does_asset_exist(label_path):
        label = asset_lib.load_asset(label_path)
    if not label:
        label = asset_tools.create_asset(label_name, folder_path, unreal.PrimaryAssetLabel, None)

    if not label:
        unreal.log_error(f"Failed to create asset: {label_path}")
        return

    # 2. Configure rules
    rules = unreal.PrimaryAssetRules()
    rules.set_editor_property("chunk_id", 3)
    rules.set_editor_property("apply_recursively", False) # Disable recursive application
    rules.set_editor_property("priority", 2)              # Set priority to 2
    label.set_editor_property("rules", rules)

    # 3. Collect resources - only DT_SpineData_p0000
    explicit_assets = []
    
    dt_path = "/Game/_Zenith/Gameplay/Data/DT_SpineData_p0000"
    if asset_lib.does_asset_exist(dt_path):
        dt_obj = asset_lib.load_asset(dt_path)
        if dt_obj:
            explicit_assets.append(dt_obj)
            unreal.log(f"Added DataTable to Chunk3: {dt_path}")
        else:
            unreal.log_warning(f"Failed to load DataTable: {dt_path}")
    else:
        unreal.log_warning(f"DataTable not found: {dt_path}")

    # 4. Write explicit asset list and save
    label.set_editor_property("explicit_assets", explicit_assets)
    asset_lib.save_loaded_asset(label)
    
    unreal.log(f"--- [Success] Chunk3 configuration created ---")
    unreal.log(f"Label location: {label_path}")
    unreal.log(f"Settings: Priority=2, Recursive=False")
    unreal.log(f"Total included assets: {len(explicit_assets)}")

def update_extend_skin_data_asset(simple_skins, advanced_base_skins, advanced_extend_skins):
    """
    Automatically populate the three array variables of ExtendSkinAssets data asset
    """
    # Target Data Asset path (based on your screenshot)
    da_path = "/Game/Mods/EnderLilies_More_Skins_Mod/ExtendSkinAssets"
    
    # Check if asset exists
    if not unreal.EditorAssetLibrary.does_asset_exist(da_path):
        # Try to copy from .empty file
        empty_file_path = os.path.join(CONTENT_DIR, "Mods", "EnderLilies_More_Skins_Mod", "ExtendSkinAssets.uasset.empty")
        target_file_path = os.path.join(CONTENT_DIR, "Mods", "EnderLilies_More_Skins_Mod", "ExtendSkinAssets.uasset")
        
        if os.path.exists(empty_file_path):
            import shutil
            shutil.copy2(empty_file_path, target_file_path)
            unreal.log(f"Copied ExtendSkinAssets from .empty file")
            
            # Refresh asset registry to recognize new file
            asset_registry = unreal.AssetRegistryHelpers.get_asset_registry()
            asset_registry.scan_paths_synchronous(["/Game/Mods/"], True)
            
            # Check again if asset exists
            if not unreal.EditorAssetLibrary.does_asset_exist(da_path):
                unreal.log_warning(f"Failed to load ExtendSkinAssets after copying from .empty file")
                return
        else:
            unreal.log_warning(f"ExtendSkinAssets not found and no .empty file available")
            return

    # Load Data Asset
    data_asset = unreal.load_asset(da_path)
    
    # --- 1. Collect Textures (include all types) ---
    texture_assets = []
    
    # Helper function: Get texture path based on filename and type
    def get_tex_asset(filename, skin_type):
        asset_name = filename.replace(".png", "")
        if skin_type == "simple" or skin_type == "advanced_extend":
            # Extended skins are in corresponding Base folder
            base_id = filename[:5] + "_Lily"
            path = f"/Game/_Zenith/Characters/{base_id}/Textures/{asset_name}"
        else:
            # Advanced base skins are in their own folder
            path = f"/Game/_Zenith/Characters/{asset_name}/Textures/{asset_name}"
        
        return unreal.load_asset(path)

    # Collect simple skins
    for skin in simple_skins:
        tex = get_tex_asset(skin, "simple")
        if tex: texture_assets.append(tex)
            
    # Collect advanced base skins
    for skin in advanced_base_skins:
        tex = get_tex_asset(skin, "advanced_base")
        if tex: texture_assets.append(tex)
            
    # Collect advanced extended skins
    for skin in advanced_extend_skins:
        tex = get_tex_asset(skin, "advanced_extend")
        if tex: texture_assets.append(tex)

    # --- 2. Collect Atlas and Skeleton Data (Advanced Base only) ---
    atlas_assets = []
    skeleton_assets = []
    
    for skin in advanced_base_skins:
        asset_id = skin.replace(".png", "")
        
        # UE4 Asset Reference Format: /Path/To/PackageName.ObjectName
        # PackageName is p0007_Lily (the .uasset filename without extension)
        # ObjectName is p0007_Lily-atlas or p0007_Lily-data (internal object names)
        
        # 1. Base package path (points to .uasset file)
        package_path = f"/Game/_Zenith/Characters/{asset_id}/{asset_id}"
        
        # 2. Build specific object reference path with dot notation
        # The dot "." separates package path from internal object name
        atlas_full_path = f"{package_path}.{asset_id}-atlas"
        data_full_path = f"{package_path}.{asset_id}-data"
        
        unreal.log(f"Trying to load Atlas at: {atlas_full_path}")
        
        atlas_obj = unreal.load_asset(atlas_full_path)
        data_obj = unreal.load_asset(data_full_path)
        
        if atlas_obj: 
            atlas_assets.append(atlas_obj)
            unreal.log(f"Found Atlas: {asset_id}")
        else: 
            unreal.log_warning(f"Missing Atlas for {asset_id} (Path: {atlas_full_path})")
            
        if data_obj: 
            skeleton_assets.append(data_obj)
            unreal.log(f"Found Skeleton Data: {asset_id}")
        else:
            unreal.log_warning(f"Missing Skeleton Data for {asset_id} (Path: {data_full_path})")

    # --- 3. Write variables to Data Asset ---
    data_asset.set_editor_property("ExtendSkinTextures", texture_assets)
    data_asset.set_editor_property("ExtendSkinAtlas", atlas_assets)
    data_asset.set_editor_property("ExtendSkinSkeleton", skeleton_assets)
    
    unreal.EditorAssetLibrary.save_loaded_asset(data_asset)
    unreal.log(f"--- [Success] Updated ExtendSkinAssets ---")
    unreal.log(f"Textures: {len(texture_assets)}")
    unreal.log(f"Atlases: {len(atlas_assets)}")
    unreal.log(f"Skeletons: {len(skeleton_assets)}")

def apply_custom_skin_layers(asset_path, json_path):
    """Override DefaultSkins property from JSON only"""
    if not os.path.exists(json_path):
        return

    # Load asset (internal name is pXXXX_Lily-data)
    asset = unreal.load_asset(asset_path)
    if not asset:
        return

    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            config = json.load(f)

        if "DefaultSkins" in config:
            # Directly override C++ default generated ["_common", "pXXXX_Lily", "_Meat_Head_0"]
            asset.set_editor_property("DefaultSkins", config["DefaultSkins"])
            
            # Save and mark dirty data
            unreal.EditorAssetLibrary.save_loaded_asset(asset)
            unreal.log(f"[SDK] Custom skins applied to: {asset_path}")
            
    except Exception as e:
        unreal.log_error(f"[SDK] Failed to parse {json_path}: {str(e)}")


# --- Main execution flow ---
if __name__ == "__main__":
    # Validate folder structure and collect skin files
    simple_exts, adv_bases, adv_exts = validate_structure()

    # 1. Process simple skin extensions (p0001-p0006)
    unreal.log("\n--- Processing Simple Extensions ---")
    for base_name, png_list in simple_exts.items():
        dest = f"/Game/_Zenith/Characters/{base_name}/Textures/"
        folder_path = os.path.join(EXTEND_SKINS_ROOT, base_name)
        for png in png_list:
            import_texture(os.path.join(folder_path, png), dest, png.replace(".png", ""))

    # 2. Process advanced skin bases (p0007+)
    unreal.log("\n--- Processing Advanced Bases ---")
    for sid, info in adv_bases.items():
        base_name = info['name']
        dest_root = f"/Game/_Zenith/Characters/{base_name}/"
        dest_tex = dest_root + "Textures/"
        
        # Import texture
        import_texture(info['png'], dest_tex, base_name)
        # Import Spine (will call modified C++ Factory to merge into dest_root/base_name.uasset)
        import_spine_assets(info['skel'], info['atlas'], dest_root, base_name)
        
        # Apply custom skin layers from JSON if available
        json_path = os.path.join(EXTEND_SKINS_ROOT, base_name, "DefaultSkins.json")
        if os.path.exists(json_path):
            # Build asset path (internal name is pXXXX_Lily-data)
            data_asset_path = f"{dest_root}{base_name}.{base_name}-data"
            apply_custom_skin_layers(data_asset_path, json_path)

    # 3. Process advanced skin extension textures
    unreal.log("\n--- Processing Advanced Extensions ---")
    for base_name, png_list in adv_exts.items():
        dest = f"/Game/_Zenith/Characters/{base_name}/Textures/"
        folder_path = os.path.join(EXTEND_SKINS_ROOT, base_name)
        for png in png_list:
            import_texture(os.path.join(folder_path, png), dest, png.replace(".png", ""))

    # 4. Update DataTable (only for advanced base skins)
    update_data_table(adv_bases.keys())

    # 5. Refresh assets and update DataAsset and Labels
    unreal.log("Refreshing asset registry...")
    asset_registry = unreal.AssetRegistryHelpers.get_asset_registry()
    asset_registry.scan_paths_synchronous(["/Game/_Zenith/Characters/"], True)
    
    # Small delay to ensure asset indexing is complete
    import time
    time.sleep(0.5)
    
    # Need to convert to suitable format for subsequent functions
    simple_skins = []
    for base_name, png_list in simple_exts.items():
        simple_skins.extend(png_list)
    
    advanced_base_skins = []
    for info in adv_bases.values():
        advanced_base_skins.append(info['name'] + ".png")
    
    advanced_extend_skins = []
    for base_name, png_list in adv_exts.items():
        advanced_extend_skins.extend(png_list)
    
    # Update ExtendSkinAssets DataAsset
    unreal.log("Updating ExtendSkinAssets Data Asset...")
    update_extend_skin_data_asset(simple_skins, advanced_base_skins, advanced_extend_skins)
    
    setup_chunk2_label(simple_skins, advanced_base_skins, advanced_extend_skins)
    setup_chunk3_label()
    
    unreal.log("=== SDK Process Finished Successfully ===")
    unreal.log(f"Processed {len(simple_skins)} simple skins")
    unreal.log(f"Processed {len(advanced_base_skins)} advanced base skins")
    unreal.log(f"Processed {len(advanced_extend_skins)} advanced extend skins")
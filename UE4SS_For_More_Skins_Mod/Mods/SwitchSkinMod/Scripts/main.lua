-- ===============================================================
-- Hybrid mode skin switching plugin (stateless variant detection)
-- ===============================================================

local AssetPath = "/Game/Mods/EnderLilies_More_Skins_Mod/ExtendSkinAssets.ExtendSkinAssets"

-- 1. Define absolutely fixed base skins (1-6)
local BASE_SKINS = {
    {level = 1,  asset = "p0001", variants = {""}}, -- Alt+1
    {level = 2,  asset = "p0002", variants = {""}}, -- Alt+2
    {level = 5,  asset = "p0003", variants = {""}}, -- Alt+3
    {level = 7,  asset = "p0004", variants = {""}}, -- Alt+4
    {level = 9,  asset = "p0005", variants = {""}}, -- Alt+5
    {level = 11, asset = "p0006", variants = {""}}, -- Alt+6
}

local SKINS = {}
local INITIALIZED = false

-- Parsing tool: Parse texture name (p0001_1_Lily -> ID:p0001, Prefix:1_)
local function ParseVariant(fullName)
    local name = fullName:match("([^%.]+)$") or ""
    local id, varNum = name:match("^(p%d%d%d%d)_(%d+)_Lily")
    if id and varNum then return id, varNum .. "_" end
    return name:match("^(p%d%d%d%d)_Lily"), ""
end

-- Core: Build final skin table
local function BuildSkinTable()
    print("[Mod] Merging Base Skins with DataAsset...")
    
    -- Force reload the DataAsset
    local DA = StaticFindObject(AssetPath)
    if not DA or not DA:IsValid() then
        print("[Mod] DataAsset not found, loading...")
        LoadAsset(AssetPath)
        DA = StaticFindObject(AssetPath)
    end
    
    -- Copy base template
    local tempMap = {}
    local order = {}
    for i, s in ipairs(BASE_SKINS) do
        tempMap[s.asset] = {asset = s.asset, level = s.level, variants = {""}, isAdvanced = false}
        table.insert(order, s.asset)
    end

    if DA and DA:IsValid() then
        print("[Mod] DataAsset loaded successfully")
        -- 1. Scan textures, assign variants
        local texArray = DA.ExtendSkinTextures
        if texArray then
            local texCount = texArray:GetArrayNum()
            print(string.format("[Mod] Found %d textures in DataAsset", texCount))
            for i = 1, texCount do
                local tex = texArray[i]
                if tex and tex:IsValid() then
                    local id, prefix = ParseVariant(tex:GetFullName())
                    if id then
                        if not tempMap[id] then
                            -- Calculate correct level: p0007 = 12, p0008 = 13, p0009 = 14, etc.
                            local idNum = tonumber(id:match("p(%d%d%d%d)"))
                            local level = idNum >= 7 and (12 + (idNum - 7)) or 12
                            tempMap[id] = {asset = id, level = level, variants = {}, isAdvanced = true}
                            table.insert(order, id)
                            print(string.format("[Mod] Added new skin: %s (level %d)", id, level))
                        end
                        -- Avoid duplicate variant additions
                        local exists = false
                        for _, v in ipairs(tempMap[id].variants) do if v == prefix then exists = true break end end
                        if not exists then table.insert(tempMap[id].variants, prefix) end
                    end
                end
            end
        else
            print("[Mod] WARNING: ExtendSkinTextures array is nil")
        end

        -- 2. Match advanced skins' Atlas/Data
        local function MapExtra(prop, field)
            local arr = DA[prop]
            if not arr then 
                print(string.format("[Mod] WARNING: %s array is nil", prop))
                return 
            end
            for i = 1, arr:GetArrayNum() do
                local obj = arr[i]
                if obj and obj:IsValid() then
                    local id = obj:GetFullName():match("(p%d%d%d%d)")
                    if id and tempMap[id] then 
                        tempMap[id][field] = obj
                        print(string.format("[Mod] Mapped %s for %s", field, id))
                    end
                end
            end
        end
        MapExtra("ExtendSkinAtlas", "customAtlas")
        MapExtra("ExtendSkinSkeleton", "customData")
    else
        print("[Mod] ERROR: Failed to load DataAsset!")
    end

    -- 3. Convert to final array and sort variants
    SKINS = {}
    for _, id in ipairs(order) do
        local skin = tempMap[id]
        table.sort(skin.variants, function(a, b) 
            if a == "" then return true end if b == "" then return false end
            return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0)
        end)
        table.insert(SKINS, skin)
    end

    print(string.format("[Mod] Total Skins Loaded: %d", #SKINS))
    INITIALIZED = true
end

-- Detect current variant index from atlas texture
local function DetectCurrentVariant(animComp, skin)
    if not animComp.Atlas or not animComp.Atlas:IsValid() then return 1 end
    
    local currentTex = animComp.Atlas.atlasPages[1]
    if not currentTex or not currentTex:IsValid() then return 1 end
    
    local currentTexName = currentTex:GetFullName():match("([^%.]+)$") or ""
    
    -- Match against all variants
    for i, prefix in ipairs(skin.variants) do
        local expectedName = (prefix == "") and (skin.asset .. "_Lily") or (skin.asset .. "_" .. prefix .. "Lily")
        if currentTexName == expectedName then
            return i
        end
    end
    
    return 1
end

-- Apply texture for specific variant
local function ApplyTexture(animComp, skin, vIndex)
    local variantPrefix = skin.variants[vIndex] or ""
    local texName = (variantPrefix == "") and (skin.asset .. "_Lily") or (skin.asset .. "_" .. variantPrefix .. "Lily")
    local texPath = string.format("/Game/_Zenith/Characters/%s_Lily/Textures/%s.%s", skin.asset, texName, texName)
    
    LoadAsset(texPath)
    local newTex = StaticFindObject(texPath)
    if newTex and newTex:IsValid() then
        if animComp.Atlas and animComp.Atlas:IsValid() then
            animComp.Atlas.atlasPages[1] = newTex
            print(string.format("[Applied] %s (Variant %d/%d)", texName, vIndex, #skin.variants))
        end
    else
        print("[Error] Failed to load texture: " .. texPath)
    end
end

-- Skin switching logic
local function SwitchSkin(index)
    if not INITIALIZED then BuildSkinTable() end
    
    -- Silently ignore if index out of range
    if index > #SKINS then return end
    
    local skin = SKINS[index]
    if not skin then return end

    local pc = FindFirstOf("PC_Base_C")
    local lily = pc and pc.PawnCharacter
    local animComp = lily and lily.SpineSkeletonAnimationEx
    if not animComp or not animComp:IsValid() then return end
    
    -- Check if advanced skin's data is still valid (may become invalid after title screen return)
    if skin.isAdvanced and skin.customAtlas and not skin.customAtlas:IsValid() then
        print("[Mod] Detected stale skin data, rebuilding...")
        INITIALIZED = false
        BuildSkinTable()
        skin = SKINS[index]
        if not skin then return end
    end

    -- Generate target path
    local folder = string.format("/Game/_Zenith/Characters/%s_Lily/", skin.asset)
    local targetAtlasPath = string.format("%s%s_Lily.%s_Lily-atlas", folder, skin.asset, skin.asset)
    
    local currentAtlasPath = ""
    if animComp.Atlas and animComp.Atlas:IsValid() then
        currentAtlasPath = animComp.Atlas:GetFullName():match("%s(.+)$") or ""
    end

    -- Check if skeleton data needs to be switched
    if currentAtlasPath ~= targetAtlasPath then
        print(string.format("[Base] Switching to %s", skin.asset))
        
        local newAtlas = skin.customAtlas
        local newData = skin.customData

        -- If not configured in DataAsset (base skins), then search manually
        if not newAtlas or not newData then
            local dataPath = folder .. skin.asset .. "_Lily." .. skin.asset .. "_Lily-data"
            LoadAsset(targetAtlasPath)
            LoadAsset(dataPath)
            newAtlas = StaticFindObject(targetAtlasPath)
            newData = StaticFindObject(dataPath)
        end

        if newAtlas and newData and newAtlas:IsValid() and newData:IsValid() then
            local paramComp = FindFirstOf("ParameterPlayerComponent")
            if paramComp and paramComp:IsValid() then
                paramComp:SetSkinLevel(skin.level)
                paramComp.SkinLevel = skin.level
            end
            animComp:ReplaceSpineData(newAtlas, newData, nil)
        end
    else
        -- Only cycle variants when staying on the same character
        if #skin.variants > 1 then
            local currentVariant = DetectCurrentVariant(animComp, skin)
            local nextVariant = (currentVariant % #skin.variants) + 1
            ApplyTexture(animComp, skin, nextVariant)
        else
            ApplyTexture(animComp, skin, 1)
        end
    end
end

-- Hotkey registration (Alt+1~9, Alt+A~Z)
local function RegisterBinds()
    local keys = {
        Key.ONE, Key.TWO, Key.THREE, Key.FOUR, Key.FIVE, Key.SIX, Key.SEVEN, Key.EIGHT, Key.NINE,
        Key.A, Key.B, Key.C, Key.D, Key.E, Key.F, Key.G, Key.H, Key.I, Key.J, Key.K, Key.L, Key.M,
        Key.N, Key.O, Key.P, Key.Q, Key.R, Key.S, Key.T, Key.U, Key.V, Key.W, Key.X, Key.Y, Key.Z,
    }
    for i, k in ipairs(keys) do
        RegisterKeyBind(k, {ModifierKey.ALT}, function()
            ExecuteInGameThread(function()
                local ok, err = pcall(function() SwitchSkin(i) end)
                if not ok then print("[Fatal] " .. tostring(err)) end
            end)
        end)
    end
    
    -- Ghost mode (Alt+0)
    RegisterKeyBind(Key.ZERO, {ModifierKey.ALT}, function()
        ExecuteInGameThread(function()
            local pc = FindFirstOf("PC_Base_C")
            local animComp = pc and pc.PawnCharacter and pc.PawnCharacter.SpineSkeletonAnimationEx
            if animComp and animComp.Atlas then
                animComp.Atlas.atlasPages[1] = nil
                print("[Special] Ghost State")
            end
        end)
    end)
end

RegisterBinds()
print("[Mod] SwitchSkinMod Loaded (Stateless Version).")
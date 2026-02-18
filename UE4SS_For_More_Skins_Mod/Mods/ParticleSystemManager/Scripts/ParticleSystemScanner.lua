-- ParticleSystemManager/Scripts/ParticleSystemScanner.lua

local ParticleSystemScanner = {}

local function GetSafeFullName(obj)
    if not obj then return "Nil" end
    local valid = false
    -- 用 pcall 包裹 IsValid，防止 nullptr 导致的 C++ 异常
    pcall(function() valid = obj:IsValid() end)
    if not valid then return "Invalid" end
    local status, result = pcall(function() return obj:GetFullName() end)
    return (status and result) and result or "Error"
end

local function ParseUEString(fullStr)
    if not fullStr or fullStr == "Nil" or fullStr == "Error" or fullStr == "Invalid" then 
        return "UnknownClass", "UnknownID" 
    end
    -- 从全名截取类名和 ID
    local className = fullStr:match("^(.-)%s") or "UnknownClass"
    local objectId = fullStr:match(":([%w_]+)$") or fullStr:match("%.([%w_]+)$") or "UnknownID"
    return className, objectId
end

-- ==================== 打印逻辑 ====================

function ParticleSystemScanner.TreePrint(instance)
    if not instance or not instance.LODs then return end

    print("\n" .. string.rep("=", 60))
    print(string.format(">> 粒子系统视图: %s", instance.psPath))
    print(string.rep("=", 60))

    for i, lodData in ipairs(instance.LODs) do
        -- 从新结构中提取实际的 LOD 对象
        local lod = lodData.lodObj
        local lodFull = GetSafeFullName(lod)
        if lodFull ~= "Nil" and lodFull ~= "Invalid" then
            
            -- 获取发射器名称
            local eName = "Unnamed"
            local emitter = lod:GetOuter()
            if emitter and emitter:IsValid() then
                eName = emitter.EmitterName:ToString()
            end
            
            print(string.format("  [Slot %d] %s", i, eName))

            -- 1. 材质
            local matName = "None"
            if lod.RequiredModule and lod.RequiredModule.Material then
                matName = lod.RequiredModule.Material:GetFName():ToString()
            end
            print(string.format("      ├─ 材质: %s", matName))

            -- 2. 三大核心模块 ID 解析
            local _, reqId = ParseUEString(GetSafeFullName(lod.RequiredModule))
            local _, tdId  = ParseUEString(GetSafeFullName(lod.TypeDataModule))
            local _, spId  = ParseUEString(GetSafeFullName(lod.SpawnModule))
            
            print(string.format("      ├─ Required: %s", reqId))
            print(string.format("      ├─ TypeDataModule: %s", tdId))
            print(string.format("      ├─ SpawnModule: %s", spId))
            
            -- 3. 峰值 (Debugger 逻辑)
            local peak = lod.PeakActiveParticles or "N/A"
            print(string.format("      ├─ PeakActiveParticles: %s", tostring(peak)))

            -- 4. 深度扫描子模块
            local mods = lod.Modules
            local count = mods:GetArrayNum()
            print(string.format("      └─ 包含模块 (%d 个):", count))

            for j = 1, count do
                local m = mods[j]
                local branch = (j == count) and "          └─ " or "          ├─ "
                
                -- 解析并清洗类名
                local mClass, mId = ParseUEString(GetSafeFullName(m))
                local shortClass = mClass:gsub("ParticleModule", "")
                
                print(string.format("%s[%s] | ID: %s", branch, shortClass, mId))
            end
        else
            print(string.format("  [Slot %d] 警告: LOD对象无效 (%s)", i, lodFull))
        end
    end
    print(string.rep("-", 60) .. "\n")
end

return ParticleSystemScanner
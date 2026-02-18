-- AbilitiesMod/Scripts/SetCommandActionTimeline.lua

-- ===============================================================
--   Module: SetCommandActionTimeline
--   职责: 修改 CommandAction 的 AbilityTimeline 逻辑时间轴
-- ===============================================================

local SetCommandActionTimeline = {}

--[[
    函数: SetTimelineTo
    作用: 修改指定 CA 类的所有实例以及默认对象的 Timeline.To 值
    输入: 
        - className: 字符串, 例如 "CA_s5030_Attack_Air_Sp_01_C"
        - defaultPath: 字符串, 完整路径, 例如 "/Game/.../CA_s5030_Attack_Air_Sp_01.Default__CA_s5030_Attack_Air_Sp_01_C"
        - targetValue: 浮点数, 目标 To 值 (持续时间)
]]
function SetCommandActionTimeline.SetTimelineTo(className, defaultPath, targetValue)
    if not className or not defaultPath or not targetValue then return end

    -- 内部辅助：执行具体的修改操作
    local function ApplyToObj(obj, label)
        if obj and obj:IsValid() and obj.AbilityTimeline then
            local entries = obj.AbilityTimeline.Entries
            if entries and entries[1] then
                local entry = entries[1]
                local oldTo = entry.To
                entry.To = targetValue
                -- print(string.format("[Timeline] %-15s | %s | To: %.2f -> %.2f", className, label, oldTo, targetValue))
                return true
            end
        end
        return false
    end

    -- 1. 修改内存中所有现有的实例 (FindAllOf)
    local instances = FindAllOf(className)
    if instances then
        for _, ca in pairs(instances) do
            ApplyToObj(ca, "Instance")
        end
    end

    -- 2. 修改默认对象 (StaticFindObject)
    -- 必须修改默认对象，否则新生成的技能对象会恢复原样
    local defaultObj = StaticFindObject(defaultPath)
    if defaultObj then
        ApplyToObj(defaultObj, "Default")
    else
        print(string.format("[Timeline] 警告: 找不到默认对象 %s", defaultPath))
    end
end

return SetCommandActionTimeline
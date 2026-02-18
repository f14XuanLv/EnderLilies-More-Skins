-- ParticleSystemManager/Scripts/ParticleSpriteEmitter/Modules/ParticleModuleLifetime.lua

-- ===============================================================
--   Module: ParticleModuleLifetime
--   映射类: UScriptClass'ParticleModuleLifetime'
-- ===============================================================

local ParticleModuleLifetime = {}

-- ==================== 数据结构参考 ====================
-- LifetimeData: { Min = float, Max = float, Values = {float, ...} }
-- 
-- Lifetime 结构示例:
-- (MinValue=1.000000,MaxValue=1.000000,Distribution=None,
--  Table=(TimeScale=0.000000,TimeBias=0.000000,Values=(1.000000),
--         Op=1,EntryCount=1,EntryStride=1,SubEntryStride=0,LockFlag=0))

-- 1. 获取当前 Lifetime 数据 (用于初始化备份)
function ParticleModuleLifetime.GetLifetime(moduleObj)
    if not moduleObj or not moduleObj:IsValid() then return nil end
    local data = { Min = moduleObj.Lifetime.MinValue, Max = moduleObj.Lifetime.MaxValue, Values = {} }
    if moduleObj.Lifetime.Table and moduleObj.Lifetime.Table.Values then
        local ueVals = moduleObj.Lifetime.Table.Values
        for i = 1, ueVals:GetArrayNum() do 
            data.Values[i] = ueVals[i] 
        end
    end
    return data
end

-- 2. 设置 Lifetime 数据
function ParticleModuleLifetime.SetLifetime(moduleObj, data)
    if not moduleObj or not data then return end
    moduleObj.Lifetime.MinValue = data.Min or 1.0
    moduleObj.Lifetime.MaxValue = data.Max or 1.0
    if moduleObj.Lifetime.Table and moduleObj.Lifetime.Table.Values and data.Values then
        local ueVals = moduleObj.Lifetime.Table.Values
        for i = 1, ueVals:GetArrayNum() do
            if data.Values[i] then
                ueVals[i] = data.Values[i]
            end
        end
    end
end

-- 3. 简单设置 Lifetime (将 Min、Max 和 Values 都设置为同一个值)
function ParticleModuleLifetime.SetLifetimeSimple(moduleObj, value)
    if not moduleObj or not value then return end
    moduleObj.Lifetime.MinValue = value
    moduleObj.Lifetime.MaxValue = value
    if moduleObj.Lifetime.Table and moduleObj.Lifetime.Table.Values then
        local ueVals = moduleObj.Lifetime.Table.Values
        for i = 1, ueVals:GetArrayNum() do
            ueVals[i] = value
        end
    end
end

return ParticleModuleLifetime
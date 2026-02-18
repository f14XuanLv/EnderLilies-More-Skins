-- ParticleSystemManager/Scripts/ParticleSpriteEmitter/ParticleModuleRequired.lua

-- ===============================================================
--   Module: ParticleModuleRequired
--   映射类: UScriptClass'ParticleModuleRequired'
-- ===============================================================

local ParticleModuleRequired = {}

-- ==================== 数据结构参考 ====================
-- EmitterDuration: float (发射器持续时间，单位：秒)

-- 1. 获取当前 EmitterDuration 数据 (用于初始化备份)
function ParticleModuleRequired.GetEmitterDuration(moduleObj)
    if not moduleObj or not moduleObj:IsValid() then return nil end
    return moduleObj.EmitterDuration
end

-- 2. 设置 EmitterDuration 数据
function ParticleModuleRequired.SetEmitterDuration(moduleObj, duration)
    if not moduleObj or not moduleObj:IsValid() then return end
    moduleObj.EmitterDuration = duration or 1.0
end

return ParticleModuleRequired
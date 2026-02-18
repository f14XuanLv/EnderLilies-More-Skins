-- ===============================================================
--   Module: ParticleTypeDataManager
--   职责: 处理发射器类型数据 (TypeData) 的剥离与转换
-- ===============================================================

local ParticleTypeDataManager = {}

--[[
    函数: StripTypeDataGpu
    作用: 剥离 GPU 类型数据模块。
    原理: 通过将 TypeDataModule 槽位设为 nil，强制该发射器从 GPU 仿真管线
          回退（Fallback）至 CPU 仿真管线，使得 Lua 动态修改的
          ColorOverLife 等模块的查找表（Lookup Table）能够生效（实时反映在视觉表现上）。
    输入: lodObj (UParticleLODLevel)
]]
function ParticleTypeDataManager.StripTypeDataGpu(lodObj)
    if not lodObj or not lodObj:IsValid() then return end
    
    local td = lodObj.TypeDataModule
    if td and td:IsValid() then
        -- 检查是否为 GPU 仿真模块
        if td:IsA("/Script/Engine.ParticleModuleTypeDataGpu") then
            -- 剥离操作：将槽位设为 nil
            lodObj.TypeDataModule = nil
        end
    end
end

--[[
    函数: StripAllTypeDataGpu
    作用: 遍历并剥离该粒子系统实例下所有发射器的 GPU 类型数据模块
    输入: instance (ParticleSystemManager 实例)
]]
function ParticleTypeDataManager.StripAllTypeDataGpu(instance)
    if not instance or not instance.LODs then return end
    
    for i, lodData in ipairs(instance.LODs) do
        ParticleTypeDataManager.StripTypeDataGpu(lodData.lodObj)
    end
end

return ParticleTypeDataManager
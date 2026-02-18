-- ParticleSystemManager/Scripts/ParticleSystemManager.lua

local ParticleSystemManager = {}
ParticleSystemManager.__index = ParticleSystemManager

-- 引入底层逻辑模块
local ScannerLib  = require("ParticleSystemScanner")
local RequiredLib = require("ParticleSpriteEmitter.ParticleModuleRequired")
local SpawnLib    = require("ParticleSpriteEmitter.ParticleModuleSpawn")
local LifetimeLib = require("ParticleSpriteEmitter.Modules.ParticleModuleLifetime")
local ColorLib    = require("ParticleSpriteEmitter.Modules.ParticleModuleColorOverLife")
local TypeDataLib = require("ParticleTypeDataManager")

-- ========== 获取指定 Slot 的子模块 (需通过 .lodObj 访问) ==========
function ParticleSystemManager:GetModule(slotId, className)
    if not self:_ValidateSlot(slotId) then return nil end
    local mods = self.LODs[slotId].lodObj.Modules
    if not mods or not mods:IsValid() then return nil end
    for i = 1, mods:GetArrayNum() do
        if mods[i]:IsA("/Script/Engine." .. className) then return mods[i] end
    end
    return nil
end

-- ==================== 初始扫描与备份 ====================
function ParticleSystemManager:InternalInitialScan(psObj)
    local emitters = psObj.Emitters
    local count = emitters:GetArrayNum()
    
    for i = 1, count do
        local emitter = emitters[i]
        local lod = emitter.LODLevels[1]
        
        -- 先初始化基础结构（包含 lodObj），使得 GetModule 等函数可以正常工作
        self.LODs[i] = { lodObj = lod }
        
        -- 按照 UE4 ParticleLODLevel 的结构备份数据
        self.LODs[i].RequiredModuleData = {
            -- 利用 RequiredLib 提供的函数获取原始数值备份
            OriginalEmitterDuration = RequiredLib.GetEmitterDuration(lod.RequiredModule)
        }

        self.LODs[i].SpawnModuleData = {
            -- 利用 SpawnLib 提供的函数获取原始数值备份
            OriginalRate = SpawnLib.GetRate(lod.SpawnModule),
            OriginalBurstList = SpawnLib.GetBurstList(lod.SpawnModule)
        }

        self.LODs[i].ModulesData = {
            LifetimeModule = {
                -- 利用 GetModule 和 LifetimeLib 获取原始数值备份
                OriginalLifetime = LifetimeLib.GetLifetime(self:GetModule(i, "ParticleModuleLifetime"))
            },
            ColorOverLifeModule = {
                -- 利用 GetModule 和 ColorLib 获取原始数值备份
                OriginalColorOverLife = ColorLib.GetColorOverLife(self:GetModule(i, "ParticleModuleColorOverLife"))
            }
        }
    end
end

-- ================== 验证 Slot ID ==================
function ParticleSystemManager:_ValidateSlot(slotId)
    local max = #self.LODs
    if slotId < 1 or slotId > max then
        local psShortName = self.psPath:match("%.([%w_]+)$") or self.psPath
        local validIds = {}
        for i=1, max do table.insert(validIds, i) end

        print(string.format("[ParticleSystemManager Warning] 粒子系统 [%s] 不存在 Slot ID: %d", psShortName, slotId))
        print(string.format(">> 该系统有效的 Slot ID 为: {%s} -> 操作已跳过。", table.concat(validIds, ", ")))
        return false
    end
    return true
end

-- ==================== 构造函数 ====================
function ParticleSystemManager.new(psPath)
    local self = setmetatable({}, ParticleSystemManager)
    
    self.psPath = psPath
    self.LODs = {}

    LoadAsset(psPath)
    local psObj = StaticFindObject(psPath)
    
    if psObj and psObj:IsValid() then
        self:InternalInitialScan(psObj)
    else
        error("[ParticleSystemManager] 无法加载资源路径: " .. tostring(psPath))
    end
    
    return self
end

-- ==================== 实例方法 ====================

-- 打印树状结构
function ParticleSystemManager:TreePrint()
    ScannerLib.TreePrint(self)
end

-- 设置发射器持续时间
function ParticleSystemManager:SetEmitterDuration(slotId, duration)
    if self:_ValidateSlot(slotId) then
        RequiredLib.SetEmitterDuration(self.LODs[slotId].lodObj.RequiredModule, duration)
    end
end

-- 设置 Lifetime 数据
function ParticleSystemManager:SetLifetime(slotId, lifetimeData)
    if not self:_ValidateSlot(slotId) then return end
    local lifetimeModule = self:GetModule(slotId, "ParticleModuleLifetime")
    if lifetimeModule then
        LifetimeLib.SetLifetime(lifetimeModule, lifetimeData)
    end
end

-- 简单设置 Lifetime (将 Min、Max 和 Values 都设置为同一个值)
function ParticleSystemManager:SetLifetimeSimple(slotId, value)
    if not self:_ValidateSlot(slotId) then return end
    local lifetimeModule = self:GetModule(slotId, "ParticleModuleLifetime")
    if lifetimeModule then
        LifetimeLib.SetLifetimeSimple(lifetimeModule, value)
    end
end

-- 设置 ColorOverLife 数据
function ParticleSystemManager:SetColorOverLife(slotId, colorData)
    if not self:_ValidateSlot(slotId) then return end
    local colorModule = self:GetModule(slotId, "ParticleModuleColorOverLife")
    if colorModule then
        ColorLib.SetColorOverLife(colorModule, colorData)
    end
end

-- 关闭发射器
function ParticleSystemManager:CloseEmitter(slotId)
    if self:_ValidateSlot(slotId) then
        SpawnLib.CloseEmitter(self.LODs[slotId].lodObj.SpawnModule)
    end
end

-- 重新开启发射器 (从 self 提取备份数据)
function ParticleSystemManager:ReOpenEmitter(slotId)
    if self:_ValidateSlot(slotId) then
        local originalData = {
            Rate = self.LODs[slotId].SpawnModuleData.OriginalRate,
            BurstList = self.LODs[slotId].SpawnModuleData.OriginalBurstList
        }
        SpawnLib.ReOpenEmitter(self.LODs[slotId].lodObj.SpawnModule, originalData)
    end
end

-- 直接开启发射器 (无需备份数据)
function ParticleSystemManager:OpenEmitter(slotId, targetValue)
    if self:_ValidateSlot(slotId) then
        SpawnLib.OpenEmitter(self.LODs[slotId].lodObj.SpawnModule, targetValue)
    end
end

-- 剥离 GPU 类型数据模块
function ParticleSystemManager:StripTypeDataGpu(slotId)
    if self:_ValidateSlot(slotId) then
        TypeDataLib.StripTypeDataGpu(self.LODs[slotId].lodObj)
    end
end

-- 剥离所有 GPU 类型数据模块
function ParticleSystemManager:StripAllTypeDataGpu()
    TypeDataLib.StripAllTypeDataGpu(self)
end

return ParticleSystemManager
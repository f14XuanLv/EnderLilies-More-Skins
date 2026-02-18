-- ParticleSystemManager/Scripts/ParticleSpriteEmitter/ParticleModuleSpawn.lua

local ParticleModuleSpawn = {}

-- ==================== 数据结构参考 ====================
-- RateData: { Min = float, Max = float, Values = {float, ...} }
-- BurstData: { {Count=int, CountLow=int, Time=float}, ... }

-- 1. 获取当前 Rate 数据 (用于初始化备份)
function ParticleModuleSpawn.GetRate(moduleObj)
    if not moduleObj or not moduleObj:IsValid() then return nil end
    local data = { Min = moduleObj.Rate.MinValue, Max = moduleObj.Rate.MaxValue, Values = {} }
    if moduleObj.Rate.Table and moduleObj.Rate.Table.Values then
        local ueVals = moduleObj.Rate.Table.Values
        for i = 1, ueVals:GetArrayNum() do data.Values[i] = ueVals[i] end
    end
    return data
end

-- 2. 设置 Rate 数据
function ParticleModuleSpawn.SetRate(moduleObj, data)
    if not moduleObj or not data then return end
    moduleObj.Rate.MinValue = data.Min or 0.0
    moduleObj.Rate.MaxValue = data.Max or 0.0
    if moduleObj.Rate.Table and moduleObj.Rate.Table.Values and data.Values then
        local ueVals = moduleObj.Rate.Table.Values
        for i = 1, ueVals:GetArrayNum() do
            if data.Values[i] then ueVals[i] = data.Values[i] end
        end
    end
end

-- 3. 获取当前 BurstList (用于初始化备份)
function ParticleModuleSpawn.GetBurstList(moduleObj)
    if not moduleObj or not moduleObj.BurstList then return {} end
    local list = {}
    local ueList = moduleObj.BurstList
    for i = 1, ueList:GetArrayNum() do
        table.insert(list, { Count = ueList[i].Count, CountLow = ueList[i].CountLow, Time = ueList[i].Time })
    end
    return list
end

-- 4. 设置 BurstList 数据
function ParticleModuleSpawn.SetBurstList(moduleObj, dataList)
    if not moduleObj or not moduleObj.BurstList or not dataList then return end
    local ueList = moduleObj.BurstList
    for i = 1, ueList:GetArrayNum() do
        local d = dataList[i]
        if d then
            ueList[i].Count = d.Count or 0
            ueList[i].CountLow = d.CountLow or -1
            ueList[i].Time = d.Time or 0.0
        end
    end
end

-- ==================== 核心开关函数 ====================

-- 5. 关闭发射器 (全清零)
function ParticleModuleSpawn.CloseEmitter(moduleObj)
    if not moduleObj then return end
    -- 清零 Rate
    local zeroRate = { Min = 0.0, Max = 0.0, Values = {} }
    if moduleObj.Rate.Table and moduleObj.Rate.Table.Values then
        for i = 1, moduleObj.Rate.Table.Values:GetArrayNum() do zeroRate.Values[i] = 0.0 end
    end
    ParticleModuleSpawn.SetRate(moduleObj, zeroRate)
    
    -- 清零 Burst
    if moduleObj.BurstList then
        local zeroBurst = {}
        for i = 1, moduleObj.BurstList:GetArrayNum() do
            table.insert(zeroBurst, { Count = 0, CountLow = -1, Time = 0.0 })
        end
        ParticleModuleSpawn.SetBurstList(moduleObj, zeroBurst)
    end
end

-- 6. 重新开启发射器 (从传入的备份数据还原)
-- 参数 originalData 格式为: { Rate = ..., BurstList = ... }
function ParticleModuleSpawn.ReOpenEmitter(moduleObj, originalData)
    if not moduleObj or not originalData then return end
    
    if originalData.Rate then
        ParticleModuleSpawn.SetRate(moduleObj, originalData.Rate)
    end
    
    if originalData.BurstList then
        ParticleModuleSpawn.SetBurstList(moduleObj, originalData.BurstList)
    end
end

-- 7. 直接开启发射器 (无需备份数据，使用默认激活值)
-- 用于在没有备份数据的情况下强制开启发射器
-- 参数 targetValue: 目标激活值，默认 10.0
function ParticleModuleSpawn.OpenEmitter(moduleObj, targetValue)
    if not moduleObj or not moduleObj:IsValid() then return end
    targetValue = targetValue or 10.0
    
    -- 设置 Rate 为目标值
    if moduleObj.Rate and moduleObj.Rate.Table and moduleObj.Rate.Table.Values then
        local vals = moduleObj.Rate.Table.Values
        -- 检查 UObject 是否有效
        if vals:IsValid() then
            for i = 1, vals:GetArrayNum() do
                vals[i] = targetValue
            end
            moduleObj.Rate.MinValue = targetValue
            moduleObj.Rate.MaxValue = targetValue
        end
    end
    
    -- 设置 BurstList 为目标值
    if moduleObj.BurstList and moduleObj.BurstList:IsValid() then
        local bursts = moduleObj.BurstList
        for i = 1, bursts:GetArrayNum() do
            bursts[i].Count = math.floor(targetValue)
            bursts[i].CountLow = -1
        end
    end
end

return ParticleModuleSpawn
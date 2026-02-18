-- ParticleSystemManager/Scripts/ParticleSpriteEmitter/Modules/ParticleModuleColorOverLife.lua

-- ===============================================================
--   Module: ParticleModuleColorOverLife
--   映射类: UScriptClass'ParticleModuleColorOverLife'
-- ===============================================================

local ParticleModuleColorOverLife = {}

-- ==================== 数据结构参考 ====================
--[[
ColorOverLifeData = {
    -- 标量字段（已弃用但仍可修改）
    MinValue = float,
    MaxValue = float,
    
    -- 向量范围（RGB 上下限）
    MinValueVec = {x = float, y = float, z = float},
    MaxValueVec = {x = float, y = float, z = float},
    
    -- 分布类型
    Distribution = string,  -- "None", "Uniform", etc.
    
    -- 时间控制
    TimeScale = float,
    TimeBias = float,
    
    -- 颜色采样点数组（至少1个点，会自动插值适应到 EntryCount 个采样点）
    -- 注意：
    --   1. 如果不提供 EntryCount，将使用对象的 Table.EntryCount 原值（默认 128）
    --   2. 如果提供 EntryCount，将清空 Values 数组并重新装填数据，同时更新 Table.EntryCount
    -- 插值逻辑：无论传入多少个点，都会在这些点的完整范围内进行线性插值，
    --           最终生成 EntryCount 个均匀分布的采样点
    --   • 传入点数 < EntryCount：在源点之间插值，生成更多中间过渡点
    --   • 传入点数 = EntryCount：每个源点直接对应一个目标采样点
    --   • 传入点数 > EntryCount：从所有源点的范围内均匀采样（保留全部颜色信息）
    ColorPoints = {
        {r = float, g = float, b = float},
        {r = float, g = float, b = float},
        ...
    },
    
    -- 自定义采样点数量（可选）
    EntryCount = int,  -- 如果提供，将清空 Values 数组并重新装填为指定数量的采样点
    
    -- 操作类型
    Op = int,
    LockFlag = int,
    SubEntryStride = int
}
]]

-- ==================== 内部插值函数 ====================

-- 颜色点插值函数（内部使用，不导出）
-- 参数：
--   sourcePoints: 源颜色采样点数组 {{r,g,b}, ...}
--   targetCount: 目标采样点数量（从 Table.EntryCount 获取）
-- 返回：插值后的 Values 数组（长度为 targetCount * 3）
local function InterpolateColorPoints(sourcePoints, targetCount)
    local sourceCount = #sourcePoints
    if sourceCount < 1 or targetCount < 1 then return {} end
    
    local entryStride = 3  -- RGB 固定为 3
    local values = {}
    
    -- 特殊情况：只有一个源点，直接复制
    if sourceCount == 1 then
        local singleColor = sourcePoints[1]
        for i = 0, targetCount - 1 do
            local valueIdx = i * entryStride + 1
            values[valueIdx]     = singleColor.r
            values[valueIdx + 1] = singleColor.g
            values[valueIdx + 2] = singleColor.b
        end
        return values
    end
    
    -- 线性插值函数
    local function lerp(a, b, t)
        return a + (b - a) * t
    end
    
    -- 在两个颜色点之间插值
    local function lerpColor(color1, color2, t)
        return {
            r = lerp(color1.r, color2.r, t),
            g = lerp(color1.g, color2.g, t),
            b = lerp(color1.b, color2.b, t)
        }
    end
    
    -- 填充目标采样点（至少2个源点）
    for i = 0, targetCount - 1 do
        local t = targetCount > 1 and (i / (targetCount - 1)) or 0  -- 归一化位置 0.0 ~ 1.0
        
        -- 计算在源数组中的位置
        local sourcePos = t * (sourceCount - 1)  -- 0.0 ~ (sourceCount-1)
        local sourceIdx = math.floor(sourcePos)  -- 整数部分
        local sourceFrac = sourcePos - sourceIdx -- 小数部分
        
        local color
        if sourceIdx >= sourceCount - 1 then
            -- 最后一个点
            color = sourcePoints[sourceCount]
        else
            -- 在两个点之间插值
            local color1 = sourcePoints[sourceIdx + 1]  -- Lua 数组从 1 开始
            local color2 = sourcePoints[sourceIdx + 2]
            color = lerpColor(color1, color2, sourceFrac)
        end
        
        -- 写入 Values 数组
        local valueIdx = i * entryStride + 1
        values[valueIdx]     = color.r
        values[valueIdx + 1] = color.g
        values[valueIdx + 2] = color.b
    end
    
    return values
end

-- ==================== 核心函数 ====================

-- 1. 获取当前 ColorOverLife 数据（用于初始化备份）
function ParticleModuleColorOverLife.GetColorOverLife(moduleObj)
    if not moduleObj or not moduleObj:IsValid() then return nil end
    if not moduleObj.ColorOverLife then return nil end
    
    local col = moduleObj.ColorOverLife
    local data = {}
    
    -- 标量字段
    data.MinValue = col.MinValue
    data.MaxValue = col.MaxValue
    
    -- 向量范围
    if col.MinValueVec then
        data.MinValueVec = {
            x = col.MinValueVec.X,
            y = col.MinValueVec.Y,
            z = col.MinValueVec.Z
        }
    end
    
    if col.MaxValueVec then
        data.MaxValueVec = {
            x = col.MaxValueVec.X,
            y = col.MaxValueVec.Y,
            z = col.MaxValueVec.Z
        }
    end
    
    -- 分布类型
    data.Distribution = col.Distribution
    
    -- Table 属性
    if col.Table then
        data.TimeScale = col.Table.TimeScale
        data.TimeBias = col.Table.TimeBias
        data.Op = col.Table.Op
        data.LockFlag = col.Table.LockFlag
        data.SubEntryStride = col.Table.SubEntryStride
        data.EntryCount = col.Table.EntryCount
        data.EntryStride = col.Table.EntryStride
        
        -- 提取原始 Values（EntryCount × EntryStride）
        data.RawValues = {}
        if col.Table.Values then
            for i = 1, col.Table.Values:GetArrayNum() do
                data.RawValues[i] = col.Table.Values[i]
            end
        end
    end
    
    return data
end

-- 2. 设置 ColorOverLife 数据
function ParticleModuleColorOverLife.SetColorOverLife(moduleObj, data)
    if not moduleObj or not moduleObj:IsValid() then return end
    if not moduleObj.ColorOverLife then return end
    if not data then return end
    
    local col = moduleObj.ColorOverLife
    
    -- ==================== 修改标量字段 ====================
    if data.MinValue ~= nil then
        col.MinValue = data.MinValue
    end
    
    if data.MaxValue ~= nil then
        col.MaxValue = data.MaxValue
    end
    
    -- ==================== 修改向量范围 ====================
    if data.MinValueVec and col.MinValueVec then
        col.MinValueVec.X = data.MinValueVec.x or 0
        col.MinValueVec.Y = data.MinValueVec.y or 0
        col.MinValueVec.Z = data.MinValueVec.z or 0
    end
    
    if data.MaxValueVec and col.MaxValueVec then
        col.MaxValueVec.X = data.MaxValueVec.x or 255
        col.MaxValueVec.Y = data.MaxValueVec.y or 255
        col.MaxValueVec.Z = data.MaxValueVec.z or 255
    end
    
    -- ==================== 修改分布类型 ====================
    if data.Distribution ~= nil then
        pcall(function()
            col.Distribution = data.Distribution
        end)
    end
    
    -- ==================== 修改 Table 属性 ====================
    if not col.Table then return end
    
    local table = col.Table
    
    -- 时间控制
    if data.TimeScale ~= nil then
        table.TimeScale = data.TimeScale
    end
    
    if data.TimeBias ~= nil then
        table.TimeBias = data.TimeBias
    end
    
    -- 操作类型
    if data.Op ~= nil then
        table.Op = data.Op
    end
    
    if data.LockFlag ~= nil then
        table.LockFlag = data.LockFlag
    end
    
    if data.SubEntryStride ~= nil then
        table.SubEntryStride = data.SubEntryStride
    end
    
    -- ==================== 修改颜色采样点数组（动态插值）====================
    if data.ColorPoints then
        local sourcePoints = data.ColorPoints
        local sourceCount = #sourcePoints
        
        -- 验证至少有1个点
        if sourceCount < 1 then return end
        
        -- 验证每个点的格式
        for i, point in ipairs(sourcePoints) do
            if not (point.r and point.g and point.b) then return end
        end
        
        -- 动态获取目标采样点数量
        local targetCount
        if data.EntryCount ~= nil then
            -- 使用自定义的 EntryCount
            targetCount = data.EntryCount
            
            -- 清空 Values 数组
            table.Values = {}
            
            -- 设置新的 EntryCount
            table.EntryCount = targetCount
        else
            -- 使用原有的 EntryCount
            targetCount = table.EntryCount or 128
        end

        -- 重建 Values 数组
        if not table.Values then
            table.Values = {}
        end
        
        -- 调用插值函数
        local interpolatedValues = InterpolateColorPoints(sourcePoints, targetCount)
        
        -- 写入 Values 数组
        for i = 1, #interpolatedValues do
            table.Values[i] = interpolatedValues[i]
        end
    end
    
    -- ==================== 直接设置原始 Values（高级用法）====================
    if data.RawValues and table.Values then
        for i = 1, #data.RawValues do
            table.Values[i] = data.RawValues[i]
        end
    end
end

-- ==================== AlphaOverLife 数据结构参考 ====================
--[[
AlphaOverLifeData = {
    -- 标量字段
    MinValue = float,
    MaxValue = float,
    
    -- 分布类型
    Distribution = string,  -- "None", "Uniform", etc.
    
    -- 时间控制
    TimeScale = float,
    TimeBias = float,
    
    -- Alpha 采样点数组
    -- 注意：
    --   1. 如果不提供 EntryCount，将使用对象的 Table.EntryCount 原值（默认值）
    --   2. 如果提供 EntryCount，将清空 Values 数组并重新装填数据，同时更新 Table.EntryCount
    -- 插值逻辑：无论传入多少个点，都会在这些点的完整范围内进行线性插值，
    --           最终生成 EntryCount 个均匀分布的采样点
    AlphaPoints = {
        float, float, ...
    },
    
    -- 自定义采样点数量（可选）
    EntryCount = int,
    
    -- 操作类型
    Op = int,
    LockFlag = int,
    SubEntryStride = int
}
]]

-- ==================== Alpha 插值函数 ====================

-- Alpha 点插值函数（内部使用，不导出）
-- 参数：
--   sourcePoints: 源 alpha 采样点数组 {float, float, ...}
--   targetCount: 目标采样点数量（从 Table.EntryCount 获取）
-- 返回：插值后的 Values 数组（长度为 targetCount）
local function InterpolateAlphaPoints(sourcePoints, targetCount)
    local sourceCount = #sourcePoints
    if sourceCount < 1 or targetCount < 1 then return {} end
    
    local values = {}
    
    -- 特殊情况：只有一个源点，直接复制
    if sourceCount == 1 then
        local singleAlpha = sourcePoints[1]
        for i = 0, targetCount - 1 do
            values[i + 1] = singleAlpha
        end
        return values
    end
    
    -- 线性插值函数
    local function lerp(a, b, t)
        return a + (b - a) * t
    end
    
    -- 填充目标采样点（至少2个源点）
    for i = 0, targetCount - 1 do
        local t = targetCount > 1 and (i / (targetCount - 1)) or 0  -- 归一化位置 0.0 ~ 1.0
        
        -- 计算在源数组中的位置
        local sourcePos = t * (sourceCount - 1)  -- 0.0 ~ (sourceCount-1)
        local sourceIdx = math.floor(sourcePos)  -- 整数部分
        local sourceFrac = sourcePos - sourceIdx -- 小数部分
        
        local alpha
        if sourceIdx >= sourceCount - 1 then
            -- 最后一个点
            alpha = sourcePoints[sourceCount]
        else
            -- 在两个点之间插值
            local alpha1 = sourcePoints[sourceIdx + 1]  -- Lua 数组从 1 开始
            local alpha2 = sourcePoints[sourceIdx + 2]
            alpha = lerp(alpha1, alpha2, sourceFrac)
        end
        
        -- 写入 Values 数组
        values[i + 1] = alpha
    end
    
    return values
end

-- ==================== AlphaOverLife 函数 ====================

-- 3. 获取当前 AlphaOverLife 数据
function ParticleModuleColorOverLife.GetAlphaOverLife(moduleObj)
    if not moduleObj or not moduleObj:IsValid() then return nil end
    if not moduleObj.AlphaOverLife then return nil end
    
    local alpha = moduleObj.AlphaOverLife
    local data = {}
    
    -- 标量字段
    data.MinValue = alpha.MinValue
    data.MaxValue = alpha.MaxValue
    
    -- 分布类型
    data.Distribution = alpha.Distribution
    
    -- Table 属性
    if alpha.Table then
        data.TimeScale = alpha.Table.TimeScale
        data.TimeBias = alpha.Table.TimeBias
        data.Op = alpha.Table.Op
        data.LockFlag = alpha.Table.LockFlag
        data.SubEntryStride = alpha.Table.SubEntryStride
        data.EntryCount = alpha.Table.EntryCount
        data.EntryStride = alpha.Table.EntryStride
        
        -- 提取原始 Values（EntryCount × EntryStride）
        data.RawValues = {}
        if alpha.Table.Values then
            for i = 1, alpha.Table.Values:GetArrayNum() do
                data.RawValues[i] = alpha.Table.Values[i]
            end
        end
    end
    
    return data
end

-- 4. 设置 AlphaOverLife 数据
function ParticleModuleColorOverLife.SetAlphaOverLife(moduleObj, data)
    if not moduleObj or not moduleObj:IsValid() then return end
    if not moduleObj.AlphaOverLife then return end
    if not data then return end
    
    local alpha = moduleObj.AlphaOverLife
    
    -- ==================== 修改标量字段 ====================
    if data.MinValue ~= nil then
        alpha.MinValue = data.MinValue
    end
    
    if data.MaxValue ~= nil then
        alpha.MaxValue = data.MaxValue
    end
    
    -- ==================== 修改分布类型 ====================
    if data.Distribution ~= nil then
        pcall(function()
            alpha.Distribution = data.Distribution
        end)
    end
    
    -- ==================== 修改 Table 属性 ====================
    if not alpha.Table then return end
    
    local table = alpha.Table
    
    -- 时间控制
    if data.TimeScale ~= nil then
        table.TimeScale = data.TimeScale
    end
    
    if data.TimeBias ~= nil then
        table.TimeBias = data.TimeBias
    end
    
    -- 操作类型
    if data.Op ~= nil then
        table.Op = data.Op
    end
    
    if data.LockFlag ~= nil then
        table.LockFlag = data.LockFlag
    end
    
    if data.SubEntryStride ~= nil then
        table.SubEntryStride = data.SubEntryStride
    end
    
    -- ==================== 修改 Alpha 采样点数组（动态插值）====================
    if data.AlphaPoints then
        local sourcePoints = data.AlphaPoints
        local sourceCount = #sourcePoints
        
        -- 验证至少有1个点
        if sourceCount < 1 then return end
        
        -- 验证每个点是数字
        for i, point in ipairs(sourcePoints) do
            if type(point) ~= "number" then return end
        end
        
        -- 动态获取目标采样点数量
        local targetCount
        if data.EntryCount ~= nil then
            -- 使用自定义的 EntryCount
            targetCount = data.EntryCount
            
            -- 清空 Values 数组
            table.Values = {}
            
            -- 设置新的 EntryCount
            table.EntryCount = targetCount
        else
            -- 使用原有的 EntryCount
            targetCount = table.EntryCount or 1
        end

        -- 重建 Values 数组
        if not table.Values then
            table.Values = {}
        end
        
        -- 调用插值函数
        local interpolatedValues = InterpolateAlphaPoints(sourcePoints, targetCount)
        
        -- 写入 Values 数组
        for i = 1, #interpolatedValues do
            table.Values[i] = interpolatedValues[i]
        end
    end
    
    -- ==================== 直接设置原始 Values（高级用法）====================
    if data.RawValues and table.Values then
        for i = 1, #data.RawValues do
            table.Values[i] = data.RawValues[i]
        end
    end
end

return ParticleModuleColorOverLife
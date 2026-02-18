-- AbilitiesMod/Scripts/S5030/Sp.lua

--[[
## **PS_S5030_Attack_Sp_01 映射表**

| Slot | 描述 |
|------|------|
| **1** | 发散喷射的雾，原深红色 |
| **2** | 中距轻微发散的火光，原紫色 |
| **3** | 中心主光柱，原亮橘红色 |
| **4** | 中心离散血片，原深红黑色 |
| **5** | 外围细光针片，原紫色+橘红色 |
| **6** | 中心粒子，原橘红色 |
| **7** | 喷射口外层短距发散喷射光，原紫色 |
| **8** | 喷射口内层中短距发散喷射光，原红色 |

## **PS_S5030_Attack_Sp_02 映射表**

| Slot | 描述 |
|------|------|
| **1** | 外围光圈，原橘红色 |
]]--

local Sp = {}

local toolkitPath = "Mods/ParticleSystemManager/Scripts/?.lua"
if not string.find(package.path, toolkitPath, 1, true) then
    package.path = package.path .. ";" .. toolkitPath
end

local PSM = require("ParticleSystemManager")
local TimelineLib = require("SetCommandActionTimeline")

-- ==================== 持久化粒子系统对象 ====================
local particleSystems = {
    sp01 = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5030_Attack_Sp_01.PS_S5030_Attack_Sp_01",
        instance = nil
    },
    sp02 = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5030_Attack_Sp_02.PS_S5030_Attack_Sp_02",
        instance = nil
    }
}

-- ==================== 发射器开关配置（Apply 1/2/3 共用）====================
--[[
配置说明：
  - "DoNothing": 不对发射器做任何操作（推荐用于发布 mod）
  - "Open":      强制开启发射器（用于调试观察，但无法完美还原原始 Spawn 参数）
  - "Close":     关闭发射器（用于调试观察）
  
注意事项：
  - Open/Close 主要用于调试时观察单个发射器的效果
  - Open 使用固定值激活发射器，无法完美还原原始的 Spawn 参数
  - ReOpen 需要完整的状态备份，对状态保存要求严格，暂时不采用
  - 发布 mod 时建议全部设置为 "DoNothing"，让发射器保持原始状态
]]--
local EmitterConfig = {
    sp01 = {
        [1] = "DoNothing",  -- Slot 1: 发散喷射的雾
        [2] = "DoNothing",  -- Slot 2: 中距轻微发散的火光
        [3] = "DoNothing",  -- Slot 3: 中心主光柱
        [4] = "DoNothing",  -- Slot 4: 中心离散血片
        [5] = "DoNothing",  -- Slot 5: 外围细光针片
        [6] = "DoNothing",  -- Slot 6: 中心粒子
        [7] = "DoNothing",  -- Slot 7: 喷射口外层短距发散喷射光
        [8] = "DoNothing",  -- Slot 8: 喷射口内层中短距发散喷射光
    },
    sp02 = {
        [1] = "DoNothing",  -- Slot 1: 外围光圈
    }
}

-- 懒加载：确保对象在游戏线程中创建
local function EnsureParticleSystems()
    for name, ps in pairs(particleSystems) do
        if not ps.instance then
            ps.instance = PSM.new(ps.path)
        end
    end
end

-- 设置技能时间轴的辅助函数
local function SetAbilityTimeline(timelineTo)
    -- 空中奥义
    TimelineLib.SetTimelineTo(
        "CA_s5030_Attack_Air_Sp_01_C",
        "/Game/_Zenith/Gameplay/CommandActions/Spirits/s5030_Leader/CA_s5030_Attack_Air_Sp_01.Default__CA_s5030_Attack_Air_Sp_01_C",
        timelineTo
    )

    -- 地面奥义
    TimelineLib.SetTimelineTo(
        "CA_s5030_Attack_Ground_Sp_01_C",
        "/Game/_Zenith/Gameplay/CommandActions/Spirits/s5030_Leader/CA_s5030_Attack_Ground_Sp_01.Default__CA_s5030_Attack_Ground_Sp_01_C",
        timelineTo
    )
end

-- 应用发射器开关配置
local function ApplyEmitterConfig()
    local ps01 = particleSystems.sp01.instance
    local ps02 = particleSystems.sp02.instance
    
    if not ps01 or not ps02 then
        print("[s5030] Warning: 粒子系统实例未初始化，跳过发射器配置应用")
        return
    end
    
    -- 应用 SP01 的发射器配置
    for slot, action in pairs(EmitterConfig.sp01) do
        if action == "Open" then
            ps01:OpenEmitter(slot, 10.0)
        elseif action == "Close" then
            ps01:CloseEmitter(slot)
        -- "DoNothing" 或其他值则不执行任何操作
        end
    end
    
    -- 应用 SP02 的发射器配置
    for slot, action in pairs(EmitterConfig.sp02) do
        if action == "Open" then
            ps02:OpenEmitter(slot, 10.0)
        elseif action == "Close" then
            ps02:CloseEmitter(slot)
        -- "DoNothing" 或其他值则不执行任何操作
        end
    end
end


-- 东方Project - 恋符「Master Spark」
function Sp.Apply1()
    local AbilityTimelineTo = 4.0
    local isPrintInfo = false

    -- 逻辑时间轴修改 (Timeline 部分) ---
    print("[s5030] 正在同步逻辑时间轴...")
    SetAbilityTimeline(AbilityTimelineTo)

    -- 特效修改 (PSM 部分) ---
    EnsureParticleSystems()
    
    local ps01 = particleSystems.sp01.instance
    local ps02 = particleSystems.sp02.instance
    
    if isPrintInfo then
        ps01:TreePrint()
        ps02:TreePrint()
    end
    
    -- 应用发射器开关配置
    ApplyEmitterConfig()
    
    ps01:StripAllTypeDataGpu() -- 剥离所有 GPU 类型数据模块

    -- 发射器的视觉特效的持续时间被两种逻辑控制
    -- 一个是依赖喷射后持续时间（Lifetime）
    -- 另一个是依赖持续喷射时间（EmitterDuration）
    -- 两个类型都只需要修改各自的依赖即可
    
    -- === Slot 1: 发散喷射的雾，原深红色 ===
    ps01:SetLifetimeSimple(1, 5.5)
    ps01:SetColorOverLife(1, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=204, g=0,   b=0},
            {r=204, g=102, b=0},
            {r=204, g=204, b=0},
            {r=0,   g=204, b=0},
            {r=0,   g=204, b=204},
            {r=0,   g=0,   b=204},
            {r=111, g=0,   b=204},
            {r=89, g=0, b=163},
            {r=43, g=0, b=82},
            {r=4, g=0, b=8},
            {r=2, g=0, b=4},
        }
    })
    
    -- === Slot 2: 中距轻微发散的火光，原紫色 ===
    ps01:SetLifetimeSimple(2, 6.0)
    ps01:SetColorOverLife(2, {
        TimeScale = 230.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=90, g=0,  b=0},
            {r=70, g=30, b=0},
            {r=40, g=40, b=0},
            {r=0,  g=53, b=0},
            {r=0,  g=50, b=50},
            {r=0,  g=0,  b=73},
            {r=45, g=0,  b=81},
            {r=63, g=0,  b=0},
            {r=49, g=21, b=0},
            {r=28, g=28, b=0},
            {r=0,  g=37, b=0},
            {r=0,  g=35, b=35},
            {r=0,  g=0,  b=51},
            {r=32, g=0,  b=57},
        }
    })
    
    -- === Slot 3: 中心主光柱，原亮橘红色 → 七彩祥龙（彩虹渐变）===
    ps01:SetLifetimeSimple(3, 4.0)
    ps01:SetColorOverLife(3, {
        TimeScale = 162.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=204, g=0,   b=0},    -- 红
            {r=204, g=102, b=0},    -- 橙
            {r=204, g=204, b=0},    -- 黄
            {r=0,   g=204, b=0},    -- 绿
            {r=0,   g=204, b=204},  -- 青
            {r=0,   g=0,   b=204},  -- 蓝
            {r=111, g=0,   b=204},  -- 紫
            {r=204, g=0,   b=0},    -- 红
            {r=204, g=102, b=0},    -- 橙
            {r=204, g=204, b=0},    -- 黄
            {r=0,   g=204, b=0},    -- 绿
            {r=0,   g=204, b=204},  -- 青
            {r=0,   g=0,   b=204},  -- 蓝
            {r=111, g=0,   b=204},  -- 紫
        }
    })
    
    -- === Slot 4: 中心离散血片，原深红黑色 ===
    ps01:SetEmitterDuration(4, 3.5)
    ps01:SetColorOverLife(4, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=20, g=0,  b=0},
            {r=20, g=10, b=0},
            {r=20, g=20, b=0},
            {r=0,  g=20, b=0},
            {r=0,  g=20, b=20},
            {r=0,  g=0,  b=20},
            {r=11, g=0,  b=20},
        }
    })
    
    -- === Slot 5: 外围细光针片，原紫色+橘红色 ===
    ps01:SetEmitterDuration(5, 3.5)
    ps01:SetColorOverLife(5, {
        TimeScale = 192.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=204, g=0,   b=0},
            {r=204, g=102, b=0},
            {r=204, g=204, b=0},
            {r=0,   g=204, b=0},
            {r=0,   g=204, b=204},
            {r=0,   g=0,   b=204},
            {r=111, g=0,   b=204},
        }
    })
    
    -- === Slot 6: 中心粒子，原橘红色 ===
    ps01:SetEmitterDuration(6, 2.8)
    ps01:SetColorOverLife(6, {
        TimeScale = 3.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 3,
        ColorPoints = {
            {r=30, g=0, b=60},
            {r=111, g=0, b=204},
        }
    })
    
    -- === Slot 7: 喷射口外层短距发散喷射光，原紫色 ===
    ps01:SetEmitterDuration(7, 3.2)
    ps01:SetColorOverLife(7, {
        TimeScale = 3.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 3,
        ColorPoints = {
            {r=40, g=2, b=2},
            {r=2, g=40, b=2},
            {r=2, g=2, b=40},
        }
    })
    
    -- === Slot 8: 喷射口内层中短距发散喷射光，原红色 ===
    ps01:SetEmitterDuration(8, 3.5)
    ps01:SetColorOverLife(8, {
        TimeScale = 3.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 3,
        ColorPoints = {
            {r=20, g=1, b=1},
            {r=1, g=20, b=1},
            {r=1, g=1, b=20},
        }
    })
    
    -- ========== SP02 修改 ==========
    ps02:StripAllTypeDataGpu() -- 剥离所有 GPU 类型数据模块
    ps02:SetEmitterDuration(1, 3.5)
    
    -- === Slot 1: 外围光圈，原橘红色 ===
    ps02:SetColorOverLife(1, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 128,
        ColorPoints = {
            {r=224, g=0,   b=0},
            {r=224, g=112, b=0},
            {r=224, g=224, b=0},
            {r=0,   g=224, b=0},
            {r=0,   g=224, b=224},
            {r=0,   g=0,   b=224},
            {r=122, g=0,   b=224},
        }
    })
end





-- ELDEN RING 黑夜魔法 - 黑夜彗星亚兹勒
function Sp.Apply2()
    local AbilityTimelineTo = 4.0
    local isPrintInfo = false

    -- 逻辑时间轴修改 (Timeline 部分) ---
    print("[s5030] 正在同步逻辑时间轴...")
    SetAbilityTimeline(AbilityTimelineTo)

    -- 特效修改 (PSM 部分) ---
    EnsureParticleSystems()
    
    local ps01 = particleSystems.sp01.instance
    local ps02 = particleSystems.sp02.instance
    
    if isPrintInfo then
        ps01:TreePrint()
        ps02:TreePrint()
    end
    
    -- 应用发射器开关配置
    ApplyEmitterConfig()
    
    ps01:StripAllTypeDataGpu() -- 剥离所有 GPU 类型数据模块

    -- 发射器的视觉特效的持续时间被两种逻辑控制
    -- 一个是依赖喷射后持续时间（Lifetime）
    -- 另一个是依赖持续喷射时间（EmitterDuration）
    -- 两个类型都只需要修改各自的依赖即可
    
    -- === Slot 1: 发散喷射的雾，原深红色 ===
    ps01:SetLifetimeSimple(1, 5.5)
    ps01:SetColorOverLife(1, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=20},
            {r=0, g=0, b=1}
        }
    })
    
    -- === Slot 2: 中距轻微发散的火光，原紫色 ===
    ps01:SetLifetimeSimple(2, 5.5)
    ps01:SetColorOverLife(2, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=3},
            {r=0, g=0, b=12},
            {r=0, g=0, b=3}
        }
    })
    
    -- === Slot 3: 中心主光柱，原亮橘红色 ===
    ps01:SetLifetimeSimple(3, 4.0)
    ps01:SetColorOverLife(3, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=5},
            {r=0, g=0, b=8},
            {r=0, g=0, b=10},
            {r=0, g=0, b=15},
        }
    })
    
    -- === Slot 4: 中心离散血片，原深红黑色 ===
    ps01:SetEmitterDuration(4, 3.5)
    ps01:SetColorOverLife(4, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=2}
        }
    })
    
    -- === Slot 5: 外围细光针片，原紫色+橘红色 ===
    ps01:SetEmitterDuration(5, 3.2)
    ps01:SetColorOverLife(5, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=20},
            {r=0, g=0, b=5},
        }
    })
    
    -- === Slot 6: 中心粒子，原橘红色 ===
    ps01:SetEmitterDuration(6, 3.0)
    ps01:SetColorOverLife(6, {
        TimeScale = 2.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 2,
        ColorPoints = {
            {r=0, g=0, b=5},
            {r=0, g=0, b=30}
        }
    })
    
    -- === Slot 7: 喷射口外层短距发散喷射光，原紫色 ===
    ps01:SetEmitterDuration(7, 3.2)
    ps01:SetColorOverLife(7, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=18}
        }
    })
    
    -- === Slot 8: 喷射口内层中短距发散喷射光，原红色 ===
    ps01:SetEmitterDuration(8, 3.5)
    ps01:SetColorOverLife(8, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=0, g=0, b=10}
        }
    })
    
    -- ========== SP02 修改 ==========
    ps02:StripAllTypeDataGpu() -- 剥离所有 GPU 类型数据模块
    ps02:SetEmitterDuration(1, 3.5)
    
    -- === Slot 1: 外围光圈，原橘红色 ===
    ps02:SetColorOverLife(1, {
        TimeScale = 1.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 1,
        ColorPoints = {
            {r=0, g=0, b=30},
        }
    })
end






-- 镭射炮 - 蓝
function Sp.Apply3()
    local AbilityTimelineTo = 4.0
    local isPrintInfo = false

    -- 逻辑时间轴修改 (Timeline 部分) ---
    print("[s5030] 正在同步逻辑时间轴...")
    SetAbilityTimeline(AbilityTimelineTo)

    -- 特效修改 (PSM 部分) ---
    EnsureParticleSystems()
    
    local ps01 = particleSystems.sp01.instance
    local ps02 = particleSystems.sp02.instance
    
    if isPrintInfo then
        ps01:TreePrint()
        ps02:TreePrint()
    end
    
    -- 应用发射器开关配置
    ApplyEmitterConfig()
    
    ps01:StripAllTypeDataGpu() -- 剥离所有 GPU 类型数据模块

    -- 发射器的视觉特效的持续时间被两种逻辑控制
    -- 一个是依赖喷射后持续时间（Lifetime）
    -- 另一个是依赖持续喷射时间（EmitterDuration）
    -- 两个类型都只需要修改各自的依赖即可
    
    -- === Slot 1: 发散喷射的雾，原深红色 ===
    ps01:SetLifetimeSimple(1, 5.5)
    ps01:SetColorOverLife(1, {
        TimeScale = 7.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 7,
        ColorPoints = {
            {r=50, g=100, b=255},
            {r=50, g=100, b=255},
            {r=25, g=50, b=224},
            {r=20, g=45, b=214},
            {r=5, g=10, b=50},
            {r=2, g=4, b=30},
            {r=1, g=2, b=15},
        }
    })
    
    -- === Slot 2: 中距轻微发散的火光，原紫色 ===
    ps01:SetLifetimeSimple(2, 6.0)
    ps01:SetColorOverLife(2, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=18, g=50, b=224},
            {r=18, g=50, b=255},
            {r=3, g=7, b=40}
        }
    })
    
    -- === Slot 3: 中心主光柱，原亮橘红色 ===
    ps01:SetLifetimeSimple(3, 4.0)
    ps01:SetColorOverLife(3, {
        TimeScale = 1.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=18, g=39, b=180},
        }
    })
    
    -- === Slot 4: 中心离散血片，原深红黑色 ===
    ps01:SetEmitterDuration(4, 3.5)
    ps01:SetColorOverLife(4, {
        TimeScale = 1.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=1, g=2, b=10}
        }
    })
    
    -- === Slot 5: 外围细光针片，原紫色+橘红色 ===
    ps01:SetEmitterDuration(5, 3.2)
    ps01:SetColorOverLife(5, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=19, g=57, b=190},
            {r=6, g=18, b=60},
        }
    })
    
    -- === Slot 6: 中心粒子，原橘红色 ===
    ps01:SetEmitterDuration(6, 3.0)
    ps01:SetColorOverLife(6, {
        TimeScale = 2.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 2,
        ColorPoints = {
            {r=3, g=6, b=40},
            {r=25, g=50, b=225}
        }
    })
    
    -- === Slot 7: 喷射口外层短距发散喷射光，原紫色 ===
    ps01:SetEmitterDuration(7, 3.2)
    ps01:SetColorOverLife(7, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=22, g=44, b=230}
        }
    })
    
    -- === Slot 8: 喷射口内层中短距发散喷射光，原红色 ===
    ps01:SetEmitterDuration(8, 3.5)
    ps01:SetColorOverLife(8, {
        TimeScale = 127.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        ColorPoints = {
            {r=15, g=30, b=120}
        }
    })
    
    -- ========== SP02 修改 ==========
    ps02:StripAllTypeDataGpu() -- 剥离所有 GPU 类型数据模块
    ps02:SetEmitterDuration(1, 3.5)
    
    -- === Slot 1: 外围光圈，原橘红色 ===
    ps02:SetColorOverLife(1, {
        TimeScale = 1.0,
        TimeBias = 0.0,
        MinValueVec = {x=0, y=0, z=0},
        MaxValueVec = {x=255, y=255, z=255},
        EntryCount = 1,
        ColorPoints = {
            {r=25, g=50, b=255},
        }
    })
end

return Sp
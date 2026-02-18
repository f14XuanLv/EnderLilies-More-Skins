-- AbilitiesMod/Scripts/S5000/Basic.lua

--[[
## **S5000 平A粒子系统路径**

从日志中提取的粒子系统：
- PS_S5000_A: A攻击
- PS_S5000_B: B攻击
- PS_S5000_C: C攻击
- PS_S5000_D: D攻击
- PS_S5000_E_01: E攻击 01
- PS_S5000_E_02: E攻击 02
- PS_S5000_E_03: E攻击 03
- PS_S5000_E_Air: E空中攻击

Slot 映射（针对 A/B/C/D/E_01）：

- Slot 2: 从黑骑士身上喷溅的液体 (Liquid) (原本为血深红色/Gpu数据剥离后为蓝色) - MI_Liquid
- Slot 3: 碎屑 (Dust) - MI_Hahen102
- Slot 4: 剑影 (LineShadow) - MI_Sword02/04
- Slot 5: 锐利斩击细线 (LineLight) - MI_Sword02/04
- Slot 6: 主剑光核心 (Main) - MI_Sword01/03

E_02 (砸地爆炸) Slot 映射：
- Slot 1: 碎屑 (hahen) - MI_Hahen102
- Slot 2: 高薄烟雾 (smoke) - MI_Smoke_64_G_02
- Slot 3: 低浓尘雾 (Impact) - MI_Smoke64_A
- Slot 4: 飞溅火花 (hibana) - MI_BallHard
- Slot 5: 碎屑 (dust) - MI_Hahen102

E_03 Slot 映射：
- Slot 1: 火花 - MI_BallHard
- Slot 2: 火花 - MI_BallHard

E_Air Slot 映射：
- Slot 1: 火花 - MI_BallHard
]]--

local Basic = {}

local toolkitPath = "Mods/ParticleSystemManager/Scripts/?.lua"
if not string.find(package.path, toolkitPath, 1, true) then
    package.path = package.path .. ";" .. toolkitPath
end

local PSM = require("ParticleSystemManager")

-- ==================== 持久化粒子系统对象 ====================
local particleSystems = {
    a = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_A.PS_S5000_A",
        instance = nil
    },
    b = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_B.PS_S5000_B",
        instance = nil
    },
    c = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_C.PS_S5000_C",
        instance = nil
    },
    d = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_D.PS_S5000_D",
        instance = nil
    },
    e_01 = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_E_01.PS_S5000_E_01",
        instance = nil
    },
    e_02 = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_E_02.PS_S5000_E_02",
        instance = nil
    },
    e_03 = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_E_03.PS_S5000_E_03",
        instance = nil
    },
    e_air = {
        path = "/Game/_Zenith/Art/Effects/Battle/PS_S5000_E_Air.PS_S5000_E_Air",
        instance = nil
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

-- ==================== 修改逻辑 ====================

-- 1. 处理标准的剑气 (A, B, C, D, E_01)
local function ApplySwordStyle(ps)
    if not ps then return end
    
    ps:StripAllTypeDataGpu()

    -- === Slot 2: 喷溅液体 (原本的红色/Gpu数据剥离后为蓝色) ===
    -- 直接关闭
    ps:CloseEmitter(2)

    -- Slot 3: 碎屑
    ps:SetColorOverLife(3, {
        ColorPoints = {
            {r=180, g=130, b=20},
            {r=0, g=0, b=0}
        }
    })

    -- === Slot 4: 剑影 (原本的红色影) ===
    -- 修改为黑暗金阴影色 #78734D (120, 115, 77)，要归一化
    ps:SetColorOverLife(4, {
        ColorPoints = {
            {r=120/255, g=115/255, b=77/255}, -- 起始黑暗金
            {r=10/255,  g=10/255,  b=5/255}    -- 接近消失时的暗褐色
        },
    })

    -- Slot 5: 斩击线
    ps:SetColorOverLife(5, {
        ColorPoints = {
            {r=50, g=35, b=5},
            {r=1, g=0.5, b=0}
        }
    })

    -- Slot 6: 主剑光
    ps:SetColorOverLife(6, {
        ColorPoints = {
            {r=235, g=160, b=30},
            {r=1, g=0.6, b=0.1}
        }
    })
end

-- 2. 处理砸地爆炸 (E_02)
local function ApplyExplosionStyle(ps)
    if not ps then return end
    
    ps:StripAllTypeDataGpu()
    
    -- Slot 1 Hahen 碎屑粉尘
    -- 归一化
    ps:SetColorOverLife(1, {
        ColorPoints = {
            {r=180/255, g=130/255, b=20/255},
            {r=0, g=0, b=0}
        }
    })

    -- Slot 2: Smoke 高薄烟雾
    -- 直接关闭
    ps:CloseEmitter(2)

    -- Slot 3: Impact 低浓尘雾
    -- 直接关闭
    ps:CloseEmitter(3)

    -- Slot 4: Hibana 明亮火花
    ps:SetColorOverLife(4, {
        ColorPoints = {
            {r=245, g=200, b=100},
            {r=0, g=0, b=0}
        }
    })

    -- Slot 5: Dust 碎屑粉尘
    -- 归一化
    ps:SetColorOverLife(5, {
        ColorPoints = {
            {r=180/255, g=130/255, b=20/255},
            {r=0, g=0, b=0}
        }
    })
    
end

-- 3. 处理火花 (E_03)
local function ApplySparkStyle_E_03(ps)
    if not ps then return end
    
    ps:StripAllTypeDataGpu()

    -- Slot 1: Oya
    ps:SetColorOverLife(1, {
        ColorPoints = {
            {r=245, g=200, b=100},
            {r=50, g=30, b=0}
        }
    })

    -- Slot 2: Hibana
    ps:SetColorOverLife(2, {
        ColorPoints = {
            {r=245, g=200, b=100},
            {r=50, g=30, b=0}
        }
    })
end

-- 3. 处理火花 (E_Air)
local function ApplySparkStyle_E_Air(ps)
    if not ps then return end
    
    ps:StripAllTypeDataGpu()

    -- Slot 1: hibana
    ps:SetColorOverLife(1, {
        ColorPoints = {
            {r=245, g=200, b=100},
            {r=50, g=30, b=0}
        }
    })

end

-- 打印所有粒子系统的树状结构
function Basic.PrintAllParticleSystems()
    print("\n========== S5000 平A粒子系统结构 ==========")
    
    EnsureParticleSystems()
    
    for name, ps in pairs(particleSystems) do
        if ps.instance then
            print(string.format("\n--- %s: %s ---", name:upper(), ps.path))
            ps.instance:TreePrint()
        end
    end
    
    print("\n========== 打印完成 ==========\n")
end

-- ELDEN RING 黄金律法 - 神圣属性调色
function Basic.Apply1()
    
    EnsureParticleSystems()

    -- 是否打印详细的粒子系统信息
    local isPrintInfo = false
    
    -- 应用剑气风格
    ApplySwordStyle(particleSystems.a.instance)
    ApplySwordStyle(particleSystems.b.instance)
    ApplySwordStyle(particleSystems.c.instance)
    ApplySwordStyle(particleSystems.d.instance)
    ApplySwordStyle(particleSystems.e_01.instance)
    
    -- 应用爆炸风格
    ApplyExplosionStyle(particleSystems.e_02.instance)
    
    -- 应用火花风格
    ApplySparkStyle_E_03(particleSystems.e_03.instance)
    ApplySparkStyle_E_Air(particleSystems.e_air.instance)
end

return Basic
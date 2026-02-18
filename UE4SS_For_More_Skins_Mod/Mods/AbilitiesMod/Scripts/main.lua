print("[AbilitiesMod] Script Loaded")

-- 1. 统一配置工具包路径
local toolkitPath = "Mods/ParticleSystemManager/Scripts/?.lua"
if not string.find(package.path, toolkitPath, 1, true) then
    package.path = package.path .. ";" .. toolkitPath
end

-- 2. 引入各个角色的技能模块
local S5030_Sp = require("S5030.Sp")
local S5000_Basic = require("S5000.Basic")

-- 3. 配置表：定义每个模块及其最大 Apply 数量和对应的按键
local moduleConfigs = {
    {name = "S5030_Sp", module = S5030_Sp, maxApply = 3, key = Key.Z},
    {name = "S5000_Basic", module = S5000_Basic, maxApply = 1, key = Key.X},
    -- 未来可以在此添加更多模块，例如：
    -- {name = "SomeModule", module = SomeModule, maxApply = 2, key = Key.C},
    -- {name = "AnotherModule", module = AnotherModule, maxApply = 4, key = Key.V},
}

-- 4. 状态表：存储每个模块当前的 Apply 索引
local currentIndex = {}
for _, config in ipairs(moduleConfigs) do
    currentIndex[config.name] = 1
end

-- 5. 统一的轮转函数
local function rotateAndApply(moduleName)
    ExecuteInGameThread(function()
        -- 找到对应的配置
        local config = nil
        for _, cfg in ipairs(moduleConfigs) do
            if cfg.name == moduleName then
                config = cfg
                break
            end
        end
        
        if not config then
            print("[AbilitiesMod Error] 未找到模块: " .. moduleName)
            return
        end
        
        -- 获取当前索引
        local index = currentIndex[moduleName]
        
        print(string.format("\n[AbilitiesMod] --- 应用 %s.Apply%d ---", moduleName, index))
        
        -- 调用对应的 Apply 函数
        local applyFuncName = "Apply" .. index
        local status, err = pcall(function()
            config.module[applyFuncName]()
        end)
        
        if not status then
            print("[AbilitiesMod Error] 应用失败: " .. tostring(err))
        else
            print(string.format("[AbilitiesMod] --- %s.Apply%d 已生效 ---", moduleName, index))
        end
        
        -- 轮转到下一个索引（循环）
        currentIndex[moduleName] = (index % config.maxApply) + 1
        print(string.format("[AbilitiesMod] 下次按键将应用: %s.Apply%d", moduleName, currentIndex[moduleName]))
    end)
end

-- 6. 为每个模块注册键绑定
for _, config in ipairs(moduleConfigs) do
    RegisterKeyBind(config.key, {ModifierKey.ALT}, function()
        rotateAndApply(config.name)
    end)
end

print("[AbilitiesMod] 轮转系统已初始化")
print("[AbilitiesMod] 按键绑定: Alt+Z (S5030_Sp), Alt+X (S5000_Basic)")
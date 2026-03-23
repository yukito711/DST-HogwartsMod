-- recipes.lua
-- 统一管理所有物品的合成配方
-- 规则：
--   1. 所有配方只在此文件注册，modmain.lua 不再重复注册
--   2. 新增物品直接在此文件追加，无需修改其他文件
--   3. 魔法 Tab 使用 GLOBAL.HW_MAGIC_TAB（由 modmain.lua 注入）

print("[Hogwarts] recipes.lua loaded")

local MAGIC_TAB = GLOBAL.HW_MAGIC_TAB

-- ============================================================
-- 旧版魔杖（magic_wand）
-- 保留：已验证的原始物品，供测试和过渡期使用
-- ============================================================

AddRecipe(
    "magic_wand",
    {
        Ingredient("livinglog", 2),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("bluegem", 1),
    },
    MAGIC_TAB,                  -- 统一使用魔法Tab（移除旧 RECIPETABS.WAR）
    GLOBAL.TECH.SCIENCE_TWO,
    nil, 1, nil, nil, nil,
    "images/inventoryimages/magic_wand.xml",
    "magic_wand.tex"
)

-- ============================================================
-- hw_magic_wand（新版魔杖，支持 mana 和亲和力系统）
-- 合成条件：靠近魔法工作台（MAGIC_ONE）
-- 材料：活木x2 + 独眼怪眼球x1 + 蓝宝石x1
-- ============================================================

AddRecipe(
    "hw_magic_wand",
    {
        Ingredient("livinglog", 2),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("bluegem", 1),
    },
    MAGIC_TAB,
    GLOBAL.TECH.MAGIC_ONE,
    nil, 1, nil, nil, nil,
    "images/inventoryimages/magic_wand.xml",
    "magic_wand.tex"
)

-- ============================================================
-- hw_magic_workbench（魔法工作台）
-- 合成条件：二级科学站（SCIENCE_TWO）
-- 材料：原木x4 + 活木x2 + 金块x2
-- ============================================================

AddRecipe(
    "hw_magic_workbench",
    {
        Ingredient("log", 4),
        Ingredient("livinglog", 2),
        Ingredient("goldnugget", 2),
    },
    MAGIC_TAB,
    GLOBAL.TECH.SCIENCE_TWO,
    nil, 1, nil, nil, nil,
    "images/inventoryimages/magic_wand.xml",
    "magic_wand.tex"
)

-- modmain.lua
Assets = {
    Asset("IMAGE", "images/inventoryimages/magic_wand.tex"),
    Asset("ATLAS", "images/inventoryimages/magic_wand.xml"),
}

PrefabFiles = {
    "magic_wand",
    "fireball_projectile",
}

-- 创建自定义魔法标签栏
local MAGIC_TAB = AddRecipeTab(
    "魔法",                                    -- 标签名称
    999,                                        -- 排序权重
    "images/inventoryimages/magic_wand.xml",   -- 标签图标图集
    "magic_wand.tex",                          -- 标签图标
    0                                           -- 标签类型
)

-- 魔杖配方
AddRecipe(
    "magic_wand",
    {
        Ingredient("livinglog", 2),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("bluegem", 1),
    },
    MAGIC_TAB,
    GLOBAL.TECH.SCIENCE_TWO,
    nil, 1, nil, nil, nil,
    "images/inventoryimages/magic_wand.xml",
    "magic_wand.tex"
)

print("[Hogwarts Mod] Loaded successfully!")
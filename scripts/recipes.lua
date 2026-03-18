-- recipes.lua
-- 统一管理所有物品的合成配方

-- 魔杖配方
-- 材料：活木x2 + 独眼怪眼球x1 + 蓝宝石x1

print("[Hogwarts] recipes loaded, RECIPETABS:", GLOBAL.RECIPETABS ~= nil)

AddRecipe(
    "magic_wand",
    {
        Ingredient("livinglog", 2),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("bluegem", 1),
    },
    GLOBAL.RECIPETABS.WAR,
    GLOBAL.TECH.SCIENCE_TWO,
    nil, 1, nil, nil, nil,
    "images/inventoryimages/magic_wand.xml",
    "magic_wand.tex"
)
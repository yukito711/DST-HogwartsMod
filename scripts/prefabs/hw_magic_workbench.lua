-- hw_magic_workbench.lua
-- Prefab: hw_magic_workbench
-- 魔法工作台：霍格沃茨世界所有物品的专属合成台
-- 特性：
--   - 作为 TECH.MAGIC_ONE 解锁条件，玩家必须靠近才能合成魔法物品
--   - 可用锤子拆除，返还 50% 材料
--   - 有生命值（可被破坏）

local TUNE = HWTUNE

-- ============================================================
-- 资源声明（暂时复用魔杖图标作为占位，后续替换专属贴图）
-- ============================================================

local assets = {
    Asset("IMAGE", "images/inventoryimages/magic_wand.tex"),
    Asset("ATLAS", "images/inventoryimages/magic_wand.xml"),
}

-- ============================================================
-- onhammered
-- ============================================================

--- 被锤子拆除时触发：播放拆除特效并移除实体。
-- 材料返还由 lootdropper 组件在 OnRemoveEntity 时自动处理。
-- 归属：Server
-- @param inst    entity  工作台实体
-- @param worker  entity  执行拆除的玩家
local function onhammered(inst, worker)
    if not TheWorld.ismastersim then return end

    -- 播放拆除粒子特效
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    if fx then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    inst:Remove()
end

--- 被锤子工作时触发（每次锤击），可扩展为震动动画。
-- @param inst    entity
-- @param worker  entity
-- @param workleft  number  剩余工作量
local function onwork(inst, worker, workleft)
    -- 可扩展：播放锤击动画/音效
end

-- ============================================================
-- fn
-- ============================================================

--- 创建 hw_magic_workbench 实体。
-- @return  entity  工作台实体
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- 物理：不可穿越的建筑体积
    MakeObstaclePhysics(inst, 1)

    -- 动画：暂时借用原版 "researchlab" 外观作为占位
    inst.AnimState:SetBank("researchlab")
    inst.AnimState:SetBuild("researchlab")
    inst.AnimState:PlayAnimation("idle")

    -- 小地图图标（使用科技站默认图标，后续替换）
    inst.MiniMapEntity:SetIcon("techtree.png")

    inst:AddTag("structure")
    inst:AddTag("hw_workbench")

    -- 网络同步标记
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- ---- 以下仅服务端 ----

    -- 生命值：工作台可被攻击摧毁
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNE.WORKBENCH_HEALTH)

    -- 可检查
    inst:AddComponent("inspectable")

    -- 战利品掉落（拆除时返还材料）
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({
        "livinglog",
        "boards",
    })

    -- 可锤击拆除
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)      -- 需要锤击4次
    inst.components.workable:SetOnWorkCallback(onwork)
    inst.components.workable:SetOnFinishCallback(onhammered)

    -- 科技等级：作为 MAGIC_ONE 解锁源
    -- 玩家靠近时获得 MAGIC_ONE 技术等级，离开时失去
    inst:AddComponent("prototyper")
    inst.components.prototyper.trees = {
        TECH = { MAGIC_ONE = 1 }
    }

    return inst
end

-- ============================================================
-- 字符串
-- ============================================================

STRINGS.NAMES.HW_MAGIC_WORKBENCH = "魔法工作台"
STRINGS.HW = STRINGS.HW or {}
STRINGS.HW.STRUCTURES = STRINGS.HW.STRUCTURES or {}
STRINGS.HW.STRUCTURES.MAGIC_WORKBENCH = {
    NAME     = "魔法工作台",
    DESCRIBE = "散发着古老魔力的工作台，是制作一切魔法物品的起点。",
}

return Prefab("hw_magic_workbench", fn, assets)

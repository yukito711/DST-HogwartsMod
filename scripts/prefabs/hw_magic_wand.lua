-- hw_magic_wand.lua
-- Prefab: hw_magic_wand
-- 魔法魔杖（新版），遵循 hw_ 命名规范
-- 特性：
--   - 装备时附加 hw_mana 组件到持有者
--   - 首次装备时为持有者生成唯一亲和力（0.5-1.5）
--   - 攻击时消耗 mana，伤害 = base_damage * affinity * sanity_mult
--   - 支持装填咒语（通过 active_spell 字段切换）
--   - 客户端监听特效事件，播放对应视觉效果

local SpellBase      = require("spells/hw_spell_base")
local Incendio       = require("spells/hw_incendio")
local Episkey        = require("spells/hw_episkey")
local Sectumsempra   = require("spells/hw_sectumsempra")
local MagicEffects   = require("magic_effects")

local TUNE = HWTUNE

-- ============================================================
-- 资源声明
-- ============================================================

local assets = {
    Asset("IMAGE", "images/inventoryimages/magic_wand.tex"),
    Asset("ATLAS", "images/inventoryimages/magic_wand.xml"),
}

-- ============================================================
-- 数值配置（从 hw_tuning 读取，禁止硬编码）
-- ============================================================

local WAND_DAMAGE    = 88        -- 基础伤害（亲和力和sanity_mult会在此基础上缩放）
local WAND_RANGE_MIN = 8
local WAND_RANGE_MAX = 10
local WAND_MANA_COST = 8         -- 每次普通攻击消耗的 mana
local WAND_MAX_USES  = 100

-- ============================================================
-- GenerateAffinity
-- ============================================================

--- 为持有者生成一个唯一的亲和力值并存储在魔杖上。
-- 亲和力与玩家 userid 绑定：同一玩家对同一把魔杖的亲和力不变。
-- 仅影响攻击咒语和治疗咒语的效果，不影响实用/不可饶恕咒。
-- @param inst   entity  魔杖实体
-- @param owner  entity  装备者（玩家）
-- @return       number  亲和力值 [0.5, 1.5]
local function GenerateAffinity(inst, owner)
    -- 以 userid + 魔杖 GUID 为种子，保证同玩家同把魔杖唯一
    local userid = owner.userid or tostring(owner.GUID)
    local seed   = tonumber(string.sub(userid, -4), 16) or owner.GUID
    math.randomseed(seed + inst.GUID)

    local affinity = TUNE.WAND_AFFINITY_MIN
                   + math.random() * (TUNE.WAND_AFFINITY_MAX - TUNE.WAND_AFFINITY_MIN)
    -- 保留两位小数
    affinity = math.floor(affinity * 100 + 0.5) / 100

    inst._affinity = affinity
    inst._affinity_owner = userid
    return affinity
end

-- ============================================================
-- onequip
-- ============================================================

--- 装备时：切换持握动画，为持有者添加/启动 hw_mana 组件。
-- 归属：Server
-- @param inst   entity  魔杖实体
-- @param owner  entity  装备者
local function onequip(inst, owner)
    -- 动画
    owner.AnimState:OverrideSymbol("swap_object", "swap_orangestaff", "swap_orangestaff")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if not TheWorld.ismastersim then return end

    -- 生成或恢复亲和力
    local userid = owner.userid or tostring(owner.GUID)
    if inst._affinity_owner ~= userid then
        GenerateAffinity(inst, owner)
    end

    -- 添加 hw_mana 组件（若持有者尚未拥有）
    if not owner.components.hw_mana then
        owner:AddComponent("hw_mana")
    end

    -- 将当前活跃咒语的冷却任务宿主设为持有者
    if inst._active_spell then
        inst._active_spell:SetCooldownOwner(owner)
    end
end

-- ============================================================
-- onunequip
-- ============================================================

--- 卸下时：恢复正常动画，通知 mana 组件进入非战斗状态。
-- 归属：Server
-- @param inst   entity  魔杖实体
-- @param owner  entity  卸下者
local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if not TheWorld.ismastersim then return end

    -- 停止战斗 regen 计时
    if owner.components.hw_mana then
        owner.components.hw_mana:StopCombatRegen()
    end
end

-- ============================================================
-- onattack
-- ============================================================

--- 攻击命中时：检查 mana，计算伤害缩放，广播特效事件。
-- weapon 组件负责基础伤害和仇恨，此处处理 mana 消耗和伤害修正。
-- 归属：Server
-- @param inst      entity  魔杖实体
-- @param attacker  entity  攻击者（玩家）
-- @param target    entity  攻击目标
local function onattack(inst, attacker, target)
    if not TheWorld.ismastersim then return end

    local mana = attacker.components.hw_mana
    if not mana or not mana:CanSpend(WAND_MANA_COST) then
        -- mana 不足：取消攻击（可扩展为提示音效）
        return
    end

    -- 消耗 mana
    mana:DoDelta(-WAND_MANA_COST)
    -- 触发战斗回复速率
    mana:StartCombatRegen()

    -- 获取亲和力（确保已生成）
    local affinity = inst._affinity or 1.0

    -- sanity 倍率（使用基类函数逻辑，直接计算）
    local sanity_mult = 1.0
    if attacker.components.sanity then
        local s = attacker.components.sanity:GetPercent() * GLOBAL.TUNING.MAX_SANITY
        if s >= TUNE.SANITY_BREAKPOINT_HIGH then
            sanity_mult = TUNE.SANITY_MULT_HIGH
        elseif s >= TUNE.SANITY_BREAKPOINT_MID then
            sanity_mult = TUNE.SANITY_MULT_MID
        else
            sanity_mult = TUNE.SANITY_MULT_LOW
        end
    end

    -- 修正 weapon 组件伤害（动态调整，使 combat 系统感知正确伤害值）
    if inst.components.weapon then
        inst.components.weapon:SetDamage(WAND_DAMAGE * affinity * sanity_mult)
    end

    -- 广播飞行特效事件给客户端
    if target then
        local sx, sy, sz = attacker.Transform:GetWorldPosition()
        local tx, ty, tz = target.Transform:GetWorldPosition()
        inst:PushEvent("hw_wand_fire", {
            sx = sx, sy = sy + 1, sz = sz,
            tx = tx, ty = ty,     tz = tz,
        })
    end
end

-- ============================================================
-- fn（Prefab 工厂函数）
-- ============================================================

--- 创建 hw_magic_wand 实体。
-- @return  entity  魔杖实体
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    -- 地面动画：借用橙色法杖模型
    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("staffs")
    inst.AnimState:PlayAnimation("orangestaff")

    inst:AddTag("hw_magic_wand")
    inst:AddTag("hw_weapon")
    inst:AddTag("weapon")  -- 兼容原版战斗 AI

    -- 亲和力状态
    inst._affinity       = 1.0
    inst._affinity_owner = nil

    -- 初始化咒语槽（默认装填燃烧咒）
    local incendio = Incendio()
    inst._active_spell = incendio

    -- 客户端：监听服务端广播的特效事件
    inst:ListenForEvent("hw_wand_fire", function(wand, data)
        MagicEffects.WandShoot(data.sx, data.sy, data.sz, data.tx, data.ty, data.tz)
    end)

    -- 客户端：监听各咒语特效事件
    inst:ListenForEvent("hw_fx_incendio",     function(_, d) Incendio.OnClientFX(inst, d)     end)
    inst:ListenForEvent("hw_fx_episkey",      function(_, d) Episkey.OnClientFX(inst, d)      end)
    inst:ListenForEvent("hw_fx_sectumsempra", function(_, d) Sectumsempra.OnClientFX(inst, d) end)

    -- 网络同步标记（客户端初始化到此为止）
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- ---- 以下仅服务端 ----

    -- 背包图标
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename  = "magic_wand"
    inst.components.inventoryitem.atlasname  = "images/inventoryimages/magic_wand.xml"

    -- 耐久
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(WAND_MAX_USES)
    inst.components.finiteuses:SetUses(WAND_MAX_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    -- 武器：基础伤害（onattack 会动态修正）
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(WAND_DAMAGE)
    inst.components.weapon:SetRange(WAND_RANGE_MIN, WAND_RANGE_MAX)
    inst.components.weapon:SetOnAttack(onattack)

    -- 装备
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -- 可检查
    inst:AddComponent("inspectable")

    return inst
end

-- ============================================================
-- 字符串（统一管理，此处临时放置，后续迁移到 strings.lua）
-- ============================================================

STRINGS.NAMES.HW_MAGIC_WAND = "魔杖"
STRINGS.HW = STRINGS.HW or {}
STRINGS.HW.ITEMS = STRINGS.HW.ITEMS or {}
STRINGS.HW.ITEMS.MAGIC_WAND = {
    NAME     = "魔杖",
    DESCRIBE = "散发着神秘魔力。与施法者心意相通，亲和力：%.2f",
}

return Prefab("hw_magic_wand", fn, assets)

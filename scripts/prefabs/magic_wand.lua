-- magic_wand.lua
-- 魔杖：哈利波特魔法世界第一件武器
-- 功能：远程88点伤害，每次攻击san-6，耐久100次

-- 引入魔法特效库
local MagicEffects = require("magic_effects")

local assets = {
    Asset("IMAGE", "images/inventoryimages/magic_wand.tex"),
    Asset("ATLAS", "images/inventoryimages/magic_wand.xml"),
}

-- 装备时：显示手持动画
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_orangestaff", "swap_orangestaff")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

-- 卸下时：恢复正常动画
local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

-- 服务端：攻击命中时触发
-- weapon组件负责88点伤害和仇恨系统
-- 此处额外处理：san扣减 + 广播飞行特效给客户端
local function onattack(inst, attacker, target)
    -- 每次攻击扣除6点san值
    if attacker and attacker.components.sanity then
        attacker.components.sanity:DoDelta(6)
    end

    -- 广播飞行特效位置给客户端
    if attacker and target then
        local sx, sy, sz = attacker.Transform:GetWorldPosition()
        local tx, ty, tz = target.Transform:GetWorldPosition()
        inst:PushEvent("magicwand_fire", {
            sx = sx, sy = sy + 1, sz = sz,  -- 起点略微抬高，从手部发出
            tx = tx, ty = ty, tz = tz,
        })
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- 添加物理碰撞体，让物品在地面可见可拾取
    MakeInventoryPhysics(inst)

    -- 地面模型：借用橙色法杖
    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("staffs")
    inst.AnimState:PlayAnimation("orangestaff")

    inst:AddTag("magic_wand")

    -- 客户端：监听服务端广播的飞行特效事件
    -- 在客户端生成飞行光球和爆炸特效
    inst:ListenForEvent("magicwand_fire", function(inst, data)
        MagicEffects.WandShoot(data.sx, data.sy, data.sz, data.tx, data.ty, data.tz)
    end)

    -- 网络同步标记（必须在所有客户端设置之后）
    inst.entity:SetPristine()

    -- 客户端预加载 fireball_projectile
    if not TheWorld.ismastersim then
        inst:DoTaskInTime(1, function()
            local fx = SpawnPrefab("fireball_projectile")
            if fx then
                fx.Transform:SetPosition(0, -100, 0)
                TheWorld._fireball_preload = fx
                print("[Hogwarts Mod] client fireball preloaded!")
            end
        end)
        return inst
    end

    if not TheWorld.ismastersim then
        return inst
    end

    -- 预加载飞行特效，确保 fireball_projectile 可用
    inst:DoTaskInTime(0, function()
        print("[Hogwarts Mod] inst:DoTaskInTime!")
        local fx = SpawnPrefab("fireball_projectile")
        if fx then
            fx:Remove()
            print("[Hogwarts Mod] fireball_projectile preloaded!")
        end
    end)

    -- 背包图标：借用原版橙色法杖占位，后续替换为自定义魔杖图标
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "magic_wand"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/magic_wand.xml"

    -- 耐久度：100次使用后销毁
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(100)
    inst.components.finiteuses:SetUses(100)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    -- 武器组件：负责88点伤害、远程判定和仇恨系统
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(88)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(onattack)

    -- 装备组件：手持槽位
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -- 可检查：右键查看描述
    inst:AddComponent("inspectable")

    return inst
end

-- 物品名称和描述
STRINGS.NAMES.MAGIC_WAND = "魔杖"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MAGIC_WAND = "这是一根魔杖，散发着神秘的魔力。使用它需要付出代价。"

return Prefab("magic_wand", fn, assets)
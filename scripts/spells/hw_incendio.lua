-- hw_incendio.lua
-- 燃烧咒 Incendio
-- 归属：Server（效果逻辑） + Client（特效监听）
-- 效果：点燃目标实体，使其持续燃烧 INCENDIO_FIRE_DURATION 秒。
--       若目标不可燃，则在目标位置生成地面火焰（fire prefab）。
--       实用类咒语，伤害不随 sanity 缩放。

local SpellBase = require("spells/hw_spell_base")
local SpellDefs = require("hw_data/hw_spells")

-- ============================================================
-- 定义 Incendio 类（继承 SpellBase）
-- ============================================================

local Incendio = Class(SpellBase, function(self)
    SpellBase._ctor(self, SpellDefs.incendio)
end)

-- ============================================================
-- _OnCast（重写基类钩子）
-- ============================================================

--- 施放燃烧咒的服务端效果：
--   1. 若目标有 burnable 组件，直接点燃。
--   2. 否则在目标位置生成 fire prefab。
-- @param caster  entity        施法者（玩家）
-- @param target  entity|nil    目标实体（点击怪物时有值）
-- @param pos     Vector3|nil   目标位置（点击地面时有值）
function Incendio:_OnCast(caster, target, pos)
    local duration = self.config.fire_duration

    if target and target:IsValid() then
        -- 目标可燃：使用 burnable 组件点燃
        if target.components.burnable then
            target.components.burnable:Ignite()
            -- 一段时间后自动灭火
            target:DoTaskInTime(duration, function()
                if target and target:IsValid() and target.components.burnable then
                    target.components.burnable:Extinguish()
                end
            end)
        else
            -- 目标不可燃：在其位置生成地面火焰
            local tx, ty, tz = target.Transform:GetWorldPosition()
            self:_SpawnFire(tx, ty, tz, duration)
        end
    elseif pos then
        -- 点击地面：在指定位置生成火焰
        self:_SpawnFire(pos.x, pos.y or 0, pos.z, duration)
    end
end

--- 在指定位置生成一个短命的 fire 特效 prefab。
-- @param x, y, z  number  世界坐标
-- @param duration number  自动移除延迟（秒）
function Incendio:_SpawnFire(x, y, z, duration)
    local fire = SpawnPrefab("fire")
    if fire then
        fire.Transform:SetPosition(x, y, z)
        fire:DoTaskInTime(duration, function()
            if fire and fire:IsValid() then
                fire:Remove()
            end
        end)
    end
end

-- ============================================================
-- 客户端特效监听（注册到魔杖 prefab 的 ListenForEvent）
-- ============================================================

--- 客户端收到 hw_fx_incendio 事件后播放飞行光球特效。
-- 此函数由 hw_magic_wand.lua 在客户端侧调用。
-- @param inst  entity  魔杖实体
-- @param data  table   {sx,sy,sz,tx,ty,tz}
function Incendio.OnClientFX(inst, data)
    local MagicEffects = require("magic_effects")
    -- 橙色飞行光球 + 落点爆炸（复用已有特效库）
    MagicEffects.WandShoot(data.sx, data.sy, data.sz, data.tx, data.ty, data.tz, "orange")
end

return Incendio

-- hw_sectumsempra.lua
-- 割裂咒 Sectumsempra
-- 归属：Server（效果逻辑） + Client（特效监听）
-- 效果：
--   1. 对目标造成即时伤害 = SECTUMSEMPRA_DAMAGE * sanity_mult
--   2. 施加流血 DoT：每 dot_interval 秒造成 dot_damage * sanity_mult，共 dot_ticks 次
-- 伤害随施法者 sanity 缩放（scales_with_sanity = true）
-- 对 BOSS 同样有效（无豁免）

local SpellBase = require("spells/hw_spell_base")
local SpellDefs = require("hw_data/hw_spells")

local Sectumsempra = Class(SpellBase, function(self)
    SpellBase._ctor(self, SpellDefs.sectumsempra)
end)

-- ============================================================
-- _OnCast
-- ============================================================

--- 施放割裂咒：即时伤害 + 流血 DoT。
-- @param caster  entity        施法者（玩家）
-- @param target  entity|nil    攻击目标（需有 health 组件）
-- @param pos     Vector3|nil   未使用
function Sectumsempra:_OnCast(caster, target, pos)
    if not target or not target:IsValid() then return end
    if not target.components.health then return end

    local mult = self:GetSanityMult(caster)
    local cfg  = self.config

    -- 即时伤害（忽略护甲，直接 DoDelta）
    self:_ApplyDamage(target, caster, cfg.damage * mult)

    -- 流血 DoT：分 dot_ticks 次
    for i = 1, cfg.dot_ticks do
        target:DoTaskInTime(i * cfg.dot_interval, function()
            if target and target:IsValid() and not target.components.health:IsDead() then
                self:_ApplyDamage(target, caster, cfg.dot_damage * mult)
                -- 客户端血迹特效由 "splat_blood" tag 驱动，无需额外广播
            end
        end)
    end
end

--- 对目标造成伤害，标记攻击来源以触发仇恨系统。
-- @param target  entity  攻击目标
-- @param attacker entity 攻击来源（用于仇恨/击杀归属）
-- @param amount  number  伤害量
function Sectumsempra:_ApplyDamage(target, attacker, amount)
    if target and target.components.health then
        target.components.health:DoDelta(-amount, nil, "hw_sectumsempra", attacker)
    end
end

-- ============================================================
-- 客户端特效
-- ============================================================

--- 客户端收到 hw_fx_sectumsempra 事件后播放割裂光束特效。
-- @param inst  entity  魔杖实体
-- @param data  table   {sx,sy,sz,tx,ty,tz}
function Sectumsempra.OnClientFX(inst, data)
    local MagicEffects = require("magic_effects")
    -- 复用飞行光球，后续可替换为专属红色光束特效
    MagicEffects.WandShoot(data.sx, data.sy, data.sz, data.tx, data.ty, data.tz, "red")
end

return Sectumsempra

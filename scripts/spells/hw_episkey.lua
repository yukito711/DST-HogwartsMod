-- hw_episkey.lua
-- 愈合咒 Episkey
-- 归属：Server（效果逻辑） + Client（特效监听）
-- 效果：
--   1. 立即恢复目标 HP = EPISKEY_INSTANT_HEAL * sanity_mult
--   2. 启动 HoT：每 hot_interval 秒恢复 hot_heal * sanity_mult，共 hot_ticks 次
-- 治疗量随施法者 sanity 缩放（scales_with_sanity = true）

local SpellBase = require("spells/hw_spell_base")
local SpellDefs = require("hw_data/hw_spells")

local Episkey = Class(SpellBase, function(self)
    SpellBase._ctor(self, SpellDefs.episkey)
end)

-- ============================================================
-- _OnCast
-- ============================================================

--- 施放愈合咒：立即治疗 + 启动 HoT 任务。
-- @param caster  entity        施法者
-- @param target  entity|nil    治疗目标（优先使用，若为 nil 则治疗自身）
-- @param pos     Vector3|nil   未使用（愈合咒针对实体）
function Episkey:_OnCast(caster, target, pos)
    -- 确定治疗目标：优先 target，否则治疗自身
    local heal_target = (target and target:IsValid() and target.components.health)
                        and target or caster

    local mult = self:GetSanityMult(caster)
    local cfg  = self.config

    -- 立即治疗
    self:_ApplyHeal(heal_target, cfg.instant_heal * mult)

    -- HoT：分 hot_ticks 次，每次延迟 i * hot_interval 秒
    for i = 1, cfg.hot_ticks do
        heal_target:DoTaskInTime(i * cfg.hot_interval, function()
            if heal_target and heal_target:IsValid() then
                self:_ApplyHeal(heal_target, cfg.hot_heal * mult)
            end
        end)
    end
end

--- 对目标 health 组件施加治疗。
-- @param target  entity  必须有 health 组件
-- @param amount  number  治疗量（已经过 sanity_mult 计算）
function Episkey:_ApplyHeal(target, amount)
    if target and target.components.health then
        target.components.health:DoDelta(amount)
    end
end

-- ============================================================
-- 客户端特效
-- ============================================================

--- 客户端收到 hw_fx_episkey 事件后播放愈合光环特效。
-- @param inst  entity  魔杖实体
-- @param data  table   {sx,sy,sz,tx,ty,tz}
function Episkey.OnClientFX(inst, data)
    -- 生成愈合光效（使用 heal_fx prefab，DST 内置）
    local fx = SpawnPrefab("heal_fx")
    if fx then
        fx.Transform:SetPosition(data.tx, data.ty, data.tz)
    end
end

return Episkey

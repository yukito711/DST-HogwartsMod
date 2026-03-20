-- hw_spell_base.lua
-- 咒语基类/施法调度器
-- 归属：Server（Cast/CanCast 等逻辑全部在服务端执行）
-- 所有具体咒语继承此类，并重写 _OnCast。

local TUNE = HWTUNE

local SpellBase = Class(function(self, config)
    assert(config and config.id, "[HW] SpellBase: config.id is required")
    self.config   = config
    self._cooldown_remaining = 0
    self._cooldown_task      = nil
end)

-- ============================================================
-- New（工厂函数）
-- ============================================================

--- 从咒语配置表构建咒语对象。
-- 具体咒语文件调用此函数时传入 hw_spells.lua 中对应的配置条目。
-- @param config  table   hw_spells.lua 中的单条咒语定义
-- @return        SpellBase 实例（子类通过 Class(SpellBase, ...) 继承）
function SpellBase.New(config)
    return SpellBase(config)
end

-- ============================================================
-- CanCast
-- ============================================================

--- 检查施法者是否满足施放此咒语的全部前提条件：
--   1. 冷却归零
--   2. mana 充足（hw_mana 组件）
--   3. sanity 达到阈值
-- @param caster  entity  施法者（通常是玩家）
-- @return        bool    true 表示可以施放
function SpellBase:CanCast(caster)
    -- 冷却检查
    if self._cooldown_remaining > 0 then
        return false
    end

    -- mana 检查
    local mana = caster.components.hw_mana
    if not mana or not mana:CanSpend(self.config.mana_cost) then
        return false
    end

    -- sanity 检查
    local sanity = caster.components.sanity
    if sanity then
        local current_sanity = sanity:GetPercent() * GLOBAL.TUNING.MAX_SANITY
        if current_sanity < self.config.sanity_required then
            return false
        end
    end

    return true
end

-- ============================================================
-- Cast
-- ============================================================

--- 执行施法：扣除 mana，调用具体咒语逻辑，启动冷却，广播特效事件。
-- 必须在服务端调用。调用前请先用 CanCast 检查。
-- @param caster  entity        施法者
-- @param target  entity|nil    目标实体（部分咒语可为 nil，改用 pos）
-- @param pos     Vector3|nil   目标位置（target 为 nil 时使用）
function SpellBase:Cast(caster, target, pos)
    if not TheWorld.ismastersim then return end

    -- 扣除 mana
    local mana = caster.components.hw_mana
    if mana then
        mana:DoDelta(-self.config.mana_cost)
    end

    -- 执行具体咒语逻辑（由子类重写）
    self:_OnCast(caster, target, pos)

    -- 广播特效事件给客户端
    if self.config.effect_event and (target or pos) then
        local tx, ty, tz
        if target and target.Transform then
            tx, ty, tz = target.Transform:GetWorldPosition()
        elseif pos then
            tx, ty, tz = pos.x, pos.y or 0, pos.z
        end
        local sx, sy, sz = caster.Transform:GetWorldPosition()
        caster:PushEvent(self.config.effect_event, {
            sx = sx, sy = sy + 1, sz = sz,
            tx = tx, ty = ty,     tz = tz,
        })
    end

    -- 启动冷却
    self:StartCooldown()
end

-- ============================================================
-- _OnCast（由子类重写）
-- ============================================================

--- 具体咒语效果的实现钩子，基类为空实现。
-- 子类必须重写此函数以实现咒语效果。
-- @param caster  entity
-- @param target  entity|nil
-- @param pos     Vector3|nil
function SpellBase:_OnCast(caster, target, pos)
    -- 子类实现
end

-- ============================================================
-- GetSanityMult
-- ============================================================

--- 根据施法者当前 sanity 计算伤害/治疗倍率。
-- 仅在 config.scales_with_sanity == true 时应由具体咒语调用。
-- @param caster  entity  施法者
-- @return        number  倍率（0.5 / 0.75 / 1.0）
function SpellBase:GetSanityMult(caster)
    if not self.config.scales_with_sanity then return 1.0 end

    local sanity = caster.components.sanity
    if not sanity then return TUNE.SANITY_MULT_HIGH end

    local current = sanity:GetPercent() * GLOBAL.TUNING.MAX_SANITY
    if current >= TUNE.SANITY_BREAKPOINT_HIGH then
        return TUNE.SANITY_MULT_HIGH
    elseif current >= TUNE.SANITY_BREAKPOINT_MID then
        return TUNE.SANITY_MULT_MID
    else
        return TUNE.SANITY_MULT_LOW
    end
end

-- ============================================================
-- StartCooldown
-- ============================================================

--- 启动冷却计时器，每秒递减 _cooldown_remaining。
function SpellBase:StartCooldown()
    self._cooldown_remaining = self.config.cooldown
    if self._cooldown_task then
        self._cooldown_task:Cancel()
    end
    -- 使用持有者的 DoPeriodicTask（需通过 inst 参数注入）
    -- 由于 SpellBase 不直接持有 inst，通过 _cooldown_owner 注入
    if self._cooldown_owner then
        self._cooldown_task = self._cooldown_owner:DoPeriodicTask(1, function()
            self._cooldown_remaining = math.max(0, self._cooldown_remaining - 1)
            if self._cooldown_remaining <= 0 then
                self._cooldown_task:Cancel()
                self._cooldown_task = nil
            end
        end)
    end
end

--- 注入 inst（任务宿主），由 spellcaster 组件在装备时调用。
-- @param inst  entity  负责运行 DoPeriodicTask 的实体（通常是魔杖或玩家）
function SpellBase:SetCooldownOwner(inst)
    self._cooldown_owner = inst
end

-- ============================================================
-- GetCooldownRemaining
-- ============================================================

--- 返回当前剩余冷却时间（秒）。
-- @return  number  剩余秒数，0 表示已就绪
function SpellBase:GetCooldownRemaining()
    return self._cooldown_remaining
end

return SpellBase

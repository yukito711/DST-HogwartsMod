-- hw_mana.lua
-- 组件名：hw_mana
-- 归属：Server（所有逻辑在服务端执行，通过 NetVar 同步给客户端）
-- 职责：管理玩家的 mana 值，包括上限、再生和消耗。

local TUNE = HWTUNE

-- ============================================================
-- 组件定义
-- ============================================================

local HwMana = Class(function(self, inst)
    self.inst = inst

    -- 内部状态
    self._max       = TUNE.MANA_BASE_MAX
    self._current   = TUNE.MANA_BASE_MAX
    self._in_combat = false
    self._regen_task = nil
    self._accum     = 0  -- 用于非整数回复的累计值

    -- 网络同步变量（客户端只读）
    -- 使用 0-1 百分比同步，减少带宽，客户端根据 max 还原显示值
    self._net_percent = net_float(inst.GUID, "hw_mana.percent", "hw_mana_dirty")
    self._net_max     = net_uint(inst.GUID,  "hw_mana.max",     "hw_mana_max_dirty")

    if not TheWorld.ismastersim then
        -- 客户端：监听网络变量变化，触发 UI 刷新
        inst:ListenForEvent("hw_mana_dirty",     function() inst:PushEvent("hw_mana_changed") end)
        inst:ListenForEvent("hw_mana_max_dirty", function() inst:PushEvent("hw_mana_changed") end)
        return
    end

    -- 服务端：监听战斗事件切换 regen 速率
    inst:ListenForEvent("attacked",     function() self:StartCombatRegen() end)
    inst:ListenForEvent("onattackother",function() self:StartCombatRegen() end)

    self:_StartRegenTask()
    self:_SyncNet()
end)

-- ============================================================
-- Initialize（与 Class 构造函数等价，供外部显式重置调用）
-- ============================================================

--- 将 mana 重置为满值，重启 regen。
-- 通常只在调试或玩家重生时调用。
function HwMana:Initialize()
    self._current = self._max
    self._accum   = 0
    self:_SyncNet()
    self:_StartRegenTask()
end

-- ============================================================
-- SetMax
-- ============================================================

--- 设置 mana 上限，并按比例调整当前值。
-- @param max  number  新的最大 mana（应为 TUNE.MANA_BASE_MAX 或 TUNE.MANA_UPGRADED_MAX）
function HwMana:SetMax(max)
    local pct = self._current / self._max
    self._max = max
    self._current = math.min(self._current, max)
    -- 可选：保持百分比，取决于设计
    -- self._current = math.floor(pct * max)
    self:_SyncNet()
    self.inst:PushEvent("hw_mana_maxchanged", {max = max})
end

-- ============================================================
-- DoDelta
-- ============================================================

--- 增加或减少 mana，结果夹在 [0, max]。
-- @param delta  number  正数为恢复，负数为消耗
function HwMana:DoDelta(delta)
    local before = self._current
    self._current = math.max(0, math.min(self._max, self._current + delta))
    if self._current ~= before then
        self:_SyncNet()
        self.inst:PushEvent("hw_mana_changed", {current = self._current, max = self._max})
    end
end

-- ============================================================
-- GetPercent
-- ============================================================

--- 返回当前 mana 占最大值的百分比（0.0 - 1.0）。
-- 客户端可通过 net_percent 读取，服务端用此函数。
-- @return  number  [0.0, 1.0]
function HwMana:GetPercent()
    return self._current / self._max
end

-- ============================================================
-- GetCurrent / GetMax
-- ============================================================

--- 返回当前 mana 绝对值。
-- @return  number
function HwMana:GetCurrent()
    return self._current
end

--- 返回最大 mana 绝对值。
-- @return  number
function HwMana:GetMax()
    return self._max
end

-- ============================================================
-- CanSpend
-- ============================================================

--- 检查是否有足够 mana 施放一个消耗 cost 的咒语。
-- @param cost  number  咒语 mana 消耗
-- @return      bool
function HwMana:CanSpend(cost)
    return self._current >= cost
end

-- ============================================================
-- StartCombatRegen / StopCombatRegen
-- ============================================================

--- 切换到战斗回复速率（0.3/s）。
-- 由攻击/被攻击事件触发，3秒无战斗后自动恢复。
function HwMana:StartCombatRegen()
    self._in_combat = true
    -- 3秒后恢复普通回复速率
    if self._combat_exit_task then
        self._combat_exit_task:Cancel()
    end
    self._combat_exit_task = self.inst:DoTaskInTime(3, function()
        self:StopCombatRegen()
    end)
end

--- 恢复站立回复速率（1.0/s）。
function HwMana:StopCombatRegen()
    self._in_combat = false
    self._combat_exit_task = nil
end

-- ============================================================
-- 内部：_DoRegen
-- ============================================================

--- 每 tick（TUNE.MANA_TICK_INTERVAL 秒）调用一次，执行 mana 回复。
-- @param dt  number  实际经过时间（秒），由 DoPeriodicTask 提供
function HwMana:_DoRegen(dt)
    if self._current >= self._max then return end

    local rate = self._in_combat and TUNE.MANA_REGEN_COMBAT or TUNE.MANA_REGEN_STANDING
    self._accum = self._accum + rate * dt
    if self._accum >= 1 then
        local gain = math.floor(self._accum)
        self._accum = self._accum - gain
        self:DoDelta(gain)
    end
end

-- ============================================================
-- 内部：_StartRegenTask
-- ============================================================

--- 启动周期性 regen 任务。若已存在则先取消再重建。
function HwMana:_StartRegenTask()
    if self._regen_task then
        self._regen_task:Cancel()
    end
    local interval = TUNE.MANA_TICK_INTERVAL
    self._regen_task = self.inst:DoPeriodicTask(interval, function()
        self:_DoRegen(interval)
    end)
end

-- ============================================================
-- 内部：_SyncNet
-- ============================================================

--- 将当前状态同步到网络变量，通知所有客户端。
function HwMana:_SyncNet()
    self._net_percent:set(self:GetPercent())
    self._net_max:set(self._max)
end

-- ============================================================
-- OnRemoveFromEntity
-- ============================================================

--- 组件被移除时清理任务，防止内存泄漏。
function HwMana:OnRemoveFromEntity()
    if self._regen_task then
        self._regen_task:Cancel()
        self._regen_task = nil
    end
    if self._combat_exit_task then
        self._combat_exit_task:Cancel()
        self._combat_exit_task = nil
    end
end

return HwMana

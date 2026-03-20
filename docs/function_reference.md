# DST-HogwartsMod 函数参考文档

> 版本：v0.1.0 | 对应代码分支：`claude/review-program-content-wCGok`
>
> **图例**：🟢 Server（仅服务端执行）| 🔵 Client（仅客户端执行）| 🟡 Both（双端均执行）

---

## 目录

1. [hw_data/hw_tuning.lua — 数值常量表](#1-hw_datahw_tuninglua)
2. [hw_data/hw_spells.lua — 咒语配置表](#2-hw_datahw_spellslua)
3. [components/hw_mana.lua — Mana 组件](#3-componentshw_manalua)
4. [spells/hw_spell_base.lua — 咒语基类](#4-spellshw_spell_baselua)
5. [spells/hw_incendio.lua — 燃烧咒](#5-spellshw_incendiolua)
6. [spells/hw_episkey.lua — 愈合咒](#6-spellshw_episkeylua)
7. [spells/hw_sectumsempra.lua — 割裂咒](#7-spellshw_sectumsempralua)
8. [prefabs/hw_magic_wand.lua — 魔杖 Prefab](#8-prefabshw_magic_wandlua)
9. [prefabs/hw_magic_workbench.lua — 魔法工作台 Prefab](#9-prefabshw_magic_workbenchlua)

---

## 1. `hw_data/hw_tuning.lua`

**类型**：纯数据文件，无函数，输出全局表 `HWTUNE`。

**用途**：集中管理所有数值常量，其他模块通过 `HWTUNE.<KEY>` 读取。禁止在其他文件硬编码数字。

**关键常量**：

| 常量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `MANA_BASE_MAX` | number | 100 | 初始最大 mana |
| `MANA_UPGRADED_MAX` | number | 200 | 升级后最大 mana |
| `MANA_REGEN_STANDING` | number | 1.0 | 站立时每秒 mana 回复量 |
| `MANA_REGEN_COMBAT` | number | 0.3 | 战斗中每秒 mana 回复量 |
| `MANA_TICK_INTERVAL` | number | 1.0 | Regen tick 间隔（秒） |
| `SANITY_THRESHOLD_STANDARD` | number | 50 | 普通咒语最低 sanity |
| `SANITY_THRESHOLD_UNFORGIVABLE` | number | 200 | 不可饶恕咒最低 sanity |
| `SANITY_MULT_HIGH` | number | 1.00 | sanity ≥ 150 时的效果倍率 |
| `SANITY_MULT_MID` | number | 0.75 | sanity 100-149 时的效果倍率 |
| `SANITY_MULT_LOW` | number | 0.50 | sanity 50-99 时的效果倍率 |
| `WAND_AFFINITY_MIN` | number | 0.5 | 魔杖亲和力最小值 |
| `WAND_AFFINITY_MAX` | number | 1.5 | 魔杖亲和力最大值 |

---

## 2. `hw_data/hw_spells.lua`

**类型**：纯数据文件，返回 `SpellDefs` 表（局部变量，通过 `require` 获取）。

**用途**：定义所有咒语的静态属性，咒语逻辑文件从此处读取配置。

**返回格式**：`table`，键为咒语 id，值为咒语配置表。

**每条配置的通用字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 咒语唯一标识符（snake_case） |
| `tier` | string | 等级：`"basic"` / `"intermediate"` / `"advanced"` |
| `type` | string | 类型：`"utility"` / `"attack"` / `"heal"` / `"control"` / `"dark"` |
| `mana_cost` | number | 施放消耗的 mana |
| `cooldown` | number | 冷却时间（秒） |
| `sanity_required` | number | 施放所需的最低 sanity 值 |
| `scales_with_sanity` | bool | 是否受 sanity 影响效果倍率 |
| `effect_event` | string | 服务端广播给客户端的特效事件名 |
| `range` | number | 施法范围（单位：游戏距离单位） |

---

## 3. `components/hw_mana.lua`

**组件名**：`hw_mana`
**挂载对象**：玩家实体（装备魔杖时由 `onequip` 添加）
**归属**：服务端逻辑 + NetVar 同步给客户端

---

### `HwMana:Initialize()` 🟢

**说明**：将 mana 重置为满值，重启 regen 任务。通常只在调试或玩家重生时显式调用（Class 构造时自动执行一次初始化）。

**参数**：无
**返回值**：无

---

### `HwMana:SetMax(max)` 🟢

**说明**：设置 mana 上限，当前值夹在新上限内，同步 NetVar。

| 参数 | 类型 | 说明 |
|------|------|------|
| `max` | number | 新的最大 mana，建议使用 `HWTUNE.MANA_BASE_MAX` 或 `HWTUNE.MANA_UPGRADED_MAX` |

**返回值**：无
**副作用**：触发 `hw_mana_maxchanged` 事件，推送 `{max}` 数据。

---

### `HwMana:DoDelta(delta)` 🟢

**说明**：增加或减少 mana，结果夹在 `[0, max]`。

| 参数 | 类型 | 说明 |
|------|------|------|
| `delta` | number | 正数为恢复，负数为消耗（如 `-10` 表示消耗 10 点） |

**返回值**：无
**副作用**：若值发生变化，触发 `hw_mana_changed` 事件（推送 `{current, max}`）并同步 NetVar。

---

### `HwMana:GetPercent()` 🟡

**说明**：返回当前 mana 占最大值的百分比，用于 UI 显示。

**参数**：无
**返回值**：`number`，范围 `[0.0, 1.0]`

---

### `HwMana:GetCurrent()` 🟡

**说明**：返回当前 mana 绝对值。

**参数**：无
**返回值**：`number`

---

### `HwMana:GetMax()` 🟡

**说明**：返回当前 mana 上限。

**参数**：无
**返回值**：`number`

---

### `HwMana:CanSpend(cost)` 🟢

**说明**：检查当前 mana 是否足够支付指定消耗。施法前必须调用此函数判断。

| 参数 | 类型 | 说明 |
|------|------|------|
| `cost` | number | 待消耗的 mana 量 |

**返回值**：`bool`，`true` 表示 mana 充足

---

### `HwMana:StartCombatRegen()` 🟢

**说明**：切换到战斗回复速率（`0.3/s`）。由攻击/被攻击事件自动触发，3 秒无战斗后自动调用 `StopCombatRegen`。

**参数**：无
**返回值**：无

---

### `HwMana:StopCombatRegen()` 🟢

**说明**：恢复站立回复速率（`1.0/s`）。

**参数**：无
**返回值**：无

---

### `HwMana:_DoRegen(dt)` 🟢（内部函数）

**说明**：由 `DoPeriodicTask` 每 tick 调用，按当前状态（战斗/非战斗）累计并执行 mana 回复。外部不应直接调用。

| 参数 | 类型 | 说明 |
|------|------|------|
| `dt` | number | 实际经过时间（秒），由 `DoPeriodicTask` 提供 |

**返回值**：无

---

### `HwMana:OnRemoveFromEntity()` 🟢（DST 生命周期钩子）

**说明**：组件被移除时自动调用，取消所有定时任务，防止内存泄漏。

**参数**：无
**返回值**：无

---

## 4. `spells/hw_spell_base.lua`

**类**：`SpellBase`（通过 `Class(SpellBase, ...)` 被各具体咒语继承）
**归属**：服务端逻辑（`CanCast`/`Cast` 必须在服务端调用）

---

### `SpellBase.New(config)` 🟢

**说明**：工厂函数，从 `hw_spells.lua` 配置表构建咒语对象。具体咒语通过 `Class(SpellBase, ...)` 继承，一般不直接调用此函数。

| 参数 | 类型 | 说明 |
|------|------|------|
| `config` | table | `hw_spells.lua` 中的单条咒语定义 |

**返回值**：`SpellBase` 实例

---

### `SpellBase:CanCast(caster)` 🟢

**说明**：检查施法者是否满足施放此咒语的全部前提条件：① 冷却归零，② mana 充足，③ sanity 达到阈值。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者（通常是玩家实体） |

**返回值**：`bool`，`true` 表示可以施放

---

### `SpellBase:Cast(caster, target, pos)` 🟢

**说明**：执行施法完整流程：① 扣除 mana，② 调用 `_OnCast`（子类实现），③ 广播特效事件给客户端，④ 启动冷却。

**调用前提**：必须先通过 `CanCast` 检查。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者 |
| `target` | entity \| nil | 目标实体，点击怪物时有值 |
| `pos` | Vector3 \| nil | 目标位置，点击地面时有值；`target` 优先 |

**返回值**：无
**副作用**：触发 `config.effect_event` 网络事件（推送 `{sx,sy,sz,tx,ty,tz}`）。

---

### `SpellBase:_OnCast(caster, target, pos)` 🟢（子类重写钩子）

**说明**：具体咒语效果的实现入口。基类为空实现，子类必须重写。由 `Cast` 内部调用，外部不应直接调用。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者 |
| `target` | entity \| nil | 目标实体 |
| `pos` | Vector3 \| nil | 目标位置 |

**返回值**：无

---

### `SpellBase:GetSanityMult(caster)` 🟢

**说明**：根据施法者当前 sanity 计算效果倍率。仅在 `config.scales_with_sanity == true` 的咒语中调用。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者 |

**返回值**：`number`

| 施法者 sanity | 返回值 |
|--------------|--------|
| ≥ 150 | 1.00 |
| 100 – 149 | 0.75 |
| 50 – 99 | 0.50 |

---

### `SpellBase:StartCooldown()` 🟢

**说明**：启动冷却计时器，将 `_cooldown_remaining` 设为 `config.cooldown`，每秒递减直至归零。

**参数**：无
**返回值**：无
**前提**：需先调用 `SetCooldownOwner` 提供任务宿主。

---

### `SpellBase:SetCooldownOwner(inst)` 🟢

**说明**：注入负责运行 `DoPeriodicTask` 的实体（通常是持有魔杖的玩家）。由魔杖 `onequip` 调用。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 任务宿主实体 |

**返回值**：无

---

### `SpellBase:GetCooldownRemaining()` 🟡

**说明**：返回当前咒语的剩余冷却时间（秒），用于 UI 冷却条显示。

**参数**：无
**返回值**：`number`，0 表示已就绪

---

## 5. `spells/hw_incendio.lua`

**类**：`Incendio`（继承 `SpellBase`）
**配置**：来自 `hw_spells.lua` → `SpellDefs.incendio`

---

### `Incendio:_OnCast(caster, target, pos)` 🟢

**说明**：燃烧咒效果。优先点燃目标实体（`burnable` 组件），目标不可燃则在位置生成 `fire` prefab。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者 |
| `target` | entity \| nil | 目标实体 |
| `pos` | Vector3 \| nil | 目标地面位置（target 为 nil 时使用） |

**返回值**：无

---

### `Incendio:_SpawnFire(x, y, z, duration)` 🟢（内部函数）

**说明**：在指定位置生成 `fire` prefab，持续 `duration` 秒后自动移除。

| 参数 | 类型 | 说明 |
|------|------|------|
| `x, y, z` | number | 世界坐标 |
| `duration` | number | 存在时长（秒） |

**返回值**：无

---

### `Incendio.OnClientFX(inst, data)` 🔵

**说明**：客户端收到 `hw_fx_incendio` 事件后调用，播放橙色飞行光球 + 落点爆炸特效。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `data` | table | `{sx, sy, sz, tx, ty, tz}`：起点和终点坐标 |

**返回值**：无

---

## 6. `spells/hw_episkey.lua`

**类**：`Episkey`（继承 `SpellBase`）
**配置**：来自 `hw_spells.lua` → `SpellDefs.episkey`

---

### `Episkey:_OnCast(caster, target, pos)` 🟢

**说明**：愈合咒效果。立即治疗目标（或自身），再启动 HoT 定时任务。治疗量 × `sanity_mult`。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者 |
| `target` | entity \| nil | 治疗目标（为 nil 时治疗自身） |
| `pos` | Vector3 \| nil | 未使用 |

**返回值**：无

---

### `Episkey:_ApplyHeal(target, amount)` 🟢（内部函数）

**说明**：对目标 `health` 组件执行一次治疗，`amount` 已包含 `sanity_mult` 缩放。

| 参数 | 类型 | 说明 |
|------|------|------|
| `target` | entity | 治疗目标（需有 `health` 组件） |
| `amount` | number | 治疗量（已乘 sanity_mult） |

**返回值**：无

---

### `Episkey.OnClientFX(inst, data)` 🔵

**说明**：客户端收到 `hw_fx_episkey` 事件后调用，在目标位置播放 `heal_fx` 愈合光效。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `data` | table | `{sx, sy, sz, tx, ty, tz}` |

**返回值**：无

---

## 7. `spells/hw_sectumsempra.lua`

**类**：`Sectumsempra`（继承 `SpellBase`）
**配置**：来自 `hw_spells.lua` → `SpellDefs.sectumsempra`

---

### `Sectumsempra:_OnCast(caster, target, pos)` 🟢

**说明**：割裂咒效果。对目标造成即时伤害，再启动流血 DoT 定时任务。伤害量 × `sanity_mult`。

| 参数 | 类型 | 说明 |
|------|------|------|
| `caster` | entity | 施法者 |
| `target` | entity \| nil | 攻击目标（需有 `health` 组件，为 nil 时直接返回） |
| `pos` | Vector3 \| nil | 未使用 |

**返回值**：无

---

### `Sectumsempra:_ApplyDamage(target, attacker, amount)` 🟢（内部函数）

**说明**：对目标造成伤害，并标记攻击来源以触发原版仇恨/击杀归属系统。

| 参数 | 类型 | 说明 |
|------|------|------|
| `target` | entity | 被攻击目标 |
| `attacker` | entity | 攻击来源（玩家），用于仇恨归属 |
| `amount` | number | 伤害量（已乘 sanity_mult） |

**返回值**：无

---

### `Sectumsempra.OnClientFX(inst, data)` 🔵

**说明**：客户端收到 `hw_fx_sectumsempra` 事件后调用，播放红色飞行光球特效（后续替换为专属光束）。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `data` | table | `{sx, sy, sz, tx, ty, tz}` |

**返回值**：无

---

## 8. `prefabs/hw_magic_wand.lua`

**Prefab 名**：`hw_magic_wand`

---

### `GenerateAffinity(inst, owner)` 🟢

**说明**：为持有者生成唯一亲和力值（`0.5 – 1.5`），以 `userid + inst.GUID` 为随机种子，同一玩家对同一把魔杖的亲和力保持不变。亲和力仅影响攻击/治疗类咒语效果，不影响实用/不可饶恕咒。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `owner` | entity | 装备者（玩家） |

**返回值**：`number`，亲和力值（保留两位小数）
**副作用**：设置 `inst._affinity` 和 `inst._affinity_owner`。

---

### `onequip(inst, owner)` 🟡

**说明**：装备时触发。切换持握动画（双端），服务端生成/恢复亲和力、为持有者添加 `hw_mana` 组件、设置咒语冷却宿主。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `owner` | entity | 装备者 |

**返回值**：无

---

### `onunequip(inst, owner)` 🟡

**说明**：卸下时触发。恢复正常动画（双端），服务端停止 mana 战斗回复计时。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `owner` | entity | 卸下者 |

**返回值**：无

---

### `onattack(inst, attacker, target)` 🟢

**说明**：攻击命中时触发（服务端）。检查 mana 是否充足，消耗 mana，根据亲和力和 sanity_mult 动态修正 `weapon` 组件伤害值，广播飞行特效事件。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 魔杖实体 |
| `attacker` | entity | 攻击者（玩家） |
| `target` | entity | 攻击目标 |

**返回值**：无
**副作用**：触发 `hw_wand_fire` 事件（推送 `{sx,sy,sz,tx,ty,tz}`）。

---

### `fn()` 🟡

**说明**：Prefab 工厂函数，由 DST 引擎在 `SpawnPrefab("hw_magic_wand")` 时调用。创建实体，双端注册监听器，服务端挂载所有组件。

**参数**：无
**返回值**：`entity`，魔杖实体

---

## 9. `prefabs/hw_magic_workbench.lua`

**Prefab 名**：`hw_magic_workbench`

---

### `onhammered(inst, worker)` 🟢

**说明**：工作台被锤子拆除完成时触发。掉落战利品，播放 `collapse_small` 拆除特效，移除实体。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 工作台实体 |
| `worker` | entity | 执行拆除的玩家 |

**返回值**：无

---

### `onwork(inst, worker, workleft)` 🟢

**说明**：每次锤击时触发（工作进度回调）。当前为空实现，可扩展为震动动画或音效。

| 参数 | 类型 | 说明 |
|------|------|------|
| `inst` | entity | 工作台实体 |
| `worker` | entity | 操作玩家 |
| `workleft` | number | 剩余工作量 |

**返回值**：无

---

### `fn()` 🟡

**说明**：Prefab 工厂函数。创建工作台实体，双端设置动画和小地图图标，服务端挂载 `health`/`workable`/`lootdropper`/`prototyper` 组件，使其成为 `TECH.MAGIC_ONE` 的解锁源。

**参数**：无
**返回值**：`entity`，工作台实体

---

## 附录：Client/Server 事件对照表

| 事件名 | 触发方（Server） | 监听方（Client） | 数据格式 |
|--------|----------------|----------------|---------|
| `hw_wand_fire` | `onattack` | `hw_magic_wand.lua` | `{sx,sy,sz,tx,ty,tz}` |
| `hw_fx_incendio` | `SpellBase:Cast` | `Incendio.OnClientFX` | `{sx,sy,sz,tx,ty,tz}` |
| `hw_fx_episkey` | `SpellBase:Cast` | `Episkey.OnClientFX` | `{sx,sy,sz,tx,ty,tz}` |
| `hw_fx_sectumsempra` | `SpellBase:Cast` | `Sectumsempra.OnClientFX` | `{sx,sy,sz,tx,ty,tz}` |
| `hw_mana_changed` | `HwMana:DoDelta` | UI 层（待实现） | `{current, max}` |
| `hw_mana_maxchanged` | `HwMana:SetMax` | UI 层（待实现） | `{max}` |

---

## 附录：数据流示意

```
玩家按攻击键
    │
    ▼ (Client 预测动画)
    weapon 组件触发 combat 系统
    │
    ▼ (Server)
onattack(inst, attacker, target)
    ├─ hw_mana:CanSpend() → false → 中止
    └─ hw_mana:DoDelta(-cost)
       hw_mana:StartCombatRegen()
       weapon:SetDamage(base * affinity * sanity_mult)
       PushEvent("hw_wand_fire", {...})
           │
           ▼ (Client)
       MagicEffects.WandShoot(...)  ← 播放飞行光球特效
```

-- hw_spells.lua
-- 所有咒语的定义配置表。
-- 咒语逻辑文件（scripts/spells/）从此处读取配置，不硬编码参数。
-- 新增咒语只需在此添加条目，无需修改核心逻辑文件。

local TUNE = HWTUNE  -- hw_tuning.lua 已在 modmain 中全局加载

local SpellDefs = {

    -- ---------------------------------------------------------
    -- Incendio：燃烧咒
    -- 类型：实用/攻击
    -- 效果：点燃目标或地面，不消耗 sanity，但需 sanity > 50
    -- ---------------------------------------------------------
    incendio = {
        id              = "incendio",
        tier            = "basic",              -- basic / intermediate / advanced
        type            = "utility",
        mana_cost       = TUNE.INCENDIO_MANA_COST,
        cooldown        = TUNE.INCENDIO_COOLDOWN,
        sanity_required = TUNE.SANITY_THRESHOLD_STANDARD,
        scales_with_sanity = false,             -- 实用咒不随sanity缩放
        fire_duration   = TUNE.INCENDIO_FIRE_DURATION,
        range           = 8,
        effect_event    = "hw_fx_incendio",     -- 服务端广播给客户端的事件名
    },

    -- ---------------------------------------------------------
    -- Episkey：愈合咒
    -- 类型：治疗
    -- 效果：立即恢复 HP + HoT（每秒，共5次）
    --       治疗量随 sanity 缩放
    -- ---------------------------------------------------------
    episkey = {
        id              = "episkey",
        tier            = "basic",
        type            = "heal",
        mana_cost       = TUNE.EPISKEY_MANA_COST,
        cooldown        = TUNE.EPISKEY_COOLDOWN,
        sanity_required = TUNE.SANITY_THRESHOLD_STANDARD,
        scales_with_sanity = true,
        instant_heal    = TUNE.EPISKEY_INSTANT_HEAL,
        hot_heal        = TUNE.EPISKEY_HOT_HEAL,
        hot_ticks       = TUNE.EPISKEY_HOT_TICKS,
        hot_interval    = TUNE.EPISKEY_HOT_INTERVAL,
        range           = 6,
        effect_event    = "hw_fx_episkey",
    },

    -- ---------------------------------------------------------
    -- Sectumsempra：割裂咒
    -- 类型：攻击
    -- 效果：即时伤害 + 流血 DoT（每2秒，共3次）
    --       伤害随 sanity 缩放
    -- ---------------------------------------------------------
    sectumsempra = {
        id              = "sectumsempra",
        tier            = "intermediate",
        type            = "attack",
        mana_cost       = TUNE.SECTUMSEMPRA_MANA_COST,
        cooldown        = TUNE.SECTUMSEMPRA_COOLDOWN,
        sanity_required = TUNE.SANITY_THRESHOLD_STANDARD,
        scales_with_sanity = true,
        damage          = TUNE.SECTUMSEMPRA_DAMAGE,
        dot_damage      = TUNE.SECTUMSEMPRA_DOT_DAMAGE,
        dot_ticks       = TUNE.SECTUMSEMPRA_DOT_TICKS,
        dot_interval    = TUNE.SECTUMSEMPRA_DOT_INTERVAL,
        range           = 10,
        effect_event    = "hw_fx_sectumsempra",
    },
}

return SpellDefs

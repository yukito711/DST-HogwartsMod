-- hw_tuning.lua
-- 全局数值常量表，所有模块从此处读取，禁止在其他文件硬编码数字。
-- 修改此文件即可完成全局平衡调整。

HWTUNE = {
    -- =========================================================
    -- Mana 系统
    -- =========================================================
    MANA_BASE_MAX           = 100,      -- 初始最大mana
    MANA_UPGRADED_MAX       = 200,      -- 升级后最大mana
    MANA_REGEN_STANDING     = 1.0,      -- 站立时每秒回复量
    MANA_REGEN_COMBAT       = 0.3,      -- 战斗中每秒回复量
    MANA_TICK_INTERVAL      = 1.0,      -- regen tick 间隔（秒）

    -- =========================================================
    -- Sanity 施法阈值
    -- =========================================================
    SANITY_THRESHOLD_STANDARD   = 50,   -- 普通咒语最低sanity要求
    SANITY_THRESHOLD_UNFORGIVABLE = 200, -- 不可饶恕咒最低sanity要求

    -- Sanity 影响的伤害/治疗倍率区间
    SANITY_MULT_HIGH        = 1.00,     -- sanity >= 150
    SANITY_MULT_MID         = 0.75,     -- sanity 100-149
    SANITY_MULT_LOW         = 0.50,     -- sanity 50-99

    SANITY_BREAKPOINT_HIGH  = 150,
    SANITY_BREAKPOINT_MID   = 100,

    -- =========================================================
    -- 魔杖亲和力
    -- =========================================================
    WAND_AFFINITY_MIN       = 0.5,
    WAND_AFFINITY_MAX       = 1.5,

    -- =========================================================
    -- 咒语：Incendio（燃烧咒）
    -- =========================================================
    INCENDIO_MANA_COST      = 10,
    INCENDIO_COOLDOWN       = 5.0,      -- 秒
    INCENDIO_FIRE_DURATION  = 4.0,      -- 目标燃烧持续秒数

    -- =========================================================
    -- 咒语：Episkey（愈合咒）
    -- =========================================================
    EPISKEY_MANA_COST       = 20,
    EPISKEY_COOLDOWN        = 8.0,
    EPISKEY_INSTANT_HEAL    = 40,       -- 立即恢复HP
    EPISKEY_HOT_HEAL        = 10,       -- 每次HoT治疗量
    EPISKEY_HOT_TICKS       = 5,        -- HoT次数
    EPISKEY_HOT_INTERVAL    = 1.0,      -- HoT间隔（秒）

    -- =========================================================
    -- 咒语：Sectumsempra（割裂咒）
    -- =========================================================
    SECTUMSEMPRA_MANA_COST  = 25,
    SECTUMSEMPRA_COOLDOWN   = 10.0,
    SECTUMSEMPRA_DAMAGE     = 60,       -- 即时伤害（乘sanity_mult）
    SECTUMSEMPRA_DOT_DAMAGE = 15,       -- 每次DoT伤害
    SECTUMSEMPRA_DOT_TICKS  = 3,        -- DoT次数
    SECTUMSEMPRA_DOT_INTERVAL = 2.0,    -- DoT间隔（秒）

    -- =========================================================
    -- 魔法工作台
    -- =========================================================
    WORKBENCH_HEALTH        = 200,      -- 工作台耐久
}

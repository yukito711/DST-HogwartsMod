-- magic_effects.lua
-- 魔法特效统一管理库
-- 所有魔杖和魔法物品的特效都在此文件扩展

local MagicEffects = {}

-- 飞行光球
-- 用 fireball_projectile 作为飞行体，分步移动模拟飞行
-- 参数：起点(sx,sy,sz) 终点(tx,ty,tz) color(保留参数备用) onfinish(到达终点回调)
function MagicEffects.FlyBall(sx, sy, sz, tx, ty, tz, color, onfinish)
    local fx = SpawnPrefab("fireball_projectile")
    if not fx then return end
    
    fx.Transform:SetPosition(sx, sy, sz)

    local steps = 12
    local dx = (tx - sx) / steps
    local dz = (tz - sz) / steps

    for i = 1, steps do
        local step = i
        fx:DoTaskInTime(i * 0.02, function()
            if fx and fx:IsValid() then
                fx.Transform:SetPosition(sx + dx * step, sy, sz + dz * step)
                if step == steps then
                    if onfinish then onfinish(tx, ty, tz) end
                    fx:Remove()
                end
            end
        end)
    end
end

-- 命中爆炸特效
-- 使用 explode_small，客户端可见
function MagicEffects.HitExplosion(tx, ty, tz)
    local hit = SpawnPrefab("explode_small")
    if hit then
        hit.Transform:SetPosition(tx, ty + 1, tz)
    end
end

-- 魔杖标准发射：飞行光球 + 命中爆炸
-- 后续新魔杖可调用此函数，或自定义color参数区分效果
function MagicEffects.WandShoot(sx, sy, sz, tx, ty, tz, color)
    MagicEffects.FlyBall(sx, sy, sz, tx, ty, tz, color, function(x, y, z)
        MagicEffects.HitExplosion(x, y, z)
    end)
end

return MagicEffects
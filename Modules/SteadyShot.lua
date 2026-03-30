local function getBaseSteadyCastTime()
    return HunterLib.GetConfigValue("steady", "castTime") or 1.40
end

local function getSafetyMargin()
    return HunterLib.GetConfigValue("steady", "safetyMargin") or 0.40
end

local function getEffectiveSteadyCastTime()
    local base = getBaseSteadyCastTime()
    local mod = 1.0

    if HunterLib.GetActiveHasteModifier then
        mod = HunterLib.GetActiveHasteModifier()
    end

    return base * mod
end

local function getRequiredWindow()
    return getEffectiveSteadyCastTime() + getSafetyMargin()
end

local function getPossibleSteadies(reloadRemaining)
    local room = reloadRemaining - getSafetyMargin()
    local cast = getEffectiveSteadyCastTime()

    if room <= 0 or cast <= 0 then
        return 0
    end

    return math.floor(room / cast)
end

function HunterLib.GetSteadyCastTime()
    return getEffectiveSteadyCastTime()
end

function HunterLib.GetSteadyPossibleCasts()
    if not HunterLib.Auto.isReloading then
        return 0
    end

    return getPossibleSteadies(HunterLib.GetReloadRemaining())
end

function HunterLib.CanSteadyShot()
    if HunterLib.Auto.isCasting then
        return nil
    end
    if not HunterLib.Auto.isShooting then
        return nil
    end
    if not HunterLib.Auto.isReloading then
        return nil
    end

    local reloadRem = HunterLib.GetReloadRemaining()
    local need = getRequiredWindow()

    return reloadRem > (need + HunterLib.Const.RELOAD_GUARD)
end

function HunterLib.CastNoClip(spell)
    if HunterLib.CanSteadyShot() then
        local castTime = getEffectiveSteadyCastTime()
        HunterLib.StartCast(spell, castTime + 0.75)
        CastSpellByName(spell)
    end
end

function Hunter_SteadyShot()
    if not UnitExists("target") or UnitIsDead("target") then
        return
    end

    if HunterLib.Auto.isCasting then
        HunterLib.Debug("WAIT casting")
        return
    end

    if not HunterLib.Auto.isShooting then
        HunterLib.Debug("WAIT no auto")
        return
    end

    if not HunterLib.Auto.isReloading then
        HunterLib.Debug("WAIT no reload")
        return
    end

    local reloadRem = HunterLib.GetReloadRemaining()
    local steady = getEffectiveSteadyCastTime()
    local margin = getSafetyMargin()
    local need = getRequiredWindow()
    local possible = getPossibleSteadies(reloadRem)

    HunterLib.Debug(string.format(
        "reload=%.2f need=%.2f steady=%.2f margin=%.2f possible=%d",
        reloadRem,
        need,
        steady,
        margin,
        possible
    ))

    if reloadRem > (need + HunterLib.Const.RELOAD_GUARD) then
        HunterLib.Debug("CAST steady")
        HunterLib.StartCast("Steady Shot", steady + 0.75)
        CastSpellByName("Steady Shot")
    else
        HunterLib.Debug("WAIT")
    end
end

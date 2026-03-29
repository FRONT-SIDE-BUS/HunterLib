local RELOAD_GUARD = 0.05

local function HL_GetBaseSteadyCastTime()
  if HunterLibDB and HunterLibDB.steadyCastTime then
    return HunterLibDB.steadyCastTime
  end
  return 1.40
end

local function HL_GetSafetyMargin()
  if HunterLibDB and HunterLibDB.steadySafetyMargin then
    return HunterLibDB.steadySafetyMargin
  end
  return 0.40
end

local function HL_GetEffectiveSteadyCastTime()
  local base = HL_GetBaseSteadyCastTime()
  local mod = 1.0

  if HunterLib.GetActiveHasteModifier then
    mod = HunterLib.GetActiveHasteModifier()
  end

  return base * mod
end

local function HL_GetRequiredWindow()
  return HL_GetEffectiveSteadyCastTime() + HL_GetSafetyMargin()
end

local function HL_GetPossibleSteadies(reloadRemaining)
  local room = reloadRemaining - HL_GetSafetyMargin()
  local cast = HL_GetEffectiveSteadyCastTime()

  if room <= 0 or cast <= 0 then
    return 0
  end

  return math.floor(room / cast)
end

function HunterLib.GetSteadyCastTime()
  return HL_GetEffectiveSteadyCastTime()
end

function HunterLib.GetSteadyPossibleCasts()
  if not HunterLib.Auto.isReloading then
    return 0
  end

  return HL_GetPossibleSteadies(HunterLib.GetReloadRemaining())
end

function HunterLib.CanSteadyShot()
  if HunterLib.Auto.isCasting then return nil end
  if not HunterLib.Auto.isShooting then return nil end
  if not HunterLib.Auto.isReloading then return nil end

  local reloadRem = HunterLib.GetReloadRemaining()
  local need = HL_GetRequiredWindow()

  return reloadRem > (need + RELOAD_GUARD)
end

function HunterLib.CastNoClip(spell)
  if HunterLib.CanSteadyShot() then
    local castTime = HL_GetEffectiveSteadyCastTime()
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
  local steady = HL_GetEffectiveSteadyCastTime()
  local margin = HL_GetSafetyMargin()
  local need = HL_GetRequiredWindow()
  local possible = HL_GetPossibleSteadies(reloadRem)

  HunterLib.Debug(string.format(
    "reload=%.2f need=%.2f steady=%.2f margin=%.2f possible=%d",
    reloadRem, need, steady, margin, possible
  ))

  if reloadRem > (need + RELOAD_GUARD) then
    HunterLib.Debug("CAST steady")
    HunterLib.StartCast("Steady Shot", steady + 0.75)
    CastSpellByName("Steady Shot")
  else
    HunterLib.Debug("WAIT")
  end
end
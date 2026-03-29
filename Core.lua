HunterLib = {}

HunterLib.Auto = {
  isShooting = false,
  isReloading = false,
  isCasting = false,
  currentCast = nil,
  castStart = 0,
  castTimeout = 0,
  reloadStart = 0,
  reloadDuration = 0,
  debug = true
}

HunterLib.SpeedWatch = {
  lastRangedSpeed = nil
}

function HunterLib.Debug(msg)
  if HunterLib.Auto.debug then
    DEFAULT_CHAT_FRAME:AddMessage("HL: "..msg)
  end
end

function HunterLib.GetRangedSpeed()
  local speed = UnitRangedDamage("player")
  if speed and speed > 0 then
    return speed
  end
  return 2.0
end

function HunterLib.StartAuto()
  HunterLib.Auto.isShooting = true
end

function HunterLib.StopAuto()
  HunterLib.Auto.isShooting = false
  HunterLib.Auto.isReloading = false
end

function HunterLib.StartReload()
  local speed = HunterLib.GetRangedSpeed()
  local reload = speed - 0.5

  if reload < 0 then
    reload = 0
  end

  HunterLib.Auto.reloadStart = GetTime()
  HunterLib.Auto.reloadDuration = reload
  HunterLib.Auto.isReloading = true

  HunterLib.Debug("reload start "..string.format("%.2f", reload))
end

function HunterLib.GetReloadRemaining()
  if not HunterLib.Auto.isReloading then
    return 0
  end

  return HunterLib.Auto.reloadDuration - (GetTime() - HunterLib.Auto.reloadStart)
end

function HunterLib.StartCast(spell, timeout)
  HunterLib.Auto.isCasting = true
  HunterLib.Auto.currentCast = spell
  HunterLib.Auto.castStart = GetTime()
  HunterLib.Auto.castTimeout = timeout or 2.0
end

function HunterLib.StopCast()
  HunterLib.Auto.isCasting = false
  HunterLib.Auto.currentCast = nil
  HunterLib.Auto.castStart = 0
  HunterLib.Auto.castTimeout = 0
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("START_AUTOREPEAT_SPELL")
f:RegisterEvent("STOP_AUTOREPEAT_SPELL")
f:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
f:RegisterEvent("SPELLCAST_STOP")
f:RegisterEvent("SPELLCAST_FAILED")
f:RegisterEvent("SPELLCAST_INTERRUPTED")
f:RegisterEvent("UNIT_RANGEDDAMAGE")

f:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    HunterLib.Auto.isShooting = false
    HunterLib.Auto.isReloading = false
    HunterLib.StopCast()
    HunterLib.SpeedWatch.lastRangedSpeed = HunterLib.GetRangedSpeed()
    return
  end

  if event == "START_AUTOREPEAT_SPELL" then
    HunterLib.Debug("auto ON")
    HunterLib.StartAuto()
    return
  end

  if event == "STOP_AUTOREPEAT_SPELL" then
    HunterLib.Debug("auto OFF")
    HunterLib.StopAuto()
    return
  end

  if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
    if arg1 and string.find(arg1, "Auto Shot") then
      HunterLib.Debug("AUTO FIRED")
      HunterLib.StartReload()
      return
    end

    -- If Turtle logs Steady Shot damage here, this safely clears stale cast state.
    if arg1 and string.find(arg1, "Steady Shot") then
      HunterLib.Debug("steady impact")
      HunterLib.StopCast()
      return
    end
  end

  if event == "SPELLCAST_STOP" then
    HunterLib.Debug("cast end")
    HunterLib.StopCast()
    return
  end

  if event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
    HunterLib.Debug("cast fail")
    HunterLib.StopCast()
    return
  end

  if event == "UNIT_RANGEDDAMAGE" then
    if arg1 == "player" then
      local current = HunterLib.GetRangedSpeed()
      local last = HunterLib.SpeedWatch.lastRangedSpeed

      if last and math.abs(current - last) > 0.01 then
        HunterLib.Debug("ranged speed changed "..string.format("%.2f", last).." -> "..string.format("%.2f", current))

        if HunterLib.MarkCurrentBuffsAsCandidates then
          HunterLib.MarkCurrentBuffsAsCandidates()
        end
      end

      HunterLib.SpeedWatch.lastRangedSpeed = current
    end
    return
  end
end)

f:SetScript("OnUpdate", function()
  if HunterLib.Auto.isReloading and HunterLib.GetReloadRemaining() <= 0 then
    HunterLib.Auto.isReloading = nil
    HunterLib.Debug("reload done")
  end

  -- Cast watchdog: clears stale casting state if events fail.
  if HunterLib.Auto.isCasting and HunterLib.Auto.castStart and HunterLib.Auto.castTimeout then
    if (GetTime() - HunterLib.Auto.castStart) > HunterLib.Auto.castTimeout then
      HunterLib.Debug("cast timeout reset")
      HunterLib.StopCast()
    end
  end
end)
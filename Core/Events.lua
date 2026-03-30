local frame = CreateFrame("Frame")
HunterLib.EventFrame = frame

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
    local reload = speed - HunterLib.Const.RELOAD_OFFSET
    if reload < 0 then
        reload = 0
    end

    HunterLib.Auto.reloadStart = GetTime()
    HunterLib.Auto.reloadDuration = reload
    HunterLib.Auto.isReloading = true
    HunterLib.Debug("reload start " .. string.format("%.2f", reload))
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

local function onPlayerEnteringWorld()
    HunterLib.Auto.isShooting = false
    HunterLib.Auto.isReloading = false
    HunterLib.StopCast()
    HunterLib.SpeedWatch.lastRangedSpeed = HunterLib.GetRangedSpeed()
    HunterLib.GetDB()
    if HunterLib.BuffTrackerInit then
        HunterLib.BuffTrackerInit()
    end
    if HunterLib.UI.InitMinimapButton then
        HunterLib.UI.InitMinimapButton()
    end
end

local function onChatMsgSpellSelfDamage()
    if arg1 and string.find(arg1, "Auto Shot") then
        HunterLib.Debug("auto fired")
        HunterLib.StartReload()
        return
    end

    if arg1 and string.find(arg1, "Steady Shot") then
        HunterLib.Debug("steady impact")
        HunterLib.StopCast()
        return
    end
end

local function onRangedDamageChanged()
    if arg1 ~= "player" then
        return
    end

    local current = HunterLib.GetRangedSpeed()
    local last = HunterLib.SpeedWatch.lastRangedSpeed

    if last and math.abs(current - last) > 0.01 then
        HunterLib.Debug("ranged speed changed " .. string.format("%.2f", last) .. " -> " .. string.format("%.2f", current))
        if HunterLib.UI.RefreshBuffsTab then
            HunterLib.UI.RefreshBuffsTab()
        end
    end

    HunterLib.SpeedWatch.lastRangedSpeed = current
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("START_AUTOREPEAT_SPELL")
frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_FAILED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("UNIT_RANGEDDAMAGE")

frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        onPlayerEnteringWorld()
    elseif event == "START_AUTOREPEAT_SPELL" then
        HunterLib.Debug("auto ON")
        HunterLib.StartAuto()
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        HunterLib.Debug("auto OFF")
        HunterLib.StopAuto()
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        onChatMsgSpellSelfDamage()
    elseif event == "SPELLCAST_STOP" then
        HunterLib.Debug("cast end")
        HunterLib.StopCast()
    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        HunterLib.Debug("cast fail")
        HunterLib.StopCast()
    elseif event == "UNIT_RANGEDDAMAGE" then
        onRangedDamageChanged()
    end
end)

frame:SetScript("OnUpdate", function()
    if HunterLib.Auto.isReloading and HunterLib.GetReloadRemaining() <= 0 then
        HunterLib.Auto.isReloading = false
        HunterLib.Debug("reload done")
    end

    if HunterLib.Auto.isCasting and HunterLib.Auto.castStart and HunterLib.Auto.castTimeout then
        if (GetTime() - HunterLib.Auto.castStart) > HunterLib.Auto.castTimeout then
            HunterLib.Debug("cast timeout reset")
            HunterLib.StopCast()
        end
    end
end)

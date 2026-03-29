local HAWK_TEXTURE = "Interface\\Icons\\Spell_Nature_RavenForm"
local MARK_TEXTURE = "Interface\\Icons\\Ability_Hunter_SniperShot"

local function Hunter_HasPlayerBuff(texture)
    local i
    for i = 1, 16 do
        local t = UnitBuff("player", i)
        if t == texture then
            return 1
        end
    end
    return nil
end

local function Hunter_TargetHasDebuffTexture(texture)
    if not UnitExists("target") or UnitIsDead("target") then
        return nil
    end

    local i
    for i = 1, 16 do
        local t = UnitDebuff("target", i)
        if t == texture then
            return 1
        end
    end

    return nil
end

function Hunter_AspectHawk()
    if not Hunter_HasPlayerBuff(HAWK_TEXTURE) then
        HunterLib.Debug("aspect hawk")
        CastSpellByName("Aspect of the Hawk")
    end
end

function Hunter_HuntersMark()
    if not UnitExists("target") or UnitIsDead("target") then
        return
    end

    if not UnitCanAttack("player", "target") then
        return
    end

    if not Hunter_TargetHasDebuffTexture(MARK_TEXTURE) then
        HunterLib.Debug("hunter's mark")
        CastSpellByName("Hunter's Mark")
    end
end

function Hunter_MarkSetup()
    Hunter_AspectHawk()
    Hunter_HuntersMark()
end
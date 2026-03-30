local HAWK_TEXTURE = "Interface\\Icons\\Spell_Nature_RavenForm"
local MARK_TEXTURE = "Interface\\Icons\\Ability_Hunter_SniperShot"

function Hunter_MarkAndHawk()
    if not HunterLib.Util.PlayerHasBuffTexture(HAWK_TEXTURE) then
        CastSpellByName("Aspect of the Hawk")
        return
    end

    if not HunterLib.Util.TargetHasDebuffTexture(MARK_TEXTURE) then
        if UnitExists("target") and not UnitIsDead("target") then
            CastSpellByName("Hunter's Mark")
        end
    end
end

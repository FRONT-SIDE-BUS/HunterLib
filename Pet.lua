-- Smart pet attack
-- PvP: only send pet if it is not already attacking a player
-- PvE: only send pet if target is not already targeting the pet

function Hunter_PetAttack()
    if not UnitExists("target") or not UnitExists("pet") or UnitIsDead("target") then
        return
    end

    local isPlayerTarget = UnitIsPlayer("target")

    if isPlayerTarget then
        local petOnPlayer = UnitExists("pettarget") and UnitIsPlayer("pettarget")
        if not petOnPlayer then
            HunterLib.Debug("pet attack pvp")
            PetAttack()
        end
        return
    end

    local targetOnPet = UnitExists("targettarget") and UnitIsUnit("targettarget", "pet")
    if not targetOnPet then
        HunterLib.Debug("pet attack pve")
        PetAttack()
    end
end

function Hunter_PetAutoSummon()
    if not UnitExists("pet") then
        HunterLib.Debug("call pet")
        CastSpellByName("Call Pet")
    elseif UnitIsDead("pet") then
        HunterLib.Debug("revive pet")
        CastSpellByName("Revive Pet")
    end
end

function Hunter_PetFollow()
    if UnitExists("pet") then
        HunterLib.Debug("pet follow")
        PetFollow()
    end
end
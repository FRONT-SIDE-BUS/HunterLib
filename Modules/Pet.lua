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

    if UnitExists("targettarget") and UnitIsUnit("targettarget", "pet") then
        HunterLib.Debug("pet hold pve")
        return
    end

    HunterLib.Debug("pet attack pve")
    PetAttack()
end

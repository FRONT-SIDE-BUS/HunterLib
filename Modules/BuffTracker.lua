
local SCHEMA_VERSION = 7

local function initBuffDB()
    local db = HunterLib.GetDB()
    if not db.buffTrackerSchemaVersion or db.buffTrackerSchemaVersion < SCHEMA_VERSION then
        db.savedBuffs = {}
        db.capturedBuffs = {}
        db.buffTrackerSchemaVersion = SCHEMA_VERSION
    end
    db.savedBuffs = db.savedBuffs or {}
    db.capturedBuffs = db.capturedBuffs or {}
end

local function getActiveBuffMap()
    return HunterLib.Util.GetCurrentPlayerBuffMap()
end

local function sanitizePercent(value)
    local n = tonumber(value)
    if not n or n < 0 then return 0 end
    return n
end

local function dbgval(v)
    if v == nil then return "nil" end
    if v == "" then return '""' end
    return tostring(v)
end

local function isWeakName(name)
    return (not name) or name == "" or name == "(unnamed)"
end

local function getAuraSearchBlob(aura)
    local parts = {}
    if aura then
        if aura.name then table.insert(parts, string.lower(aura.name)) end
        if aura.description then table.insert(parts, string.lower(aura.description)) end
        if aura.tooltip then table.insert(parts, string.lower(aura.tooltip)) end
    end
    return table.concat(parts, " ")
end

local function isAutomaticCandidate(aura)
    local blob = getAuraSearchBlob(aura)
    if not blob or blob == "" then return nil end
    if string.find(blob, "haste") then return 1 end
    if string.find(blob, "attack speed") then return 1 end
    return nil
end

local function normalizeSpellID(v)
    local n = tonumber(v)
    if n and n > 0 then return n end
    return nil
end

local function getTrackingKey(info, fallback)
    if info and info.trackingKey and info.trackingKey ~= "" then
        return info.trackingKey
    end
    if info and normalizeSpellID(info.spellID) then
        return normalizeSpellID(info.spellID)
    end
    if info and info.name and info.name ~= "" then
        if info.texture and info.texture ~= "" then
            return "name:" .. tostring(info.name) .. "|" .. tostring(info.texture)
        end
        return "name:" .. tostring(info.name)
    end
    if info and info.texture and info.texture ~= "" then
        return "tex:" .. tostring(info.texture)
    end
    return tostring(fallback or "")
end

local function getDisplayName(info, fallback)
    if info and info.alias and info.alias ~= "" then return info.alias end
    if info and info.name and info.name ~= "" then return info.name end
    return tostring(fallback or "")
end

local function getShownID(info, aura)
    local sid = normalizeSpellID(aura and aura.spellID) or normalizeSpellID(info and info.spellID)
    if sid then return tostring(sid) end
    return "null"
end

local function debugAuraSnapshot(prefix, buffID, aura)
    if not aura then
        HunterLib.Debug(prefix .. " buffID=" .. dbgval(buffID) .. " aura=nil")
        return
    end
    HunterLib.Debug(prefix
        .. " buffID=" .. dbgval(buffID)
        .. ", slot=" .. dbgval(aura.slot)
        .. ", handle=" .. dbgval(aura.handle)
        .. ", index=" .. dbgval(aura.index)
        .. ", name=" .. dbgval(aura.name)
        .. ", desc=" .. dbgval(aura.description)
        .. ", remain=" .. dbgval(aura.remaining)
        .. ", tex=" .. dbgval(aura.texture))
end

local function mergeAuraIntoInfo(info, aura)
    if not info or not aura then return end
    if aura.name and aura.name ~= "" then info.name = aura.name end
    if (not info.texture or info.texture == "") and aura.texture and aura.texture ~= "" then info.texture = aura.texture end
    if normalizeSpellID(aura.spellID) then info.spellID = normalizeSpellID(aura.spellID) end
    if aura.description and aura.description ~= "" then info.description = aura.description end
    if aura.remaining and aura.remaining ~= "" then info.remaining = aura.remaining end
    if aura.tooltip and aura.tooltip ~= "" then info.tooltip = aura.tooltip end
    if aura.tooltipLines and table.getn(aura.tooltipLines) > 0 then info.tooltipLines = aura.tooltipLines end
    if not info.candidate and isAutomaticCandidate(aura) then info.candidate = 1 end
    info.trackingKey = getTrackingKey(info, aura.id)
end

local function buildNewCapturedEntry(aura)
    return {
        trackingKey = getTrackingKey(aura, aura.id),
        texture = aura.texture or "",
        name = aura.name or "",
        alias = aura.name or "",
        spellID = normalizeSpellID(aura.spellID),
        percent = 0,
        candidate = isAutomaticCandidate(aura),
        tooltip = aura.tooltip or nil,
        tooltipLines = aura.tooltipLines or nil,
        description = aura.description or nil,
        remaining = aura.remaining or nil,
    }
end

local function ensureTrackingKeys(map)
    local oldKey, info, newKey, moves = nil, nil, nil, {}
    for oldKey, info in pairs(map or {}) do
        if info then
            if info.spellID and not normalizeSpellID(info.spellID) then
                info.spellID = nil
            else
                info.spellID = normalizeSpellID(info.spellID)
            end
            info.trackingKey = getTrackingKey(info, oldKey)
            newKey = info.trackingKey
            if oldKey ~= newKey then
                table.insert(moves, { old = oldKey, new = newKey, info = info })
            end
        end
    end
    local i, move
    for i = 1, table.getn(moves) do
        move = moves[i]
        if not map[move.new] then
            map[move.new] = move.info
        end
        map[move.old] = nil
    end
end

local function sameIdentity(info, aura)
    if not info or not aura then return nil end
    if normalizeSpellID(info.spellID) and normalizeSpellID(aura.spellID) and normalizeSpellID(info.spellID) == normalizeSpellID(aura.spellID) then
        return 1
    end
    if info.name and info.name ~= "" and aura.name and aura.name ~= "" and info.name == aura.name then
        if info.texture and info.texture ~= "" and aura.texture and aura.texture ~= "" then
            return info.texture == aura.texture and 1 or nil
        end
        return 1
    end
    if info.texture and info.texture ~= "" and aura.texture and aura.texture ~= "" and info.texture == aura.texture then
        return 1
    end
    return nil
end

local function pruneDuplicateFallbackRows(map, aura, keepKey)
    local key, info
    for key, info in pairs(map) do
        if key ~= keepKey and info then
            if sameIdentity(info, aura) then
                if (not normalizeSpellID(info.spellID)) or normalizeSpellID(aura.spellID) then
                    map[key] = nil
                end
            end
        end
    end
end


local function findPreferredExistingKey(map, aura)
    local key, info
    if not map or not aura then return nil end
    for key, info in pairs(map) do
        if info and sameIdentity(info, aura) then
            if normalizeSpellID(info.spellID) then
                return normalizeSpellID(info.spellID)
            end
            if info.trackingKey and info.trackingKey ~= "" then
                return info.trackingKey
            end
            return key
        end
    end
    return nil
end

local function resolveCanonicalKey(db, aura, rawKey)
    if aura and normalizeSpellID(aura.spellID) then
        return normalizeSpellID(aura.spellID)
    end
    local key = findPreferredExistingKey(db and db.savedBuffs, aura)
    if key then return key end
    key = findPreferredExistingKey(db and db.capturedBuffs, aura)
    if key then return key end
    return rawKey
end

local function findActiveAuraForEntry(entryID, info, activeMap)
    local aura
    if not activeMap then return nil end
    aura = activeMap[entryID]
    if aura then return aura end
    if info and normalizeSpellID(info.spellID) and activeMap[normalizeSpellID(info.spellID)] then
        return activeMap[normalizeSpellID(info.spellID)]
    end
    if info and info.trackingKey and activeMap[info.trackingKey] then
        return activeMap[info.trackingKey]
    end
    if info and info.name and info.name ~= "" then
        for _, aura in pairs(activeMap) do
            if aura.name == info.name then
                if info.texture and info.texture ~= "" then
                    if aura.texture == info.texture then return aura end
                else
                    return aura
                end
            end
        end
    end
    if info and info.texture and info.texture ~= "" then
        for _, aura in pairs(activeMap) do
            if aura.texture == info.texture then return aura end
        end
    end
    return nil
end

local function strengthenWeakEntriesFromMap(db, activeMap)
    local key, aura, info
    for key, aura in pairs(activeMap) do
        info = db.capturedBuffs[key]
        if info then mergeAuraIntoInfo(info, aura) end
        info = db.savedBuffs[key]
        if info then mergeAuraIntoInfo(info, aura) end
    end
end

function HunterLib.BuffTrackerInit()
    initBuffDB()
    local db = HunterLib.GetDB()
    ensureTrackingKeys(db.capturedBuffs)
    ensureTrackingKeys(db.savedBuffs)
end

function HunterLib.GetCapturedBuffs()
    initBuffDB()
    ensureTrackingKeys(HunterLib.GetDB().capturedBuffs)
    return HunterLib.GetDB().capturedBuffs
end

function HunterLib.GetSavedBuffs()
    initBuffDB()
    ensureTrackingKeys(HunterLib.GetDB().savedBuffs)
    return HunterLib.GetDB().savedBuffs
end

function HunterLib.CaptureCurrentPlayerBuffs()
    initBuffDB()
    local db = HunterLib.GetDB()
    ensureTrackingKeys(db.capturedBuffs)
    ensureTrackingKeys(db.savedBuffs)

    local activeMap = getActiveBuffMap()
    local added, refreshed, unresolved = 0, 0, 0
    local key, aura, existing

    for key, aura in pairs(activeMap) do
        local rawKey = key
        key = resolveCanonicalKey(db, aura, key)
        if rawKey ~= key then
            if normalizeSpellID(key) and not normalizeSpellID(aura.spellID) then
                aura.spellID = normalizeSpellID(key)
            end
            aura.id = key
            HunterLib.Debug("capture-key-resolve raw=" .. dbgval(rawKey) .. " -> " .. dbgval(key))
        end

        debugAuraSnapshot("capture-snapshot", key, aura)
        if aura.unresolved then
            unresolved = unresolved + 1
        elseif db.savedBuffs[key] then
            mergeAuraIntoInfo(db.savedBuffs[key], aura)
            pruneDuplicateFallbackRows(db.savedBuffs, aura, key)
            pruneDuplicateFallbackRows(db.capturedBuffs, aura, key)
            if rawKey ~= key then
                db.savedBuffs[rawKey] = nil
                db.capturedBuffs[rawKey] = nil
            end
            HunterLib.Debug("capture-merge-saved buffID=" .. dbgval(key) .. ", finalName=" .. dbgval(db.savedBuffs[key].name))
            refreshed = refreshed + 1
        else
            existing = db.capturedBuffs[key]
            if existing then
                mergeAuraIntoInfo(existing, aura)
                pruneDuplicateFallbackRows(db.capturedBuffs, aura, key)
                pruneDuplicateFallbackRows(db.savedBuffs, aura, key)
                if rawKey ~= key then
                    db.capturedBuffs[rawKey] = nil
                    db.savedBuffs[rawKey] = nil
                end
                HunterLib.Debug("capture-refresh-captured buffID=" .. dbgval(key) .. ", finalName=" .. dbgval(existing.name))
                refreshed = refreshed + 1
            else
                db.capturedBuffs[key] = buildNewCapturedEntry(aura)
                pruneDuplicateFallbackRows(db.capturedBuffs, aura, key)
                pruneDuplicateFallbackRows(db.savedBuffs, aura, key)
                if rawKey ~= key then
                    db.capturedBuffs[rawKey] = nil
                    db.savedBuffs[rawKey] = nil
                end
                HunterLib.Debug("capture-add buffID=" .. dbgval(key) .. ", finalName=" .. dbgval(db.capturedBuffs[key].name) .. ", desc=" .. dbgval(db.capturedBuffs[key].description) .. ", remain=" .. dbgval(db.capturedBuffs[key].remaining))
                added = added + 1
            end
        end
    end

    strengthenWeakEntriesFromMap(db, activeMap)
    HunterLib.Debug("capture scan: added=" .. added .. ", refreshed=" .. refreshed .. ", unresolved=" .. unresolved)

    if HunterLib.UI.RefreshBuffsTab then HunterLib.UI.RefreshBuffsTab() end
    return added, refreshed, unresolved
end

function HunterLib.MarkCurrentBuffsAsCandidates()
    return 0
end

function HunterLib.UpdateCaptured(buffID, alias, percent)
    initBuffDB()
    local info = HunterLib.GetDB().capturedBuffs[buffID]
    if info then
        info.alias = (alias and alias ~= "") and alias or info.name
        info.percent = sanitizePercent(percent)
    end
end

function HunterLib.SaveCapturedBuff(buffID)
    initBuffDB()
    local db = HunterLib.GetDB()
    local info = db.capturedBuffs[buffID]
    if not info then return nil end

    db.savedBuffs[buffID] = {
        trackingKey = getTrackingKey(info, buffID),
        texture = info.texture or "",
        name = (info.name and info.name ~= "") and info.name or tostring(buffID),
        alias = (info.alias and info.alias ~= "") and info.alias or ((info.name and info.name ~= "") and info.name or tostring(buffID)),
        spellID = normalizeSpellID(info.spellID),
        percent = sanitizePercent(info.percent),
        enabled = 1,
        tooltip = info.tooltip or nil,
        tooltipLines = info.tooltipLines or nil,
        description = info.description or nil,
        remaining = info.remaining or nil,
    }
    db.capturedBuffs[buffID] = nil
    if HunterLib.UI.RefreshBuffsTab then HunterLib.UI.RefreshBuffsTab() end
    return 1
end

function HunterLib.UpdateSavedBuff(buffID, alias, percent)
    initBuffDB()
    local info = HunterLib.GetDB().savedBuffs[buffID]
    if info then
        info.alias = (alias and alias ~= "") and alias or info.name
        info.percent = sanitizePercent(percent)
    end
end

function HunterLib.DeleteCapturedBuff(buffID)
    initBuffDB()
    HunterLib.GetDB().capturedBuffs[buffID] = nil
    if HunterLib.UI.RefreshBuffsTab then HunterLib.UI.RefreshBuffsTab() end
end

function HunterLib.DeleteSavedBuff(buffID)
    initBuffDB()
    HunterLib.GetDB().savedBuffs[buffID] = nil
    if HunterLib.UI.RefreshBuffsTab then HunterLib.UI.RefreshBuffsTab() end
end

function HunterLib.ToggleSavedBuff(buffID)
    return nil
end

function HunterLib.IsSavedBuffActive(buffID)
    initBuffDB()
    local activeMap = getActiveBuffMap()
    local info = HunterLib.GetDB().savedBuffs[buffID]
    local aura = findActiveAuraForEntry(buffID, info, activeMap)
    return aura and not aura.unresolved and 1 or nil
end

function HunterLib.GetTrackedHasteBuffCount()
    initBuffDB()
    local count, id, info = 0, nil, nil
    for id, info in pairs(HunterLib.GetDB().savedBuffs) do
        if info and info.enabled and sanitizePercent(info.percent) > 0 then count = count + 1 end
    end
    return count
end

function HunterLib.GetActiveTrackedBuffSummary()
    initBuffDB()
    local db = HunterLib.GetDB()
    local activeMap = getActiveBuffMap()
    local names, count, buffID, info, aura = {}, 0, nil, nil, nil
    for buffID, info in pairs(db.savedBuffs) do
        aura = findActiveAuraForEntry(buffID, info, activeMap)
        if aura and not aura.unresolved and info and sanitizePercent(info.percent) > 0 then
            count = count + 1
            mergeAuraIntoInfo(info, aura)
            table.insert(names, getDisplayName(info, buffID))
        end
    end
    table.sort(names)
    return count, table.concat(names, ", ")
end

function HunterLib.GetActiveHasteModifier()
    initBuffDB()
    local db = HunterLib.GetDB()
    local activeMap = getActiveBuffMap()
    local mod, buffID, info, aura = 1.0, nil, nil, nil
    for buffID, info in pairs(db.savedBuffs) do
        aura = findActiveAuraForEntry(buffID, info, activeMap)
        if aura and not aura.unresolved and info and sanitizePercent(info.percent) > 0 then
            mod = mod * (1 - (sanitizePercent(info.percent) / 100))
        end
    end
    return mod
end

function HunterLib.GetMergedBuffEntries(filterMode)
    initBuffDB()
    local db = HunterLib.GetDB()
    ensureTrackingKeys(db.capturedBuffs)
    ensureTrackingKeys(db.savedBuffs)
    local activeMap = getActiveBuffMap()
    local list = {}
    local id, info, aura

    strengthenWeakEntriesFromMap(db, activeMap)

    for id, info in pairs(db.capturedBuffs) do
        if filterMode ~= "saved" then
            if filterMode ~= "candidates" or info.candidate then
                aura = findActiveAuraForEntry(id, info, activeMap)
                table.insert(list, {
                    id = id,
                    spellID = normalizeSpellID((aura and aura.spellID) or info.spellID),
                    shownID = getShownID(info, aura),
                    texture = info.texture or "",
                    name = info.name or "",
                    alias = (info.alias and info.alias ~= "") and info.alias or (info.name or ""),
                    percent = sanitizePercent(info.percent),
                    status = "captured",
                    candidate = info.candidate and 1 or nil,
                    enabled = nil,
                    active = aura and 1 or nil,
                    tooltip = (aura and aura.tooltip) or info.tooltip,
                    tooltipLines = (aura and aura.tooltipLines) or info.tooltipLines,
                    description = (aura and aura.description) or info.description,
                    remaining = (aura and aura.remaining) or info.remaining,
                })
            end
        end
    end

    for id, info in pairs(db.savedBuffs) do
        if filterMode == "all" or filterMode == "saved" or not filterMode then
            aura = findActiveAuraForEntry(id, info, activeMap)
            table.insert(list, {
                id = id,
                spellID = normalizeSpellID((aura and aura.spellID) or info.spellID),
                shownID = getShownID(info, aura),
                texture = info.texture or "",
                name = info.name or "",
                alias = (info.alias and info.alias ~= "") and info.alias or (info.name or ""),
                percent = sanitizePercent(info.percent),
                status = "saved",
                candidate = nil,
                enabled = info.enabled and 1 or nil,
                active = aura and 1 or nil,
                tooltip = (aura and aura.tooltip) or info.tooltip,
                tooltipLines = (aura and aura.tooltipLines) or info.tooltipLines,
                description = (aura and aura.description) or info.description,
                remaining = (aura and aura.remaining) or info.remaining,
            })
        end
    end

    table.sort(list, function(a, b)
        if a.status ~= b.status then return a.status == "captured" end
        if a.status == "captured" and b.status == "captured" and a.candidate ~= b.candidate then
            return a.candidate and true or false
        end
        if a.status == "saved" and b.status == "saved" and a.active ~= b.active then
            return a.active and true or false
        end
        return tostring(a.name or a.id) < tostring(b.name or b.id)
    end)

    return list
end

function HunterLib.ExportSavedBuffs()
    initBuffDB()
    local parts, id, info = {}, nil, nil
    for id, info in pairs(HunterLib.GetDB().savedBuffs) do
        table.insert(parts,
            tostring(id)
            .. "," .. (info.name or "")
            .. "," .. (info.alias or info.name or "")
            .. "," .. tostring(sanitizePercent(info.percent))
            .. "," .. (info.texture or "")
            .. "," .. tostring(info.enabled and 1 or 0)
        )
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

function HunterLib.ImportSavedBuffs(str)
    initBuffDB()
    if not str or str == "" then return 0 end

    local db = HunterLib.GetDB()
    local imported, entry = 0, nil
    local id, name, alias, percent, texture, enabled

    for entry in string.gmatch(str, "([^;]+)") do
        id, name, alias, percent, texture, enabled = string.match(entry, "([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")
        if id and id ~= "" then
            local sid = normalizeSpellID(id)
            local key = sid or id
            db.savedBuffs[key] = {
                trackingKey = key,
                spellID = sid,
                name = name or tostring(key),
                alias = alias or name or tostring(key),
                percent = sanitizePercent(percent),
                texture = texture or "",
                enabled = tonumber(enabled) == 1 and 1 or nil,
            }
            imported = imported + 1
        end
    end

    if HunterLib.UI.RefreshBuffsTab then HunterLib.UI.RefreshBuffsTab() end
    return imported
end

function HunterLib.ResetCapturedBuffs()
    initBuffDB()
    HunterLib.GetDB().capturedBuffs = {}
end

function HunterLib.ResetSavedBuffs()
    initBuffDB()
    HunterLib.GetDB().savedBuffs = {}
end

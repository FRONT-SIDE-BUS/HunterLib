local MAX_AURAS = HunterLib.Const.MAX_AURAS

local scanner

local function ensureScanner()
    if scanner then return scanner end
    scanner = CreateFrame("GameTooltip", "HLTip", UIParent, "GameTooltipTemplate")
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    return scanner
end

local function readTooltipLines(tt)
    local lines = {}
    local i = 1
    while true do
        local left = getglobal("HLTipTextLeft" .. i)
        if not left then break end
        local value = left:GetText()
        if value and value ~= "" then table.insert(lines, value) end
        i = i + 1
    end
    return lines
end

local function extractTooltipMeta(lines)
    local meta = { name=nil, description=nil, remaining=nil }
    if not lines or table.getn(lines) == 0 then return meta end
    meta.name = lines[1]
    local i, line
    for i = 2, table.getn(lines) do
        line = lines[i]
        if line and line ~= "" then
            if string.find(string.lower(line), "remaining") then
                if not meta.remaining then meta.remaining = line end
            elseif not meta.description then
                meta.description = line
            end
        end
    end
    return meta
end

local function safeTooltipByHandle(slot, handle)
    local tt = ensureScanner()
    local attempt, lines
    for attempt = 1, 4 do
        tt:SetOwner(UIParent, "ANCHOR_NONE")
        tt:ClearLines()
        if tt.SetPlayerBuff and handle and handle >= 0 then
            tt:SetPlayerBuff(handle)
            lines = readTooltipLines(tt)
            if lines and table.getn(lines) > 0 then
                tt:Hide()
                return lines
            end
        end
        tt:ClearLines()
        if tt.SetPlayerBuff and slot and slot >= 0 then
            tt:SetPlayerBuff(slot)
            lines = readTooltipLines(tt)
            if lines and table.getn(lines) > 0 then
                tt:Hide()
                return lines
            end
        end
        tt:ClearLines()
    end
    tt:Hide()
    return nil
end

function HunterLib.Util.GetPlayerBuffByIndex(index)
    local texture, stacks, buffID = UnitBuff("player", index)
    return texture, stacks, buffID
end

function HunterLib.Util.GetTargetDebuffTexture(index)
    return UnitDebuff("target", index)
end

function HunterLib.Util.PlayerHasBuffTexture(texture)
    local i
    for i = 1, MAX_AURAS do
        local t = UnitBuff("player", i)
        if t == texture then return 1 end
    end
    return nil
end

function HunterLib.Util.TargetHasDebuffTexture(texture)
    if not UnitExists("target") or UnitIsDead("target") then return nil end
    local i
    for i = 1, MAX_AURAS do
        local t = UnitDebuff("target", i)
        if t == texture then return 1 end
    end
    return nil
end

function HunterLib.Util.GetPlayerBuffTooltip(index, handle)
    local lines = safeTooltipByHandle(index and (index - 1) or nil, handle)
    if not lines or table.getn(lines) == 0 then return nil, nil, nil end
    local meta = extractTooltipMeta(lines)
    return lines, table.concat(lines, "\n"), meta
end

local function buildFallbackKey(name, texture, index)
    if name and name ~= "" then
        if texture and texture ~= "" then return "name:" .. name .. "|" .. texture end
        return "name:" .. name
    end
    if texture and texture ~= "" then return "tex:" .. texture end
    return "slot:" .. tostring(index)
end

local function scanUnitBuffs()
    local byTexture = {}
    local i, texture, stacks, buffID, list
    for i = 1, MAX_AURAS do
        texture, stacks, buffID = UnitBuff("player", i)
        if texture or buffID then
            list = byTexture[texture or ""]
            if not list then
                list = {}
                byTexture[texture or ""] = list
            end
            table.insert(list, {
                index = i,
                texture = texture or "",
                stacks = stacks or 0,
                spellID = (buffID and buffID ~= 0) and buffID or nil,
            })
        end
    end
    return byTexture
end

local function scanTooltipBuffs()
    local list = {}
    local slot, handle, texture, lines, text, meta
    for slot = 0, (MAX_AURAS - 1) do
        handle = nil
        if GetPlayerBuff then
            handle = GetPlayerBuff(slot, "HELPFUL")
        end
        if handle and handle >= 0 then
            texture = GetPlayerBuffTexture and GetPlayerBuffTexture(handle) or ""
            lines, text, meta = HunterLib.Util.GetPlayerBuffTooltip(slot + 1, handle)
            table.insert(list, {
                slot = slot,
                handle = handle,
                texture = texture or "",
                tooltipLines = lines,
                tooltip = text,
                name = (meta and meta.name) or "",
                description = meta and meta.description or nil,
                remaining = meta and meta.remaining or nil,
            })
        end
    end
    return list
end

local function popBestUnitRecord(byTexture, texture)
    local list = byTexture[texture or ""]
    if list and table.getn(list) > 0 then
        local rec = list[1]
        table.remove(list, 1)
        return rec
    end
    return nil
end

function HunterLib.Util.GetCurrentPlayerBuffMap()
    local map = {}
    local used = {}
    local unitByTexture = scanUnitBuffs()
    local tooltipList = scanTooltipBuffs()
    local i, tip, unitRec, key

    for i = 1, table.getn(tooltipList) do
        tip = tooltipList[i]
        unitRec = popBestUnitRecord(unitByTexture, tip.texture)
        if unitRec and unitRec.spellID then
            key = unitRec.spellID
        else
            key = buildFallbackKey(tip.name, tip.texture, tip.slot)
        end
        if not used[key] then
            map[key] = {
                slot = tip.slot,
                handle = tip.handle,
                index = unitRec and unitRec.index or nil,
                texture = tip.texture or (unitRec and unitRec.texture) or "",
                stacks = unitRec and unitRec.stacks or 0,
                id = key,
                spellID = unitRec and unitRec.spellID or nil,
                tooltipLines = tip.tooltipLines,
                tooltip = tip.tooltip,
                name = tip.name or "",
                description = tip.description or nil,
                remaining = tip.remaining or nil,
                unresolved = (not tip.name or tip.name == "") and 1 or nil,
            }
            used[key] = 1
        end
    end

    -- Add UnitBuff-only leftovers if any exist.
    local texture, list, j, rec
    for texture, list in pairs(unitByTexture) do
        for j = 1, table.getn(list) do
            rec = list[j]
            key = rec.spellID or buildFallbackKey(nil, rec.texture, rec.index)
            if not used[key] then
                map[key] = {
                    slot = nil,
                    handle = nil,
                    index = rec.index,
                    texture = rec.texture or "",
                    stacks = rec.stacks or 0,
                    id = key,
                    spellID = rec.spellID or nil,
                    tooltipLines = nil,
                    tooltip = nil,
                    name = "",
                    description = nil,
                    remaining = nil,
                    unresolved = 1,
                }
                used[key] = 1
            end
        end
    end

    return map
end

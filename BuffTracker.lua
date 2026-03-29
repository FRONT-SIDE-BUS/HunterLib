-- =========================
-- BUFF TRACKER
-- Captured buffs + saved buffs + candidate detection
-- =========================

local function HL_InitBuffDB()
  if not HunterLibDB then
    HunterLibDB = {}
  end

  if not HunterLibDB.savedBuffs then
    HunterLibDB.savedBuffs = {}
  end

  if not HunterLibDB.capturedBuffs then
    HunterLibDB.capturedBuffs = {}
  end
end

function HunterLib.BuffTrackerInit()
  HL_InitBuffDB()
end

function HunterLib.GetCapturedBuffs()
  HL_InitBuffDB()
  return HunterLibDB.capturedBuffs
end

function HunterLib.GetSavedBuffs()
  HL_InitBuffDB()
  return HunterLibDB.savedBuffs
end

function HunterLib.CaptureCurrentPlayerBuffs()
  HL_InitBuffDB()

  local added = 0
  local i

  for i = 1, 16 do
    local texture, stacks, buffID = UnitBuff("player", i)

    if buffID and buffID ~= 0 then
      if not HunterLibDB.savedBuffs[buffID]
      and not HunterLibDB.capturedBuffs[buffID] then
        HunterLibDB.capturedBuffs[buffID] = {
          texture = texture or "",
          name = "",
          percent = 0,
          candidate = nil
        }
        added = added + 1
      end
    end
  end

  HunterLib.Debug("captured buffs: "..added)
  return added
end

function HunterLib.MarkCurrentBuffsAsCandidates()
  HL_InitBuffDB()

  local marked = 0
  local i

  for i = 1, 16 do
    local texture, stacks, buffID = UnitBuff("player", i)

    if buffID and HunterLibDB.capturedBuffs[buffID] then
      if not HunterLibDB.capturedBuffs[buffID].candidate then
        HunterLibDB.capturedBuffs[buffID].candidate = 1
        marked = marked + 1
      end
    end
  end

  if marked > 0 then
    HunterLib.Debug("candidate buffs marked: "..marked)
  end
end

function HunterLib.UpdateCaptured(buffID, name, percent)
  HL_InitBuffDB()

  local b = HunterLibDB.capturedBuffs[buffID]
  if b then
    b.name = name or ""
    b.percent = tonumber(percent) or 0
  end
end

function HunterLib.SaveCapturedBuff(buffID)
  HL_InitBuffDB()

  local b = HunterLibDB.capturedBuffs[buffID]
  if not b then return end

  HunterLibDB.savedBuffs[buffID] = {
    texture = b.texture or "",
    name = (b.name and b.name ~= "") and b.name or tostring(buffID),
    percent = tonumber(b.percent) or 0,
    enabled = 1
  }

  HunterLibDB.capturedBuffs[buffID] = nil
  HunterLib.Debug("saved buff "..buffID)
end

function HunterLib.UpdateSavedBuff(buffID, name, percent)
  HL_InitBuffDB()

  local b = HunterLibDB.savedBuffs[buffID]
  if b then
    if name and name ~= "" then
      b.name = name
    end
    b.percent = tonumber(percent) or 0
  end
end

function HunterLib.DeleteCapturedBuff(buffID)
  HL_InitBuffDB()
  HunterLibDB.capturedBuffs[buffID] = nil
end

function HunterLib.DeleteSavedBuff(buffID)
  HL_InitBuffDB()
  HunterLibDB.savedBuffs[buffID] = nil
end

function HunterLib.ToggleSavedBuff(buffID)
  HL_InitBuffDB()

  local b = HunterLibDB.savedBuffs[buffID]
  if b then
    if b.enabled then
      b.enabled = nil
    else
      b.enabled = 1
    end
  end
end

function HunterLib.IsSavedBuffActive(buffID)
  local i
  for i = 1, 16 do
    local texture, stacks, id = UnitBuff("player", i)
    if id == buffID then
      return 1
    end
  end
  return nil
end

function HunterLib.GetActiveHasteModifier()
  HL_InitBuffDB()

  local mod = 1.0
  local i

  for i = 1, 16 do
    local texture, stacks, buffID = UnitBuff("player", i)

    if buffID and HunterLibDB.savedBuffs[buffID] then
      local b = HunterLibDB.savedBuffs[buffID]
      if b.enabled and b.percent and b.percent > 0 then
        mod = mod * (1 - (b.percent / 100))
      end
    end
  end

  return mod
end

function HunterLib.GetMergedBuffEntries(filterMode)
  HL_InitBuffDB()

  local list = {}
  local id, info

  for id, info in pairs(HunterLibDB.capturedBuffs) do
    if filterMode ~= "saved" then
      if filterMode ~= "candidates" or info.candidate then
        table.insert(list, {
          id = id,
          texture = info.texture or "",
          name = (info.name and info.name ~= "") and info.name or "",
          percent = info.percent or 0,
          status = "captured",
          candidate = info.candidate and 1 or nil,
          enabled = nil,
          active = nil
        })
      end
    end
  end

  for id, info in pairs(HunterLibDB.savedBuffs) do
    if filterMode == "all" or filterMode == "saved" or not filterMode then
      table.insert(list, {
        id = id,
        texture = info.texture or "",
        name = info.name or tostring(id),
        percent = info.percent or 0,
        status = "saved",
        candidate = nil,
        enabled = info.enabled and 1 or nil,
        active = HunterLib.IsSavedBuffActive(id)
      })
    end
  end

  table.sort(list, function(a, b)
    if a.status ~= b.status then
      if a.status == "captured" and b.status ~= "captured" then return true end
      if b.status == "captured" and a.status ~= "captured" then return false end
    end

    if a.status == "captured" and b.status == "captured" then
      if a.candidate and not b.candidate then return true end
      if b.candidate and not a.candidate then return false end
    end

    if a.status == "saved" and b.status == "saved" then
      if a.active and not b.active then return true end
      if b.active and not a.active then return false end
    end

    return a.id < b.id
  end)

  return list
end

function HunterLib.ExportSavedBuffs()
  HL_InitBuffDB()

  local parts = {}
  local id, info

  for id, info in pairs(HunterLibDB.savedBuffs) do
    table.insert(parts,
      tostring(id) .. "," ..
      (info.name or "") .. "," ..
      tostring(info.percent or 0) .. "," ..
      (info.texture or "") .. "," ..
      tostring(info.enabled and 1 or 0)
    )
  end

  table.sort(parts)
  return table.concat(parts, ";")
end

function HunterLib.ImportSavedBuffs(str)
  HL_InitBuffDB()

  if not str or str == "" then return 0 end

  local imported = 0
  local entry

  for entry in string.gmatch(str, "([^;]+)") do
    local id, name, percent, texture, enabled =
      string.match(entry, "([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")

    id = tonumber(id)
    percent = tonumber(percent)

    if id then
      HunterLibDB.savedBuffs[id] = {
        name = name or tostring(id),
        percent = percent or 0,
        texture = texture or "",
        enabled = tonumber(enabled) == 1 and 1 or nil
      }
      imported = imported + 1
    end
  end

  return imported
end
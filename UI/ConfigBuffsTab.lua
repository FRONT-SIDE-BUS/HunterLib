local ROW_HEIGHT = 28
local FILTERS = {
  { key = "all", label = "All" },
  { key = "saved", label = "Saved" },
  { key = "candidates", label = "Candidates" },
}

local function getFilter()
  local db = HunterLib.GetDB()
  db.ui = db.ui or {}
  return db.ui.buffFilter or "all"
end

local function setFilter(value)
  local db = HunterLib.GetDB()
  db.ui = db.ui or {}
  db.ui.buffFilter = value
end

local function gatherStats(entries)
  local stats = { captured = 0, candidate = 0, saved = 0, active = 0 }
  local _, entry
  for _, entry in ipairs(entries or {}) do
    if entry.status == "captured" then
      stats.captured = stats.captured + 1
      if entry.candidate then stats.candidate = stats.candidate + 1 end
    else
      stats.saved = stats.saved + 1
      if entry.active and tonumber(entry.percent or 0) > 0 then
        stats.active = stats.active + 1
      end
    end
  end
  return stats
end

local function setStatusVisual(fontString, entry)
  if entry.status == "captured" then
    if entry.candidate then
      fontString:SetText("CANDIDATE")
      fontString:SetTextColor(1.00, 0.82, 0.00)
    else
      fontString:SetText("CAPTURED")
      fontString:SetTextColor(0.82, 0.82, 0.82)
    end
    return
  end

  if entry.active then
    fontString:SetText("ON")
    fontString:SetTextColor(0.20, 1.00, 0.20)
  else
    fontString:SetText("OFF")
    fontString:SetTextColor(1.00, 0.22, 0.22)
  end
end

local function setRowTexture(row, path)
  if path and path ~= "" then
    row.icon:SetTexture(path)
  else
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  end
end


local function applyEntryTooltip(frame, entry)
  if not frame or not frame.SetScript then
    return
  end
  frame.entryData = entry
  frame:SetScript("OnEnter", function(self)
    local data = self.entryData
    if not data then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if data.tooltipLines and table.getn(data.tooltipLines) > 0 then
      local i
      for i = 1, table.getn(data.tooltipLines) do
        if i == 1 then
          GameTooltip:SetText(data.tooltipLines[i])
        else
          GameTooltip:AddLine(data.tooltipLines[i], 0.85, 0.85, 0.85, 1)
        end
      end
    elseif data.tooltip and data.tooltip ~= "" then
      GameTooltip:SetText(data.tooltip)
    else
      GameTooltip:SetText(data.name and data.name ~= "" and data.name or tostring(data.id))
      GameTooltip:AddLine("No tooltip captured yet.", 0.6, 0.6, 0.6, 1)
    end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
end

local function createExportWindow(parent)
  local popup = CreateFrame("Frame", nil, parent)
  popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  popup:SetWidth(510)
  popup:SetHeight(230)
  popup:SetFrameStrata("FULLSCREEN_DIALOG")
  popup:Hide()
  HunterLib.UI.ApplyFrameStyle(popup)

  HunterLib.UI.CreateTitle(popup, "Import / Export", "TOPLEFT", popup, "TOPLEFT", 16, -14)
  local close = HunterLib.UI.CreateButton(popup, 22, 22, "X")
  close:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -10, -10)
  close:SetScript("OnClick", function() popup:Hide() end)

  local help = HunterLib.UI.CreateSmallText(popup, "Copy saved data out, or paste data here and press Import.", "TOPLEFT", popup, "TOPLEFT", 16, -40)
  help:SetWidth(470)

  local box = HunterLib.UI.CreateEditBox(popup, 474, 110, false)
  box:SetMultiLine(true)
  box:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -64)
  box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -16, 52)
  box:SetFontObject("GameFontHighlightSmall")
  box:SetJustifyH("LEFT")
  box:SetScript("OnEscapePressed", function() this:ClearFocus() popup:Hide() end)

  local selectBtn = HunterLib.UI.CreateButton(popup, 100, 22, "Select All")
  selectBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 16, 14)
  selectBtn:SetScript("OnClick", function() box:HighlightText() box:SetFocus() end)

  local importBtn = HunterLib.UI.CreateButton(popup, 84, 22, "Import")
  importBtn:SetPoint("LEFT", selectBtn, "RIGHT", 8, 0)

  local status = HunterLib.UI.CreateSmallText(popup, "", "LEFT", importBtn, "RIGHT", 12, 0)
  popup.box = box
  popup.status = status
  popup.importBtn = importBtn
  return popup
end

function HunterLib.UI.CreateBuffsTab(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent.content, "TOPLEFT", 0, 0)
  panel:SetPoint("BOTTOMRIGHT", parent.content, "BOTTOMRIGHT", 0, 0)

  HunterLib.UI.CreateTitle(panel, "Buff Tracker", "TOPLEFT", panel, "TOPLEFT", 16, -16)
  local subtitle = HunterLib.UI.CreateSmallText(panel, "Capture buffs, then let the addon auto-flag likely haste candidates from their tooltip text.", "TOPLEFT", panel, "TOPLEFT", 18, -40)
  subtitle:SetWidth(720)

  local actions = CreateFrame("Frame", nil, panel)
  actions:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -74)
  actions:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -74)
  actions:SetHeight(52)
  HunterLib.UI.ApplyInsetStyle(actions)
  HunterLib.UI.CreateLabel(actions, "Actions", "TOPLEFT", actions, "TOPLEFT", 14, -12)

  local captureButton = HunterLib.UI.CreateButton(actions, 128, 22, "Capture Buffs")
  captureButton:SetPoint("TOPLEFT", actions, "TOPLEFT", 14, -24)
  local exportButton = HunterLib.UI.CreateButton(actions, 84, 22, "Export")
  exportButton:SetPoint("LEFT", captureButton, "RIGHT", 8, 0)
  local clearCapturedButton = HunterLib.UI.CreateButton(actions, 110, 22, "Clear Captured")
  clearCapturedButton:SetPoint("LEFT", exportButton, "RIGHT", 8, 0)
  local clearSavedButton = HunterLib.UI.CreateButton(actions, 96, 22, "Clear Saved")
  clearSavedButton:SetPoint("LEFT", clearCapturedButton, "RIGHT", 8, 0)

  local filters = CreateFrame("Frame", nil, panel)
  filters:SetPoint("TOPLEFT", actions, "BOTTOMLEFT", 0, -10)
  filters:SetPoint("TOPRIGHT", actions, "BOTTOMRIGHT", 0, -10)
  filters:SetHeight(44)
  HunterLib.UI.ApplyInsetStyle(filters)
  HunterLib.UI.CreateLabel(filters, "View", "TOPLEFT", filters, "TOPLEFT", 14, -12)

  local filterButtons = {}
  local anchorX = 60
  local i, info
  for i, info in ipairs(FILTERS) do
    local btn = HunterLib.UI.CreateButton(filters, 82, 22, info.label)
    btn:SetPoint("TOPLEFT", filters, "TOPLEFT", anchorX, -10)
    anchorX = anchorX + 88
    btn.filterKey = info.key
    filterButtons[i] = btn
  end

  local statsBar = CreateFrame("Frame", nil, panel)
  statsBar:SetPoint("TOPLEFT", filters, "BOTTOMLEFT", 0, -10)
  statsBar:SetPoint("TOPRIGHT", filters, "BOTTOMRIGHT", 0, -10)
  statsBar:SetHeight(22)
  local capturedPill = HunterLib.UI.CreateStatusPill(statsBar, 116)
  capturedPill:SetPoint("LEFT", statsBar, "LEFT", 0, 0)
  local candidatePill = HunterLib.UI.CreateStatusPill(statsBar, 122)
  candidatePill:SetPoint("LEFT", capturedPill, "RIGHT", 8, 0)
  local savedPill = HunterLib.UI.CreateStatusPill(statsBar, 100)
  savedPill:SetPoint("LEFT", candidatePill, "RIGHT", 8, 0)
  local activePill = HunterLib.UI.CreateStatusPill(statsBar, 100)
  activePill:SetPoint("LEFT", savedPill, "RIGHT", 8, 0)

  local listFrame = CreateFrame("Frame", nil, panel)
  listFrame:SetPoint("TOPLEFT", statsBar, "BOTTOMLEFT", 0, -10)
  listFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
  HunterLib.UI.ApplyInsetStyle(listFrame)

  local scrollFrame = CreateFrame("ScrollFrame", "HunterLibBuffsScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -28, 6)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetWidth(560)
  content:SetHeight(1)
  scrollFrame:SetScrollChild(content)

  local scrollBar = getglobal("HunterLibBuffsScrollFrameScrollBar")

  local function getMaxScroll()
    local visible = scrollFrame:GetHeight() or 0
    local total = content:GetHeight() or 0
    local maxScroll = total - visible
    if maxScroll < 0 then maxScroll = 0 end
    return maxScroll
  end

  local function clampScroll(value)
    if value == nil then value = 0 end
    local maxScroll = getMaxScroll()
    if value < 0 then value = 0 end
    if value > maxScroll then value = maxScroll end
    scrollFrame:SetVerticalScroll(value)
    if scrollBar then
      if maxScroll > 0 then
        scrollBar:Show()
      else
        scrollBar:Hide()
      end
    end
  end

  scrollFrame:EnableMouseWheel(1)
  scrollFrame:SetScript("OnMouseWheel", function()
    local delta = arg1
    if delta == nil then return end
    local current = scrollFrame:GetVerticalScroll() or 0
    local step = ROW_HEIGHT * 3
    if delta > 0 then
      clampScroll(current - step)
    else
      clampScroll(current + step)
    end
  end)

  local header = CreateFrame("Frame", nil, content)
  header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
  header:SetHeight(22)
  HunterLib.UI.ApplySoftInsetStyle(header)

  HunterLib.UI.CreateSmallText(header, "Buff", "LEFT", header, "LEFT", 8, 0):SetWidth(154)
  HunterLib.UI.CreateSmallText(header, "ID", "LEFT", header, "LEFT", 166, 0):SetWidth(36)
  HunterLib.UI.CreateSmallText(header, "%", "LEFT", header, "LEFT", 212, 0):SetWidth(24)
  HunterLib.UI.CreateSmallText(header, "State", "LEFT", header, "LEFT", 274, 0):SetWidth(60)
  HunterLib.UI.CreateSmallText(header, "Alias", "LEFT", header, "LEFT", 350, 0):SetWidth(48)

  panel.rows = {}
  panel.exportPopup = createExportWindow(parent)

  local function createRow(index)
    local row = CreateFrame("Frame", nil, content)
    row:SetHeight(26)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(24 + ((index - 1) * ROW_HEIGHT) + 4))
    row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(24 + ((index - 1) * ROW_HEIGHT) + 4))
    HunterLib.UI.ApplySoftInsetStyle(row)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(18)
    row.icon:SetHeight(18)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetWidth(138)
    row.name:SetJustifyH("LEFT")

    row.idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.idText:SetPoint("LEFT", row, "LEFT", 166, 0)
    row.idText:SetWidth(36)
    row.idText:SetJustifyH("LEFT")

    row.percentBox = HunterLib.UI.CreateEditBox(row, 44, 20, false)
    row.percentBox.holder:SetPoint("LEFT", row, "LEFT", 208, 0)

    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.status:SetPoint("LEFT", row, "LEFT", 274, 0)
    row.status:SetWidth(62)
    row.status:SetJustifyH("LEFT")

    row.nameBox = HunterLib.UI.CreateEditBox(row, 100, 20, false)
    row.nameBox.holder:SetPoint("LEFT", row, "LEFT", 346, 0)

    row.primaryButton = HunterLib.UI.CreateButton(row, 42, 20, "Save")
    row.primaryButton:SetPoint("RIGHT", row, "RIGHT", -58, 0)
    row.secondaryButton = HunterLib.UI.CreateButton(row, 52, 20, "Delete")
    row.secondaryButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)

    panel.rows[index] = row
    return row
  end

  local function bindRow(row, entry)
    row:Show()
    applyEntryTooltip(row, entry)
    setRowTexture(row, entry.texture)
    row.name:SetText((entry.name and entry.name ~= "") and entry.name or "(unnamed)")
    row.idText:SetText(entry.shownID or "null")
    row.percentBox:SetText(tostring(entry.percent or 0))
    row.nameBox:SetText(entry.alias or entry.name or "")
    setStatusVisual(row.status, entry)

    if entry.status == "captured" then
      row.primaryButton:SetText("Save")
      row.primaryButton:SetScript("OnClick", function()
        HunterLib.UpdateCaptured(entry.id, row.nameBox:GetText(), row.percentBox:GetText())
        HunterLib.SaveCapturedBuff(entry.id)
      end)
      row.secondaryButton:SetText("Delete")
      row.secondaryButton:SetScript("OnClick", function() HunterLib.DeleteCapturedBuff(entry.id) end)
    else
      row.primaryButton:SetText("Update")
      row.primaryButton:SetScript("OnClick", function()
        HunterLib.UpdateSavedBuff(entry.id, row.nameBox:GetText(), row.percentBox:GetText())
        if HunterLib.UI.RefreshBuffsTab then HunterLib.UI.RefreshBuffsTab() end
      end)
      row.secondaryButton:SetText("Delete")
      row.secondaryButton:SetScript("OnClick", function()
        HunterLib.UpdateSavedBuff(entry.id, row.nameBox:GetText(), row.percentBox:GetText())
        HunterLib.DeleteSavedBuff(entry.id)
      end)
    end
  end

  local function refreshFilterButtons()
    local current = getFilter()
    local _, btn
    for _, btn in ipairs(filterButtons) do
      btn.isActive = btn.filterKey == current and 1 or nil
      HunterLib.UI.SetButtonState(btn, btn.isActive and "active" or "normal")
    end
  end

  local function refresh()
    local entries = HunterLib.GetMergedBuffEntries(getFilter())
    local stats = gatherStats(HunterLib.GetMergedBuffEntries("all"))
    local count = table.getn(entries)
    local i

    capturedPill.text:SetText("Captured: " .. stats.captured)
    candidatePill.text:SetText("Candidates: " .. stats.candidate)
    savedPill.text:SetText("Saved: " .. stats.saved)
    activePill.text:SetText("Active: " .. stats.active)

    for i = 1, count do
      local row = panel.rows[i] or createRow(i)
      bindRow(row, entries[i])
    end

    for i = count + 1, table.getn(panel.rows) do
      panel.rows[i]:Hide()
    end

    local totalHeight = 28 + (count * ROW_HEIGHT)
    if totalHeight < 40 then totalHeight = 40 end
    content:SetHeight(totalHeight)
    clampScroll(scrollFrame:GetVerticalScroll() or 0)
    refreshFilterButtons()
  end

  local function openExportPopup(mode)
    local popup = panel.exportPopup
    local db = HunterLib.GetDB()
    db.ui = db.ui or {}
    if mode == "export" then
      db.ui.exportText = HunterLib.ExportSavedBuffs()
      popup.status:SetText("Export text ready.")
    else
      popup.status:SetText("Paste data and press Import.")
    end
    popup.box:SetText(db.ui.exportText or "")
    popup.box:HighlightText()
    popup.box:SetFocus()
    popup:Show()
  end

  captureButton:SetScript("OnClick", function() HunterLib.CaptureCurrentPlayerBuffs() end)
  exportButton:SetScript("OnClick", function() openExportPopup("export") end)
  panel.exportPopup.importBtn:SetScript("OnClick", function()
    local text = panel.exportPopup.box:GetText() or ""
    HunterLib.GetDB().ui.exportText = text
    local count = HunterLib.ImportSavedBuffs(text)
    panel.exportPopup.status:SetText("Imported: " .. tostring(count))
  end)
  clearCapturedButton:SetScript("OnClick", function() HunterLib.ResetCapturedBuffs() HunterLib.UI.RefreshBuffsTab() end)
  clearSavedButton:SetScript("OnClick", function() HunterLib.ResetSavedBuffs() HunterLib.UI.RefreshBuffsTab() end)

  for i, btn in ipairs(filterButtons) do
    local currentButton = btn
    currentButton:SetScript("OnClick", function()
      setFilter(currentButton.filterKey)
      refresh()
    end)
  end

  panel:SetScript("OnShow", refresh)
  panel.Refresh = refresh
  return panel
end

function HunterLib.UI.RefreshBuffsTab()
  if HunterLib.UI.BuffsTab and HunterLib.UI.BuffsTab.Refresh then
    HunterLib.UI.BuffsTab:Refresh()
  end
end

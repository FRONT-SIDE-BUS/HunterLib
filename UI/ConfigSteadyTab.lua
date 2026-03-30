local function createSettingRow(parent, anchor, labelText)
  local row = CreateFrame("Frame", nil, parent)
  if anchor then
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
  else
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -50)
  end
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  row:SetHeight(30)

  row.label = HunterLib.UI.CreateLabel(row, labelText, "LEFT", row, "LEFT", 18, 0)
  row.label:SetWidth(220)

  row.box = HunterLib.UI.CreateEditBox(row, 128, 26, false)
  row.box.holder:SetPoint("RIGHT", row, "RIGHT", -26, 0)
  return row
end

function HunterLib.UI.CreateSteadyTab(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent.content, "TOPLEFT", 0, 0)
  panel:SetPoint("BOTTOMRIGHT", parent.content, "BOTTOMRIGHT", 0, 0)

  HunterLib.UI.CreateTitle(panel, "Steady Shot", "TOPLEFT", panel, "TOPLEFT", 16, -16)
  local subtitle = HunterLib.UI.CreateSmallText(panel, "Minimal configuration first. The live timing display will return later in a cleaner design.", "TOPLEFT", panel, "TOPLEFT", 18, -40)
  subtitle:SetWidth(720)

  local settings = CreateFrame("Frame", nil, panel)
  settings:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -74)
  settings:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -74)
  settings:SetHeight(216)
  HunterLib.UI.ApplyInsetStyle(settings)
  HunterLib.UI.CreateLabel(settings, "Steady settings", "TOPLEFT", settings, "TOPLEFT", 14, -12)

  local content = CreateFrame("Frame", nil, settings)
  content:SetPoint("TOPLEFT", settings, "TOPLEFT", 0, 0)
  content:SetPoint("TOPRIGHT", settings, "TOPRIGHT", 0, 0)
  content:SetHeight(132)

  local castRow = createSettingRow(content, nil, "Base cast time")
  local marginRow = createSettingRow(content, castRow, "Safety margin")

  local debugRow = CreateFrame("Frame", nil, settings)
  debugRow:SetPoint("TOPLEFT", content, "BOTTOMLEFT", 0, -6)
  debugRow:SetPoint("TOPRIGHT", settings, "TOPRIGHT", 0, 0)
  debugRow:SetHeight(26)

  local debugCheck = HunterLib.UI.CreateCheckbox(debugRow, "Enable debug messages")
  debugCheck:SetPoint("LEFT", debugRow, "LEFT", 14, 0)

  local actionLine = CreateFrame("Frame", nil, settings)
  actionLine:SetPoint("BOTTOMLEFT", settings, "BOTTOMLEFT", 18, 18)
  actionLine:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -18, 18)
  actionLine:SetHeight(30)

  local saveButton = HunterLib.UI.CreateButton(actionLine, 160, 28, "Save Settings")
  saveButton:SetPoint("LEFT", actionLine, "LEFT", 0, 0)
  saveButton.isActive = 1
  HunterLib.UI.SetButtonState(saveButton, "active")

  local statusText = HunterLib.UI.CreateSmallText(actionLine, "", "LEFT", saveButton, "RIGHT", 14, 0)
  statusText:SetWidth(380)

  local lower = CreateFrame("Frame", nil, panel)
  lower:SetPoint("TOPLEFT", settings, "BOTTOMLEFT", 0, -14)
  lower:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 18)
  HunterLib.UI.ApplyInsetStyle(lower)
  HunterLib.UI.CreateLabel(lower, "Timing overview", "TOPLEFT", lower, "TOPLEFT", 14, -12)

  local hint = HunterLib.UI.CreateSmallText(lower,
    "This area is temporarily simplified while the live timing readout is being redesigned.",
    "TOPLEFT", lower, "TOPLEFT", 16, -42)
  hint:SetWidth(720)
  hint:SetTextColor(0.82, 0.82, 0.88, 1)

  local note = CreateFrame("Frame", nil, lower)
  note:SetPoint("TOPLEFT", lower, "TOPLEFT", 16, -72)
  note:SetPoint("TOPRIGHT", lower, "TOPRIGHT", -16, -72)
  note:SetHeight(58)
  HunterLib.UI.ApplySoftInsetStyle(note)

  local noteText = HunterLib.UI.CreateSmallText(note,
    "A new live timing panel will return here in a later pass.",
    "LEFT", note, "LEFT", 12, 0)
  noteText:SetWidth(680)
  noteText:SetTextColor(0.76, 0.76, 0.82, 1)

  local function refresh()
    local db = HunterLib.GetDB()
    castRow.box:SetText(string.format("%.2f", db.steady.castTime or 1.40))
    marginRow.box:SetText(string.format("%.2f", db.steady.safetyMargin or 0.40))
    debugCheck:SetChecked(db.debug and 1 or nil)
    statusText:SetText("")
  end

  saveButton:SetScript("OnClick", function()
    local cast = tonumber(castRow.box:GetText()) or 1.40
    local margin = tonumber(marginRow.box:GetText()) or 0.40
    HunterLib.SetConfigValue("steady", "castTime", cast)
    HunterLib.SetConfigValue("steady", "safetyMargin", margin)
    HunterLib.SetConfigValue("debug", nil, debugCheck:GetChecked() and true or false)
    statusText:SetText("Settings saved.")
  end)

  castRow.box:SetScript("OnEnterPressed", function() saveButton:Click() this:ClearFocus() end)
  marginRow.box:SetScript("OnEnterPressed", function() saveButton:Click() this:ClearFocus() end)

  panel:SetScript("OnShow", refresh)
  panel.Refresh = refresh
  return panel
end

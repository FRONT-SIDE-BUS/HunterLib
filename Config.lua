local function HL_InitDB()
  if not HunterLibDB then HunterLibDB = {} end
  if not HunterLibDB.steadyCastTime then HunterLibDB.steadyCastTime = 1.40 end
  if not HunterLibDB.steadySafetyMargin then HunterLibDB.steadySafetyMargin = 0.40 end
  if HunterLibDB.debug == nil then HunterLibDB.debug = true end
  if not HunterLibDB.savedBuffs then HunterLibDB.savedBuffs = {} end
  if not HunterLibDB.capturedBuffs then HunterLibDB.capturedBuffs = {} end
end

local function HL_Round(v)
  return math.floor(v * 100 + 0.5) / 100
end

local function HL_Clamp(v, minv, maxv)
  if v < minv then return minv end
  if v > maxv then return maxv end
  return v
end

local function HL_CreateBackdrop(frame, r, g, b, a)
  if not frame then return end
  if not frame.SetBackdrop then return end

  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  frame:SetBackdropColor(r or .06, g or .06, b or .06, a or .96)
  frame:SetBackdropBorderColor(.35, .35, .35, 1)
end

local function HL_SkinFrame(frame)
  HL_CreateBackdrop(frame, .05, .05, .05, .96)
end

local function HL_SkinEditBox(edit)
  edit:SetAutoFocus(nil)
  edit:SetFontObject(ChatFontNormal)
  edit:SetHeight(20)
end

local function HL_CreateButton(parent, text, w, h)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(w or 60)
  btn:SetHeight(h or 20)

  HL_CreateBackdrop(btn, .10, .10, .10, .98)

  btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
  btn.text:SetText(text or "")
  btn.text:SetTextColor(.90, .90, .90)

  btn.disabled = nil

  function btn:SetText(t)
    self.text:SetText(t or "")
  end

  function btn:SetDisabled(state)
    self.disabled = state
    if state then
      self:SetBackdropColor(.07, .07, .07, .98)
      self:SetBackdropBorderColor(.20, .20, .20, 1)
      self.text:SetTextColor(.45, .45, .45)
    else
      self:SetBackdropColor(.10, .10, .10, .98)
      self:SetBackdropBorderColor(.35, .35, .35, 1)
      self.text:SetTextColor(.90, .90, .90)
    end
  end

  btn:SetScript("OnEnter", function()
    if this.disabled then return end
    this:SetBackdropColor(.16, .16, .16, .98)
    this.text:SetTextColor(1, .82, 0)
  end)

  btn:SetScript("OnLeave", function()
    if this.disabled then return end
    this:SetBackdropColor(.10, .10, .10, .98)
    this.text:SetTextColor(.90, .90, .90)
  end)

  btn:SetScript("OnMouseDown", function()
    if this.disabled then return end
    this:SetBackdropColor(.04, .04, .04, .98)
  end)

  btn:SetScript("OnMouseUp", function()
    if this.disabled then return end
    this:SetBackdropColor(.16, .16, .16, .98)
  end)

  return btn
end

local function HL_CreateCloseButton(parent)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(18)
  btn:SetHeight(18)

  HL_CreateBackdrop(btn, .10, .10, .10, 1)

  btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  btn.text:SetPoint("CENTER", 0, 0)
  btn.text:SetText("x")
  btn.text:SetTextColor(.8, .8, .8)

  btn:SetScript("OnEnter", function()
    this:SetBackdropColor(.25, .10, .10, 1)
    this.text:SetTextColor(1, .2, .2)
  end)

  btn:SetScript("OnLeave", function()
    this:SetBackdropColor(.10, .10, .10, 1)
    this.text:SetTextColor(.8, .8, .8)
  end)

  btn:SetScript("OnClick", function()
    parent:Hide()
  end)

  return btn
end

local function HL_CreateCheckbox(parent, label)
  local cb = CreateFrame("Button", nil, parent)
  cb:SetWidth(16)
  cb:SetHeight(16)

  HL_CreateBackdrop(cb, .08, .08, .08, 1)

  cb.checked = nil

  cb.check = cb:CreateTexture(nil, "ARTWORK")
  cb.check:SetAllPoints(cb)
  cb.check:SetTexture(1, .82, 0, .8)
  cb.check:Hide()

  cb.label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  cb.label:SetText(label or "")

  function cb:SetCheckedState(state)
    self.checked = state and 1 or nil
    if self.checked then
      self.check:Show()
    else
      self.check:Hide()
    end
  end

  cb:SetScript("OnClick", function()
    this:SetCheckedState(not this.checked)
    if this.OnValueChanged then
      this:OnValueChanged(this.checked)
    end
  end)

  return cb
end

local function HL_CreateTab(parent, text, w)
  local btn = HL_CreateButton(parent, text, w or 70, 20)
  btn.active = nil

  function btn:SetActive(active)
    self.active = active
    if active then
      self:SetBackdropColor(.18, .18, .18, .98)
      self:SetBackdropBorderColor(.75, .60, .15, 1)
      self.text:SetTextColor(1, .82, 0)
    else
      self:SetBackdropColor(.10, .10, .10, .98)
      self:SetBackdropBorderColor(.35, .35, .35, 1)
      self.text:SetTextColor(.85, .85, .85)
    end
  end

  return btn
end

local function HL_Separator(parent, y)
  local sep = parent:CreateTexture(nil, "ARTWORK")
  sep:SetHeight(1)
  sep:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
  sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
  sep:SetTexture(.3, .3, .3, .6)
  return sep
end

local function HL_CreateListRow(parent, y)
  local row = CreateFrame("Button", nil, parent)
  row:SetWidth(680)
  row:SetHeight(20)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints(row)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetWidth(16)
  row.icon:SetHeight(16)
  row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)

  row.id = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.id:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
  row.id:SetWidth(50)
  row.id:SetJustifyH("LEFT")

  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.name:SetPoint("LEFT", row.id, "RIGHT", 10, 0)
  row.name:SetWidth(240)
  row.name:SetJustifyH("LEFT")

  row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.pct:SetPoint("LEFT", row.name, "RIGHT", 16, 0)
  row.pct:SetWidth(40)
  row.pct:SetJustifyH("LEFT")

  row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.status:SetPoint("LEFT", row.pct, "RIGHT", 20, 0)
  row.status:SetWidth(160)
  row.status:SetJustifyH("LEFT")

  row.selected = nil
  row.tooltipText = nil

  row:SetScript("OnEnter", function()
    if not this.selected then
      this.bg:SetTexture(1, 1, 1, .05)
    end

    if this.tooltipText then
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:AddLine(this.tooltipText.title or "Buff")
      if this.tooltipText.line1 then GameTooltip:AddLine(this.tooltipText.line1, 1, 1, 1) end
      if this.tooltipText.line2 then GameTooltip:AddLine(this.tooltipText.line2, .8, .8, .8) end
      if this.tooltipText.line3 then GameTooltip:AddLine(this.tooltipText.line3, .8, .8, .8) end
      GameTooltip:Show()
    end
  end)

  row:SetScript("OnLeave", function()
    if not this.selected then
      this.bg:SetTexture(1, 1, 1, .02)
    end
    GameTooltip:Hide()
  end)

  return row
end

local f = CreateFrame("Frame", "HunterLibConfigFrame", UIParent)
f:SetWidth(760)
f:SetHeight(400)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() this:StartMoving() end)
f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
f:SetFrameStrata("DIALOG")
f:SetToplevel(true)
HL_SkinFrame(f)
f:Hide()

f.currentTab = "steady"
f.selectedIndex = nil
f.selectedEntry = nil
f.buffEntries = {}
f.filterMode = "all"

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
f.title:SetText("HunterLib")

f.close = HL_CreateCloseButton(f)
f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

f.steadyTab = HL_CreateTab(f, "Steady", 72)
f.steadyTab:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -34)

f.buffsTab = HL_CreateTab(f, "Buffs", 72)
f.buffsTab:SetPoint("LEFT", f.steadyTab, "RIGHT", 4, 0)

HL_Separator(f, -58)

f.steadyPane = CreateFrame("Frame", nil, f)
f.steadyPane:SetWidth(730)
f.steadyPane:SetHeight(320)
f.steadyPane:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -62)

f.buffsPane = CreateFrame("Frame", nil, f)
f.buffsPane:SetWidth(730)
f.buffsPane:SetHeight(320)
f.buffsPane:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -62)
f.buffsPane:Hide()

function f:SwitchTab(tab)
  self.currentTab = tab

  if tab == "steady" then
    self.steadyPane:Show()
    self.buffsPane:Hide()
    self.steadyTab:SetActive(1)
    self.buffsTab:SetActive(nil)
  else
    self.steadyPane:Hide()
    self.buffsPane:Show()
    self.steadyTab:SetActive(nil)
    self.buffsTab:SetActive(1)
  end
end

f.steadyTab:SetScript("OnClick", function() f:SwitchTab("steady") end)
f.buffsTab:SetScript("OnClick", function() f:SwitchTab("buffs") end)

-- steady pane omitted unchanged behavior
local function MakeInlineRow(parent, y, labelText)
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(700)
  row:SetHeight(22)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.label:SetWidth(120)
  row.label:SetJustifyH("LEFT")
  row.label:SetText(labelText)

  row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.value:SetPoint("LEFT", row.label, "RIGHT", 8, 0)
  row.value:SetWidth(60)
  row.value:SetJustifyH("LEFT")

  row.mf = HL_CreateButton(row, "-0.01", 48, 18)
  row.mf:SetPoint("LEFT", row.value, "RIGHT", 8, 0)

  row.pf = HL_CreateButton(row, "+0.01", 48, 18)
  row.pf:SetPoint("LEFT", row.mf, "RIGHT", 4, 0)

  row.mc = HL_CreateButton(row, "-0.05", 48, 18)
  row.mc:SetPoint("LEFT", row.pf, "RIGHT", 8, 0)

  row.pc = HL_CreateButton(row, "+0.05", 48, 18)
  row.pc:SetPoint("LEFT", row.mc, "RIGHT", 4, 0)

  return row
end

f.steadyPane.head = f.steadyPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.steadyPane.head:SetPoint("TOPLEFT", f.steadyPane, "TOPLEFT", 0, 0)
f.steadyPane.head:SetText("Steady Shot Settings")

f.castRow = MakeInlineRow(f.steadyPane, -36, "Cast Time")
f.marginRow = MakeInlineRow(f.steadyPane, -64, "Safety Margin")

f.debug = HL_CreateCheckbox(f.steadyPane, "Debug")
f.debug:SetPoint("TOPLEFT", f.steadyPane, "TOPLEFT", 0, -98)
f.debug.OnValueChanged = function(self, state)
  HunterLibDB.debug = state and true or nil
  HunterLib.Auto.debug = HunterLibDB.debug and true or nil
end

f.resetBtn = HL_CreateButton(f.steadyPane, "Reset", 80, 20)
f.resetBtn:SetPoint("TOPLEFT", f.steadyPane, "TOPLEFT", 0, -132)
f.resetBtn:SetScript("OnClick", function()
  HunterLibDB.steadyCastTime = 1.40
  HunterLibDB.steadySafetyMargin = 0.40
  f:RefreshSteady()
end)

f.steadyHelp = f.steadyPane:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.steadyHelp:SetPoint("TOPLEFT", f.resetBtn, "BOTTOMLEFT", 0, -14)
f.steadyHelp:SetWidth(420)
f.steadyHelp:SetJustifyH("LEFT")
f.steadyHelp:SetText("Use the Buffs tab to capture, review, and save tracked haste buffs.")

function f:RefreshSteady()
  HL_InitDB()
  self.castRow.value:SetText(string.format("%.2f", HunterLibDB.steadyCastTime))
  self.marginRow.value:SetText(string.format("%.2f", HunterLibDB.steadySafetyMargin))
  self.debug:SetCheckedState(HunterLibDB.debug and 1 or nil)
  HunterLib.Auto.debug = HunterLibDB.debug and true or nil
end

f.castRow.mf:SetScript("OnClick", function()
  HunterLibDB.steadyCastTime = HL_Clamp(HL_Round(HunterLibDB.steadyCastTime - 0.01), 0.50, 3.00)
  f:RefreshSteady()
end)
f.castRow.pf:SetScript("OnClick", function()
  HunterLibDB.steadyCastTime = HL_Clamp(HL_Round(HunterLibDB.steadyCastTime + 0.01), 0.50, 3.00)
  f:RefreshSteady()
end)
f.castRow.mc:SetScript("OnClick", function()
  HunterLibDB.steadyCastTime = HL_Clamp(HL_Round(HunterLibDB.steadyCastTime - 0.05), 0.50, 3.00)
  f:RefreshSteady()
end)
f.castRow.pc:SetScript("OnClick", function()
  HunterLibDB.steadyCastTime = HL_Clamp(HL_Round(HunterLibDB.steadyCastTime + 0.05), 0.50, 3.00)
  f:RefreshSteady()
end)

f.marginRow.mf:SetScript("OnClick", function()
  HunterLibDB.steadySafetyMargin = HL_Clamp(HL_Round(HunterLibDB.steadySafetyMargin - 0.01), 0.00, 1.50)
  f:RefreshSteady()
end)
f.marginRow.pf:SetScript("OnClick", function()
  HunterLibDB.steadySafetyMargin = HL_Clamp(HL_Round(HunterLibDB.steadySafetyMargin + 0.01), 0.00, 1.50)
  f:RefreshSteady()
end)
f.marginRow.mc:SetScript("OnClick", function()
  HunterLibDB.steadySafetyMargin = HL_Clamp(HL_Round(HunterLibDB.steadySafetyMargin - 0.05), 0.00, 1.50)
  f:RefreshSteady()
end)
f.marginRow.pc:SetScript("OnClick", function()
  HunterLibDB.steadySafetyMargin = HL_Clamp(HL_Round(HunterLibDB.steadySafetyMargin + 0.05), 0.00, 1.50)
  f:RefreshSteady()
end)

-- buffs toolbar
f.buffsPane.head = f.buffsPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.buffsPane.head:SetPoint("TOPLEFT", f.buffsPane, "TOPLEFT", 0, 0)
f.buffsPane.head:SetText("Buff Library")

f.captureBtn = HL_CreateButton(f.buffsPane, "Capture", 60, 20)
f.captureBtn:SetPoint("TOPLEFT", f.buffsPane, "TOPLEFT", 0, -26)

f.saveBtn = HL_CreateButton(f.buffsPane, "Save", 60, 20)
f.saveBtn:SetPoint("LEFT", f.captureBtn, "RIGHT", 2, 0)

f.deleteBtn = HL_CreateButton(f.buffsPane, "Delete", 60, 20)
f.deleteBtn:SetPoint("LEFT", f.saveBtn, "RIGHT", 2, 0)

f.toggleBtn = HL_CreateButton(f.buffsPane, "Toggle", 60, 20)
f.toggleBtn:SetPoint("LEFT", f.deleteBtn, "RIGHT", 2, 0)

f.filterAllBtn = HL_CreateButton(f.buffsPane, "All", 44, 20)
f.filterAllBtn:SetPoint("LEFT", f.toggleBtn, "RIGHT", 12, 0)

f.filterCandBtn = HL_CreateButton(f.buffsPane, "Candidates", 78, 20)
f.filterCandBtn:SetPoint("LEFT", f.filterAllBtn, "RIGHT", 2, 0)

f.filterSavedBtn = HL_CreateButton(f.buffsPane, "Saved", 52, 20)
f.filterSavedBtn:SetPoint("LEFT", f.filterCandBtn, "RIGHT", 2, 0)

f.exportBtn = HL_CreateButton(f.buffsPane, "Export", 60, 20)
f.exportBtn:SetPoint("TOPRIGHT", f.buffsPane, "TOPRIGHT", -62, -26)

f.importBtn = HL_CreateButton(f.buffsPane, "Import", 60, 20)
f.importBtn:SetPoint("LEFT", f.exportBtn, "RIGHT", 2, 0)

f.captureBtn:SetScript("OnClick", function()
  if HunterLib.CaptureCurrentPlayerBuffs then
    HunterLib.CaptureCurrentPlayerBuffs()
    f:RefreshBuffs()
  end
end)

f.saveBtn:SetScript("OnClick", function()
  if f.saveBtn.disabled then return end
  if not f.selectedEntry then return end

  local id = f.selectedEntry.id
  local name = f.editorName:GetText()
  local pct = f.editorPercent:GetText()

  if f.selectedEntry.status == "captured" then
    HunterLib.UpdateCaptured(id, name, pct)
    HunterLib.SaveCapturedBuff(id)
  else
    HunterLib.UpdateSavedBuff(id, name, pct)
  end

  f.selectedIndex = nil
  f.selectedEntry = nil
  f:RefreshBuffs()
end)

f.deleteBtn:SetScript("OnClick", function()
  if not f.selectedEntry then return end

  if f.selectedEntry.status == "captured" then
    HunterLib.DeleteCapturedBuff(f.selectedEntry.id)
  else
    HunterLib.DeleteSavedBuff(f.selectedEntry.id)
  end

  f.selectedIndex = nil
  f.selectedEntry = nil
  f:RefreshBuffs()
end)

f.toggleBtn:SetScript("OnClick", function()
  if not f.selectedEntry then return end
  if f.selectedEntry.status == "saved" then
    HunterLib.ToggleSavedBuff(f.selectedEntry.id)
    f:RefreshBuffs()
  end
end)

f.filterAllBtn:SetScript("OnClick", function()
  f.filterMode = "all"
  f.selectedIndex = nil
  f.selectedEntry = nil
  f:RefreshBuffs()
end)

f.filterCandBtn:SetScript("OnClick", function()
  f.filterMode = "candidates"
  f.selectedIndex = nil
  f.selectedEntry = nil
  f:RefreshBuffs()
end)

f.filterSavedBtn:SetScript("OnClick", function()
  f.filterMode = "saved"
  f.selectedIndex = nil
  f.selectedEntry = nil
  f:RefreshBuffs()
end)

-- popup
local popup = CreateFrame("Frame", "HunterLibToolsPopup", UIParent)
popup:SetWidth(500)
popup:SetHeight(120)
popup:SetPoint("CENTER", UIParent, "CENTER", 60, 20)
popup:SetMovable(true)
popup:EnableMouse(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", function() this:StartMoving() end)
popup:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
popup:SetFrameStrata("FULLSCREEN_DIALOG")
popup:SetToplevel(true)
HL_SkinFrame(popup)
popup:Hide()

popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
popup.title:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -10)
popup.title:SetText("HunterLib Tools")

popup.close = HL_CreateCloseButton(popup)
popup.close:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -6, -6)

popup.label = popup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
popup.label:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -32)
popup.label:SetText("Export or paste import data below")

popup.box = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
popup.box:SetWidth(472)
popup.box:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -52)
HL_SkinEditBox(popup.box)

popup.info = popup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
popup.info:SetPoint("TOPLEFT", popup.box, "BOTTOMLEFT", 0, -8)
popup.info:SetWidth(472)
popup.info:SetJustifyH("LEFT")
popup.info:SetText("")

popup.export = HL_CreateButton(popup, "Export Current", 100, 20)
popup.export:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 12, 10)

popup.import = HL_CreateButton(popup, "Import Data", 90, 20)
popup.import:SetPoint("LEFT", popup.export, "RIGHT", 4, 0)

popup.clear = HL_CreateButton(popup, "Clear", 60, 20)
popup.clear:SetPoint("LEFT", popup.import, "RIGHT", 4, 0)

local function HL_ShowPopup()
  popup:SetFrameLevel(f:GetFrameLevel() + 20)
  popup:Show()
  popup:Raise()
end

popup.export:SetScript("OnClick", function()
  local data = HunterLib.ExportSavedBuffs and HunterLib.ExportSavedBuffs() or ""
  popup.box:SetText(data)
  popup.info:SetText("Exported "..tostring(string.len(data or "")).." chars")
end)

popup.import:SetScript("OnClick", function()
  local str = popup.box:GetText()
  if str and str ~= "" and HunterLib.ImportSavedBuffs then
    local n = HunterLib.ImportSavedBuffs(str)
    popup.info:SetText("Imported "..tostring(n).." buffs")
    f.selectedIndex = nil
    f.selectedEntry = nil
    f:RefreshBuffs()
  end
end)

popup.clear:SetScript("OnClick", function()
  popup.box:SetText("")
  popup.info:SetText("")
end)

f.exportBtn:SetScript("OnClick", function()
  HL_ShowPopup()
  popup.box:SetText(HunterLib.ExportSavedBuffs and HunterLib.ExportSavedBuffs() or "")
  popup.info:SetText("Ready to export")
end)

f.importBtn:SetScript("OnClick", function()
  HL_ShowPopup()
  popup.box:SetText("")
  popup.info:SetText("Paste import data, then click Import Data")
end)

HL_Separator(f.buffsPane, -52)

f.listFrame = CreateFrame("Frame", nil, f.buffsPane)
f.listFrame:SetWidth(720)
f.listFrame:SetHeight(170)
f.listFrame:SetPoint("TOPLEFT", f.buffsPane, "TOPLEFT", 0, -56)
HL_SkinFrame(f.listFrame)

f.headerID = f.listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.headerID:SetPoint("TOPLEFT", f.listFrame, "TOPLEFT", 34, -10)
f.headerID:SetText("ID")

f.headerName = f.listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.headerName:SetPoint("TOPLEFT", f.listFrame, "TOPLEFT", 90, -10)
f.headerName:SetText("Name")

f.headerPct = f.listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.headerPct:SetPoint("TOPLEFT", f.listFrame, "TOPLEFT", 350, -10)
f.headerPct:SetText("%")

f.headerStatus = f.listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.headerStatus:SetPoint("TOPLEFT", f.listFrame, "TOPLEFT", 410, -10)
f.headerStatus:SetText("Status")

f.rows = {}
f.visibleRows = 7

local function HL_RowOnClick()
  local idx = this.index
  f.selectedIndex = idx
  f.selectedEntry = f.buffEntries[idx]
  f:RefreshBuffs()
end

for i = 1, f.visibleRows do
  local row = HL_CreateListRow(f.listFrame, -28 - (i-1)*20)
  row.index = i
  row:RegisterForClicks("LeftButtonUp")
  row:SetScript("OnClick", HL_RowOnClick)
  f.rows[i] = row
end

f.scroll = CreateFrame("ScrollFrame", "HunterLibBuffScrollFrame", f.listFrame, "FauxScrollFrameTemplate")
f.scroll:SetPoint("TOPRIGHT", f.listFrame, "TOPRIGHT", -26, -24)
f.scroll:SetPoint("BOTTOMRIGHT", f.listFrame, "BOTTOMRIGHT", -6, 8)
f.scroll:SetScript("OnVerticalScroll", function()
  FauxScrollFrame_OnVerticalScroll(20, function()
    f:RefreshBuffs()
  end)
end)

if _G["HunterLibBuffScrollFrameScrollUpButton"] then
  HL_CreateBackdrop(_G["HunterLibBuffScrollFrameScrollUpButton"], .10, .10, .10, .98)
end

if _G["HunterLibBuffScrollFrameScrollDownButton"] then
  HL_CreateBackdrop(_G["HunterLibBuffScrollFrameScrollDownButton"], .10, .10, .10, .98)
end

f.editor = CreateFrame("Frame", nil, f.buffsPane)
f.editor:SetWidth(720)
f.editor:SetHeight(82)
f.editor:SetPoint("TOPLEFT", f.listFrame, "BOTTOMLEFT", 0, -10)
HL_SkinFrame(f.editor)

f.editorTitle = f.editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.editorTitle:SetPoint("TOPLEFT", f.editor, "TOPLEFT", 10, -10)
f.editorTitle:SetText("Selected Buff")

f.editorStatus = f.editor:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.editorStatus:SetPoint("TOPLEFT", f.editorTitle, "BOTTOMLEFT", 0, -4)
f.editorStatus:SetWidth(420)
f.editorStatus:SetJustifyH("LEFT")
f.editorStatus:SetText("No selection")

f.editorNameLabel = f.editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
f.editorNameLabel:SetPoint("TOPLEFT", f.editor, "TOPLEFT", 10, -42)
f.editorNameLabel:SetText("Name")

f.editorName = CreateFrame("EditBox", nil, f.editor, "InputBoxTemplate")
f.editorName:SetWidth(220)
f.editorName:SetPoint("LEFT", f.editorNameLabel, "RIGHT", 10, 0)
HL_SkinEditBox(f.editorName)

f.editorPctLabel = f.editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
f.editorPctLabel:SetPoint("LEFT", f.editorName, "RIGHT", 20, 0)
f.editorPctLabel:SetText("Speed %")

f.editorPercent = CreateFrame("EditBox", nil, f.editor, "InputBoxTemplate")
f.editorPercent:SetWidth(60)
f.editorPercent:SetPoint("LEFT", f.editorPctLabel, "RIGHT", 10, 0)
HL_SkinEditBox(f.editorPercent)

f.preview = f.editor:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
f.preview:SetPoint("TOPLEFT", f.editor, "TOPLEFT", 10, -64)
f.preview:SetWidth(680)
f.preview:SetJustifyH("LEFT")
f.preview:SetText("Preview: ---")

f.editorName:SetScript("OnTextChanged", function()
  local name = this:GetText() or ""
  f.preview:SetText("Preview: "..name)
  f:UpdateSaveState()
end)

f.editorPercent:SetScript("OnTextChanged", function()
  f:UpdateSaveState()
end)

function f:UpdateSaveState()
  if not self.selectedEntry then
    self.saveBtn:SetDisabled(1)
    return
  end

  local pct = tonumber(self.editorPercent:GetText())
  if pct == nil then
    self.saveBtn:SetDisabled(1)
    return
  end

  if self.selectedEntry.status == "captured" and self.editorName:GetText() == "" then
    self.saveBtn:SetDisabled(1)
    return
  end

  self.saveBtn:SetDisabled(nil)
end

function f:RefreshBuffs()
  local entries = HunterLib.GetMergedBuffEntries and HunterLib.GetMergedBuffEntries(self.filterMode) or {}
  local offset = FauxScrollFrame_GetOffset(self.scroll)

  self.buffEntries = entries
  FauxScrollFrame_Update(self.scroll, table.getn(entries), self.visibleRows, 20)

  self.filterAllBtn:SetDisabled(self.filterMode == "all")
  self.filterCandBtn:SetDisabled(self.filterMode == "candidates")
  self.filterSavedBtn:SetDisabled(self.filterMode == "saved")

  for i = 1, self.visibleRows do
    local data = entries[offset + i]
    local row = self.rows[i]

    row.selected = nil
    row.tooltipText = nil

    if data then
      row.index = offset + i
      row.icon:SetTexture(data.texture or "")
      row.id:SetText(tostring(data.id))
      row.name:SetText((data.name and data.name ~= "") and data.name or ("Buff "..tostring(data.id)))
      row.pct:SetText(tostring(data.percent or 0).."%")

      if data.status == "captured" then
        if data.candidate then
          row.status:SetText("captured / candidate")
          row.status:SetTextColor(1, .82, 0)
        else
          row.status:SetText("captured")
          row.status:SetTextColor(.75, .75, .75)
        end
      else
        if data.active then
          row.status:SetText("saved / active")
          row.status:SetTextColor(.2, 1, .2)
        elseif data.enabled then
          row.status:SetText("saved / enabled")
          row.status:SetTextColor(.45, 1, .45)
        else
          row.status:SetText("saved / disabled")
          row.status:SetTextColor(1, .45, .45)
        end
      end

      row.tooltipText = {
        title = (data.name and data.name ~= "") and data.name or tostring(data.id),
        line1 = "Buff ID: "..tostring(data.id),
        line2 = "Speed: "..tostring(data.percent or 0).."%",
        line3 = "Status: "..data.status
      }

      if self.selectedIndex == offset + i then
        row.selected = 1
        row.bg:SetTexture(1, .82, 0, .22)
      else
        if math.mod(offset + i, 2) == 0 then
          row.bg:SetTexture(1, 1, 1, .02)
        else
          row.bg:SetTexture(1, 1, 1, .04)
        end
      end

      row:Show()
    else
      row:Hide()
    end
  end

  if self.selectedEntry then
    local found = nil
    for i = 1, table.getn(entries) do
      if entries[i].id == self.selectedEntry.id and entries[i].status == self.selectedEntry.status then
        found = entries[i]
        break
      end
    end
    self.selectedEntry = found
  end

  if self.selectedEntry then
    local statusText = self.selectedEntry.status
    if self.selectedEntry.status == "saved" then
      if self.selectedEntry.enabled then
        statusText = "saved / enabled"
      else
        statusText = "saved / disabled"
      end
      if self.selectedEntry.active then
        statusText = "saved / active"
      end
    elseif self.selectedEntry.candidate then
      statusText = "captured / candidate"
    end

    self.editorStatus:SetText("ID "..self.selectedEntry.id.." / "..statusText)
    self.editorName:SetText(self.selectedEntry.name or "")
    self.editorPercent:SetText(tostring(self.selectedEntry.percent or 0))
  else
    self.editorStatus:SetText("No selection")
    self.editorName:SetText("")
    self.editorPercent:SetText("")
  end

  self:UpdateSaveState()
end

function HunterLib.OpenConfig(tab)
  HL_InitDB()
  if HunterLib.BuffTrackerInit then
    HunterLib.BuffTrackerInit()
  end

  f:RefreshSteady()
  f:RefreshBuffs()

  if tab == "buffs" then
    f:SwitchTab("buffs")
  else
    f:SwitchTab("steady")
  end

  f:Raise()
  f:Show()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
  HL_InitDB()
  if HunterLib.BuffTrackerInit then
    HunterLib.BuffTrackerInit()
  end
  f:RefreshSteady()
  f:RefreshBuffs()
  f:SwitchTab("steady")
end)

SLASH_HUNTERLIB1 = "/hl"
SLASH_HUNTERLIB2 = "/hunterlib"
SlashCmdList["HUNTERLIB"] = function()
  if f:IsShown() then
    f:Hide()
  else
    HunterLib.OpenConfig("steady")
  end
end
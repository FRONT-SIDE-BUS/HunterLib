local colors = HunterLib.UI.Colors or {}

local function setColor(fs, color)
  if fs and fs.SetTextColor and color then
    fs:SetTextColor(color[1], color[2], color[3], color[4])
  end
end

function HunterLib.UI.CreateTitle(parent, text, point, rel, relPoint, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  fs:SetPoint(point, rel or parent, relPoint or point, x or 0, y or 0)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  setColor(fs, colors.gold)
  return fs
end

function HunterLib.UI.CreateLabel(parent, text, point, rel, relPoint, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint(point, rel or parent, relPoint or point, x or 0, y or 0)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  setColor(fs, colors.gold)
  return fs
end

function HunterLib.UI.CreateText(parent, text, point, rel, relPoint, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint(point, rel or parent, relPoint or point, x or 0, y or 0)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  setColor(fs, colors.text)
  return fs
end

function HunterLib.UI.CreateSmallText(parent, text, point, rel, relPoint, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint(point, rel or parent, relPoint or point, x or 0, y or 0)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  setColor(fs, colors.muted)
  return fs
end

function HunterLib.UI.CreateDivider(parent, offsetY)
  local line = parent:CreateTexture(nil, "BORDER")
  line:SetTexture(1, 1, 1, 0.10)
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, offsetY or 0)
  line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, offsetY or 0)
  line:SetHeight(1)
  return line
end

function HunterLib.UI.CreateButton(parent, width, height, text)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(width or 120)
  btn:SetHeight(height or 24)
  HunterLib.UI.ApplyButtonStyle(btn)

  local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
  fs:SetText(text or "Button")
  btn.text = fs
  HunterLib.UI.SetButtonState(btn, "normal")

  btn:SetScript("OnEnter", function()
    if not this.isActive then
      HunterLib.UI.SetButtonState(this, "hover")
    end
  end)
  btn:SetScript("OnLeave", function()
    if this.isActive then
      HunterLib.UI.SetButtonState(this, "active")
    else
      HunterLib.UI.SetButtonState(this, "normal")
    end
  end)

  function btn:SetText(value)
    self.text:SetText(value or "")
  end

  return btn
end

function HunterLib.UI.CreateEditBox(parent, width, height, numeric)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetWidth(width or 100)
  holder:SetHeight(height or 24)
  holder:SetFrameLevel((parent:GetFrameLevel() or 1) + 1)
  HunterLib.UI.ApplySoftInsetStyle(holder)

  local box = CreateFrame("EditBox", nil, holder)
  box:SetPoint("TOPLEFT", holder, "TOPLEFT", 6, -4)
  box:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -6, 4)
  box:SetAutoFocus(false)
  box:SetFontObject("GameFontHighlightSmall")
  box:SetJustifyH("CENTER")
  box:SetTextInsets(0, 0, 0, 0)
  box:SetFrameLevel(holder:GetFrameLevel() + 1)
  box:SetTextColor(colors.value[1], colors.value[2], colors.value[3], colors.value[4])
  box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  box:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  box:SetScript("OnEditFocusGained", function() this:HighlightText() end)
  if numeric then box:SetNumeric(true) end

  holder.editBox = box
  box.holder = holder
  return box
end

function HunterLib.UI.CreateCheckbox(parent, text)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  setColor(fs, colors.text)
  cb.label = fs
  return cb
end

function HunterLib.UI.CreateStatusPill(parent, width)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetWidth(width or 110)
  frame:SetHeight(18)
  HunterLib.UI.ApplySoftInsetStyle(frame)

  local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("CENTER", frame, "CENTER", 0, 0)
  setColor(fs, colors.muted)
  frame.text = fs
  return frame
end

function HunterLib.UI.CreateSectionCard(parent, titleText, x, y, h)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 16, y or -16)
  frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, y or -16)
  if h then frame:SetHeight(h) end
  HunterLib.UI.ApplyInsetStyle(frame)
  frame.title = HunterLib.UI.CreateLabel(frame, titleText or "", "TOPLEFT", frame, "TOPLEFT", 14, -12)
  return frame
end

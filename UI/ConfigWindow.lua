SLASH_HUNTERLIB1 = "/hunterlib"
SLASH_HUNTERLIB2 = "/hl"

local function setActiveButton(button, active)
  button.isActive = active and 1 or nil
  HunterLib.UI.SetButtonState(button, active and "active" or "normal")
end

local function showTab(frame, tabName)
  HunterLib.State.activeTab = tabName
  HunterLib.GetDB().config.activeTab = tabName
  frame.currentTab = tabName

  frame.steadyTab:Hide()
  frame.buffsTab:Hide()

  setActiveButton(frame.navButtons.steady, nil)
  setActiveButton(frame.navButtons.buffs, nil)

  if tabName == "buffs" then
    frame.buffsTab:Show()
    frame.buffsTab:Refresh()
    setActiveButton(frame.navButtons.buffs, 1)
    frame.footerText:SetText("Capture buffs, clean the list, and save only the haste effects you actually want to track.")
  else
    frame.steadyTab:Show()
    frame.steadyTab:Refresh()
    setActiveButton(frame.navButtons.steady, 1)
    frame.footerText:SetText("Adjust Steady Shot timing and keep the addon configuration simple and readable.")
  end
end

local function saveWindowPosition(frame)
  local point, _, relativePoint, x, y = frame:GetPoint()
  local db = HunterLib.GetDB()
  db.config.point = point
  db.config.relativePoint = relativePoint
  db.config.x = x
  db.config.y = y
end

function HunterLib.OpenConfig(tabName)
  if not HunterLib.UI.ConfigFrame then HunterLib.UI.CreateConfigWindow() end
  HunterLib.UI.ConfigFrame:Show()
  showTab(HunterLib.UI.ConfigFrame, tabName or HunterLib.GetDB().config.activeTab or "steady")
end

function HunterLib.UI.ToggleConfig(tabName)
  if not HunterLib.UI.ConfigFrame then HunterLib.UI.CreateConfigWindow() end
  local frame = HunterLib.UI.ConfigFrame
  local targetTab = tabName or HunterLib.GetDB().config.activeTab or "steady"

  if frame:IsShown() and (not tabName or frame.currentTab == targetTab) then
    frame:Hide()
  else
    frame:Show()
    showTab(frame, targetTab)
  end
end

function HunterLib.UI.CreateConfigWindow()
  if HunterLib.UI.ConfigFrame then return HunterLib.UI.ConfigFrame end

  local db = HunterLib.GetDB()
  local frame = CreateFrame("Frame", "HunterLibConfigFrame", UIParent)
  frame:SetWidth(db.config.width or 860)
  frame:SetHeight(db.config.height or 560)
  frame:SetPoint(db.config.point or "CENTER", UIParent, db.config.relativePoint or "CENTER", db.config.x or 0, db.config.y or 0)
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() saveWindowPosition(this) end)
  HunterLib.UI.ApplyFrameStyle(frame)
  HunterLib.UI.ConfigFrame = frame
  HunterLibConfigFrame = frame

  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  header:SetHeight(54)

  local title = HunterLib.UI.CreateTitle(header, "HunterLib", "TOPLEFT", header, "TOPLEFT", 16, -12)
  local subtitle = HunterLib.UI.CreateSmallText(header, "A compact hunter utility panel styled around pfUI's minimal dark layout.", "TOPLEFT", header, "TOPLEFT", 18, -34)
  subtitle:SetWidth(540)

  local close = HunterLib.UI.CreateButton(header, 22, 22, "X")
  close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -10)
  close:SetScript("OnClick", function() frame:Hide() end)

  local sidebar = CreateFrame("Frame", nil, frame)
  sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
  sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 38)
  sidebar:SetWidth(178)
  HunterLib.UI.ApplyInsetStyle(sidebar)

  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 12, 0)
  content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 38)
  HunterLib.UI.ApplyInsetStyle(content)
  frame.content = content

  local footer = CreateFrame("Frame", nil, frame)
  footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
  footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
  footer:SetHeight(20)
  HunterLib.UI.ApplyInsetStyle(footer)
  frame.footerText = HunterLib.UI.CreateSmallText(footer, "", "LEFT", footer, "LEFT", 10, 0)

  local navTitle = HunterLib.UI.CreateLabel(sidebar, "Sections", "TOPLEFT", sidebar, "TOPLEFT", 14, -14)
  local steadyBtn = HunterLib.UI.CreateButton(sidebar, 146, 26, "Steady Shot")
  steadyBtn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 16, -46)
  local buffsBtn = HunterLib.UI.CreateButton(sidebar, 146, 26, "Buff Tracker")
  buffsBtn:SetPoint("TOPLEFT", steadyBtn, "BOTTOMLEFT", 0, -10)

  local helpBox = CreateFrame("Frame", nil, sidebar)
  helpBox:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 12)
  helpBox:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -12, 12)
  helpBox:SetHeight(150)
  HunterLib.UI.ApplySoftInsetStyle(helpBox)
  local helpTitle = HunterLib.UI.CreateLabel(helpBox, "Quick help", "TOPLEFT", helpBox, "TOPLEFT", 10, -10)
  local helpText = HunterLib.UI.CreateSmallText(helpBox,
    "/hl opens the window.\n\nLeft-click the minimap button for Steady Shot.\nRight-click it for Buff Tracker.",
    "TOPLEFT", helpBox, "TOPLEFT", 10, -32)
  helpText:SetWidth(136)

  frame.navButtons = { steady = steadyBtn, buffs = buffsBtn }
  frame.steadyTab = HunterLib.UI.CreateSteadyTab(frame)
  frame.buffsTab = HunterLib.UI.CreateBuffsTab(frame)
  HunterLib.UI.BuffsTab = frame.buffsTab

  steadyBtn:SetScript("OnClick", function() showTab(frame, "steady") end)
  buffsBtn:SetScript("OnClick", function() showTab(frame, "buffs") end)

  SlashCmdList["HUNTERLIB"] = function(msg)
    local input = string.lower(msg or "")
    if input == "steady" then
      HunterLib.UI.ToggleConfig("steady")
    elseif input == "buffs" then
      HunterLib.UI.ToggleConfig("buffs")
    else
      HunterLib.UI.ToggleConfig()
    end
  end

  SLASH_HUNTERLIB_SHOW1 = "/hlshow"
  SlashCmdList["HUNTERLIB_SHOW"] = function() HunterLib.OpenConfig(HunterLib.GetDB().config.activeTab or "steady") end

  SLASH_HUNTERLIB_HIDE1 = "/hlhide"
  SlashCmdList["HUNTERLIB_HIDE"] = function() if HunterLib.UI.ConfigFrame then HunterLib.UI.ConfigFrame:Hide() end end

  showTab(frame, db.config.activeTab or "steady")
  frame:Hide()
  return frame
end

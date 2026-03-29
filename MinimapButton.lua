local function HL_MinimapInitDB()
  if not HunterLibDB then
    HunterLibDB = {}
  end

  if HunterLibDB.minimapAngle == nil then
    HunterLibDB.minimapAngle = 45
  end

  if HunterLibDB.minimapHidden == nil then
    HunterLibDB.minimapHidden = false
  end
end

local function HL_MinimapSetPosition(btn)
  local angle = HunterLibDB.minimapAngle or 45
  local radius = 78
  local x = math.cos(angle * math.pi / 180) * radius
  local y = math.sin(angle * math.pi / 180) * radius

  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local button = CreateFrame("Button", "HunterLibMinimapButton", Minimap)
button:SetWidth(32)
button:SetHeight(32)
button:SetFrameStrata("MEDIUM")
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:EnableMouse(true)
button:SetMovable(true)
button:SetClampedToScreen(true)

button.border = button:CreateTexture(nil, "OVERLAY")
button.border:SetWidth(53)
button.border:SetHeight(53)
button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
button.border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

button.icon = button:CreateTexture(nil, "BACKGROUND")
button.icon:SetWidth(20)
button.icon:SetHeight(20)
button.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)

button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
button.highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button.highlight:SetBlendMode("ADD")
button.highlight:SetAllPoints(button)

button:SetScript("OnClick", function()
  if arg1 == "LeftButton" then
    if HunterLibConfigFrame:IsShown() and HunterLibConfigFrame.currentTab == "steady" then
      HunterLibConfigFrame:Hide()
    else
      if HunterLib.OpenConfig then
        HunterLib.OpenConfig("steady")
      end
    end
  elseif arg1 == "RightButton" then
    if HunterLibConfigFrame:IsShown() and HunterLibConfigFrame.currentTab == "buffs" then
      HunterLibConfigFrame:Hide()
    else
      if HunterLib.OpenConfig then
        HunterLib.OpenConfig("buffs")
      end
    end
  end
end)

button:SetScript("OnDragStart", function()
  if not IsShiftKeyDown() then return end

  this:SetScript("OnUpdate", function()
    local mx, my = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local px, py = Minimap:GetCenter()

    mx = mx / scale
    my = my / scale

    local angle = math.deg(math.atan2(my - py, mx - px))
    if angle < 0 then angle = angle + 360 end

    HunterLibDB.minimapAngle = angle
    HL_MinimapSetPosition(this)
  end)
end)

button:SetScript("OnDragStop", function()
  this:SetScript("OnUpdate", nil)
end)

button:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:AddLine("HunterLib")
  GameTooltip:AddLine("Left Click: Steady settings", 1, 1, 1)
  GameTooltip:AddLine("Right Click: Buffs", 1, 1, 1)
  GameTooltip:AddLine("Shift + Drag: Move button", 1, 1, 1)
  GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function()
  HL_MinimapInitDB()

  if HunterLibDB.minimapHidden then
    button:Hide()
  else
    button:Show()
    HL_MinimapSetPosition(button)
  end
end)

function HunterLib.ShowMinimapButton()
  HL_MinimapInitDB()
  HunterLibDB.minimapHidden = false
  button:Show()
  HL_MinimapSetPosition(button)
end

function HunterLib.HideMinimapButton()
  HL_MinimapInitDB()
  HunterLibDB.minimapHidden = true
  button:Hide()
end

SLASH_HUNTERLIBSHOW1 = "/hlshow"
SlashCmdList["HUNTERLIBSHOW"] = function()
  HunterLib.ShowMinimapButton()
end

SLASH_HUNTERLIBHIDE1 = "/hlhide"
SlashCmdList["HUNTERLIBHIDE"] = function()
  HunterLib.HideMinimapButton()
end
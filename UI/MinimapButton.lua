local button

local function updatePosition()
    if not button then
        return
    end

    local db = HunterLib.GetDB()
    local angle = db.minimap.angle or 45
    local radius = 78
    local x = math.cos(angle * math.pi / 180) * radius
    local y = math.sin(angle * math.pi / 180) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function HunterLib.ShowMinimapButton()
    local db = HunterLib.GetDB()
    db.minimap.hide = nil
    if button then
        button:Show()
        updatePosition()
    end
end

function HunterLib.HideMinimapButton()
    local db = HunterLib.GetDB()
    db.minimap.hide = 1
    if button then
        button:Hide()
    end
end

function HunterLib.UI.InitMinimapButton()
    if button then
        if HunterLib.GetDB().minimap.hide then
            button:Hide()
        else
            button:Show()
            updatePosition()
        end
        return
    end

    button = CreateFrame("Button", "HunterLibMinimapButton", Minimap)
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
            HunterLib.UI.ToggleConfig("steady")
        elseif arg1 == "RightButton" then
            HunterLib.UI.ToggleConfig("buffs")
        end
    end)

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("HunterLib")
        GameTooltip:AddLine("Left Click: Steady settings", 1, 1, 1)
        GameTooltip:AddLine("Right Click: Buff Tracker", 1, 1, 1)
        GameTooltip:AddLine("Shift + Drag: Move button", 1, 1, 1)
        GameTooltip:AddLine("/hlshow or /hlhide also work", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function()
        if not IsShiftKeyDown() then
            return
        end

        this:SetScript("OnUpdate", function()
            local mx, my = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = Minimap:GetCenter()
            mx = mx / scale
            my = my / scale

            local angle = math.deg(math.atan2(my - cy, mx - cx))
            if angle < 0 then
                angle = angle + 360
            end

            HunterLib.GetDB().minimap.angle = angle
            updatePosition()
        end)
    end)

    button:SetScript("OnDragStop", function()
        this:SetScript("OnUpdate", nil)
    end)

    if HunterLib.GetDB().minimap.hide then
        button:Hide()
    else
        button:Show()
        updatePosition()
    end
end

SLASH_HUNTERLIBSHOW1 = "/hlshow"
SlashCmdList["HUNTERLIBSHOW"] = function()
    HunterLib.ShowMinimapButton()
end

SLASH_HUNTERLIBHIDE1 = "/hlhide"
SlashCmdList["HUNTERLIBHIDE"] = function()
    HunterLib.HideMinimapButton()
end

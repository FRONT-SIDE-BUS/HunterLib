HunterLib.UI.Colors = {
  bg = {0.03, 0.03, 0.04, 0.96},
  panel = {0.05, 0.05, 0.06, 0.94},
  inset = {0.02, 0.02, 0.03, 0.98},
  soft = {0.08, 0.08, 0.10, 0.95},
  button = {0.09, 0.09, 0.11, 0.98},
  buttonHover = {0.12, 0.12, 0.15, 0.98},
  buttonActive = {0.13, 0.10, 0.04, 0.98},
  border = {0.18, 0.18, 0.22, 1},
  borderSoft = {0.11, 0.11, 0.14, 1},
  borderActive = {0.85, 0.66, 0.18, 1},
  gold = {1.00, 0.82, 0.00, 1},
  text = {0.94, 0.94, 0.96, 1},
  muted = {0.68, 0.68, 0.74, 1},
  value = {0.98, 0.98, 1.00, 1},
  green = {0.40, 0.82, 0.46, 1},
  red = {0.88, 0.34, 0.34, 1},
}

local colors = HunterLib.UI.Colors

local function applyBackdrop(frame, fill, edge)
  if not frame or not frame.SetBackdrop then return end

  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })

  local bg = fill or colors.panel
  local border = edge or colors.border
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

function HunterLib.UI.ApplyFrameStyle(frame)
  applyBackdrop(frame, colors.bg, colors.borderSoft)
end

function HunterLib.UI.ApplyPanelStyle(frame)
  applyBackdrop(frame, colors.panel, colors.border)
end

function HunterLib.UI.ApplyInsetStyle(frame)
  applyBackdrop(frame, colors.inset, colors.borderSoft)
end

function HunterLib.UI.ApplySoftInsetStyle(frame)
  applyBackdrop(frame, colors.soft, colors.borderSoft)
end

function HunterLib.UI.ApplyButtonStyle(button)
  applyBackdrop(button, colors.button, colors.border)
end

function HunterLib.UI.SetButtonState(button, state)
  if not button then return end

  local text = button.text or button:GetFontString()
  if state == "active" then
    button:SetBackdropColor(colors.buttonActive[1], colors.buttonActive[2], colors.buttonActive[3], colors.buttonActive[4])
    button:SetBackdropBorderColor(colors.borderActive[1], colors.borderActive[2], colors.borderActive[3], colors.borderActive[4])
    if text then text:SetTextColor(colors.gold[1], colors.gold[2], colors.gold[3], colors.gold[4]) end
  elseif state == "hover" then
    button:SetBackdropColor(colors.buttonHover[1], colors.buttonHover[2], colors.buttonHover[3], colors.buttonHover[4])
    button:SetBackdropBorderColor(colors.borderActive[1], colors.borderActive[2], colors.borderActive[3], colors.borderActive[4])
    if text then text:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4]) end
  else
    button:SetBackdropColor(colors.button[1], colors.button[2], colors.button[3], colors.button[4])
    button:SetBackdropBorderColor(colors.border[1], colors.border[2], colors.border[3], colors.border[4])
    if text then text:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4]) end
  end
end

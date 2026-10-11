local TENT_RATE = 0.13
local RESTED_CAP = 1.5
local MAX_BUBBLES = 30
local THRESHOLD = 1

local x, m, r, b
local tents = 0
local lastTents = 0
local lastXP = GetXPExhaustion() or 0
local lastUpdate = GetTime()
local elapsed = 0
local remaining = 0
local time = "0:00"
local lastText

local f = CreateFrame("Button", "Bubbles", UIParent)

f:ClearAllPoints()
f:SetWidth(100)
f:SetHeight(25)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
f:SetFrameStrata("HIGH")

f.text = f:CreateFontString(nil, "LOW", "GameFontNormal")
f.text:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE")
f.text:ClearAllPoints()
f.text:SetAllPoints(f)
f.text:SetPoint("LEFT", 0, 0)
f.text:SetJustifyH("LEFT")
f.text:SetFontObject(GameFontWhite)

local function BubbleCount(rested, max)
  if -1 == (rested or -1) or not max or max == 0 then
    return 0
  end
  return math.floor(20 * rested / max + 0.5)
end

local function FormatTime(secs)
  secs = math.floor(secs or 0)
  local mins = math.floor(secs / 60)
  local s = secs - (mins * 60)
  if s < 10 then
    return mins .. ":0" .. s
  end
  return mins .. ":" .. s
end

local function Refresh()
  x = UnitXP("player")
  m = UnitXPMax("player")
  r = GetXPExhaustion() or 0
  b = BubbleCount(r, m)

  local text
  if tents > 0 and tents < 10 then
    text = "|cfff58cba" .. b .. "|cffffffff Bubbles / |cfff58cba" .. tents
  else
    text = "|cfff58cba" .. b .. "|cffffffff Bubbles"
  end

  if text ~= lastText then
    f.text:SetText(text)
    f:SetWidth(f.text:GetStringWidth() + 10)
    lastText = text
  end
end

f:SetScript("OnUpdate", function()
  local now = GetTime()
  local delta = now - lastUpdate

  lastUpdate = now
  elapsed = elapsed + delta

  if elapsed >= THRESHOLD then
    elapsed = 0

    r = GetXPExhaustion() or 0
    local gained = r - lastXP
    lastXP = r

    m = UnitXPMax("player")
    local rate = 0
    if m and m > 0 then
      rate = (gained / m) * 100
    end
    -- ty to https://github.com/Pizzahawaiii/PizzaWorldBuffs/blob/dbfef375451131c62d26db4c15cee5bae5b41133/src/tents.lua#L69
    tents = math.floor(rate / (TENT_RATE * THRESHOLD))

    local p = TENT_RATE * math.max(tents, 1) / THRESHOLD
    if m and m > 0 then
      remaining = (1 - r / (m * RESTED_CAP)) * (100 / p)
    else
      remaining = 0
    end
    time = FormatTime(remaining)

    if tents ~= lastTents then
      Refresh()
      lastTents = tents
    end
  end
end)

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_UPDATE_RESTING")
f:SetScript("OnEvent", function()
  Refresh()
end)

f:SetMovable(true)
f:EnableMouse(true)
f:SetScript("OnMouseDown", function(self)
  self:StartMoving()
end)

f:SetScript("OnMouseUp", function(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(true)
end)

f:SetScript("OnEnter", function(self)
  local rested = GetXPExhaustion() or 0
  local max = UnitXPMax("player")
  local cur = UnitXP("player") or 0
  local bubbles = BubbleCount(rested, max)

  GameTooltip:SetOwner(self, "ANCHOR_NONE")
  GameTooltip:ClearAllPoints()

  GameTooltip:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, (CONTAINER_OFFSET_Y or 0) + 13)
  GameTooltip:SetClampedToScreen(true)

  GameTooltip:AddLine("|cfff58cbaBubbles (|cffffffff" .. bubbles .. "|cfff58cba)")
  GameTooltip:AddLine("|cffaaaaaaMaximum amount of rested bubbles is " .. MAX_BUBBLES .. ". To fully rest with one tent takes around 13 minutes. Multiple tents can stack and speed up resting.", 0, 0, 0, true)
  GameTooltip:AddLine(" ")
  if max and max > 0 then
    -- ty to https://forum.turtle-wow.org/viewtopic.php?p=65081#p65081
    GameTooltip:AddDoubleLine("|cffffffffRested", "|cffaaaaaa" .. rested .. " XP")
    if rested + cur > max then
      GameTooltip:AddDoubleLine("|cffffffffRested+", "|cffaaaaaa" .. rested + cur - max .. " XP")
    end
    GameTooltip:AddDoubleLine("|cffffffffStill", "|cffaaaaaa" .. max - cur .. " XP")
    GameTooltip:AddDoubleLine("|cffffffffPercent", "|cffaaaaaa" .. math.floor(cur / max * 100) .. "%")
  end

  GameTooltip:AddDoubleLine("|cffffffffTime to full rest", "|cfff58cba" .. time .. " |cffaaaaaamin")

  if tents > 0 then
    GameTooltip:AddDoubleLine("|cffffffffStatus", "|cffaaaaaaGaining from " .. tents .. " tent(s)")
  end

  GameTooltip:Show()
end)

f:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

SLASH_BUBBLES1 = "/bubbles"
SLASH_BUBBLES2 = "/b"

SlashCmdList["BUBBLES"] = function(msg)
  msg = string.lower(msg or "")

  if msg == "reset" then
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetUserPlaced(false)
    DEFAULT_CHAT_FRAME:AddMessage("|cfff58cbaBubbles|cffffffff frame reset to center.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cfff58cbaBubbles commands:")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff/b reset - Reset frame to center")
  end
end

DEFAULT_CHAT_FRAME:AddMessage("|cfff58cbaBubbles |cffffffff1.2 loaded")

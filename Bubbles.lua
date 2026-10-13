local TENT_RATE = 0.13
local RESTED_CAP = 1.5
local MAX_BUBBLES = 30
local THRESHOLD = 1
local CONFIRM_SAMPLES = 2
local TENT_DISPLAY_CAP = 10
local SCALE_MIN, SCALE_MAX = 0.5, 2
local FONT_MIN, FONT_MAX = 8, 24

local L = {
  loaded = "|cfff58cbaBubbles |cffffffff%s loaded",
  label = "|cfff58cba%s|cffffffff Bubbles",
  labelTents = "|cfff58cba%s|cffffffff Bubbles / |cfff58cba%s",
  reset = "|cfff58cbaBubbles|cffffffff frame reset to center.",
  commands = "|cfff58cbaBubbles commands:",
  cmdReset = "|cffffffff/b reset - Reset frame to center",
  cmdScale = "|cffffffff/b scale <0.5-2> - Set frame scale",
  cmdFont = "|cffffffff/b font <8-24> - Set font size",
  scaleSet = "|cfff58cbaBubbles|cffffffff scale set to %s.",
  scaleUsage = "|cfff58cbaBubbles|cffffffff usage: /b scale <0.5-2>",
  fontSet = "|cfff58cbaBubbles|cffffffff font size set to %d.",
  fontUsage = "|cfff58cbaBubbles|cffffffff usage: /b font <8-24>",
  tooltipTitle = "|cfff58cbaBubbles (|cffffffff%d|cfff58cba)",
  tooltipCap = "|cffaaaaaaMaximum amount of rested bubbles is %d. To fully rest with one tent takes around 13 minutes. Multiple tents can stack and speed up resting.",
  rested = "|cffffffffRested",
  restedPlus = "|cffffffffRested+",
  still = "|cffffffffStill",
  percent = "|cffffffffPercent",
  timeToFull = "|cffffffffTime to full rest",
  status = "|cffffffffStatus",
  gaining = "|cffaaaaaaGaining from %d tent(s)",
  min = "|cffaaaaaamin",
  xp = "|cffaaaaaa%s XP",
  percentVal = "|cffaaaaaa%d%%",
}

BubblesDB = BubblesDB or {}

local tents = 0
local pendingTents = 0
local pendingCount = 0
local lastXP = GetXPExhaustion() or 0
local nextTick = GetTime() + THRESHOLD
local time = "0:00"
local lastText

local f = CreateFrame("Button", "Bubbles", UIParent)

f:SetWidth(100)
f:SetHeight(25)
f:SetFrameStrata("HIGH")

f:ClearAllPoints()
if BubblesDB.point then
  f:SetPoint(BubblesDB.point, UIParent, BubblesDB.relativePoint, BubblesDB.x, BubblesDB.y)
else
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end
f:SetScale(BubblesDB.scale or 1)

f.text = f:CreateFontString(nil, "LOW", "GameFontNormal")
f.text:ClearAllPoints()
f.text:SetAllPoints(f)
f.text:SetJustifyH("LEFT")

local function ApplyFont()
  f.text:SetFontObject(GameFontWhite)
  local family, baseSize, flags = f.text:GetFont()
  f.text:SetFont(family, BubblesDB.fontSize or baseSize or 13, flags)
end

ApplyFont()

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
  local rested = GetXPExhaustion() or 0
  local max = UnitXPMax("player")
  local b = BubbleCount(rested, max)

  local text
  if tents > 0 and tents < TENT_DISPLAY_CAP then
    text = L.labelTents:format(b, tents)
  else
    text = L.label:format(b)
  end

  if text ~= lastText then
    f.text:SetText(text)
    f:SetWidth(f.text:GetStringWidth() + 10)
    lastText = text
  end
end

f:SetScript("OnUpdate", function()
  local now = GetTime()
  if now < nextTick then
    return
  end
  nextTick = now + THRESHOLD

  local r = GetXPExhaustion() or 0
  local gained = r - lastXP
  lastXP = r
  if gained < 0 then
    gained = 0
  end

  local m = UnitXPMax("player")

  if m and m > 0 then
    local rate = (gained / m) * 100
    -- ty to https://github.com/Pizzahawaiii/PizzaWorldBuffs/blob/dbfef375451131c62d26db4c15cee5bae5b41133/src/tents.lua#L69
    local rawTents = math.floor(rate / (TENT_RATE * THRESHOLD))
    if rawTents < 0 then
      rawTents = 0
    end

    if rawTents == pendingTents then
      pendingCount = pendingCount + 1
    else
      pendingTents = rawTents
      pendingCount = 1
    end

    if pendingCount >= CONFIRM_SAMPLES and tents ~= pendingTents then
      tents = pendingTents
      Refresh()
    end

    local p = TENT_RATE * math.max(tents, 1) / THRESHOLD
    local remaining = (1 - r / (m * RESTED_CAP)) * (100 / p)
    if remaining < 0 then
      remaining = 0
    end
    time = FormatTime(remaining)
  else
    pendingTents = 0
    pendingCount = 0
    time = "0:00"
    if tents ~= 0 then
      tents = 0
      Refresh()
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
  local point, _, relativePoint, x, y = self:GetPoint(1)
  BubblesDB.point = point
  BubblesDB.relativePoint = relativePoint
  BubblesDB.x = x
  BubblesDB.y = y
end)

local function ShowTooltip(self)
  local rested = GetXPExhaustion() or 0
  local max = UnitXPMax("player")
  local cur = UnitXP("player") or 0
  local bubbles = BubbleCount(rested, max)

  GameTooltip:SetOwner(self, "ANCHOR_NONE")
  GameTooltip:ClearAllPoints()

  GameTooltip:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, (CONTAINER_OFFSET_Y or 0) + 13)
  GameTooltip:SetClampedToScreen(true)

  GameTooltip:AddLine(L.tooltipTitle:format(bubbles))
  GameTooltip:AddLine(L.tooltipCap:format(MAX_BUBBLES), 0, 0, 0, true)
  GameTooltip:AddLine(" ")
  if max and max > 0 then
    -- ty to https://forum.turtle-wow.org/viewtopic.php?p=65081#p65081
    GameTooltip:AddDoubleLine(L.rested, L.xp:format(rested))
    if rested + cur > max then
      GameTooltip:AddDoubleLine(L.restedPlus, L.xp:format(rested + cur - max))
    end
    GameTooltip:AddDoubleLine(L.still, L.xp:format(max - cur))
    GameTooltip:AddDoubleLine(L.percent, L.percentVal:format(math.floor(cur / max * 100)))
  end

  GameTooltip:AddDoubleLine(L.timeToFull, "|cfff58cba" .. time .. " " .. L.min)

  if tents > 0 then
    GameTooltip:AddDoubleLine(L.status, L.gaining:format(tents))
  end

  GameTooltip:Show()
end

f:SetScript("OnEnter", function(self)
  ShowTooltip(self)
end)

f:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

SLASH_BUBBLES1 = "/bubbles"
SLASH_BUBBLES2 = "/b"

SlashCmdList["BUBBLES"] = function(msg)
  msg = string.lower(msg or "")
  local cmd, arg = string.match(msg, "^(%S*)%s*(.-)%s*$")
  cmd = cmd or ""

  if cmd == "reset" then
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetUserPlaced(false)
    BubblesDB.point = nil
    BubblesDB.relativePoint = nil
    BubblesDB.x = nil
    BubblesDB.y = nil
    DEFAULT_CHAT_FRAME:AddMessage(L.reset)
  elseif cmd == "scale" then
    local val = tonumber(arg)
    if val and val >= SCALE_MIN and val <= SCALE_MAX then
      BubblesDB.scale = val
      f:SetScale(val)
      DEFAULT_CHAT_FRAME:AddMessage(L.scaleSet:format(val))
    else
      DEFAULT_CHAT_FRAME:AddMessage(L.scaleUsage)
    end
  elseif cmd == "font" then
    local val = tonumber(arg)
    if val and val >= FONT_MIN and val <= FONT_MAX then
      BubblesDB.fontSize = val
      ApplyFont()
      DEFAULT_CHAT_FRAME:AddMessage(L.fontSet:format(val))
    else
      DEFAULT_CHAT_FRAME:AddMessage(L.fontUsage)
    end
  else
    DEFAULT_CHAT_FRAME:AddMessage(L.commands)
    DEFAULT_CHAT_FRAME:AddMessage(L.cmdReset)
    DEFAULT_CHAT_FRAME:AddMessage(L.cmdScale)
    DEFAULT_CHAT_FRAME:AddMessage(L.cmdFont)
  end
end

DEFAULT_CHAT_FRAME:AddMessage(L.loaded:format("1.3"))

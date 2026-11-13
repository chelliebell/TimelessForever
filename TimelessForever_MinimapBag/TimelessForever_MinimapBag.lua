-- =========================================================================
-- TimelessForever_MinimapBag
-- High-Performance Minimap Button Bag powered by the MinimapButtonButton Engine
-- Features:
--   * Square & Circle Minimap Orbit + Free Positioning
--   * Custom Launcher Icon Engine (Presets + Custom Texture / FileID)
--   * Classic Round & Modern Box Launcher Styles
--   * 8-Way Dynamic Grid Layout & Button Scaling
--   * Bulletproof Button Collection (LibDBIcon, LibMapButton, Children)
--   * System Frame Guard (Zero Blizzard Minimap Lua Errors)
--   * Live Settings Update Engine (AceConfig-3.0 + Blizzard Settings)
--   * Suite Hub Integration (/timelessforever bag, /tfbag, /minimapbag, /mbb)
-- =========================================================================

local addonName, ns = ...
local LibStub = _G.LibStub

local cos = math.cos
local sin = math.sin
local rad = math.rad
local deg = math.deg
local atan2 = math.atan2
local abs = math.abs
local min = math.min
local max = math.max
local ceil = math.ceil
local floor = math.floor
local strfind = string.find
local strmatch = string.match
local strlower = string.lower
local format = string.format
local tinsert = table.insert
local sort = table.sort
local wipe = table.wipe

local BRAND_TITLE = "|cff00ccffTimelessForever|r |cffffffffAddon Tray|r"
local CHAT_PREFIX = "|cff00ccff[AddonTray]|r "

-- Safe frame methods captured before any overrides
local RawClearAllPoints = _G.UIParent.ClearAllPoints
local RawSetPoint = _G.UIParent.SetPoint
local RawSetScale = _G.UIParent.SetScale

local function doNothing() end

-- =========================================================================
-- Built-in Icon Presets
-- =========================================================================
local ICON_PRESETS = {
    ["phoenix"] = {
        name = "Phoenix Bolt (Classic MBB)",
        texture = "Interface\\ICONS\\artifactability_FireMage_PhoenixBolt",
    },
    ["gamehivehq"] = {
        name = "GameHiveHQ Logo",
        texture = "Interface\\AddOns\\TimelessForever_MinimapBag\\Icons\\GameHiveHQ",
    },
    ["bag"] = {
        name = "Leather Satchel",
        texture = "Interface\\Icons\\INV_Misc_Bag_08",
    },
    ["traveler"] = {
        name = "Traveler's Backpack",
        texture = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
    },
    ["compass"] = {
        name = "Explorer's Compass",
        texture = "Interface\\Icons\\INV_Misc_Compass_01",
    },
    ["gear"] = {
        name = "Golden Cogwheel",
        texture = "Interface\\Icons\\INV_Misc_Gear_01",
    },
    ["shovel"] = {
        name = "Archaeologist Shovel",
        texture = "Interface\\AddOns\\TimelessForever_MinimapBag\\Icons\\Shovel",
    },
    ["flask"] = {
        name = "Orange Alchemy Flask",
        texture = "Interface\\AddOns\\TimelessForever_MinimapBag\\Icons\\Alchemy_80_FlaskOrange",
    },
    ["factions"] = {
        name = "Horde & Alliance",
        texture = "Interface\\AddOns\\TimelessForever_MinimapBag\\Icons\\horde&Alliance",
    },
    ["horde"] = {
        name = "Horde War Crest",
        texture = "Interface\\Icons\\INV_BannerPVP_02",
    },
    ["alliance"] = {
        name = "Alliance Lion Crest",
        texture = "Interface\\Icons\\INV_BannerPVP_01",
    },
    ["hearthstone"] = {
        name = "Hearthstone",
        texture = "Interface\\Icons\\INV_Misc_Rune_01",
    },
    ["swords"] = {
        name = "Crossed Swords",
        texture = "Interface\\Icons\\Ability_DualWield",
    },
    ["shield"] = {
        name = "Knight's Shield",
        texture = "Interface\\Icons\\INV_Shield_04",
    },
    ["star"] = {
        name = "Radiant Star",
        texture = "Interface\\Icons\\Spell_Holy_SurgeOfLight",
    },
    ["coin"] = {
        name = "Gold Coin Sack",
        texture = "Interface\\Icons\\INV_Misc_Coin_01",
    },
    ["skull"] = {
        name = "Shadow Skull",
        texture = "Interface\\Icons\\Spell_Shadow_Skull",
    },
    ["murloc"] = {
        name = "Murloc Fin",
        texture = "Interface\\Icons\\INV_Misc_MonsterHead_02",
    },
    ["eye"] = {
        name = "All-Seeing Eye",
        texture = "Interface\\Icons\\INV_Misc_Eye_01",
    },
    ["potion"] = {
        name = "Healing Potion",
        texture = "Interface\\Icons\\INV_Potion_51",
    },
    ["crown"] = {
        name = "Royal Crown",
        texture = "Interface\\Icons\\INV_Crown_01",
    },
    ["diamond"] = {
        name = "Shining Diamond",
        texture = "Interface\\Icons\\INV_Misc_Gem_Diamond_02",
    },
    ["chest"] = {
        name = "Treasure Chest",
        texture = "Interface\\Icons\\INV_Misc_Gift_02",
    },
    ["map"] = {
        name = "Treasure Map",
        texture = "Interface\\Icons\\INV_Misc_Map02",
    },
    ["key"] = {
        name = "Skeleton Key",
        texture = "Interface\\Icons\\INV_Misc_Key_03",
    },
    ["logo"] = {
        name = "MinimapButtonButton Logo",
        texture = "Interface\\AddOns\\TimelessForever_MinimapBag\\Icons\\Logo",
    },
}

-- =========================================================================
-- System Ignored Minimap Frames (Protected System Frames)
-- =========================================================================
local SYSTEM_IGNORED = {
    ["Minimap"] = true,
    ["MinimapBackdrop"] = true,
    ["MinimapCluster"] = true,
    ["MinimapZoomIn"] = true,
    ["MinimapZoomOut"] = true,
    ["MiniMapTrackingFrame"] = true,
    ["MiniMapTracking"] = true,
    ["MiniMapTrackingButton"] = true,
    ["MiniMapMeetingStoneFrame"] = true,
    ["MiniMapMailFrame"] = true,
    ["MiniMapBattlefieldFrame"] = true,
    ["MiniMapWorldMapButton"] = true,
    ["MiniMapPing"] = true,
    ["TimeManagerClockButton"] = true,
    ["GameTimeFrame"] = true,
    ["MiniMapInstanceDifficulty"] = true,
    ["GuildInstanceDifficulty"] = true,
    ["MiniMapVoiceChatFrame"] = true,
    ["MiniMapRecordingButton"] = true,
    ["QueueStatusMinimapButton"] = true,
    ["QueueStatusButton"] = true,
    ["GarrisonMinimapButton"] = true,
    ["ExpansionLandingPageMinimapButton"] = true,
    ["ExpansionLandingPage"] = true,
    ["MinimapZoneTextButton"] = true,
    ["GPSArrow"] = true,
    ["QuestWayArrowFrame"] = true,
    ["TimelessMinimapBagLauncher"] = true,
    ["TimelessForever_MinimapBagButton"] = true,
    ["TimelessForever_MinimapBagContainer"] = true,
    ["MinimapButtonButtonButton"] = true,
    ["MBB_MinimapButtonFrame"] = true,
    ["MBBFrame"] = true,
    ["HelpOpenTicketButton"] = true,
    ["HelpOpenWebTicketButton"] = true,
}

local function IsIgnoredFrame(name)
    if not name or name == "" then return true end
    if SYSTEM_IGNORED[name] then return true end
    if strfind(name, "ExpansionLanding") then return true end
    if strfind(name, "GarrisonMinimap") then return true end
    if strfind(name, "MiniMapTracking") then return true end
    if strfind(name, "MiniMapMeetingStone") then return true end
    if strfind(name, "MiniMapMail") then return true end
    if strfind(name, "MiniMapBattlefield") then return true end
    if strfind(name, "MiniMapWorldMap") then return true end
    if strfind(name, "TimeManagerClock") then return true end
    if strfind(name, "MiniMapInstanceDifficulty") then return true end
    if strfind(name, "GuildInstanceDifficulty") then return true end
    if strfind(name, "MiniMapVoiceChat") then return true end
    if strfind(name, "MiniMapRecording") then return true end
    if strfind(name, "QueueStatus") then return true end
    if strfind(name, "MinimapZoneText") then return true end
    if strfind(name, "MinimapZoom") then return true end
    if strfind(name, "GPSArrow") then return true end
    if strfind(name, "QuestWayArrow") then return true end
    if strfind(name, "Pin$") or strfind(name, "POI$") or strfind(name, "Arrow") then return true end
    if strfind(name, "^TimelessMinimapBag") or strfind(name, "^TimelessForever_MinimapBag") then return true end
    if strfind(name, "^MBB_") or name == "MBBFrame" or strfind(name, "^MinimapButtonButton") then return true end
    return false
end

-- =========================================================================
-- Constants
-- =========================================================================
local CONSTANTS = {
    FRAME_STRATA = "MEDIUM",
    FRAME_LEVEL = 7,
    EDGE_SIZE = 16,
    MAINBUTTON_DEFAULT_SIZE = 44,
    MAINBUTTON_MIN_SIZE = 32,
    MAINBUTTON_MAX_SIZE = 52,
    LOGO_SIZE = 20,
    BUTTON_SPACING = 2,
    EDGE_INSET = 4,
}

local ANCHORS = {
    CENTER = "CENTER",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    TOP = "TOP",
    BOTTOM = "BOTTOM",
    TOPLEFT = "TOPLEFT",
    TOPRIGHT = "TOPRIGHT",
    BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT",
}

-- =========================================================================
-- Database & Default Configuration
-- =========================================================================
local DEFAULT_DB = {
    minimapShape = "circle", -- "circle", "square", "free"
    angle = 200,
    radius = 80,
    freePos = { "CENTER", "UIParent", "CENTER", 0, 0 },
    iconPreset = "phoenix",
    customIcon = "",
    buttonStyle = "classic", -- "classic" (round minimap button) or "box" (modern square)
    launcherSize = 33,       -- pixel width and height (20 - 55)
    iconColor = "white",     -- "white", "class", "cyan", "gold", "green", "purple", "red"
    borderColor = "default", -- "default", "class", "cyan", "gold", "green", "purple", "red", "silver", "hidden"
    iconAlpha = 1.0,         -- idle opacity (0.1 - 1.0)
    fadeOnMouseover = false, -- fade icon when idle, brighten on hover
    hoverPulse = false,      -- subtle bounce pulse animation on hover
    lockPosition = false,    -- prevent accidental dragging
    hideInCombat = false,    -- autohide minimap icon during combat
    showCounterBadge = false,-- show collected button count on icon
    badgeColor = "cyan",     -- badge text color
    collectAddonCompartment = true, -- collect addons registered with Addon Compartment into the Minimap Bag
    redirectCompartmentClick = true, -- clicking AddonCompartmentFrame opens the Minimap Bag
    dockBagLauncher = false, -- If true, hides the floating launcher in favor of docked control bar button
    direction = "leftdown",
    buttonsPerRow = 5,
    scale = 10,       -- 10 = 100%
    buttonScale = 10, -- 10 = 100%
    autoClose = false,
    showTooltip = true,
    buttonsShown = false,
    blacklist = {},
    whitelist = {
        TimelessHealLauncher = true,
        ForeverHealLauncher = true,
        TimelessHealMinimapBtn = true,
        ForeverHealMinimapBtn = true,
        ZygorGuidesViewerMapIcon = true,
        TrinketMenu_IconFrame = true,
        CodexBrowserIcon = true,
    },
}

local function InitDB()
    TimelessMinimapBagDB = TimelessMinimapBagDB or {}

    -- Migrate from legacy MinimapButtonButtonOptions if present and DB is empty
    if _G.MinimapButtonButtonOptions and type(_G.MinimapButtonButtonOptions) == "table" then
        local mbbOpt = _G.MinimapButtonButtonOptions
        if not TimelessMinimapBagDB.direction and mbbOpt.direction then
            TimelessMinimapBagDB.direction = mbbOpt.direction
        end
        if not TimelessMinimapBagDB.buttonsPerRow and mbbOpt.buttonsPerRow then
            TimelessMinimapBagDB.buttonsPerRow = mbbOpt.buttonsPerRow
        end
        if not TimelessMinimapBagDB.scale and mbbOpt.scale then
            TimelessMinimapBagDB.scale = mbbOpt.scale
        end
        if not TimelessMinimapBagDB.buttonScale and mbbOpt.buttonScale then
            TimelessMinimapBagDB.buttonScale = mbbOpt.buttonScale
        end
        if TimelessMinimapBagDB.autoClose == nil and mbbOpt.autoClose ~= nil then
            TimelessMinimapBagDB.autoClose = mbbOpt.autoClose
        end
        if mbbOpt.blacklist and type(mbbOpt.blacklist) == "table" then
            TimelessMinimapBagDB.blacklist = TimelessMinimapBagDB.blacklist or {}
            for k, v in pairs(mbbOpt.blacklist) do
                TimelessMinimapBagDB.blacklist[k] = v
            end
        end
        if mbbOpt.whitelist and type(mbbOpt.whitelist) == "table" then
            TimelessMinimapBagDB.whitelist = TimelessMinimapBagDB.whitelist or {}
            for k, v in pairs(mbbOpt.whitelist) do
                TimelessMinimapBagDB.whitelist[k] = v
            end
        end
    end

    -- Fill defaults
    for k, v in pairs(DEFAULT_DB) do
        if TimelessMinimapBagDB[k] == nil then
            if type(v) == "table" then
                TimelessMinimapBagDB[k] = CopyTable and CopyTable(v) or {}
            else
                TimelessMinimapBagDB[k] = v
            end
        end
    end
    TimelessMinimapBagDB.blacklist = TimelessMinimapBagDB.blacklist or {}
    TimelessMinimapBagDB.whitelist = TimelessMinimapBagDB.whitelist or {}
    TimelessMinimapBagDB.whitelist["TimelessHealLauncher"] = true
    TimelessMinimapBagDB.whitelist["ForeverHealLauncher"] = true
    TimelessMinimapBagDB.whitelist["TimelessHealMinimapBtn"] = true
    TimelessMinimapBagDB.whitelist["ForeverHealMinimapBtn"] = true
    TimelessMinimapBagDB.blacklist["TimelessHealLauncher"] = nil
    TimelessMinimapBagDB.blacklist["ForeverHealLauncher"] = nil
    TimelessMinimapBagDB.blacklist["TimelessHealMinimapBtn"] = nil
    TimelessMinimapBagDB.blacklist["ForeverHealMinimapBtn"] = nil
end

local function GetPlayerClassColor()
    local playerClass = select(2, _G.UnitClass("player"))
    local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[playerClass]) or
                  (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[playerClass])
    if color then
        return color.r, color.g, color.b, 1
    end
    return 0, 0.8, 1, 1
end

local function GetColorRGB(colorKey)
    if colorKey == "class" then
        return GetPlayerClassColor()
    elseif colorKey == "cyan" then
        return 0.00, 0.85, 1.00
    elseif colorKey == "gold" then
        return 1.00, 0.82, 0.00
    elseif colorKey == "green" then
        return 0.10, 1.00, 0.20
    elseif colorKey == "purple" then
        return 0.75, 0.25, 1.00
    elseif colorKey == "red" then
        return 1.00, 0.25, 0.25
    elseif colorKey == "silver" then
        return 0.80, 0.85, 0.90
    end
    return 1.00, 1.00, 1.00
end

local function ResolveTexturePath(tex)
    if not tex or tex == "" then return nil end
    tex = tostring(tex):trim()
    if tonumber(tex) then
        return tonumber(tex)
    end
    if not strfind(tex, "\\") and not strfind(tex, "/") then
        return "Interface\\Icons\\" .. tex
    end
    return tex
end

local function GetActiveIconTexture()
    local db = TimelessMinimapBagDB
    if db and db.customIcon and db.customIcon:trim() ~= "" then
        local resolved = ResolveTexturePath(db.customIcon)
        if resolved then return resolved end
    end
    local preset = db and ICON_PRESETS[db.iconPreset]
    if preset then
        return preset.texture
    end
    return "Interface\\ICONS\\artifactability_FireMage_PhoenixBolt"
end

-- =========================================================================
-- Geometric Positioning: Square vs Circle Orbit
-- =========================================================================
local function CalculateOrbitCoords(shape, angleDeg, radius)
    local r = rad(angleDeg)
    if shape == "square" then
        -- Project ray (cos r, sin r) onto square bounding box [-w, w] x [-h, h]
        local w = radius * 0.95
        local h = radius * 0.95
        local c = abs(cos(r))
        local s = abs(sin(r))
        local scaleFactor
        if c > 0.0001 and s > 0.0001 then
            scaleFactor = min(w / c, h / s)
        elseif c > 0.0001 then
            scaleFactor = w / c
        else
            scaleFactor = h / s
        end
        return scaleFactor * cos(r), scaleFactor * sin(r)
    else
        -- Circle
        return cos(r) * radius, sin(r) * radius
    end
end

-- =========================================================================
-- Layout Engine (8-way Grid Layout System)
-- =========================================================================
local LayoutManager = {
    availableLayouts = {},
    currentLayout = nil,
    innerOffset = CONSTANTS.EDGE_INSET,
    outerOffset = -2,
}

local collectedButtons = {}
local collectedButtonMap = {}
local mainButton, buttonContainer, logo
local roundBg, roundBorder, roundHighlight

-- Forward declaration of updates
local UpdateLayout
local UpdateLauncherPosition
local UpdateLauncherVisual
local HideButtons
local ShowButtons
local ToggleButtons
local OpenOptionsDialog
local CollectAddonCompartmentAddons

-- Base Layout Class
local LayoutBase = {}
LayoutBase.__index = LayoutBase

function LayoutBase:New()
    local instance = setmetatable({}, self)
    return instance
end

function LayoutBase:isButtonDisplayed(button)
    return button and button.IsShown and button:IsShown()
end

function LayoutBase:iterateDisplayedButtons(callback)
    local idx = 1
    for _, button in ipairs(collectedButtons) do
        if self:isButtonDisplayed(button) then
            callback(button, idx)
            idx = idx + 1
        end
    end
end

function LayoutBase:getShownButtonCount()
    local count = 0
    self:iterateDisplayedButtons(function() count = count + 1 end)
    return count
end

function LayoutBase:getFrameEffectiveWidth(frame)
    local s = (frame.GetScale and frame:GetScale()) or 1
    return (frame.GetWidth and frame:GetWidth() or 32) * s
end

function LayoutBase:getFrameEffectiveHeight(frame)
    local s = (frame.GetScale and frame:GetScale()) or 1
    return (frame.GetHeight and frame:GetHeight() or 32) * s
end

function LayoutBase:getMaximumButtonDimensions()
    local maxWidth = 0
    local maxHeight = 0

    self:iterateDisplayedButtons(function(button)
        maxWidth = max(maxWidth, self:getFrameEffectiveWidth(button))
        maxHeight = max(maxHeight, self:getFrameEffectiveHeight(button))
    end)

    if maxWidth == 0 then maxWidth = CONSTANTS.MAINBUTTON_MIN_SIZE end
    if maxHeight == 0 then maxHeight = CONSTANTS.MAINBUTTON_MIN_SIZE end

    return maxWidth, maxHeight
end

function LayoutBase:setFrameEffectiveAnchor(frame, anchor, parent, parentAnchor, x, y)
    local s = (frame.GetScale and frame:GetScale()) or 1
    if s == 0 then s = 1 end
    RawClearAllPoints(frame)
    RawSetPoint(frame, anchor, parent, parentAnchor, x / s, y / s)
end

-- Horizontal Layout Subclass
local HorizontalLayout = setmetatable({}, { __index = LayoutBase })
HorizontalLayout.__index = HorizontalLayout

function HorizontalLayout:calculateButtonAreaDimension(dim, count)
    local total = LayoutManager.innerOffset * 2 + dim
    if count > 1 then
        total = total + (count - 1) * (dim + CONSTANTS.BUTTON_SPACING)
    end
    return total
end

function HorizontalLayout:calculateGridSize()
    local buttonCount = self:getShownButtonCount()
    local perRow = max(1, TimelessMinimapBagDB.buttonsPerRow or 5)
    return min(buttonCount, perRow), ceil(buttonCount / perRow)
end

function HorizontalLayout:calculateButtonContainerSize()
    local cols, rows = self:calculateGridSize()
    local w = self:calculateButtonAreaDimension(self.buttonWidth, cols)
    local h = self:calculateButtonAreaDimension(self.buttonHeight, rows)
    return w, h
end

function HorizontalLayout:anchorDisplayedButtons()
    local perRow = max(1, TimelessMinimapBagDB.buttonsPerRow or 5)
    local row = 0
    local col = 0

    self:iterateDisplayedButtons(function(button)
        if col >= perRow then
            col = col - perRow
            row = row + 1
        end
        self:anchorButton(button, row, col)
        col = col + 1
    end)
end

function HorizontalLayout:calculateButtonXOffset(col)
    return (self.buttonWidth + CONSTANTS.BUTTON_SPACING) * col + LayoutManager.innerOffset + self.buttonWidth / 2
end

function HorizontalLayout:calculateButtonYOffset(row)
    return (self.buttonHeight + CONSTANTS.BUTTON_SPACING) * row + LayoutManager.innerOffset + self.buttonHeight / 2
end

function HorizontalLayout:updateLayout()
    self.buttonWidth, self.buttonHeight = self:getMaximumButtonDimensions()
    local w, h = self:calculateButtonContainerSize()
    buttonContainer:SetSize(w, h)
    self:anchorButtonContainer()
    self:anchorDisplayedButtons()
end

-- Vertical Layout Subclass
local VerticalLayout = setmetatable({}, { __index = LayoutBase })
VerticalLayout.__index = VerticalLayout

function VerticalLayout:calculateButtonAreaDimension(dim, count)
    local total = LayoutManager.innerOffset * 2 + dim
    if count > 1 then
        total = total + (count - 1) * (dim + CONSTANTS.BUTTON_SPACING)
    end
    return total
end

function VerticalLayout:calculateGridSize()
    local buttonCount = self:getShownButtonCount()
    local perRow = max(1, TimelessMinimapBagDB.buttonsPerRow or 5)
    return ceil(buttonCount / perRow), min(buttonCount, perRow)
end

function VerticalLayout:calculateButtonContainerSize()
    local cols, rows = self:calculateGridSize()
    local w = self:calculateButtonAreaDimension(self.buttonWidth, cols)
    local h = self:calculateButtonAreaDimension(self.buttonHeight, rows)
    return w, h
end

function VerticalLayout:anchorDisplayedButtons()
    local perRow = max(1, TimelessMinimapBagDB.buttonsPerRow or 5)
    local row = 0
    local col = 0

    self:iterateDisplayedButtons(function(button)
        if row >= perRow then
            row = row - perRow
            col = col + 1
        end
        self:anchorButton(button, row, col)
        row = row + 1
    end)
end

function VerticalLayout:calculateButtonXOffset(col)
    return (self.buttonWidth + CONSTANTS.BUTTON_SPACING) * col + LayoutManager.innerOffset + self.buttonWidth / 2
end

function VerticalLayout:calculateButtonYOffset(row)
    return (self.buttonHeight + CONSTANTS.BUTTON_SPACING) * row + LayoutManager.innerOffset + self.buttonHeight / 2
end

function VerticalLayout:updateLayout()
    self.buttonWidth, self.buttonHeight = self:getMaximumButtonDimensions()
    local w, h = self:calculateButtonContainerSize()
    buttonContainer:SetSize(w, h)
    self:anchorButtonContainer()
    self:anchorDisplayedButtons()
end

local function GetAnchorButton()
    if TimelessMinimapBagDB and TimelessMinimapBagDB.dockBagLauncher then
        if _G.TimelessForever_Minimap_BagDockBtn and _G.TimelessForever_Minimap_BagDockBtn:IsShown() then
            return _G.TimelessForever_Minimap_BagDockBtn
        end
    end
    return mainButton
end

-- Specific Layout Concrete Classes
-- 1. LeftDown
local LeftDownLayout = setmetatable({}, { __index = HorizontalLayout })
LeftDownLayout.__index = LeftDownLayout
function LeftDownLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.TOPRIGHT, GetAnchorButton(), ANCHORS.TOPLEFT, -LayoutManager.outerOffset, 0)
end
function LeftDownLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.TOPRIGHT, -self:calculateButtonXOffset(col), -self:calculateButtonYOffset(row))
end

-- 2. LeftUp
local LeftUpLayout = setmetatable({}, { __index = HorizontalLayout })
LeftUpLayout.__index = LeftUpLayout
function LeftUpLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.BOTTOMRIGHT, GetAnchorButton(), ANCHORS.BOTTOMLEFT, -LayoutManager.outerOffset, 0)
end
function LeftUpLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.BOTTOMRIGHT, -self:calculateButtonXOffset(col), self:calculateButtonYOffset(row))
end

-- 3. RightDown
local RightDownLayout = setmetatable({}, { __index = HorizontalLayout })
RightDownLayout.__index = RightDownLayout
function RightDownLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.TOPLEFT, GetAnchorButton(), ANCHORS.TOPRIGHT, LayoutManager.outerOffset, 0)
end
function RightDownLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.TOPLEFT, self:calculateButtonXOffset(col), -self:calculateButtonYOffset(row))
end

-- 4. RightUp
local RightUpLayout = setmetatable({}, { __index = HorizontalLayout })
RightUpLayout.__index = RightUpLayout
function RightUpLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.BOTTOMLEFT, GetAnchorButton(), ANCHORS.BOTTOMRIGHT, LayoutManager.outerOffset, 0)
end
function RightUpLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.BOTTOMLEFT, self:calculateButtonXOffset(col), self:calculateButtonYOffset(row))
end

-- 5. UpLeft
local UpLeftLayout = setmetatable({}, { __index = VerticalLayout })
UpLeftLayout.__index = UpLeftLayout
function UpLeftLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.BOTTOMRIGHT, GetAnchorButton(), ANCHORS.TOPRIGHT, 0, LayoutManager.outerOffset)
end
function UpLeftLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.BOTTOMRIGHT, -self:calculateButtonXOffset(col), self:calculateButtonYOffset(row))
end

-- 6. UpRight
local UpRightLayout = setmetatable({}, { __index = VerticalLayout })
UpRightLayout.__index = UpRightLayout
function UpRightLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.BOTTOMLEFT, GetAnchorButton(), ANCHORS.TOPLEFT, 0, LayoutManager.outerOffset)
end
function UpRightLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.BOTTOMLEFT, self:calculateButtonXOffset(col), self:calculateButtonYOffset(row))
end

-- 7. DownLeft
local DownLeftLayout = setmetatable({}, { __index = VerticalLayout })
DownLeftLayout.__index = DownLeftLayout
function DownLeftLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.TOPRIGHT, GetAnchorButton(), ANCHORS.BOTTOMRIGHT, 0, -LayoutManager.outerOffset)
end
function DownLeftLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.TOPRIGHT, -self:calculateButtonXOffset(col), -self:calculateButtonYOffset(row))
end

-- 8. DownRight
local DownRightLayout = setmetatable({}, { __index = VerticalLayout })
DownRightLayout.__index = DownRightLayout
function DownRightLayout:anchorButtonContainer()
    buttonContainer:ClearAllPoints()
    buttonContainer:SetPoint(ANCHORS.TOPLEFT, GetAnchorButton(), ANCHORS.BOTTOMLEFT, 0, -LayoutManager.outerOffset)
end
function DownRightLayout:anchorButton(button, row, col)
    self:setFrameEffectiveAnchor(button, ANCHORS.CENTER, buttonContainer, ANCHORS.TOPLEFT, self:calculateButtonXOffset(col), -self:calculateButtonYOffset(row))
end

LayoutManager.availableLayouts["leftdown"] = LeftDownLayout:New()
LayoutManager.availableLayouts["leftup"] = LeftUpLayout:New()
LayoutManager.availableLayouts["rightdown"] = RightDownLayout:New()
LayoutManager.availableLayouts["rightup"] = RightUpLayout:New()
LayoutManager.availableLayouts["upleft"] = UpLeftLayout:New()
LayoutManager.availableLayouts["upright"] = UpRightLayout:New()
LayoutManager.availableLayouts["downleft"] = DownLeftLayout:New()
LayoutManager.availableLayouts["downright"] = DownRightLayout:New()

local function ApplyLayout(dirName)
    local layout = LayoutManager.availableLayouts[strlower(dirName or "leftdown")]
    if not layout then
        layout = LayoutManager.availableLayouts["leftdown"]
    end
    LayoutManager.currentLayout = layout
    UpdateLayout()
end

UpdateLayout = function()
    if LayoutManager.currentLayout then
        LayoutManager.currentLayout:updateLayout()
    end
end

-- =========================================================================
-- Button Collecting & Hook Engine
-- =========================================================================
local function UpdateLayoutIfVisibilityChanged(frame)
    local vis = frame:IsShown()
    if collectedButtonMap[frame] ~= vis then
        collectedButtonMap[frame] = vis
        UpdateLayout()
    end
end

local function IsDescendant(parent, child)
    if not parent or not child then return false end
    if parent == child then return true end
    local p = child.GetParent and child:GetParent()
    return p and (p == parent or IsDescendant(parent, p))
end

local function IsHoveringBagOrLauncher()
    local anchorBtn = GetAnchorButton and GetAnchorButton() or mainButton
    if _G.MouseIsOver then
        if (buttonContainer and buttonContainer:IsShown() and _G.MouseIsOver(buttonContainer, 6, -6, -6, 6))
            or (anchorBtn and anchorBtn:IsShown() and _G.MouseIsOver(anchorBtn, 4, -4, -4, 4))
            or (mainButton and mainButton:IsShown() and _G.MouseIsOver(mainButton, 4, -4, -4, 4)) then
            return true
        end
    end
    local foci = _G.GetMouseFoci and _G.GetMouseFoci() or {}
    for _, frame in ipairs(foci) do
        if IsDescendant(buttonContainer, frame) or IsDescendant(anchorBtn, frame) or IsDescendant(mainButton, frame) then
            return true
        end
    end
    return false
end

local function CheckButtonHover()
    if not TimelessMinimapBagDB.autoClose then return end
    if ns.isConfigOpen then return end -- Keep open while settings are active

    if IsHoveringBagOrLauncher() then return end
    _G.C_Timer.After(0.25, function()
        if not TimelessMinimapBagDB.autoClose or ns.isConfigOpen then return end
        if not IsHoveringBagOrLauncher() then
            HideButtons()
        end
    end)
end
_G.TimelessForever_MinimapBag_CheckHover = CheckButtonHover

local function CollectButton(button)
    if not button or collectedButtonMap[button] ~= nil then return end
    local name = button.GetName and button:GetName()
    if IsIgnoredFrame(name) then return end
    if TimelessMinimapBagDB and TimelessMinimapBagDB.blacklist and TimelessMinimapBagDB.blacklist[name] then return end

    button:SetParent(buttonContainer)
    button:SetFrameStrata(CONSTANTS.FRAME_STRATA)
    button:SetFrameLevel(CONSTANTS.FRAME_LEVEL + 1)
    button:SetScript("OnDragStart", nil)
    button:SetScript("OnDragStop", nil)
    button:SetIgnoreParentScale(false)
    local bScale = (TimelessMinimapBagDB and TimelessMinimapBagDB.buttonScale) or 10
    RawSetScale(button, bScale / 10)

    if type(button.Show) == "function" and type(button.Hide) == "function" then
        hooksecurefunc(button, "Show", UpdateLayoutIfVisibilityChanged)
        hooksecurefunc(button, "Hide", UpdateLayoutIfVisibilityChanged)
    end

    -- Lock movement methods so rogue addons don't move buttons back
    button.ClearAllPoints = doNothing
    button.SetPoint = doNothing
    button.SetParent = doNothing
    button.SetScale = doNothing

    if type(button.HookScript) == "function" then
        pcall(button.HookScript, button, "OnLeave", CheckButtonHover)
    end

    tinsert(collectedButtons, button)
    collectedButtonMap[button] = button:IsShown()
end

local function CollectLibDBIconButtons()
    local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not LibDBIcon or type(LibDBIcon.GetButtonList) ~= "function" then return end

    for _, btnName in ipairs(LibDBIcon:GetButtonList()) do
        local btn = LibDBIcon:GetMinimapButton(btnName)
        if btn then CollectButton(btn) end
    end
end

local function CollectLibMapButtonButtons()
    local LibMapButton = LibStub and LibStub:GetLibrary("LibMapButton-1.1", true)
    if not LibMapButton or type(LibMapButton.buttons) ~= "table" then return end

    for _, btn in pairs(LibMapButton.buttons) do
        CollectButton(btn)
    end
end

local function CollectWhitelistedButtons()
    -- Always collect TimelessForever suite launchers if present
    local suiteLaunchers = {
        "TimelessHealLauncher",
        "ForeverHealLauncher",
        "TimelessHealMinimapBtn",
        "ForeverHealMinimapBtn",
    }
    for _, name in ipairs(suiteLaunchers) do
        local btn = _G[name]
        if btn and type(btn) == "table" and btn.IsObjectType and btn:IsObjectType("Frame") then
            CollectButton(btn)
        end
    end

    if TimelessMinimapBagDB and TimelessMinimapBagDB.whitelist then
        for btnName in pairs(TimelessMinimapBagDB.whitelist) do
            local btn = _G[btnName]
            if btn and type(btn) == "table" and btn.IsObjectType and btn:IsObjectType("Frame") then
                CollectButton(btn)
            end
        end
    end
end

local function NameMatchesButtonPattern(frameName)
    local patterns = {
        "^LibDBIcon10_",
        "MinimapButton",
        "MinimapFrame",
        "MinimapIcon",
        "[-_]Minimap[-_]",
        "Minimap$",
        "TimelessHealLauncher",
        "ForeverHealLauncher",
        "Timeless.*Launcher",
        "Forever.*Launcher",
        "HealLauncher",
    }
    for _, pat in ipairs(patterns) do
        if strmatch(frameName, pat) then return true end
    end
    return false
end

local function NameMatchesPinPattern(frameName)
    local patterns = {
        "^HandyNotes",
        "^TomTom",
        "^HereBeDragons",
        "^Questie",
        "^GatherMate",
        "^pin",
        "^Pin",
    }
    for _, pat in ipairs(patterns) do
        if strmatch(frameName, pat) then return true end
    end
    return false
end

local function ShouldButtonBeCollected(btn)
    if not btn or type(btn) ~= "table" or not btn.IsObjectType or not btn:IsObjectType("Frame") then
        return false
    end
    if collectedButtonMap[btn] ~= nil then return false end

    local name = btn.GetName and btn:GetName()
    if not name or name == "" then return false end
    if IsIgnoredFrame(name) then return false end
    if TimelessMinimapBagDB and TimelessMinimapBagDB.blacklist and TimelessMinimapBagDB.blacklist[name] then return false end
    if issecurevariable and issecurevariable(_G, name) then return false end

    if strmatch(name, "%d$") and not strmatch(name, "^TomCats-") then
        return false
    end

    return NameMatchesButtonPattern(name) and not NameMatchesPinPattern(name)
end

local function ScanMinimapChildren()
    if not Minimap or not Minimap.GetChildren then return end
    for _, child in ipairs({ Minimap:GetChildren() }) do
        if ShouldButtonBeCollected(child) then
            CollectButton(child)
        end
    end
end

local function SortCollectedButtons()
    sort(collectedButtons, function(a, b)
        return (a:GetName() or "") < (b:GetName() or "")
    end)
end

local function CollectMinimapButtonsAndUpdateLayout()
    local prevCount = #collectedButtons
    CollectLibDBIconButtons()
    CollectLibMapButtonButtons()
    CollectWhitelistedButtons()
    if CollectAddonCompartmentAddons then
        CollectAddonCompartmentAddons()
    end
    ScanMinimapChildren()

    if #collectedButtons > prevCount then
        SortCollectedButtons()
        UpdateLayout()
    end
end

-- =========================================================================
-- Main Launcher Frame & Visual Engine
-- =========================================================================
local backdropTemplate = _G.BackdropTemplateMixin and "BackdropTemplate" or nil

mainButton = _G.CreateFrame("Button", "TimelessForever_MinimapBagButton", _G.UIParent, backdropTemplate)
mainButton:SetParent(_G.UIParent)
mainButton:SetFrameStrata(CONSTANTS.FRAME_STRATA)
mainButton:SetFrameLevel(CONSTANTS.FRAME_LEVEL)
mainButton:SetClampedToScreen(true)
mainButton:EnableMouse(true)
mainButton:RegisterForClicks("AnyUp")
mainButton:SetSize(CONSTANTS.MAINBUTTON_DEFAULT_SIZE, CONSTANTS.MAINBUTTON_DEFAULT_SIZE)

-- 1. Round Minimap Visual Elements
roundBg = mainButton:CreateTexture(nil, "BACKGROUND")
roundBg:SetSize(21, 21)
roundBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
roundBg:SetPoint("CENTER", mainButton, "CENTER", 0, 0)

roundBorder = mainButton:CreateTexture(nil, "OVERLAY")
roundBorder:SetSize(53, 53)
roundBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
roundBorder:SetPoint("TOPLEFT", mainButton, "TOPLEFT", 0, 0)

roundHighlight = mainButton:CreateTexture(nil, "BACKGROUND")
roundHighlight:SetSize(1, 1)
roundHighlight:SetAlpha(0)
roundHighlight:Hide()

-- 2. Icon Texture (Vibrant vertex color, dynamically styled)
logo = mainButton:CreateTexture(nil, "ARTWORK")
logo:SetPoint("CENTER", mainButton, "CENTER", 0, 0)
logo:SetSize(CONSTANTS.LOGO_SIZE, CONSTANTS.LOGO_SIZE)
logo:SetVertexColor(1, 1, 1, 1)

-- 3. Counter Badge Frame (Displays number of collected buttons on the icon)
local badgeFrame = _G.CreateFrame("Frame", nil, mainButton)
badgeFrame:SetSize(16, 12)
badgeFrame:SetPoint("BOTTOMRIGHT", mainButton, "BOTTOMRIGHT", 2, -2)
badgeFrame:SetFrameLevel(mainButton:GetFrameLevel() + 5)
badgeFrame:Hide()

local badgeBg = badgeFrame:CreateTexture(nil, "BACKGROUND")
badgeBg:SetAllPoints()
badgeBg:SetColorTexture(0.04, 0.06, 0.10, 0.88)

local badgeText = badgeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
badgeText:SetPoint("CENTER", badgeFrame, "CENTER", 0, 0)
badgeText:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
badgeText:SetText("0")

local function UpdateBadge()
    if not badgeFrame or not badgeText then return end
    local db = TimelessMinimapBagDB
    if db and db.showCounterBadge then
        badgeFrame:Show()
        badgeText:SetText(tostring(#collectedButtons))
        local cr, cg, cb = GetColorRGB(db.badgeColor or "cyan")
        badgeText:SetTextColor(cr, cg, cb, 1)
    else
        badgeFrame:Hide()
    end
end

-- 4. Hover Pulse Animation Group
local hoverAnimGroup = nil
local function PlayHoverPulse()
    local db = TimelessMinimapBagDB
    if not db or not db.hoverPulse then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if not hoverAnimGroup then
        hoverAnimGroup = mainButton:CreateAnimationGroup()
        local a1 = hoverAnimGroup:CreateAnimation("Scale")
        a1:SetScale(1.12, 1.12)
        a1:SetDuration(0.12)
        a1:SetOrder(1)
        local a2 = hoverAnimGroup:CreateAnimation("Scale")
        a2:SetScale(1 / 1.12, 1 / 1.12)
        a2:SetDuration(0.12)
        a2:SetOrder(2)
    end
    if not hoverAnimGroup:IsPlaying() then
        hoverAnimGroup:Play()
    end
end

-- 5. Collected Button Container Frame
buttonContainer = _G.CreateFrame("Frame", "TimelessForever_MinimapBagContainer", _G.UIParent, backdropTemplate)
buttonContainer:SetParent(mainButton)
buttonContainer:SetFrameStrata(CONSTANTS.FRAME_STRATA)
buttonContainer:SetFrameLevel(CONSTANTS.FRAME_LEVEL)
buttonContainer:Hide()

if buttonContainer.SetBackdrop then
    buttonContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = CONSTANTS.EDGE_SIZE,
        insets = {
            left = CONSTANTS.EDGE_INSET,
            right = CONSTANTS.EDGE_INSET,
            top = CONSTANTS.EDGE_INSET,
            bottom = CONSTANTS.EDGE_INSET,
        },
    })
    buttonContainer:SetBackdropColor(0.04, 0.06, 0.10, 0.92)
    buttonContainer:SetBackdropBorderColor(0.00, 0.80, 1.00, 0.90)
end

buttonContainer:SetScript("OnLeave", CheckButtonHover)
mainButton:SetScript("OnLeave", CheckButtonHover)

-- =========================================================================
-- Addon Compartment Integration Engine
-- Makes any addon registered with Addon Compartment available in the Minimap Bag
-- =========================================================================
local compartmentButtons = {}

local function CreateOrCollectCompartmentButton(addonKey, displayName, iconTex, clickFunc, notes, onEnterFunc, onLeaveFunc)
    if not addonKey or addonKey == "" then return end
    local cleanKey = tostring(addonKey):gsub("[^%a%d_]", "")

    -- Only allow ONE single icon for the TimelessForever suite: "TimelessForever"
    -- Filter out all individual submodules from creating duplicate compartment icons
    local blockedKeys = {
        ["MinimapBag"] = true,
        ["TimelessForever_MinimapBag"] = true,
        ["TimelessMinimapBag"] = true,
        ["TimelessForeverMinimapBag"] = true,
        ["TimelessForever_Move"] = true,
        ["TimelessForeverMove"] = true,
        ["TimelessMove"] = true,
        ["ForeverMove"] = true,
        ["MoveScale"] = true,
        ["TimelessForever_Tweaks"] = true,
        ["TimelessForeverTweaks"] = true,
        ["TimelessTweaks"] = true,
        ["ForeverTweaks"] = true,
        ["TweaksOptimizer"] = true,
        ["TimelessForever_AITranslate"] = true,
        ["TimelessForeverAITranslate"] = true,
        ["TimelessTranslate"] = true,
        ["ForeverTranslate"] = true,
        ["AITranslate"] = true,
        ["TimelessForever_Minimap"] = true,
        ["TimelessForeverMinimap"] = true,
        ["MinimapSquare"] = true,
        ["TimelessForeverMinimapSquare"] = true,
        ["TimelessForever"] = true,
        ["TimelessForever_Heal"] = true,
        ["TimelessForeverHeal"] = true,
        ["TimelessHeal"] = true,
        ["ForeverHeal"] = true,
        ["TimelessForever_Fishing"] = true,
        ["TimelessForeverFishing"] = true,
        ["TimelessFishing"] = true,
    }
    if blockedKeys[cleanKey] then
        return
    end
    local dispClean = displayName and tostring(displayName):gsub("[^%a%d_]", "")
    if dispClean and blockedKeys[dispClean] then
        return
    end

    local frameName = "TimelessBag_Comp_" .. cleanKey

    if compartmentButtons[cleanKey] and _G[frameName] then
        CollectButton(_G[frameName])
        return _G[frameName]
    end

    local btn = _G.CreateFrame("Button", frameName, buttonContainer, backdropTemplate)
    btn:SetSize(31, 31)
    btn:RegisterForClicks("AnyUp")

    -- Background texture
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(21, 21)
    bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    -- Icon texture
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(20, 20)
    local texPath = iconTex
    if not texPath or texPath == "" then
        texPath = "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    icon:SetTexture(texPath)
    btn.icon = icon

    -- Round border to match minimap style
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Highlight
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(24, 24)
    hl:SetPoint("CENTER")
    hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hl:SetBlendMode("ADD")

    -- Click script
    btn:SetScript("OnClick", function(self, mouseBtn)
        if type(clickFunc) == "function" then
            pcall(clickFunc, addonKey, mouseBtn)
        elseif type(clickFunc) == "string" and _G[clickFunc] then
            pcall(_G[clickFunc], addonKey, mouseBtn)
        elseif _G.SlashCmdList[addonKey:upper()] then
            pcall(_G.SlashCmdList[addonKey:upper()], "")
        end
    end)

    -- Tooltip script
    btn:SetScript("OnEnter", function(self)
        if onEnterFunc and type(onEnterFunc) == "function" then
            pcall(onEnterFunc, self)
        elseif onEnterFunc and type(onEnterFunc) == "string" and _G[onEnterFunc] then
            pcall(_G[onEnterFunc], self)
        else
            _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            _G.GameTooltip:ClearLines()
            _G.GameTooltip:AddLine(displayName or addonKey, 1, 1, 1)
            if notes and notes ~= "" then
                _G.GameTooltip:AddLine(notes, 0.85, 0.85, 0.85, true)
            end
            _G.GameTooltip:AddLine("|cffffd100Left-Click:|r Open", 0.7, 0.7, 0.7)
            _G.GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if onLeaveFunc and type(onLeaveFunc) == "function" then
            pcall(onLeaveFunc, self)
        elseif onLeaveFunc and type(onLeaveFunc) == "string" and _G[onLeaveFunc] then
            pcall(_G[onLeaveFunc], self)
        else
            _G.GameTooltip:Hide()
        end
        CheckButtonHover()
    end)

    compartmentButtons[cleanKey] = btn
    CollectButton(btn)
    return btn
end

CollectAddonCompartmentAddons = function()
    local db = TimelessMinimapBagDB
    if db and db.collectAddonCompartment == false then return end

    -- 1. Check AddonCompartmentFrame.registeredAddons table
    local comp = _G.AddonCompartmentFrame
    if comp and type(comp.registeredAddons) == "table" then
        for _, item in ipairs(comp.registeredAddons) do
            if type(item) == "table" and item.text then
                local key = item.addonName or item.text
                CreateOrCollectCompartmentButton(key, item.text, item.icon, item.func, nil, item.funcOnEnter, item.funcOnLeave)
            end
        end
    end

    -- 2. Scan loaded addons for TOC AddonCompartmentFunc declarations
    local getNum = (_G.C_AddOns and _G.C_AddOns.GetNumAddOns) or _G.GetNumAddOns
    local getInfo = (_G.C_AddOns and _G.C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
    local getMeta = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local isLoaded = (_G.C_AddOns and _G.C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded

    if getNum and getInfo and getMeta then
        for i = 1, getNum() do
            local name, title = getInfo(i)
            local compFunc = getMeta(i, "AddonCompartmentFunc")
            if compFunc and compFunc ~= "" and (not isLoaded or isLoaded(i)) then
                local icon = getMeta(i, "IconTexture") or getMeta(i, "IconAtlas")
                local notes = getMeta(i, "Notes")
                local onEnter = getMeta(i, "AddonCompartmentFuncOnEnter")
                local onLeave = getMeta(i, "AddonCompartmentFuncOnLeave")
                CreateOrCollectCompartmentButton(name, title or name, icon, compFunc, notes, onEnter, onLeave)
            end
        end
    end
end

-- Hook dynamic registration of addons calling AddonCompartmentFrame:RegisterAddon
if _G.AddonCompartmentFrame and _G.AddonCompartmentFrame.RegisterAddon and not ns.compHooked then
    ns.compHooked = true
    hooksecurefunc(_G.AddonCompartmentFrame, "RegisterAddon", function(self, data)
        if not TimelessMinimapBagDB then return end
        local db = TimelessMinimapBagDB
        if db and db.collectAddonCompartment == false then return end
        if type(data) == "table" and data.text then
            local key = data.addonName or data.text
            CreateOrCollectCompartmentButton(key, data.text, data.icon, data.func, nil, data.funcOnEnter, data.funcOnLeave)
            if UpdateLayout then UpdateLayout() end
        end
    end)
end

-- Hook Addon Compartment button click on minimap to open the Minimap Bag
if _G.AddonCompartmentFrame and not ns.compClickHooked then
    ns.compClickHooked = true
    _G.AddonCompartmentFrame:HookScript("OnClick", function(self, button)
        local db = TimelessMinimapBagDB
        if db and db.redirectCompartmentClick ~= false then
            ToggleButtons()
        end
    end)
end

-- Dragging State Engine (Smooth Orbit & Free Dragging)
local isDragging = false
local dragWatcher = _G.CreateFrame("Frame")

local function OnDragUpdate()
    if not isDragging then return end
    local db = TimelessMinimapBagDB

    if db.minimapShape == "free" then
        return -- Handled natively by StartMoving
    end

    local mx, my = Minimap:GetCenter()
    local px, py = _G.GetCursorPosition()
    local scale = Minimap:GetEffectiveScale() or 1
    px, py = px / scale, py / scale

    local dx = px - mx
    local dy = py - my
    local angle = deg(atan2(dy, dx))
    if angle < 0 then angle = angle + 360 end
    db.angle = floor(angle + 0.5)

    UpdateLauncherPosition()

    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry then
        pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessMinimapBag")
    end
end

local function StartDraggingLauncher()
    local db = TimelessMinimapBagDB
    if db.lockPosition then return end

    isDragging = true
    if db.minimapShape == "free" then
        mainButton:SetMovable(true)
        mainButton:StartMoving()
    else
        dragWatcher:SetScript("OnUpdate", OnDragUpdate)
    end
end

local function StopDraggingLauncher()
    if not isDragging then return end
    isDragging = false
    dragWatcher:SetScript("OnUpdate", nil)

    local db = TimelessMinimapBagDB
    if db.minimapShape == "free" then
        mainButton:StopMovingOrSizing()
        mainButton:SetMovable(false)
        db.freePos = { mainButton:GetPoint() }
    end

    UpdateLauncherPosition()
end

-- Mouse Click & Drag Registration
mainButton:RegisterForDrag("LeftButton", "MiddleButton")

mainButton:SetScript("OnMouseDown", function(self, button)
    if button == "MiddleButton" or _G.IsAltKeyDown() then
        StartDraggingLauncher()
    end
end)

mainButton:SetScript("OnMouseUp", function(self, button)
    if isDragging then
        StopDraggingLauncher()
    end
end)

mainButton:SetScript("OnDragStart", function(self)
    StartDraggingLauncher()
end)

mainButton:SetScript("OnDragStop", function(self)
    StopDraggingLauncher()
end)

mainButton:SetScript("OnClick", function(self, button)
    if isDragging then
        StopDraggingLauncher()
        return
    end

    if button == "RightButton" or _G.IsShiftKeyDown() then
        OpenOptionsDialog()
    else
        ToggleButtons()
    end
end)

-- Hover Pop-Out Handling (No Tooltip / Highlight Overlay)
mainButton:SetScript("OnEnter", function(self)
    local db = TimelessMinimapBagDB
    if db.fadeOnMouseover then
        self:SetAlpha(1.0)
    end
    PlayHoverPulse()

    -- Pop out bag on hover without any tooltip overlay
    if not isDragging then
        CollectMinimapButtonsAndUpdateLayout()
        ShowButtons()
    end
end)

mainButton:SetScript("OnLeave", function(self)
    local db = TimelessMinimapBagDB
    if db.fadeOnMouseover then
        self:SetAlpha(db.iconAlpha or 0.6)
    end
    _G.GameTooltip:Hide()
    CheckButtonHover()
end)

-- Visual Stylizer: Round vs Modern Box
UpdateLauncherVisual = function()
    local db = TimelessMinimapBagDB
    local tex = GetActiveIconTexture()
    logo:SetTexture(tex)

    local ir, ig, ib = GetColorRGB(db.iconColor or "white")
    logo:SetVertexColor(ir, ig, ib, 1)

    local sz = db.launcherSize or 33
    mainButton:SetSize(sz, sz)

    if db.buttonStyle == "box" then
        roundBg:Hide()
        roundBorder:Hide()
        roundHighlight:Hide()

        local logoSz = floor(sz * 0.65)
        logo:SetSize(logoSz, logoSz)

        if mainButton.SetBackdrop then
            mainButton:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = CONSTANTS.EDGE_SIZE,
                insets = {
                    left = CONSTANTS.EDGE_INSET,
                    right = CONSTANTS.EDGE_INSET,
                    top = CONSTANTS.EDGE_INSET,
                    bottom = CONSTANTS.EDGE_INSET,
                },
            })
            local r, g, b = GetPlayerClassColor()
            mainButton:SetBackdropColor(r * 0.4, g * 0.4, b * 0.4, 0.95)

            if db.borderColor == "hidden" then
                mainButton:SetBackdropBorderColor(0, 0, 0, 0)
            else
                local br, bg, bb = GetColorRGB(db.borderColor or "cyan")
                mainButton:SetBackdropBorderColor(br, bg, bb, 0.90)
            end
        end
    else
        -- Classic Round
        if mainButton.SetBackdrop then
            mainButton:SetBackdrop(nil)
        end
        roundBg:Show()
        roundHighlight:Hide()

        local bgSz = floor(sz * 0.64)
        local borderSz = floor(sz * 1.60)
        local logoSz = floor(sz * 0.60)

        roundBg:SetSize(bgSz, bgSz)
        roundBorder:SetSize(borderSz, borderSz)
        logo:SetSize(logoSz, logoSz)

        if db.borderColor == "hidden" then
            roundBorder:Hide()
        else
            roundBorder:Show()
            if db.borderColor == "default" or not db.borderColor then
                roundBorder:SetVertexColor(1, 1, 1, 1)
            else
                local br, bg, bb = GetColorRGB(db.borderColor)
                roundBorder:SetVertexColor(br, bg, bb, 1)
            end
        end

        if logo.SetMask then
            pcall(function() logo:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask") end)
        end
    end

    -- Idle Alpha
    local isMouseOver = _G.MouseIsOver and _G.MouseIsOver(mainButton)
    if db.fadeOnMouseover and not isMouseOver then
        mainButton:SetAlpha(db.iconAlpha or 0.6)
    else
        mainButton:SetAlpha(1.0)
    end

    UpdateBadge()
    mainButton:Show()
end

-- Position Updater: Square vs Circle Orbit vs Free
UpdateLauncherPosition = function()
    local db = TimelessMinimapBagDB
    mainButton:ClearAllPoints()

    if db.minimapShape == "free" then
        local fp = db.freePos or { "CENTER", "UIParent", "CENTER", 0, 0 }
        mainButton:SetPoint(fp[1] or "CENTER", _G.UIParent, fp[3] or "CENTER", fp[4] or 0, fp[5] or 0)
    else
        local x, y = CalculateOrbitCoords(db.minimapShape, db.angle or 200, db.radius or 80)
        mainButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end

function TimelessForever_MinimapBag_SetDocked(docked)
    if TimelessMinimapBagDB then
        TimelessMinimapBagDB.dockBagLauncher = false
    end
    if mainButton then
        mainButton:Show()
    end
    if UpdateLayout then
        UpdateLayout()
    end
end
_G["TimelessForever_MinimapBag_SetDocked"] = TimelessForever_MinimapBag_SetDocked

local function ApplyScale()
    local s = (TimelessMinimapBagDB.scale or 10) / 10
    RawSetScale(mainButton, s)
end

local function ApplyButtonScale()
    local s = (TimelessMinimapBagDB.buttonScale or 10) / 10
    for _, btn in ipairs(collectedButtons) do
        RawSetScale(btn, s)
    end
    UpdateLayout()
end

ShowButtons = function()
    CollectMinimapButtonsAndUpdateLayout()
    TimelessMinimapBagDB.buttonsShown = true
    buttonContainer:Show()
    UpdateLayout()
end

HideButtons = function()
    if ns.isConfigOpen then return end
    TimelessMinimapBagDB.buttonsShown = false
    buttonContainer:Hide()
end

ToggleButtons = function()
    CollectMinimapButtonsAndUpdateLayout()
    if buttonContainer:IsShown() then
        HideButtons()
    else
        ShowButtons()
    end
end

-- =========================================================================
-- Live Updating AceConfig-3.0 Options Panel
-- =========================================================================
local optionsTable = nil

local function BuildOptionsTable()
    if optionsTable then return optionsTable end

    local presetList = {}
    for k, v in pairs(ICON_PRESETS) do
        presetList[k] = "|T" .. v.texture .. ":16:16:0:0|t " .. v.name
    end

    optionsTable = {
        name = "Addon Tray",
        type = "group",
        args = {
            intro = {
                name = BRAND_TITLE,
                type = "header",
                order = 1,
            },
            desc = {
                name = "A modern, high-performance minimap Addon Tray with hover pop-out, square & circle minimap orbit, and custom icon engine.\n",
                type = "description",
                order = 2,
                fontSize = "medium",
            },
            orbitHeader = {
                name = "Minimap Shape & Movement (Live Orbit)",
                type = "header",
                order = 10,
            },
            minimapShape = {
                name = "Minimap Shape",
                desc = "Choose whether the button moves around a Circular minimap, traces a Square minimap, or floats freely.",
                type = "select",
                order = 11,
                values = {
                    ["circle"] = "Circle (Round Minimap Orbit)",
                    ["square"] = "Square (Square / Rectangular Minimap Orbit)",
                    ["free"] = "Free Floating (Detach & place anywhere)",
                },
                get = function() return TimelessMinimapBagDB.minimapShape end,
                set = function(_, val)
                    TimelessMinimapBagDB.minimapShape = val
                    UpdateLauncherPosition()
                    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                    if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                end,
            },
            angle = {
                name = "Minimap Angle",
                desc = "Rotate the launcher button around your Circle or Square minimap in real time (0° to 360°).",
                type = "range",
                order = 12,
                min = 0,
                max = 360,
                step = 1,
                disabled = function() return TimelessMinimapBagDB.minimapShape == "free" end,
                get = function() return TimelessMinimapBagDB.angle or 200 end,
                set = function(_, val)
                    TimelessMinimapBagDB.angle = val
                    UpdateLauncherPosition()
                end,
            },
            radius = {
                name = "Minimap Distance / Radius",
                desc = "Distance in pixels from the center of the minimap to the button.",
                type = "range",
                order = 13,
                min = 40,
                max = 140,
                step = 1,
                disabled = function() return TimelessMinimapBagDB.minimapShape == "free" end,
                get = function() return TimelessMinimapBagDB.radius or 80 end,
                set = function(_, val)
                    TimelessMinimapBagDB.radius = val
                    UpdateLauncherPosition()
                end,
            },
            lockPosition = {
                name = "Lock Icon Position",
                desc = "Locks the minimap icon in place to prevent accidental dragging.",
                type = "toggle",
                order = 14,
                get = function() return TimelessMinimapBagDB.lockPosition end,
                set = function(_, val)
                    TimelessMinimapBagDB.lockPosition = val
                    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                    if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                end,
            },
            snapGroup = {
                name = "Quick Snap to Minimap Angles",
                type = "group",
                inline = true,
                order = 15,
                disabled = function() return TimelessMinimapBagDB.minimapShape == "free" end,
                args = {
                    snapTop = {
                        name = "Top (90°)",
                        type = "execute",
                        order = 1,
                        func = function()
                            TimelessMinimapBagDB.angle = 90
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapTopRight = {
                        name = "Top-Right (45°)",
                        type = "execute",
                        order = 2,
                        func = function()
                            TimelessMinimapBagDB.angle = 45
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapRight = {
                        name = "Right (0°)",
                        type = "execute",
                        order = 3,
                        func = function()
                            TimelessMinimapBagDB.angle = 0
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapBottomRight = {
                        name = "Bottom-Right (315°)",
                        type = "execute",
                        order = 4,
                        func = function()
                            TimelessMinimapBagDB.angle = 315
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapBottom = {
                        name = "Bottom (270°)",
                        type = "execute",
                        order = 5,
                        func = function()
                            TimelessMinimapBagDB.angle = 270
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapBottomLeft = {
                        name = "Bottom-Left (225°)",
                        type = "execute",
                        order = 6,
                        func = function()
                            TimelessMinimapBagDB.angle = 225
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapLeft = {
                        name = "Left (180°)",
                        type = "execute",
                        order = 7,
                        func = function()
                            TimelessMinimapBagDB.angle = 180
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    snapTopLeft = {
                        name = "Top-Left (135°)",
                        type = "execute",
                        order = 8,
                        func = function()
                            TimelessMinimapBagDB.angle = 135
                            UpdateLauncherPosition()
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                    resetPos = {
                        name = "Reset Default (200°)",
                        desc = "Reset the button position back to standard default angle.",
                        type = "execute",
                        order = 9,
                        func = function()
                            TimelessMinimapBagDB.angle = 200
                            TimelessMinimapBagDB.radius = 80
                            TimelessMinimapBagDB.minimapShape = "circle"
                            UpdateLauncherPosition()
                            _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Position reset to default.")
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                        end,
                    },
                },
            },
            iconHeader = {
                name = "Launcher Appearance & Icon Tweaks (Live Preview)",
                type = "header",
                order = 20,
            },
            iconPreset = {
                name = "Choose Icon Preset",
                desc = "Select an icon texture displayed on the main minimap launcher button.",
                type = "select",
                order = 21,
                values = presetList,
                get = function() return TimelessMinimapBagDB.iconPreset end,
                set = function(_, val)
                    TimelessMinimapBagDB.iconPreset = val
                    TimelessMinimapBagDB.customIcon = ""
                    UpdateLauncherVisual()
                    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                    if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                end,
            },
            customIcon = {
                name = "Custom Texture Path",
                desc = "Enter any custom icon texture path or fileID (e.g. Interface\\Icons\\Spell_Holy_Renew). Leave blank to use preset.",
                type = "input",
                order = 22,
                width = "double",
                get = function() return TimelessMinimapBagDB.customIcon or "" end,
                set = function(_, val)
                    TimelessMinimapBagDB.customIcon = (val or ""):trim()
                    UpdateLauncherVisual()
                    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                    if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                end,
            },
            buttonStyle = {
                name = "Button Frame Style",
                desc = "Choose between classic circular minimap border or clean modern square box.",
                type = "select",
                order = 23,
                values = {
                    ["classic"] = "Classic Minimap Button (Round Border)",
                    ["box"] = "Modern Square Box (Clean Tooltip Border)",
                },
                get = function() return TimelessMinimapBagDB.buttonStyle or "classic" end,
                set = function(_, val)
                    TimelessMinimapBagDB.buttonStyle = val
                    UpdateLauncherVisual()
                end,
            },
            launcherSize = {
                name = "Launcher Icon Size",
                desc = "Adjust the physical pixel size of the minimap icon (20px to 55px).",
                type = "range",
                order = 24,
                min = 20,
                max = 55,
                step = 1,
                get = function() return TimelessMinimapBagDB.launcherSize or 33 end,
                set = function(_, val)
                    TimelessMinimapBagDB.launcherSize = val
                    UpdateLauncherVisual()
                end,
            },
            iconColor = {
                name = "Icon Tint / Color",
                desc = "Color tint applied to the launcher icon texture.",
                type = "select",
                order = 25,
                values = {
                    ["white"] = "Original Full Color",
                    ["class"] = "Player Class Color",
                    ["cyan"] = "Cyan Neon",
                    ["gold"] = "Royal Gold",
                    ["green"] = "Fel Green",
                    ["purple"] = "Void Purple",
                    ["red"] = "Crimson Red",
                },
                get = function() return TimelessMinimapBagDB.iconColor or "white" end,
                set = function(_, val)
                    TimelessMinimapBagDB.iconColor = val
                    UpdateLauncherVisual()
                end,
            },
            borderColor = {
                name = "Border Color / Style",
                desc = "Color tint applied to the button border ring or box frame.",
                type = "select",
                order = 26,
                values = {
                    ["default"] = "Default Bronze / Gold",
                    ["class"] = "Player Class Color",
                    ["cyan"] = "Cyan Neon",
                    ["gold"] = "Royal Gold",
                    ["green"] = "Fel Green",
                    ["purple"] = "Void Purple",
                    ["red"] = "Crimson Red",
                    ["silver"] = "Silver Chrome",
                    ["hidden"] = "Hidden (Borderless)",
                },
                get = function() return TimelessMinimapBagDB.borderColor or "default" end,
                set = function(_, val)
                    TimelessMinimapBagDB.borderColor = val
                    UpdateLauncherVisual()
                end,
            },
            iconAlpha = {
                name = "Idle Opacity / Alpha",
                desc = "Transparency of the minimap icon when not hovering over it.",
                type = "range",
                order = 27,
                min = 0.1,
                max = 1.0,
                step = 0.05,
                isPercent = true,
                get = function() return TimelessMinimapBagDB.iconAlpha or 1.0 end,
                set = function(_, val)
                    TimelessMinimapBagDB.iconAlpha = val
                    UpdateLauncherVisual()
                end,
            },
            fadeOnMouseover = {
                name = "Fade Icon When Idle",
                desc = "Dim the icon to idle opacity when not hovered, and brighten to 100% on mouseover.",
                type = "toggle",
                order = 28,
                get = function() return TimelessMinimapBagDB.fadeOnMouseover end,
                set = function(_, val)
                    TimelessMinimapBagDB.fadeOnMouseover = val
                    UpdateLauncherVisual()
                end,
            },
            hoverPulse = {
                name = "Hover Pulse Animation",
                desc = "Play a subtle bouncy pulse animation when mouse hovers over the icon.",
                type = "toggle",
                order = 29,
                get = function() return TimelessMinimapBagDB.hoverPulse end,
                set = function(_, val)
                    TimelessMinimapBagDB.hoverPulse = val
                end,
            },
            hideInCombat = {
                name = "Hide Icon in Combat",
                desc = "Automatically hide the minimap launcher icon during combat to reduce screen clutter.",
                type = "toggle",
                order = 30,
                get = function() return TimelessMinimapBagDB.hideInCombat end,
                set = function(_, val)
                    TimelessMinimapBagDB.hideInCombat = val
                    if _G.InCombatLockdown and _G.InCombatLockdown() then
                        if val then
                            mainButton:Hide()
                            buttonContainer:Hide()
                        else
                            mainButton:Show()
                        end
                    end
                end,
            },
            showCounterBadge = {
                name = "Show Button Count Badge",
                desc = "Display a mini badge on the icon showing the total number of collected buttons.",
                type = "toggle",
                order = 31,
                get = function() return TimelessMinimapBagDB.showCounterBadge end,
                set = function(_, val)
                    TimelessMinimapBagDB.showCounterBadge = val
                    UpdateBadge()
                end,
            },
            badgeColor = {
                name = "Badge Text Color",
                desc = "Color of the collected buttons count text.",
                type = "select",
                order = 32,
                disabled = function() return not TimelessMinimapBagDB.showCounterBadge end,
                values = {
                    ["cyan"] = "Cyan",
                    ["gold"] = "Gold",
                    ["white"] = "White",
                    ["green"] = "Green",
                    ["class"] = "Class Color",
                },
                get = function() return TimelessMinimapBagDB.badgeColor or "cyan" end,
                set = function(_, val)
                    TimelessMinimapBagDB.badgeColor = val
                    UpdateBadge()
                end,
            },
            layoutHeader = {
                name = "Bag Layout & Behavior (Live Updating)",
                type = "header",
                order = 40,
            },
            previewToggle = {
                name = "Show Bag Flyout",
                desc = "Keep the bag flyout visible while adjusting settings.",
                type = "toggle",
                order = 41,
                get = function() return buttonContainer:IsShown() end,
                set = function(_, val)
                    if val then ShowButtons() else HideButtons() end
                end,
            },
            direction = {
                name = "Growth Direction",
                desc = "Direction where collected buttons expand relative to the main button.",
                type = "select",
                order = 42,
                values = {
                    ["leftdown"] = "Left > Down",
                    ["leftup"] = "Left > Up",
                    ["rightdown"] = "Right > Down",
                    ["rightup"] = "Right > Up",
                    ["downleft"] = "Down > Left",
                    ["downright"] = "Down > Right",
                    ["upleft"] = "Up > Left",
                    ["upright"] = "Up > Right",
                },
                get = function() return TimelessMinimapBagDB.direction or "leftdown" end,
                set = function(_, val)
                    TimelessMinimapBagDB.direction = val
                    ApplyLayout(val)
                end,
            },
            buttonsPerRow = {
                name = "Buttons Per Row / Column",
                desc = "Maximum buttons placed in one row before wrapping to the next line.",
                type = "range",
                order = 43,
                min = 1,
                max = 20,
                step = 1,
                get = function() return TimelessMinimapBagDB.buttonsPerRow or 5 end,
                set = function(_, val)
                    TimelessMinimapBagDB.buttonsPerRow = val
                    UpdateLayout()
                end,
            },
            scale = {
                name = "Main Button Scale",
                desc = "Scale factor for the launcher button (10 = 100%).",
                type = "range",
                order = 44,
                min = 5,
                max = 25,
                step = 1,
                get = function() return TimelessMinimapBagDB.scale or 10 end,
                set = function(_, val)
                    TimelessMinimapBagDB.scale = val
                    ApplyScale()
                end,
            },
            buttonScale = {
                name = "Collected Buttons Scale",
                desc = "Scale factor for the collected buttons inside the bag (10 = 100%).",
                type = "range",
                order = 45,
                min = 5,
                max = 25,
                step = 1,
                get = function() return TimelessMinimapBagDB.buttonScale or 10 end,
                set = function(_, val)
                    TimelessMinimapBagDB.buttonScale = val
                    ApplyButtonScale()
                end,
            },
            autoClose = {
                name = "Auto-Close Bag",
                desc = "Automatically close the button bag when mouse moves away.",
                type = "toggle",
                order = 46,
                get = function() return TimelessMinimapBagDB.autoClose end,
                set = function(_, val)
                    TimelessMinimapBagDB.autoClose = val
                    if val and not ns.isConfigOpen then HideButtons() end
                end,
            },
            showTooltip = {
                name = "Show Tooltip",
                desc = "Show help tooltip when hovering over launcher button.",
                type = "toggle",
                order = 47,
                get = function() return TimelessMinimapBagDB.showTooltip end,
                set = function(_, val) TimelessMinimapBagDB.showTooltip = val end,
            },
            compartmentHeader = {
                name = "Addon Compartment Integration",
                type = "header",
                order = 50,
            },
            collectAddonCompartment = {
                name = "Collect Addon Compartment Addons",
                desc = "Automatically collect any addons registered with Blizzard's Addon Compartment into this Minimap Bag.",
                type = "toggle",
                order = 51,
                get = function() return TimelessMinimapBagDB.collectAddonCompartment ~= false end,
                set = function(_, val)
                    TimelessMinimapBagDB.collectAddonCompartment = val
                    CollectMinimapButtonsAndUpdateLayout()
                end,
            },
            redirectCompartmentClick = {
                name = "Open Bag When Clicking Compartment",
                desc = "Clicking the Addon Compartment button on the minimap opens this button bag.",
                type = "toggle",
                order = 52,
                get = function() return TimelessMinimapBagDB.redirectCompartmentClick ~= false end,
                set = function(_, val)
                    TimelessMinimapBagDB.redirectCompartmentClick = val
                end,
            },
            buttonsHeader = {
                name = "Discovered Minimap Buttons",
                type = "header",
                order = 60,
            },
            rescanBtn = {
                name = "Rescan Minimap",
                desc = "Rescan the minimap for newly created buttons from other addons.",
                type = "execute",
                order = 61,
                func = function()
                    CollectMinimapButtonsAndUpdateLayout()
                    _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. format("Rescan completed (%d buttons collected).", #collectedButtons))
                    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                    if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
                end,
            },
            buttonsGroup = {
                name = "Collected Buttons List",
                type = "group",
                inline = true,
                order = 62,
                args = {},
            },
        },
    }
    return optionsTable
end

local function RefreshButtonArgs()
    local opt = BuildOptionsTable()
    opt.args.buttonsGroup.args = {}

    for i, btn in ipairs(collectedButtons) do
        local name = btn:GetName() or ("Button" .. i)
        opt.args.buttonsGroup.args[name] = {
            name = name,
            desc = "Check to collect into bag, uncheck to ignore.",
            type = "toggle",
            order = i,
            get = function() return not TimelessMinimapBagDB.blacklist[name] end,
            set = function(_, val)
                if val then
                    TimelessMinimapBagDB.blacklist[name] = nil
                else
                    TimelessMinimapBagDB.blacklist[name] = true
                end
                UpdateLayout()
                local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                if reg then pcall(reg.NotifyChange, reg, "TimelessMinimapBag") end
            end,
        }
    end
end

OpenOptionsDialog = function()
    local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
    local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if not AceConfig or not AceConfigDialog then return end

    ns.isConfigOpen = true
    ShowButtons()

    RefreshButtonArgs()
    AceConfig:RegisterOptionsTable("TimelessMinimapBag", BuildOptionsTable())

    local suite = _G["TimelessForeverSuite"] or _G["TimelessSuite"] or _G["ForeverSuite"]
    if suite and suite.OpenSettings then
        suite:OpenSettings("bag")
    else
        AceConfigDialog:Open("TimelessMinimapBag")
    end

    if AceConfigRegistry then
        pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessMinimapBag")
    end
end

-- Close config flag when Blizzard options hide
if _G.SettingsPanel and _G.SettingsPanel.HookScript then
    pcall(_G.SettingsPanel.HookScript, _G.SettingsPanel, "OnHide", function()
        ns.isConfigOpen = false
    end)
end
if _G.InterfaceOptionsFrame and _G.InterfaceOptionsFrame.HookScript then
    pcall(_G.InterfaceOptionsFrame.HookScript, _G.InterfaceOptionsFrame, "OnHide", function()
        ns.isConfigOpen = false
    end)
end

-- =========================================================================
-- TimelessForever Suite Hub Integration
-- =========================================================================
local function RegisterWithSuiteHub()
    local suite = _G["TimelessForeverSuite"] or _G["TimelessSuite"] or _G["ForeverSuite"]
    if suite and suite.RegisterModuleTab then
        local opt = BuildOptionsTable()
        RefreshButtonArgs()
        pcall(function()
            suite:RegisterModuleTab("bag", "Addon Tray", 6, opt.args)
        end)
    end
end

-- =========================================================================
-- Slash Command Handlers
-- =========================================================================
SLASH_TIMELESSMINIMAPBAG1 = "/tfbag"
SLASH_TIMELESSMINIMAPBAG2 = "/minimapbag"
SLASH_TIMELESSMINIMAPBAG3 = "/addontray"
SLASH_TIMELESSMINIMAPBAG4 = "/tftray"

local function HandleBagSlash(msg)
    local cmd = (msg or ""):trim():lower()
    if cmd == "opt" or cmd == "options" or cmd == "config" or cmd == "settings" then
        OpenOptionsDialog()
    elseif cmd == "reset" then
        TimelessMinimapBagDB.angle = 200
        TimelessMinimapBagDB.radius = 80
        TimelessMinimapBagDB.minimapShape = "circle"
        UpdateLauncherPosition()
        UpdateLayout()
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Position reset to default.")
    elseif cmd == "square" then
        TimelessMinimapBagDB.minimapShape = "square"
        UpdateLauncherPosition()
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Minimap shape set to |cffffd100Square|r.")
    elseif cmd == "circle" then
        TimelessMinimapBagDB.minimapShape = "circle"
        UpdateLauncherPosition()
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Minimap shape set to |cffffd100Circle|r.")
    elseif cmd == "rescan" or cmd == "scan" then
        CollectMinimapButtonsAndUpdateLayout()
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. format("Rescan completed (%d buttons collected).", #collectedButtons))
    else
        ToggleButtons()
    end
end

SlashCmdList["TIMELESSMINIMAPBAG"] = HandleBagSlash

-- Export global suite API for other TimelessForever modules (e.g. TimelessForever_Minimap)
_G.TimelessForever_MinimapBag_Toggle = ToggleButtons
_G.TimelessForever_MinimapBag_Show = ShowButtons
_G.TimelessForever_MinimapBag_Hide = HideButtons
_G.TimelessForever_MinimapBag_OpenOptions = OpenOptionsDialog
_G.TimelessForever_MinimapBag_GetButtonCount = function() return #collectedButtons end
_G.TimelessForever_MinimapBag_Rescan = CollectMinimapButtonsAndUpdateLayout

-- Also provide /mbb alias if not claimed
if not SlashCmdList["MBB"] then
    SLASH_MBB1 = "/mbb"
    SlashCmdList["MBB"] = HandleBagSlash
end

-- Hook into /timelessforever macro
if _G.TimelessForeverSuite then
    -- Registered via suite tab
end

-- =========================================================================
-- Event Dispatcher & Initialization
-- =========================================================================
local eventFrame = _G.CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "TimelessForever_MinimapBag") then
        InitDB()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if TimelessMinimapBagDB and TimelessMinimapBagDB.hideInCombat then
            mainButton:Hide()
            buttonContainer:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if TimelessMinimapBagDB and TimelessMinimapBagDB.hideInCombat then
            mainButton:Show()
            if TimelessMinimapBagDB.buttonsShown then
                buttonContainer:Show()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        InitDB()
        TimelessMinimapBagDB.dockBagLauncher = false
        UpdateLauncherVisual()
        ApplyScale()
        UpdateLauncherPosition()
        ApplyLayout(TimelessMinimapBagDB.direction)
        mainButton:Show()

        if TimelessMinimapBagDB.buttonsShown then
            buttonContainer:Show()
        end

        -- Hook LibDBIcon callbacks for buttons created on the fly
        local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
        if LibDBIcon and type(LibDBIcon.RegisterCallback) == "function" then
            pcall(LibDBIcon.RegisterCallback, "TimelessForever_MinimapBag", "LibDBIcon_IconCreated", function(_, button)
                CollectButton(button)
                UpdateLayout()
            end)
        end

        -- Staggered rescans to catch late-registering addons (Questie, DBM, HealBot, etc.)
        _G.C_Timer.After(0.1, function()
            CollectMinimapButtonsAndUpdateLayout()
            RegisterWithSuiteHub()
        end)

        _G.C_Timer.After(1.0, function()
            CollectMinimapButtonsAndUpdateLayout()
            RegisterWithSuiteHub()
        end)

        _G.C_Timer.After(4.0, function()
            CollectMinimapButtonsAndUpdateLayout()
            RegisterWithSuiteHub()
        end)

        -- Register options table for Suite Hub (do not create duplicate standalone entry in ESC -> Options -> AddOns)
        local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
        if AceConfig then
            AceConfig:RegisterOptionsTable("TimelessMinimapBag", BuildOptionsTable())
        end
        RegisterWithSuiteHub()
    end
end)

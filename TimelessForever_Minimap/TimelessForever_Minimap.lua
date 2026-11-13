-- =========================================================================
-- TimelessForever Minimap (Square & Suite Controls)
-- World of Warcraft Modern Square Minimap with Integrated Minimap Bag
-- Compatible with Classic Era, Camelot/Classic Beta, and Retail
-- =========================================================================

local addonName, ns = ...
local _G = _G

-- LibStub and Ace3 Libraries
local LibStub = _G.LibStub
local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)

-- Branding & Constants
local BRAND_TITLE = "|cff00ccffTimelessForever|r Minimap"
local CHAT_PREFIX = "|cff00ccff[TF Minimap]|r "
local MASK_SQUARE = "Interface\\Buttons\\WHITE8X8"
local MASK_CIRCLE = "Textures\\MinimapMask"

local MINIMUM_SIZE = 160
local DEFAULT_SIZE = 240
local HEADER_SPACE, FOOTER_SPACE = 24, 26

-- Colors
local COLOR_GOLD = { 0.95, 0.76, 0.35, 1 }
local COLOR_CYAN = { 0.00, 0.85, 1.00, 1 }
local COLOR_GREY = { 0.55, 0.55, 0.58, 1 }

local function GetPlayerClassColor()
    local _, playerClass = _G.UnitClass("player")
    local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[playerClass]) or
                  (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[playerClass])
    if color then
        return color.r, color.g, color.b, 1
    end
    return 0.0, 0.85, 1.0, 1
end

local function GetColorRGB(colorKey, customR, customG, customB)
    if colorKey == "class" then
        return GetPlayerClassColor()
    elseif colorKey == "cyan" then
        return 0.00, 0.85, 1.00, 1
    elseif colorKey == "gold" then
        return 1.00, 0.82, 0.00, 1
    elseif colorKey == "green" then
        return 0.10, 1.00, 0.20, 1
    elseif colorKey == "purple" then
        return 0.75, 0.25, 1.00, 1
    elseif colorKey == "red" then
        return 1.00, 0.25, 0.25, 1
    elseif colorKey == "silver" then
        return 0.85, 0.88, 0.92, 1
    elseif colorKey == "black" then
        return 0.00, 0.00, 0.00, 1
    elseif colorKey == "white" then
        return 1.00, 1.00, 1.00, 1
    elseif colorKey == "custom" then
        return customR or 0, customG or 0.85, customB or 1, 1
    end
    return 0.00, 0.85, 1.00, 1
end

-- =========================================================================
-- Default Settings & Schema
-- =========================================================================
local DEFAULT_DB = {
    schema = 1,
    shape = "square",            -- "square" or "circle"
    size = DEFAULT_SIZE,
    x = -16,
    y = -16,
    iconScale = 1.0,
    barScale = 1.0,
    barPosition = "bottom",       -- "bottom" or "top"

    -- Border Customization
    borderStyle = "thin",         -- "thin", "sleek", "thick", "double", "glow", "none"
    borderColor = "cyan",         -- "cyan", "class", "gold", "green", "purple", "red", "silver", "black", "custom"
    borderCustomR = 0.0,
    borderCustomG = 0.85,
    borderCustomB = 1.0,

    -- Map Opacity & Combat
    mapAlpha = 1.0,
    combatAlpha = 1.0,
    hideControlsInCombat = false,
    autoLockInCombat = true,
    hideQuestRing = true,
    widestOnLogin = true,
    locked = true,

    -- Coordinates
    showCoordinates = true,
    coordsPosition = "footer",    -- "footer", "topleft", "topright", "bottomleft", "bottomright"
    coordsFormat = "plain",       -- "plain" (45, 62), "parens" ((45, 62)), "labeled" (X: 45 | Y: 62)
    coordsPrecision = 0,          -- 0 or 1 decimal
    coordsColor = "cyan",         -- "cyan", "class", "gold", "white", "green"

    -- Zone Text
    showZone = true,
    zonePosition = "top",         -- "top", "inside_top", "inside_bottom", "footer"
    zoneColor = "gold",           -- "react", "class", "gold", "white", "cyan"
    zoneFontSize = 12,
    showSubzone = false,

    -- Mouse Wheel Zoom
    enableWheelZoom = true,
    zoomStep = 1,

    -- Footer / Header Control Elements
    showClock = true,
    showCalendar = true,
    showTracking = true,
    showCompartment = true,
    showDifficulty = true,
    showQueue = true,
    showGear = true,
    showBagBtn = false,

    -- Control Bar Layout & Spacing
    elementSpacing = 4,
    coordsClockOrder = "coords_clock",
    gearPosition = "row",         -- "row", "right", "left", "hidden"
    clockColor = "gold",          -- "gold", "white", "cyan", "class", "yellow"

    -- Addon Tray Integration
    dockBagLauncher = false,
    showBagBadge = false,
    redirectCompartmentClick = true,
}

local db = nil

local function InitDB()
    if not TimelessForeverMinimapDB then
        -- Attempt migration from SquareForeverMinimapDB if user previously used it
        if _G.SquareForeverMinimapDB and type(_G.SquareForeverMinimapDB) == "table" then
            local old = _G.SquareForeverMinimapDB
            TimelessForeverMinimapDB = {}
            for k, v in pairs(DEFAULT_DB) do TimelessForeverMinimapDB[k] = v end
            if old.size and old.size >= MINIMUM_SIZE then TimelessForeverMinimapDB.size = old.size end
            if old.x then TimelessForeverMinimapDB.x = old.x end
            if old.y then TimelessForeverMinimapDB.y = old.y end
            if old.iconScale then TimelessForeverMinimapDB.iconScale = old.iconScale end
            if old.footerScale then TimelessForeverMinimapDB.barScale = old.footerScale end
            if old.showCoordinates ~= nil then TimelessForeverMinimapDB.showCoordinates = old.showCoordinates end
            if old.showZone ~= nil then TimelessForeverMinimapDB.showZone = old.showZone end
            if old.hideQuestRing ~= nil then TimelessForeverMinimapDB.hideQuestRing = old.hideQuestRing end
            if old.widestOnLogin ~= nil then TimelessForeverMinimapDB.widestOnLogin = old.widestOnLogin end
        else
            TimelessForeverMinimapDB = {}
            for k, v in pairs(DEFAULT_DB) do TimelessForeverMinimapDB[k] = v end
        end
    else
        for k, v in pairs(DEFAULT_DB) do
            if TimelessForeverMinimapDB[k] == nil then
                TimelessForeverMinimapDB[k] = v
            end
        end
    end
    TimelessForeverMinimapDB.showBagBtn = false
    TimelessForeverMinimapDB.dockBagLauncher = false
    db = TimelessForeverMinimapDB
end

-- =========================================================================
-- Forward Declarations & Frames
-- =========================================================================
local holder, borderFrame, outerGlow, footerBar
local editor, grip, catcher
local customCoordsText, footerCoordsFrame, footerCoordsText, customSubzoneText
local settingsGearBtn, bagDockBtn
local applying = false
local pending = false
local fighting = false
local dragging = false
local resizing = false
local nativeSize = 140
local questRingChanged = false
local hiddenFrames = {}

-- Queue Eye management
local queueButton, queueAdopted, queueScale, queueAnchor

local Apply
local SavePosition
local StopEditing
local OpenOptionsDialog
local UpdateCoordinates

-- Global shape query for LibDBIcon and other addons
if _G.GetMinimapShape == nil then
    _G.GetMinimapShape = function()
        return (db and db.shape == "square") and "SQUARE" or "ROUND"
    end
end

local function MaximumSize()
    local w = (_G.UIParent and _G.UIParent:GetWidth()) or 1920
    local h = (_G.UIParent and _G.UIParent:GetHeight()) or 1080
    return math.max(MINIMUM_SIZE, math.min(w - 24, h - HEADER_SPACE - FOOTER_SPACE - 24))
end

local function Resolve(path)
    local value = _G
    for key in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return nil end
        value = value[key]
    end
    return value
end

local function HideDecoration(frame)
    if not frame then return end
    hiddenFrames[#hiddenFrames + 1] = frame
    frame:Hide()
    if frame.HookScript then
        frame:HookScript("OnShow", function(self)
            if _G.InCombatLockdown and _G.InCombatLockdown() then
                pending = true
            else
                self:Hide()
            end
        end)
    end
end

-- =========================================================================
-- Queue Status Eye Helpers (Safe Edit Mode Integration)
-- =========================================================================
local function QueueInRow()
    local EditMode = _G.EditModeManagerFrame
    return queueButton and (not EditMode or not EditMode:IsEditModeActive())
        and (queueButton.IsInDefaultPosition and queueButton:IsInDefaultPosition()) and true or false
end

local function BlizzardQueueAnchor()
    if not queueButton or not queueButton.GetPoint then return nil end
    local point, relativeTo, relativePoint, x, y = queueButton:GetPoint(1)
    if not point or relativeTo == footerBar then return nil end
    local s = queueButton:GetScale() or 1
    return { point, relativeTo, relativePoint, (x or 0) * s, (y or 0) * s }
end

local function ReleaseQueue()
    if not queueAdopted or not queueButton then return end
    queueAdopted = false
    local anchor = BlizzardQueueAnchor() or queueAnchor
    if queueButton.SetScaleBase then queueButton:SetScaleBase(queueScale or 1) end
    if not anchor then return end
    if queueButton.ClearAllPointsBase and queueButton.SetPointBase then
        queueButton:ClearAllPointsBase()
        local s = queueScale or 1
        queueButton:SetPointBase(anchor[1], anchor[2], anchor[3], anchor[4] / s, anchor[5] / s)
    end
end

-- =========================================================================
-- Quest Blob Ring Suppression
-- =========================================================================
local function ApplyQuestRing()
    local Minimap = _G.Minimap
    if not Minimap or not holder then return end
    if not (db.hideQuestRing or questRingChanged) then return end
    questRingChanged = true
    local scalar = db.hideQuestRing and 0 or 1
    if Minimap.SetQuestBlobRingScalar then
        Minimap:SetQuestBlobRingScalar(scalar)
    end
    if Minimap.SetTaskBlobRingScalar then
        Minimap:SetTaskBlobRingScalar(scalar)
    end
end

-- =========================================================================
-- Border Styling Engine
-- =========================================================================
local function UpdateBorder()
    if not borderFrame or not db then return end

    if db.borderStyle == "none" then
        borderFrame:Hide()
        if outerGlow then outerGlow:Hide() end
        return
    end

    borderFrame:Show()
    local r, g, b, a = GetColorRGB(db.borderColor, db.borderCustomR, db.borderCustomG, db.borderCustomB)

    local edgeSize = 1
    if db.borderStyle == "thin" then
        edgeSize = 1
    elseif db.borderStyle == "sleek" then
        edgeSize = 2
    elseif db.borderStyle == "thick" then
        edgeSize = 3
    elseif db.borderStyle == "double" then
        edgeSize = 2
    elseif db.borderStyle == "glow" then
        edgeSize = 2
    end

    if borderFrame.SetBackdrop then
        borderFrame:SetBackdrop({
            edgeFile = MASK_SQUARE,
            edgeSize = edgeSize,
        })
        borderFrame:SetBackdropBorderColor(r, g, b, a)
    end

    if db.borderStyle == "glow" then
        if not outerGlow then
            outerGlow = _G.CreateFrame("Frame", nil, holder, "BackdropTemplate")
            outerGlow:SetPoint("TOPLEFT", holder, "TOPLEFT", -2, 2)
            outerGlow:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 2, -2)
            outerGlow:SetFrameLevel(borderFrame:GetFrameLevel() - 1)
            outerGlow:EnableMouse(false)
        end
        outerGlow:Show()
        if outerGlow.SetBackdrop then
            outerGlow:SetBackdrop({
                edgeFile = MASK_SQUARE,
                edgeSize = 2,
            })
            outerGlow:SetBackdropBorderColor(r, g, b, 0.45)
        end
    elseif outerGlow then
        outerGlow:Hide()
    end
end

-- =========================================================================
-- Control Bar & Button Layout
-- =========================================================================
local function PlaceControl(frame, point, relativePoint, x, y)
    if not frame then return end
    frame:SetParent(holder)
    frame:SetScale(1)
    frame:ClearAllPoints()
    frame:SetPoint(point, holder, relativePoint, x, y)
    frame:SetFrameLevel(holder:GetFrameLevel() + 10)
end

local function LayoutControls(size)
    local cluster = _G.MinimapCluster
    if not cluster or not footerBar then return end

    -- Zone Text Button Placement
    if cluster.ZoneTextButton then
        cluster.ZoneTextButton:ClearAllPoints()
        if db.zonePosition == "top" then
            PlaceControl(cluster.ZoneTextButton, "BOTTOM", "TOP", 0, 6)
        elseif db.zonePosition == "inside_top" then
            PlaceControl(cluster.ZoneTextButton, "TOP", "TOP", 0, -4)
        elseif db.zonePosition == "inside_bottom" then
            PlaceControl(cluster.ZoneTextButton, "BOTTOM", "BOTTOM", 0, 4)
        else
            cluster.ZoneTextButton:SetParent(footerBar)
            cluster.ZoneTextButton:SetPoint("CENTER", footerBar, "CENTER", 0, 0)
        end
        cluster.ZoneTextButton:SetWidth(size)
        if _G.MinimapZoneText then
            _G.MinimapZoneText:SetWidth(size)
            -- Font sizing
            local font, _, flags = _G.MinimapZoneText:GetFont()
            if font then
                _G.MinimapZoneText:SetFont(font, db.zoneFontSize or 12, flags or "OUTLINE")
            end
            -- Color tint
            if db.zoneColor == "react" then
                -- Blizzard manages pvp color natively
            else
                local zr, zg, zb = GetColorRGB(db.zoneColor)
                _G.MinimapZoneText:SetTextColor(zr, zg, zb, 1)
            end
        end
        cluster.ZoneTextButton:SetShown(db.showZone)
    end

    -- Footbar / Control Bar Buttons
    local controls = {}

    if bagDockBtn then
        bagDockBtn:Hide()
    end

    -- 2. Coordinates & Clock (Ordered cleanly without overlapping)
    local addCoords = (db.showCoordinates and db.coordsPosition == "footer" and footerCoordsFrame)
    local addClock = (db.showClock and _G.TimeManagerClockButton)

    if db.coordsClockOrder == "clock_coords" then
        if addClock then table.insert(controls, _G.TimeManagerClockButton) end
        if addCoords then table.insert(controls, footerCoordsFrame) end
    else
        if addCoords then table.insert(controls, footerCoordsFrame) end
        if addClock then table.insert(controls, _G.TimeManagerClockButton) end
    end

    -- Style Clock Button
    if _G.TimeManagerClockButton then
        if db.showClock then
            _G.TimeManagerClockButton:Show()
            _G.TimeManagerClockButton:SetParent(footerBar)
            if _G.TimeManagerClockTicker then
                _G.TimeManagerClockTicker:ClearAllPoints()
                _G.TimeManagerClockTicker:SetPoint("CENTER", _G.TimeManagerClockButton, "CENTER", 0, 0)
                if db.clockColor then
                    local cr, cg, cb = GetColorRGB(db.clockColor)
                    _G.TimeManagerClockTicker:SetTextColor(cr, cg, cb, 1)
                end
            end
            if _G.TimeManagerClockButton.GetNormalTexture and _G.TimeManagerClockButton:GetNormalTexture() then
                _G.TimeManagerClockButton:GetNormalTexture():SetAlpha(0)
            end
        else
            _G.TimeManagerClockButton:Hide()
        end
    end

    -- 3. Tracking Icon
    if db.showTracking and cluster.Tracking then
        table.insert(controls, cluster.Tracking)
        cluster.Tracking:Show()
    elseif cluster.Tracking then
        cluster.Tracking:Hide()
    end

    -- 4. Addon Compartment (Include text count in frame dimensions so it doesn't overlap)
    if db.showCompartment and _G.AddonCompartmentFrame then
        table.insert(controls, _G.AddonCompartmentFrame)
        _G.AddonCompartmentFrame:Show()
        local txt = _G.AddonCompartmentFrame.Text
        if txt and txt:IsShown() then
            txt:ClearAllPoints()
            txt:SetPoint("LEFT", _G.AddonCompartmentFrame, "RIGHT", -2, 0)
        end
    elseif _G.AddonCompartmentFrame then
        _G.AddonCompartmentFrame:Hide()
    end

    -- 5. Calendar / Day-Night Sun Icon
    if db.showCalendar and _G.GameTimeFrame then
        table.insert(controls, _G.GameTimeFrame)
        _G.GameTimeFrame:Show()
    elseif _G.GameTimeFrame then
        _G.GameTimeFrame:Hide()
    end

    -- 6. Instance Difficulty (only when inside dungeon/raid)
    if db.showDifficulty and cluster.InstanceDifficulty and cluster.InstanceDifficulty:IsShown() then
        table.insert(controls, cluster.InstanceDifficulty)
    end

    -- 7. Settings Gear (when in row)
    if db.showGear and settingsGearBtn and (db.gearPosition == "row" or not db.gearPosition) then
        table.insert(controls, settingsGearBtn)
        settingsGearBtn:Show()
    end

    -- Hide Blizzard clutter frames that create empty space
    if cluster.DielFrame then cluster.DielFrame:Hide() end
    if cluster.GamepadButtons and not (_G.C_GamePad and _G.C_GamePad.IsEnabled and _G.C_GamePad.IsEnabled()) then
        cluster.GamepadButtons:Hide()
    end
    if _G.ExpansionLandingPageMinimapButton then
        local normalTex = _G.ExpansionLandingPageMinimapButton.GetNormalTexture and _G.ExpansionLandingPageMinimapButton:GetNormalTexture()
        if normalTex and normalTex:GetTexture() and normalTex:GetTexture() ~= "" then
            table.insert(controls, _G.ExpansionLandingPageMinimapButton)
        else
            _G.ExpansionLandingPageMinimapButton:Hide()
        end
    end
    if cluster.MinimapContainer and cluster.MinimapContainer.PlayerCoords then
        cluster.MinimapContainer.PlayerCoords:Hide()
    end

    -- 8. Sequential Layout with customizable spacing
    local width = 0
    local spacing = db.elementSpacing or 4

    local function GetElementDimensions(frame)
        if not frame then return 0, 0 end
        if frame == footerCoordsFrame then
            local tw = (footerCoordsText and footerCoordsText:GetStringWidth()) or 36
            return math.max(38, tw + 6), 20
        elseif frame == _G.TimeManagerClockButton then
            local tw = (_G.TimeManagerClockTicker and _G.TimeManagerClockTicker:GetStringWidth()) or 32
            return math.max(36, tw + 8), 20
        elseif frame == _G.AddonCompartmentFrame then
            local countW = 0
            local txt = _G.AddonCompartmentFrame.Text
            if txt and txt:IsShown() and txt:GetText() and txt:GetText() ~= "" then
                countW = txt:GetStringWidth() or 0
            end
            return math.max(18, 18 + countW + (countW > 0 and 4 or 0)), 20
        else
            local w = frame:GetWidth() or 20
            local h = frame:GetHeight() or 20
            return math.max(16, w), math.max(16, h)
        end
    end

    for _, frame in ipairs(controls) do
        frame:SetParent(footerBar)
        local frameW, frameH = GetElementDimensions(frame)
        local scale = math.min(1, 20 / math.max(1, frameH))
        frame:SetScale(scale)
        frame:ClearAllPoints()
        local scaledW = frameW * scale
        frame:SetWidth(frameW)
        frame:SetPoint("CENTER", footerBar, "LEFT", (width + scaledW / 2) / scale, 0)
        width = width + scaledW + spacing
    end

    if width > 0 then
        width = width - spacing
    end

    -- 9. Group Finder / Queue Status Eye
    local queueX, queueRelative
    if db.showQueue and QueueInRow() then
        queueAnchor = BlizzardQueueAnchor() or queueAnchor
        if not queueAdopted then queueScale = queueButton:GetScale() end
        queueAdopted = true
        local eyeH = (queueButton.Eye and queueButton.Eye:GetHeight()) or 20
        queueRelative = 20 / math.max(1, eyeH) * (queueScale or 1)
        local queueW = (queueButton:GetWidth() or 20) * queueRelative
        queueX = width + spacing + queueW / 2
        if queueButton:IsShown() then
            width = width + spacing + queueW
        end
    else
        ReleaseQueue()
    end

    -- 10. Dedicated Gear Positioning (when set to "right" or "left")
    if db.showGear and settingsGearBtn and db.gearPosition == "right" then
        settingsGearBtn:SetParent(holder)
        settingsGearBtn:SetScale(1)
        settingsGearBtn:ClearAllPoints()
        settingsGearBtn:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -2, -14)
        settingsGearBtn:Show()
    elseif db.showGear and settingsGearBtn and db.gearPosition == "left" then
        settingsGearBtn:SetParent(holder)
        settingsGearBtn:SetScale(1)
        settingsGearBtn:ClearAllPoints()
        settingsGearBtn:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 2, -14)
        settingsGearBtn:Show()
    elseif not db.showGear or db.gearPosition == "hidden" then
        if settingsGearBtn then settingsGearBtn:Hide() end
    end

    -- 11. Sizing and placement of footerBar
    width = math.max(1, width)
    local barScale = math.min(db.barScale or 1.0, size / width)
    footerBar:SetSize(width, 20)
    footerBar:SetScale(barScale)
    footerBar:ClearAllPoints()

    if db.barPosition == "top" then
        footerBar:SetPoint("BOTTOM", holder, "TOP", 0, 2 / barScale)
    else
        footerBar:SetPoint("TOP", holder, "BOTTOM", 0, -2 / barScale)
    end

    if queueX and queueButton and queueButton.SetScaleBase then
        queueButton:SetScaleBase(queueRelative * footerBar:GetEffectiveScale() / (queueButton:GetParent():GetEffectiveScale() or 1))
        if queueButton.ClearAllPointsBase and queueButton.SetPointBase then
            queueButton:ClearAllPointsBase()
            queueButton:SetPointBase("CENTER", footerBar, "LEFT", queueX / queueRelative, 0)
        end
    end

    -- Combat Visibility
    if fighting and db.hideControlsInCombat then
        footerBar:Hide()
    else
        footerBar:Show()
    end
end

-- =========================================================================
-- Custom Coordinates System (Screen / Corner & Footer Anchors)
-- =========================================================================
local function CreateCoordinatesEngine()
    if customCoordsText then return end

    -- Corner coordinates frame
    local coordFrame = _G.CreateFrame("Frame", "TimelessForever_Minimap_CornerCoords", holder)
    coordFrame:SetAllPoints()
    coordFrame:SetFrameLevel(holder:GetFrameLevel() + 12)

    customCoordsText = coordFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    customCoordsText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    customCoordsText:SetText("00, 00")

    -- Footer coordinates container (strictly sized to prevent overlapping)
    footerCoordsFrame = _G.CreateFrame("Frame", "TimelessForever_Minimap_FooterCoords", footerBar)
    footerCoordsFrame:SetHeight(20)
    footerCoordsFrame:SetWidth(44)

    footerCoordsText = footerCoordsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerCoordsText:SetPoint("CENTER", footerCoordsFrame, "CENTER", 0, 0)
    footerCoordsText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    footerCoordsText:SetText("00, 00")

    local elapsed = 0
    coordFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.15 then return end
        elapsed = 0
        UpdateCoordinates()
    end)
end

UpdateCoordinates = function()
    if not db or not db.showCoordinates then
        if customCoordsText then customCoordsText:Hide() end
        if footerCoordsFrame then footerCoordsFrame:Hide() end
        if _G.MinimapCluster and _G.MinimapCluster.MinimapContainer and _G.MinimapCluster.MinimapContainer.PlayerCoords then
            _G.MinimapCluster.MinimapContainer.PlayerCoords:Hide()
        end
        return
    end

    local mapID = _G.C_Map and _G.C_Map.GetBestMapForUnit and _G.C_Map.GetBestMapForUnit("player")
    local pos = mapID and _G.C_Map.GetPlayerMapPosition and _G.C_Map.GetPlayerMapPosition(mapID, "player")

    local coordStr = "--, --"
    if pos and pos.x and pos.y and (pos.x > 0 or pos.y > 0) then
        local x = pos.x * 100
        local y = pos.y * 100
        local prec = db.coordsPrecision or 0

        local strX = string.format("%." .. prec .. "f", x)
        local strY = string.format("%." .. prec .. "f", y)

        if db.coordsFormat == "parens" then
            coordStr = string.format("(%s, %s)", strX, strY)
        elseif db.coordsFormat == "labeled" then
            coordStr = string.format("X: %s | Y: %s", strX, strY)
        else
            coordStr = string.format("%s, %s", strX, strY)
        end
    end

    local cr, cg, cb = GetColorRGB(db.coordsColor or "cyan")

    -- Footer position
    if db.coordsPosition == "footer" then
        if customCoordsText then customCoordsText:Hide() end
        if footerCoordsFrame and footerCoordsText then
            footerCoordsFrame:Show()
            footerCoordsText:SetText(coordStr)
            footerCoordsText:SetTextColor(cr, cg, cb, 1)
            local tw = footerCoordsText:GetStringWidth() or 36
            local newW = math.max(38, tw + 6)
            if math.abs((footerCoordsFrame:GetWidth() or 0) - newW) > 2 then
                footerCoordsFrame:SetWidth(newW)
            end
        end
    else
        -- Corner position
        if footerCoordsFrame then footerCoordsFrame:Hide() end
        if customCoordsText then
            customCoordsText:ClearAllPoints()
            if db.coordsPosition == "topleft" then
                customCoordsText:SetPoint("TOPLEFT", holder, "TOPLEFT", 6, -6)
            elseif db.coordsPosition == "topright" then
                customCoordsText:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -6, -6)
            elseif db.coordsPosition == "bottomleft" then
                customCoordsText:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 6, 6)
            elseif db.coordsPosition == "bottomright" then
                customCoordsText:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -6, 6)
            end
            customCoordsText:Show()
            customCoordsText:SetText(coordStr ~= "--, --" and coordStr or "")
            customCoordsText:SetTextColor(cr, cg, cb, 1)
        end
    end

    -- Always keep Blizzard's native PlayerCoords frame hidden to prevent overlapping text
    if _G.MinimapCluster and _G.MinimapCluster.MinimapContainer and _G.MinimapCluster.MinimapContainer.PlayerCoords then
        _G.MinimapCluster.MinimapContainer.PlayerCoords:Hide()
    end
end

-- =========================================================================
-- Main Apply & Geometric Layout Engine
-- =========================================================================
Apply = function()
    if not holder or applying then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        pending = true
        return
    end

    applying = true
    pending = false

    local cluster = _G.MinimapCluster
    local Minimap = _G.Minimap
    if not cluster or not Minimap then
        applying = false
        return
    end

    -- Sync coordinate system to screen scale
    local uScale = (_G.UIParent and _G.UIParent:GetEffectiveScale()) or 1
    local cScale = (cluster.GetEffectiveScale and cluster:GetEffectiveScale()) or 1
    holder:SetScale(uScale / cScale)

    local size = math.max(MINIMUM_SIZE, math.min(db.size, MaximumSize()))
    local x = math.max(size - _G.UIParent:GetWidth(), math.min(0, db.x))
    local y = math.max(size + FOOTER_SPACE - _G.UIParent:GetHeight(), math.min(-HEADER_SPACE, db.y))

    holder:ClearAllPoints()
    holder:SetPoint("TOPRIGHT", _G.UIParent, "TOPRIGHT", x, y)
    holder:SetSize(size, size)

    -- Sizing Minimap visually via Scale to preserve engine blip projection
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", holder, "CENTER", 0, 0)
    Minimap:SetSize(nativeSize, nativeSize)
    Minimap:SetScale(size / nativeSize)
    if Minimap.SetIconScale then
        Minimap:SetIconScale(db.iconScale or 1.0)
    end

    -- Shape Mask Application
    if db.shape == "square" then
        Minimap:SetMaskTexture(MASK_SQUARE)
    else
        Minimap:SetMaskTexture(MASK_CIRCLE)
    end

    -- Opacity
    local alpha = fighting and (db.combatAlpha or 1.0) or (db.mapAlpha or 1.0)
    Minimap:SetAlpha(alpha)

    -- Border
    UpdateBorder()

    -- Quest area ring scalar
    ApplyQuestRing()

    -- Catcher frame strata & mouse level
    if catcher then
        catcher:SetFrameLevel(math.min(Minimap:GetFrameLevel() + 1, holder:GetFrameLevel() + 9))
    end

    -- Update Bar and Controls
    LayoutControls(size)
    UpdateCoordinates()

    -- Ensure hidden frames stay hidden
    for _, frame in ipairs(hiddenFrames) do
        frame:Hide()
    end

    -- Inform TimelessForever_MinimapBag of square shape & dock status
    local shouldDock = (db.dockBagLauncher and db.showBagBtn) and true or false
    if _G.TimelessMinimapBagDB then
        _G.TimelessMinimapBagDB.minimapShape = db.shape
        _G.TimelessMinimapBagDB.dockBagLauncher = shouldDock
    end
    if _G.TimelessForever_MinimapBag_SetDocked then
        _G.TimelessForever_MinimapBag_SetDocked(shouldDock)
    elseif _G.TimelessForever_MinimapBagButton then
        if shouldDock then
            _G.TimelessForever_MinimapBagButton:Hide()
        else
            _G.TimelessForever_MinimapBagButton:Show()
        end
    end

    applying = false
end

-- =========================================================================
-- Dragging, Sizing & Lock/Unlock Mechanics
-- =========================================================================
SavePosition = function()
    if not holder or not _G.UIParent then return end
    local right, top = holder:GetRight(), holder:GetTop()
    if right and top then
        db.x = right - _G.UIParent:GetWidth()
        db.y = top - _G.UIParent:GetHeight()
    end
end

StopEditing = function()
    if not holder then return end
    if editor then editor:SetScript("OnUpdate", nil) end
    if dragging then holder:StopMovingOrSizing() end
    if dragging or resizing then SavePosition() end
    dragging, resizing = false, false
    if not _G.InCombatLockdown or not _G.InCombatLockdown() then
        Apply()
    else
        pending = true
    end
end

local function ApplyCtrl()
    if not (catcher and editor) or (_G.InCombatLockdown and _G.InCombatLockdown()) then return end
    local take = not fighting and not editor:IsShown() and _G.IsControlKeyDown() == true
    catcher:EnableMouse(take)
    if not take and _G.GameTooltip:IsOwned(catcher) then _G.GameTooltip:Hide() end
end

local function LockChanged()
    ApplyCtrl()
    if _G.GameTooltip:IsOwned(editor) and not editor:IsShown() then
        _G.GameTooltip:Hide()
    end
    if AceConfigRegistry then
        pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessForeverMinimap")
        pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessForever")
    end
end

local function UnlockMinimap()
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Cannot unlock minimap during combat.")
        return
    end
    db.locked = false
    if editor then editor:Show() end
    LockChanged()
    _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Minimap |cff00ff00Unlocked|r. Drag overlay to move, bottom-left corner to resize. Ctrl+Click to lock.")
end

local function LockMinimap()
    StopEditing()
    SavePosition()
    db.size = holder:GetWidth()
    db.locked = true
    if editor then editor:Hide() end
    LockChanged()
    _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Minimap |cffff9900Locked|r and layout saved.")
end

-- =========================================================================
-- Integrated Bag Button in Control Bar
-- =========================================================================
local function CreateBagDockButton(parent)
    local btn = _G.CreateFrame("Button", "TimelessForever_Minimap_BagDockBtn", parent, "BackdropTemplate")
    btn:SetSize(20, 20)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(16, 16)
    icon:SetTexture("Interface\\ICONS\\artifactability_FireMage_PhoenixBolt")

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")

    -- Badge text for button count
    local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
    badge:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    badge:SetTextColor(0, 0.85, 1, 1)
    badge:SetText("")

    local function RefreshBadge()
        if not db or not db.showBagBadge then
            badge:SetText("")
            return
        end
        local count = 0
        if _G.TimelessForever_MinimapBag_GetButtonCount then
            count = _G.TimelessForever_MinimapBag_GetButtonCount()
        elseif _G.collectedButtons then
            count = #_G.collectedButtons
        end
        badge:SetText(count > 0 and tostring(count) or "")
    end

    btn:SetScript("OnEnter", function(self)
        RefreshBadge()
        if _G.TimelessForever_MinimapBag_Show then
            _G.TimelessForever_MinimapBag_Show()
        end
        _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        _G.GameTooltip:ClearLines()
        _G.GameTooltip:AddLine(BRAND_TITLE .. " Bag", 1, 1, 1)
        _G.GameTooltip:AddLine("Hover or Left-Click: Open / Close Button Bag", 0.85, 0.85, 0.85)
        _G.GameTooltip:AddLine("Right-Click: Bag Options", 0.7, 0.7, 0.7)
        if _G.TimelessForever_MinimapBag_GetButtonCount then
            _G.GameTooltip:AddLine(string.format("|cff00ccffCollected Buttons:|r %d", _G.TimelessForever_MinimapBag_GetButtonCount()), 0.9, 0.9, 0.9)
        end
        _G.GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        _G.GameTooltip:Hide()
        if _G.TimelessForever_MinimapBag_CheckHover then
            _G.TimelessForever_MinimapBag_CheckHover()
        end
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if _G.TimelessForever_MinimapBag_OpenOptions then
                _G.TimelessForever_MinimapBag_OpenOptions()
            elseif _G.SlashCmdList["TIMELESSMINIMAPBAG"] then
                _G.SlashCmdList["TIMELESSMINIMAPBAG"]("opt")
            end
        else
            if _G.TimelessForever_MinimapBag_Toggle then
                _G.TimelessForever_MinimapBag_Toggle()
            elseif _G.SlashCmdList["TIMELESSMINIMAPBAG"] then
                _G.SlashCmdList["TIMELESSMINIMAPBAG"]("")
            end
        end
        RefreshBadge()
    end)

    btn.RefreshBadge = RefreshBadge
    return btn
end

-- =========================================================================
-- Settings Gear Button in Control Bar
-- =========================================================================
local function CreateSettingsGearButton(parent)
    local btn = _G.CreateFrame("Button", "TimelessForever_Minimap_GearBtn", parent, "BackdropTemplate")
    btn:SetSize(20, 20)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local gear = btn:CreateTexture(nil, "ARTWORK")
    gear:SetPoint("CENTER")
    gear:SetSize(15, 15)
    gear:SetTexture("Interface\\WorldMap\\Gear_64Grey")
    gear:SetVertexColor(0.85, 0.85, 0.88, 1)

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")

    btn:SetScript("OnEnter", function(self)
        gear:SetVertexColor(1.0, 0.82, 0.0, 1)
        _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        _G.GameTooltip:ClearLines()
        _G.GameTooltip:AddLine(BRAND_TITLE, 1, 1, 1)
        _G.GameTooltip:AddLine("Left-Click: Minimap Settings", 0.85, 0.85, 0.85)
        _G.GameTooltip:AddLine("Right-Click: TimelessForever Suite Hub", 0.7, 0.7, 0.7)
        _G.GameTooltip:AddLine("Shift-Click: Lock / Unlock Minimap", 0.7, 0.7, 0.7)
        _G.GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        gear:SetVertexColor(0.85, 0.85, 0.88, 1)
        _G.GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self, button)
        if _G.IsShiftKeyDown() then
            if db.locked then UnlockMinimap() else LockMinimap() end
        elseif button == "RightButton" then
            if _G.TimelessForeverSuite and _G.TimelessForeverSuite.OpenSettings then
                _G.TimelessForeverSuite:OpenSettings("minimap")
            else
                OpenOptionsDialog()
            end
        else
            OpenOptionsDialog()
        end
    end)

    return btn
end

-- =========================================================================
-- Interactive Editing Overlay & Resize Grip
-- =========================================================================
local function CreateEditorOverlay()
    if editor then return end

    -- Locked catcher for Ctrl+click unlocking
    catcher = _G.CreateFrame("Button", nil, holder)
    catcher:SetAllPoints(holder)
    catcher:EnableMouse(false)
    catcher:RegisterForClicks("LeftButtonUp")
    catcher:SetScript("OnClick", function()
        if _G.IsControlKeyDown() then UnlockMinimap() end
    end)
    catcher:SetScript("OnEnter", function(self)
        _G.GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        _G.GameTooltip:SetText("TimelessForever Minimap")
        _G.GameTooltip:AddLine("Ctrl+Click: Unlock minimap to move/resize", 0.85, 0.85, 0.85)
        _G.GameTooltip:Show()
    end)
    catcher:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
    catcher:SetScript("OnShow", ApplyCtrl)

    -- Editor Frame
    editor = _G.CreateFrame("Frame", nil, holder, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
    editor:SetAllPoints(holder)
    editor:SetFrameLevel(_G.Minimap:GetFrameLevel() + 20)
    editor:EnableMouse(true)
    editor:RegisterForDrag("LeftButton")
    if editor.SetBackdrop then
        editor:SetBackdrop({
            bgFile = MASK_SQUARE,
            edgeFile = MASK_SQUARE,
            edgeSize = 2,
        })
        editor:SetBackdropColor(0.0, 0.65, 1.0, 0.22)
        editor:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.85)
    else
        local tint = editor:CreateTexture(nil, "OVERLAY")
        tint:SetAllPoints()
        tint:SetColorTexture(0.0, 0.65, 1.0, 0.22)
    end

    local label = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText("|cff00ccffTimelessForever Minimap|r\n\n|cffffffffDrag|r to move\n|cffffd100Drag Corner|r to resize\n|cffff5555Ctrl+Click|r to lock")

    local resizeData
    local function Follow()
        if (_G.InCombatLockdown and _G.InCombatLockdown()) or not _G.IsMouseButtonDown("LeftButton") then
            StopEditing()
            return
        end
        if not (resizing and resizeData) then return end
        local cx, cy = _G.GetCursorPosition()
        local dx = resizeData.x - cx
        local dy = resizeData.y - cy
        local delta = (math.abs(dx) > math.abs(dy) and dx or dy) / (_G.UIParent:GetEffectiveScale() or 1)
        local available = math.min(_G.UIParent:GetWidth() + db.x, _G.UIParent:GetHeight() + db.y - FOOTER_SPACE)
        db.size = math.max(MINIMUM_SIZE, math.min(resizeData.size + delta, MaximumSize(), available))
        Apply()
    end

    local pressed
    editor:SetScript("OnMouseDown", function(_, button)
        pressed = (button == "LeftButton")
    end)

    editor:SetScript("OnDragStart", function()
        pressed = false
        if _G.InCombatLockdown and _G.InCombatLockdown() then return end
        dragging = true
        holder:StartMoving()
        editor:SetScript("OnUpdate", Follow)
    end)

    editor:SetScript("OnMouseUp", function(_, button)
        local click = pressed and (button == "LeftButton")
        pressed = false
        if click and _G.IsControlKeyDown() then
            LockMinimap()
        end
    end)

    editor:SetScript("OnDragStop", StopEditing)
    editor:SetScript("OnHide", StopEditing)

    -- Resize Grip (6-dot corner grip in bottom-left)
    local GRIP_DOTS = { { 0, 0 }, { 4, 0 }, { 8, 0 }, { 0, 4 }, { 4, 4 }, { 0, 8 } }
    grip = _G.CreateFrame("Button", nil, editor)
    grip:SetFrameLevel(editor:GetFrameLevel() + 1)
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 2, 2)
    grip:RegisterForClicks("LeftButtonUp")
    grip.dots = {}

    for _, at in ipairs(GRIP_DOTS) do
        local dot = grip:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(MASK_SQUARE)
        dot:SetSize(2, 2)
        dot:SetPoint("BOTTOMLEFT", grip, "BOTTOMLEFT", 3 + at[1], 3 + at[2])
        dot:SetVertexColor(COLOR_GREY[1], COLOR_GREY[2], COLOR_GREY[3], 1)
        grip.dots[#grip.dots + 1] = dot
    end

    local function PaintGrip(color)
        for _, dot in ipairs(grip.dots) do
            dot:SetVertexColor(color[1], color[2], color[3], 1)
        end
    end

    grip:SetScript("OnEnter", function()
        PaintGrip(COLOR_GOLD)
        _G.GameTooltip:SetOwner(grip, "ANCHOR_TOPRIGHT")
        _G.GameTooltip:SetText("Drag to resize. Double-click for default size.")
        _G.GameTooltip:Show()
    end)

    grip:SetScript("OnLeave", function()
        if not resizing then PaintGrip(COLOR_GREY) end
        _G.GameTooltip:Hide()
    end)

    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or (_G.InCombatLockdown and _G.InCombatLockdown()) then return end
        _G.GameTooltip:Hide()
        SavePosition()
        resizing = true
        local cx, cy = _G.GetCursorPosition()
        resizeData = { x = cx, y = cy, size = holder:GetWidth() }
        editor:SetScript("OnUpdate", Follow)
    end)

    grip:SetScript("OnMouseUp", function()
        StopEditing()
        if not grip:IsMouseOver() then PaintGrip(COLOR_GREY) end
    end)

    grip:SetScript("OnDoubleClick", function()
        db.size = DEFAULT_SIZE
        Apply()
    end)

    editor:Hide()
end

-- =========================================================================
-- Mouse Wheel Zooming Engine
-- =========================================================================
local function SetupMouseWheelZoom()
    local Minimap = _G.Minimap
    if not Minimap then return end

    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if not db or not db.enableWheelZoom then return end
        local step = db.zoomStep or 1
        local currentZoom = Minimap:GetZoom() or 0
        local levels = Minimap:GetZoomLevels() or 5

        if delta > 0 then
            Minimap:SetZoom(math.min(levels, currentZoom + step))
        else
            Minimap:SetZoom(math.max(0, currentZoom - step))
        end
    end)
end

-- =========================================================================
-- Core Start & Initialization
-- =========================================================================
local function Start()
    if holder or not db then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        pending = true
        return
    end

    local Minimap = _G.Minimap
    local cluster = _G.MinimapCluster
    if not Minimap or not cluster then return end

    nativeSize = Minimap:GetWidth() or 140

    -- Holder frame
    holder = _G.CreateFrame("Frame", "TimelessForever_MinimapHolder", cluster)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    holder:SetFrameStrata("LOW")

    -- Border frame
    borderFrame = _G.CreateFrame("Frame", nil, holder, "BackdropTemplate")
    borderFrame:SetAllPoints(holder)
    borderFrame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    borderFrame:EnableMouse(false)

    -- Footer / Control Bar
    footerBar = _G.CreateFrame("Frame", "TimelessForever_MinimapFooter", holder)
    footerBar:SetFrameLevel(holder:GetFrameLevel() + 10)

    -- Control buttons
    settingsGearBtn = CreateSettingsGearButton(footerBar)
    bagDockBtn = CreateBagDockButton(footerBar)

    -- Reparent Minimap
    Minimap:SetParent(holder)
    cluster:EnableMouse(false)

    -- Hide native circular textures
    local circularDecorations = {
        cluster.BorderTop,
        cluster.GamepadHudBackground,
        Minimap.ZoomIn,
        Minimap.ZoomOut,
        Minimap.ZoomHitArea,
    }
    for _, f in ipairs(circularDecorations) do
        HideDecoration(f)
    end

    if _G.MinimapCompassTexture then _G.MinimapCompassTexture:SetAlpha(0) end
    if _G.MinimapCompassTextureUnderlay then _G.MinimapCompassTextureUnderlay:SetAlpha(0) end

    -- Hook native scaling and layout methods safely
    if cluster.SetScale then hooksecurefunc(cluster, "SetScale", Apply) end
    if cluster.SetEditModeScale then hooksecurefunc(cluster, "SetEditModeScale", Apply) end
    if cluster.SetIconScale then hooksecurefunc(cluster, "SetIconScale", Apply) end
    if cluster.SetHeaderUnderneath then hooksecurefunc(cluster, "SetHeaderUnderneath", Apply) end
    if _G.MiniMapIndicatorFrame_UpdatePosition then
        hooksecurefunc("MiniMapIndicatorFrame_UpdatePosition", Apply)
    end

    -- Setup Editor Overlay & Grip
    CreateEditorOverlay()

    -- Setup Coordinates Engine
    CreateCoordinatesEngine()

    -- Setup Mouse Wheel Zoom
    SetupMouseWheelZoom()

    -- Hook button show/hide events to refresh bar width
    local barButtons = {
        cluster.Tracking,
        _G.AddonCompartmentFrame,
        cluster.InstanceDifficulty,
        _G.ExpansionLandingPageMinimapButton,
        cluster.GamepadButtons,
        _G.TimeManagerClockButton,
        _G.GameTimeFrame,
    }
    for _, f in ipairs(barButtons) do
        if f and f.HookScript then
            f:HookScript("OnShow", Apply)
            f:HookScript("OnHide", Apply)
        end
    end

    -- Setup Queue Status Button
    if _G.QueueStatusButton then
        queueButton = _G.QueueStatusButton
        queueButton:HookScript("OnShow", Apply)
        queueButton:HookScript("OnHide", Apply)
        if queueButton.UpdateDefaultAnchor then
            hooksecurefunc(queueButton, "UpdateDefaultAnchor", Apply)
        end
        if queueButton.UpdateSystemSettingSize then
            hooksecurefunc(queueButton, "UpdateSystemSettingSize", function()
                queueScale = queueButton:GetScale()
                Apply()
            end)
        end
        if _G.EventRegistry and _G.EventRegistry.RegisterCallback then
            pcall(_G.EventRegistry.RegisterCallback, _G.EventRegistry, "EditMode.Enter", Apply, ns)
            pcall(_G.EventRegistry.RegisterCallback, _G.EventRegistry, "EditMode.Exit", Apply, ns)
        end
    end

    Apply()

    if db.widestOnLogin then
        Minimap:SetZoom(0)
    end

    if not db.locked then
        editor:Show()
    end
end

-- =========================================================================
-- Options Table (AceConfig-3.0 & Suite Integration)
-- =========================================================================
local function BuildOptionsTable()
    local options = {
        name = "TimelessForever Minimap",
        type = "group",
        args = {
            generalHeader = {
                name = "Minimap Geometry & Shape",
                type = "header",
                order = 1,
            },
            shape = {
                name = "Minimap Shape",
                desc = "Choose between sleek Square minimap or classic Round minimap.",
                type = "select",
                order = 2,
                values = {
                    ["square"] = "Sleek Square (Recommended)",
                    ["circle"] = "Classic Circle",
                },
                get = function() return db.shape end,
                set = function(_, val)
                    db.shape = val
                    Apply()
                end,
            },
            size = {
                name = "Minimap Size (Side Length)",
                desc = "Adjust the physical pixel size of the minimap (160px to 450px).",
                type = "range",
                order = 3,
                min = 160,
                max = 450,
                step = 5,
                get = function() return db.size end,
                set = function(_, val)
                    db.size = val
                    Apply()
                end,
            },
            iconScale = {
                name = "Blip / Icon Scale",
                desc = "Scale factor for tracking blips and quest markers on the map.",
                type = "range",
                order = 4,
                min = 0.5,
                max = 2.0,
                step = 0.1,
                isPercent = true,
                get = function() return db.iconScale end,
                set = function(_, val)
                    db.iconScale = val
                    Apply()
                end,
            },
            locked = {
                name = "Lock Position & Size",
                desc = "Lock the minimap to prevent accidental dragging. When unlocked, an overlay appears with drag-to-move and corner resize.",
                type = "toggle",
                order = 5,
                get = function() return db.locked end,
                set = function(_, val)
                    if val then LockMinimap() else UnlockMinimap() end
                end,
            },
            presetGroup = {
                name = "Quick Size & Snap Presets",
                type = "group",
                inline = true,
                order = 6,
                args = {
                    snapTopRight = {
                        name = "Snap Top-Right",
                        type = "execute",
                        order = 1,
                        func = function()
                            db.x = -16
                            db.y = -16
                            Apply()
                        end,
                    },
                    snapTopLeft = {
                        name = "Snap Top-Left",
                        type = "execute",
                        order = 2,
                        func = function()
                            db.x = db.size - _G.UIParent:GetWidth() + 16
                            db.y = -16
                            Apply()
                        end,
                    },
                    sizeCompact = {
                        name = "Compact (190px)",
                        type = "execute",
                        order = 3,
                        func = function() db.size = 190; Apply() end,
                    },
                    sizeStandard = {
                        name = "Standard (240px)",
                        type = "execute",
                        order = 4,
                        func = function() db.size = 240; Apply() end,
                    },
                    sizeLarge = {
                        name = "Large (300px)",
                        type = "execute",
                        order = 5,
                        func = function() db.size = 300; Apply() end,
                    },
                },
            },
            borderHeader = {
                name = "Custom Border Styling (Live Preview)",
                type = "header",
                order = 10,
            },
            borderStyle = {
                name = "Border Style",
                desc = "Select frame outline border style.",
                type = "select",
                order = 11,
                values = {
                    ["thin"] = "Thin 1px Line (Clean Minimalist)",
                    ["sleek"] = "Sleek 2px Border",
                    ["thick"] = "Thick 3px Bold Frame",
                    ["glow"] = "Neon Glow Outline",
                    ["none"] = "None (Borderless Edge-to-Edge)",
                },
                get = function() return db.borderStyle end,
                set = function(_, val)
                    db.borderStyle = val
                    UpdateBorder()
                end,
            },
            borderColor = {
                name = "Border Color Preset",
                desc = "Color tint applied to the minimap border.",
                type = "select",
                order = 12,
                values = {
                    ["cyan"] = "Timeless Cyan (#00ccff)",
                    ["class"] = "Player Class Color",
                    ["gold"] = "Royal Gold (#ffd100)",
                    ["green"] = "Fel Green (#1eff00)",
                    ["purple"] = "Void Purple (#a335ee)",
                    ["red"] = "Crimson Red (#ff2020)",
                    ["silver"] = "Silver Chrome",
                    ["black"] = "Pitch Black",
                    ["custom"] = "Custom RGB",
                },
                get = function() return db.borderColor end,
                set = function(_, val)
                    db.borderColor = val
                    UpdateBorder()
                end,
            },
            borderCustomColor = {
                name = "Custom Border Color",
                desc = "Pick custom RGB color when Border Color is set to Custom RGB.",
                type = "color",
                order = 13,
                disabled = function() return db.borderColor ~= "custom" end,
                get = function()
                    return db.borderCustomR or 0, db.borderCustomG or 0.85, db.borderCustomB or 1
                end,
                set = function(_, r, g, b)
                    db.borderCustomR, db.borderCustomG, db.borderCustomB = r, g, b
                    UpdateBorder()
                end,
            },
            bagHeader = {
                name = "TimelessForever Addon Tray Integration",
                type = "header",
                order = 20,
            },
            redirectCompartmentToBag = {
                name = "Redirect Addon Compartment to Addon Tray",
                desc = "Clicking Blizzard's Addon Compartment on the minimap will automatically open the TimelessForever Addon Tray flyout.",
                type = "toggle",
                order = 21,
                get = function()
                    local bagDB = _G.TimelessForever_MinimapBagDB or _G.TimelessMinimapBagDB
                    if bagDB and bagDB.redirectCompartmentClick ~= nil then
                        return bagDB.redirectCompartmentClick
                    end
                    return db.redirectCompartmentClick ~= false
                end,
                set = function(_, val)
                    db.redirectCompartmentClick = val
                    local bagDB = _G.TimelessForever_MinimapBagDB or _G.TimelessMinimapBagDB
                    if bagDB then
                        bagDB.redirectCompartmentClick = val
                    end
                end,
            },
            openBagOptions = {
                name = "Open Addon Tray Options",
                desc = "Quick shortcut to open the full TimelessForever Addon Tray configuration panel.",
                type = "execute",
                order = 24,
                func = function()
                    if _G.TimelessForever_MinimapBag_OpenOptions then
                        _G.TimelessForever_MinimapBag_OpenOptions()
                    elseif _G.SlashCmdList["TIMELESSMINIMAPBAG"] then
                        _G.SlashCmdList["TIMELESSMINIMAPBAG"]("opt")
                    end
                end,
            },
            rescanBagButtons = {
                name = "Rescan Addon Buttons",
                desc = "Force an immediate rescan of the minimap to collect newly loaded buttons into the Addon Tray.",
                type = "execute",
                order = 25,
                func = function()
                    if _G.TimelessForever_MinimapBag_Rescan then
                        _G.TimelessForever_MinimapBag_Rescan()
                    elseif _G.SlashCmdList["TIMELESSMINIMAPBAG"] then
                        _G.SlashCmdList["TIMELESSMINIMAPBAG"]("rescan")
                    end
                end,
            },
            coordsHeader = {
                name = "Player Coordinates Engine",
                type = "header",
                order = 30,
            },
            showCoordinates = {
                name = "Show Coordinates",
                desc = "Display live player coordinates.",
                type = "toggle",
                order = 31,
                get = function() return db.showCoordinates end,
                set = function(_, val)
                    db.showCoordinates = val
                    Apply()
                end,
            },
            coordsPosition = {
                name = "Coordinates Location",
                desc = "Where coordinates are displayed.",
                type = "select",
                order = 32,
                values = {
                    ["footer"] = "In Control Bar (Bottom/Top)",
                    ["topleft"] = "Top-Left Corner",
                    ["topright"] = "Top-Right Corner",
                    ["bottomleft"] = "Bottom-Left Corner",
                    ["bottomright"] = "Bottom-Right Corner",
                },
                get = function() return db.coordsPosition end,
                set = function(_, val)
                    db.coordsPosition = val
                    Apply()
                end,
            },
            coordsFormat = {
                name = "Coordinates Format",
                desc = "Text formatting style.",
                type = "select",
                order = 33,
                values = {
                    ["plain"] = "45, 62",
                    ["parens"] = "(45, 62)",
                    ["labeled"] = "X: 45 | Y: 62",
                },
                get = function() return db.coordsFormat end,
                set = function(_, val)
                    db.coordsFormat = val
                    UpdateCoordinates()
                end,
            },
            coordsPrecision = {
                name = "Decimals / Precision",
                desc = "Choose integer coordinates or one decimal place.",
                type = "select",
                order = 34,
                values = {
                    [0] = "Integer (45, 62)",
                    [1] = "Tenths (45.3, 62.8)",
                },
                get = function() return db.coordsPrecision end,
                set = function(_, val)
                    db.coordsPrecision = val
                    UpdateCoordinates()
                end,
            },
            coordsColor = {
                name = "Coordinates Color",
                desc = "Font color of the coordinates.",
                type = "select",
                order = 35,
                values = {
                    ["cyan"] = "Timeless Cyan",
                    ["class"] = "Player Class Color",
                    ["gold"] = "Royal Gold",
                    ["white"] = "Bright White",
                    ["green"] = "Fel Green",
                },
                get = function() return db.coordsColor end,
                set = function(_, val)
                    db.coordsColor = val
                    UpdateCoordinates()
                end,
            },
            zoneHeader = {
                name = "Zone & Subzone Text",
                type = "header",
                order = 40,
            },
            showZone = {
                name = "Show Zone Text",
                desc = "Display current area / zone name.",
                type = "toggle",
                order = 41,
                get = function() return db.showZone end,
                set = function(_, val)
                    db.showZone = val
                    Apply()
                end,
            },
            zonePosition = {
                name = "Zone Text Position",
                desc = "Location of the zone text header relative to the minimap.",
                type = "select",
                order = 42,
                values = {
                    ["top"] = "Above Map (Floating)",
                    ["inside_top"] = "Inside Map (Top)",
                    ["inside_bottom"] = "Inside Map (Bottom)",
                    ["footer"] = "In Control Bar",
                },
                get = function() return db.zonePosition end,
                set = function(_, val)
                    db.zonePosition = val
                    Apply()
                end,
            },
            zoneColor = {
                name = "Zone Text Color",
                desc = "Color of the zone header.",
                type = "select",
                order = 43,
                values = {
                    ["gold"] = "Royal Gold",
                    ["class"] = "Player Class Color",
                    ["react"] = "PvP Reaction Color (Friendly/Hostile)",
                    ["white"] = "Bright White",
                    ["cyan"] = "Timeless Cyan",
                },
                get = function() return db.zoneColor end,
                set = function(_, val)
                    db.zoneColor = val
                    Apply()
                end,
            },
            zoneFontSize = {
                name = "Zone Font Size",
                desc = "Size of the zone text font.",
                type = "range",
                order = 44,
                min = 9,
                max = 18,
                step = 1,
                get = function() return db.zoneFontSize end,
                set = function(_, val)
                    db.zoneFontSize = val
                    Apply()
                end,
            },
            barHeader = {
                name = "Control Bar & Native Buttons",
                type = "header",
                order = 50,
            },
            barPosition = {
                name = "Control Bar Position",
                desc = "Place the control bar underneath or on top of the minimap.",
                type = "select",
                order = 51,
                values = {
                    ["bottom"] = "Bottom of Map",
                    ["top"] = "Top of Map",
                },
                get = function() return db.barPosition end,
                set = function(_, val)
                    db.barPosition = val
                    Apply()
                end,
            },
            barScale = {
                name = "Control Bar Scale",
                desc = "Scale factor of the icons in the control bar.",
                type = "range",
                order = 52,
                min = 0.6,
                max = 1.4,
                step = 0.05,
                isPercent = true,
                get = function() return db.barScale end,
                set = function(_, val)
                    db.barScale = val
                    Apply()
                end,
            },
            elementSpacing = {
                name = "Button Spacing / Padding",
                desc = "Horizontal spacing between buttons and text elements in the control bar (1px to 12px).",
                type = "range",
                order = 53,
                min = 1,
                max = 12,
                step = 1,
                get = function() return db.elementSpacing or 4 end,
                set = function(_, val)
                    db.elementSpacing = val
                    Apply()
                end,
            },
            coordsClockOrder = {
                name = "Clock & Coordinates Order",
                desc = "Choose which comes first in the control bar.",
                type = "select",
                order = 54,
                values = {
                    ["coords_clock"] = "Coordinates then Clock (36, 60  7:03)",
                    ["clock_coords"] = "Clock then Coordinates (7:03  36, 60)",
                },
                get = function() return db.coordsClockOrder or "coords_clock" end,
                set = function(_, val)
                    db.coordsClockOrder = val
                    Apply()
                end,
            },
            gearPosition = {
                name = "Settings Gear Position",
                desc = "Placement of the settings gear button.",
                type = "select",
                order = 55,
                values = {
                    ["row"] = "In Button Row (Centered with Icons)",
                    ["right"] = "Pinned to Bottom-Right Corner",
                    ["left"] = "Pinned to Bottom-Left Corner",
                    ["hidden"] = "Hidden",
                },
                get = function() return db.gearPosition or "row" end,
                set = function(_, val)
                    db.gearPosition = val
                    Apply()
                end,
            },
            clockColor = {
                name = "Clock Text Color",
                desc = "Color of the clock display text.",
                type = "select",
                order = 56,
                values = {
                    ["gold"] = "Royal Gold (#ffd100)",
                    ["white"] = "Bright White",
                    ["cyan"] = "Timeless Cyan",
                    ["class"] = "Player Class Color",
                },
                get = function() return db.clockColor or "gold" end,
                set = function(_, val)
                    db.clockColor = val
                    Apply()
                end,
            },
            showClock = {
                name = "Show Clock",
                type = "toggle",
                order = 57,
                get = function() return db.showClock end,
                set = function(_, val) db.showClock = val; Apply() end,
            },
            showCalendar = {
                name = "Show Calendar",
                type = "toggle",
                order = 58,
                get = function() return db.showCalendar end,
                set = function(_, val) db.showCalendar = val; Apply() end,
            },
            showTracking = {
                name = "Show Tracking Icon",
                type = "toggle",
                order = 59,
                get = function() return db.showTracking end,
                set = function(_, val) db.showTracking = val; Apply() end,
            },
            showCompartment = {
                name = "Show Addon Compartment",
                type = "toggle",
                order = 60,
                get = function() return db.showCompartment end,
                set = function(_, val) db.showCompartment = val; Apply() end,
            },
            showDifficulty = {
                name = "Show Dungeon/Raid Difficulty",
                type = "toggle",
                order = 61,
                get = function() return db.showDifficulty end,
                set = function(_, val) db.showDifficulty = val; Apply() end,
            },
            showQueue = {
                name = "Show Group Finder Queue Eye",
                type = "toggle",
                order = 62,
                get = function() return db.showQueue end,
                set = function(_, val) db.showQueue = val; Apply() end,
            },
            showGear = {
                name = "Show Settings Gear Button",
                type = "toggle",
                order = 63,
                get = function() return db.showGear end,
                set = function(_, val) db.showGear = val; Apply() end,
            },
            zoomHeader = {
                name = "Mouse Wheel Zoom & Map Behavior",
                type = "header",
                order = 65,
            },
            enableWheelZoom = {
                name = "Mouse Wheel Zoom",
                desc = "Enable scrolling mouse wheel over the minimap to zoom in / out smoothly.",
                type = "toggle",
                order = 66,
                get = function() return db.enableWheelZoom end,
                set = function(_, val) db.enableWheelZoom = val end,
            },
            zoomStep = {
                name = "Zoom Steps Per Tick",
                desc = "How many zoom levels to advance per wheel click.",
                type = "range",
                order = 67,
                min = 1,
                max = 3,
                step = 1,
                get = function() return db.zoomStep end,
                set = function(_, val) db.zoomStep = val end,
            },
            widestOnLogin = {
                name = "Widest Zoom on Login",
                desc = "Automatically zoom all the way out when logging into the game.",
                type = "toggle",
                order = 68,
                get = function() return db.widestOnLogin end,
                set = function(_, val) db.widestOnLogin = val end,
            },
            hideQuestRing = {
                name = "Hide Checkered Quest Blob Ring",
                desc = "Hide the checkered texture ring drawn while standing inside a quest objective area.",
                type = "toggle",
                order = 69,
                get = function() return db.hideQuestRing end,
                set = function(_, val) db.hideQuestRing = val; ApplyQuestRing() end,
            },
            combatHeader = {
                name = "Combat & Opacity Settings",
                type = "header",
                order = 70,
            },
            mapAlpha = {
                name = "Minimap Opacity (Normal)",
                desc = "Overall transparency of the minimap when out of combat.",
                type = "range",
                order = 71,
                min = 0.3,
                max = 1.0,
                step = 0.05,
                isPercent = true,
                get = function() return db.mapAlpha end,
                set = function(_, val) db.mapAlpha = val; Apply() end,
            },
            combatAlpha = {
                name = "Minimap Opacity (In Combat)",
                desc = "Transparency of the minimap during active combat.",
                type = "range",
                order = 72,
                min = 0.3,
                max = 1.0,
                step = 0.05,
                isPercent = true,
                get = function() return db.combatAlpha end,
                set = function(_, val) db.combatAlpha = val; Apply() end,
            },
            hideControlsInCombat = {
                name = "Hide Control Bar in Combat",
                desc = "Automatically hide the footer/header button row during combat to eliminate screen clutter.",
                type = "toggle",
                order = 73,
                get = function() return db.hideControlsInCombat end,
                set = function(_, val) db.hideControlsInCombat = val; Apply() end,
            },
        },
    }
    return options
end

OpenOptionsDialog = function()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.OpenSettings then
        suite:OpenSettings("minimap")
        return
    end
    if not AceConfig or not AceConfigDialog then return end
    AceConfig:RegisterOptionsTable("TimelessForeverMinimap", BuildOptionsTable())
    AceConfigDialog:Open("TimelessForeverMinimap")
    if AceConfigRegistry then
        pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessForeverMinimap")
    end
end

-- =========================================================================
-- Suite Hub Integration
-- =========================================================================
local function RegisterWithSuiteHub()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        local opt = BuildOptionsTable()
        pcall(function()
            suite:RegisterModuleTab("minimap", "Minimap", 5, opt.args)
        end)
    end
end

-- =========================================================================
-- Slash Command Handlers
-- =========================================================================
SLASH_TIMELESSFOREVERMINIMAP1 = "/tfmap"
SLASH_TIMELESSFOREVERMINIMAP2 = "/tfminimap"
SLASH_TIMELESSFOREVERMINIMAP3 = "/squaremap"
SLASH_TIMELESSFOREVERMINIMAP4 = "/fminimap"
SLASH_TIMELESSFOREVERMINIMAP5 = "/sfm"

local function HandleMinimapSlash(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")

    if cmd == "" or cmd == "opt" or cmd == "options" or cmd == "config" or cmd == "settings" then
        OpenOptionsDialog()
    elseif cmd == "unlock" then
        UnlockMinimap()
    elseif cmd == "lock" then
        LockMinimap()
    elseif cmd == "bag" then
        if _G.TimelessForever_MinimapBag_Toggle then
            _G.TimelessForever_MinimapBag_Toggle()
        elseif _G.SlashCmdList["TIMELESSMINIMAPBAG"] then
            _G.SlashCmdList["TIMELESSMINIMAPBAG"]("")
        end
    elseif cmd == "reset" then
        StopEditing()
        db.x = -16
        db.y = -16
        db.size = DEFAULT_SIZE
        db.shape = "square"
        db.locked = true
        if editor then editor:Hide() end
        Apply()
        if _G.Minimap then _G.Minimap:SetZoom(0) end
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Position, size, and layout reset to default.")
    elseif cmd == "max" then
        if _G.Minimap then _G.Minimap:SetZoom(0) end
    elseif cmd == "size" and tonumber(arg) then
        db.size = math.max(MINIMUM_SIZE, math.min(tonumber(arg), MaximumSize()))
        Apply()
        _G.DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "Size set to " .. db.size .. "px.")
    else
        _G.DEFAULT_CHAT_FRAME:AddMessage(BRAND_TITLE .. " Commands:")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap - Open settings panel")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap unlock - Show interactive drag & resize overlay")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap lock - Lock minimap and save layout")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap bag - Toggle Minimap Bag flyout")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap size <px> - Set minimap side length")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap max - Zoom all the way out")
        _G.DEFAULT_CHAT_FRAME:AddMessage("  /tfmap reset - Reset to default position & size")
    end
end

_G.SlashCmdList["TIMELESSFOREVERMINIMAP"] = HandleMinimapSlash

-- =========================================================================
-- Event Dispatcher
-- =========================================================================
local eventFrame = _G.CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

local questEvents = {
    PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED = true,
    QUEST_POI_UPDATE = true,
    ZONE_CHANGED = true,
    ZONE_CHANGED_NEW_AREA = true,
}
for ev in pairs(questEvents) do
    eventFrame:RegisterEvent(ev)
end

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "TimelessForever_Minimap") then
        InitDB()
    elseif event == "PLAYER_LOGIN" then
        InitDB()
        Start()

        -- Register in AceConfig (Suite Hub handles the single TimelessForever entry in ESC -> Options -> AddOns)
        if AceConfig then
            AceConfig:RegisterOptionsTable("TimelessForeverMinimap", BuildOptionsTable())
        end

        _G.C_Timer.After(0.2, function()
            RegisterWithSuiteHub()
            if bagDockBtn and bagDockBtn.RefreshBadge then
                bagDockBtn.RefreshBadge()
            end
            local shouldDock = (db.dockBagLauncher and db.showBagBtn) and true or false
            if _G.TimelessForever_MinimapBag_SetDocked then
                _G.TimelessForever_MinimapBag_SetDocked(shouldDock)
            elseif _G.TimelessForever_MinimapBagButton then
                if shouldDock then
                    _G.TimelessForever_MinimapBagButton:Hide()
                else
                    _G.TimelessForever_MinimapBagButton:Show()
                end
            end
        end)

        _G.C_Timer.After(1.0, function()
            RegisterWithSuiteHub()
            if bagDockBtn and bagDockBtn.RefreshBadge then
                bagDockBtn.RefreshBadge()
            end
            local shouldDock = (db.dockBagLauncher and db.showBagBtn) and true or false
            if _G.TimelessForever_MinimapBag_SetDocked then
                _G.TimelessForever_MinimapBag_SetDocked(shouldDock)
            elseif _G.TimelessForever_MinimapBagButton then
                if shouldDock then
                    _G.TimelessForever_MinimapBagButton:Hide()
                else
                    _G.TimelessForever_MinimapBagButton:Show()
                end
            end
        end)
    elseif event == "PLAYER_LOGOUT" then
        if holder and (dragging or resizing) then
            SavePosition()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        fighting = true
        if editor then
            StopEditing()
            editor:Hide()
            LockChanged()
        end
        if db and (db.hideControlsInCombat or db.combatAlpha ~= db.mapAlpha) then
            Apply()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        fighting = false
        Start()
        if pending then Apply() end
        ApplyCtrl()
        if db and (db.hideControlsInCombat or db.combatAlpha ~= db.mapAlpha) then
            Apply()
        end
    elseif event == "MODIFIER_STATE_CHANGED" then
        if arg1 == "LCTRL" or arg1 == "RCTRL" then
            ApplyCtrl()
        end
    elseif questEvents[event] then
        ApplyQuestRing()
    elseif event == "CVAR_UPDATE" then
        if arg1 == "rotateMinimap" then
            _G.C_Timer.After(0, Apply)
        end
    elseif event ~= "ADDON_LOADED" then
        Apply()
    end
end)


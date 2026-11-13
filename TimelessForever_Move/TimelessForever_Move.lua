-- =========================================================================
-- TimelessMove: Original Window & Frame Mover for World of Warcraft
-- =========================================================================

local addonName, addonTable = ...
local TimelessMove = CreateFrame("Frame")
local ForeverMove = TimelessMove
local ICON = "|TInterface\\Icons\\INV_Gizmo_02:16:16:0:0|t "

-- Modern API compatibility polyfill for removed FrameXML globals
if not _G.SetDesaturation then
    _G.SetDesaturation = function(texture, desaturation)
        if texture and texture.SetDesaturated then
            texture:SetDesaturated(desaturation)
        end
    end
end

-- Default Configuration
local defaultSettings = {
    enabled = true,
    savePositions = true,
    clampToScreen = true,
    scaleWithWheel = true,
    showChatFeedback = true,
    unlockWorldMap = true,
}

-- Database initialization
TimelessForever_MoveDB = TimelessForever_MoveDB or TimelessForeverMoveDB or TimelessMoveDB or ForeverMoveDB or { positions = {}, settings = {} }
TimelessForeverMoveDB = TimelessForever_MoveDB
TimelessMoveDB = TimelessForever_MoveDB
ForeverMoveDB = TimelessMoveDB

-- Frames that must never be moved like standard windows (fullscreen customizers, cinematics)
local blacklistedFrames = {
    ["BarberShopFrame"] = true,
    ["CinematicFrame"] = true,
    ["MovieFrame"] = true,
}

local function InitDB()
    TimelessMoveDB = TimelessMoveDB or {}
    TimelessMoveDB.positions = TimelessMoveDB.positions or {}
    TimelessMoveDB.settings = TimelessMoveDB.settings or {}

    for k, v in pairs(defaultSettings) do
        if TimelessMoveDB.settings[k] == nil then
            TimelessMoveDB.settings[k] = v
        end
    end

    -- Clean up any blacklisted frames from positions
    for frameName in pairs(blacklistedFrames) do
        if TimelessMoveDB.positions then TimelessMoveDB.positions[frameName] = nil end
        if TimelessForever_MoveDB and TimelessForever_MoveDB.positions then TimelessForever_MoveDB.positions[frameName] = nil end
        if TimelessForeverMoveDB and TimelessForeverMoveDB.positions then TimelessForeverMoveDB.positions[frameName] = nil end
        if ForeverMoveDB and ForeverMoveDB.positions then ForeverMoveDB.positions[frameName] = nil end
    end

end

-- Comprehensive list of UI Frames
local allKnownFrames = {
    -- Character, Skills, Talents & Spells
    "CharacterFrame",
    "PaperDollFrame",
    "ReputationFrame",
    "SkillFrame",
    "HonorFrame",
    "TokenFrame",
    "SpellBookFrame",
    "PlayerSpellsFrame",
    "TalentFrame",
    "PlayerTalentFrame",
    "ClassTalentFrame",
    "PetStableFrame",
    "DressUpFrame",
    "WardrobeFrame",
    
    -- Quests, World & Social
    "QuestLogFrame",
    "QuestLogDetailFrame",
    "QuestLogPopupDetailFrame",
    "QuestFrame",
    "GossipFrame",
    "FriendsFrame",
    "IgnoreListFrame",
    "WhoFrame",
    "ChannelFrame",
    "GuildFrame",
    "GuildControlUI",
    "CommunitiesFrame",
    "LFGParentFrame",
    "PVEFrame",
    "PVPParentFrame",
    "PVPReadyDialog",
    "WorldMapFrame",
    "FlightMapFrame",
    
    -- Vendors, Mail, Trade & Banks
    "MerchantFrame",
    "MailFrame",
    "OpenMailFrame",
    "SendMailFrame",
    "BankFrame",
    "GuildBankFrame",
    "AccountBankPanel",
    "TradeFrame",
    "LootFrame",
    "MasterLooterFrame",
    "BonusRollFrame",
    "TaxiFrame",
    "ItemTextFrame",
    "ItemSocketingFrame",
    "TabardFrame",
    "GuildRegistrarFrame",
    "PetitionFrame",
    
    -- Bags & Containers
    "ContainerFrameCombinedBags",
    "ContainerFrame1",
    "ContainerFrame2",
    "ContainerFrame3",
    "ContainerFrame4",
    "ContainerFrame5",
    "ContainerFrame6",
    "ContainerFrame7",
    "ContainerFrame8",
    "ContainerFrame9",
    "ContainerFrame10",
    "ContainerFrame11",
    "ContainerFrame12",
    "ContainerFrame13",
    
    -- System, Options & Menus
    "GameMenuFrame",
    "SettingsPanel",
    "VideoOptionsFrame",
    "AudioOptionsFrame",
    "InterfaceOptionsFrame",
    "ChatConfigFrame",
    "HelpFrame",
    "TicketStatusFrame",
    "AddonList",
    "ColorPickerFrame",
    "ReadyCheckFrame",
    "TalkingHeadFrame",
    "SubtitlesFrame",
    "StaticPopup1",
    "StaticPopup2",
    "StaticPopup3",
    "StaticPopup4",
    
    -- Blizzard Addons / On-Demand Frames
    "InspectFrame",
    "MacroFrame",
    "KeyBindingFrame",
    "AuctionFrame",
    "AuctionHouseFrame",
    "TimeManagerFrame",
    "StopwatchFrame",
    "CalendarFrame",
    "AchievementFrame",
    "CollectionsJournal",
    "EncounterJournal",
    "ArchaeologyFrame",
    "ReforgingFrame",
    "VoidStorageFrame",
    "ItemUpgradeFrame",
    "ItemInteractionFrame",
    "ProfessionsFrame",
    "ProfessionsBookFrame",
    "TradeSkillFrame",
    "CraftFrame",
    "ClassTrainerFrame",
    "PlayerChoiceFrame",
    "MajorFactionsFrame",
    "GenericTraitFrame",
    "ExpansionLandingPage",
    "WeeklyRewardsFrame",
    "ChallengesKeystoneFrame",
    "DelvesDashboardFrame",
}

-- Forward declaration for World Map functions
local IsWorldMapMaximized, SetupWorldMapMovement, ToggleWorldMapFullscreen

-- Position Persistence Helpers
local function SaveFramePosition(frame)
    if not TimelessMoveDB.settings.savePositions then return end
    if not frame or not frame.GetName then return end
    local name = frame:GetName()
    if not name or blacklistedFrames[name] then return end

    -- SPECIAL CASE: Do not overwrite windowed coordinates if WorldMapFrame is currently maximized
    if (frame == WorldMapFrame or name == "WorldMapFrame") and IsWorldMapMaximized and IsWorldMapMaximized() then
        return
    end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    if point then
        TimelessMoveDB.positions[name] = TimelessMoveDB.positions[name] or {}
        TimelessMoveDB.positions[name].point = point
        TimelessMoveDB.positions[name].relativePoint = relativePoint or point
        TimelessMoveDB.positions[name].xOfs = xOfs or 0
        TimelessMoveDB.positions[name].yOfs = yOfs or 0
        TimelessMoveDB.positions[name].scale = frame:GetScale() or 1
    end
end

local function RestoreFramePosition(frame)
    if not frame or not frame.GetName then return end
    local name = frame:GetName()
    if not name or blacklistedFrames[name] or not TimelessMoveDB or not TimelessMoveDB.positions then return end

    -- SPECIAL CASE: Do not force windowed position if WorldMapFrame is currently maximized
    if (frame == WorldMapFrame or name == "WorldMapFrame") and IsWorldMapMaximized and IsWorldMapMaximized() then
        return
    end

    local pos = TimelessMoveDB.positions[name]
    if pos then
        if pos.point then
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
        end
        if pos.scale and TimelessMoveDB.settings.scaleWithWheel then
            frame:SetScale(pos.scale)
        end
    end
end

-- =========================================================================
-- World Map Movement & Fullscreen Engine
-- =========================================================================

IsWorldMapMaximized = function()
    if not WorldMapFrame then return false end
    if WorldMapFrame.IsMaximized then
        return WorldMapFrame:IsMaximized() == true
    end
    local maxMin = WorldMapFrame.BorderFrame and WorldMapFrame.BorderFrame.MaximizeMinimizeFrame
    if maxMin and maxMin.isMaximized ~= nil then
        return maxMin.isMaximized == true
    end
    return false
end

local function UpdateWorldMapFullscreenButton(btn)
    if not btn then return end
    local isMax = IsWorldMapMaximized()
    if isMax then
        btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Down")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
        btn.tooltipText = "Restore World Map to Windowed\n(Double-click title bar also restores)"
    else
        btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Down")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
        btn.tooltipText = "Toggle World Map Fullscreen\n(Double-click title bar also maximizes)"
    end
end

ToggleWorldMapFullscreen = function()
    if not WorldMapFrame then return end

    local isMax = IsWorldMapMaximized()
    local maxMin = WorldMapFrame.BorderFrame and WorldMapFrame.BorderFrame.MaximizeMinimizeFrame

    if isMax then
        -- Restore to Windowed
        if maxMin and maxMin.MinimizeButton and maxMin.MinimizeButton:IsShown() and maxMin.MinimizeButton:IsEnabled() then
            maxMin.MinimizeButton:Click()
        elseif maxMin and maxMin.Minimize then
            maxMin:Minimize()
        elseif WorldMapFrame.SetDisplayState then
            WorldMapFrame:SetDisplayState(1)
        elseif WorldMapFrame.HandleUserActionToggleSelf then
            WorldMapFrame:HandleUserActionToggleSelf()
        end

        C_Timer.After(0.02, function()
            RestoreFramePosition(WorldMapFrame)
        end)
    else
        -- Maximize to Fullscreen
        SaveFramePosition(WorldMapFrame)

        if maxMin and maxMin.MaximizeButton and maxMin.MaximizeButton:IsShown() and maxMin.MaximizeButton:IsEnabled() then
            maxMin.MaximizeButton:Click()
        elseif maxMin and maxMin.Maximize then
            maxMin:Maximize()
        elseif WorldMapFrame.SetDisplayState then
            WorldMapFrame:SetDisplayState(2)
        elseif WorldMapFrame.HandleUserActionToggleSelf then
            WorldMapFrame:HandleUserActionToggleSelf()
        end
    end

    if WorldMapFrame._timelessFsButton then
        UpdateWorldMapFullscreenButton(WorldMapFrame._timelessFsButton)
    end
end

SetupWorldMapMovement = function()
    if not WorldMapFrame then return end
    if not (TimelessMoveDB.settings.enabled and (TimelessMoveDB.settings.unlockWorldMap ~= false)) then return end

    -- 1. Ensure UIPanelWindows["WorldMapFrame"] remains valid so Blizzard layout manager / MaximizeUIPanel does not error
    if UIPanelWindows and not UIPanelWindows["WorldMapFrame"] then
        UIPanelWindows["WorldMapFrame"] = { area = "full", pushable = 0, whileDead = 1, checkOtherPanels = 1 }
    end

    -- 2. Ensure Leatrix Maps compatibility if installed
    if _G.LeaMapsLC then
        _G.LeaMapsLC["UnlockMap"] = "On"
        _G.LeaMapsLC["EnableMovement"] = "On"
    end
    if _G.LeaMapsDB then
        _G.LeaMapsDB["UnlockMap"] = "On"
        _G.LeaMapsDB["EnableMovement"] = "On"
    end

    if WorldMapFrame._timelessMapConfigured then
        if WorldMapFrame._timelessFsButton then
            UpdateWorldMapFullscreenButton(WorldMapFrame._timelessFsButton)
        end
        return
    end

    WorldMapFrame:SetMovable(true)
    WorldMapFrame:SetClampedToScreen(TimelessMoveDB.settings.clampToScreen)
    WorldMapFrame:EnableMouse(true)
    WorldMapFrame:RegisterForDrag("LeftButton")

    local function StartMapDrag()
        if not TimelessMoveDB.settings.enabled then return end
        if IsWorldMapMaximized() then return end
        WorldMapFrame:StartMoving()
        WorldMapFrame._isMoving = true
    end

    local function StopMapDrag()
        if WorldMapFrame._isMoving then
            WorldMapFrame:StopMovingOrSizing()
            WorldMapFrame:SetUserPlaced(true)
            WorldMapFrame._isMoving = false
            SaveFramePosition(WorldMapFrame)
        end
    end

    WorldMapFrame:HookScript("OnDragStart", StartMapDrag)
    WorldMapFrame:HookScript("OnDragStop", StopMapDrag)

    -- Double-click title bar to toggle fullscreen
    local lastTitleClick = 0
    local function HandleTitleDoubleClick(button)
        if button == "LeftButton" then
            local now = GetTime()
            if (now - lastTitleClick) < 0.35 then
                ToggleWorldMapFullscreen()
                lastTitleClick = 0
            else
                lastTitleClick = now
            end
        end
    end

    local function HookMapDragTarget(target)
        if not target or target._timelessMapHooked then return end
        target:EnableMouse(true)
        target:RegisterForDrag("LeftButton")
        target:HookScript("OnDragStart", StartMapDrag)
        target:HookScript("OnDragStop", StopMapDrag)
        target:HookScript("OnMouseUp", function(_, button)
            HandleTitleDoubleClick(button)
        end)
        target._timelessMapHooked = true
    end

    if WorldMapFrame.BorderFrame then
        HookMapDragTarget(WorldMapFrame.BorderFrame.TitleContainer)
        HookMapDragTarget(WorldMapFrame.BorderFrame)
    end
    if WorldMapTitleButton then HookMapDragTarget(WorldMapTitleButton) end
    if WorldMapFrameTitle then HookMapDragTarget(WorldMapFrameTitle) end
    if _G.LeaMapsCB and _G.LeaMapsCB["MapTitleFrame"] then
        HookMapDragTarget(_G.LeaMapsCB["MapTitleFrame"])
    end

    -- Dedicated Top Drag Grip (Guarantees draggable header even with custom UI skins)
    local mapDragGrip = CreateFrame("Frame", "TimelessWorldMapTopGrip", WorldMapFrame)
    mapDragGrip:SetHeight(28)
    mapDragGrip:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 10, 0)
    mapDragGrip:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -75, 0)
    mapDragGrip:SetFrameStrata("HIGH")
    mapDragGrip:SetFrameLevel(99)
    HookMapDragTarget(mapDragGrip)

    -- Shift + LeftClick Drag anywhere on ScrollContainer (directly over the map)
    if WorldMapFrame.ScrollContainer then
        WorldMapFrame.ScrollContainer:HookScript("OnMouseDown", function(_, button)
            if button == "LeftButton" and (IsShiftKeyDown() or IsAltKeyDown()) then
                StartMapDrag()
            end
        end)
        WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", function(_, button)
            StopMapDrag()
        end)
    end

    -- Dedicated Fullscreen Toggle Button
    local fsButton = CreateFrame("Button", "TimelessWorldMapFullscreenButton", WorldMapFrame)
    fsButton:SetSize(22, 22)
    fsButton:SetFrameStrata("HIGH")
    fsButton:SetFrameLevel(100)

    local closeBtn = (WorldMapFrame.BorderFrame and WorldMapFrame.BorderFrame.CloseButton) or WorldMapFrameCloseButton
    if closeBtn then
        fsButton:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    else
        fsButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -36, -4)
    end

    fsButton:SetScript("OnClick", function()
        ToggleWorldMapFullscreen()
    end)
    fsButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText or "Toggle Fullscreen Map", 1, 1, 1)
        GameTooltip:AddLine("Double-click title bar or click here to toggle.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + Drag anywhere on map to move.", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    fsButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateWorldMapFullscreenButton(fsButton)
    WorldMapFrame._timelessFsButton = fsButton

    if WorldMapFrame.SynchronizeDisplayState then
        hooksecurefunc(WorldMapFrame, "SynchronizeDisplayState", function()
            UpdateWorldMapFullscreenButton(fsButton)
            if not IsWorldMapMaximized() then
                RestoreFramePosition(WorldMapFrame)
            end
        end)
    end
    if WorldMapFrame.OnFrameSizeChanged then
        hooksecurefunc(WorldMapFrame, "OnFrameSizeChanged", function()
            UpdateWorldMapFullscreenButton(fsButton)
        end)
    end

    WorldMapFrame:HookScript("OnShow", function(self)
        if _G.LeaMapsLC then
            _G.LeaMapsLC["UnlockMap"] = "On"
            _G.LeaMapsLC["EnableMovement"] = "On"
        end
        if _G.LeaMapsDB then
            _G.LeaMapsDB["UnlockMap"] = "On"
            _G.LeaMapsDB["EnableMovement"] = "On"
        end

        UpdateWorldMapFullscreenButton(fsButton)
        if not IsWorldMapMaximized() then
            RestoreFramePosition(self)
        end
    end)

    if WorldMapFrame:IsShown() and not IsWorldMapMaximized() then
        RestoreFramePosition(WorldMapFrame)
    end

    WorldMapFrame._timelessMapConfigured = true
end

-- Core Enablement Function
local function EnableFrameMovement(frame)
    if type(frame) == "string" then
        frame = _G[frame]
    end
    if not frame then return end

    local name = (type(frame) == "string" and frame) or (frame.GetName and frame:GetName())
    if name and blacklistedFrames[name] then
        return
    end

    if frame == WorldMapFrame or (frame.GetName and frame:GetName() == "WorldMapFrame") then
        SetupWorldMapMovement()
        return
    end

    if frame._timelessMoveEnabled then return end

    -- Make frame movable
    frame:SetMovable(true)
    frame:SetClampedToScreen(TimelessMoveDB.settings.clampToScreen)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    -- Hook Drag on the main frame
    frame:HookScript("OnDragStart", function(self)
        if TimelessMoveDB.settings.enabled and not self.isLocked and self:IsMovable() then
            self:StartMoving()
            self._isMoving = true
        end
    end)

    frame:HookScript("OnDragStop", function(self)
        if self._isMoving then
            self:StopMovingOrSizing()
            self:SetUserPlaced(true)
            self._isMoving = false
            SaveFramePosition(self)
        end
    end)

    -- Hook Mouse Wheel for Scaling (Ctrl + MouseWheel)
    frame:EnableMouseWheel(true)
    frame:HookScript("OnMouseWheel", function(self, delta)
        if TimelessMoveDB.settings.enabled and TimelessMoveDB.settings.scaleWithWheel and IsControlKeyDown() then
            local currentScale = self:GetScale() or 1
            local newScale = currentScale + (delta * 0.05)
            newScale = math.max(0.5, math.min(2.0, newScale)) -- 50% to 200%
            self:SetScale(newScale)
            SaveFramePosition(self)
        end
    end)

    -- Hook Show to restore saved position
    frame:HookScript("OnShow", function(self)
        RestoreFramePosition(self)
    end)

    -- Attach Dragging & Scaling to header and title elements
    local dragTargets = {
        frame.TitleContainer,
        frame.TitleBg,
        frame.Header,
        frame.Title,
        frame.NineSlice,
        frame.NineSlice and frame.NineSlice.TopEdge,
        frame.BorderFrame,
        frame.ArtOverlay,
        _G[frame:GetName() and (frame:GetName() .. "TitleText") or ""],
        _G[frame:GetName() and (frame:GetName() .. "Header") or ""],
        _G[frame:GetName() and (frame:GetName() .. "Title") or ""],
    }

    for _, target in ipairs(dragTargets) do
        if target and target.EnableMouse and not target._timelessMoveHooked then
            target:EnableMouse(true)
            target:RegisterForDrag("LeftButton")

            target:HookScript("OnDragStart", function()
                if TimelessMoveDB.settings.enabled and not frame.isLocked and frame:IsMovable() then
                    frame:StartMoving()
                    frame._isMoving = true
                end
            end)

            target:HookScript("OnDragStop", function()
                if frame._isMoving then
                    frame:StopMovingOrSizing()
                    frame:SetUserPlaced(true)
                    frame._isMoving = false
                    SaveFramePosition(frame)
                end
            end)

            target:EnableMouseWheel(true)
            target:HookScript("OnMouseWheel", function(_, delta)
                if TimelessMoveDB.settings.enabled and TimelessMoveDB.settings.scaleWithWheel and IsControlKeyDown() then
                    local currentScale = frame:GetScale() or 1
                    local newScale = currentScale + (delta * 0.05)
                    newScale = math.max(0.5, math.min(2.0, newScale))
                    frame:SetScale(newScale)
                    SaveFramePosition(frame)
                end
            end)

            target._timelessMoveHooked = true
        end
    end

    -- If frame is currently open, restore position immediately
    if frame:IsShown() then
        RestoreFramePosition(frame)
    end

    frame._timelessMoveEnabled = true
end

-- Scan and hook all known frames
local function ScanAndEnableFrames()
    if WorldMapFrame then
        SetupWorldMapMovement()
    end
    for _, frameName in ipairs(allKnownFrames) do
        local frame = _G[frameName]
        if frame and not frame._timelessMoveEnabled then
            EnableFrameMovement(frame)
        end
    end
end

-- Helper: Get frame currently under mouse cursor
local function GetFrameUnderMouse()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return foci and foci[1]
    elseif GetMouseFocus then
        return GetMouseFocus()
    end
end

-- Global Hooks to automatically catch panels as they open
hooksecurefunc("ShowUIPanel", function(frame)
    if frame then
        EnableFrameMovement(frame)
        RestoreFramePosition(frame)
    end
end)

if SetUIPanel then
    hooksecurefunc("SetUIPanel", function(key, frame)
        if frame then
            EnableFrameMovement(frame)
            RestoreFramePosition(frame)
        end
    end)
end

-- Helper: Toggle a setting directly via slash command
local function ToggleSetting(key, displayName)
    InitDB()
    TimelessMoveDB.settings[key] = not TimelessMoveDB.settings[key]
    local state = TimelessMoveDB.settings[key] and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
    print(ICON .. "|cff00ccff" .. displayName .. ":|r " .. state)

    if key == "clampToScreen" then
        for _, fName in ipairs(allKnownFrames) do
            local f = _G[fName]
            if f and f.SetClampedToScreen then
                f:SetClampedToScreen(TimelessMoveDB.settings[key])
            end
        end
    end
end

-- =========================================================================
-- TimelessMove Settings Window
-- =========================================================================

local unifiedPanel = CreateFrame("Frame", "TimelessSuiteSettingsPanel", UIParent, "BackdropTemplate")
unifiedPanel:SetSize(320, 430)
unifiedPanel:SetPoint("CENTER")
unifiedPanel:SetMovable(true)
unifiedPanel:EnableMouse(true)
unifiedPanel:RegisterForDrag("LeftButton")
unifiedPanel:SetScript("OnDragStart", unifiedPanel.StartMoving)
unifiedPanel:SetScript("OnDragStop", unifiedPanel.StopMovingOrSizing)
unifiedPanel:SetClampedToScreen(true)
unifiedPanel:SetFrameStrata("DIALOG")
unifiedPanel:Hide()

unifiedPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- Header Banner
local uHeader = unifiedPanel:CreateTexture(nil, "ARTWORK")
uHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
uHeader:SetSize(280, 56)
uHeader:SetPoint("TOP", unifiedPanel, "TOP", 0, 12)

local uTitle = unifiedPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
uTitle:SetPoint("TOP", uHeader, "TOP", 0, -14)
uTitle:SetText(ICON .. "|cff00ccffTimeless|r |cffffffffMove|r")

-- Close Button 'X'
local uCloseX = CreateFrame("Button", nil, unifiedPanel, "UIPanelCloseButton")
uCloseX:SetPoint("TOPRIGHT", unifiedPanel, "TOPRIGHT", -4, -4)
uCloseX:SetScript("OnClick", function() unifiedPanel:Hide() end)

-- Checkbox Factory
local function CreateUICheckbox(parent, text, tooltip, x, y, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    cb.text:SetText(text)

    cb:SetScript("OnShow", function(self)
        self:SetChecked(getFunc() == true)
    end)

    cb:SetScript("OnClick", function(self)
        setFunc(self:GetChecked())
    end)

    if tooltip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return cb
end

-- ==================== MOVE SETTINGS ====================
local moveHeader = unifiedPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
moveHeader:SetPoint("TOPLEFT", unifiedPanel, "TOPLEFT", 24, -42)
moveHeader:SetText("|TInterface\\Icons\\INV_Misc_Gear_01:14:14:0:0|t |cffffd100Window Move & Scale|r")

local moveDivider = unifiedPanel:CreateTexture(nil, "ARTWORK")
moveDivider:SetColorTexture(1, 0.82, 0, 0.35)
moveDivider:SetSize(272, 1)
moveDivider:SetPoint("TOPLEFT", moveHeader, "BOTTOMLEFT", 0, -4)

CreateUICheckbox(unifiedPanel, "Enable Window Moving", "Left-click and drag any window to move it freely.", 24, -72,
    function() return TimelessMoveDB.settings.enabled end,
    function(val) TimelessMoveDB.settings.enabled = val end
)

CreateUICheckbox(unifiedPanel, "Save Window Positions", "Remember moved window positions across reloads and game restarts.", 24, -104,
    function() return TimelessMoveDB.settings.savePositions end,
    function(val) TimelessMoveDB.settings.savePositions = val end
)

CreateUICheckbox(unifiedPanel, "Clamp Windows to Screen", "Prevent windows from being dragged off the monitor edges.", 24, -136,
    function() return TimelessMoveDB.settings.clampToScreen end,
    function(val)
        TimelessMoveDB.settings.clampToScreen = val
        for _, fName in ipairs(allKnownFrames) do
            local f = _G[fName]
            if f and f.SetClampedToScreen then f:SetClampedToScreen(val) end
        end
    end
)

CreateUICheckbox(unifiedPanel, "Ctrl + MouseWheel Scaling", "Hold Ctrl and scroll mouse wheel over any window to resize it (50% to 200%).", 24, -168,
    function() return TimelessMoveDB.settings.scaleWithWheel end,
    function(val) TimelessMoveDB.settings.scaleWithWheel = val end
)

CreateUICheckbox(unifiedPanel, "Unlock World Map (Move & Fullscreen)", "Allows moving the World Map freely, Shift-drag anywhere on the map, and adds a Fullscreen toggle button.", 24, -200,
    function() return TimelessMoveDB.settings.unlockWorldMap ~= false end,
    function(val)
        TimelessMoveDB.settings.unlockWorldMap = val
        if val then
            SetupWorldMapMovement()
        end
    end
)

local moveStatsText = unifiedPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
moveStatsText:SetPoint("TOPLEFT", unifiedPanel, "TOPLEFT", 24, -240)

local resetMoveBtn = CreateFrame("Button", nil, unifiedPanel, "UIPanelButtonTemplate")
resetMoveBtn:SetSize(272, 24)
resetMoveBtn:SetPoint("TOPLEFT", moveStatsText, "BOTTOMLEFT", 0, -8)
resetMoveBtn:SetText("Reset Window Positions")
resetMoveBtn:SetScript("OnClick", function()
    TimelessMoveDB.positions = {}
    print(ICON .. "|cff00ccff[TimelessMove]|r All window positions have been reset.")
    ReloadUI()
end)

local scanMoveBtn = CreateFrame("Button", nil, unifiedPanel, "UIPanelButtonTemplate")
scanMoveBtn:SetSize(272, 24)
scanMoveBtn:SetPoint("TOPLEFT", resetMoveBtn, "BOTTOMLEFT", 0, -8)
scanMoveBtn:SetText("Re-Scan Game Windows")
scanMoveBtn:SetScript("OnClick", function()
    ScanAndEnableFrames()
    print(ICON .. "|cff00ccff[TimelessMove]|r Re-scanned and updated all game windows.")
end)

local targetMoveBtn = CreateFrame("Button", nil, unifiedPanel, "UIPanelButtonTemplate")
targetMoveBtn:SetSize(272, 24)
targetMoveBtn:SetPoint("TOPLEFT", scanMoveBtn, "BOTTOMLEFT", 0, -8)
targetMoveBtn:SetText("Make Hovered Window Movable")
targetMoveBtn:SetScript("OnClick", function()
    if SlashCmdList["FOREVERMOVE"] or SlashCmdList["TIMELESSFOREVERMOVE"] then
        local fn = SlashCmdList["TIMELESSFOREVERMOVE"] or SlashCmdList["FOREVERMOVE"]
        fn("target")
    end
end)

-- Window OnShow update hook
unifiedPanel:HookScript("OnShow", function()
    local count = 0
    if TimelessMoveDB and TimelessMoveDB.positions then
        for _ in pairs(TimelessMoveDB.positions) do count = count + 1 end
    end
    moveStatsText:SetText("Saved Custom Positions: |cffffd100" .. count .. "|r")
end)

-- Bottom Row: Reload UI & Close
local reloadBtn = CreateFrame("Button", nil, unifiedPanel, "UIPanelButtonTemplate")
reloadBtn:SetSize(130, 26)
reloadBtn:SetPoint("BOTTOMLEFT", unifiedPanel, "BOTTOMLEFT", 24, 16)
reloadBtn:SetText("Reload UI (/rl)")
reloadBtn:SetScript("OnClick", function() ReloadUI() end)

local closeAllBtn = CreateFrame("Button", nil, unifiedPanel, "UIPanelButtonTemplate")
closeAllBtn:SetSize(100, 26)
closeAllBtn:SetPoint("BOTTOMRIGHT", unifiedPanel, "BOTTOMRIGHT", -24, 16)
closeAllBtn:SetText("Close")
closeAllBtn:SetScript("OnClick", function() unifiedPanel:Hide() end)

-- =========================================================================
-- Blizzard Options Registration (AceConfig Move Options)
-- =========================================================================

local function RegisterBlizzOptions()
    if TimelessMove._blizzRegistered then return end

    local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
    local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
    if not (AceConfig and AceConfigDialog) then return end

    local options = {
        name = "TimelessMove",
        type = "group",
        args = {
            desc = {
                name = "Universal Window Movement & Scaling Configuration\n",
                type = "description",
                order = 1,
            },
            enabled = {
                name = "Enable Window Moving",
                desc = "Left-click and drag any window to move it freely.",
                type = "toggle",
                order = 2,
                width = "full",
                get = function() return TimelessMoveDB.settings.enabled end,
                set = function(_, val) TimelessMoveDB.settings.enabled = val end,
            },
            save = {
                name = "Save Window Positions",
                desc = "Remember moved window positions across game restarts.",
                type = "toggle",
                order = 3,
                width = "full",
                get = function() return TimelessMoveDB.settings.savePositions end,
                set = function(_, val) TimelessMoveDB.settings.savePositions = val end,
            },
            clamp = {
                name = "Clamp Windows to Screen",
                desc = "Prevent windows from being dragged off monitor edges.",
                type = "toggle",
                order = 4,
                width = "full",
                get = function() return TimelessMoveDB.settings.clampToScreen end,
                set = function(_, val)
                    TimelessMoveDB.settings.clampToScreen = val
                    for _, fName in ipairs(allKnownFrames) do
                        local f = _G[fName]
                        if f and f.SetClampedToScreen then f:SetClampedToScreen(val) end
                    end
                end,
            },
            scale = {
                name = "Ctrl + MouseWheel Scaling",
                desc = "Hold Ctrl and scroll mouse wheel over any window to scale it (50% to 200%).",
                type = "toggle",
                order = 5,
                width = "full",
                get = function() return TimelessMoveDB.settings.scaleWithWheel end,
                set = function(_, val) TimelessMoveDB.settings.scaleWithWheel = val end,
            },
            worldmap = {
                name = "Unlock World Map (Move & Fullscreen)",
                desc = "Allows dragging the World Map freely, Shift-drag anywhere on the map, and adds a Fullscreen toggle button.",
                type = "toggle",
                order = 6,
                width = "full",
                get = function() return TimelessMoveDB.settings.unlockWorldMap ~= false end,
                set = function(_, val)
                    TimelessMoveDB.settings.unlockWorldMap = val
                    if val then
                        SetupWorldMapMovement()
                    end
                end,
            },
            spacer1 = {
                name = "\n",
                type = "description",
                order = 6,
            },
            stats = {
                name = function()
                    local count = 0
                    if TimelessMoveDB and TimelessMoveDB.positions then
                        for _ in pairs(TimelessMoveDB.positions) do count = count + 1 end
                    end
                    return "|cffffd100Saved Custom Window Positions:|r " .. count .. "\n"
                end,
                type = "description",
                order = 7,
            },
            resetBtn = {
                name = "Reset Window Positions",
                desc = "Clear all saved custom window positions and restore game defaults.",
                type = "execute",
                order = 8,
                func = function()
                    TimelessMoveDB.positions = {}
                    print(ICON .. "|cff00ccff[TimelessMove]|r Window positions reset.")
                    ReloadUI()
                end,
            },
            scanBtn = {
                name = "Re-Scan Game Windows",
                desc = "Re-scan all UI panels on screen and make them movable.",
                type = "execute",
                order = 9,
                func = function()
                    ScanAndEnableFrames()
                    print(ICON .. "|cff00ccff[TimelessMove]|r Re-scanned and updated all game windows.")
                end,
            },
            targetBtn = {
                name = "Make Hovered Window Movable",
                desc = "Hover mouse over any elusive frame and click to make it movable.",
                type = "execute",
                order = 10,
                func = function()
                    if SlashCmdList["TIMELESSFOREVERMOVE"] then
                        SlashCmdList["TIMELESSFOREVERMOVE"]("target")
                    end
                end,
            },
            spacer2 = {
                name = "\n",
                type = "description",
                order = 11,
            },
            reloadBtn = {
                name = "Reload UI (/rl)",
                desc = "Quick reload UI to apply visual updates immediately.",
                type = "execute",
                order = 12,
                func = function() ReloadUI() end,
            },
        },
    }

    AceConfig:RegisterOptionsTable("TimelessForever_Move", options)

    local TimelessSuite = (_G["TimelessForeverSuite"] or _G["TimelessSuite"]) or {}
    _G["TimelessForeverSuite"] = TimelessSuite
    _G["TimelessSuite"] = TimelessSuite
    if not TimelessSuite.options then
        TimelessSuite.options = { name = "TimelessForever", type = "group", childGroups = "tab", args = {} }
    end
    if not TimelessSuite.RegisterModuleTab then
        function TimelessSuite:RegisterModuleTab(id, tabName, order, tabArgs)
            self.options.args[id] = { name = tabName, type = "group", order = order, args = tabArgs }
            self:RefreshOptions()
        end
    end
    if not TimelessSuite.RefreshOptions then
        function TimelessSuite:RefreshOptions()
            local LibStub = _G.LibStub
            if not LibStub then return end
            local AceConfig = LibStub("AceConfig-3.0", true)
            local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
            if not AceConfig or not AceConfigDialog then return end
            AceConfig:RegisterOptionsTable("TimelessForever", self.options)
            AceConfig:RegisterOptionsTable("Timeless", self.options)
            if not self._blizzRegistered then
                local _, catID = AceConfigDialog:AddToBlizOptions("TimelessForever", "TimelessForever")
                self._blizzCategoryID = catID
                self._blizzRegistered = true
            end
            if AceConfigRegistry then
                pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessForever")
                pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "Timeless")
            end
        end
    end

    TimelessSuite:RegisterModuleTab("move", "Move", 1, options.args)
    TimelessMove._blizzRegistered = true
end

-- =========================================================================
-- Event Handling & Lifecycle
-- =========================================================================

TimelessMove:RegisterEvent("PLAYER_ENTERING_WORLD")
TimelessMove:RegisterEvent("ADDON_LOADED")
TimelessMove:RegisterEvent("PLAYER_LOGOUT")
TimelessMove:RegisterEvent("VARIABLES_LOADED")

TimelessMove:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName or arg1 == "TimelessMove" then
            InitDB()
        end
        ScanAndEnableFrames()
        RegisterBlizzOptions()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED" then
        InitDB()
        ScanAndEnableFrames()
        RegisterBlizzOptions()
        C_Timer.After(1, RegisterBlizzOptions)
    elseif event == "PLAYER_LOGOUT" then
        if TimelessMoveDB.settings and TimelessMoveDB.settings.savePositions then
            for _, frameName in ipairs(allKnownFrames) do
                local frame = _G[frameName]
                if frame and frame:IsShown() then
                    SaveFramePosition(frame)
                end
            end
        end
    end
end)

-- =========================================================================
-- Slash Commands
-- =========================================================================

SLASH_TIMELESSFOREVERMOVE1 = "/tfmove"
SLASH_TIMELESSFOREVERMOVE2 = "/tfm"
SLASH_TIMELESSFOREVERMOVE3 = "/timelessmove"
SLASH_TIMELESSFOREVERMOVE4 = "/tmove"
SLASH_TIMELESSFOREVERMOVE5 = "/tm"
SLASH_TIMELESSFOREVERMOVE6 = "/forevermove"
SLASH_TIMELESSFOREVERMOVE7 = "/fm"

SLASH_TIMELESSMOVE1 = "/tm"
SLASH_TIMELESSMOVE2 = "/tmove"
SLASH_TIMELESSMOVE3 = "/fm"

SlashCmdList["TIMELESSFOREVERMOVE"] = function(msg)
    local cmd = string.lower(string.trim(msg or ""))

    if cmd == "" or cmd == "config" or cmd == "settings" or cmd == "opt" or cmd == "menu" or
       cmd == "move" or cmd == "windows" then
        if unifiedPanel:IsShown() and cmd ~= "move" then
            unifiedPanel:Hide()
        else
            unifiedPanel:Show()
        end
    elseif cmd == "map" or cmd == "worldmap" then
        if WorldMapFrame then
            if WorldMapFrame:IsShown() then
                WorldMapFrame:Hide()
            else
                WorldMapFrame:Show()
            end
        end
    elseif cmd == "map fs" or cmd == "map fullscreen" or cmd == "map max" then
        if WorldMapFrame then
            if not WorldMapFrame:IsShown() then WorldMapFrame:Show() end
            ToggleWorldMapFullscreen()
        end
    elseif cmd == "map reset" then
        if TimelessMoveDB and TimelessMoveDB.positions then
            TimelessMoveDB.positions["WorldMapFrame"] = nil
        end
        if WorldMapFrame then
            WorldMapFrame:ClearAllPoints()
            WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        print(ICON .. "|cff00ccff[TimelessMove]|r World Map position reset to center.")
    elseif cmd == "save" then
        ToggleSetting("savePositions", "Position Saving")
    elseif cmd == "scale" then
        ToggleSetting("scaleWithWheel", "Ctrl+MouseWheel Scaling")
    elseif cmd == "clamp" then
        ToggleSetting("clampToScreen", "Screen Edge Clamping")
    elseif cmd == "toggle" or cmd == "enable" or cmd == "disable" then
        ToggleSetting("enabled", "TimelessMove Mover")
    elseif cmd == "barber" or cmd == "reset barber" then
        if SlashCmdList["TIMELESSBARBER"] then
            SlashCmdList["TIMELESSBARBER"]("")
        else
            print(ICON .. "|cff00ccff[TimelessMove]|r Barber controls are handled by the |cffffffffTimelessForever Barber|r addon (/barber).")
        end
    elseif cmd == "reset" then
        TimelessMoveDB.positions = {}
        print(ICON .. "|cff00ccff[TimelessMove]|r All window positions have been reset to default.")
        ReloadUI()
    elseif cmd == "scan" then
        ScanAndEnableFrames()
        print(ICON .. "|cff00ccff[TimelessMove]|r Re-scanned and enabled all current windows.")
    elseif cmd == "target" then
        local frame = GetFrameUnderMouse()
        while frame and frame:GetParent() and frame:GetParent() ~= UIParent and not frame:GetName() do
            frame = frame:GetParent()
        end
        if frame and frame ~= UIParent then
            local topFrame = frame
            while topFrame:GetParent() and topFrame:GetParent() ~= UIParent do
                topFrame = topFrame:GetParent()
            end
            EnableFrameMovement(topFrame)
            print(ICON .. "|cff00ccff[TimelessMove]|r Enabled movement for frame: |cffffd100" .. (topFrame:GetName() or "Unnamed") .. "|r")
        else
            print(ICON .. "|cffff0000[TimelessMove]|r Hover your mouse over any window and type |cffffffff/tm target|r to make it movable.")
        end
    else
        print(ICON .. "|cff00ccff[TimelessMove]|r Commands:")
        print("  |cffffffff/timeless|r or |cffffffff/tm|r - Open Move & Scale Settings")
        print("  |cffffffff/tm target|r - Make window under mouse cursor movable")
        print("  |cffffffff/rl|r - Quick reload UI")
    end
end

-- Quick Reload Command: /rl
SLASH_FOREVERMOVERELOAD1 = "/rl"
SlashCmdList["FOREVERMOVERELOAD"] = function()
    ReloadUI()
end

SlashCmdList["FOREVERMOVE"] = SlashCmdList["TIMELESSFOREVERMOVE"]
SlashCmdList["TIMELESSMOVE"] = SlashCmdList["TIMELESSFOREVERMOVE"]

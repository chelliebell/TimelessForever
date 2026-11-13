-- =========================================================================
-- TimelessForever Suite Master Addon
-- Unified Settings Hub with Dynamic Tabs for All Modules
-- =========================================================================

local addonName, TimelessForeverSuite = ...
_G["TimelessForeverSuite"] = TimelessForeverSuite or _G["TimelessForeverSuite"] or {}
TimelessForeverSuite = _G["TimelessForeverSuite"]
_G["TimelessSuite"] = TimelessForeverSuite
_G["ForeverSuite"] = TimelessForeverSuite

local ICON_TEXTURE = "Interface\\AddOns\\TimelessForever\\Icons\\gamehivehq"
local ICON = "|T" .. ICON_TEXTURE .. ":14:14:0:0|t "
local BRAND_TITLE = "|cff00ccffTimelessForever|r"

-- Initialize Options Group
TimelessForeverSuite.options = TimelessForeverSuite.options or {
    name = "TimelessForever",
    type = "group",
    childGroups = "tab",
    args = {},
}

-- Ensure SavedVariables are initialized
function TimelessForeverSuite:InitDB()
    TimelessForeverDB = TimelessForeverDB or {}
    TimelessForeverDB.minimap = TimelessForeverDB.minimap or {}
    if TimelessForeverDB.minimap.hide == nil then
        TimelessForeverDB.minimap.hide = false
    end
    if TimelessForeverDB.minimap.angle == nil then
        TimelessForeverDB.minimap.angle = 220
    end
    if TimelessForeverDB.macroIcon == nil then
        TimelessForeverDB.macroIcon = "INV_MISC_QUESTIONMARK"
    end
    if TimelessForeverDB.customMacroIcon == nil then
        TimelessForeverDB.customMacroIcon = ""
    end
    if TimelessForeverDB.macroBody == nil then
        TimelessForeverDB.macroBody = "#showtooltip\n/timelessforever"
    end
    if TimelessForeverDB.cleanStartupChat == nil then
        TimelessForeverDB.cleanStartupChat = true
    end
    if TimelessForeverDB.createStartupTab == nil then
        TimelessForeverDB.createStartupTab = true
    end
    if TimelessForeverDB.showStartupNotice == nil then
        TimelessForeverDB.showStartupNotice = false
    end
    if TimelessForeverDB.cleanStartupMode == nil then
        TimelessForeverDB.cleanStartupMode = "ALWAYS"
    end
end

-- =========================================================================
-- Clean Addon Startup Chat & "ADDON Startup" Tab Manager
-- =========================================================================
local TSC = _G["TimelessStartupClean"] or {}
_G["TimelessStartupClean"] = TSC

TSC.buffer = TSC.buffer or {}
TSC.count = TSC.count or 0
TSC.isActive = true
TSC.inChatEvent = false
TSC.targetFrame = nil
TSC.orig_print = TSC.orig_print or _G.print

local function FindAddonChatFrame()
    if TSC.targetFrame and TSC.targetFrame.AddMessage then
        return TSC.targetFrame
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local name = GetChatWindowInfo(i)
        if name then
            local l = name:lower()
            if l == "addon startup" or l == "addonstartup" or l == "addons" or l == "addon" or l == "addon log" or l == "addonlog" then
                local frame = _G["ChatFrame" .. i]
                if frame and frame.AddMessage then
                    TSC.targetFrame = frame
                    return frame
                end
            end
        end
    end
    return nil
end

local function GetOrCreateAddonStartupChatFrame()
    local existing = FindAddonChatFrame()
    if existing then return existing end

    local canCreate = true
    if TimelessForeverDB and TimelessForeverDB.createStartupTab == false then
        canCreate = false
    end
    if not canCreate then return nil end

    if FCF_OpenNewWindow then
        local frame = FCF_OpenNewWindow("ADDON Startup")
        if frame then
            if FCF_DockFrame and GENERAL_CHAT_DOCK then
                local numDocked = 1
                if FCFDock_GetChatFrames then
                    local frames = FCFDock_GetChatFrames(GENERAL_CHAT_DOCK)
                    numDocked = frames and #frames or 1
                end
                pcall(FCF_DockFrame, frame, numDocked + 1)
            end

            if ChatFrame_RemoveAllMessageGroups then
                pcall(ChatFrame_RemoveAllMessageGroups, frame)
            end
            if ChatFrame_RemoveAllChannels then
                pcall(ChatFrame_RemoveAllChannels, frame)
            end

            frame:AddMessage("|cff00ccff=== [ADDON Startup] Clean Log ===|r")
            frame:AddMessage("|cff888888All addon initialization messages and welcome banners are automatically captured here to keep your main chat clean.|r")

            TSC.targetFrame = frame
            return frame
        end
    end
    return nil
end

function TSC:Route(msg, r, g, b)
    if not msg then return end
    self.count = self.count + 1
    local frame = FindAddonChatFrame()
    if frame and frame.AddMessage then
        frame:AddMessage(msg, r or 1, g or 1, b or 1)
    else
        table.insert(self.buffer, { text = msg, r = r or 1, g = g or 1, b = b or 1 })
    end
end

local function FlushStartupBuffer()
    local frame = GetOrCreateAddonStartupChatFrame()
    if frame then
        TSC.targetFrame = frame
        if TSC.buffer and #TSC.buffer > 0 then
            for _, entry in ipairs(TSC.buffer) do
                frame:AddMessage(entry.text, entry.r, entry.g, entry.b)
            end
            TSC.buffer = {}
        end
    end
end

if ChatFrame_MessageEventHandler and not TSC.msgHandlerHooked then
    local orig_MsgHandler = ChatFrame_MessageEventHandler
    ChatFrame_MessageEventHandler = function(self, event, ...)
        if event and type(event) == "string" and event:sub(1, 9) == "CHAT_MSG_" then
            TSC.inChatEvent = true
            local ok, res = pcall(orig_MsgHandler, self, event, ...)
            TSC.inChatEvent = false
            return res
        end
        return orig_MsgHandler(self, event, ...)
    end
    TSC.msgHandlerHooked = true
end

if not TSC.printHooked then
    local orig_print = _G.print
    _G.print = function(...)
        local isCleanChat = true
        if TimelessForeverDB and TimelessForeverDB.cleanStartupChat == false then
            isCleanChat = false
        end
        local mode = (TimelessForeverDB and TimelessForeverDB.cleanStartupMode) or "ALWAYS"
        local shouldFilter = isCleanChat and (TSC.isActive or (mode == "ALWAYS"))
        if shouldFilter then
            local n = select("#", ...)
            local msg = ""
            for i = 1, n do
                local arg = select(i, ...)
                if i > 1 then msg = msg .. " " end
                msg = msg .. tostring(arg)
            end
            TSC:Route(msg, 1, 1, 1)
            return
        end
        return orig_print(...)
    end
    TSC.printHooked = true
end

local function HookChatFrameAddMessage(frame)
    if not frame or frame._tscHooked then return end
    local orig_AddMessage = frame.AddMessage
    frame.AddMessage = function(self, text, r, g, b, id, holdTime)
        local isCleanChat = true
        if TimelessForeverDB and TimelessForeverDB.cleanStartupChat == false then
            isCleanChat = false
        end
        local mode = (TimelessForeverDB and TimelessForeverDB.cleanStartupMode) or "ALWAYS"
        local shouldFilter = isCleanChat and (TSC.isActive or (mode == "ALWAYS"))
        if shouldFilter and not TSC.inChatEvent then
            local target = FindAddonChatFrame()
            if target and target == self then
                return orig_AddMessage(self, text, r, g, b, id, holdTime)
            end
            TSC:Route(text, r, g, b)
            return
        end
        return orig_AddMessage(self, text, r, g, b, id, holdTime)
    end
    frame._tscHooked = true
end

local function HookEllesmereUI()
    local EUI = _G.EllesmereUI
    if not EUI or not EUI._chatCFD then return end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local cf = _G["ChatFrame" .. i]
        if cf then
            local d = EUI._chatCFD(cf)
            if d and d.bg then
                local children = { d.bg:GetChildren() }
                for _, child in ipairs(children) do
                    if child.GetObjectType and child:GetObjectType() == "ScrollingMessageFrame" and not child._tscHooked then
                        local orig_SMF_AddMessage = child.AddMessage
                        child.AddMessage = function(self, text, r, g, b, chatTypeID, lineID, event)
                            if TSC.isActive and not TSC.inChatEvent then
                                local target = FindAddonChatFrame()
                                if target and target ~= cf then
                                    return
                                end
                            end
                            return orig_SMF_AddMessage(self, text, r, g, b, chatTypeID, lineID, event)
                        end
                        child._tscHooked = true
                    end
                end
            end
        end
    end
end

if DEFAULT_CHAT_FRAME then
    HookChatFrameAddMessage(DEFAULT_CHAT_FRAME)
end
if ChatFrame1 then
    HookChatFrameAddMessage(ChatFrame1)
end

function TimelessForeverSuite:OpenStartupTab()
    local frame = GetOrCreateAddonStartupChatFrame()
    if frame then
        if FCF_SelectDockFrame then
            FCF_SelectDockFrame(frame)
        elseif FCFDock_SelectWindow and GENERAL_CHAT_DOCK then
            FCFDock_SelectWindow(GENERAL_CHAT_DOCK, frame)
        end
    end
end

function TimelessForeverSuite:ClearStartupTab()
    local frame = FindAddonChatFrame()
    if frame and frame.Clear then
        frame:Clear()
        frame:AddMessage("|cff00ccff=== [ADDON Startup] Clean Log (Cleared) ===|r")
        local orig = TSC.orig_print or _G.print
        orig(ICON .. BRAND_TITLE .. ": [ADDON Startup] tab log cleared.")
    end
end

function TimelessForeverSuite:GetResolvedMacroIcon()
    self:InitDB()
    local icon = TimelessForeverDB.macroIcon or "INV_MISC_QUESTIONMARK"
    if icon == "CUSTOM" then
        local custom = strtrim(TimelessForeverDB.customMacroIcon or "")
        custom = custom:gsub("^Interface\\Icons\\", ""):gsub("^Interface/Icons/", "")
        if custom ~= "" then
            return custom
        end
        return "INV_MISC_QUESTIONMARK"
    end
    return icon
end

function TimelessForeverSuite:GetResolvedMacroBody()
    self:InitDB()
    local body = TimelessForeverDB.macroBody
    if not body or strtrim(body) == "" then
        body = "#showtooltip\n/timelessforever"
    end
    local icon = self:GetResolvedMacroIcon()
    -- If the user picked a specific icon (not the ? question mark) and the body only has a bare
    -- #showtooltip with slash commands (no /cast, /use, or /equip), WoW forces the ? icon unless
    -- bare #showtooltip is omitted.
    if icon ~= "INV_MISC_QUESTIONMARK" then
        local lower = body:lower()
        local hasActionItemOrSpell = lower:find("/cast") or lower:find("/use") or lower:find("/equip")
        if not hasActionItemOrSpell then
            body = body:gsub("^%s*#showtooltip%s*\r?\n", "")
        end
    end
    return body
end

-- =========================================================================
-- Module Tab Registration & Options Refresh
-- =========================================================================

function TimelessForeverSuite:RegisterModuleTab(id, tabName, order, tabArgs)
    if not self.options then
        self.options = {
            name = "TimelessForever",
            type = "group",
            childGroups = "tab",
            args = {},
        }
    end
    self.options.args[id] = {
        name = tabName,
        type = "group",
        childGroups = "tab",
        order = order,
        args = tabArgs,
    }
    self:RefreshOptions()
end

function TimelessForeverSuite:RefreshOptions()
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

function TimelessForeverSuite:OpenSettings(tabKey, subKey)
    local LibStub = _G.LibStub
    local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
    if AceConfigDialog and tabKey then
        if subKey then
            pcall(function() AceConfigDialog:SelectGroup("TimelessForever", tabKey, subKey) end)
            pcall(function() AceConfigDialog:SelectGroup("Timeless", tabKey, subKey) end)
        else
            pcall(function() AceConfigDialog:SelectGroup("TimelessForever", tabKey) end)
            pcall(function() AceConfigDialog:SelectGroup("Timeless", tabKey) end)
        end
    end
    local catID = self._blizzCategoryID or (AceConfigDialog and AceConfigDialog.BlizOptionsIDMap and (AceConfigDialog.BlizOptionsIDMap["TimelessForever"] or AceConfigDialog.BlizOptionsIDMap["Timeless"])) or "TimelessForever"
    local opened = false
    if Settings and Settings.OpenToCategory and type(catID) == "number" then
        local ok = pcall(Settings.OpenToCategory, catID)
        if ok then opened = true end
    end
    if not opened and InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, "TimelessForever")
        pcall(InterfaceOptionsFrame_OpenToCategory, "Timeless")
        opened = true
    end
    if not opened and AceConfigDialog then
        pcall(function() AceConfigDialog:Open("TimelessForever") end)
    end
end

-- =========================================================================
-- Macro Creation Engine
-- =========================================================================
local pendingMacroCreation = false

function TimelessForeverSuite:CreateMacro(forceUpdate)
    if InCombatLockdown() then
        pendingMacroCreation = true
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": |cffff3333In combat - macro creation queued for when combat ends.|r")
        return false
    end

    self:InitDB()
    local macroName = "TimelessForever"
    local macroBody = self:GetResolvedMacroBody()
    local macroIcon = self:GetResolvedMacroIcon()

    local existingIndex = nil
    if GetMacroIndexByName then
        local idx = GetMacroIndexByName(macroName)
        if idx and idx > 0 then
            existingIndex = idx
        end
    end

    local numAccountMacros, numCharMacros = GetNumMacros()
    if not existingIndex then
        for i = 1, (numAccountMacros + numCharMacros) do
            local name = GetMacroInfo(i)
            if name and string.lower(name) == string.lower(macroName) then
                existingIndex = i
                break
            end
        end
    end

    if existingIndex then
        local _, _, currentBody = GetMacroInfo(existingIndex)
        local needsUpdate = forceUpdate or (currentBody and string.find(currentBody, "/tf"))
        if needsUpdate then
            local success, err = pcall(EditMacro, existingIndex, macroName, macroIcon, macroBody)
            if success then
                DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Macro |cffffd100\"" .. macroName .. "\"|r updated!")
                return true
            else
                DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": |cffff3333Failed to update macro: " .. tostring(err) .. "|r")
                return false
            end
        else
            return true
        end
    end

    local maxAccount = MAX_ACCOUNT_MACROS or 120
    local maxChar = MAX_CHARACTER_MACROS or 18
    local perChar = false

    if numAccountMacros >= maxAccount then
        if numCharMacros < maxChar then
            perChar = true
        else
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": |cffff3333Macro slots are full! Please free up a macro slot in /macro.|r")
            return false
        end
    end

    local success, result = pcall(CreateMacro, macroName, macroIcon, macroBody, perChar)
    if success and result then
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": In-game macro |cffffd100\"" .. macroName .. "\"|r created! Type |cffffd100/macro|r to drag it onto your action bars.")
        if TimelessForeverDB then
            TimelessForeverDB.macroCreated = true
        end
        return true
    else
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": |cffff3333Failed to create macro: " .. tostring(result) .. "|r")
        return false
    end
end

-- =========================================================================
-- Minimap Button
-- =========================================================================
local minimapBtn = nil

function TimelessForeverSuite:UpdateMinimapPosition()
    if not minimapBtn then return end
    self:InitDB()
    local db = TimelessForeverDB.minimap

    if db.hide then
        minimapBtn:Hide()
        return
    else
        minimapBtn:Show()
    end

    local angle = db.angle or 220
    local rad = math.rad(angle)
    local radius = 80
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius

    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function TimelessForeverSuite:SetMinimapShown(show)
    self:InitDB()
    TimelessForeverDB.minimap.hide = not show
    self:UpdateMinimapPosition()
    DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Minimap icon " .. (show and "|cff00ff00shown|r" or "|cffff3333hidden|r") .. ". (Type |cffffd100/timelessforever minimap|r to toggle)")
end

function TimelessForeverSuite:ResetMinimapPosition()
    self:InitDB()
    TimelessForeverDB.minimap.angle = 220
    TimelessForeverDB.minimap.hide = false
    self:UpdateMinimapPosition()
    DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Minimap icon position reset.")
end

function TimelessForeverSuite:ToggleMinimap()
    self:InitDB()
    self:SetMinimapShown(TimelessForeverDB.minimap.hide)
end

local function ShowMinimapContextMenu(anchor)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchor, function(owner, rootDescription)
            rootDescription:CreateTitle("TimelessForever Suite")
            rootDescription:CreateButton("Open Settings Hub", function() TimelessForeverSuite:OpenSettings() end)
            rootDescription:CreateDivider()
            rootDescription:CreateButton("Move (Frames)", function() TimelessForeverSuite:OpenSettings("move") end)
            rootDescription:CreateButton("Heal (Frames)", function() TimelessForeverSuite:OpenSettings("heal") end)
            rootDescription:CreateButton("AI Translate", function() TimelessForeverSuite:OpenSettings("translate") end)
            rootDescription:CreateButton("Tweaks & Graphics", function() TimelessForeverSuite:OpenSettings("tweaks") end)
            rootDescription:CreateButton("Minimap Overhaul", function() TimelessForeverSuite:OpenSettings("minimap") end)
            rootDescription:CreateButton("Addon Tray", function() TimelessForeverSuite:OpenSettings("bag") end)
            rootDescription:CreateButton("Fishing", function() TimelessForeverSuite:OpenSettings("fishing") end)
            rootDescription:CreateButton("Nightlight", function() TimelessForeverSuite:OpenSettings("nightlight") end)
            rootDescription:CreateButton("Disenchant", function() TimelessForeverSuite:OpenSettings("disenchant") end)
            rootDescription:CreateButton("Button Bar", function() TimelessForeverSuite:OpenSettings("bar") end)
            rootDescription:CreateButton("Emotes (Emote Wheel)", function() TimelessForeverSuite:OpenSettings("emotes") end)
            rootDescription:CreateButton("Buffs (Buff Wheel)", function() TimelessForeverSuite:OpenSettings("buffs") end)
            rootDescription:CreateButton("Fall Saver (Auto-Glide)", function() TimelessForeverSuite:OpenSettings("fallsaver") end)
            rootDescription:CreateDivider()
            rootDescription:CreateButton("About & Updates", function() TimelessForeverSuite:OpenSettings("about") end)
            rootDescription:CreateDivider()
            rootDescription:CreateButton("Create / Update Macro", function() TimelessForeverSuite:CreateMacro(true) end)
            rootDescription:CreateButton("Reset Minimap Position", function() TimelessForeverSuite:ResetMinimapPosition() end)
            rootDescription:CreateButton("Hide Minimap Icon", function() TimelessForeverSuite:SetMinimapShown(false) end)
        end)
        return
    end

    if not TimelessForeverSuite.contextMenuFrame then
        TimelessForeverSuite.contextMenuFrame = CreateFrame("Frame", "TimelessForeverContextMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
    local menuList = {
        { text = "TimelessForever Suite", isTitle = true, notCheckable = true },
        { text = "Open Settings Hub", func = function() TimelessForeverSuite:OpenSettings() end, notCheckable = true },
        { text = "Move (Frames)", func = function() TimelessForeverSuite:OpenSettings("move") end, notCheckable = true },
        { text = "Heal (Frames)", func = function() TimelessForeverSuite:OpenSettings("heal") end, notCheckable = true },
        { text = "AI Translate", func = function() TimelessForeverSuite:OpenSettings("translate") end, notCheckable = true },
        { text = "Tweaks & Graphics", func = function() TimelessForeverSuite:OpenSettings("tweaks") end, notCheckable = true },
        { text = "Minimap Overhaul", func = function() TimelessForeverSuite:OpenSettings("minimap") end, notCheckable = true },
        { text = "Addon Tray", func = function() TimelessForeverSuite:OpenSettings("bag") end, notCheckable = true },
        { text = "Fishing", func = function() TimelessForeverSuite:OpenSettings("fishing") end, notCheckable = true },
        { text = "Nightlight", func = function() TimelessForeverSuite:OpenSettings("nightlight") end, notCheckable = true },
        { text = "Disenchant", func = function() TimelessForeverSuite:OpenSettings("disenchant") end, notCheckable = true },
        { text = "Button Bar", func = function() TimelessForeverSuite:OpenSettings("bar") end, notCheckable = true },
        { text = "Emotes (Emote Wheel)", func = function() TimelessForeverSuite:OpenSettings("emotes") end, notCheckable = true },
        { text = "Buffs (Buff Wheel)", func = function() TimelessForeverSuite:OpenSettings("buffs") end, notCheckable = true },
        { text = "Fall Saver (Auto-Glide)", func = function() TimelessForeverSuite:OpenSettings("fallsaver") end, notCheckable = true },
        { text = "About & Updates", func = function() TimelessForeverSuite:OpenSettings("about") end, notCheckable = true },
        { text = "Create / Update Macro", func = function() TimelessForeverSuite:CreateMacro(true) end, notCheckable = true },
        { text = "Reset Minimap Position", func = function() TimelessForeverSuite:ResetMinimapPosition() end, notCheckable = true },
        { text = "Hide Minimap Icon", func = function() TimelessForeverSuite:SetMinimapShown(false) end, notCheckable = true },
    }
    if EasyMenu then
        EasyMenu(menuList, TimelessForeverSuite.contextMenuFrame, "cursor", 0, 0, "MENU")
    else
        TimelessForeverSuite:OpenSettings()
    end
end

function TimelessForeverSuite:CreateMinimapButton()
    if minimapBtn then return end

    minimapBtn = CreateFrame("Button", "TimelessForeverMinimapButton", Minimap)
    minimapBtn:SetSize(32, 32)
    minimapBtn:SetFrameStrata("MEDIUM")
    minimapBtn:SetFrameLevel(8)
    minimapBtn:SetMovable(true)
    minimapBtn:EnableMouse(true)
    minimapBtn:RegisterForClicks("AnyUp")
    minimapBtn:RegisterForDrag("LeftButton")
    minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 7, -5)

    local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetTexture(ICON_TEXTURE)
    icon:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 7, -6)
    if icon.SetMask then
        pcall(function() icon:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask") end)
    end

    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)

    minimapBtn.bg = bg
    minimapBtn.icon = icon
    minimapBtn.border = border

    minimapBtn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            if not mx or not scale or scale == 0 then return end
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if angle < 0 then angle = angle + 360 end
            TimelessForeverSuite:InitDB()
            TimelessForeverDB.minimap.angle = angle
            TimelessForeverSuite:UpdateMinimapPosition()
        end)
    end)

    minimapBtn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isDragging = nil
        self:SetScript("OnUpdate", nil)
    end)

    minimapBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ShowMinimapContextMenu(self)
        else
            TimelessForeverSuite:OpenSettings()
        end
    end)

    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ICON .. BRAND_TITLE .. " Suite", 1, 1, 1)
        GameTooltip:AddLine("Unified Settings Hub by GameHiveHQ", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffLeft-Click:|r Open Settings Hub", 0.2, 1, 0.2)
        GameTooltip:AddLine("|cffffffffRight-Click:|r Quick Actions & Modules", 0.2, 1, 0.2)
        GameTooltip:AddLine("|cffffffffDrag:|r Reposition on Minimap", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    minimapBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    self.minimapBtn = minimapBtn
    _G["TimelessForeverMinimapBtn"] = minimapBtn
    _G["TimelessMinimapBtn"] = minimapBtn

    -- Register with ForeverMap Button Bag if present
    if _G["ForeverMap_RegisterMinimapButton"] and ForeverMapDB and ForeverMapDB.collectIcons then
        pcall(_G["ForeverMap_RegisterMinimapButton"], minimapBtn)
    end

    -- LibDataBroker integration if present
    local LibStub = _G.LibStub
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    if ldb and not TimelessForeverSuite.dataBrokerObject then
        TimelessForeverSuite.dataBrokerObject = ldb:NewDataObject("TimelessForever", {
            type = "launcher",
            text = "TimelessForever",
            icon = ICON_TEXTURE,
            OnClick = function(brokerFrame, button)
                if button == "RightButton" then
                    ShowMinimapContextMenu(brokerFrame)
                else
                    TimelessForeverSuite:OpenSettings()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine(ICON .. BRAND_TITLE, 1, 1, 1)
                tooltip:AddLine("Left-Click: Open Settings Hub", 1, 1, 1)
                tooltip:AddLine("Right-Click: Quick Actions & Modules", 1, 1, 1)
            end,
        })
    end

    self:UpdateMinimapPosition()
end

-- =========================================================================
-- General Options Tab
-- =========================================================================

local MACRO_ICON_OPTIONS = {
    ["INV_MISC_QUESTIONMARK"]    = "|TInterface\\Icons\\INV_Misc_QuestionMark:18:18:0:0|t  Question Mark (? / #showtooltip)",
    ["Spell_Holy_BorrowedTime"]  = "|TInterface\\Icons\\Spell_Holy_BorrowedTime:18:18:0:0|t  Timeless Hourglass (Borrowed Time)",
    ["INV_Misc_PocketWatch_01"]  = "|TInterface\\Icons\\INV_Misc_PocketWatch_01:18:18:0:0|t  Golden Pocket Watch",
    ["INV_Misc_PocketWatch_02"]  = "|TInterface\\Icons\\INV_Misc_PocketWatch_02:18:18:0:0|t  Silver Pocket Watch",
    ["INV_Misc_Gear_01"]         = "|TInterface\\Icons\\INV_Misc_Gear_01:18:18:0:0|t  Settings Gear (Cogwheel)",
    ["INV_Gizmo_02"]             = "|TInterface\\Icons\\INV_Gizmo_02:18:18:0:0|t  Engineering Gizmo",
    ["Trade_Engineering"]        = "|TInterface\\Icons\\Trade_Engineering:18:18:0:0|t  Engineering Wrench & Gear",
    ["Spell_Holy_MagicalSentry"] = "|TInterface\\Icons\\Spell_Holy_MagicalSentry:18:18:0:0|t  Arcane Intellect",
    ["Spell_Nature_StarFall"]    = "|TInterface\\Icons\\Spell_Nature_StarFall:18:18:0:0|t  Starfall Cosmic",
    ["INV_Misc_Head_Dragon_01"]  = "|TInterface\\Icons\\INV_Misc_Head_Dragon_01:18:18:0:0|t  Dragon Crest",
    ["INV_Crown_01"]             = "|TInterface\\Icons\\INV_Crown_01:18:18:0:0|t  Royal Crown",
    ["Spell_Holy_FlashHeal"]     = "|TInterface\\Icons\\Spell_Holy_FlashHeal:18:18:0:0|t  Holy Flash Heal",
    ["Trade_Fishing"]            = "|TInterface\\Icons\\Trade_Fishing:18:18:0:0|t  Fishing Hook & Bobber",
    ["Interface\\Buttons\\UI-EmptySlot"] = "|TInterface\\Buttons\\UI-EmptySlot:18:18:0:0|t  Blank (Invisible Slot - No ?)",
    ["INV_Misc_Bag_08"]          = "|TInterface\\Icons\\INV_Misc_Bag_08:18:18:0:0|t  Adventurer's Pack",
    ["INV_Misc_Rune_01"]         = "|TInterface\\Icons\\INV_Misc_Rune_01:18:18:0:0|t  Hearthstone Rune",
    ["Spell_Nature_Lightning"]   = "|TInterface\\Icons\\Spell_Nature_Lightning:18:18:0:0|t  Lightning Bolt",
    ["CUSTOM"]                   = "|TInterface\\Icons\\INV_Misc_Gear_01:18:18:0:0|t  Custom Icon Texture Name...",
}

local MACRO_PRESET_COMMANDS = {
    ["/run if IsShiftKeyDown() then SlashCmdList[\"TIMELESSFOREVER\"](\"\") else ReloadUI() end"] = "Dual Action: Click to /rl, Shift-Click to Open Settings",
    ["#showtooltip\n/timelessforever"]           = "Open Main Settings Hub (#showtooltip + /timelessforever)",
    ["/timelessforever"]                         = "Open Main Settings Hub (/timelessforever)",
    ["/timelessforever heal"]                    = "Open Heal Frame Settings (/timelessforever heal)",
    ["/timelessforever tweaks"]                  = "Open Graphics & CVars Tweaks (/timelessforever tweaks)",
    ["/timelessforever fishing"]                 = "Open Fishing Helper Settings (/timelessforever fishing)",
    ["/timelessforever minimap"]                 = "Open Minimap Settings (/timelessforever minimap)",
    ["/timelessforever bag"]                     = "Open Addon Tray Settings (/timelessforever bag)",
    ["/timelessforever move"]                    = "Open Frame Mover Settings (/timelessforever move)",
    ["/timelessforever translate"]               = "Open AI Translate Settings (/timelessforever translate)",
    ["/timelessforever nightlight"]              = "Open Nightlight Settings (/timelessforever nightlight)",
    ["/timelessforever emotes"]                  = "Open Emote Wheel Settings (/timelessforever emotes)",
    ["/timelessforever buffs"]                   = "Open Buff Wheel Settings (/timelessforever buffs)",
    ["/emotes"]                                  = "Toggle Radial Emote Wheel (/emotes)",
    ["/buffs"]                                   = "Toggle Radial Buff Wheel (/buffs)",
    ["/nightlight"]                              = "Toggle Mouse Nightlight On/Off (/nightlight)",
}

local function RegisterGeneralTab()
    local generalArgs = {
        header = {
            name = ICON .. BRAND_TITLE .. " Suite Hub",
            type = "header",
            order = 1,
        },
        desc = {
            name = "Welcome to TimelessForever by GameHiveHQ. Use the tabs above to configure installed modules, manage your in-game macro, or adjust your minimap button.\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },
        macroHeader = {
            name = "In-Game Action Bar Macro",
            type = "header",
            order = 10,
        },
        macroDesc = {
            name = "Customize the |cffffd100\"TimelessForever\"|r macro in your Macro panel (/macro). Choose an icon and edit the macro text below—changes automatically update your in-game macro.\n",
            type = "description",
            order = 11,
        },
        macroIconSelect = {
            name = "Macro Icon",
            desc = "Choose the icon for the TimelessForever macro on your action bars. Selecting a specific icon automatically disables bare #showtooltip so WoW displays your chosen icon instead of a red question mark.",
            type = "select",
            width = "double",
            order = 12,
            values = MACRO_ICON_OPTIONS,
            get = function()
                TimelessForeverSuite:InitDB()
                return TimelessForeverDB.macroIcon or "INV_MISC_QUESTIONMARK"
            end,
            set = function(_, val)
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.macroIcon = val
                TimelessForeverSuite:CreateMacro(true)
            end,
        },
        customMacroIcon = {
            name = "Custom Icon Name (if Custom selected)",
            desc = "Enter any WoW icon texture name (e.g. Spell_Holy_BorrowedTime or INV_Fishingpole_02) when 'Custom Icon Texture Name...' is selected.",
            type = "input",
            width = "normal",
            order = 13,
            get = function()
                TimelessForeverSuite:InitDB()
                return TimelessForeverDB.customMacroIcon or ""
            end,
            set = function(_, val)
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.customMacroIcon = strtrim(val or "")
                TimelessForeverDB.macroIcon = "CUSTOM"
                TimelessForeverSuite:CreateMacro(true)
            end,
        },
        macroPreset = {
            name = "Quick Command Preset",
            desc = "Quickly fill the macro text with a preset TimelessForever command.",
            type = "select",
            width = "double",
            order = 14,
            values = MACRO_PRESET_COMMANDS,
            get = function()
                TimelessForeverSuite:InitDB()
                return MACRO_PRESET_COMMANDS[TimelessForeverDB.macroBody] and TimelessForeverDB.macroBody or nil
            end,
            set = function(_, val)
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.macroBody = val
                TimelessForeverSuite:CreateMacro(true)
            end,
        },
        macroBodyInput = {
            name = "Macro Text (#showtooltip / /timelessforever)",
            desc = "Edit the exact macro commands for the TimelessForever macro.",
            type = "input",
            multiline = 4,
            width = "full",
            order = 15,
            get = function()
                TimelessForeverSuite:InitDB()
                return TimelessForeverDB.macroBody or "#showtooltip\n/timelessforever"
            end,
            set = function(_, val)
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.macroBody = val
                TimelessForeverSuite:CreateMacro(true)
            end,
        },
        createMacroBtn = {
            name = "Create / Update Macro",
            desc = "Creates or updates the TimelessForever macro in your Macro panel (/macro).",
            type = "execute",
            order = 16,
            func = function()
                TimelessForeverSuite:CreateMacro(true)
            end,
        },
        resetMacroBtn = {
            name = "Reset Macro to Default",
            desc = "Reset the macro text to #showtooltip / /timelessforever and default icon.",
            type = "execute",
            order = 17,
            func = function()
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.macroIcon = "INV_MISC_QUESTIONMARK"
                TimelessForeverDB.customMacroIcon = ""
                TimelessForeverDB.macroBody = "#showtooltip\n/timelessforever"
                TimelessForeverSuite:CreateMacro(true)
            end,
        },
        minimapHeader = {
            name = "Minimap Icon",
            type = "header",
            order = 20,
        },
        showMinimap = {
            name = "Show Minimap Button",
            desc = "Show or hide the TimelessForever icon on your minimap.",
            type = "toggle",
            order = 21,
            get = function()
                TimelessForeverSuite:InitDB()
                return not TimelessForeverDB.minimap.hide
            end,
            set = function(_, val)
                TimelessForeverSuite:SetMinimapShown(val)
            end,
        },
        resetMinimap = {
            name = "Reset Minimap Position",
            desc = "Reset the minimap button position to its default angle.",
            type = "execute",
            order = 22,
            func = function()
                TimelessForeverSuite:ResetMinimapPosition()
            end,
        },
        chatCleanerHeader = {
            name = "Addon Chat & Startup Cleanliness",
            type = "header",
            order = 25,
        },
        cleanStartupChat = {
            name = "Clean Addon Spam (Keep Main Chat Clean)",
            desc = "Silences startup splash banners and direct prints from ALL addons in your main chat window (General) and routes them into the dedicated 'ADDON Startup' chat tab.",
            type = "toggle",
            order = 26,
            get = function()
                TimelessForeverSuite:InitDB()
                return TimelessForeverDB.cleanStartupChat ~= false
            end,
            set = function(_, val)
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.cleanStartupChat = val
                TSC.isActive = val
                if val then
                    GetOrCreateAddonStartupChatFrame()
                end
            end,
        },
        createStartupTab = {
            name = "Create & Maintain 'ADDON Startup' Tab",
            desc = "Automatically creates and docks an 'ADDON Startup' chat tab next to General/Combat Log.",
            type = "toggle",
            order = 27,
            get = function()
                TimelessForeverSuite:InitDB()
                return TimelessForeverDB.createStartupTab ~= false
            end,
            set = function(_, val)
                TimelessForeverSuite:InitDB()
                TimelessForeverDB.createStartupTab = val
                if val then
                    GetOrCreateAddonStartupChatFrame()
                end
            end,
        },
        viewCleanedAddonsBtn = {
            name = "View Cleaned Addons List",
            desc = "Open the Cleaned Addons Viewer window to see all addons that were cleaned up and their messages.",
            type = "execute",
            order = 27.5,
            func = function()
                local TSC = _G["TimelessStartupClean"]
                if TSC and TSC.OpenViewer then
                    TSC:OpenViewer()
                end
            end,
        },
        openStartupTabBtn = {
            name = "Open 'ADDON Startup' Tab",
            desc = "Switch chat focus to the 'ADDON Startup' chat tab.",
            type = "execute",
            order = 28,
            func = function()
                TimelessForeverSuite:OpenStartupTab()
            end,
        },
        clearStartupTabBtn = {
            name = "Clear 'ADDON Startup' Log",
            desc = "Clears all captured messages inside the 'ADDON Startup' tab.",
            type = "execute",
            order = 29,
            func = function()
                TimelessForeverSuite:ClearStartupTab()
            end,
        },
        modulesHeader = {
            name = "Quick Module Access",
            type = "header",
            order = 30,
        },
        openMoveBtn = {
            name = "Move (Frames)",
            desc = "Configure frame mover & UI unlocker.",
            type = "execute",
            order = 31,
            func = function() TimelessForeverSuite:OpenSettings("move") end,
        },
        openHealBtn = {
            name = "Heal (Frames)",
            desc = "Configure party & raid unit frames.",
            type = "execute",
            order = 32,
            func = function() TimelessForeverSuite:OpenSettings("heal") end,
        },
        openTranslateBtn = {
            name = "AI Translate",
            desc = "Configure real-time in-game AI translator.",
            type = "execute",
            order = 33,
            func = function() TimelessForeverSuite:OpenSettings("translate") end,
        },
        openTweaksBtn = {
            name = "Tweaks & Graphics",
            desc = "Configure graphics, CVars, and performance tweaks.",
            type = "execute",
            order = 34,
            func = function() TimelessForeverSuite:OpenSettings("tweaks") end,
        },
        openMinimapBtn = {
            name = "Minimap Overhaul",
            desc = "Configure square minimap, borders, and coordinates.",
            type = "execute",
            order = 35,
            func = function() TimelessForeverSuite:OpenSettings("minimap") end,
        },
        openBagBtn = {
            name = "Addon Tray",
            desc = "Configure minimap addon button collector tray.",
            type = "execute",
            order = 36,
            func = function() TimelessForeverSuite:OpenSettings("bag") end,
        },
        openFishingBtn = {
            name = "Fishing Helper",
            desc = "Configure double-click fishing, auto-loot, and lure alerts.",
            type = "execute",
            order = 37,
            func = function() TimelessForeverSuite:OpenSettings("fishing") end,
        },
        openNightlightBtn = {
            name = "Nightlight (Mouse Light)",
            desc = "Configure the toggleable lantern & flashlight around your mouse cursor.",
            type = "execute",
            order = 38,
            func = function() TimelessForeverSuite:OpenSettings("nightlight") end,
        },
        openEmotesBtn = {
            name = "Emotes (Emote Wheel)",
            desc = "Configure the radial Emote Wheel, keybind, and Poses (Sit, Lie Down, Sleep, Dance).",
            type = "execute",
            order = 38.5,
            func = function() TimelessForeverSuite:OpenSettings("emotes") end,
        },
        openBuffsBtn = {
            name = "Buffs & Scrolls",
            desc = "Configure the radial Buff Wheel and ScrollsPicker stat scrolls tracker.",
            type = "execute",
            order = 38.6,
            func = function() TimelessForeverSuite:OpenSettings("buffs") end,
        },
        openBarBtn = {
            name = "Button Bar",
            desc = "Unified floating action bar grouping Nightlight, Disenchant, and Fishing buttons.",
            type = "execute",
            order = 38.5,
            func = function() TimelessForeverSuite:OpenSettings("bar") end,
        },
        openFallSaverBtn = {
            name = "Fall Saver (Smart Fall Detector)",
            desc = "Auto-detects your class/race fall ability (Walk on Air, Slow Fall, Levitate, Bubble, Cat Form, etc.) and triggers only when truly falling—never on a normal jump.",
            type = "execute",
            order = 38.8,
            func = function() TimelessForeverSuite:OpenSettings("fallsaver") end,
        },
        openAboutBtn = {
            name = "About & Updates",
            desc = "View suite version status, installed modules, and full update changelog.",
            type = "execute",
            order = 39,
            func = function() TimelessForeverSuite:OpenSettings("about") end,
        },
        slashHeader = {
            name = "Slash Commands Reference",
            type = "header",
            order = 40,
        },
        slashDesc = {
            name = "|cffffd100/timelessforever|r (or |cffffd100/timeless|r) - Open settings hub\n" ..
                   "|cffffd100/timelessforever macro|r - Create or update the in-game macro\n" ..
                   "|cffffd100/timelessforever icon|r - Toggle minimap icon\n" ..
                   "|cffffd100/timelessforever reset|r - Reset minimap icon position\n" ..
                   "|cffffd100/timelessforever move|r / |cffffd100heal|r / |cffffd100translate|r / |cffffd100tweaks|r / |cffffd100minimap|r / |cffffd100bag|r / |cffffd100fishing|r / |cffffd100nightlight|r / |cffffd100emotes|r / |cffffd100buffs|r / |cffffd100bar|r / |cffffd100fallsaver|r / |cffffd100about|r - Jump directly to module tab",
            type = "description",
            order = 41,
        },
    }
    TimelessForeverSuite:RegisterModuleTab("general", "General", 0, generalArgs)
end

-- =========================================================================
-- Slash Commands
-- =========================================================================

local function HandleTimelessSlash(msg)
    local cmd = string.lower(string.trim(msg or ""))
    if cmd == "move" or cmd == "windows" then
        TimelessForeverSuite:OpenSettings("move")
    elseif cmd == "heal" or cmd == "frames" then
        TimelessForeverSuite:OpenSettings("heal")
    elseif cmd == "translate" or cmd == "aitranslate" or cmd == "ai" or cmd == "trans" or cmd == "chat" then
        TimelessForeverSuite:OpenSettings("translate")
    elseif cmd == "tweaks" or cmd == "cvar" or cmd == "graphics" or cmd == "opt" then
        TimelessForeverSuite:OpenSettings("tweaks")
    elseif cmd == "combat" or cmd == "combatsettings" or cmd == "autopotion" or cmd == "windstone" then
        TimelessForeverSuite:OpenSettings("tweaks", "combatTab")
    elseif cmd == "minimap" or cmd == "map" then
        TimelessForeverSuite:OpenSettings("minimap")
    elseif cmd == "bag" or cmd == "minimapbag" or cmd == "mbag" then
        TimelessForeverSuite:OpenSettings("bag")
    elseif cmd == "fishing" or cmd == "fish" then
        TimelessForeverSuite:OpenSettings("fishing")
    elseif cmd == "nightlight" or cmd == "light" or cmd == "lantern" then
        TimelessForeverSuite:OpenSettings("nightlight")
    elseif cmd == "emotes" or cmd == "emote" or cmd == "emotewheel" or cmd == "wheel" then
        TimelessForeverSuite:OpenSettings("emotes")
    elseif cmd == "buffs" or cmd == "buff" or cmd == "buffwheel" or cmd == "bw" or cmd == "tbuffs" then
        TimelessForeverSuite:OpenSettings("buffs")
    elseif cmd == "bar" or cmd == "buttonbar" or cmd == "tfbar" or cmd == "toolbar" then
        TimelessForeverSuite:OpenSettings("bar")
    elseif cmd == "disenchant" or cmd == "de" or cmd == "tfde" then
        if _G.TimelessDisenchant and _G.TimelessDisenchant.ToggleUI then
            _G.TimelessDisenchant:ToggleUI()
        elseif SlashCmdList and SlashCmdList["TIMELESSFOREVER_DISENCHANT"] then
            SlashCmdList["TIMELESSFOREVER_DISENCHANT"]("")
        else
            TimelessForeverSuite:OpenSettings("bar")
        end
    elseif cmd == "scrolls" or cmd == "sp" or cmd == "scrollspicker" then
        if _G.ScrollsPicker and _G.ScrollsPicker.ToggleUI then
            _G.ScrollsPicker.ToggleUI()
        elseif SlashCmdList and SlashCmdList["SCROLLSPICKER"] then
            SlashCmdList["SCROLLSPICKER"]("")
        else
            TimelessForeverSuite:OpenSettings("buffs")
        end
    elseif cmd == "fall" or cmd == "fallsaver" or cmd == "glide" then
        TimelessForeverSuite:OpenSettings("fallsaver")
    elseif cmd == "about" or cmd == "changelog" or cmd == "info" or cmd == "ver" or cmd == "version" then
        TimelessForeverSuite:OpenSettings("about")
    elseif cmd == "macro" then
        TimelessForeverSuite:CreateMacro(true)
    elseif cmd == "clean" or cmd == "startupclean" or cmd == "chatclean" or cmd == "sc" or cmd == "startupclearer" then
        if TSC and TSC.OpenViewer then
            TSC:OpenViewer()
        elseif TSC and TSC.PrintCleanedList then
            TSC:PrintCleanedList()
        end
    elseif cmd == "tab" or cmd == "startuptab" then
        TimelessForeverSuite:OpenStartupTab()
    elseif cmd == "clearstartup" then
        TimelessForeverSuite:ClearStartupTab()
    elseif cmd == "icon" or cmd == "toggleicon" then
        TimelessForeverSuite:ToggleMinimap()
    elseif cmd == "reset" then
        TimelessForeverSuite:ResetMinimapPosition()
    elseif cmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. " Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever|r - Open settings hub")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever bar|r - Open Button Bar settings")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever buffs|r - Open Buffs & Scrolls settings")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever move|r - Open Frame Unlocker settings")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever macro|r - Create or update in-game macro")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever icon|r - Toggle minimap icon")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever reset|r - Reset minimap icon position")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/timelessforever move|r, |cffffd100heal|r, |cffffd100tweaks|r, |cffffd100minimap|r, |cffffd100bag|r, |cffffd100fishing|r, |cffffd100nightlight|r, |cffffd100emotes|r, |cffffd100about|r")
    else
        TimelessForeverSuite:OpenSettings()
    end
end

if not SlashCmdList["TIMELESSFOREVER"] then
    SLASH_TIMELESSFOREVER1 = "/timelessforever"
    SLASH_TIMELESSFOREVER2 = "/timeless"
    SLASH_TIMELESSFOREVER3 = "/forever"
    SlashCmdList["TIMELESSFOREVER"] = HandleTimelessSlash
    SlashCmdList["TIMELESS"] = HandleTimelessSlash
    SlashCmdList["FOREVER"] = HandleTimelessSlash
end

-- =========================================================================
-- About & Suite Status Hub
-- =========================================================================

local SUITE_MODULES = {
    -- Core & Utilities
    {
        id = "TimelessForever",
        title = "TimelessForever (Core Hub)",
        category = "Core & Utilities",
        icon = "Interface\\AddOns\\TimelessForever\\Icons\\gamehivehq",
        desc = "Central settings hub, minimap launcher button, and automatic action bar macro builder.",
        command = "/timelessforever",
        tabKey = "general",
    },
    {
        id = "TimelessForever_Bar",
        title = "Timeless Button Bar",
        category = "Core & Utilities",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        desc = "Unified floating action bar grouping Nightlight, Disenchant, and Fishing buttons.",
        command = "/tfbar",
        tabKey = "bar",
    },
    {
        id = "ScrollsPicker",
        title = "ScrollsPicker (Stat Scrolls)",
        category = "Core & Utilities",
        icon = "Interface\\Icons\\INV_Scroll_02",
        desc = "Scans bags for Classic Stat Scrolls (Agility, Strength, Stamina, Intellect, Spirit, Protection I–IV), auto-pops up when buff expires, 1-click use.",
        command = "/sp",
        tabKey = "buffs",
    },
    {
        id = "TimelessForever_Disenchant",
        title = "Disenchant (1-Click Fast DE)",
        category = "Core & Utilities",
        icon = "Interface\\Icons\\INV_Enchant_Disenchant",
        desc = "Right-click gear in bags to disenchant instantly without equipping, plus mailbox mode and auto-loot.",
        command = "/tfde",
        tabKey = "bar",
    },
    {
        id = "TimelessForever_Fishing",
        title = "Fishing Helper",
        category = "Core & Utilities",
        icon = "Interface\\Icons\\Trade_Fishing",
        desc = "1-click and double-click fishing, automatic rod detection, combat weapon restore, and click-anywhere to reel in.",
        command = "/timelessforever fishing",
        tabKey = "fishing",
    },
    -- Interface & Frame Movement
    {
        id = "TimelessForever_Move",
        title = "Move (Frame Unlocker)",
        category = "Interface & Frame Movement",
        icon = "Interface\\Icons\\INV_Gizmo_02",
        desc = "Drag, scale, and save positions of default Blizzard UI frames and MacroAssistForever with zero taint.",
        command = "/timelessmove",
        tabKey = "move",
    },
    {
        id = "TimelessForever_Minimap",
        title = "Minimap Overhaul",
        category = "Interface & Frame Movement",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        desc = "Sleek square minimap, clean custom borders, real-time player & cursor coordinates, zone header, and tray docking.",
        command = "/timelessforever minimap",
        tabKey = "minimap",
    },
    {
        id = "TimelessForever_MinimapBag",
        title = "Addon Tray (Button Collector)",
        category = "Interface & Frame Movement",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        desc = "Gathers messy minimap addon buttons into a neat pop-out tray with square and circle orbit docking.",
        command = "/timelessforever bag",
        tabKey = "bag",
    },
    {
        id = "TimelessForever_Barber",
        title = "Barber (Barber Shop Fix)",
        category = "Interface & Frame Movement",
        icon = "Interface\\Icons\\INV_Misc_Scissors_01",
        desc = "Full Barber Shop UI fix, screen auto-centering, interface scaling, and camera rotation control.",
        command = "/timelessbarber",
    },
    {
        id = "TimelessForever_Bookmarks",
        title = "Bookmarks (Map Bookmarks)",
        category = "Interface & Frame Movement",
        icon = "Interface\\Icons\\Spell_Arcane_PortalIronforge",
        desc = "Right-click anywhere on the map to place custom markers with icons, notes, waypoints, and minimap tracking.",
        command = "/tfbm",
    },
    {
        id = "TimelessForever_Heal",
        title = "Heal (Mouseover Frames)",
        category = "Interface & Frame Movement",
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        desc = "Ultra-responsive, lightweight mouseover healing unit frames for 5-man dungeons and 40-man raids.",
        command = "/timelessforever heal",
        tabKey = "heal",
    },
    -- Immersion & Atmosphere
    {
        id = "TimelessForever_nightlight",
        title = "Nightlight (Mouse Torch)",
        category = "Immersion & Atmosphere",
        icon = "Interface\\Icons\\INV_Misc_Lantern_01",
        desc = "Atmospheric lantern & torchlight around cursor with darkness cutout, smooth bloom, torch flicker, and 4 progression tiers.",
        command = "/nightlight",
        tabKey = "nightlight",
    },
    {
        id = "TimelessForever_FallSaver",
        title = "Fall Saver (Auto-Glide Engine)",
        category = "Immersion & Atmosphere",
        icon = "Interface\\Icons\\Ability_Hunter_Pet_Eagle",
        desc = "Smart fall detector distinguishing normal jumping (~0.83s) from real falls, triggering racial/class float abilities before impact.",
        command = "/timelessforever fallsaver",
        tabKey = "fallsaver",
    },
    -- Radial Wheels & Actions
    {
        id = "TimelessForever_Buffs",
        title = "Buffs (Radial Buff Wheel)",
        category = "Radial Wheels & Actions",
        icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
        desc = "Radial buff wheel auto-populating class buffs, auras, seals, weapon imbues, duration tracking, and ScrollsPicker integration.",
        command = "/timelessforever buffs",
        tabKey = "buffs",
    },
    {
        id = "TimelessForever_Emotes",
        title = "Emotes (Radial Emote Wheel)",
        category = "Radial Wheels & Actions",
        icon = "Interface\\Icons\\Spell_Shadow_Charm",
        desc = "Radial emote wheel with keybind support, body poses (Sit, Lie Down, Sleep, Stand, Kneel), greetings, dances, and Favorites slices.",
        command = "/timelessforever emotes",
        tabKey = "emotes",
    },
    -- Optimization & Performance
    {
        id = "TimelessForever_Tweaks",
        title = "Tweaks & Graphics",
        category = "Optimization & Performance",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        desc = "Graphics engine and CVars optimizer, 2.6x max camera distance, nameplate distance slider, and performance presets.",
        command = "/timelessforever tweaks",
        tabKey = "tweaks",
    },
    {
        id = "ShiftBuyMax",
        title = "ShiftBuyMax (Vendor Helper)",
        category = "Optimization & Performance",
        icon = "Interface\\Icons\\INV_Misc_Coin_02",
        desc = "Shift-click any vendor item to instantly purchase a full stack or max affordable quantity.",
        command = "/shiftbuymax",
    },
    {
        id = "!StartupClean",
        title = "!StartupClean (Chat Cleaner)",
        category = "Optimization & Performance",
        icon = "Interface\\Icons\\Spell_ChargePositive",
        desc = "Cleans noisy addon startup announcements and routes them to a dedicated 'ADDON Startup' chat tab.",
        command = "/startupclean",
    },
    {
        id = "TimelessForever_AITranslate",
        title = "AI Translate",
        category = "Optimization & Performance",
        icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
        desc = "Real-time in-game chat translation for party, raid, whisper, and world chat with learning dictionary support.",
        command = "/timelessforever translate",
    },
}

local function GetAddOnMetaHelper(name, field)
    if name == "TimelessForever_Bar" or name == "TimelessForever_FallSaver" then
        name = "TimelessForever"
    end
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local val = C_AddOns.GetAddOnMetadata(name, field)
        if val then return val end
    end
    if _G.GetAddOnMetadata then
        local val = _G.GetAddOnMetadata(name, field)
        if val then return val end
    end
    return nil
end

local function CheckAddOnLoadedHelper(name)
    if name == "TimelessForever_Bar" then
        return _G.TimelessForever_ButtonBar ~= nil
    elseif name == "TimelessForever_FallSaver" then
        return true
    end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif _G.IsAddOnLoaded then
        return _G.IsAddOnLoaded(name)
    end
    return false
end

local function GetModuleCounts()
    local active = 0
    local total = #SUITE_MODULES
    for _, mod in ipairs(SUITE_MODULES) do
        if CheckAddOnLoadedHelper(mod.id) then
            active = active + 1
        end
    end
    return active, total
end

local CATEGORY_LIST = {
    { key = "Core & Utilities", color = "00e5ff" },
    { key = "Interface & Frame Movement", color = "ffcc00" },
    { key = "Immersion & Atmosphere", color = "ffaa00" },
    { key = "Radial Wheels & Actions", color = "d980fa" },
    { key = "Optimization & Performance", color = "00ff88" },
}

local function BuildDynamicModuleStatusText()
    local lines = {}
    local activeCount, totalCount = GetModuleCounts()
    table.insert(lines, "|cff00ccffModule Directory Status:|r  |cff00ff00" .. activeCount .. " Active|r  |cff888888/|r  |cffffd100" .. totalCount .. " Total Modules Installed|r\n")

    for _, cat in ipairs(CATEGORY_LIST) do
        local catModules = {}
        for _, mod in ipairs(SUITE_MODULES) do
            if mod.category == cat.key then
                table.insert(catModules, mod)
            end
        end

        if #catModules > 0 then
            table.insert(lines, "|cff" .. cat.color .. "━━━ " .. cat.key .. " ━━━|r")
            for _, mod in ipairs(catModules) do
                local loaded = CheckAddOnLoadedHelper(mod.id)
                local ver = GetAddOnMetaHelper(mod.id, "Version") or "1.0.0"
                local statusTag = loaded and "|cff00ff00[ACTIVE]|r" or "|cff888888[NOT LOADED]|r"
                local iconStr = mod.icon and ("|T" .. mod.icon .. ":14:14:0:0|t ") or ""
                table.insert(lines, iconStr .. "|cffffd100" .. mod.title .. "|r  |cff888888v" .. ver .. "|r  " .. statusTag .. "  |cff888888(Cmd: |cffffd100" .. mod.command .. "|cff888888)|r")
                table.insert(lines, "    |cffcccccc" .. mod.desc .. "|r")
            end
            table.insert(lines, "")
        end
    end
    return table.concat(lines, "\n")
end

local CHANGELOG_TODAY = [[
|cff00e5ff⚡ Unified Timeless Button Bar (TimelessForever_Bar)|r
  • |cff00ff00[NEW]|r Created a unified, floating action bar grouping your most-used utility buttons: Nightlight, Disenchant, and Fishing into one movable bar!
  • |cff00ff00[CLEAN]|r Renamed buttons to clean, consistent labels: "Nightlight", "Disenchant", and "Fishing".
  • |cff00ff00[CUSTOM]|r Shift+Drag to move anywhere, auto-save position, toggle Horizontal / Vertical layout, and lock bar position.
  • |cff00ff00[COMMANDS]|r Type |cffffd100/tfbar|r to toggle visibility, or |cffffd100/tfbar reset|r to center. Dedicated Button Bar settings tab added.

|cff00e5ff📜 Stat Scrolls Bag Scanner (ScrollsPicker & Radial Buff Wheel)|r
  • |cff00ff00[NEW]|r Added ScrollsPicker: scans bags for all classic Stat Scrolls (Agility, Strength, Stamina, Intellect, Spirit, and Protection Ranks I–IV).
  • |cff00ff00[SMART UI]|r Live bag counts, missing rank detection, and 1-click scroll application directly from the window without searching bags.
  • |cff00ff00[AUTO-POPUP]|r Auto-detects missing or expiring scroll buffs and pops up the tracker; automatically hides once all buffs are active.
  • |cff00ff00[SUITE TAB]|r Full settings integrated directly into the TimelessForever Buffs tab with missing-rank filters and scale slider.

|cff00e5ff📦 TimelessForever_Move — MacroAssistForever Integration|r
  • |cff00ff00[NEW]|r Added full movement, scale adjustment, and position persistence for the MacroAssistForever window.
  • |cff00ff00[HEADERS]|r Dynamic title and header grab targets supporting both capitalized and lowercase titlebar elements.
  • |cff00ff00[SHORTCUTS]|r Added |cffffd100/timelessmove macro|r (toggle) and |cffffd100/timelessmove macro reset|r (center).
  • |cff00ff00[RELIABLE]|r Zero-taint event hooking for ShowMacroFrame and SlashCmdList preventing Lua startup errors.

|cff00e5ff💎 Disenchant & Nightlight Polish|r
  • |cff00ff00[DISENCHANT]|r Instant 1-click disenchanting from bags without equipping gear, auto-loot, and mailbox mode.
  • |cff00ff00[NIGHTLIGHT]|r Fixed syntax issue in trainer tier progression; seamless integration with the Unified Button Bar.
  • |cff00ff00[ABOUT TAB]|r Completely redesigned About & Updates tab into clean inline cards, categorized directory, and quick navigation.
]]

local CHANGELOG_PREVIOUS = [[
|cffffd100Version 1.3.0 (October 2026):|r
  • [NEW] TimelessForever_nightlight: Mouse cursor lantern & flashlight with darkness fog cutout, radial glow, torch flicker, and 8 color presets.
  • [NEW] In-Game About & Updates tab with real-time module status inspection.
  • [UPDATE] TimelessForever_Fishing: Added auto rod detection, auto-swap back to combat weapons, and click-anywhere reel-in.
  • [UPDATE] TimelessForever_Minimap: Refined square borders and live coordinate display.
  • [UPDATE] TimelessForever_MinimapBag: Enhanced button collector and docking shelf.
  • [UPDATE] TimelessForever_Tweaks: 2.6x max camera distance and CVar optimizations.

|cffffd100Version 1.2.0:|r
  • [NEW] TimelessForever_AITranslate: Companion dictionary learning engine protocol.
  • [UPDATE] TimelessForever_Heal: Improved debuff highlight priority and mouseover responsiveness.
  • [UPDATE] TimelessForever_Move: Enhanced frame anchoring and persistence.

|cffffd100Version 1.1.0:|r
  • [NEW] TimelessForever_MinimapBag: Addon Tray button collector.
  • [NEW] Square minimap live coordinates and zone banner.
  • [NEW] Action-bar macro builder with custom icon selection.

|cffffd100Version 1.0.0:|r
  • Initial release of TimelessForever suite: Core Hub, Move, Heal, Tweaks, and Fishing.
]]

local function RegisterAboutTab()
    local aboutArgs = {
        header = {
            name = ICON .. BRAND_TITLE .. " Suite — About & Status",
            type = "header",
            order = 1,
        },
        overviewGroup = {
            name = "Suite Overview",
            type = "group",
            inline = true,
            order = 2,
            args = {
                info = {
                    name = function()
                        local active, total = GetModuleCounts()
                        return "|cffffd100Suite Version:|r |cff00ff001.4.0|r  |cff888888(Universal Release — Retail, Classic & Forever)|r\n" ..
                               "|cffffd100Author:|r TimelessForever Dev Chelliebellie / GameHiveHQ\n" ..
                               "|cffffd100Live Status:|r |cff00ff00" .. active .. "|r of |cffffd100" .. total .. "|r modules currently active and running\n" ..
                               "|cffffd100Category:|r Quality-of-Life, Immersion, Automation & Performance\n\n" ..
                               "TimelessForever is an all-in-one modular suite delivering immersive cursor lighting, automated fishing, fast disenchanting, stat scroll tracking, frame movement, custom minimap & button tray, radial wheels, and graphics optimization.\n"
                    end,
                    type = "description",
                    order = 1,
                    fontSize = "medium",
                },
                buttonBarBtn = {
                    name = "Button Bar Settings",
                    desc = "Jump directly to the Unified Button Bar settings tab.",
                    type = "execute",
                    order = 10,
                    width = "normal",
                    func = function() TimelessForeverSuite:OpenSettings("bar") end,
                },
                buffsBtn = {
                    name = "Buffs & Scrolls",
                    desc = "Jump directly to the Buffs and ScrollsPicker settings tab.",
                    type = "execute",
                    order = 11,
                    width = "normal",
                    func = function() TimelessForeverSuite:OpenSettings("buffs") end,
                },
                moveBtn = {
                    name = "Frame Unlocker",
                    desc = "Jump directly to the Frame Unlocker (Move) settings tab.",
                    type = "execute",
                    order = 12,
                    width = "normal",
                    func = function() TimelessForeverSuite:OpenSettings("move") end,
                },
                macroBtn = {
                    name = "Create / Update Macro",
                    desc = "Create or update the /timelessforever action bar macro.",
                    type = "execute",
                    order = 13,
                    width = "normal",
                    func = function() TimelessForeverSuite:CreateMacro(true) end,
                },
                resetMinimapBtn = {
                    name = "Reset Minimap Icon",
                    desc = "Reset the TimelessForever minimap launcher icon position to default.",
                    type = "execute",
                    order = 14,
                    width = "normal",
                    func = function() TimelessForeverSuite:ResetMinimapPosition() end,
                },
                reloadBtn = {
                    name = "Reload UI",
                    desc = "Reload the World of Warcraft user interface.",
                    type = "execute",
                    order = 15,
                    width = "normal",
                    confirm = true,
                    confirmText = "Are you sure you want to reload the UI?",
                    func = function() ReloadUI() end,
                },
            },
        },
        todayGroup = {
            name = "What's New in v1.4.0 (Today's Updates)",
            type = "group",
            inline = true,
            order = 3,
            args = {
                notes = {
                    name = CHANGELOG_TODAY,
                    type = "description",
                    order = 1,
                    fontSize = "medium",
                },
            },
        },
        quickNavGroup = {
            name = "Quick Module Navigation",
            type = "group",
            inline = true,
            order = 4,
            args = {
                navDesc = {
                    name = "Click any module below to jump directly to its dedicated settings tab:\n",
                    type = "description",
                    order = 1,
                },
                btnGeneral = {
                    name = "General Hub",
                    type = "execute",
                    order = 2,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("general") end,
                },
                btnBar = {
                    name = "Button Bar",
                    type = "execute",
                    order = 3,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("bar") end,
                },
                btnMove = {
                    name = "Move",
                    type = "execute",
                    order = 4,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("move") end,
                },
                btnBuffs = {
                    name = "Buffs & Scrolls",
                    type = "execute",
                    order = 5,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("buffs") end,
                },
                btnFishing = {
                    name = "Fishing",
                    type = "execute",
                    order = 6,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("fishing") end,
                },
                btnNightlight = {
                    name = "Nightlight",
                    type = "execute",
                    order = 7,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("nightlight") end,
                },
                btnMinimap = {
                    name = "Minimap",
                    type = "execute",
                    order = 8,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("minimap") end,
                },
                btnBag = {
                    name = "Addon Tray",
                    type = "execute",
                    order = 9,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("bag") end,
                },
                btnTweaks = {
                    name = "Tweaks",
                    type = "execute",
                    order = 10,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("tweaks") end,
                },
                btnHeal = {
                    name = "Heal",
                    type = "execute",
                    order = 11,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("heal") end,
                },
                btnEmotes = {
                    name = "Emotes",
                    type = "execute",
                    order = 12,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("emotes") end,
                },
                btnFallSaver = {
                    name = "Fall Saver",
                    type = "execute",
                    order = 13,
                    width = "half",
                    func = function() TimelessForeverSuite:OpenSettings("fallsaver") end,
                },
            },
        },
        modulesGroup = {
            name = "Installed Modules Directory & Live Status",
            type = "group",
            inline = true,
            order = 5,
            args = {
                status = {
                    name = BuildDynamicModuleStatusText,
                    type = "description",
                    order = 1,
                },
            },
        },
        historyGroup = {
            name = "Version History & Archive",
            type = "group",
            inline = true,
            order = 6,
            args = {
                history = {
                    name = CHANGELOG_PREVIOUS,
                    type = "description",
                    order = 1,
                },
            },
        },
    }
    TimelessForeverSuite:RegisterModuleTab("about", "About", 100, aboutArgs)
end

-- =========================================================================
-- Smart Fall Saver & Auto-Glide Engine (All Races, Classes & Items)
-- Distinguishes normal jumping (~0.83s) from real falling!
-- =========================================================================

local FallSaver = CreateFrame("Frame", "TimelessForever_FallSaverFrame", UIParent)
TimelessForeverSuite.FallSaver = FallSaver

local FALL_DEFAULTS = {
    enabled = true,
    spacebarGlide = true,          -- Press SPACE in mid-air while falling to activate ability
    showAlertButton = true,        -- Show glowing clickable alert button on screen when falling
    showCooldownWarning = true,    -- Pop up warning button/tracker when Fall-Saving Ability is used & on cooldown
    cooldownDisplayMode = "always",-- "always" = show entire cooldown duration, "popup" = show 10s on use + when falling
    playAlertSound = true,         -- Play subtle warning sound when real falling is detected
    playCooldownSound = true,      -- Play urgent warning sound if falling while on cooldown + ready chime when off CD
    jumpThreshold = 0.95,          -- Seconds airborne after pressing Jump before counting as falling (normal jump is ~0.83s)
    ledgeThreshold = 0.35,         -- Seconds airborne when walking off a ledge without pressing Jump
    allowImmunities = true,        -- Allow emergency immunities (Divine Shield, BoP, Ice Block, LIP)
    allowItems = true,             -- Allow Parachute Cloak, Noggenfogger Elixir, LIP
    alertPos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -110 },
    cdWarnPos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -170 },
}

-- Complete database of Racial, Class, and Item Fall Abilities in WoW Forever
local FALL_ABILITIES_DB = {
    -- 1. RACIAL ABILITIES (Skyborne: Windshaper & High Order)
    {
        key = "WALK_ON_AIR",
        name = "Walk on Air",
        category = "Racial (Skyborne)",
        races = { Skyborne = true },
        spellNames = { "Walk on Air" },
        spellIDs = {},
        icon = "Interface\\Icons\\INV_Elemental_Primal_Air",
        macro = "/cast Walk on Air",
        buffName = "Walk on Air",
        defaultCD = 90,
        buffDur = 10,
        priority = 1,
        desc = "Skyborne Racial: Glide downward through the air for 10 sec while controlling direction (1.5m CD, no reagent).",
    },

    -- 2. MAGE ABILITIES
    {
        key = "SLOW_FALL",
        name = "Slow Fall",
        category = "Class (Mage)",
        classes = { MAGE = true },
        spellNames = { "Slow Fall" },
        spellIDs = { 130 },
        reagentItemID = 17056, -- Light Feather
        icon = "Interface\\Icons\\Spell_Magic_FeatherFall",
        macro = "/cast [@player] Slow Fall\n/cast Slow Fall",
        buffName = "Slow Fall",
        defaultCD = 0,
        buffDur = 30,
        priority = 2,
        desc = "Mage (Lv 12): Slows falling speed for 30 sec (uses Light Feather if required).",
    },
    {
        key = "BLINK",
        name = "Blink",
        category = "Class (Mage)",
        classes = { MAGE = true },
        spellNames = { "Blink" },
        spellIDs = { 1953 },
        icon = "Interface\\Icons\\Spell_Arcane_Blink",
        macro = "/stopcasting\n/cast Blink",
        defaultCD = 15,
        priority = 5,
        desc = "Mage (Lv 20): Teleports 20 yds forward and resets falling momentum right before landing.",
    },
    {
        key = "ICE_BLOCK",
        name = "Ice Block",
        category = "Class (Mage)",
        classes = { MAGE = true },
        spellNames = { "Ice Block" },
        spellIDs = { 11958, 45438 },
        isImmunity = true,
        icon = "Interface\\Icons\\Spell_Frost_Frost",
        macro = "/stopcasting\n/cast Ice Block",
        buffName = "Ice Block",
        defaultCD = 300,
        buffDur = 10,
        priority = 8,
        desc = "Mage (Lv 25 Frost Talent): 10 sec immunity that negates lethal fall damage.",
    },

    -- 3. PRIEST ABILITIES
    {
        key = "LEVITATE",
        name = "Levitate",
        category = "Class (Priest)",
        classes = { PRIEST = true },
        spellNames = { "Levitate" },
        spellIDs = { 1706 },
        reagentItemID = 17056, -- Light Feather
        icon = "Interface\\Icons\\Spell_Holy_LayOnHands",
        macro = "/cast [@player] Levitate\n/cast Levitate",
        buffName = "Levitate",
        defaultCD = 0,
        buffDur = 120,
        priority = 2,
        desc = "Priest (Lv 34): Floats slowly through the air for 2 min (uses Light Feather if required).",
    },
    {
        key = "PW_SHIELD",
        name = "Power Word: Shield",
        category = "Class (Priest)",
        classes = { PRIEST = true },
        spellNames = { "Power Word: Shield" },
        spellIDs = { 10901, 10900, 10899, 10898, 6066, 6065, 3747, 600, 592, 17 },
        icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",
        macro = "/cast [@player] Power Word: Shield",
        buffName = "Power Word: Shield",
        defaultCD = 4,
        buffDur = 30,
        priority = 9,
        desc = "Priest (Lv 6+): Absorbs physical fall damage on landing when Levitate is unavailable.",
    },

    -- 4. PALADIN ABILITIES
    {
        key = "BLESSING_OF_PROTECTION",
        name = "Blessing of Protection",
        category = "Class (Paladin)",
        classes = { PALADIN = true },
        spellNames = { "Blessing of Protection" },
        spellIDs = { 10278, 5599, 1022 },
        isImmunity = true,
        icon = "Interface\\Icons\\Spell_Holy_SealOfProtection",
        macro = "/cast [@player] Blessing of Protection",
        buffName = "Blessing of Protection",
        defaultCD = 300,
        buffDur = 10,
        priority = 4,
        desc = "Paladin (Lv 10+): Physical immunity for 6-10 sec — completely negates all fall damage!",
    },
    {
        key = "DIVINE_SHIELD",
        name = "Divine Shield",
        category = "Class (Paladin)",
        classes = { PALADIN = true },
        spellNames = { "Divine Shield" },
        spellIDs = { 1020, 642 },
        isImmunity = true,
        icon = "Interface\\Icons\\Spell_Holy_DivineIntervention",
        macro = "/stopcasting\n/cast Divine Shield",
        buffName = "Divine Shield",
        defaultCD = 300,
        buffDur = 12,
        priority = 6,
        desc = "Paladin (Lv 34+): Complete immunity for 10-12 sec — negates all fall damage.",
    },
    {
        key = "DIVINE_PROTECTION",
        name = "Divine Protection",
        category = "Class (Paladin)",
        classes = { PALADIN = true },
        spellNames = { "Divine Protection" },
        spellIDs = { 5573, 498 },
        isImmunity = true,
        icon = "Interface\\Icons\\Spell_Holy_Restoration",
        macro = "/stopcasting\n/cast Divine Protection",
        buffName = "Divine Protection",
        defaultCD = 300,
        buffDur = 8,
        priority = 7,
        desc = "Paladin (Lv 6+): Defensive shield / immunity fallback.",
    },

    -- 5. DRUID ABILITIES
    {
        key = "CAT_FORM",
        name = "Cat Form",
        category = "Class (Druid)",
        classes = { DRUID = true },
        spellNames = { "Cat Form" },
        spellIDs = { 768 },
        icon = "Interface\\Icons\\Ability_Druid_CatForm",
        macro = "/cast !Cat Form",
        buffName = "Cat Form",
        defaultCD = 0,
        priority = 3,
        desc = "Druid (Lv 20+): Shifts into Cat Form to reduce fall damage (especially with Lv 40 Feline Grace passive).",
    },
    {
        key = "BARKSKIN",
        name = "Barkskin",
        category = "Class (Druid)",
        classes = { DRUID = true },
        spellNames = { "Barkskin" },
        spellIDs = { 22812 },
        icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem",
        macro = "/cast Barkskin",
        buffName = "Barkskin",
        defaultCD = 60,
        buffDur = 15,
        priority = 9,
        desc = "Druid (Lv 44+): Reduces all damage taken by 20% for 15 sec.",
    },

    -- 6. WARRIOR ABILITIES
    {
        key = "CHARGE",
        name = "Charge / Intercept",
        category = "Class (Warrior)",
        classes = { WARRIOR = true },
        spellNames = { "Intercept", "Charge" },
        spellIDs = { 20617, 20616, 20252, 11578, 6178, 100 },
        requiresTarget = true,
        icon = "Interface\\Icons\\Ability_Warrior_Charge",
        macro = "/cast Charge\n/cast Intercept",
        defaultCD = 15,
        priority = 5,
        desc = "Warrior (Lv 4+): Charges an enemy target on the ground to cancel fall damage.",
    },

    -- 7. WARLOCK ABILITIES
    {
        key = "VOIDWALKER_SACRIFICE",
        name = "Sacrifice (Voidwalker)",
        category = "Class (Warlock)",
        classes = { WARLOCK = true },
        spellNames = { "Sacrifice" },
        spellIDs = { 19443, 19442, 19441, 19440, 19438, 7812 },
        isPetSpell = true,
        icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield",
        macro = "/cast Sacrifice",
        buffName = "Sacrifice",
        defaultCD = 0,
        buffDur = 30,
        priority = 6,
        desc = "Warlock (Voidwalker): Sacrifices Voidwalker for a large shield that absorbs fall damage.",
    },

    -- 8. UNIVERSAL ITEMS (All Classes & Races)
    {
        key = "PARACHUTE_CLOAK",
        name = "Parachute Cloak",
        category = "Item (Engineering Cloak)",
        isItem = true,
        equipSlot = 15,
        itemID = 10518,
        icon = "Interface\\Icons\\INV_Misc_Cape_11",
        macro = "/use 15",
        buffName = "Slow Fall",
        defaultCD = 1800,
        buffDur = 10,
        priority = 3,
        desc = "Engineering Cloak (Slot 15): Grants Slow Fall for 10 sec (30m CD).",
    },
    {
        key = "NOGGENFOGGER",
        name = "Noggenfogger Elixir",
        category = "Item (Consumable)",
        isItem = true,
        itemID = 8529,
        icon = "Interface\\Icons\\INV_Potion_83",
        macro = "/use item:8529",
        buffName = "Slow Fall",
        defaultCD = 3,
        buffDur = 120,
        priority = 7,
        desc = "Consumable: Can grant 2 min Slow Fall buff.",
    },
    {
        key = "LIP",
        name = "Limited Invulnerability Potion",
        category = "Item (Potion)",
        isItem = true,
        isImmunity = true,
        itemID = 3387,
        icon = "Interface\\Icons\\INV_Potion_62",
        macro = "/use item:3387",
        buffName = "Invulnerability",
        defaultCD = 120,
        buffDur = 6,
        priority = 8,
        desc = "Potion: Grants physical damage immunity for 6 sec — negates 100% of fall damage!",
    },
}

-- Passive Fall Reduction Reference (Rogue Safe Fall, Druid Feline Grace, Shaman Reincarnation)
local PASSIVE_FALL_ABILITIES = {
    { class = "DRUID",  name = "Feline Grace",  spellID = 20719, level = 40, desc = "Passive (Lv 40): Reduces falling damage while in Cat Form." },
    { class = "ROGUE",  name = "Safe Fall",     spellID = 1860,  level = 40, desc = "Passive (Lv 40): Reduces damage taken from falls." },
    { class = "SHAMAN", name = "Reincarnation", spellID = 20608, level = 30, desc = "Passive (Lv 30): Allows self-resurrection upon fatal fall (requires Ankh)." },
}

local ACTIVE_SAFE_BUFFS = {
    ["Walk on Air"] = true,
    ["Slow Fall"] = true,
    ["Levitate"] = true,
    ["Parachute"] = true,
    ["Divine Shield"] = true,
    ["Blessing of Protection"] = true,
    ["Divine Protection"] = true,
    ["Ice Block"] = true,
    ["Invulnerability"] = true,
}

-- WoW Forever / 12.1 Secret Value Guard:
-- Never compare, index, or do arithmetic on a value where issecretvalue(v) is true!
local isSecret = _G.issecretvalue or function() return false end
local function Unsecret(v)
    if v ~= nil and isSecret(v) then
        return nil, true
    end
    return v, false
end

-- Self-timed cast timestamps (plain Lua numbers, never secret!)
local selfCastTimestamps = {}
local lastArmedAbilityKey = nil

function FallSaver:GetDB()
    TimelessForeverSuite:InitDB()
    TimelessForeverDB.fallSaver = TimelessForeverDB.fallSaver or {}
    local db = TimelessForeverDB.fallSaver
    for k, v in pairs(FALL_DEFAULTS) do
        if db[k] == nil then
            if type(v) == "table" then
                db[k] = { point = v.point, relativePoint = v.relativePoint, x = v.x, y = v.y }
            else
                db[k] = v
            end
        end
    end
    return db
end

-- Safe Spell & Item Inspection Helpers (100% Secret-Value Proof)
local function SafeGetSpellNameAndIcon(spellIdentifier)
    if not spellIdentifier then return nil, nil, nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellIdentifier)
        if ok and info and not isSecret(info) then
            local name = Unsecret(info.name)
            local iconID = Unsecret(info.iconID)
            local spellID = Unsecret(info.spellID)
            if name then
                return name, iconID, spellID
            end
        end
    end
    if _G.GetSpellInfo then
        local ok, name, _, icon, _, _, _, spellID = pcall(_G.GetSpellInfo, spellIdentifier)
        if ok then
            name = Unsecret(name)
            icon = Unsecret(icon)
            spellID = Unsecret(spellID)
            if name then
                return name, icon, spellID
            end
        end
    end
    return nil, nil, nil
end

local function IsSpellKnownByPlayer(entry)
    -- 1. Check by Spell IDs
    if entry.spellIDs then
        for _, id in ipairs(entry.spellIDs) do
            if _G.IsPlayerSpell then
                local ok, res = pcall(_G.IsPlayerSpell, id)
                if ok and Unsecret(res) then return true, id end
            end
            if _G.IsSpellKnown then
                local ok, res = pcall(_G.IsSpellKnown, id, entry.isPetSpell or false)
                if ok and Unsecret(res) then return true, id end
            end
            if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
                local ok, inBook = pcall(C_SpellBook.IsSpellInSpellBook, id)
                if ok and Unsecret(inBook) then return true, id end
            end
        end
    end

    -- 2. Check by Spell Name in player's spellbook (works for custom Forever racials like "Walk on Air"!)
    if entry.spellNames then
        for _, sName in ipairs(entry.spellNames) do
            local name, _, resolvedID = SafeGetSpellNameAndIcon(sName)
            if name and name ~= "" then
                return true, resolvedID or sName
            end
        end
    end

    return false, nil
end

local function FormatCooldownTime(seconds)
    seconds = Unsecret(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then return "0s" end
    if seconds >= 60 then
        local m = math.floor(seconds / 60)
        local s = math.floor(seconds % 60)
        return string.format("%dm %02ds", m, s)
    elseif seconds >= 10 then
        return string.format("%ds", math.ceil(seconds))
    else
        return string.format("%.1fs", seconds)
    end
end

local function FormatShortTimer(seconds)
    seconds = Unsecret(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then return "" end
    if seconds >= 60 then
        local m = math.floor(seconds / 60)
        local s = math.floor(seconds % 60)
        return string.format("%d:%02d", m, s)
    else
        return string.format("%d", math.ceil(seconds))
    end
end

local function GetSpellCooldownRemaining(spellIdentifier, entry)
    local now = GetTime()
    if spellIdentifier then
        if C_Spell and C_Spell.GetSpellCooldown then
            local ok, info = pcall(C_Spell.GetSpellCooldown, spellIdentifier)
            if ok and info and not isSecret(info) then
                local start, sHidden = Unsecret(info.startTime)
                local dur, dHidden = Unsecret(info.duration)
                if not sHidden and not dHidden and type(start) == "number" and type(dur) == "number" then
                    if dur <= 1.5 then return 0, 0, 0 end -- Ignore GCD
                    local rem = (start + dur) - now
                    if rem > 0 then
                        if entry and entry.key then selfCastTimestamps[entry.key] = start end
                        return rem, start, dur
                    end
                    return 0, 0, 0
                end
            end
        end
        if _G.GetSpellCooldown then
            local ok, rawStart, rawDur = pcall(_G.GetSpellCooldown, spellIdentifier)
            if ok then
                local start, sHidden = Unsecret(rawStart)
                local dur, dHidden = Unsecret(rawDur)
                if not sHidden and not dHidden and type(start) == "number" and type(dur) == "number" then
                    if dur <= 1.5 then return 0, 0, 0 end
                    local rem = (start + dur) - now
                    if rem > 0 then
                        if entry and entry.key then selfCastTimestamps[entry.key] = start end
                        return rem, start, dur
                    end
                    return 0, 0, 0
                end
            end
        end
    end

    -- Fallback to self-timed cast timestamp if game returned secret values in combat!
    if entry and entry.key and entry.defaultCD and entry.defaultCD > 1.5 then
        local castAt = selfCastTimestamps[entry.key]
        if castAt then
            local rem = (castAt + entry.defaultCD) - now
            if rem > 0 then
                return rem, castAt, entry.defaultCD
            else
                selfCastTimestamps[entry.key] = nil
            end
        end
    end
    return 0, 0, 0
end

local function SafeGetItemCount(itemID)
    if not itemID then return 0 end
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID)
        count = ok and Unsecret(count) or nil
        if type(count) == "number" then return count end
    end
    if _G.GetItemCount then
        local ok, count = pcall(_G.GetItemCount, itemID)
        count = ok and Unsecret(count) or nil
        if type(count) == "number" then return count end
    end
    return 0
end

local function GetItemCooldownRemaining(itemID, entry)
    local now = GetTime()
    if itemID then
        if C_Container and C_Container.GetItemCooldown then
            local ok, rawStart, rawDur = pcall(C_Container.GetItemCooldown, itemID)
            if ok then
                local start, sHidden = Unsecret(rawStart)
                local dur, dHidden = Unsecret(rawDur)
                if not sHidden and not dHidden and type(start) == "number" and type(dur) == "number" and dur > 1.5 then
                    local rem = (start + dur) - now
                    if rem > 0 then
                        if entry and entry.key then selfCastTimestamps[entry.key] = start end
                        return rem, start, dur
                    end
                    return 0, 0, 0
                end
            end
        end
        if _G.GetItemCooldown then
            local ok, rawStart, rawDur = pcall(_G.GetItemCooldown, itemID)
            if ok then
                local start, sHidden = Unsecret(rawStart)
                local dur, dHidden = Unsecret(rawDur)
                if not sHidden and not dHidden and type(start) == "number" and type(dur) == "number" and dur > 1.5 then
                    local rem = (start + dur) - now
                    if rem > 0 then
                        if entry and entry.key then selfCastTimestamps[entry.key] = start end
                        return rem, start, dur
                    end
                    return 0, 0, 0
                end
            end
        end
    end

    if entry and entry.key and entry.defaultCD and entry.defaultCD > 1.5 then
        local castAt = selfCastTimestamps[entry.key]
        if castAt then
            local rem = (castAt + entry.defaultCD) - now
            if rem > 0 then
                return rem, castAt, entry.defaultCD
            else
                selfCastTimestamps[entry.key] = nil
            end
        end
    end
    return 0, 0, 0
end

local function PlayerHasActiveSafeBuff()
    local now = GetTime()
    for i = 1, 40 do
        local name, expTime
        local brokeLoop = false
        if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
            local ok, data = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
            if not ok or not data then
                brokeLoop = true
            elseif not isSecret(data) then
                name = Unsecret(data.name)
                expTime = Unsecret(data.expirationTime)
            end
        elseif _G.UnitBuff then
            local ok, bName, v2, v3, v4, v5, v6, v7 = pcall(_G.UnitBuff, "player", i)
            if not ok or bName == nil then
                brokeLoop = true
            else
                name = Unsecret(bName)
                local u6 = Unsecret(v6)
                local u7 = Unsecret(v7)
                if type(u6) == "number" and u6 > now then
                    expTime = u6
                elseif type(u7) == "number" and u7 > now then
                    expTime = u7
                end
            end
        else
            brokeLoop = true
        end
        if brokeLoop then break end
        if type(name) == "string" and ACTIVE_SAFE_BUFFS[name] then
            local rem = (type(expTime) == "number" and expTime > now) and (expTime - now) or nil
            return true, name, rem
        end
    end

    -- Fallback to self-timed buff duration if UnitBuff returned secret values in combat!
    for _, entry in ipairs(FALL_ABILITIES_DB) do
        if entry.buffDur and entry.buffDur > 0 and selfCastTimestamps[entry.key] then
            local rem = (selfCastTimestamps[entry.key] + entry.buffDur) - now
            if rem > 0 then
                return true, entry.buffName or entry.name, rem
            end
        end
    end

    return false, nil, nil
end

local function PlayerHasBuffNamed(targetName)
    if not targetName then return false end
    for i = 1, 40 do
        local name
        local brokeLoop = false
        if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
            local ok, data = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
            if not ok or not data then
                brokeLoop = true
            elseif not isSecret(data) then
                name = Unsecret(data.name)
            end
        elseif _G.UnitBuff then
            local ok, bName = pcall(_G.UnitBuff, "player", i)
            if not ok or bName == nil then
                brokeLoop = true
            else
                name = Unsecret(bName)
            end
        else
            brokeLoop = true
        end
        if brokeLoop then break end
        if type(name) == "string" and name == targetName then return true end
    end
    return false
end

-- Detect the best available Fall Ability for the current player right now
function FallSaver:DetectBestFallAbility(ignoreCooldown)
    local db = self:GetDB()
    local _, playerClass = UnitClass("player")
    local raceName, raceFile = UnitRace("player")
    playerClass = Unsecret(playerClass)
    raceName = Unsecret(raceName)
    raceFile = Unsecret(raceFile)
    local isSkyborne = (type(raceFile) == "string" and string.find(string.lower(raceFile), "skyborne"))
        or (type(raceName) == "string" and string.find(string.lower(raceName), "skyborne"))

    local bestReady = nil
    local bestOnCooldown = nil
    local allDetected = {}

    for _, entry in ipairs(FALL_ABILITIES_DB) do
        local matchesClassOrRace = false
        if entry.races then
            if entry.races.Skyborne and isSkyborne then
                matchesClassOrRace = true
            elseif raceFile and entry.races[raceFile] then
                matchesClassOrRace = true
            end
        elseif entry.classes then
            if playerClass and entry.classes[playerClass] then
                matchesClassOrRace = true
            end
        elseif entry.isItem then
            if db.allowItems ~= false then
                matchesClassOrRace = true
            end
        end

        if entry.isImmunity and db.allowImmunities == false then
            matchesClassOrRace = false
        end

        if matchesClassOrRace then
            if entry.isItem then
                local hasItem = false
                if entry.equipSlot then
                    local equippedID = Unsecret(GetInventoryItemID("player", entry.equipSlot))
                    if equippedID and equippedID == entry.itemID then
                        hasItem = true
                    end
                elseif entry.itemID then
                    if SafeGetItemCount(entry.itemID) > 0 then
                        hasItem = true
                    end
                end

                if hasItem then
                    local cdRem, cdStart, cdDur = GetItemCooldownRemaining(entry.itemID, entry)
                    local itemRecord = {
                        entry = entry,
                        name = entry.name,
                        icon = entry.icon,
                        macro = entry.macro,
                        cdRemaining = cdRem,
                        cdStart = cdStart,
                        cdDuration = cdDur,
                        ready = (cdRem <= 0),
                    }
                    table.insert(allDetected, itemRecord)
                    if itemRecord.ready and not bestReady then
                        bestReady = itemRecord
                    elseif itemRecord.cdRemaining > 0 and not bestOnCooldown then
                        bestOnCooldown = itemRecord
                    end
                end
            else
                local known, resolvedIdentifier = IsSpellKnownByPlayer(entry)
                if known then
                    local hasReagent = true
                    if entry.reagentItemID then
                        local count = SafeGetItemCount(entry.reagentItemID)
                        if count <= 0 then
                            if _G.IsUsableSpell then
                                local ok, usable = pcall(_G.IsUsableSpell, entry.name)
                                if not (ok and Unsecret(usable)) then
                                    hasReagent = false
                                end
                            else
                                hasReagent = false
                            end
                        end
                    end

                    -- Skip Cat Form if already in Cat Form
                    local alreadyInForm = false
                    if entry.key == "CAT_FORM" and PlayerHasBuffNamed("Cat Form") then
                        alreadyInForm = true
                    end

                    local cdRem, cdStart, cdDur = GetSpellCooldownRemaining(resolvedIdentifier or entry.name, entry)
                    local _, dynamicIcon = SafeGetSpellNameAndIcon(resolvedIdentifier or entry.name)
                    local spellRecord = {
                        entry = entry,
                        name = entry.name,
                        icon = dynamicIcon or entry.icon,
                        macro = entry.macro,
                        cdRemaining = cdRem,
                        cdStart = cdStart,
                        cdDuration = cdDur,
                        hasReagent = hasReagent,
                        alreadyInForm = alreadyInForm,
                        ready = (cdRem <= 0) and hasReagent and not alreadyInForm,
                    }
                    table.insert(allDetected, spellRecord)
                    if spellRecord.ready and not bestReady then
                        bestReady = spellRecord
                    elseif spellRecord.cdRemaining > 0 and not bestOnCooldown and hasReagent then
                        bestOnCooldown = spellRecord
                    end
                end
            end
        end
    end

    if ignoreCooldown then
        return bestReady or bestOnCooldown, allDetected, bestOnCooldown
    end
    return bestReady, allDetected, bestOnCooldown
end

-- =========================================================================
-- Secure Button, Spacebar Mid-Air Override & On-Screen Fall Alert UI
-- =========================================================================

local fallSecureBtn = CreateFrame("Button", "TF_FallSaveButton", UIParent, "SecureActionButtonTemplate")
fallSecureBtn:RegisterForClicks("AnyDown")
fallSecureBtn:SetAttribute("type", nil)

local alertBtn = CreateFrame("Button", "TimelessForever_FallAlertButton", UIParent, "SecureActionButtonTemplate,BackdropTemplate")
alertBtn:SetSize(236, 52)
alertBtn:SetPoint("CENTER", UIParent, "CENTER", 0, -110)
alertBtn:SetFrameStrata("HIGH")
alertBtn:SetClampedToScreen(true)
alertBtn:SetMovable(true)
alertBtn:EnableMouse(true)
alertBtn:RegisterForClicks("AnyUp", "AnyDown")
alertBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
alertBtn:SetBackdropColor(0.06, 0.08, 0.12, 0.92)
alertBtn:SetBackdropBorderColor(0.0, 0.85, 1.0, 0.95)
alertBtn:Hide()

local alertIcon = alertBtn:CreateTexture(nil, "ARTWORK")
alertIcon:SetSize(38, 38)
alertIcon:SetPoint("LEFT", alertBtn, "LEFT", 7, 0)
alertIcon:SetTexture("Interface\\Icons\\INV_Elemental_Primal_Air")
alertIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local alertTitle = alertBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alertTitle:SetPoint("TOPLEFT", alertIcon, "TOPRIGHT", 8, -2)
alertTitle:SetPoint("RIGHT", alertBtn, "RIGHT", -6, 0)
alertTitle:SetJustifyH("LEFT")
alertTitle:SetText("|cff00ddffWalk on Air|r")

local alertSub = alertBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
alertSub:SetPoint("BOTTOMLEFT", alertIcon, "BOTTOMRIGHT", 8, 2)
alertSub:SetPoint("RIGHT", alertBtn, "RIGHT", -6, 0)
alertSub:SetJustifyH("LEFT")
alertSub:SetText("|cffffd100Press SPACE or Click!|r")

-- Shift + Left-Click Drag to reposition the Fall Alert Button
alertBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() and not InCombatLockdown() then
        self:StartMoving()
        self._isMoving = true
    end
end)
alertBtn:SetScript("OnMouseUp", function(self)
    if self._isMoving then
        self:StopMovingOrSizing()
        self._isMoving = false
        local point, _, relativePoint, x, y = self:GetPoint()
        local db = FallSaver:GetDB()
        db.alertPos = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = x or 0,
            y = y or -110,
        }
    end
end)

-- Release SPACE override binding immediately upon clicking TF_FallSaveButton or alertBtn!
local function OnFallSaveButtonPostClick()
    if lastArmedAbilityKey then
        selfCastTimestamps[lastArmedAbilityKey] = GetTime()
    end
    isSpacebarOverrideBound = false
    if not InCombatLockdown() then
        ClearOverrideBindings(fallSecureBtn)
        fallSecureBtn:SetAttribute("type", nil)
        fallSecureBtn:SetAttribute("macrotext", nil)
        if not testAlertMode then
            alertBtn:Hide()
        end
    end
end
fallSecureBtn:SetScript("PostClick", OnFallSaveButtonPostClick)
alertBtn:SetScript("PostClick", OnFallSaveButtonPostClick)

-- =========================================================================
-- Cooldown Warning & Active Glide Status Popup Button
-- Non-secure frame so it can pop up, pulse, and hide even IN COMBAT!
-- =========================================================================

local cdWarnBtn = CreateFrame("Button", "TimelessForever_FallCooldownFrame", UIParent, "BackdropTemplate")
cdWarnBtn:SetSize(256, 54)
cdWarnBtn:SetPoint("CENTER", UIParent, "CENTER", 0, -170)
cdWarnBtn:SetFrameStrata("HIGH")
cdWarnBtn:SetClampedToScreen(true)
cdWarnBtn:SetMovable(true)
cdWarnBtn:EnableMouse(true)
cdWarnBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
cdWarnBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
cdWarnBtn:SetBackdropColor(0.12, 0.06, 0.04, 0.93)
cdWarnBtn:SetBackdropBorderColor(1.0, 0.45, 0.1, 0.95)
cdWarnBtn:Hide()

local cdWarnIcon = cdWarnBtn:CreateTexture(nil, "ARTWORK")
cdWarnIcon:SetSize(38, 38)
cdWarnIcon:SetPoint("LEFT", cdWarnBtn, "LEFT", 7, 0)
cdWarnIcon:SetTexture("Interface\\Icons\\INV_Elemental_Primal_Air")
cdWarnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local cdWarnSwipe = CreateFrame("Cooldown", "TimelessForever_FallCooldownSwipe", cdWarnBtn, "CooldownFrameTemplate")
cdWarnSwipe:SetAllPoints(cdWarnIcon)
if cdWarnSwipe.SetDrawEdge then pcall(cdWarnSwipe.SetDrawEdge, cdWarnSwipe, true) end
if cdWarnSwipe.SetHideCountdownNumbers then pcall(cdWarnSwipe.SetHideCountdownNumbers, cdWarnSwipe, true) end

local cdWarnIconTimer = cdWarnBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cdWarnIconTimer:SetPoint("CENTER", cdWarnIcon, "CENTER", 0, 0)
cdWarnIconTimer:SetText("")

local cdWarnTitle = cdWarnBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cdWarnTitle:SetPoint("TOPLEFT", cdWarnIcon, "TOPRIGHT", 8, -3)
cdWarnTitle:SetPoint("RIGHT", cdWarnBtn, "RIGHT", -6, 0)
cdWarnTitle:SetJustifyH("LEFT")
cdWarnTitle:SetText("|cffff8800Walk on Air — ON COOLDOWN|r")

local cdWarnSub = cdWarnBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
cdWarnSub:SetPoint("BOTTOMLEFT", cdWarnIcon, "BOTTOMRIGHT", 8, 3)
cdWarnSub:SetPoint("RIGHT", cdWarnBtn, "RIGHT", -6, 0)
cdWarnSub:SetJustifyH("LEFT")
cdWarnSub:SetText("|cffffcc00Ready in 1m 30s|r")

-- Track Cooldown Warning state
local cdWarnDismissedUntilReady = false
local cdLastKnownOnCD = {}
local cdPopupTriggeredTime = 0
local cdReadyFlashUntil = 0
local cdReadyFlashAbility = nil
local cdTestMode = false
local dangerSoundPlayedThisFall = false
local lastSwipeStart = 0
local lastSwipeDur = 0

cdWarnBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() then
        self:StartMoving()
        self._isMoving = true
    end
end)
cdWarnBtn:SetScript("OnMouseUp", function(self)
    if self._isMoving then
        self:StopMovingOrSizing()
        self._isMoving = false
        local point, _, relativePoint, x, y = self:GetPoint()
        local db = FallSaver:GetDB()
        db.cdWarnPos = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = x or 0,
            y = y or -170,
        }
    end
end)
cdWarnBtn:SetScript("OnClick", function(self, button)
    if IsShiftKeyDown() then return end
    if button == "RightButton" then
        if cdTestMode then
            cdTestMode = false
            self:Hide()
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Cooldown Warning test button |cffff5555HIDDEN|r.")
        else
            cdWarnDismissedUntilReady = true
            self:Hide()
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Cooldown popup dismissed (will still warn if you fall while on cooldown).")
        end
    else
        local _, _, bestOnCD = FallSaver:DetectBestFallAbility(false)
        if bestOnCD and bestOnCD.cdRemaining and bestOnCD.cdRemaining > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s%s: |T%s:14:14:0:0|t |cffff8800%s|r is on cooldown for |cffffd100%s|r! (Right-click popup to hide, Shift+Drag to move).",
                ICON, BRAND_TITLE, bestOnCD.icon or "", bestOnCD.name, FormatCooldownTime(bestOnCD.cdRemaining)))
        elseif cdTestMode then
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Cooldown Warning is in Test Mode (Shift+Left-Click drag to move, Right-Click to close).")
        end
    end
end)
cdWarnBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(ICON .. BRAND_TITLE .. " — Fall Save Cooldown Tracker")
    GameTooltip:AddLine("|cffffd100Left-Click:|r Print remaining cooldown in chat", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("|cffffd100Right-Click:|r Dismiss until next fall or cooldown reset", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("|cffffd100Shift + Left-Drag:|r Move this warning button", 0.85, 0.85, 0.85)
    GameTooltip:Show()
end)
cdWarnBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

function FallSaver:RestoreAlertPosition()
    local db = self:GetDB()
    if not InCombatLockdown() then
        alertBtn:ClearAllPoints()
        local pos = db.alertPos or FALL_DEFAULTS.alertPos
        alertBtn:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or -110)
    end
    cdWarnBtn:ClearAllPoints()
    local cdPos = db.cdWarnPos or FALL_DEFAULTS.cdWarnPos
    cdWarnBtn:SetPoint(cdPos.point or "CENTER", UIParent, cdPos.relativePoint or "CENTER", cdPos.x or 0, cdPos.y or -170)
end

-- State variables for Jump vs. Fall & Swimming Tracking
-- NOTE: We NEVER hook JumpOrAscendStart so we never taint WoW's Jump/Swim-Up engine!
local lastJumpPressTime = 0
local lastSwimTime = 0
local fallStartTime = nil
local currentFallStartedFromJump = false
local isRealFallingArmed = false
local isSpacebarOverrideBound = false
local soundPlayedThisFall = false
local testAlertMode = false

local function IsJumpKeyCurrentlyDown()
    if not _G.IsKeyDown then return false end
    local k1, k2 = GetBindingKey("JUMP")
    if k1 and _G.IsKeyDown(k1) then return true end
    if k2 and _G.IsKeyDown(k2) then return true end
    if _G.IsKeyDown("SPACE") then return true end
    return false
end

local function TryBindSpacebarOverride()
    if isSpacebarOverrideBound or InCombatLockdown() then return end
    local db = FallSaver:GetDB()
    if db.spacebarGlide == false then return end
    -- CRITICAL: Never steal SPACE while the user is still holding SPACE down from jumping!
    -- Otherwise WoW's native JUMP binding misses the key-up event (AscendStop), causing infinite jumping in water!
    if IsJumpKeyCurrentlyDown() then return end

    ClearOverrideBindings(fallSecureBtn)
    local key1, key2 = GetBindingKey("JUMP")
    if key1 then
        SetOverrideBindingClick(fallSecureBtn, true, key1, "TF_FallSaveButton")
    else
        SetOverrideBindingClick(fallSecureBtn, true, "SPACE", "TF_FallSaveButton")
    end
    if key2 then
        SetOverrideBindingClick(fallSecureBtn, true, key2, "TF_FallSaveButton")
    end
    isSpacebarOverrideBound = true
end

local function ArmFallProtection(abilityRecord)
    if not abilityRecord then return end
    local db = FallSaver:GetDB()
    lastArmedAbilityKey = abilityRecord.entry and abilityRecord.entry.key or nil

    if not InCombatLockdown() then
        fallSecureBtn:SetAttribute("type", "macro")
        fallSecureBtn:SetAttribute("macrotext", abilityRecord.macro)

        alertBtn:SetAttribute("type", "macro")
        alertBtn:SetAttribute("macrotext", abilityRecord.macro)

        -- Only bind SPACE once the initial jump key press has been released!
        TryBindSpacebarOverride()

        if db.showAlertButton ~= false then
            alertIcon:SetTexture(abilityRecord.icon or "Interface\\Icons\\INV_Elemental_Primal_Air")
            alertTitle:SetText("|cff00ddff" .. (abilityRecord.name or "Fall Save") .. "|r")
            alertBtn:Show()
        end
    end

    if db.playAlertSound ~= false and not soundPlayedThisFall then
        soundPlayedThisFall = true
        if PlaySound then
            pcall(PlaySound, 8959) -- RAID_WARNING / subtle alert chime
        end
    end

    isRealFallingArmed = true
end

local function DisarmFallProtection()
    isRealFallingArmed = false
    isSpacebarOverrideBound = false
    if not InCombatLockdown() then
        ClearOverrideBindings(fallSecureBtn)
        fallSecureBtn:SetAttribute("type", nil)
        fallSecureBtn:SetAttribute("macrotext", nil)
        if not testAlertMode and alertBtn:IsShown() then
            alertBtn:Hide()
        end
    end
end

-- Pre-configure alertBtn before combat so clicking it still works even in combat
local function PreConfigureCombatFallback()
    if InCombatLockdown() then return end
    local best = FallSaver:DetectBestFallAbility(true)
    if best then
        alertBtn:SetAttribute("type", "macro")
        alertBtn:SetAttribute("macrotext", best.macro)
        alertIcon:SetTexture(best.icon or "Interface\\Icons\\INV_Elemental_Primal_Air")
        alertTitle:SetText("|cff00ddff" .. best.name .. "|r")
    end
end

-- Update the Cooldown Warning / Active Glide Status Popup Frame
local function UpdateCooldownWarningUI(now, isGenuinelyFalling, hasSafeBuff, safeBuffName, safeBuffRem, bestReady, bestOnCD)
    local db = FallSaver:GetDB()
    if cdTestMode then return end
    if db.showCooldownWarning == false then
        if cdWarnBtn:IsShown() then cdWarnBtn:Hide() end
        return
    end

    -- Detect transitions onto cooldown or off cooldown
    if bestOnCD and bestOnCD.cdRemaining and bestOnCD.cdRemaining > 1.5 then
        local key = bestOnCD.entry.key
        if not cdLastKnownOnCD[key] then
            cdLastKnownOnCD[key] = bestOnCD
            cdWarnDismissedUntilReady = false
            cdPopupTriggeredTime = now
            cdReadyFlashUntil = 0
        else
            cdLastKnownOnCD[key] = bestOnCD
        end
    else
        for k, prevRec in pairs(cdLastKnownOnCD) do
            cdLastKnownOnCD[k] = nil
            cdWarnDismissedUntilReady = false
            cdReadyFlashAbility = prevRec
            cdReadyFlashUntil = now + 3.0
            if db.playCooldownSound ~= false and PlaySound then
                pcall(PlaySound, 5274) -- AuctionWindowOpen / pleasant ready chime
            end
        end
    end

    -- 1. If a Fall-Saving Ability is currently ON COOLDOWN:
    if bestOnCD and bestOnCD.cdRemaining and bestOnCD.cdRemaining > 0 then
        local mode = db.cooldownDisplayMode or "always"
        local shouldShow = true
        if mode == "popup" then
            local withinInitialPopup = ((now - cdPopupTriggeredTime) <= 10.0)
            shouldShow = withinInitialPopup or hasSafeBuff or isGenuinelyFalling
        end
        if cdWarnDismissedUntilReady and not isGenuinelyFalling then
            shouldShow = false
        end

        if shouldShow then
            cdWarnIcon:SetTexture(bestOnCD.icon or "Interface\\Icons\\INV_Elemental_Primal_Air")
            local sStart = Unsecret(bestOnCD.cdStart) or 0
            local sDur = Unsecret(bestOnCD.cdDuration) or 0
            if type(sStart) == "number" and type(sDur) == "number" and sStart > 0 and sDur > 1.5 and (math.abs(sStart - lastSwipeStart) > 0.5 or math.abs(sDur - lastSwipeDur) > 0.5) then
                lastSwipeStart = sStart
                lastSwipeDur = sDur
                if cdWarnSwipe.SetCooldown then
                    pcall(cdWarnSwipe.SetCooldown, cdWarnSwipe, sStart, sDur)
                end
            end

            cdWarnIconTimer:SetText("|cffffdd44" .. FormatShortTimer(bestOnCD.cdRemaining) .. "|r")

            if hasSafeBuff then
                -- STATE A1: Currently Gliding / Slow-Falling while ability is on cooldown!
                if cdWarnIcon.SetDesaturated then pcall(cdWarnIcon.SetDesaturated, cdWarnIcon, false) end
                cdWarnBtn:SetBackdropColor(0.08, 0.12, 0.16, 0.94)
                cdWarnBtn:SetBackdropBorderColor(1.0, 0.78, 0.15, 0.98)
                cdWarnTitle:SetText(string.format("|cff00ff99%s ACTIVE|r |cffffaa00(ON CD)|r", safeBuffName or bestOnCD.name))
                if type(safeBuffRem) == "number" and safeBuffRem > 0 then
                    cdWarnSub:SetText(string.format("|cff00ddffGlide: %.1fs left|r  |cff888888•|r  |cffffaa00CD: %s|r", safeBuffRem, FormatCooldownTime(bestOnCD.cdRemaining)))
                else
                    cdWarnSub:SetText(string.format("|cff00ddffProtected|r  |cff888888•|r  |cffffaa00Cooldown: %s|r", FormatCooldownTime(bestOnCD.cdRemaining)))
                end
            elseif isGenuinelyFalling then
                -- STATE B: DANGER! Player is genuinely falling while their primary Fall Save is on cooldown!
                if cdWarnIcon.SetDesaturated then pcall(cdWarnIcon.SetDesaturated, cdWarnIcon, true) end
                local pulse = 0.55 + 0.45 * math.abs(math.sin(now * 7.5))
                cdWarnBtn:SetBackdropColor(0.24 * pulse, 0.03, 0.03, 0.96)
                cdWarnBtn:SetBackdropBorderColor(1.0, 0.12 * pulse, 0.12 * pulse, 1.0)

                if bestReady then
                    cdWarnTitle:SetText(string.format("|cffff4444%s ON CD (%s)!|r", bestOnCD.name, FormatCooldownTime(bestOnCD.cdRemaining)))
                    cdWarnSub:SetText(string.format("|cffffd100Backup Armed:|r |cff00ff00%s|r!", bestReady.name))
                else
                    cdWarnTitle:SetText(string.format("|cffff2222WARNING: %s ON CD!|r", bestOnCD.name))
                    cdWarnSub:SetText(string.format("|cffff5555NO FALL SAVE! Ready in %s|r", FormatCooldownTime(bestOnCD.cdRemaining)))
                    if db.playCooldownSound ~= false and not dangerSoundPlayedThisFall then
                        dangerSoundPlayedThisFall = true
                        if PlaySound then
                            pcall(PlaySound, 8959)
                        end
                    end
                end
            else
                -- STATE A2: On the ground / normal state after using Fall-Saving Ability while it's on cooldown
                if cdWarnIcon.SetDesaturated then pcall(cdWarnIcon.SetDesaturated, cdWarnIcon, true) end
                cdWarnBtn:SetBackdropColor(0.12, 0.06, 0.04, 0.92)
                cdWarnBtn:SetBackdropBorderColor(1.0, 0.45, 0.10, 0.95)
                cdWarnTitle:SetText(string.format("|cffff8800%s — ON COOLDOWN|r", bestOnCD.name))
                if bestReady then
                    cdWarnSub:SetText(string.format("|cffffcc00CD: %s|r |cffaaaaaa(Backup: %s)|r", FormatCooldownTime(bestOnCD.cdRemaining), bestReady.name))
                else
                    cdWarnSub:SetText(string.format("|cffffcc00Ready in %s|r |cffff6666(No Fall Save!)|r", FormatCooldownTime(bestOnCD.cdRemaining)))
                end
            end

            if not cdWarnBtn:IsShown() then
                cdWarnBtn:Show()
            end
        else
            if cdWarnBtn:IsShown() then
                cdWarnBtn:Hide()
            end
        end
        return
    end

    -- 2. Cooldown just finished! Show a brief 3-second green "READY!" confirmation flash
    if cdReadyFlashUntil > now and cdReadyFlashAbility then
        if cdWarnIcon.SetDesaturated then pcall(cdWarnIcon.SetDesaturated, cdWarnIcon, false) end
        if cdWarnSwipe.Clear then pcall(cdWarnSwipe.Clear, cdWarnSwipe) end
        lastSwipeStart = 0
        lastSwipeDur = 0
        cdWarnIcon:SetTexture(cdReadyFlashAbility.icon or "Interface\\Icons\\INV_Elemental_Primal_Air")
        cdWarnIconTimer:SetText("|cff00ff00OK|r")
        cdWarnBtn:SetBackdropColor(0.04, 0.14, 0.06, 0.94)
        cdWarnBtn:SetBackdropBorderColor(0.15, 1.0, 0.35, 0.98)
        cdWarnTitle:SetText(string.format("|cff00ff00%s — READY!|r", cdReadyFlashAbility.name))
        cdWarnSub:SetText("|cff88ff88Fall-Saving Ability Restored!|r")
        if not cdWarnBtn:IsShown() then
            cdWarnBtn:Show()
        end
        return
    end

    if cdWarnBtn:IsShown() then
        cdWarnBtn:Hide()
    end
end

-- Real-time OnUpdate Fall Detector & Cooldown Monitor
local fallCheckElapsed = 0
FallSaver:SetScript("OnUpdate", function(self, elapsed)
    fallCheckElapsed = fallCheckElapsed + elapsed
    if fallCheckElapsed < 0.04 then return end -- 25 FPS precision check
    fallCheckElapsed = 0

    local now = GetTime()

    -- Track Jump key state without ever hooking JumpOrAscendStart
    if IsJumpKeyCurrentlyDown() then
        lastJumpPressTime = now
    end

    -- Track Swimming / Water state FIRST and immediately release SPACE if in water or on ground!
    local isSwimmingNow = (IsSwimming and IsSwimming()) or (IsSubmerged and IsSubmerged())
    if isSwimmingNow then
        lastSwimTime = now
    end

    local isFallingNow = IsFalling and IsFalling()
    local isAirborneValid = isFallingNow
        and not isSwimmingNow
        and ((now - lastSwimTime) > 1.8) -- Never trigger while bobbing/jumping out of water!
        and not (UnitOnTaxi and UnitOnTaxi("player"))
        and not (IsFlying and IsFlying())
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))

    -- ALWAYS disarm SPACE override first if not validly falling!
    if not isAirborneValid then
        if fallStartTime ~= nil or isRealFallingArmed then
            fallStartTime = nil
            currentFallStartedFromJump = false
            soundPlayedThisFall = false
            dangerSoundPlayedThisFall = false
            DisarmFallProtection()
        end
    end

    local db = self:GetDB()
    if not db.enabled then
        if isRealFallingArmed then DisarmFallProtection() end
        if cdWarnBtn:IsShown() and not cdTestMode then cdWarnBtn:Hide() end
        return
    end

    local hasSafeBuff, safeBuffName, safeBuffRem = PlayerHasActiveSafeBuff()
    local bestReady, _, bestOnCD = self:DetectBestFallAbility(false)
    local isGenuinelyFalling = false

    if isAirborneValid then
        if not fallStartTime then
            fallStartTime = now
            currentFallStartedFromJump = ((now - lastJumpPressTime) <= 0.30)
            soundPlayedThisFall = false
            dangerSoundPlayedThisFall = false
        end

        local airTime = now - fallStartTime
        local requiredThreshold = currentFallStartedFromJump and (db.jumpThreshold or 0.95) or (db.ledgeThreshold or 0.35)

        if airTime >= requiredThreshold then
            isGenuinelyFalling = true
            if hasSafeBuff then
                if isRealFallingArmed then
                    DisarmFallProtection()
                end
            else
                if bestReady then
                    if not isRealFallingArmed then
                        ArmFallProtection(bestReady)
                    elseif not isSpacebarOverrideBound then
                        TryBindSpacebarOverride()
                    end
                    if alertBtn:IsShown() then
                        local hint = (db.spacebarGlide ~= false and not InCombatLockdown()) and "Press SPACE or Click!" or "Click to Activate!"
                        alertSub:SetText(string.format("|cffffd100%s|r |cffaaaaaa(%.1fs)|r", hint, airTime))
                    end
                elseif isRealFallingArmed then
                    DisarmFallProtection()
                end
            end
        end
    end

    -- Update the Cooldown Warning / Active Glide Status Popup
    UpdateCooldownWarningUI(now, isGenuinelyFalling, hasSafeBuff, safeBuffName, safeBuffRem, bestReady, bestOnCD)
end)

-- Create / Update "FallSave" Macro in /macro
function FallSaver:CreateFallMacro()
    if InCombatLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": |cffff3333Cannot create macro while in combat.|r")
        return
    end
    local best = self:DetectBestFallAbility(true)
    local spellName = best and best.name or "Walk on Air"
    local iconName = "INV_Elemental_Primal_Air"
    if best and best.entry and best.entry.icon then
        iconName = best.entry.icon:gsub("^Interface\\Icons\\", ""):gsub("^Interface/Icons/", "")
    end

    -- Clicks TF_FallSaveButton which is ONLY armed when IsFalling() exceeds the jump threshold!
    local body = "#showtooltip " .. spellName .. "\n/click TF_FallSaveButton LeftButton 1\n/click TF_FallSaveButton LeftButton 0"
    local macroName = "FallSave"
    local idx = GetMacroIndexByName and GetMacroIndexByName(macroName) or 0
    if idx and idx > 0 then
        pcall(EditMacro, idx, macroName, iconName, body)
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Updated |cffffd100\"FallSave\"|r macro for |cff00ddff" .. spellName .. "|r! (Protected: only activates when truly falling, never when jumping).")
    else
        local numAccount, numChar = GetNumMacros()
        local perChar = (numAccount >= (MAX_ACCOUNT_MACROS or 120))
        local ok = pcall(CreateMacro, macroName, iconName, body, perChar)
        if ok then
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Created |cffffd100\"FallSave\"|r macro for |cff00ddff" .. spellName .. "|r! Drag it from |cffffd100/macro|r to your action bars.")
        end
    end
end

-- Build live status summary for Settings UI & /fall status
function FallSaver:BuildStatusReport()
    local _, playerClass = UnitClass("player")
    local raceName = UnitRace("player") or "Unknown"
    local bestReady, allDetected, bestOnCD = self:DetectBestFallAbility(false)

    local lines = {}
    table.insert(lines, string.format("|cffffd100Character:|r %s %s", raceName, playerClass or ""))

    if bestReady then
        table.insert(lines, string.format("|cffffd100Active Fall Ability:|r |T%s:16:16:0:0|t |cff00ff00%s|r (%s) — |cff00ff00READY|r",
            bestReady.icon or "Interface\\Icons\\INV_Misc_QuestionMark", bestReady.name, bestReady.entry.category))
    elseif bestOnCD then
        table.insert(lines, string.format("|cffffd100Active Fall Ability:|r |T%s:16:16:0:0|t |cffffaa00%s|r — |cffff5555On Cooldown (%.0fs)|r",
            bestOnCD.icon or "Interface\\Icons\\INV_Misc_QuestionMark", bestOnCD.name, bestOnCD.cdRemaining or 0))
    else
        table.insert(lines, "|cffffd100Active Fall Ability:|r |cffff5555None currently available|r (Learn a class spell or carry Parachute Cloak / Noggenfogger / LIP)")
    end

    if #allDetected > 0 then
        table.insert(lines, "\n|cff00ccffDetected Usable Fall Abilities on This Character:|r")
        for i, rec in ipairs(allDetected) do
            local stateStr
            if not rec.hasReagent and rec.entry.reagentItemID then
                stateStr = "|cffff5555Missing Light Feather|r"
            elseif rec.alreadyInForm then
                stateStr = "|cff00ff00Already Active|r"
            elseif rec.cdRemaining and rec.cdRemaining > 0 then
                stateStr = string.format("|cffffaa00Cooldown (%.0fs)|r", rec.cdRemaining)
            else
                stateStr = "|cff00ff00Ready|r"
            end
            table.insert(lines, string.format("  %d. |T%s:14:14:0:0|t |cffffd100%s|r (%s) — %s",
                i, rec.icon or "", rec.name, rec.entry.category, stateStr))
        end
    end

    -- Check Passive Fall Abilities
    for _, pas in ipairs(PASSIVE_FALL_ABILITIES) do
        if pas.class == playerClass then
            local known = IsSpellKnownByPlayer({ spellIDs = { pas.spellID }, spellNames = { pas.name } })
            local status = known and "|cff00ff00Learned (Active Passive)|r" or ("|cff888888Unlearned (Requires Lv " .. pas.level .. ")|r")
            table.insert(lines, string.format("  • |cffffd100%s|r: %s — %s", pas.name, status, pas.desc))
        end
    end

    return table.concat(lines, "\n")
end

local ALL_CLASSES_FALL_GUIDE = [[|cff00ccffComplete WoW Forever Fall Abilities Reference:|r

|cffffd1001. Racial Fall Ability:|r
• |cff00ddffSkyborne (Windshaper & High Order)|r — |cffffd100Walk on Air|r: Instant 10s directional air glide (1.5m CD, no reagent). Works on ALL Skyborne classes!

|cffffd1002. Class Fall Abilities:|r
• |cff3fc7ebMage|r — |cffffd100Slow Fall|r (Lv 12, 30s float), |cffffd100Blink|r (Lv 20, resets fall momentum before ground), |cffffd100Ice Block|r (Lv 25 Frost Talent, immunity).
• |cffffffffPriest|r — |cffffd100Levitate|r (Lv 34, 2m float), |cffffd100Power Word: Shield|r (Lv 6+, absorbs impact damage).
• |cfff48cbaPaladin|r — |cffffd100Blessing of Protection|r (Lv 10+, physical immunity negates 100% of fall damage!), |cffffd100Divine Shield|r (Lv 34+, full immunity), |cffffd100Divine Protection|r (Lv 6+).
• |cffff7c0aDruid|r — |cffffd100Cat Form|r (Lv 20, reduces fall damage) + |cffffd100Feline Grace|r (Lv 40 passive), |cffffd100Barkskin|r (Lv 44, -20% damage).
• |cfffff468Rogue|r — |cffffd100Safe Fall|r (Lv 40 passive, automatically reduces fall damage).
• |cffc69b6dWarrior|r — |cffffd100Charge|r (Lv 4) / |cffffd100Intercept|r (Lv 30) to an enemy target on the ground cancels fall damage.
• |cff8788eeWarlock|r — |cffffd100Sacrifice|r (Voidwalker shield absorbs fall impact).
• |cff0070ddShaman|r — |cffffd100Reincarnation|r (Lv 30 passive self-resurrect if fall is lethal).

|cffffd1003. Universal Items (Any Class / Race):|r
• |cffffd100Parachute Cloak|r (Engineering Cloak, Slot 15) — 10s Slow Fall.
• |cffffd100Noggenfogger Elixir|r — 2 min Slow Fall buff.
• |cffffd100Limited Invulnerability Potion (LIP)|r — 6s physical immunity (negates 100% of fall damage).]]

local function RegisterFallSaverTab()
    local fallArgs = {
        header = {
            name = ICON .. BRAND_TITLE .. " - Smart Fall Saver & Auto-Glide",
            type = "header",
            order = 1,
        },
        desc = {
            name = "Automatically detects your character's best available fall-saving ability across all Races, Classes, and Items. Distinguishes normal jumping (~0.83s) from real falling so you never waste your cooldown when jumping!\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },
        statusHeader = {
            name = "Live Character Detection Status",
            type = "header",
            order = 5,
        },
        statusDesc = {
            name = function() return FallSaver:BuildStatusReport() end,
            type = "description",
            order = 6,
            fontSize = "medium",
        },
        settingsHeader = {
            name = "Fall Detection & Trigger Settings",
            type = "header",
            order = 10,
        },
        enabled = {
            name = "Enable Smart Fall Saver",
            desc = "Monitors IsFalling() and arms your best fall-saving ability only when you are genuinely falling.",
            type = "toggle",
            order = 11,
            get = function() return FallSaver:GetDB().enabled ~= false end,
            set = function(_, val)
                FallSaver:GetDB().enabled = val
                if not val then DisarmFallProtection() end
            end,
        },
        spacebarGlide = {
            name = "Spacebar Mid-Air Glide (Press SPACE While Falling)",
            desc = "When you are genuinely falling (past the jump threshold), pressing SPACE in mid-air casts your detected fall ability (like Walk on Air, Slow Fall, Levitate, or Cat Form). Normal jumps on flat ground are never affected!",
            type = "toggle",
            width = "double",
            order = 12,
            get = function() return FallSaver:GetDB().spacebarGlide ~= false end,
            set = function(_, val) FallSaver:GetDB().spacebarGlide = val end,
        },
        showAlertButton = {
            name = "Show On-Screen Fall Alert Button",
            desc = "Pops up a glowing clickable button in the center of your screen when real falling is detected (Shift+Drag to move).",
            type = "toggle",
            order = 13,
            get = function() return FallSaver:GetDB().showAlertButton ~= false end,
            set = function(_, val) FallSaver:GetDB().showAlertButton = val end,
        },
        playAlertSound = {
            name = "Play Audio Chime When Falling",
            desc = "Plays a warning chime when you have been falling longer than a normal jump.",
            type = "toggle",
            order = 14,
            get = function() return FallSaver:GetDB().playAlertSound ~= false end,
            set = function(_, val) FallSaver:GetDB().playAlertSound = val end,
        },
        showCooldownWarning = {
            name = "Show Cooldown Warning Popup When Used",
            desc = "Pops up a live Cooldown Warning button/tracker immediately when you use your Fall-Saving Ability (showing remaining glide time + cooldown timer, and flashing red if you fall while on cooldown).",
            type = "toggle",
            order = 14.2,
            get = function() return FallSaver:GetDB().showCooldownWarning ~= false end,
            set = function(_, val)
                FallSaver:GetDB().showCooldownWarning = val
                if not val and not cdTestMode then cdWarnBtn:Hide() end
            end,
        },
        playCooldownSound = {
            name = "Play Danger Alarm When Falling on Cooldown & Ready Chime",
            desc = "Plays an urgent warning alarm if you fall while your Fall-Saving Ability is on cooldown, and a pleasant chime when the cooldown finishes.",
            type = "toggle",
            order = 14.4,
            get = function() return FallSaver:GetDB().playCooldownSound ~= false end,
            set = function(_, val) FallSaver:GetDB().playCooldownSound = val end,
        },
        cooldownDisplayMode = {
            name = "Cooldown Popup Display Mode",
            desc = "Choose whether the Cooldown Warning stays on screen for the entire cooldown duration or pops up for 10s when used + whenever you fall while on cooldown.",
            type = "select",
            values = {
                always = "Show Entire Cooldown Duration (Recommended)",
                popup  = "Pop Up for 10s When Used + Whenever Falling on Cooldown",
            },
            width = "double",
            order = 14.6,
            get = function() return FallSaver:GetDB().cooldownDisplayMode or "always" end,
            set = function(_, val)
                FallSaver:GetDB().cooldownDisplayMode = val
                cdWarnDismissedUntilReady = false
            end,
        },
        allowImmunities = {
            name = "Allow Emergency Immunities (BoP / Divine Shield / Ice Block)",
            desc = "Include immunity spells (Blessing of Protection, Divine Shield, Ice Block, LIP) if no slow-fall spell is available.",
            type = "toggle",
            order = 15,
            get = function() return FallSaver:GetDB().allowImmunities ~= false end,
            set = function(_, val) FallSaver:GetDB().allowImmunities = val end,
        },
        allowItems = {
            name = "Allow Bag/Equipped Fall Items (Parachute Cloak / Noggenfogger)",
            desc = "Include Parachute Cloak, Noggenfogger Elixir, and Limited Invulnerability Potion as fallbacks.",
            type = "toggle",
            order = 16,
            get = function() return FallSaver:GetDB().allowItems ~= false end,
            set = function(_, val) FallSaver:GetDB().allowItems = val end,
        },
        jumpThreshold = {
            name = "Jump Filter Threshold (Seconds)",
            desc = "How long you must be airborne AFTER pressing Jump before it counts as falling. A normal jump on flat ground is ~0.83s, so 0.95s guarantees normal jumps never trigger it.",
            type = "range",
            min = 0.50,
            max = 2.50,
            step = 0.05,
            order = 20,
            get = function() return FallSaver:GetDB().jumpThreshold or 0.95 end,
            set = function(_, val) FallSaver:GetDB().jumpThreshold = val end,
        },
        ledgeThreshold = {
            name = "Walked-Off-Ledge Threshold (Seconds)",
            desc = "How long you must be airborne when walking/running off a cliff WITHOUT pressing Jump before it counts as falling.",
            type = "range",
            min = 0.15,
            max = 1.50,
            step = 0.05,
            order = 21,
            get = function() return FallSaver:GetDB().ledgeThreshold or 0.35 end,
            set = function(_, val) FallSaver:GetDB().ledgeThreshold = val end,
        },
        actionsHeader = {
            name = "Macro & Test Tools",
            type = "header",
            order = 30,
        },
        createFallMacroBtn = {
            name = "Create 'FallSave' Macro",
            desc = "Creates or updates a 'FallSave' macro in /macro that only fires when you are genuinely falling (doing nothing if pressed during a normal jump).",
            type = "execute",
            order = 31,
            func = function() FallSaver:CreateFallMacro() end,
        },
        testAlertBtn = {
            name = "Toggle Test Alert Button (Move Position)",
            desc = "Shows or hides the on-screen Fall Alert button so you can Shift+Left-Click drag it to your preferred screen position.",
            type = "execute",
            order = 32,
            func = function()
                testAlertMode = not testAlertMode
                if testAlertMode then
                    local best = FallSaver:DetectBestFallAbility(true)
                    alertIcon:SetTexture((best and best.icon) or "Interface\\Icons\\INV_Elemental_Primal_Air")
                    alertTitle:SetText("|cff00ddff" .. ((best and best.name) or "Walk on Air") .. "|r")
                    alertSub:SetText("|cffffd100Shift+Drag to Move (Test Mode)|r")
                    alertBtn:Show()
                else
                    alertBtn:Hide()
                end
            end,
        },
        testCooldownBtn = {
            name = "Toggle Test Cooldown Warning (Move Position)",
            desc = "Shows or hides the Cooldown Warning popup button so you can preview it and Shift+Left-Click drag it to your preferred screen position.",
            type = "execute",
            order = 33,
            func = function()
                cdTestMode = not cdTestMode
                if cdTestMode then
                    local best = FallSaver:DetectBestFallAbility(true)
                    local abilityName = (best and best.name) or "Walk on Air"
                    if cdWarnIcon.SetDesaturated then pcall(cdWarnIcon.SetDesaturated, cdWarnIcon, true) end
                    cdWarnIcon:SetTexture((best and best.icon) or "Interface\\Icons\\INV_Elemental_Primal_Air")
                    if cdWarnSwipe.SetCooldown then pcall(cdWarnSwipe.SetCooldown, cdWarnSwipe, GetTime() - 15, 90) end
                    cdWarnIconTimer:SetText("|cffffdd441:15|r")
                    cdWarnBtn:SetBackdropColor(0.12, 0.06, 0.04, 0.93)
                    cdWarnBtn:SetBackdropBorderColor(1.0, 0.45, 0.10, 0.95)
                    cdWarnTitle:SetText(string.format("|cffff8800%s — ON COOLDOWN|r", abilityName))
                    cdWarnSub:SetText("|cffffcc00Shift+Drag to Move (Test Mode)|r")
                    cdWarnBtn:Show()
                else
                    cdWarnBtn:Hide()
                end
            end,
        },
        guideHeader = {
            name = "All Classes & Races Fall Abilities Guide",
            type = "header",
            order = 40,
        },
        guideDesc = {
            name = ALL_CLASSES_FALL_GUIDE,
            type = "description",
            order = 41,
            fontSize = "medium",
        },
    }
    TimelessForeverSuite:RegisterModuleTab("fallsaver", "Fall Saver", 9, fallArgs)
end

-- Dedicated /fall and /tffall Slash Commands
SLASH_TIMELESSFALLSAVER1 = "/fall"
SLASH_TIMELESSFALLSAVER2 = "/tffall"
SLASH_TIMELESSFALLSAVER3 = "/fallsaver"
SlashCmdList["TIMELESSFALLSAVER"] = function(msg)
    local cmd = string.lower(strtrim(msg or ""))
    if cmd == "macro" then
        FallSaver:CreateFallMacro()
    elseif cmd == "status" or cmd == "check" or cmd == "detect" then
        DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. " |cff00ccffFall Saver Status:|r")
        for line in string.gmatch(FallSaver:BuildStatusReport(), "([^\n]+)") do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
        end
    elseif cmd == "test" then
        testAlertMode = not testAlertMode
        if testAlertMode then
            local best = FallSaver:DetectBestFallAbility(true)
            alertIcon:SetTexture((best and best.icon) or "Interface\\Icons\\INV_Elemental_Primal_Air")
            alertTitle:SetText("|cff00ddff" .. ((best and best.name) or "Walk on Air") .. "|r")
            alertSub:SetText("|cffffd100Shift+Drag to Move (Test Mode)|r")
            alertBtn:Show()
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Fall Alert test button |cff00ff00SHOWN|r (Shift+Left-Click drag to move).")
        else
            alertBtn:Hide()
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Fall Alert test button |cffff5555HIDDEN|r.")
        end
    elseif cmd == "cd" or cmd == "cdtest" or cmd == "cooldown" then
        cdTestMode = not cdTestMode
        if cdTestMode then
            local best = FallSaver:DetectBestFallAbility(true)
            local abilityName = (best and best.name) or "Walk on Air"
            if cdWarnIcon.SetDesaturated then pcall(cdWarnIcon.SetDesaturated, cdWarnIcon, true) end
            cdWarnIcon:SetTexture((best and best.icon) or "Interface\\Icons\\INV_Elemental_Primal_Air")
            if cdWarnSwipe.SetCooldown then pcall(cdWarnSwipe.SetCooldown, cdWarnSwipe, GetTime() - 15, 90) end
            cdWarnIconTimer:SetText("|cffffdd441:15|r")
            cdWarnBtn:SetBackdropColor(0.12, 0.06, 0.04, 0.93)
            cdWarnBtn:SetBackdropBorderColor(1.0, 0.45, 0.10, 0.95)
            cdWarnTitle:SetText(string.format("|cffff8800%s — ON COOLDOWN|r", abilityName))
            cdWarnSub:SetText("|cffffcc00Shift+Drag to Move (Test Mode)|r")
            cdWarnBtn:Show()
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Cooldown Warning test button |cff00ff00SHOWN|r (Shift+Left-Click drag to move, Right-Click to close).")
        else
            cdWarnBtn:Hide()
            DEFAULT_CHAT_FRAME:AddMessage(ICON .. BRAND_TITLE .. ": Cooldown Warning test button |cffff5555HIDDEN|r.")
        end
    else
        TimelessForeverSuite:OpenSettings("fallsaver")
    end
end

-- =========================================================================
-- Lifecycle & Event Handling
-- =========================================================================

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "ADDON_LOADED" then
        if arg1 == addonName or arg1 == "TimelessForever" then
            TimelessForeverSuite:InitDB()
            FallSaver:GetDB()
        end
    elseif event == "PLAYER_LOGIN" then
        TimelessForeverSuite:InitDB()
        FallSaver:GetDB()
        if not InCombatLockdown() then
            ClearOverrideBindings(fallSecureBtn)
        end
        FallSaver:RestoreAlertPosition()
        PreConfigureCombatFallback()
        RegisterGeneralTab()
        RegisterFallSaverTab()
        RegisterAboutTab()
        TimelessForeverSuite:CreateMinimapButton()
        pcall(function() TimelessForeverSuite:RefreshOptions() end)

        -- Automatically ensure macro exists and is up-to-date with /timelessforever
        if not InCombatLockdown() then
            TimelessForeverSuite:CreateMacro(false)
        else
            pendingMacroCreation = true
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if DEFAULT_CHAT_FRAME then
            HookChatFrameAddMessage(DEFAULT_CHAT_FRAME)
        end
        if ChatFrame1 then
            HookChatFrameAddMessage(ChatFrame1)
        end
        HookEllesmereUI()
        if TimelessForeverDB and TimelessForeverDB.cleanStartupChat ~= false then
            C_Timer.After(0.5, function()
                FlushStartupBuffer()
                if ChatFrame1 and FCF_SelectDockFrame then
                    pcall(FCF_SelectDockFrame, ChatFrame1)
                end
            end)
            C_Timer.After(1.0, HookEllesmereUI)
            C_Timer.After(2.0, HookEllesmereUI)
            C_Timer.After(4.0, HookEllesmereUI)
            local duration = 10
            C_Timer.After(duration, function()
                local mode = (TimelessForeverDB and TimelessForeverDB.cleanStartupMode) or "ALWAYS"
                if mode ~= "ALWAYS" then
                    TSC.isActive = false
                end
                FlushStartupBuffer()
                if ChatFrame1 and FCF_SelectDockFrame then
                    pcall(FCF_SelectDockFrame, ChatFrame1)
                end
                if TSC.OnStartupComplete then
                    TSC:OnStartupComplete()
                elseif TimelessForeverDB and TimelessForeverDB.showStartupNotice and TSC.count > 0 then
                    local frame = FindAddonChatFrame()
                    if frame and frame.AddMessage then
                        frame:AddMessage(ICON .. BRAND_TITLE .. ": Clean Chat: Routed " .. TSC.count .. " addon messages to this tab.")
                    end
                end
            end)
        end
    elseif event == "SPELLS_CHANGED" then
        PreConfigureCombatFallback()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit = Unsecret(arg1)
        if unit == "player" then
            local spellID = Unsecret(arg3) or Unsecret(arg2)
            local spellName = type(spellID) == "number" and SafeGetSpellNameAndIcon(spellID) or Unsecret(arg2)
            for _, entry in ipairs(FALL_ABILITIES_DB) do
                local matched = false
                if type(spellID) == "number" and entry.spellIDs then
                    for _, id in ipairs(entry.spellIDs) do
                        if id == spellID then matched = true; break end
                    end
                end
                if not matched and type(spellName) == "string" and entry.spellNames then
                    for _, sName in ipairs(entry.spellNames) do
                        if sName == spellName then matched = true; break end
                    end
                end
                if matched then
                    selfCastTimestamps[entry.key] = GetTime()
                    if not InCombatLockdown() then
                        ClearOverrideBindings(fallSecureBtn)
                    end
                    break
                end
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        PreConfigureCombatFallback()
        if not (IsFalling and IsFalling()) or (IsSwimming and IsSwimming()) or (IsSubmerged and IsSubmerged()) then
            DisarmFallProtection()
        end
        if pendingMacroCreation then
            pendingMacroCreation = false
            TimelessForeverSuite:CreateMacro(false)
        end
    end
end)

C_Timer.After(1, function()
    pcall(function() TimelessForeverSuite:RefreshOptions() end)
end)

-- =========================================================================
-- Addon Compartment Integration
-- =========================================================================
function TimelessForever_OnAddonCompartmentClick()
    if TimelessForeverSuite and TimelessForeverSuite.OpenSettings then
        TimelessForeverSuite:OpenSettings()
    end
end

if _G.AddonCompartmentFrame and _G.AddonCompartmentFrame.RegisterAddon then
    pcall(function()
        _G.AddonCompartmentFrame:RegisterAddon({
            text = "TimelessForever",
            icon = "Interface\\AddOns\\TimelessForever\\Icons\\gamehivehq",
            notCheckable = true,
            func = TimelessForever_OnAddonCompartmentClick,
        })
    end)
end


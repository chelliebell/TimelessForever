-- =========================================================================
-- !StartupClean: Early Startup Addon Chat Cleaner & Interceptor
-- =========================================================================
-- Loads alphabetically FIRST in World of Warcraft (due to the '!' prefix).
-- Intercepts startup splash banners, welcome messages, and addon prints
-- from ALL addons and cleanly routes them to the dedicated "ADDON Startup"
-- chat tab, leaving General chat clean for real player conversation.
-- Tracks which addon sent each cleaned message and provides interactive
-- hover tooltips and an interactive Cleaned Addons Viewer window.
-- =========================================================================

local TSC = _G["TimelessStartupClean"] or {}
_G["TimelessStartupClean"] = TSC

TSC.buffer = TSC.buffer or {}
TSC.count = TSC.count or 0
TSC.isActive = true
TSC.inChatEvent = false
TSC.targetFrame = nil
TSC.orig_print = TSC.orig_print or _G.print

-- Tracking cleaned messages per addon
TSC.cleanedAddons = TSC.cleanedAddons or {}
TSC.addonOrder = TSC.addonOrder or {}
TSC.currentLoadingAddon = nil
TSC.startupFinished = false

-- Known shared libraries to ignore when detecting calling addon
local KNOWN_LIBS = {
    ["ace3"] = true,
    ["aceaddon-3.0"] = true,
    ["acegui-3.0"] = true,
    ["aceconfig-3.0"] = true,
    ["aceconsole-3.0"] = true,
    ["acedb-3.0"] = true,
    ["aceevent-3.0"] = true,
    ["acetimer-3.0"] = true,
    ["libstub"] = true,
    ["callbackhandler-1.0"] = true,
    ["libsharedmedia-3.0"] = true,
    ["herebedragons"] = true,
    ["libcompress"] = true,
    ["libsink-2.0"] = true,
    ["libwindow-1.1"] = true,
    ["libdatabroker-1-1"] = true,
    ["libdbicon-1.0"] = true,
    ["libalib-1.0"] = true,
    ["libqtip-1.0"] = true,
    ["libcustomglow-1.0"] = true,
}

-- Identify caller addon from debugstack
local function IdentifyCallerAddon()
    local ok, stack = pcall(debugstack, 2, 20, 20)
    if not ok or not stack or stack == "" then return nil end
    local candidates = {}
    for line in stack:gmatch("[^\r\n]+") do
        for addon in line:gmatch("[\\/][Aa][Dd][Dd][Oo][Nn][Ss][\\/]([^\\/:]+)") do
            local l = addon:lower()
            if l ~= "!startupclean" then
                table.insert(candidates, addon)
            end
        end
    end
    if #candidates == 0 then return nil end
    for _, addon in ipairs(candidates) do
        if not KNOWN_LIBS[addon:lower()] then
            return addon
        end
    end
    return candidates[1]
end

-- Fallback: extract addon name from message text
local function ExtractAddonFromMessage(msg)
    if not msg or type(msg) ~= "string" then return nil end
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|H.-|h", ""):gsub("^%s+", ""):gsub("%s+$", "")
    
    -- [AddonName]
    local tag = clean:match("^%[([^%]]+)%]")
    if tag and #tag >= 2 and #tag <= 35 then
        local lower = tag:lower()
        if not lower:find("party") and not lower:find("raid") and not lower:find("system") and not lower:find("guild") then
            return tag
        end
    end

    -- <AddonName>
    local angle = clean:match("^<([^>]+)>")
    if angle and #angle >= 2 and #angle <= 35 then
        return angle
    end

    -- AddonName: or AddonName -
    local prefix = clean:match("^([%a0-9_%-]+)%s*[:%-]%s")
    if prefix and #prefix >= 3 and #prefix <= 30 then
        return prefix
    end

    -- Two-word addon: e.g. "TimelessForever Bookmarks ready!"
    local twoWords = clean:match("^([%a0-9_%-]+%s+[%a0-9_%-]+)%s+[Rr]eady") or clean:match("^([%a0-9_%-]+%s+[%a0-9_%-]+)%s+[Ll]oaded")
    if twoWords and #twoWords >= 3 and #twoWords <= 35 then
        return twoWords
    end

    -- One-word addon: e.g. "TimelessTweaks loaded!", "Recount loaded", "Details initialized"
    local word = clean:match("^([%a0-9_%-]+)%s+[Ll]oaded") or clean:match("^([%a0-9_%-]+)%s+[Rr]eady") or clean:match("^([%a0-9_%-]+)%s+[Ii]nitializ")
    if word and #word >= 3 and #word <= 30 then
        return word
    end

    return nil
end

-- Friendly display name for an addon
local function GetAddonDisplayName(addonKey)
    if not addonKey or addonKey == "" or addonKey == "Other" then
        return "Other / Unknown"
    end
    local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    if GetMetadata then
        local title = GetMetadata(addonKey, "Title")
        if title and title ~= "" then
            return title
        end
    end
    local GetInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
    if GetInfo then
        local name, title = GetInfo(addonKey)
        if title and title ~= "" then
            return title
        elseif name and name ~= "" then
            return name
        end
    end
    return addonKey
end

-- Search for existing Addon chat tab (ADDON Startup, Addons, Addon, etc.)
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

-- Create tab if none exists
local function EnsureAddonChatFrame()
    local existing = FindAddonChatFrame()
    if existing then return existing end

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

            -- Remove default Blizzard channels so normal player chat stays in General
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

-- Record cleaned message by addon
function TSC:RecordCleaned(addonKey, msg)
    if not addonKey or addonKey == "" then
        addonKey = "Other"
    end
    if not self.cleanedAddons[addonKey] then
        self.cleanedAddons[addonKey] = {
            name = addonKey,
            displayName = GetAddonDisplayName(addonKey),
            messages = {},
            count = 0,
        }
        table.insert(self.addonOrder, addonKey)
    end
    local entry = self.cleanedAddons[addonKey]
    entry.count = entry.count + 1
    table.insert(entry.messages, msg)
end

-- Route or buffer an intercepted message
function TSC:Route(msg, r, g, b, callerAddon)
    if not msg then return end
    self.count = self.count + 1

    if not callerAddon then
        callerAddon = IdentifyCallerAddon() or ExtractAddonFromMessage(msg) or self.currentLoadingAddon or "Other"
    end
    self:RecordCleaned(callerAddon, msg)

    local frame = FindAddonChatFrame()
    if frame and frame.AddMessage then
        frame:AddMessage(msg, r or 1, g or 1, b or 1)
    else
        table.insert(self.buffer, { text = msg, r = r or 1, g = g or 1, b = b or 1 })
    end
end

-- Flush buffered messages to target frame
function TSC:Flush()
    local frame = FindAddonChatFrame() or EnsureAddonChatFrame()
    if frame and self.buffer and #self.buffer > 0 then
        for _, entry in ipairs(self.buffer) do
            frame:AddMessage(entry.text, entry.r, entry.g, entry.b)
        end
        self.buffer = {}
    end
end

-- Show rich tooltip when hovering over an addon name
function TSC:ShowTooltipForAddon(owner, addonKey, anchor)
    local entry = self.cleanedAddons and self.cleanedAddons[addonKey]
    if not entry then return end

    GameTooltip:SetOwner(owner, anchor or "ANCHOR_CURSOR")
    GameTooltip:ClearLines()

    local title = entry.displayName or entry.name or addonKey
    GameTooltip:AddLine("|cff00ccff" .. title .. "|r", 1, 1, 1)
    local count = entry.count or (entry.messages and #entry.messages) or 0
    GameTooltip:AddLine("|cffffd100" .. count .. " message" .. (count == 1 and "" or "s") .. " cleaned at startup:|r", 0.9, 0.9, 0.9)
    GameTooltip:AddLine(" ")

    local maxPreview = 12
    for i, msg in ipairs(entry.messages) do
        if i > maxPreview then
            local remaining = #entry.messages - maxPreview
            GameTooltip:AddLine("|cff888888... and " .. remaining .. " more (click to view all)|r")
            break
        end
        local cleanLine = tostring(msg):gsub("[\r\n]+", " ")
        if #cleanLine > 140 then
            cleanLine = cleanLine:sub(1, 137) .. "..."
        end
        GameTooltip:AddLine("|cffffd100" .. i .. ".|r |cffffffff" .. cleanLine .. "|r", 1, 1, 1, true)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Click to open Cleaned Addons Viewer|r", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

-- Print list of cleaned addons to chat frame
function TSC:PrintCleanedList(targetFrame)
    local frame = targetFrame or FindAddonChatFrame() or DEFAULT_CHAT_FRAME or ChatFrame1
    if not frame or not frame.AddMessage then return end

    local totalAddons = self.addonOrder and #self.addonOrder or 0
    if totalAddons == 0 then
        frame:AddMessage("|cff00ccff[StartupClean]|r |cffffffffNo addon startup spam was intercepted.|r")
        return
    end

    frame:AddMessage("|cff00ccff=== [StartupClean] Cleaned Addons (" .. totalAddons .. ") ===|r")
    for i, addonKey in ipairs(self.addonOrder) do
        local entry = self.cleanedAddons[addonKey]
        if entry then
            local count = entry.count or #entry.messages
            local countStr = count .. " message" .. (count == 1 and "" or "s")
            local link = "|Hstartupclean:" .. addonKey .. "|h|cff00ff00[" .. (entry.displayName or addonKey) .. "]|r|h"
            frame:AddMessage("  |cff888888" .. i .. ".|r " .. link .. " |cff888888(" .. countStr .. ")|r")
        end
    end
    frame:AddMessage("|cff888888(Hover over an addon name to view what was cleaned up, or click to open viewer)|r")
end

-- Clear history
function TSC:ClearHistory()
    self.cleanedAddons = {}
    self.addonOrder = {}
    self.count = 0
    if self.UpdateViewer then
        self:UpdateViewer()
    end
end

-- Hook chat frame hyperlinks
local function HookChatFrameHyperlinks(cf)
    if not cf or cf._tscHyperlinksHooked then return end
    if cf.SetHyperlinksEnabled then
        cf:SetHyperlinksEnabled(true)
    end
    if cf.HookScript then
        cf:HookScript("OnHyperlinkEnter", function(self, link, text)
            if link and link:sub(1, 13) == "startupclean:" then
                local addonKey = link:sub(14)
                if addonKey == "ALL" then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine("|cff00ccffStartupClean|r", 1, 1, 1)
                    GameTooltip:AddLine("Click to open the Cleaned Addons Viewer window.", 0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                else
                    TSC:ShowTooltipForAddon(self, addonKey, "ANCHOR_CURSOR")
                end
            end
        end)
        cf:HookScript("OnHyperlinkLeave", function(self)
            if GameTooltip:IsOwned(self) then
                GameTooltip:Hide()
            end
        end)
    end
    cf._tscHyperlinksHooked = true
end

-- Hook SetItemRef to handle clicking on chat links
if not TSC.itemRefHooked then
    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        if link and link:sub(1, 13) == "startupclean:" then
            local addonKey = link:sub(14)
            if addonKey == "ALL" then
                TSC:OpenViewer()
            else
                TSC:OpenViewer(addonKey)
            end
            if ItemRefTooltip and ItemRefTooltip:IsShown() then
                ItemRefTooltip:Hide()
            end
        end
    end)
    TSC.itemRefHooked = true
end

-- =========================================================================
-- Cleaned Addons GUI Viewer Window
-- =========================================================================
function TSC:CreateViewer()
    if self.viewerFrame then return self.viewerFrame end

    local backdropTemplate = (BackdropTemplateMixin and "BackdropTemplate") or nil
    local f = CreateFrame("Frame", "StartupCleanViewerFrame", UIParent, backdropTemplate)
    f:SetSize(680, 480)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        f:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
        f:SetBackdropBorderColor(0.85, 0.72, 0.25, 1)
    end

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
    title:SetText("|TInterface\\Icons\\Spell_Holy_Silenced:18:18:0:0|t |cff00ccffStartupClean|r - Cleaned Addons Viewer")

    local sub = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText("Hover over an addon to preview cleaned messages. Click to display full log.")
    f.subTitle = sub

    -- Left Pane: Addons List
    local leftTitle = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    leftTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -48)
    leftTitle:SetText("|cffffd100Cleaned Addons:|r")

    local leftScroll = CreateFrame("ScrollFrame", "StartupCleanLeftScroll", f, "UIPanelScrollFrameTemplate")
    leftScroll:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -68)
    leftScroll:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 46)
    leftScroll:SetWidth(230)

    local leftChild = CreateFrame("Frame", nil, leftScroll)
    leftChild:SetWidth(210)
    leftChild:SetHeight(300)
    leftScroll:SetScrollChild(leftChild)
    f.leftChild = leftChild
    f.leftButtons = {}

    -- Divider
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.3, 0.3, 0.35, 0.6)
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", 256, -48)
    divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 256, 46)
    divider:SetWidth(1)

    -- Right Pane: Messages Display
    local rightTitle = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rightTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 268, -48)
    rightTitle:SetText("|cffffd100Cleaned Messages Log:|r")
    f.rightTitle = rightTitle

    local rightScroll = CreateFrame("ScrollFrame", "StartupCleanRightScroll", f, "UIPanelScrollFrameTemplate")
    rightScroll:SetPoint("TOPLEFT", f, "TOPLEFT", 268, -68)
    rightScroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 46)

    local editBox = CreateFrame("EditBox", nil, rightScroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(370)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) f:Hide() end)
    rightScroll:SetScrollChild(editBox)
    f.editBox = editBox

    -- Bottom Buttons
    local printBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    printBtn:SetSize(110, 24)
    printBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12)
    printBtn:SetText("Print to Chat")
    printBtn:SetScript("OnClick", function()
        TSC:PrintCleanedList()
    end)

    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 24)
    clearBtn:SetPoint("LEFT", printBtn, "RIGHT", 8, 0)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        TSC:ClearHistory()
    end)

    local copyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    copyBtn:SetSize(120, 24)
    copyBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -105, 12)
    copyBtn:SetText("Select All (Copy)")
    copyBtn:SetScript("OnClick", function()
        if f.editBox then
            f.editBox:SetFocus()
            f.editBox:HighlightText()
        end
    end)

    local closeBottomBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBottomBtn:SetSize(90, 24)
    closeBottomBtn:SetPoint("LEFT", copyBtn, "RIGHT", 8, 0)
    closeBottomBtn:SetText("Close")
    closeBottomBtn:SetScript("OnClick", function() f:Hide() end)

    table.insert(UISpecialFrames, "StartupCleanViewerFrame")
    self.viewerFrame = f
    return f
end

function TSC:UpdateViewer(selectedAddonKey)
    local f = self.viewerFrame
    if not f or not f:IsShown() then return end

    local totalAddons = self.addonOrder and #self.addonOrder or 0
    f.subTitle:SetText("Total Cleaned: |cffffd100" .. self.count .. "|r messages across |cffffd100" .. totalAddons .. "|r addons. Hover row to preview.")

    for _, btn in ipairs(f.leftButtons) do
        btn:Hide()
    end

    if totalAddons == 0 then
        f.rightTitle:SetText("|cffffd100Cleaned Messages Log:|r")
        f.editBox:SetText("No addon startup messages have been cleaned yet.")
        f.selectedAddon = nil
        return
    end

    if not selectedAddonKey or not self.cleanedAddons[selectedAddonKey] then
        selectedAddonKey = f.selectedAddon or self.addonOrder[1]
    end
    f.selectedAddon = selectedAddonKey

    local btnHeight = 26
    local totalHeight = totalAddons * btnHeight
    f.leftChild:SetHeight(math.max(totalHeight, 300))

    for i, addonKey in ipairs(self.addonOrder) do
        local btn = f.leftButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, f.leftChild, "UIPanelButtonTemplate")
            btn:SetHeight(24)
            btn:SetWidth(205)
            f.leftButtons[i] = btn
        end
        btn:SetPoint("TOPLEFT", f.leftChild, "TOPLEFT", 0, -((i - 1) * btnHeight))
        btn:Show()

        local entry = self.cleanedAddons[addonKey]
        local count = entry and entry.count or 0
        local name = entry and entry.displayName or addonKey
        local shortName = name
        if #shortName > 20 then
            shortName = shortName:sub(1, 18) .. ".."
        end

        if addonKey == selectedAddonKey then
            btn:SetText("|cff00ff00" .. shortName .. "|r (" .. count .. ")")
        else
            btn:SetText("|cffffffff" .. shortName .. "|r |cff888888(" .. count .. ")|r")
        end

        btn:SetScript("OnClick", function()
            TSC:UpdateViewer(addonKey)
        end)

        btn:SetScript("OnEnter", function(selfBtn)
            TSC:ShowTooltipForAddon(selfBtn, addonKey, "ANCHOR_RIGHT")
        end)

        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local selectedEntry = self.cleanedAddons[selectedAddonKey]
    if selectedEntry then
        local dName = selectedEntry.displayName or selectedAddonKey
        f.rightTitle:SetText("|cffffd100" .. dName .. "|r (" .. selectedEntry.count .. " cleaned messages):")
        local lines = {}
        for idx, m in ipairs(selectedEntry.messages) do
            table.insert(lines, idx .. ". " .. tostring(m))
        end
        f.editBox:SetText(table.concat(lines, "\n\n"))
    else
        f.editBox:SetText("")
    end
end

function TSC:OpenViewer(selectedAddonKey)
    local f = self:CreateViewer()
    f:Show()
    self:UpdateViewer(selectedAddonKey)
end

-- =========================================================================
-- Slash Commands
-- =========================================================================
SLASH_STARTUPCLEAN1 = "/startupclean"
SLASH_STARTUPCLEAN2 = "/sc"
SLASH_STARTUPCLEAN3 = "/startupclearer"
SlashCmdList["STARTUPCLEAN"] = function(msg)
    local cmd = (msg or ""):trim():lower()
    if cmd == "gui" or cmd == "window" or cmd == "show" or cmd == "viewer" or cmd == "list" then
        TSC:OpenViewer()
    elseif cmd == "clear" or cmd == "reset" then
        TSC:ClearHistory()
        local orig = TSC.orig_print or _G.print
        orig("|cff00ccff[StartupClean]|r Cleaned history cleared.")
    elseif cmd == "help" then
        local orig = TSC.orig_print or _G.print
        orig("|cff00ccff=== [StartupClean] Commands ===|r")
        orig("  |cffffd100/sc|r - Print list of cleaned addons to chat (hover over names to see cleaned messages)")
        orig("  |cffffd100/sc gui|r - Open the Cleaned Addons Viewer window")
        orig("  |cffffd100/sc clear|r - Clear cleaned messages history")
    else
        TSC:PrintCleanedList()
    end
end

-- Intercept player chat events ONLY so real player conversation is never touched
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

-- Hook global print(...)
if not TSC.printHooked then
    local orig_print = _G.print
    _G.print = function(...)
        if TSC.isActive then
            local caller = IdentifyCallerAddon()
            local n = select("#", ...)
            local msg = ""
            for i = 1, n do
                local arg = select(i, ...)
                if i > 1 then msg = msg .. " " end
                msg = msg .. tostring(arg)
            end
            if not caller then
                caller = ExtractAddonFromMessage(msg) or TSC.currentLoadingAddon or "Other"
            end
            TSC:Route(msg, 1, 1, 1, caller)
            return
        end
        return orig_print(...)
    end
    TSC.printHooked = true
end

-- Hook AddMessage on chat frames
local function HookFrame(frame)
    if not frame or frame._tscHooked then return end
    local orig_AddMessage = frame.AddMessage
    frame.AddMessage = function(self, text, r, g, b, id, holdTime)
        if TSC.isActive and not TSC.inChatEvent then
            local target = FindAddonChatFrame()
            if target and target == self then
                return orig_AddMessage(self, text, r, g, b, id, holdTime)
            end
            local caller = IdentifyCallerAddon() or ExtractAddonFromMessage(text) or TSC.currentLoadingAddon or "Other"
            TSC:Route(text, r, g, b, caller)
            return
        end
        return orig_AddMessage(self, text, r, g, b, id, holdTime)
    end
    frame._tscHooked = true
    HookChatFrameHyperlinks(frame)
end

-- Deep hook into EllesmereUIChat's custom ScrollingMessageFrame if active
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
                                    local caller = IdentifyCallerAddon() or ExtractAddonFromMessage(text) or TSC.currentLoadingAddon or "Other"
                                    TSC:Route(text, r, g, b, caller)
                                    return
                                end
                            end
                            return orig_SMF_AddMessage(self, text, r, g, b, chatTypeID, lineID, event)
                        end
                        child._tscHooked = true
                        HookChatFrameHyperlinks(child)
                    end
                end
            end
        end
    end
end

-- Startup completion handler
function TSC:OnStartupComplete()
    if self.startupFinished then return end
    self.startupFinished = true
    self:Flush()

    local addonTab = FindAddonChatFrame()
    if addonTab and self.count > 0 then
        self:PrintCleanedList(addonTab)
    end

    local showNotice = true
    if TimelessForeverDB and TimelessForeverDB.showStartupNotice == false then
        showNotice = false
    elseif TimelessTweaksDB and TimelessTweaksDB.showStartupNotice == false then
        showNotice = false
    end

    if showNotice and self.count > 0 then
        local genFrame = DEFAULT_CHAT_FRAME or ChatFrame1
        if genFrame and genFrame ~= addonTab and genFrame.AddMessage then
            self:PrintCleanedList(genFrame)
        end
    end
end

if DEFAULT_CHAT_FRAME then
    HookFrame(DEFAULT_CHAT_FRAME)
end
if ChatFrame1 then
    HookFrame(ChatFrame1)
end

-- Hook all existing chat frames
for i = 1, NUM_CHAT_WINDOWS or 10 do
    local cf = _G["ChatFrame" .. i]
    if cf then
        HookFrame(cf)
    end
end

-- Keep hooking chat frames as they initialize
local earlyFrame = CreateFrame("Frame")
earlyFrame:RegisterEvent("VARIABLES_LOADED")
earlyFrame:RegisterEvent("ADDON_LOADED")
earlyFrame:RegisterEvent("PLAYER_LOGIN")
earlyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
earlyFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 and type(arg1) == "string" then
            TSC.currentLoadingAddon = arg1
        end
        return
    end

    if DEFAULT_CHAT_FRAME then
        HookFrame(DEFAULT_CHAT_FRAME)
    end
    if ChatFrame1 then
        HookFrame(ChatFrame1)
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local cf = _G["ChatFrame" .. i]
        if cf then
            HookFrame(cf)
        end
    end
    HookEllesmereUI()

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        EnsureAddonChatFrame()
        TSC:Flush()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, HookEllesmereUI)
            C_Timer.After(1.0, HookEllesmereUI)
            C_Timer.After(2.0, HookEllesmereUI)
            C_Timer.After(4.0, HookEllesmereUI)
            -- Standalone startup completion timer
            C_Timer.After(8.0, function()
                TSC:OnStartupComplete()
            end)
        end
    end
end)

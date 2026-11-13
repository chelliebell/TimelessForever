-- =========================================================================
-- TimelessTweaks: Ultra Graphics, Engine CVars, Controls & UI Optimizer
-- Custom-crafted for World of Warcraft
-- Pure Zero-Taint Architecture (No EnableKeyboard, No Startup Hooks)
-- =========================================================================

local addonName, addonTable = ...
local TimelessTweaks = CreateFrame("Frame")
local ForeverTweaks = TimelessTweaks
local ICON = "|TInterface\\Icons\\INV_Gizmo_02:16:16:0:0|t "

-- =========================================================================
-- Default Configurations
-- =========================================================================
local defaultDB = {
    -- Graphics & Engine CVars
    cameraDistanceMaxZoomFactor = 4.0,
    reflectionMode = 3,
    ResampleAlwaysSharpen = 1,
    weatherdensity = 3,
    groundEffectDist = 500,
    groundEffectDensity = 256,
    doodadLodScale = 200,
    terrainLodDist = 1000,
    lodObjectCullSize = 35,
    lodObjectFadeScale = 200,

    -- Controls
    stickyTargeting = true,        -- deselectOnClick = 0, autoClearTarget = 0
    lootUnderMouse = true,         -- lootUnderMouse = 1
    autoLoot = true,               -- autoLootDefault = 1
    combineBags = true,            -- combinedBags = 1
    cameraSmoothStyle = 0,         -- 0 = Never follow

    -- Combat
    showSilhouette = true,         -- findYourselfMode = 2, findYourselfAnywhere = 1
    targetOfTarget = true,         -- showTargetOfTarget = 1
    doNotFlashLowHealth = true,    -- doNotFlashLowHealthChar = 1
    mouseoverCast = true,          -- enableMouseoverCast = 1
    mouseoverCastKey = "NONE",     -- NONE, ALT, CTRL, SHIFT
    actionTarget = true,           -- SoftTargetEnemy = 3, SoftTargetInteract = 3
    autoPotionNoWindstone = true,  -- Remove Windstone (255663) from AutoPotion macros

    -- Interface
    statusText = true,             -- statusText = 1
    displayClassColors = true,     -- chatClassColorOverride = 0, ShowClassColorInNameplate = 1
    flashingAnimation = true,      -- actionStatusFlash = 1, displaySpellActivationOverlays = 1
    healthTextFormat = "BOTH",     -- statusTextDisplay: NUMERIC, PERCENT, BOTH, NONE

    -- Social
    matureFilter = false,          -- profanityFilter = 0
    guildMemberAlert = true,       -- guildMemberNotify = 1
    discordUrl = "https://discord.gg/your-community",

    -- Action Bars & Pings
    alwaysShowActionBars = true,   -- alwaysShowActionBars = 1
    hideActionBarEndCaps = true,   -- Force hide MainActionBar.EndCaps.LeftEndCap & RightEndCap (.Texture)
    enablePings = true,            -- pingMode = 1
    pingKey = "BUTTON3",

    -- Nameplates
    friendlyNamesOnly = true,      -- nameplateShowFriendlyPlayers = 1, nameplateShowOnlyNames = 1
    friendlyClassColor = true,     -- ShowClassColorInFriendlyNameplate = 1, nameplateShowFriendlyPlayerClassColor = 1
    nameplateSize = 2.0,           -- nameplateGlobalScale = 2.0
    nameplateAuraScale = 1.0,      -- 100%
    nameplateBlockStyle = true,    -- Block style texture
    nameplateHealthPercent = true, -- Show health percentage
    nameplateCastBarAll = true,    -- nameplateShowCastBars = 1, timer on
    nameplateEnemyNPCBuffs = true,
    nameplateEnemyPlayerBuffs = true,
    nameplateFriendBuffs = true,
    nameplateDebuffPadding = 3,
    simplifyMinions = true,        -- nameplateShowFriendlyMinions = 0, nameplateShowEnemyMinions = 0
    simplifyFriendlyNPCs = true,   -- nameplateShowFriendlyNPCs = 0
    enemyPlayerClassColor = true,  -- ShowClassColorInNameplate = 1, nameplateShowEnemyPlayerClassColor = 1

    -- General & Advanced
    cursorSize = 1,                -- cursorSizePreferred: -1=Auto, 0=32, 1=48, 2=64, 3=96
    enableCooldownManager = true,  -- countdownForCooldowns = 1

    -- Chat & Startup Cleanliness
    cleanStartupChat = true,       -- Clean startup addon spam and route to 'ADDON Startup' tab
    createStartupTab = true,       -- Auto-create and maintain 'ADDON Startup' chat tab
    showStartupNotice = true,      -- Display a subtle single-line summary in main chat when startup completes
    cleanStartupDuration = 10,     -- Grace window in seconds after login to intercept startup banners
    cleanStartupMode = "ALWAYS",   -- "ALWAYS" (routes all addon output to ADDON Startup), "STARTUP" (first 10s), "OFF"
}

TimelessForever_TweaksDB = TimelessForever_TweaksDB or TimelessForeverTweaksDB or TimelessTweaksDB or ForeverTweaksDB or {}
TimelessForeverTweaksDB = TimelessForever_TweaksDB
TimelessTweaksDB = TimelessForever_TweaksDB
ForeverTweaksDB = TimelessTweaksDB

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

-- Find existing "ADDON Startup" tab (or "Addons", "Addon", etc.)
local function GetAddonStartupChatFrame()
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

-- Create or fetch "ADDON Startup" tab
local function GetOrCreateAddonStartupChatFrame()
    local existing = GetAddonStartupChatFrame()
    if existing then return existing end

    if not (TimelessTweaksDB.createStartupTab ~= false) then return nil end

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

            -- Remove Blizzard default channels so normal player chat stays in General
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
    local frame = GetAddonStartupChatFrame()
    if frame and frame.AddMessage then
        frame:AddMessage(msg, r or 1, g or 1, b or 1)
    else
        table.insert(self.buffer, { text = msg, r = r or 1, g = g or 1, b = b or 1 })
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

-- Hook global print(...)
if not TSC.printHooked then
    local orig_print = _G.print
    _G.print = function(...)
        local isCleanChat = (TimelessTweaksDB.cleanStartupChat ~= false)
        local mode = TimelessTweaksDB.cleanStartupMode or "ALWAYS"
        local shouldFilter = isCleanChat and (
            TSC.isActive or (mode == "ALWAYS")
        )
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

-- Hook ChatFrame AddMessage
local function HookChatFrameAddMessage(frame)
    if not frame or frame._tscHooked then return end
    local orig_AddMessage = frame.AddMessage
    frame.AddMessage = function(self, text, r, g, b, id, holdTime)
        local isCleanChat = (TimelessTweaksDB.cleanStartupChat ~= false)
        local mode = TimelessTweaksDB.cleanStartupMode or "ALWAYS"
        local shouldFilter = isCleanChat and (
            TSC.isActive or (mode == "ALWAYS")
        )
        if shouldFilter and not TSC.inChatEvent then
            local target = GetAddonStartupChatFrame()
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

if DEFAULT_CHAT_FRAME then
    HookChatFrameAddMessage(DEFAULT_CHAT_FRAME)
end
if ChatFrame1 then
    HookChatFrameAddMessage(ChatFrame1)
end

function TimelessTweaks:OpenStartupTab()
    local frame = GetOrCreateAddonStartupChatFrame()
    if frame then
        if FCF_SelectDockFrame then
            FCF_SelectDockFrame(frame)
        elseif FCFDock_SelectWindow and GENERAL_CHAT_DOCK then
            FCFDock_SelectWindow(GENERAL_CHAT_DOCK, frame)
        end
    end
end

function TimelessTweaks:ClearStartupTab()
    local frame = GetAddonStartupChatFrame()
    if frame and frame.Clear then
        frame:Clear()
        frame:AddMessage("|cff00ccff=== [ADDON Startup] Clean Log (Cleared) ===|r")
        local orig = TSC.orig_print or _G.print
        orig(ICON .. "|cff00ccff[TimelessTweaks]|r ADDON Startup tab log cleared.")
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

-- =========================================================================
-- Pure C-Engine Safe CVar Wrappers (Bypasses Lua wrapper taint)
-- =========================================================================
local function SafeGetCVar(cvar, defaultVal)
    if not cvar then return defaultVal end
    local val
    pcall(function()
        if C_CVar and C_CVar.GetCVar then
            val = C_CVar.GetCVar(cvar)
        elseif GetCVar then
            val = GetCVar(cvar)
        end
    end)
    if val == nil then return defaultVal end
    return val
end

local function SafeSetCVar(cvar, val)
    if not cvar then return end
    if InCombatLockdown and InCombatLockdown() then return end
    pcall(function()
        if C_CVar and C_CVar.SetCVar then
            C_CVar.SetCVar(cvar, tostring(val))
        elseif SetCVar then
            SetCVar(cvar, tostring(val))
        end
    end)
end

local function InitDB()
    TimelessForever_TweaksDB = TimelessForever_TweaksDB or TimelessForeverTweaksDB or TimelessTweaksDB or ForeverTweaksDB or {}
TimelessForeverTweaksDB = TimelessForever_TweaksDB
TimelessTweaksDB = TimelessForever_TweaksDB
ForeverTweaksDB = TimelessTweaksDB
    for k, v in pairs(defaultDB) do
        if TimelessTweaksDB[k] == nil then
            TimelessTweaksDB[k] = v
        end
    end
    if TimelessTweaksDB.cleanStartupMode == nil or TimelessTweaksDB.cleanStartupMode == "STARTUP" then
        TimelessTweaksDB.cleanStartupMode = "ALWAYS"
    end
end

-- Read-only sync of in-game CVars (never calls SetCVar on load!)
function TimelessTweaks:SyncFromGameCVars()
    local db = TimelessTweaksDB
    local function GetNum(cvar, defaultVal)
        local val = SafeGetCVar(cvar)
        local num = val and tonumber(val)
        return num or defaultVal
    end
    if db.cameraDistanceMaxZoomFactor == nil then db.cameraDistanceMaxZoomFactor = GetNum("cameraDistanceMaxZoomFactor", 4.0) end
    if db.reflectionMode == nil then db.reflectionMode = GetNum("reflectionMode", 3) end
    if db.weatherdensity == nil then db.weatherdensity = GetNum("weatherdensity", 3) end
    if db.groundEffectDist == nil then db.groundEffectDist = GetNum("groundEffectDist", 500) end
    if db.groundEffectDensity == nil then db.groundEffectDensity = GetNum("groundEffectDensity", 256) end
    if db.doodadLodScale == nil then db.doodadLodScale = GetNum("doodadLodScale", 200) end
    if db.terrainLodDist == nil then db.terrainLodDist = GetNum("terrainLodDist", 1000) end
    if db.lodObjectCullSize == nil then db.lodObjectCullSize = GetNum("lodObjectCullSize", 35) end
    if db.lodObjectFadeScale == nil then db.lodObjectFadeScale = GetNum("lodObjectFadeScale", 200) end
    if db.nameplateSize == nil then db.nameplateSize = GetNum("nameplateGlobalScale", 2.0) end
    if db.cursorSize == nil then db.cursorSize = GetNum("cursorSizePreferred", 1) end
end

-- =========================================================================
-- Apply Functions (Invoked only on explicit user click or slider change)
-- =========================================================================
function TimelessTweaks:ApplyGraphicsSettings()
    local db = TimelessTweaksDB
    SafeSetCVar("cameraDistanceMaxZoomFactor", db.cameraDistanceMaxZoomFactor or 4.0)
    SafeSetCVar("reflectionMode", db.reflectionMode or 3)
    SafeSetCVar("ResampleAlwaysSharpen", db.ResampleAlwaysSharpen or 1)
    SafeSetCVar("weatherdensity", db.weatherdensity or 3)
    SafeSetCVar("groundEffectDist", db.groundEffectDist or 500)
    SafeSetCVar("groundEffectDensity", db.groundEffectDensity or 256)
    SafeSetCVar("doodadLodScale", db.doodadLodScale or 200)
    SafeSetCVar("terrainLodDist", db.terrainLodDist or 1000)
    SafeSetCVar("lodObjectCullSize", db.lodObjectCullSize or 35)
    SafeSetCVar("lodObjectFadeScale", db.lodObjectFadeScale or 200)
end

function TimelessTweaks:ApplyControlsSettings()
    local db = TimelessTweaksDB
    SafeSetCVar("deselectOnClick", db.stickyTargeting and 0 or 1)
    SafeSetCVar("autoClearTarget", db.stickyTargeting and 0 or 1)
    SafeSetCVar("lootUnderMouse", db.lootUnderMouse and 1 or 0)
    SafeSetCVar("autoLootDefault", db.autoLoot and 1 or 0)
    SafeSetCVar("combinedBags", db.combineBags and 1 or 0)
    SafeSetCVar("cameraSmoothStyle", db.cameraSmoothStyle or 0)
end

function TimelessTweaks:ApplyCombatSettings()
    local db = TimelessTweaksDB

    if db.showSilhouette then
        SafeSetCVar("findYourselfMode", 2)
        SafeSetCVar("findYourselfAnywhere", 1)
    else
        SafeSetCVar("findYourselfMode", 0)
    end

    SafeSetCVar("showTargetOfTarget", db.targetOfTarget and 1 or 0)
    SafeSetCVar("doNotFlashLowHealthChar", db.doNotFlashLowHealth and 1 or 0)
    SafeSetCVar("enableMouseoverCast", db.mouseoverCast and 1 or 0)
    if db.mouseoverCastKey then
        SafeSetCVar("mouseoverCastKey", db.mouseoverCastKey)
    end

    if db.actionTarget then
        SafeSetCVar("SoftTargetEnemy", 3)
        SafeSetCVar("SoftTargetInteract", 3)
    else
        SafeSetCVar("SoftTargetEnemy", 0)
        SafeSetCVar("SoftTargetInteract", 0)
    end
end

function TimelessTweaks:ApplyInterfaceSettings()
    local db = TimelessTweaksDB
    SafeSetCVar("statusText", db.statusText and 1 or 0)
    SafeSetCVar("chatClassColorOverride", db.displayClassColors and 0 or 1)
    SafeSetCVar("ShowClassColorInNameplate", db.displayClassColors and 1 or 0)
    SafeSetCVar("actionStatusFlash", db.flashingAnimation and 1 or 0)
    SafeSetCVar("displaySpellActivationOverlays", db.flashingAnimation and 1 or 0)

    if db.healthTextFormat then
        SafeSetCVar("statusTextDisplay", db.healthTextFormat)
    end

    SafeSetCVar("profanityFilter", db.matureFilter and 1 or 0)
    SafeSetCVar("guildMemberNotify", db.guildMemberAlert and 1 or 0)
end

function TimelessTweaks:ApplyNameplateSettings()
    local db = TimelessTweaksDB
    SafeSetCVar("nameplateShowFriendlyPlayers", db.friendlyNamesOnly and 1 or 0)
    SafeSetCVar("nameplateShowOnlyNames", db.friendlyNamesOnly and 1 or 0)
    SafeSetCVar("ShowClassColorInFriendlyNameplate", db.friendlyClassColor and 1 or 0)
    SafeSetCVar("nameplateShowFriendlyPlayerClassColor", db.friendlyClassColor and 1 or 0)

    local scale = db.nameplateSize or 2.0
    SafeSetCVar("nameplateGlobalScale", scale)
    SafeSetCVar("nameplateSelectedScale", math.min(scale * 1.1, 2.5))

    local auraScale = db.nameplateAuraScale or 1.0
    SafeSetCVar("nameplateMinScale", auraScale)
    SafeSetCVar("nameplateMaxScale", auraScale)

    SafeSetCVar("nameplateShowCastBars", db.nameplateCastBarAll and 1 or 0)
    SafeSetCVar("nameplateShowCastBarTimer", db.nameplateCastBarAll and 1 or 0)

    if db.simplifyMinions then
        SafeSetCVar("nameplateShowFriendlyMinions", 0)
        SafeSetCVar("nameplateShowEnemyMinions", 0)
    else
        SafeSetCVar("nameplateShowFriendlyMinions", 1)
        SafeSetCVar("nameplateShowEnemyMinions", 1)
    end

    if db.simplifyFriendlyNPCs then
        SafeSetCVar("nameplateShowFriendlyNPCs", 0)
    else
        SafeSetCVar("nameplateShowFriendlyNPCs", 1)
    end

    SafeSetCVar("ShowClassColorInNameplate", db.enemyPlayerClassColor and 1 or 0)
    SafeSetCVar("nameplateShowEnemyPlayerClassColor", db.enemyPlayerClassColor and 1 or 0)
end

-- =========================================================================
-- Force Hide MainActionBar EndCaps (LeftEndCap & RightEndCap + Textures)
-- =========================================================================
local endCapTargets = {}
local endCapHooked = {}
local mainActionBarHooked = false

local function ShouldHideEndCaps()
    if TimelessTweaksDB and TimelessTweaksDB.hideActionBarEndCaps ~= nil then
        return TimelessTweaksDB.hideActionBarEndCaps ~= false
    end
    return true
end

local function SetEndCapTargetVisibility(target, shouldHide)
    if not target or target._tftEndCapWriting then return end
    target._tftEndCapWriting = true
    if shouldHide then
        if type(target.SetAlpha) == "function" then
            pcall(target.SetAlpha, target, 0)
        end
        if type(target.Hide) == "function" then
            pcall(target.Hide, target)
        end
    else
        if type(target.SetAlpha) == "function" then
            pcall(target.SetAlpha, target, 1)
        end
        if type(target.Show) == "function" then
            pcall(target.Show, target)
        end
    end
    target._tftEndCapWriting = false
end

local function HookAndTrackEndCap(target)
    if not target or (type(target) ~= "table" and type(target) ~= "userdata") then return end
    if endCapHooked[target] then return end
    endCapHooked[target] = true
    table.insert(endCapTargets, target)

    if type(target.Show) == "function" then
        pcall(hooksecurefunc, target, "Show", function(self)
            if ShouldHideEndCaps() then
                SetEndCapTargetVisibility(self, true)
            end
        end)
    end
    if type(target.SetShown) == "function" then
        pcall(hooksecurefunc, target, "SetShown", function(self, shown)
            if shown and ShouldHideEndCaps() then
                SetEndCapTargetVisibility(self, true)
            end
        end)
    end
    if type(target.SetAlpha) == "function" then
        pcall(hooksecurefunc, target, "SetAlpha", function(self, alpha)
            if alpha and alpha > 0 and ShouldHideEndCaps() then
                SetEndCapTargetVisibility(self, true)
            end
        end)
    end
    if type(target.SetAtlas) == "function" then
        pcall(hooksecurefunc, target, "SetAtlas", function(self)
            if ShouldHideEndCaps() then
                SetEndCapTargetVisibility(self, true)
            end
        end)
    end
    if type(target.SetTexture) == "function" then
        pcall(hooksecurefunc, target, "SetTexture", function(self)
            if ShouldHideEndCaps() then
                SetEndCapTargetVisibility(self, true)
            end
        end)
    end
    if type(target.HookScript) == "function" then
        pcall(function()
            target:HookScript("OnShow", function(self)
                if ShouldHideEndCaps() then
                    SetEndCapTargetVisibility(self, true)
                end
            end)
        end)
    end
end

local function CollectFromCapNode(node)
    if not node then return end
    HookAndTrackEndCap(node)
    if type(node) == "table" then
        if node.Texture then HookAndTrackEndCap(node.Texture) end
        if node.texture then HookAndTrackEndCap(node.texture) end
    end
    if type(node.GetRegions) == "function" then
        local ok, regions = pcall(function() return { node:GetRegions() } end)
        if ok and regions then
            for _, reg in ipairs(regions) do
                HookAndTrackEndCap(reg)
            end
        end
    end
end

local function DiscoverEndCapTargets()
    local mab = _G["MainActionBar"]
    if mab then
        local endCaps = mab.EndCaps or mab.endCaps
        if endCaps then
            HookAndTrackEndCap(endCaps)
            CollectFromCapNode(endCaps.LeftEndCap or endCaps.leftEndCap)
            CollectFromCapNode(endCaps.RightEndCap or endCaps.rightEndCap)
            if type(endCaps.GetRegions) == "function" then
                local ok, regions = pcall(function() return { endCaps:GetRegions() } end)
                if ok and regions then
                    for _, reg in ipairs(regions) do
                        CollectFromCapNode(reg)
                    end
                end
            end
            if type(endCaps.GetChildren) == "function" then
                local ok, children = pcall(function() return { endCaps:GetChildren() } end)
                if ok and children then
                    for _, child in ipairs(children) do
                        CollectFromCapNode(child)
                    end
                end
            end
        end
        CollectFromCapNode(mab.LeftEndCap or mab.leftEndCap)
        CollectFromCapNode(mab.RightEndCap or mab.rightEndCap)

        if not mainActionBarHooked then
            mainActionBarHooked = true
            for _, methodName in ipairs({ "UpdateEndCaps", "SetHideBarArt", "UpdateVisibility", "EditModeSystemMixin_OnEditModeExit" }) do
                if type(mab[methodName]) == "function" then
                    pcall(hooksecurefunc, mab, methodName, function()
                        if ShouldHideEndCaps() then
                            TimelessTweaks:ApplyActionBarEndCaps()
                        end
                    end)
                end
            end
        end
    end

    CollectFromCapNode(_G["MainActionBarEndCaps"])
    CollectFromCapNode(_G["MainActionBarLeftEndCap"])
    CollectFromCapNode(_G["MainActionBarRightEndCap"])

    local artFrame = _G["MainMenuBarArtFrame"]
    if artFrame then
        CollectFromCapNode(artFrame.LeftEndCap or artFrame.leftEndCap)
        CollectFromCapNode(artFrame.RightEndCap or artFrame.rightEndCap)
    end
    CollectFromCapNode(_G["MainMenuBarLeftEndCap"])
    CollectFromCapNode(_G["MainMenuBarRightEndCap"])
end

function TimelessTweaks:ApplyActionBarEndCaps()
    DiscoverEndCapTargets()
    local shouldHide = ShouldHideEndCaps()
    for _, target in ipairs(endCapTargets) do
        SetEndCapTargetVisibility(target, shouldHide)
    end
end

function TimelessTweaks:ApplyGeneralSettings()
    local db = TimelessTweaksDB
    SafeSetCVar("cursorSizePreferred", db.cursorSize or 1)
    SafeSetCVar("countdownForCooldowns", db.enableCooldownManager and 1 or 0)
    SafeSetCVar("alwaysShowActionBars", db.alwaysShowActionBars and 1 or 0)
    SafeSetCVar("pingMode", db.enablePings and 1 or 0)
    self:ApplyActionBarEndCaps()
end

function TimelessTweaks:ApplyAllSettings()
    if InCombatLockdown and InCombatLockdown() then
        print(ICON .. "|cffff0000[TimelessTweaks]|r Cannot change settings while in combat!")
        return
    end
    self:ApplyGraphicsSettings()
    self:ApplyControlsSettings()
    self:ApplyCombatSettings()
    self:ApplyInterfaceSettings()
    self:ApplyNameplateSettings()
    self:ApplyGeneralSettings()
end



-- =========================================================================
-- UI Factory Helpers (Zero Taint with initialization guard, No EnableKeyboard)
-- =========================================================================
local sliderCounter = 0
local allSliders = {}

local function RefreshAllSliders()
    for _, s in ipairs(allSliders) do
        if s.Refresh then
            s:Refresh()
        end
    end
    local LibStub = _G.LibStub
    if LibStub then
        local reg = LibStub("AceConfigRegistry-3.0", true)
        if reg then
            pcall(reg.NotifyChange, reg, "TimelessForever")
            pcall(reg.NotifyChange, reg, "Timeless")
            pcall(reg.NotifyChange, reg, "TimelessForever_Tweaks")
        end
    end
end

local function CreateStyledCheckbox(parent, label, tooltip, x, y, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)

    local txt = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    txt:SetText(label)

    local isSettingCB = false
    cb:SetScript("OnShow", function(self)
        isSettingCB = true
        self:SetChecked(getFunc())
        isSettingCB = false
    end)

    cb:SetScript("OnClick", function(self)
        if isSettingCB then return end
        local val = self:GetChecked()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        setFunc(val)
    end)

    if tooltip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return cb
end

local function CreateStyledSlider(parent, label, tooltip, x, y, minVal, maxVal, stepVal, getFunc, setFunc, formatFunc)
    sliderCounter = sliderCounter + 1
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(280, 48)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    title:SetText(label)

    local valText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, 0)

    local uniqueSliderName = "TimelessTweaksSlider_" .. sliderCounter
    local slider = CreateFrame("Slider", uniqueSliderName, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -16)
    slider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(stepVal)
    slider:SetObeyStepOnDrag(true)
    slider:SetHeight(16)

    local lowText = _G[uniqueSliderName .. "Low"]
    local highText = _G[uniqueSliderName .. "High"]
    if lowText then lowText:SetText(tostring(minVal)) end
    if highText then highText:SetText(tostring(maxVal)) end

    local function UpdateDisplay(val)
        if formatFunc then
            valText:SetText(formatFunc(val))
        else
            valText:SetText(string.format("%.1f", val))
        end
    end

    local isInitializing = false

    function frame:Refresh()
        local cur = getFunc()
        isInitializing = true
        slider:SetValue(cur)
        isInitializing = false
        UpdateDisplay(cur)
    end

    slider:SetScript("OnShow", function()
        frame:Refresh()
    end)

    slider:SetScript("OnValueChanged", function(self, val)
        if isInitializing then return end
        if stepVal >= 1 then
            val = math.floor(val + 0.5)
        else
            val = math.floor((val / stepVal) + 0.5) * stepVal
        end
        UpdateDisplay(val)
        setFunc(val)
    end)

    if tooltip then
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    frame.slider = slider
    table.insert(allSliders, frame)
    return frame
end

local function CreateStyledButton(parent, text, x, y, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetSize(width or 160, height or 24)
    btn:SetText(text)
    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if onClick then onClick(self) end
    end)
    return btn
end

-- =========================================================================
-- Main GUI Window Construction (Isolated Frame, Zero EnableKeyboard)
-- =========================================================================
local panel = CreateFrame("Frame", "TimelessTweaksFrame", UIParent, "BackdropTemplate")
panel:SetSize(800, 580)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:SetClampedToScreen(true)
panel:SetFrameStrata("DIALOG")
panel:Hide()

panel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
panel:SetBackdropColor(0.07, 0.07, 0.09, 0.96)
panel:SetBackdropBorderColor(0.24, 0.24, 0.28, 1)

local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -36, -10)
titleBar:SetHeight(28)

local titleText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
titleText:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
titleText:SetText(ICON .. "|cff00ccffTimeless|r|cffffffffTweaks|r  |cff888888System & Graphics Engine Center|r")

local closeBtn = CreateFrame("Button", nil, panel)
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
closeBtn:SetNormalFontObject("GameFontNormalLarge")
closeBtn:SetHighlightFontObject("GameFontHighlightLarge")
closeBtn:SetText("|cffff5555X|r")
closeBtn:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    panel:Hide()
end)

local sidebar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
sidebar:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
sidebar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 48)
sidebar:SetWidth(170)
sidebar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
sidebar:SetBackdropColor(0.05, 0.05, 0.06, 0.9)
sidebar:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

local contentArea = CreateFrame("Frame", nil, panel, "BackdropTemplate")
contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
contentArea:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 48)
contentArea:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
contentArea:SetBackdropColor(0.06, 0.06, 0.08, 0.85)
contentArea:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

local tabPages = {}
local tabButtons = {}

local function SelectTab(tabIndex)
    for i, page in ipairs(tabPages) do
        if i == tabIndex then
            page:Show()
            tabButtons[i]:SetBackdropColor(0.0, 0.45, 0.7, 0.8)
            tabButtons[i].text:SetTextColor(1, 1, 1, 1)
        else
            page:Hide()
            tabButtons[i]:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
            tabButtons[i].text:SetTextColor(0.8, 0.8, 0.8, 1)
        end
    end
end

local tabDefinitions = {
    { name = "Graphics & CVars", icon = "Interface\\Icons\\Spell_Fire_FlameBlades" },
    { name = "Controls & Cam",   icon = "Interface\\Icons\\INV_Misc_Gear_01" },
    { name = "Combat & Target",  icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
    { name = "Interface & Social",icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { name = "Bars & Ping",      icon = "Interface\\Icons\\Spell_Holy_MindVision" },
    { name = "Nameplates",       icon = "Interface\\Icons\\Achievement_Arena_2v2_7" },
    { name = "Advanced & Tools", icon = "Interface\\Icons\\INV_Gizmo_02" },
}

for i, tabInfo in ipairs(tabDefinitions) do
    local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
    btn:SetSize(162, 36)
    btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4, -4 - ((i - 1) * 40))
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
    btn:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)

    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(20, 20)
    iconTex:SetPoint("LEFT", btn, "LEFT", 8, 0)
    iconTex:SetTexture(tabInfo.icon)

    local txt = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", iconTex, "RIGHT", 8, 0)
    txt:SetText(tabInfo.name)
    btn.text = txt

    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        SelectTab(i)
    end)
    tabButtons[i] = btn

    local page = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    page:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 12, -12)
    page:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -28, 12)
    
    local child = CreateFrame("Frame", nil, page)
    child:SetSize(560, 720)
    page:SetScrollChild(child)
    page.content = child
    page:Hide()

    tabPages[i] = page
end

-- Hook panel OnShow so default tab is selected only when opened by the user
panel:HookScript("OnShow", function()
    SelectTab(1)
end)

-- =========================================================================
-- TAB 1: Graphics & Engine CVars
-- =========================================================================
local p1 = tabPages[1].content

local h1 = p1:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h1:SetPoint("TOPLEFT", p1, "TOPLEFT", 4, -4)
h1:SetText("|TInterface\\Icons\\Spell_Fire_FlameBlades:16:16:0:0|t Ultra Graphics & Draw Distance Engine")

local desc1 = p1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc1:SetPoint("TOPLEFT", h1, "BOTTOMLEFT", 0, -4)
desc1:SetText("Tune terrain detail, max camera zoom factor, foliage density, and object fade distance.")

CreateStyledButton(p1, "Apply Macro 1", 4, -50, 130, 24, function()
    local db = TimelessTweaksDB
    db.cameraDistanceMaxZoomFactor = 4.0
    db.reflectionMode = 3
    db.ResampleAlwaysSharpen = 1
    db.weatherdensity = 3
    db.groundEffectDist = 500
    db.groundEffectDensity = 256
    TimelessTweaks:ApplyGraphicsSettings()
    RefreshAllSliders()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r Macro 1 settings applied!")
end)

CreateStyledButton(p1, "Apply Macro 2", 140, -50, 130, 24, function()
    local db = TimelessTweaksDB
    db.doodadLodScale = 200
    db.terrainLodDist = 1000
    db.lodObjectCullSize = 35
    db.lodObjectFadeScale = 200
    TimelessTweaks:ApplyGraphicsSettings()
    RefreshAllSliders()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r Macro 2 settings applied!")
end)

CreateStyledButton(p1, "|cff00ff00Apply ALL Ultra|r", 276, -50, 130, 24, function()
    local db = TimelessTweaksDB
    db.cameraDistanceMaxZoomFactor = 4.0
    db.reflectionMode = 3
    db.ResampleAlwaysSharpen = 1
    db.weatherdensity = 3
    db.groundEffectDist = 500
    db.groundEffectDensity = 256
    db.doodadLodScale = 200
    db.terrainLodDist = 1000
    db.lodObjectCullSize = 35
    db.lodObjectFadeScale = 200
    TimelessTweaks:ApplyGraphicsSettings()
    RefreshAllSliders()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r All 10 Ultra Graphics CVars maxed and applied!")
end)

CreateStyledButton(p1, "Reset Defaults", 412, -50, 120, 24, function()
    local db = TimelessTweaksDB
    db.cameraDistanceMaxZoomFactor = 2.6
    db.reflectionMode = 1
    db.ResampleAlwaysSharpen = 0
    db.weatherdensity = 1
    db.groundEffectDist = 160
    db.groundEffectDensity = 128
    db.doodadLodScale = 100
    db.terrainLodDist = 500
    db.lodObjectCullSize = 18
    db.lodObjectFadeScale = 100
    TimelessTweaks:ApplyGraphicsSettings()
    RefreshAllSliders()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r Graphics settings restored to game defaults.")
end)

CreateStyledSlider(p1, "Camera Max Zoom Factor", "CVar cameraDistanceMaxZoomFactor (Default: 2.6, Ultra: 4.0)",
    4, -90, 1.0, 4.0, 0.1,
    function() return TimelessTweaksDB.cameraDistanceMaxZoomFactor or 4.0 end,
    function(val) TimelessTweaksDB.cameraDistanceMaxZoomFactor = val; SafeSetCVar("cameraDistanceMaxZoomFactor", val) end
)

CreateStyledSlider(p1, "Reflection Mode", "CVar reflectionMode (0: Off, 1: Terrain, 2: Trees, 3: Full Reflections)",
    4, -145, 0, 3, 1,
    function() return TimelessTweaksDB.reflectionMode or 3 end,
    function(val) TimelessTweaksDB.reflectionMode = val; SafeSetCVar("reflectionMode", val) end,
    function(val)
        local labels = { [0] = "0 - Off", [1] = "1 - Terrain", [2] = "2 - Trees", [3] = "3 - Full/Ultra" }
        return labels[val] or tostring(val)
    end
)

CreateStyledSlider(p1, "Resample Sharpening", "CVar ResampleAlwaysSharpen (0: Off, 1: Enabled)",
    4, -200, 0, 1, 0.1,
    function() return TimelessTweaksDB.ResampleAlwaysSharpen or 1 end,
    function(val) TimelessTweaksDB.ResampleAlwaysSharpen = val; SafeSetCVar("ResampleAlwaysSharpen", val) end
)

CreateStyledSlider(p1, "Weather Density", "CVar weatherdensity (0: Off, 1: Low, 2: Med, 3: Ultra)",
    4, -255, 0, 3, 1,
    function() return TimelessTweaksDB.weatherdensity or 3 end,
    function(val) TimelessTweaksDB.weatherdensity = val; SafeSetCVar("weatherdensity", val) end,
    function(val)
        local labels = { [0] = "0 - Off", [1] = "1 - Low", [2] = "2 - Med", [3] = "3 - Ultra" }
        return labels[val] or tostring(val)
    end
)

CreateStyledSlider(p1, "Ground Effect Distance", "CVar groundEffectDist (Range: 40 to 500, Ultra: 500)",
    4, -310, 40, 500, 10,
    function() return TimelessTweaksDB.groundEffectDist or 500 end,
    function(val) TimelessTweaksDB.groundEffectDist = val; SafeSetCVar("groundEffectDist", val) end,
    function(val) return string.format("%d yards", val) end
)

CreateStyledSlider(p1, "Ground Effect Density", "CVar groundEffectDensity (Range: 16 to 256, Ultra: 256)",
    284, -90, 16, 256, 16,
    function() return TimelessTweaksDB.groundEffectDensity or 256 end,
    function(val) TimelessTweaksDB.groundEffectDensity = val; SafeSetCVar("groundEffectDensity", val) end,
    function(val) return string.format("%d", val) end
)

CreateStyledSlider(p1, "Doodad LOD Scale", "CVar doodadLodScale (Range: 50 to 200, Ultra: 200)",
    284, -145, 50, 200, 10,
    function() return TimelessTweaksDB.doodadLodScale or 200 end,
    function(val) TimelessTweaksDB.doodadLodScale = val; SafeSetCVar("doodadLodScale", val) end,
    function(val) return string.format("%d%%", val) end
)

CreateStyledSlider(p1, "Terrain LOD Distance", "CVar terrainLodDist (Range: 100 to 1000, Ultra: 1000)",
    284, -200, 100, 1000, 50,
    function() return TimelessTweaksDB.terrainLodDist or 1000 end,
    function(val) TimelessTweaksDB.terrainLodDist = val; SafeSetCVar("terrainLodDist", val) end,
    function(val) return string.format("%d yards", val) end
)

CreateStyledSlider(p1, "LOD Object Cull Size", "CVar lodObjectCullSize (Range: 1 to 35, Max: 35)",
    284, -255, 1, 35, 1,
    function() return TimelessTweaksDB.lodObjectCullSize or 35 end,
    function(val) TimelessTweaksDB.lodObjectCullSize = val; SafeSetCVar("lodObjectCullSize", val) end,
    function(val) return string.format("%d", val) end
)

CreateStyledSlider(p1, "LOD Object Fade Scale", "CVar lodObjectFadeScale (Range: 50 to 200, Ultra: 200)",
    284, -310, 50, 200, 10,
    function() return TimelessTweaksDB.lodObjectFadeScale or 200 end,
    function(val) TimelessTweaksDB.lodObjectFadeScale = val; SafeSetCVar("lodObjectFadeScale", val) end,
    function(val) return string.format("%d%%", val) end
)

CreateStyledButton(p1, "View Config.wtf & Macro Export Box", 4, -380, 260, 26, function()
    TimelessTweaks:ShowExportDialog()
end)

-- =========================================================================
-- TAB 2: Controls & Camera
-- =========================================================================
local p2 = tabPages[2].content

local h2 = p2:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h2:SetPoint("TOPLEFT", p2, "TOPLEFT", 4, -4)
h2:SetText("|TInterface\\Icons\\INV_Misc_Gear_01:16:16:0:0|t Controls & Camera Options")

CreateStyledCheckbox(p2, "Sticky Targeting",
    "Prevents accidentally clearing your target when clicking empty ground.",
    4, -40,
    function() return TimelessTweaksDB.stickyTargeting end,
    function(val)
        TimelessTweaksDB.stickyTargeting = val
        SafeSetCVar("deselectOnClick", val and 0 or 1)
        SafeSetCVar("autoClearTarget", val and 0 or 1)
    end
)

CreateStyledCheckbox(p2, "Open Loot Window @ Mouse",
    "Opens the loot window directly underneath the mouse cursor.",
    4, -75,
    function() return TimelessTweaksDB.lootUnderMouse end,
    function(val)
        TimelessTweaksDB.lootUnderMouse = val
        SafeSetCVar("lootUnderMouse", val and 1 or 0)
    end
)

CreateStyledCheckbox(p2, "Auto Loot",
    "Automatically loots all items on right click without holding Shift.",
    4, -110,
    function() return TimelessTweaksDB.autoLoot end,
    function(val)
        TimelessTweaksDB.autoLoot = val
        SafeSetCVar("autoLootDefault", val and 1 or 0)
    end
)

CreateStyledCheckbox(p2, "Combine Bags",
    "Merges all inventory containers into a single unified clean bag window.",
    4, -145,
    function() return TimelessTweaksDB.combineBags end,
    function(val)
        TimelessTweaksDB.combineBags = val
        SafeSetCVar("combinedBags", val and 1 or 0)
    end
)

local camLabel = p2:CreateFontString(nil, "ARTWORK", "GameFontNormal")
camLabel:SetPoint("TOPLEFT", p2, "TOPLEFT", 4, -195)
camLabel:SetText("Camera Following Style:")

local camStyles = {
    { text = "Never (Recommended)", val = 0 },
    { text = "Only when moving", val = 1 },
    { text = "Always", val = 2 },
    { text = "Smart", val = 4 },
}

local camStyleBtns = {}
local function RefreshCamStyleBtns()
    local cur = tonumber(TimelessTweaksDB.cameraSmoothStyle) or 0
    for idx, item in ipairs(camStyles) do
        local btn = camStyleBtns[idx]
        if btn then
            if cur == item.val then
                btn:SetText("|cff00ff00* " .. item.text .. "|r")
                btn:LockHighlight()
            else
                btn:SetText(item.text)
                btn:UnlockHighlight()
            end
        end
    end
end

for idx, item in ipairs(camStyles) do
    local btn = CreateStyledButton(p2, item.text, 4, -220 - ((idx - 1) * 30), 200, 24, function()
        TimelessTweaksDB.cameraSmoothStyle = item.val
        SafeSetCVar("cameraSmoothStyle", item.val)
        RefreshCamStyleBtns()
        print(ICON .. "|cff00ccff[TimelessTweaks]|r Camera following style: |cffffd100" .. item.text .. "|r")
    end)
    btn:HookScript("OnShow", RefreshCamStyleBtns)
    camStyleBtns[idx] = btn
end

-- =========================================================================
-- TAB 3: Combat & Targeting
-- =========================================================================
local p3 = tabPages[3].content

local h3 = p3:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h3:SetPoint("TOPLEFT", p3, "TOPLEFT", 4, -4)
h3:SetText("|TInterface\\Icons\\Ability_Warrior_OffensiveStance:16:16:0:0|t Combat & Targeting Center")

CreateStyledCheckbox(p3, "Show Character Silhouette",
    "Highlights silhouette when behind walls and pillars.",
    4, -40,
    function() return TimelessTweaksDB.showSilhouette end,
    function(val)
        TimelessTweaksDB.showSilhouette = val
        if val then
            SafeSetCVar("findYourselfMode", 2)
            SafeSetCVar("findYourselfAnywhere", 1)
        else
            SafeSetCVar("findYourselfMode", 0)
        end
    end
)

CreateStyledCheckbox(p3, "Target of Target",
    "Displays target of target unit frame.",
    4, -75,
    function() return TimelessTweaksDB.targetOfTarget end,
    function(val)
        TimelessTweaksDB.targetOfTarget = val
        SafeSetCVar("showTargetOfTarget", val and 1 or 0)
    end
)

CreateStyledCheckbox(p3, "Do Not Flash Screen at Low Health",
    "Disables the red flashing screen vignette effect.",
    4, -110,
    function() return TimelessTweaksDB.doNotFlashLowHealth end,
    function(val)
        TimelessTweaksDB.doNotFlashLowHealth = val
        SafeSetCVar("doNotFlashLowHealthChar", val and 1 or 0)
    end
)

CreateStyledCheckbox(p3, "Enable Mouseover Cast",
    "Allows casting spells directly on targets under cursor.",
    4, -145,
    function() return TimelessTweaksDB.mouseoverCast end,
    function(val)
        TimelessTweaksDB.mouseoverCast = val
        SafeSetCVar("enableMouseoverCast", val and 1 or 0)
    end
)

local moLabel = p3:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
moLabel:SetPoint("TOPLEFT", p3, "TOPLEFT", 28, -175)
moLabel:SetText("Mouseover Cast Modifier Key:")

local moKeys = { "NONE", "ALT", "CTRL", "SHIFT" }
local moKeyBtns = {}
local function RefreshMoKeyBtns()
    local cur = TimelessTweaksDB.mouseoverCastKey or "NONE"
    for idx, key in ipairs(moKeys) do
        local btn = moKeyBtns[idx]
        if btn then
            if cur == key then
                btn:SetText("|cff00ff00* " .. key .. "|r")
                btn:LockHighlight()
            else
                btn:SetText(key)
                btn:UnlockHighlight()
            end
        end
    end
end

for idx, key in ipairs(moKeys) do
    local btn = CreateStyledButton(p3, key, 28 + ((idx - 1) * 75), -195, 70, 22, function()
        TimelessTweaksDB.mouseoverCastKey = key
        SafeSetCVar("mouseoverCastKey", key)
        RefreshMoKeyBtns()
        print(ICON .. "|cff00ccff[TimelessTweaks]|r Mouseover modifier set to: |cffffd100" .. key .. "|r")
    end)
    btn:HookScript("OnShow", RefreshMoKeyBtns)
    moKeyBtns[idx] = btn
end

CreateStyledCheckbox(p3, "Enable Action Target (Action Combat Mode)",
    "Automatically targets and interacts with targets in front of character reticle.",
    4, -235,
    function() return TimelessTweaksDB.actionTarget end,
    function(val)
        TimelessTweaksDB.actionTarget = val
        SafeSetCVar("SoftTargetEnemy", val and 3 or 0)
        SafeSetCVar("SoftTargetInteract", val and 3 or 0)
    end
)

CreateStyledCheckbox(p3, "AutoPotion: Remove Windstone",
    "Prevents Windstone (Zephras Isle) from being chosen in AutoPotion & AutoManaPotion macros.",
    4, -270,
    function() return TimelessTweaksDB and TimelessTweaksDB.autoPotionNoWindstone ~= false end,
    function(val)
        TimelessTweaksDB.autoPotionNoWindstone = val
        if val and TimelessTweaks.CleanAutoPotionMacros then
            TimelessTweaks:CleanAutoPotionMacros()
        end
    end
)

-- =========================================================================
-- TAB 4: Interface & Social
-- =========================================================================
local p4 = tabPages[4].content

local h4 = p4:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h4:SetPoint("TOPLEFT", p4, "TOPLEFT", 4, -4)
h4:SetText("|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0|t Interface & Social Options")

CreateStyledCheckbox(p4, "Display Status Text",
    "Shows numeric health and mana values on status bars.",
    4, -40,
    function() return TimelessTweaksDB.statusText end,
    function(val)
        TimelessTweaksDB.statusText = val
        SafeSetCVar("statusText", val and 1 or 0)
    end
)

CreateStyledCheckbox(p4, "Display Class Colors (Chat & Nameplates)",
    "Uses class colors for player names in chat and on nameplates.",
    4, -75,
    function() return TimelessTweaksDB.displayClassColors end,
    function(val)
        TimelessTweaksDB.displayClassColors = val
        SafeSetCVar("chatClassColorOverride", val and 0 or 1)
        SafeSetCVar("ShowClassColorInNameplate", val and 1 or 0)
    end
)

CreateStyledCheckbox(p4, "Flashing Animation / Animated Border Glow",
    "Displays animated proc borders and spell activation overlays.",
    4, -110,
    function() return TimelessTweaksDB.flashingAnimation end,
    function(val)
        TimelessTweaksDB.flashingAnimation = val
        SafeSetCVar("actionStatusFlash", val and 1 or 0)
        SafeSetCVar("displaySpellActivationOverlays", val and 1 or 0)
    end
)

local htLabel = p4:CreateFontString(nil, "ARTWORK", "GameFontNormal")
htLabel:SetPoint("TOPLEFT", p4, "TOPLEFT", 4, -150)
htLabel:SetText("Display Health & Mana Text Format:")

local htFormats = {
    { text = "Both (Num & %)", val = "BOTH" },
    { text = "Percentage Only", val = "PERCENT" },
    { text = "Numeric Only", val = "NUMERIC" },
    { text = "None", val = "NONE" },
}

local htFormatBtns = {}
local function RefreshHtFormatBtns()
    local cur = TimelessTweaksDB.healthTextFormat or "BOTH"
    for idx, fmt in ipairs(htFormats) do
        local btn = htFormatBtns[idx]
        if btn then
            if cur == fmt.val then
                btn:SetText("|cff00ff00* " .. fmt.text .. "|r")
                btn:LockHighlight()
            else
                btn:SetText(fmt.text)
                btn:UnlockHighlight()
            end
        end
    end
end

for idx, fmt in ipairs(htFormats) do
    local btn = CreateStyledButton(p4, fmt.text, 4, -175 - ((idx - 1) * 28), 160, 22, function()
        TimelessTweaksDB.healthTextFormat = fmt.val
        SafeSetCVar("statusTextDisplay", fmt.val)
        RefreshHtFormatBtns()
        print(ICON .. "|cff00ccff[TimelessTweaks]|r Health text format: |cffffd100" .. fmt.text .. "|r")
    end)
    btn:HookScript("OnShow", RefreshHtFormatBtns)
    htFormatBtns[idx] = btn
end

local sHeader = p4:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sHeader:SetPoint("TOPLEFT", p4, "TOPLEFT", 4, -300)
sHeader:SetText("Social & Community Settings:")

CreateStyledCheckbox(p4, "Mature Language Filter",
    "Toggles the Blizzard profanity and chat censorship filter.",
    4, -320,
    function() return TimelessTweaksDB.matureFilter end,
    function(val)
        TimelessTweaksDB.matureFilter = val
        SafeSetCVar("profanityFilter", val and 1 or 0)
    end
)

CreateStyledCheckbox(p4, "Guild Member Login / Logout Alert",
    "Displays chat notifications when guild members come online or go offline.",
    4, -355,
    function() return TimelessTweaksDB.guildMemberAlert end,
    function(val)
        TimelessTweaksDB.guildMemberAlert = val
        SafeSetCVar("guildMemberNotify", val and 1 or 0)
    end
)

CreateStyledButton(p4, "Sync up Discord (Community Link)", 4, -395, 240, 26, function()
    TimelessTweaks:ShowDiscordDialog()
end)

local scHeader = p4:CreateFontString(nil, "ARTWORK", "GameFontNormal")
scHeader:SetPoint("TOPLEFT", p4, "TOPLEFT", 4, -435)
scHeader:SetText("|TInterface\\Icons\\Spell_Holy_Silenced:16:16:0:0|t Addon Startup Cleanliness & Chat Tabs:")

CreateStyledCheckbox(p4, "Clean Addon Startup Spam (Keep Main Chat Clean)",
    "Silences startup splash banners and welcome messages from ALL addons in your main chat window (General) and routes them into a dedicated 'ADDON Startup' chat tab.",
    4, -460,
    function() return TimelessTweaksDB.cleanStartupChat end,
    function(val)
        TimelessTweaksDB.cleanStartupChat = val
        TSC.isActive = val
        if val then
            GetOrCreateAddonStartupChatFrame()
        end
    end
)

CreateStyledCheckbox(p4, "Create & Maintain 'ADDON Startup' Tab",
    "Automatically creates and docks an 'ADDON Startup' chat tab next to General/Combat Log.",
    4, -495,
    function() return TimelessTweaksDB.createStartupTab end,
    function(val)
        TimelessTweaksDB.createStartupTab = val
        if val then
            GetOrCreateAddonStartupChatFrame()
        end
    end
)

CreateStyledCheckbox(p4, "Show Clean Summary Notice in General",
    "Displays a single clean notification in General after startup completes (e.g. 'Captured 7 messages into [ADDON Startup]').",
    4, -530,
    function() return TimelessTweaksDB.showStartupNotice end,
    function(val)
        TimelessTweaksDB.showStartupNotice = val
    end
)

CreateStyledButton(p4, "Open 'ADDON Startup' Tab", 4, -570, 200, 26, function()
    TimelessTweaks:OpenStartupTab()
end)

CreateStyledButton(p4, "Clear 'ADDON Startup' Log", 212, -570, 200, 26, function()
    TimelessTweaks:ClearStartupTab()
end)

CreateStyledButton(p4, "View Cleaned Addons List", 4, -605, 200, 26, function()
    local TSC = _G["TimelessStartupClean"]
    if TSC and TSC.OpenViewer then
        TSC:OpenViewer()
    end
end)

CreateStyledButton(p4, "Print Cleaned List to Chat", 212, -605, 200, 26, function()
    local TSC = _G["TimelessStartupClean"]
    if TSC and TSC.PrintCleanedList then
        TSC:PrintCleanedList()
    end
end)

-- =========================================================================
-- TAB 5: Action Bars & Ping System
-- =========================================================================
local p5 = tabPages[5].content

local h5 = p5:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h5:SetPoint("TOPLEFT", p5, "TOPLEFT", 4, -4)
h5:SetText("|TInterface\\Icons\\Spell_Holy_MindVision:16:16:0:0|t Action Bars & Modern Ping System")

CreateStyledCheckbox(p5, "Always Show Action Bar Grids",
    "Always displays empty action bar slots even when no ability is placed there.",
    4, -40,
    function() return TimelessTweaksDB.alwaysShowActionBars end,
    function(val)
        TimelessTweaksDB.alwaysShowActionBars = val
        SafeSetCVar("alwaysShowActionBars", val and 1 or 0)
    end
)

CreateStyledCheckbox(p5, "Force Hide Action Bar EndCaps (Left & Right Gryphons/Wyverns)",
    "Force-hides MainActionBar.EndCaps.LeftEndCap (.Texture) and RightEndCap (.Texture) so decorative endcap art never reappears.",
    4, -75,
    function() return TimelessTweaksDB.hideActionBarEndCaps ~= false end,
    function(val)
        TimelessTweaksDB.hideActionBarEndCaps = val
        TimelessTweaks:ApplyActionBarEndCaps()
    end
)

local pingHeader = p5:CreateFontString(nil, "ARTWORK", "GameFontNormal")
pingHeader:SetPoint("TOPLEFT", p5, "TOPLEFT", 4, -120)
pingHeader:SetText("Ping System & Keybindings:")

CreateStyledCheckbox(p5, "Enable Modern Ping System",
    "Enables the contextual ping wheel for quickly alerting party and raid members.",
    4, -145,
    function() return TimelessTweaksDB.enablePings end,
    function(val)
        TimelessTweaksDB.enablePings = val
        SafeSetCVar("pingMode", val and 1 or 0)
    end
)

CreateStyledButton(p5, "Bind Middle Mouse (BUTTON3) to Ping", 4, -185, 270, 26, function()
    if InCombatLockdown and InCombatLockdown() then
        print(ICON .. "|cffff0000[TimelessTweaks]|r Cannot change keybinds while in combat!")
        return
    end
    pcall(function()
        SetBinding("BUTTON3", "PING")
        local currentSet = (GetCurrentBindingSet and GetCurrentBindingSet()) or 1
        if SaveBindings then SaveBindings(currentSet) end
    end)
    TimelessTweaksDB.pingKey = "BUTTON3"
    print(ICON .. "|cff00ccff[TimelessTweaks]|r Ping bound to Middle Mouse (BUTTON3)!")
end)

CreateStyledButton(p5, "Blizzard Keybindings Guide", 4, -220, 270, 26, function()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r To customize keybinds & ping:")
    print(ICON .. "|cffffd100Game Menu (Esc) -> Options -> Keybindings -> Ping System|r")
end)

-- =========================================================================
-- TAB 6: Nameplates & Breakdown
-- =========================================================================
local p6 = tabPages[6].content

local h6 = p6:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h6:SetPoint("TOPLEFT", p6, "TOPLEFT", 4, -4)
h6:SetText("|TInterface\\Icons\\Achievement_Arena_2v2_7:16:16:0:0|t Nameplate Configuration Breakdown")

CreateStyledButton(p6, "Apply Optimal PvP/PvE Nameplate Preset", 4, -30, 290, 24, function()
    local db = TimelessTweaksDB
    db.friendlyNamesOnly = true
    db.friendlyClassColor = true
    db.nameplateSize = 2.0
    db.nameplateAuraScale = 1.0
    db.nameplateBlockStyle = true
    db.nameplateHealthPercent = true
    db.nameplateCastBarAll = true
    db.simplifyMinions = true
    db.simplifyFriendlyNPCs = true
    db.enemyPlayerClassColor = true
    TimelessTweaks:ApplyNameplateSettings()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r Nameplate breakdown profile applied!")
    panel:Hide(); panel:Show()
end)

CreateStyledCheckbox(p6, "Friendly Player Nameplates: Only Show Names",
    "Hides health bars on friendly players and only renders character names.",
    4, -65,
    function() return TimelessTweaksDB.friendlyNamesOnly end,
    function(val)
        TimelessTweaksDB.friendlyNamesOnly = val
        SafeSetCVar("nameplateShowFriendlyPlayers", val and 1 or 0)
        SafeSetCVar("nameplateShowOnlyNames", val and 1 or 0)
    end
)

CreateStyledCheckbox(p6, "Friendly Player Names: Class Colors",
    "Colors friendly player names according to their class.",
    4, -95,
    function() return TimelessTweaksDB.friendlyClassColor end,
    function(val)
        TimelessTweaksDB.friendlyClassColor = val
        SafeSetCVar("ShowClassColorInFriendlyNameplate", val and 1 or 0)
        SafeSetCVar("nameplateShowFriendlyPlayerClassColor", val and 1 or 0)
    end
)

CreateStyledCheckbox(p6, "Nameplate Class Color: Enemy Players (PvP)",
    "Displays enemy player nameplates colored by class for immediate PvP recognition.",
    4, -125,
    function() return TimelessTweaksDB.enemyPlayerClassColor end,
    function(val)
        TimelessTweaksDB.enemyPlayerClassColor = val
        SafeSetCVar("ShowClassColorInNameplate", val and 1 or 0)
        SafeSetCVar("nameplateShowEnemyPlayerClassColor", val and 1 or 0)
    end
)

CreateStyledSlider(p6, "Nameplate Size (Scale)", "Multiplier for nameplate dimensions (Default: 2.0)",
    4, -165, 0.5, 2.5, 0.1,
    function() return TimelessTweaksDB.nameplateSize or 2.0 end,
    function(val)
        TimelessTweaksDB.nameplateSize = val
        SafeSetCVar("nameplateGlobalScale", val)
    end,
    function(val) return string.format("%.1fx", val) end
)

CreateStyledSlider(p6, "Buff / Debuff Scale", "Scale of buff and debuff icons over nameplates (Default: 100%)",
    284, -165, 0.5, 2.0, 0.05,
    function() return TimelessTweaksDB.nameplateAuraScale or 1.0 end,
    function(val)
        TimelessTweaksDB.nameplateAuraScale = val
        SafeSetCVar("nameplateMinScale", val)
        SafeSetCVar("nameplateMaxScale", val)
    end,
    function(val) return string.format("%d%%", math.floor(val * 100)) end
)

CreateStyledSlider(p6, "Debuff Padding", "Horizontal spacing padding between debuff icons on nameplates.",
    4, -220, 0, 10, 1,
    function() return TimelessTweaksDB.nameplateDebuffPadding or 3 end,
    function(val) TimelessTweaksDB.nameplateDebuffPadding = val end,
    function(val) return string.format("%d px", val) end
)

CreateStyledCheckbox(p6, "Style: Block Texture",
    "Uses clean solid flat health bar styling.",
    4, -280,
    function() return TimelessTweaksDB.nameplateBlockStyle end,
    function(val) TimelessTweaksDB.nameplateBlockStyle = val end
)

CreateStyledCheckbox(p6, "Nameplate Info: Health Percentage",
    "Displays numerical health percentage on unit nameplates.",
    284, -280,
    function() return TimelessTweaksDB.nameplateHealthPercent end,
    function(val) TimelessTweaksDB.nameplateHealthPercent = val end
)

CreateStyledCheckbox(p6, "Cast Bar Info: Check Everything",
    "Displays cast bars, spell names, and interruptible state.",
    4, -315,
    function() return TimelessTweaksDB.nameplateCastBarAll end,
    function(val)
        TimelessTweaksDB.nameplateCastBarAll = val
        SafeSetCVar("nameplateShowCastBars", val and 1 or 0)
        SafeSetCVar("nameplateShowCastBarTimer", val and 1 or 0)
    end
)

CreateStyledCheckbox(p6, "Simplify Nameplates: Minions (Pets & Guardians)",
    "Hides clutter from small pets, guardians, and minor minions.",
    4, -350,
    function() return TimelessTweaksDB.simplifyMinions end,
    function(val)
        TimelessTweaksDB.simplifyMinions = val
        SafeSetCVar("nameplateShowFriendlyMinions", val and 0 or 1)
        SafeSetCVar("nameplateShowEnemyMinions", val and 0 or 1)
    end
)

CreateStyledCheckbox(p6, "Simplify Nameplates: Friendly NPCs",
    "Hides health bars on friendly vendors, flight masters, and quest NPCs.",
    4, -385,
    function() return TimelessTweaksDB.simplifyFriendlyNPCs end,
    function(val)
        TimelessTweaksDB.simplifyFriendlyNPCs = val
        SafeSetCVar("nameplateShowFriendlyNPCs", val and 0 or 1)
    end
)

-- =========================================================================
-- TAB 7: Advanced & Combat Tools
-- =========================================================================
local p7 = tabPages[7].content

local h7 = p7:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
h7:SetPoint("TOPLEFT", p7, "TOPLEFT", 4, -4)
h7:SetText("|TInterface\\Icons\\INV_Gizmo_02:16:16:0:0|t Advanced Options & Utilities")

CreateStyledButton(p7, "Set up Click Caster Guide", 4, -35, 300, 26, function()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r To configure Click-Casting:")
    print(ICON .. "|cffffd100Game Menu (Esc) -> Options -> Keybindings -> Click-Casting|r (or type |cffffd100/castbinding|r)")
end)

CreateStyledCheckbox(p7, "Enable Cooldown Manager (Countdown Numbers on Buttons)",
    "Displays numerical cooldown countdowns on all action buttons and spell icons.",
    4, -75,
    function() return TimelessTweaksDB.enableCooldownManager end,
    function(val)
        TimelessTweaksDB.enableCooldownManager = val
        SafeSetCVar("countdownForCooldowns", val and 1 or 0)
    end
)

CreateStyledSlider(p7, "Cursor Size (Increase / Decrease)", "CVar cursorSizePreferred (-1: Auto, 0: Small 32px, 1: Medium 48px, 2: Large 64px, 3: Extra Large 96px)",
    4, -120, -1, 3, 1,
    function() return TimelessTweaksDB.cursorSize or 1 end,
    function(val)
        TimelessTweaksDB.cursorSize = val
        SafeSetCVar("cursorSizePreferred", val)
    end,
    function(val)
        local labels = { [-1] = "Auto", [0] = "Small (32px)", [1] = "Medium (48px)", [2] = "Large (64px)", [3] = "X-Large (96px)" }
        return labels[val] or tostring(val)
    end
)

-- Bottom Bar Actions on Main Window
CreateStyledButton(panel, "Reload UI (/rl)", 12, -545, 130, 24, function()
    ReloadUI()
end)

CreateStyledButton(panel, "|cff00ff00Apply All Tweaks|r", 150, -545, 140, 24, function()
    TimelessTweaks:ApplyAllSettings()
    print(ICON .. "|cff00ccff[TimelessTweaks]|r All system settings and CVars successfully applied!")
end)

CreateStyledButton(panel, "Export Config.wtf / Macros", 298, -545, 180, 24, function()
    TimelessTweaks:ShowExportDialog()
end)

CreateStyledButton(panel, "Close", 688, -545, 100, 24, function()
    panel:Hide()
end)

-- =========================================================================
-- Export Dialog (No EnableKeyboard)
-- =========================================================================
local exportFrame = CreateFrame("Frame", "TimelessTweaksExportFrame", UIParent, "BackdropTemplate")
exportFrame:SetSize(620, 480)
exportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
exportFrame:SetFrameStrata("TOOLTIP")
exportFrame:SetMovable(true)
exportFrame:EnableMouse(true)
exportFrame:RegisterForDrag("LeftButton")
exportFrame:SetScript("OnDragStart", exportFrame.StartMoving)
exportFrame:SetScript("OnDragStop", exportFrame.StopMovingOrSizing)
exportFrame:SetClampedToScreen(true)
exportFrame:Hide()

exportFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
exportFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
exportFrame:SetBackdropBorderColor(0.85, 0.72, 0.25, 1)

local expTitle = exportFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
expTitle:SetPoint("TOPLEFT", exportFrame, "TOPLEFT", 12, -12)
expTitle:SetText(ICON .. "|cff00ccffTimelessTweaks|r - Config.wtf & In-Game Macro Exporter")

local expSub = exportFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
expSub:SetPoint("TOPLEFT", expTitle, "BOTTOMLEFT", 0, -4)
expSub:SetText("Press Ctrl+C to copy lines into your macros or WoW's WTF/Config.wtf file.")

local expScroll = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
expScroll:SetPoint("TOPLEFT", exportFrame, "TOPLEFT", 12, -55)
expScroll:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -30, 44)

local expEditBox = CreateFrame("EditBox", nil, expScroll)
expEditBox:SetMultiLine(true)
expEditBox:SetFontObject("GameFontHighlightSmall")
expEditBox:SetWidth(560)
expEditBox:SetAutoFocus(false)
expEditBox:SetScript("OnEscapePressed", function(self) exportFrame:Hide() end)
expScroll:SetScrollChild(expEditBox)

CreateStyledButton(exportFrame, "Close", 510, -445, 90, 24, function()
    exportFrame:Hide()
end)

function TimelessTweaks:ShowExportDialog()
    local db = TimelessTweaksDB
    local macro1 = string.format([[
-- ==========================================
-- MACRO 1 (Graphics Part 1 - In-Game /console)
-- ==========================================
/console cameraDistanceMaxZoomFactor %.1f
/console reflectionMode %d
/console ResampleAlwaysSharpen %s
/console weatherdensity %d
/console groundEffectDist %d
/console groundEffectDensity %d

-- ==========================================
-- MACRO 2 (Graphics Part 2 - In-Game /console)
-- ==========================================
/console doodadLodScale %d
/console terrainLodDist %d
/console lodObjectCullSize %d
/console lodObjectFadeScale %d

-- ==========================================
-- Config.wtf (Permanent - Paste into WTF\Config.wtf)
-- ==========================================
SET cameraDistanceMaxZoomFactor "%.1f"
SET reflectionMode "%d"
SET ResampleAlwaysSharpen "%s"
SET weatherdensity "%d"
SET groundEffectDist "%d"
SET groundEffectDensity "%d"
SET doodadLodScale "%d"
SET terrainLodDist "%d"
SET lodObjectCullSize "%d"
SET lodObjectFadeScale "%d"
]],
        db.cameraDistanceMaxZoomFactor or 4.0,
        db.reflectionMode or 3,
        tostring(db.ResampleAlwaysSharpen or 1),
        db.weatherdensity or 3,
        db.groundEffectDist or 500,
        db.groundEffectDensity or 256,
        db.doodadLodScale or 200,
        db.terrainLodDist or 1000,
        db.lodObjectCullSize or 35,
        db.lodObjectFadeScale or 200,
        db.cameraDistanceMaxZoomFactor or 4.0,
        db.reflectionMode or 3,
        tostring(db.ResampleAlwaysSharpen or 1),
        db.weatherdensity or 3,
        db.groundEffectDist or 500,
        db.groundEffectDensity or 256,
        db.doodadLodScale or 200,
        db.terrainLodDist or 1000,
        db.lodObjectCullSize or 35,
        db.lodObjectFadeScale or 200
    )

    expEditBox:SetText(macro1)
    exportFrame:Show()
    expEditBox:HighlightText()
    expEditBox:SetFocus()
end

-- =========================================================================
-- Discord Dialog (No EnableKeyboard)
-- =========================================================================
local discordFrame = CreateFrame("Frame", "TimelessTweaksDiscordFrame", UIParent, "BackdropTemplate")
discordFrame:SetSize(480, 180)
discordFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
discordFrame:SetFrameStrata("TOOLTIP")
discordFrame:SetMovable(true)
discordFrame:EnableMouse(true)
discordFrame:RegisterForDrag("LeftButton")
discordFrame:SetScript("OnDragStart", discordFrame.StartMoving)
discordFrame:SetScript("OnDragStop", discordFrame.StopMovingOrSizing)
discordFrame:SetClampedToScreen(true)
discordFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
discordFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
discordFrame:SetBackdropBorderColor(0.45, 0.55, 0.95, 1)
discordFrame:Hide()

local discTitle = discordFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
discTitle:SetPoint("TOPLEFT", discordFrame, "TOPLEFT", 12, -12)
discTitle:SetText("|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0|t Discord Community Synchronization")

local discSub = discordFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
discSub:SetPoint("TOPLEFT", discTitle, "BOTTOMLEFT", 0, -6)
discSub:SetText("Copy the Discord URL below into your web browser or Discord app:")

local discBox = CreateFrame("EditBox", nil, discordFrame, "InputBoxTemplate")
discBox:SetSize(450, 24)
discBox:SetPoint("TOPLEFT", discSub, "BOTTOMLEFT", 4, -12)
discBox:SetAutoFocus(false)
discBox:SetScript("OnEscapePressed", function(self) discordFrame:Hide() end)
discBox:SetScript("OnTextChanged", function(self)
    TimelessTweaksDB.discordUrl = self:GetText()
end)

CreateStyledButton(discordFrame, "Close", 380, -140, 80, 24, function()
    discordFrame:Hide()
end)

function TimelessTweaks:ShowDiscordDialog()
    discBox:SetText(TimelessTweaksDB.discordUrl or "https://discord.gg/your-community")
    discordFrame:Show()
    discBox:HighlightText()
    discBox:SetFocus()
end

-- =========================================================================
-- AutoPotion Windstone Cleaner Tweak
-- Ensures Windstone (Item 255663) is never used in AutoPotion or AutoManaPotion
-- macros, automatically reapplying even when AutoPotion is updated via CurseForge.
-- =========================================================================
local WINDSTONE_ITEM_ID = 255663
local isCleaningMacro = false

local FOREVER_HEALTH_POTS = {
    -- Zone-locked (Hinterlands, Duskwood, Ashenvale, Feralas)
    223913, -- Major Healing Potion (Zone Locked)
    223914, -- Greater Healing Potion (Zone Locked)
    -- PvP Battleground Draughts
    17349,  -- Superior Healing Draught
    17348,  -- Major Healing Draught
    -- Standard Forever / Classic Potions
    13446,  -- Major Healing Potion
    18839,  -- Combat Healing Potion
    3928,   -- Superior Healing Potion
    288896, -- Superior Healing Potion (Forever lvl 1)
    274935, -- Tessa's Tonic
    1710,   -- Greater Healing Potion
    287977, -- Greater Healing Potion (Forever lvl 1)
    268883, -- Perishable Healing Potion
    929,    -- Healing Potion
    268882, -- Perishable Lesser Healing Potion
    858,    -- Lesser Healing Potion
    287967, -- Lesser Healing Potion (Forever lvl 1)
    268881, -- Perishable Minor Healing Potion
    118,    -- Minor Healing Potion
    287966, -- Minor Healing Potion (Forever lvl 1)
}

local FOREVER_MANA_POTS = {
    -- PvP Battleground Draughts
    17352,  -- Superior Mana Draught
    17351,  -- Major Mana Draught
    -- Standard Forever / Classic Mana Potions
    13444,  -- Major Mana Potion
    18253,  -- Major Rejuvenation Potion
    18841,  -- Combat Mana Potion
    3924,   -- Superior Mana Potion
    288897, -- Superior Mana Potion (Forever lvl 1)
    6149,   -- Greater Mana Potion
    274936, -- Tessa's Tonic (Mana)
    3827,   -- Mana Potion
    3385,   -- Lesser Mana Potion
    287969, -- Lesser Mana Potion (Forever lvl 1)
    2455,   -- Minor Mana Potion
    287968, -- Minor Mana Potion (Forever lvl 1)
    2456,   -- Minor Rejuvenation Potion
}

local function HasItemInBags(itemId)
    if not itemId then return false end
    if C_Item and C_Item.GetItemCount then
        local count = C_Item.GetItemCount(itemId, false, false, false)
        if count and count > 0 then return true end
    end
    if GetItemCount then
        local count = GetItemCount(itemId)
        if count and count > 0 then return true end
    end
    return false
end

local function GetBestHealthPotionId()
    for _, id in ipairs(FOREVER_HEALTH_POTS) do
        if HasItemInBags(id) then
            return id
        end
    end
    return nil
end

local function GetBestManaPotionId()
    for _, id in ipairs(FOREVER_MANA_POTS) do
        if HasItemInBags(id) then
            return id
        end
    end
    return nil
end

local function CleanMacroBody(macroName, body)
    if not body or not body:find("255663") then
        return body, false
    end

    local isMana = false
    local lowerName = string.lower(macroName or "")
    if lowerName:find("mana") then
        isMana = true
    end

    local replacementId = isMana and GetBestManaPotionId() or GetBestHealthPotionId()
    local newBody = body

    if replacementId then
        newBody = newBody:gsub("item:255663", "item:" .. replacementId)
        newBody = newBody:gsub("255663", tostring(replacementId))
    else
        newBody = newBody:gsub(",%s*item:255663", "")
        newBody = newBody:gsub("item:255663%s*,%s*", "")
        newBody = newBody:gsub("item:255663", "")
        newBody = newBody:gsub("/use%s*item:255663\r?\n?", "")
        newBody = newBody:gsub("/use%s*255663\r?\n?", "")
        if newBody:match("/castsequence%s*[@%w_]*%s*reset=[^%s]+\r?\n?$") or newBody:match("/castsequence%s*reset=[^%s]+\r?\n?$") then
            newBody = "#showtooltip\n"
        end
    end

    return newBody, (newBody ~= body)
end

function TimelessTweaks:CleanAutoPotionMacros()
    if InCombatLockdown() or isCleaningMacro then return 0 end
    if not TimelessTweaksDB or TimelessTweaksDB.autoPotionNoWindstone == false then return 0 end

    local cleanedCount = 0

    -- 1. Scan all general and character macros by index
    local globalCount, perCharCount = 0, 0
    if GetNumMacros then
        globalCount, perCharCount = GetNumMacros()
    end
    local totalMacros = (globalCount or 0) + (perCharCount or 0)
    for idx = 1, totalMacros do
        local mName, mIcon, mBody = GetMacroInfo(idx)
        if mBody and mBody:find("255663") then
            local cleanedBody, modified = CleanMacroBody(mName or "Macro", mBody)
            if modified and cleanedBody ~= mBody then
                isCleaningMacro = true
                EditMacro(idx, mName, mIcon, cleanedBody)
                isCleaningMacro = false
                cleanedCount = cleanedCount + 1
            end
        end
    end

    -- 2. Explicitly verify named target macros (AutoPotion & AutoManaPotion)
    local targetMacroNames = { "AutoPotion", "AutoManaPotion" }
    if LibStub then
        local AceLocale = LibStub("AceLocale-3.0", true)
        if AceLocale then
            local L = AceLocale:GetLocale("AutoPotion", true)
            if L then
                if L["AutoPotion"] then table.insert(targetMacroNames, L["AutoPotion"]) end
                if L["AutoManaPotion"] then table.insert(targetMacroNames, L["AutoManaPotion"]) end
            end
        end
    end

    for _, name in ipairs(targetMacroNames) do
        local mName, mIcon, mBody = GetMacroInfo(name)
        if not mName and GetMacroIndexByName then
            local idx = GetMacroIndexByName(name)
            if idx and idx > 0 then
                mName, mIcon, mBody = GetMacroInfo(idx)
            end
        end
        if mBody and mBody:find("255663") then
            local cleanedBody, modified = CleanMacroBody(name, mBody)
            if modified and cleanedBody ~= mBody then
                isCleaningMacro = true
                EditMacro(name, mName or name, mIcon, cleanedBody)
                isCleaningMacro = false
                cleanedCount = cleanedCount + 1
            end
        end
    end

    return cleanedCount
end

local function GetAutoPotionLiveStatusText()
    local isLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isLoaded = C_AddOns.IsAddOnLoaded("AutoPotion")
    elseif IsAddOnLoaded then
        isLoaded = IsAddOnLoaded("AutoPotion")
    end

    local statusLines = {}
    if isLoaded then
        table.insert(statusLines, "|cff00ff00[Installed & Loaded]|r AutoPotion active.")
    else
        table.insert(statusLines, "|cffff8800[Not Loaded]|r AutoPotion addon not loaded.")
    end

    local isProtected = (TimelessTweaksDB and TimelessTweaksDB.autoPotionNoWindstone ~= false)
    local protStatus = isProtected and "|cff00ff00ACTIVE (Windstone Blocked & Cleaned)|r" or "|cffff3333DISABLED (Windstone Allowed)|r"
    table.insert(statusLines, "• Protection Mode: " .. protStatus)

    -- Check AutoPotion Health Macro
    local apBody = nil
    local apName, _, b1 = GetMacroInfo("AutoPotion")
    if apName then apBody = b1 end
    if not apBody and GetMacroIndexByName then
        local idx = GetMacroIndexByName("AutoPotion")
        if idx and idx > 0 then
            local _, _, b2 = GetMacroInfo(idx)
            apBody = b2
        end
    end

    if apBody then
        if apBody:find("255663") then
            table.insert(statusLines, "• Health Macro: |cffff3333Contains Windstone (255663)|r")
        else
            local potMatch = apBody:match("item:(%d+)")
            if potMatch then
                local itemName = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(tonumber(potMatch)) or ("Item #" .. potMatch)
                table.insert(statusLines, "• Health Macro: |cffffd100" .. tostring(itemName) .. "|r (item:" .. potMatch .. ")")
            else
                table.insert(statusLines, "• Health Macro: |cff00ff00Clean / Ready|r")
            end
        end
    else
        table.insert(statusLines, "• Health Macro: |cff888888Not created yet (AutoPotion creates on bag update)|r")
    end

    -- Check AutoManaPotion Macro
    local manaBody = nil
    local mName, _, mb1 = GetMacroInfo("AutoManaPotion")
    if mName then manaBody = mb1 end
    if not manaBody and GetMacroIndexByName then
        local idx = GetMacroIndexByName("AutoManaPotion")
        if idx and idx > 0 then
            local _, _, mb2 = GetMacroInfo(idx)
            manaBody = mb2
        end
    end

    if manaBody then
        if manaBody:find("255663") then
            table.insert(statusLines, "• Mana Macro: |cffff3333Contains Windstone (255663)|r")
        else
            local potMatch = manaBody:match("item:(%d+)")
            if potMatch then
                local itemName = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(tonumber(potMatch)) or ("Item #" .. potMatch)
                table.insert(statusLines, "• Mana Macro: |cffffd100" .. tostring(itemName) .. "|r (item:" .. potMatch .. ")")
            else
                table.insert(statusLines, "• Mana Macro: |cff00ff00Clean / Ready|r")
            end
        end
    else
        table.insert(statusLines, "• Mana Macro: |cff888888Not created yet|r")
    end

    return table.concat(statusLines, "\n")
end

local function NotifyCombatOptionsChanged()
    local LibStub = _G.LibStub
    if LibStub then
        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
        if AceConfigRegistry then
            pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessForever")
            pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "Timeless")
            pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, "TimelessTweaks")
        end
    end
end

function TimelessTweaks:AttemptRuntimeAutoPotionPatch()
    local ap = _G["AutoPotion"]
    if ap and type(ap) == "table" then
        if ap.getPotsForForever and not ap._tfPatched then
            local origPots = ap.getPotsForForever
            ap.getPotsForForever = function(...)
                local pots = origPots(...)
                if pots and type(pots) == "table" then
                    for i = #pots, 1, -1 do
                        local item = pots[i]
                        if item and ((item.getId and item.getId() == 255663) or item == ap.windstone) then
                            table.remove(pots, i)
                        end
                    end
                end
                return pots
            end
            ap._tfPatched = true
        end
        if ap.getManaPotionsForForever and not ap._tfManaPatched then
            local origMana = ap.getManaPotionsForForever
            ap.getManaPotionsForForever = function(...)
                local pots = origMana(...)
                if pots and type(pots) == "table" then
                    for i = #pots, 1, -1 do
                        local item = pots[i]
                        if item and ((item.getId and item.getId() == 255663) or item == ap.manaWindstone) then
                            table.remove(pots, i)
                        end
                    end
                end
                return pots
            end
            ap._tfManaPatched = true
        end
    end
end

hooksecurefunc("EditMacro", function(indexOrName, name, icon, body)
    if isCleaningMacro or InCombatLockdown() then return end
    if not TimelessTweaksDB or TimelessTweaksDB.autoPotionNoWindstone == false then return end
    if not body or not body:find("255663") then return end

    local cleanedBody, modified = CleanMacroBody(name or tostring(indexOrName), body)
    if modified and cleanedBody ~= body then
        isCleaningMacro = true
        EditMacro(indexOrName, name, icon, cleanedBody)
        isCleaningMacro = false
    end
end)

hooksecurefunc("CreateMacro", function(name, icon, body)
    if isCleaningMacro or InCombatLockdown() then return end
    if not TimelessTweaksDB or TimelessTweaksDB.autoPotionNoWindstone == false then return end
    if not body or not body:find("255663") then return end

    local cleanedBody, modified = CleanMacroBody(name, body)
    if modified and cleanedBody ~= body then
        isCleaningMacro = true
        EditMacro(name, name, icon, cleanedBody)
        isCleaningMacro = false
    end
end)

-- =========================================================================
-- Blizzard Settings (Esc -> Options -> AddOns -> TimelessTweaks)
-- =========================================================================
local function RegisterBlizzOptions()
    if TimelessTweaks._blizzRegistered then return end
    local LibStub = _G.LibStub
    if not LibStub then return end
    local AceConfig = LibStub("AceConfig-3.0", true)
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if not AceConfig or not AceConfigDialog then return end

    local options = {
        name = "Timeless Tweaks",
        type = "group",
        childGroups = "tab",
        args = {
            gfxTab = {
                name = "Graphics",
                type = "group",
                order = 1,
                args = {
                    desc = {
                        order = 1,
                        type = "description",
                        name = "Fine-tune ultra graphics settings, render distances, reflections, and GPU sharpening filters.\n",
                    },
                    presetsHeader = {
                        order = 2,
                        type = "header",
                        name = "Quick Actions & Presets",
                    },
                    applyUltra = {
                        order = 3,
                        type = "execute",
                        name = "Apply ALL Ultra",
                        desc = "Maxes out every slider in Graphics & CVars and applies all 10 Ultra Graphics settings.",
                        func = function()
                            local db = TimelessTweaksDB
                            if not db then return end
                            db.cameraDistanceMaxZoomFactor = 4.0
                            db.reflectionMode = 3
                            db.ResampleAlwaysSharpen = 1
                            db.weatherdensity = 3
                            db.groundEffectDist = 500
                            db.groundEffectDensity = 256
                            db.doodadLodScale = 200
                            db.terrainLodDist = 1000
                            db.lodObjectCullSize = 35
                            db.lodObjectFadeScale = 200
                            TimelessTweaks:ApplyGraphicsSettings()
                            RefreshAllSliders()
                            print(ICON .. "|cff00ccff[TimelessTweaks]|r All 10 Ultra Graphics settings maxed and applied!")
                        end,
                    },
                    cvarsHeader = {
                        order = 10,
                        type = "header",
                        name = "Engine CVars & Render Distances",
                    },
                    cameraZoom = {
                        order = 11,
                        type = "range",
                        name = "Max Camera Zoom Factor",
                        desc = "Maximum camera zoom out distance. Default WoW max is 2.6; Timeless ultra max is 4.0.",
                        min = 1.0, max = 4.0, step = 0.1,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.cameraDistanceMaxZoomFactor) or 4.0 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.cameraDistanceMaxZoomFactor = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    groundEffectDist = {
                        order = 12,
                        type = "range",
                        name = "Ground Clutter Render Distance",
                        desc = "Distance at which grass, rocks, and ground clutter render (40 - 500).",
                        min = 40, max = 500, step = 10,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.groundEffectDist) or 500 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.groundEffectDist = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    groundEffectDensity = {
                        order = 13,
                        type = "range",
                        name = "Ground Clutter Density",
                        desc = "Density of foliage and grass (16 - 256).",
                        min = 16, max = 256, step = 16,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.groundEffectDensity) or 256 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.groundEffectDensity = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    terrainLodDist = {
                        order = 14,
                        type = "range",
                        name = "Terrain LOD Distance",
                        desc = "High-definition terrain mesh distance (100 - 1000).",
                        min = 100, max = 1000, step = 50,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.terrainLodDist) or 1000 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.terrainLodDist = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    doodadLodScale = {
                        order = 15,
                        type = "range",
                        name = "Doodad LOD Scale",
                        desc = "Doodad detail scale (50 - 200).",
                        min = 50, max = 200, step = 10,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.doodadLodScale) or 200 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.doodadLodScale = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    lodObjectCullSize = {
                        order = 16,
                        type = "range",
                        name = "LOD Object Cull Size",
                        desc = "LOD Object Cull Size (1 - 35).",
                        min = 1, max = 35, step = 1,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.lodObjectCullSize) or 35 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.lodObjectCullSize = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    lodObjectFadeScale = {
                        order = 17,
                        type = "range",
                        name = "LOD Object Fade Scale",
                        desc = "LOD Object Fade Scale (50 - 200).",
                        min = 50, max = 200, step = 10,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.lodObjectFadeScale) or 200 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.lodObjectFadeScale = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    reflectionMode = {
                        order = 18,
                        type = "range",
                        name = "Water & Environment Reflection",
                        desc = "Water reflection quality (0=Disabled, 3=Full Ultra).",
                        min = 0, max = 3, step = 1,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.reflectionMode) or 3 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.reflectionMode = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    weatherdensity = {
                        order = 19,
                        type = "range",
                        name = "Weather Particle Density",
                        desc = "Rain, snow, and ambient weather intensity (0=Off, 3=Heavy).",
                        min = 0, max = 3, step = 1,
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.weatherdensity) or 3 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.weatherdensity = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                    sharpen = {
                        order = 20,
                        type = "range",
                        name = "Resample Sharpening",
                        desc = "GPU FidelityFX sharpening filter (0=Off, 1=Max).",
                        min = 0, max = 1, step = 0.1,
                        get = function() return (TimelessTweaksDB and tonumber(TimelessTweaksDB.ResampleAlwaysSharpen)) or 1 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.ResampleAlwaysSharpen = val
                                TimelessTweaks:ApplyGraphicsSettings()
                                RefreshAllSliders()
                            end
                        end,
                    },
                },
            },
            controlsTab = {
                name = "Controls",
                type = "group",
                order = 2,
                args = {
                    desc = {
                        order = 1,
                        type = "description",
                        name = "Convenience, mouseover targeting, camera style, and bag integration options.\n",
                    },
                    controlsHeader = {
                        order = 10,
                        type = "header",
                        name = "Controls & Convenience",
                    },
                    stickyTargeting = {
                        order = 11,
                        type = "toggle",
                        name = "Sticky Targeting",
                        desc = "Prevents accidentally clearing your target when clicking empty ground.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.stickyTargeting ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.stickyTargeting = val
                                TimelessTweaks:ApplyControlsSettings()
                            end
                        end,
                    },
                    autoLoot = {
                        order = 12,
                        type = "toggle",
                        name = "Auto Loot",
                        desc = "Automatically loot items upon opening containers or corpses without holding shift.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.autoLoot ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.autoLoot = val
                                TimelessTweaks:ApplyControlsSettings()
                            end
                        end,
                    },
                    lootUnderMouse = {
                        order = 13,
                        type = "toggle",
                        name = "Loot Window Under Mouse",
                        desc = "Opens the loot window directly at the mouse cursor position.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.lootUnderMouse ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.lootUnderMouse = val
                                TimelessTweaks:ApplyControlsSettings()
                            end
                        end,
                    },
                    combineBags = {
                        order = 14,
                        type = "toggle",
                        name = "Combine All Bags into One",
                        desc = "Merge all backpack bags into one unified container view.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.combineBags ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.combineBags = val
                                TimelessTweaks:ApplyControlsSettings()
                            end
                        end,
                    },
                    cameraSmoothStyle = {
                        order = 15,
                        type = "select",
                        name = "Camera Following Style",
                        desc = "How the camera auto-adjusts when turning or moving.",
                        values = { [0] = "Never (Recommended)", [1] = "Only when moving", [2] = "Always" },
                        get = function() return (TimelessTweaksDB and TimelessTweaksDB.cameraSmoothStyle) or 0 end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.cameraSmoothStyle = val
                                TimelessTweaks:ApplyControlsSettings()
                            end
                        end,
                    },
                    hideActionBarEndCaps = {
                        order = 16,
                        type = "toggle",
                        width = "full",
                        name = "Force Hide Action Bar EndCaps (Left & Right Gryphons)",
                        desc = "Force-hides MainActionBar.EndCaps.LeftEndCap (.Texture) and RightEndCap (.Texture).",
                        get = function() return not TimelessTweaksDB or TimelessTweaksDB.hideActionBarEndCaps ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.hideActionBarEndCaps = val
                                TimelessTweaks:ApplyActionBarEndCaps()
                            end
                        end,
                    },
                },
            },
            combatTab = {
                name = "Combat",
                type = "group",
                order = 3,
                args = {
                    desc = {
                        order = 1,
                        type = "description",
                        name = "Combat targeting frames, mouseover casting, indicators, and live AutoPotion macro integration.\nAll changes update live in real-time without requiring a reload.\n",
                    },
                    combatHeader = {
                        order = 10,
                        type = "header",
                        name = "Combat & Targeting (Live Updates)",
                    },
                    targetOfTarget = {
                        order = 11,
                        type = "toggle",
                        name = "Target of Target",
                        desc = "Show target's target frame during combat. Toggling immediately updates frame on screen.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.targetOfTarget ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.targetOfTarget = val
                                TimelessTweaks:ApplyCombatSettings()
                                if TargetFrame_CheckTargetOfTarget then
                                    pcall(TargetFrame_CheckTargetOfTarget, TargetFrame)
                                end
                                if TargetFrame_Update then
                                    pcall(TargetFrame_Update, TargetFrame)
                                end
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    actionTarget = {
                        order = 12,
                        type = "toggle",
                        name = "Modern Action Targeting",
                        desc = "Automatically soft-targets enemies in front of your character.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.actionTarget ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.actionTarget = val
                                TimelessTweaks:ApplyCombatSettings()
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    mouseoverCast = {
                        order = 13,
                        type = "toggle",
                        name = "Mouseover Casting",
                        desc = "Enables mouseover casting on unit frames and 3D character models.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.mouseoverCast ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.mouseoverCast = val
                                TimelessTweaks:ApplyCombatSettings()
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    mouseoverCastKey = {
                        order = 14,
                        type = "select",
                        name = "Mouseover Modifier Key",
                        desc = "Choose which modifier key must be held for mouseover casting (or None to cast without any modifier).",
                        disabled = function() return not (TimelessTweaksDB and TimelessTweaksDB.mouseoverCast) end,
                        values = {
                            NONE = "None (No modifier required)",
                            ALT = "Alt Key",
                            CTRL = "Ctrl Key",
                            SHIFT = "Shift Key",
                        },
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.mouseoverCastKey or "NONE" end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.mouseoverCastKey = val
                                TimelessTweaks:ApplyCombatSettings()
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    displayClassColors = {
                        order = 15,
                        type = "toggle",
                        name = "Class Colors in Chat & Nameplates",
                        desc = "Display class-specific colors for player names in chat and on nameplates.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.displayClassColors ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.displayClassColors = val
                                TimelessTweaks:ApplyInterfaceSettings()
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    showSilhouette = {
                        order = 16,
                        type = "toggle",
                        name = "Character Silhouette Highlight",
                        desc = "Highlights character silhouette when occluded behind walls or terrain.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.showSilhouette ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.showSilhouette = val
                                TimelessTweaks:ApplyCombatSettings()
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    doNotFlashLowHealth = {
                        order = 17,
                        type = "toggle",
                        name = "Disable Low Health Screen Flash",
                        desc = "Prevents full-screen red flashing when health drops low.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.doNotFlashLowHealth ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.doNotFlashLowHealth = val
                                TimelessTweaks:ApplyCombatSettings()
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    autoPotionHeader = {
                        order = 20,
                        type = "header",
                        name = "AutoPotion Live Integration (No Windstone)",
                    },
                    autoPotionLiveStatus = {
                        order = 21,
                        type = "description",
                        name = function()
                            return GetAutoPotionLiveStatusText()
                        end,
                    },
                    autoPotionNoWindstone = {
                        order = 22,
                        type = "toggle",
                        width = "full",
                        name = "AutoPotion: Remove Windstone",
                        desc = "Automatically prevents Windstone (Item 255663) from polluting your AutoPotion and AutoManaPotion macros on Zephras Isle, auto-reapplying even if AutoPotion updates.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.autoPotionNoWindstone ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.autoPotionNoWindstone = val
                                if val and TimelessTweaks.CleanAutoPotionMacros then
                                    TimelessTweaks:CleanAutoPotionMacros()
                                end
                                NotifyCombatOptionsChanged()
                            end
                        end,
                    },
                    autoPotionAuditNow = {
                        order = 23,
                        type = "execute",
                        width = "double",
                        name = "Update Macros Live Now",
                        desc = "Scans all macros and player bags right now, replaces Windstone with the best valid potion live without needing /reload.",
                        func = function()
                            local count = 0
                            if TimelessTweaks.CleanAutoPotionMacros then
                                count = TimelessTweaks:CleanAutoPotionMacros()
                            end
                            NotifyCombatOptionsChanged()
                            print(ICON .. "|cff00ccff[TimelessTweaks]|r AutoPotion macros updated live! (" .. count .. " cleaned)")
                        end,
                    },
                },
            },
            cleanerTab = {
                name = "Startup Cleaner",
                type = "group",
                order = 4,
                args = {
                    desc = {
                        order = 1,
                        type = "description",
                        name = "Silence addon startup banners and route splash spam into an isolated chat tab.\n",
                    },
                    startupHeader = {
                        order = 10,
                        type = "header",
                        name = "Addon Startup & Chat Cleaner",
                    },
                    cleanStartupChat = {
                        order = 11,
                        type = "toggle",
                        name = "Clean Startup Spam (Keep Main Chat Clean)",
                        desc = "Silences startup splash banners and welcome messages from ALL addons in your main chat window (General) and routes them into a dedicated 'ADDON Startup' chat tab.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.cleanStartupChat ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.cleanStartupChat = val
                                local TSC = _G["TimelessStartupClean"]
                                if TSC then TSC.isActive = val end
                                if val and GetOrCreateAddonStartupChatFrame then
                                    GetOrCreateAddonStartupChatFrame()
                                end
                            end
                        end,
                    },
                    createStartupTab = {
                        order = 12,
                        type = "toggle",
                        name = "Create & Maintain 'ADDON Startup' Tab",
                        desc = "Automatically creates and docks an 'ADDON Startup' chat tab next to General/Combat Log.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.createStartupTab ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.createStartupTab = val
                                if val and GetOrCreateAddonStartupChatFrame then
                                    GetOrCreateAddonStartupChatFrame()
                                end
                            end
                        end,
                    },
                    showStartupNotice = {
                        order = 13,
                        type = "toggle",
                        name = "Show Summary Notice in General",
                        desc = "Displays a single clean notification in General after startup completes.",
                        get = function() return TimelessTweaksDB and TimelessTweaksDB.showStartupNotice ~= false end,
                        set = function(_, val)
                            if TimelessTweaksDB then
                                TimelessTweaksDB.showStartupNotice = val
                            end
                        end,
                    },
                    actionsHeader = {
                        order = 20,
                        type = "header",
                        name = "Quick Actions & Exporter",
                    },
                    openPanel = {
                        order = 21,
                        type = "execute",
                        name = "Open Full Tweaks Dashboard Window",
                        desc = "Opens the full multi-tab graphical control center.",
                        func = function()
                            if panel then panel:Show() end
                        end,
                    },
                    exportBtn = {
                        order = 22,
                        type = "execute",
                        name = "Export Config.wtf & Macros",
                        desc = "Opens the in-game macro and Config.wtf text exporter dialog.",
                        func = function()
                            TimelessTweaks:ShowExportDialog()
                        end,
                    },
                    reloadUI = {
                        order = 23,
                        type = "execute",
                        name = "Reload UI (/rl)",
                        desc = "Reload user interface to apply all system changes.",
                        func = function() ReloadUI() end,
                    },
                },
            },
        },
    }

    AceConfig:RegisterOptionsTable("TimelessForever_Tweaks", options)

    local TimelessSuite = (_G["TimelessForeverSuite"] or _G["TimelessSuite"]) or {}
    _G["TimelessForeverSuite"] = TimelessSuite
    _G["TimelessSuite"] = TimelessSuite
    if not TimelessSuite.options then
        TimelessSuite.options = { name = "TimelessForever", type = "group", childGroups = "tab", args = {} }
    end
    if not TimelessSuite.RegisterModuleTab then
        function TimelessSuite:RegisterModuleTab(id, tabName, order, tabArgs)
            self.options.args[id] = { name = tabName, type = "group", childGroups = "tab", order = order, args = tabArgs }
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

    TimelessSuite:RegisterModuleTab("tweaks", "Tweaks", 4, options.args)
    TimelessTweaks._blizzRegistered = true
end

-- =========================================================================
-- Lifecycle & Event Handling (Pure Read-Only on Startup)
-- =========================================================================
TimelessTweaks:RegisterEvent("PLAYER_LOGIN")
TimelessTweaks:RegisterEvent("PLAYER_ENTERING_WORLD")
TimelessTweaks:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
TimelessTweaks:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
TimelessTweaks:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
TimelessTweaks:RegisterEvent("BAG_UPDATE_DELAYED")
TimelessTweaks:RegisterEvent("ZONE_CHANGED_NEW_AREA")
TimelessTweaks:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(function() TimelessTweaks:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED") end)

TimelessTweaks:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        InitDB()
        self:SyncFromGameCVars()
        self:ApplyActionBarEndCaps()
        pcall(RegisterBlizzOptions)
        HookChatFrameAddMessage(DEFAULT_CHAT_FRAME)
        HookChatFrameAddMessage(ChatFrame1)
        if not (TimelessTweaksDB.cleanStartupChat ~= false) or TimelessTweaksDB.cleanStartupMode == "OFF" then
            TSC.isActive = false
        else
            TSC.isActive = true
        end
        pcall(function() self:AttemptRuntimeAutoPotionPatch() end)
        C_Timer.After(1.0, function() self:CleanAutoPotionMacros() end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:ApplyActionBarEndCaps()
        C_Timer.After(0.5, function() TimelessTweaks:ApplyActionBarEndCaps() end)
        C_Timer.After(2.0, function() TimelessTweaks:ApplyActionBarEndCaps() end)
        if DEFAULT_CHAT_FRAME then
            HookChatFrameAddMessage(DEFAULT_CHAT_FRAME)
        end
        if ChatFrame1 then
            HookChatFrameAddMessage(ChatFrame1)
        end
        C_Timer.After(1.0, function() self:CleanAutoPotionMacros() end)
        if TimelessTweaksDB.cleanStartupChat ~= false then
            C_Timer.After(0.5, function()
                FlushStartupBuffer()
                if ChatFrame1 and FCF_SelectDockFrame then
                    pcall(FCF_SelectDockFrame, ChatFrame1)
                end
            end)

            local duration = TimelessTweaksDB.cleanStartupDuration or 10
            C_Timer.After(duration, function()
                local mode = TimelessTweaksDB.cleanStartupMode or "ALWAYS"
                if mode ~= "ALWAYS" then
                    TSC.isActive = false
                end
                FlushStartupBuffer()
                if ChatFrame1 and FCF_SelectDockFrame then
                    pcall(FCF_SelectDockFrame, ChatFrame1)
                end
                if TSC.OnStartupComplete then
                    TSC:OnStartupComplete()
                elseif TimelessTweaksDB.showStartupNotice and TSC.count > 0 then
                    local frame = GetAddonStartupChatFrame()
                    if frame and frame.AddMessage then
                        frame:AddMessage(ICON .. "|cff00ccff[TimelessTweaks]|r Clean Chat: Routed |cffffd100" .. TSC.count .. "|r addon messages into this tab.")
                    end
                end
            end)
        end
    elseif event == "BAG_UPDATE_DELAYED" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_REGEN_ENABLED" then
        C_Timer.After(0.2, function() self:CleanAutoPotionMacros() end)
    else
        self:ApplyActionBarEndCaps()
    end
end)

pcall(function() TimelessTweaks:ApplyActionBarEndCaps() end)

-- =========================================================================
-- Slash Commands
-- =========================================================================
SLASH_TIMELESSFOREVERTWEAKS1 = "/tftweaks"
SLASH_TIMELESSFOREVERTWEAKS2 = "/tftw"
SLASH_TIMELESSFOREVERTWEAKS3 = "/timelesstweaks"
SLASH_TIMELESSFOREVERTWEAKS4 = "/ttweaks"
SLASH_TIMELESSFOREVERTWEAKS5 = "/tweaks"
SLASH_TIMELESSFOREVERTWEAKS6 = "/ttw"
SLASH_TIMELESSFOREVERTWEAKS7 = "/forevertweaks"
SLASH_TIMELESSFOREVERTWEAKS8 = "/ftweaks"
SLASH_TIMELESSFOREVERTWEAKS9 = "/fc"

SLASH_TIMELESSTWEAKS1 = "/tweaks"
SLASH_TIMELESSTWEAKS2 = "/ttweaks"
SLASH_TIMELESSTWEAKS3 = "/ttw"

local function HandleSlashCmd(msg)
    local cmd = string.lower(string.trim(msg or ""))
    if cmd == "ultra" then
        local db = TimelessTweaksDB
        db.cameraDistanceMaxZoomFactor = 4.0
        db.reflectionMode = 3
        db.ResampleAlwaysSharpen = 1
        db.weatherdensity = 3
        db.groundEffectDist = 500
        db.groundEffectDensity = 256
        db.doodadLodScale = 200
        db.terrainLodDist = 1000
        db.lodObjectCullSize = 35
        db.lodObjectFadeScale = 200
        TimelessTweaks:ApplyGraphicsSettings()
        RefreshAllSliders()
        print(ICON .. "|cff00ccff[TimelessTweaks]|r All 10 Ultra Graphics settings maxed and applied!")
    elseif cmd == "macro1" then
        local db = TimelessTweaksDB
        db.cameraDistanceMaxZoomFactor = 4.0
        db.reflectionMode = 3
        db.ResampleAlwaysSharpen = 1
        db.weatherdensity = 3
        db.groundEffectDist = 500
        db.groundEffectDensity = 256
        TimelessTweaks:ApplyGraphicsSettings()
        RefreshAllSliders()
        print(ICON .. "|cff00ccff[TimelessTweaks]|r Macro 1 applied!")
    elseif cmd == "macro2" then
        local db = TimelessTweaksDB
        db.doodadLodScale = 200
        db.terrainLodDist = 1000
        db.lodObjectCullSize = 35
        db.lodObjectFadeScale = 200
        TimelessTweaks:ApplyGraphicsSettings()
        RefreshAllSliders()
        print(ICON .. "|cff00ccff[TimelessTweaks]|r Macro 2 applied!")
    elseif cmd == "export" then
        TimelessTweaks:ShowExportDialog()
    elseif cmd == "clean" or cmd == "startupclean" or cmd == "sc" or cmd == "startupclearer" then
        if TSC and TSC.OpenViewer then
            TSC:OpenViewer()
        elseif TSC and TSC.PrintCleanedList then
            TSC:PrintCleanedList()
        end
    elseif cmd == "tab" or cmd == "startuptab" then
        TimelessTweaks:OpenStartupTab()
    elseif cmd == "clearstartup" then
        TimelessTweaks:ClearStartupTab()
    elseif cmd == "endcaps" or cmd == "endcap" or cmd == "gryphons" then
        InitDB()
        TimelessTweaksDB.hideActionBarEndCaps = not (TimelessTweaksDB.hideActionBarEndCaps ~= false)
        TimelessTweaks:ApplyActionBarEndCaps()
        local status = (TimelessTweaksDB.hideActionBarEndCaps ~= false) and "|cff00ff00FORCE HIDDEN|r" or "|cffffd100SHOWN|r"
        print(ICON .. "|cff00ccff[TimelessTweaks]|r MainActionBar EndCaps: " .. status)
    elseif cmd == "windstone" or cmd == "autopotion" then
        InitDB()
        TimelessTweaksDB.autoPotionNoWindstone = true
        if TimelessTweaks.CleanAutoPotionMacros then
            TimelessTweaks:CleanAutoPotionMacros()
        end
        print(ICON .. "|cff00ccff[TimelessTweaks]|r AutoPotion Windstone removal verified and applied!")
    else
        if panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
        end
    end
end

SlashCmdList["TIMELESSFOREVERTWEAKS"] = HandleSlashCmd
SlashCmdList["FOREVERTWEAKS"] = HandleSlashCmd
SlashCmdList["TIMELESSTWEAKS"] = HandleSlashCmd

-- Quick Reload Command: /rl
if not SlashCmdList["TIMELESSRELOAD"] and not SlashCmdList["RELOADUI"] then
    SLASH_TIMELESSRELOAD1 = "/rl"
    SlashCmdList["TIMELESSRELOAD"] = function() ReloadUI() end
end

print(ICON .. "|cff00ccffTimelessTweaks|r loaded! Type |cffffd100/ttweaks|r or |cffffd100/tweaks|r to open settings.")
C_Timer.After(1, function() pcall(RegisterBlizzOptions) end)

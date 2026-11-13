-- =========================================================================
-- TimelessForever_Fishing (formerly FishingTime / FishingForever / FishSwap)
-- 
-- Features:
-- 1. Auto-detects fishing rod in bags & remembers your equipped weapons (Quarter Staff, etc.)
-- 2. Automatically creates and updates the "FishSwap" macro
-- 3. Click anywhere to reel in fish like Retail (SoftTargetInteract + INTERACTTARGET override)
-- 4. Double right-click anywhere to cast Fishing
-- 5. Floating draggable FishingTime icon with Shift+Drag to reposition
-- 6. Sound booster while fishing (hear the splash clearly)
-- =========================================================================

local ADDON_NAME, addonTable = ...
local FishingApp = CreateFrame("Frame", "TimelessForever_FishingFrame")

-- -------------------------------------------------------------------------
-- Database & Defaults
-- -------------------------------------------------------------------------
local DB_DEFAULTS = {
    enabled = true,
    enableSingleClick = true,
    enableDoubleClick = false,
    doubleClickDelay = 0.4,
    enableSoundBoost = true,
    enableClickAnywhereReel = true,
    showIcon = true,
    fishingIcon = "INV_Fishingpole_02",
    customFishingIcon = "",
    macroShowTooltip = true,
    iconPos = { point = "CENTER", x = 0, y = 100 },
    lastMainHand = nil,
    lastMainID = nil,
    lastOffHand = nil,
    lastOffID = nil,
    lastRodName = nil,
    lastRodID = nil,
}

local FISHING_ICON_OPTIONS = {
    ["Trade_Fishing"]            = "|TInterface\\Icons\\Trade_Fishing:18:18:0:0|t  Fishing Skill (Hook & Bobber)",
    ["INV_Fishingpole_02"]       = "|TInterface\\Icons\\INV_Fishingpole_02:18:18:0:0|t  Classic Wooden Fishing Pole",
    ["INV_Fishingpole_01"]       = "|TInterface\\Icons\\INV_Fishingpole_01:18:18:0:0|t  Arcanite / Golden Fishing Pole",
    ["INV_Fishingpole_03"]       = "|TInterface\\Icons\\INV_Fishingpole_03:18:18:0:0|t  Mastercraft Kalu'ak Fishing Pole",
    ["INV_Fishingpole_05"]       = "|TInterface\\Icons\\INV_Fishingpole_05:18:18:0:0|t  Bone Fishing Pole",
    ["INV_Fishingpole_06"]       = "|TInterface\\Icons\\INV_Fishingpole_06:18:18:0:0|t  Jeweled Fishing Pole",
    ["INV_Fishingpole_07"]       = "|TInterface\\Icons\\INV_Fishingpole_07:18:18:0:0|t  Dragon Fishing Pole",
    ["INV_Helmet_31"]            = "|TInterface\\Icons\\INV_Helmet_31:18:18:0:0|t  Weather-Beaten Fishing Hat (Nat's Hat)",
    ["INV_Box_01"]               = "|TInterface\\Icons\\INV_Box_01:18:18:0:0|t  Angler's Tackle Box",
    ["INV_Misc_Hook_01"]         = "|TInterface\\Icons\\INV_Misc_Hook_01:18:18:0:0|t  Sharp Fish Hook",
    ["INV_Misc_Orb_03"]          = "|TInterface\\Icons\\INV_Misc_Orb_03:18:18:0:0|t  Aquadynamic Fish Attractor (Lure)",
    ["INV_Misc_Food_26"]         = "|TInterface\\Icons\\INV_Misc_Food_26:18:18:0:0|t  Bright Baubles (Bobber Lure)",
    ["INV_Drink_19"]             = "|TInterface\\Icons\\INV_Drink_19:18:18:0:0|t  Captain Rumsey's Lager",
    ["INV_Misc_Fish_01"]         = "|TInterface\\Icons\\INV_Misc_Fish_01:18:18:0:0|t  Spotted Yellowtail",
    ["INV_Misc_Fish_02"]         = "|TInterface\\Icons\\INV_Misc_Fish_02:18:18:0:0|t  Firefin Red Snapper",
    ["INV_Misc_Fish_03"]         = "|TInterface\\Icons\\INV_Misc_Fish_03:18:18:0:0|t  Bluefish / Icefin",
    ["INV_Misc_Fish_04"]         = "|TInterface\\Icons\\INV_Misc_Fish_04:18:18:0:0|t  Oily Blackmouth",
    ["INV_Misc_Fish_05"]         = "|TInterface\\Icons\\INV_Misc_Fish_05:18:18:0:0|t  Stonescale Eel",
    ["INV_Misc_Fish_06"]         = "|TInterface\\Icons\\INV_Misc_Fish_06:18:18:0:0|t  Raw Mightfish / Sunfish",
    ["INV_Misc_Fish_07"]         = "|TInterface\\Icons\\INV_Misc_Fish_07:18:18:0:0|t  Winter Squid",
    ["INV_Misc_Fish_08"]         = "|TInterface\\Icons\\INV_Misc_Fish_08:18:18:0:0|t  Bristle Whisker Catfish",
    ["INV_Misc_Fish_13"]         = "|TInterface\\Icons\\INV_Misc_Fish_13:18:18:0:0|t  Savory Deviate Fish",
    ["INV_Misc_Fish_14"]         = "|TInterface\\Icons\\INV_Misc_Fish_14:18:18:0:0|t  Darkclaw Lobster",
    ["INV_Misc_Fish_19"]         = "|TInterface\\Icons\\INV_Misc_Fish_19:18:18:0:0|t  Raw Sagefish",
    ["INV_Misc_Fish_20"]         = "|TInterface\\Icons\\INV_Misc_Fish_20:18:18:0:0|t  Golden Darter / Salmon",
    ["INV_Misc_Fish_21"]         = "|TInterface\\Icons\\INV_Misc_Fish_21:18:18:0:0|t  Magical Crawdad (Mr. Pinchy)",
    ["INV_Misc_Fish_23"]         = "|TInterface\\Icons\\INV_Misc_Fish_23:18:18:0:0|t  Old Ironjaw / Old Crafty",
    ["INV_Misc_Fish_Turtle_02"]  = "|TInterface\\Icons\\INV_Misc_Fish_Turtle_02:18:18:0:0|t  Sea Turtle Mount",
    ["DYNAMIC_TOOLTIP"]          = "|TInterface\\Icons\\INV_Misc_QuestionMark:18:18:0:0|t  Dynamic Equipped Item (#showtooltip)",
    ["CUSTOM"]                   = "|TInterface\\Icons\\INV_Misc_Gear_01:18:18:0:0|t  Custom Icon Texture Name...",
}

local function GetDB()
    if type(TimelessForever_FishingDB) ~= "table" then
        TimelessForever_FishingDB = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
        if TimelessForever_FishingDB[k] == nil then
            TimelessForever_FishingDB[k] = v
        end
    end
    return TimelessForever_FishingDB
end

local function GetResolvedFishingIcon(forFloatingButton)
    local db = GetDB()
    local icon = db.fishingIcon or "INV_Fishingpole_02"
    if db.macroShowTooltip or icon == "DYNAMIC_TOOLTIP" then
        if forFloatingButton then
            return "Trade_Fishing"
        end
        return "INV_Misc_QuestionMark"
    elseif icon == "CUSTOM" then
        local custom = strtrim(db.customFishingIcon or "")
        custom = custom:gsub("^Interface\\Icons\\", ""):gsub("^Interface/Icons/", "")
        if custom ~= "" then
            return custom
        end
        return "Trade_Fishing"
    end
    return icon
end

-- -------------------------------------------------------------------------
-- Known Fishing Poles & Helpers
-- -------------------------------------------------------------------------
local KNOWN_RODS = {
    [6256]   = true, -- Fishing Pole
    [6365]   = true, -- Strong Fishing Pole
    [6366]   = true, -- Darkwood Fishing Pole
    [6367]   = true, -- Big Iron Fishing Pole
    [12225]  = true, -- Blump Family Fishing Pole
    [19022]  = true, -- Nat Pagle's Extreme Angler FC-5000
    [19970]  = true, -- Arcanite Fishing Pole
    [25924]  = true, -- Seth's Graphite Fishing Pole
    [44050]  = true, -- Mastercraft Kalu'ak Fishing Pole
    [45858]  = true, -- Nat's Lucky Fishing Pole
    [45991]  = true, -- Bone Fishing Pole
    [45992]  = true, -- Jeweled Fishing Pole
    [46337]  = true, -- Dragon Fishing Pole
    [84661]  = true, -- Dragon Fishing Pole
    [118381] = true, -- Ephemeral Fishing Pole
    [133755] = true, -- Underlight Angler
    [199046] = true, -- Khaz'gorite Fisherfriend
    [199047] = true, -- Draconium Fisherfriend
    [199048] = true, -- Serevite Fisherfriend
}

local function GetNumBagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag)
    end
    return 0
end

local function GetBagItemID(bag, slot)
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    elseif GetContainerItemID then
        return GetContainerItemID(bag, slot)
    end
    return nil
end

local function SafeGetItemInfo(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    elseif GetItemInfo then
        return GetItemInfo(item)
    end
    return nil
end

local function GetPoleSubclassName()
    if GetItemSubClassInfo then
        return GetItemSubClassInfo(2, 20) or "Fishing Poles"
    end
    return "Fishing Poles"
end

local function IsFishingPole(itemID)
    if not itemID then return false end
    if KNOWN_RODS[itemID] then return true end

    local db = GetDB()
    if db.lastRodID and itemID == db.lastRodID then
        return true
    end

    local name, _, _, _, _, _, subType, _, _, _, _, classID, subClassID = SafeGetItemInfo(itemID)
    if classID == 2 and (subClassID == 20 or subClassID == 25) then
        return true
    end

    local poleName = GetPoleSubclassName()
    if subType and (subType == poleName or subType == "Fishing Pole" or subType == "Fishing Poles") then
        return true
    end

    return false
end

local function IsFishingPoleEquipped()
    local mainHand = GetInventoryItemID("player", 16)
    return mainHand and IsFishingPole(mainHand) or false
end

local function FindFishingRod()
    local eqMainID = GetInventoryItemID("player", 16)
    if eqMainID and IsFishingPole(eqMainID) then
        local name = SafeGetItemInfo(eqMainID)
        return name, eqMainID
    end

    for bag = 0, 5 do
        local numSlots = GetNumBagSlots(bag)
        for slot = 1, numSlots do
            local itemID = GetBagItemID(bag, slot)
            if itemID and IsFishingPole(itemID) then
                local name = SafeGetItemInfo(itemID)
                return name, itemID
            end
        end
    end
    return nil, nil
end

local FISHING_SPELL_IDS = { 7620, 7731, 7732, 18248, 33095, 51294, 88868, 131474, 131476 }

local function GetFishingSpellName()
    local name
    for _, id in ipairs(FISHING_SPELL_IDS) do
        if C_Spell and C_Spell.GetSpellName then
            name = C_Spell.GetSpellName(id)
        end
        if not name and C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(id)
            name = info and info.name
        end
        if not name and GetSpellInfo then
            name = GetSpellInfo(id)
        end
        if name and name ~= "" then
            return name
        end
    end
    return "Fishing"
end

-- -------------------------------------------------------------------------
-- Stored Weapons & Macro Generation
-- -------------------------------------------------------------------------
local pendingMacroUpdate = false

local function UpdateStoredWeapons()
    local db = GetDB()
    local mainID = GetInventoryItemID("player", 16)
    local offID = GetInventoryItemID("player", 17)

    if mainID and not IsFishingPole(mainID) then
        local mainName = SafeGetItemInfo(mainID)
        if mainName and (not db.lastRodName or mainName ~= db.lastRodName) then
            db.lastMainHand = mainName
            db.lastMainID = mainID
        end

        if offID then
            local offName = SafeGetItemInfo(offID)
            if offName then
                db.lastOffHand = offName
                db.lastOffID = offID
            end
        else
            db.lastOffHand = nil
            db.lastOffID = nil
        end
    end

    if db.lastMainHand and db.lastRodName and db.lastMainHand == db.lastRodName then
        db.lastMainHand = nil
        db.lastMainID = nil
    end
end

local secureBtn = CreateFrame("Button", "TF_FishSwapButton", UIParent, "SecureActionButtonTemplate")
secureBtn:EnableMouse(false)
secureBtn:SetAttribute("type", "macro")

local function BuildMacroBody(rodName, mainName, offName)
    local lines = {}
    local db = GetDB()
    local spellName = GetFishingSpellName() or "Fishing"

    local condEquippedRod = "[equipped:Fishing Pole,nomod][equipped:Fishing Poles,nomod]"
    if rodName and rodName ~= "" then
        condEquippedRod = string.format("[equipped:%s,nomod][equipped:Fishing Pole,nomod]", rodName)
    end

    -- Direct #showtooltip with Fishing so the macro icon displays the Fishing spell & its cast time
    table.insert(lines, string.format("#showtooltip %s %s", condEquippedRod, spellName))

    if offName and offName ~= "" then
        table.insert(lines, string.format("/equipslot %s 16 %s", condEquippedRod, mainName or ""))
        table.insert(lines, string.format("/equipslot %s 17 %s", condEquippedRod, offName))
    elseif mainName and mainName ~= "" then
        table.insert(lines, string.format("/equip %s %s", condEquippedRod, mainName))
    end

    if rodName and rodName ~= "" then
        table.insert(lines, string.format("/equip [noequipped:%s] %s", rodName, rodName))
    end

    table.insert(lines, "/cast [mod:shift] Fishing")
    return table.concat(lines, "\n")
end

local function UpdateMacro()
    if InCombatLockdown() then
        pendingMacroUpdate = true
        return
    end

    local db = GetDB()
    local rodName, rodID = FindFishingRod()
    if rodName then
        db.lastRodName = rodName
        db.lastRodID = rodID
    else
        rodName = db.lastRodName
    end

    UpdateStoredWeapons()

    local mainName = db.lastMainHand
    local offName = db.lastOffHand

    if not rodName and not mainName then return end

    local macroBody = BuildMacroBody(rodName, mainName, offName)
    secureBtn:SetAttribute("macrotext", macroBody)

    local macroIndex = GetMacroIndexByName("FishSwap")
    local icon = GetResolvedFishingIcon(false)

    if macroIndex > 0 then
        EditMacro(macroIndex, "FishSwap", icon, macroBody)
    else
        local numGlobal, numPerChar = GetNumMacros()
        if numPerChar < 18 then
            CreateMacro("FishSwap", icon, macroBody, 1)
        elseif numGlobal < 120 then
            CreateMacro("FishSwap", icon, macroBody, nil)
        end
    end
end

-- -------------------------------------------------------------------------
-- Single-Click Cast & Click-Anywhere Reel in (Only When Fishing Mode Active)
-- -------------------------------------------------------------------------
local isChannelingFishing = false
local lastRightClickTime = 0
local savedCVarSound, savedCVarBG
local activeBindingMode = "NONE" -- "NONE", "CAST", "ARMED", "REEL"
local doubleClickTimer = nil

local reelButton = CreateFrame("Button", "TF_FishingReelButton", UIParent, "SecureActionButtonTemplate")
reelButton:EnableMouse(false)
reelButton:RegisterForClicks("AnyUp", "AnyDown")

local castButton = CreateFrame("Button", "TF_FishingCastButton", UIParent, "SecureActionButtonTemplate")
castButton:EnableMouse(false)
castButton:RegisterForClicks("AnyUp", "AnyDown")
castButton:SetAttribute("type", "macro")
castButton:SetAttribute("macrotext", "/cast Fishing")

local function UpdateCastButtonSpell()
    if InCombatLockdown() then return end
    local spellName = GetFishingSpellName() or "Fishing"
    local macro = "/cast " .. spellName
    castButton:SetAttribute("type", "macro")
    castButton:SetAttribute("macrotext", macro)
    castButton:SetAttribute("type1", "macro")
    castButton:SetAttribute("macrotext1", macro)
    castButton:SetAttribute("type2", "macro")
    castButton:SetAttribute("macrotext2", macro)
end

local function IsCursorOverWorldFrame()
    if _G.GetMouseFoci then
        local foci = _G.GetMouseFoci()
        if foci and foci[1] then
            local top = foci[1]
            return top == _G.WorldFrame or (top.GetName and top:GetName() == "WorldFrame")
        end
        return true
    end
    if _G.GetMouseFocus then
        local focus = _G.GetMouseFocus()
        return focus == _G.WorldFrame or (focus and focus.GetName and focus:GetName() == "WorldFrame") or focus == nil
    end
    if _G.WorldFrame and _G.WorldFrame.IsMouseMotionFocus then
        return _G.WorldFrame:IsMouseMotionFocus()
    end
    return true
end

local function CanFishRightNow(db)
    if InCombatLockdown() then return false end
    if not db.enabled or not IsFishingPoleEquipped() then return false end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false end
    if IsMounted and IsMounted() then return false end
    if UnitOnTaxi and UnitOnTaxi("player") then return false end
    if GetUnitSpeed("player") > 0 then return false end
    if UnitExists("mouseover") then return false end
    if _G.LootFrame and _G.LootFrame:IsShown() then return false end
    if not IsCursorOverWorldFrame() then return false end
    return true
end

local function UpdateFishingClickBinding()
    if InCombatLockdown() then return end

    local db = GetDB()

    -- 1. If helper disabled or rod not equipped:
    if not db.enabled or not IsFishingPoleEquipped() then
        if activeBindingMode ~= "NONE" then
            activeBindingMode = "NONE"
            if doubleClickTimer then doubleClickTimer:Cancel(); doubleClickTimer = nil end
            lastRightClickTime = 0
            ClearOverrideBindings(reelButton)
        end
        return
    end

    -- 2. If actively channeling fishing:
    if isChannelingFishing then
        local desiredReel = false
        if db.enableClickAnywhereReel then
            local overWorld = IsCursorOverWorldFrame()
            local lootOpen = _G.LootFrame and _G.LootFrame:IsShown()
            if overWorld and not lootOpen then
                desiredReel = true
            end
        end

        local desiredMode = desiredReel and "REEL" or "NONE"
        if desiredMode ~= activeBindingMode then
            activeBindingMode = desiredMode
            ClearOverrideBindings(reelButton)
            if desiredMode == "REEL" then
                SetOverrideBinding(reelButton, true, "BUTTON2", "INTERACTTARGET")
            end
        end
        return
    end

    -- 3. If Double-Click mode is active:
    if db.enableSingleClick == false and db.enableDoubleClick then
        -- In double click mode, the binding is only active during the ARMED window.
        -- If player moved or hovered an invalid target, cancel ARMED:
        if activeBindingMode == "ARMED" then
            if not CanFishRightNow(db) then
                activeBindingMode = "NONE"
                if doubleClickTimer then doubleClickTimer:Cancel(); doubleClickTimer = nil end
                lastRightClickTime = 0
                ClearOverrideBindings(reelButton)
            end
        end
        return
    end

    -- 4. Single-Click mode (default):
    local desiredMode = CanFishRightNow(db) and "CAST" or "NONE"
    if desiredMode ~= activeBindingMode then
        activeBindingMode = desiredMode
        ClearOverrideBindings(reelButton)
        if desiredMode == "CAST" then
            UpdateCastButtonSpell()
            SetOverrideBindingClick(reelButton, true, "BUTTON2", "TF_FishingCastButton")
        end
    end
end

local function SetupRetailSoftInteract()
    -- Enable SoftTargetInteract for bobber
    pcall(function()
        if SetCVar then
            SetCVar("SoftTargetInteract", "3")
            SetCVar("SoftTargetInteractArc", "2")
            SetCVar("SoftTargetInteractRange", "30")
        end
    end)
end

local StartCastTimer, StopCastTimer, UpdateCastTimerDisplay

local function StartFishingChannel()
    isChannelingFishing = true
    if doubleClickTimer then doubleClickTimer:Cancel(); doubleClickTimer = nil end
    lastRightClickTime = 0
    SetupRetailSoftInteract()

    local db = GetDB()
    if db.enableSoundBoost then
        savedCVarSound = GetCVar("Sound_EnableSFX")
        savedCVarBG = GetCVar("Sound_EnableSoundWhenGameIsInBG")
        pcall(function()
            SetCVar("Sound_EnableSFX", "1")
            SetCVar("Sound_EnableSoundWhenGameIsInBG", "1")
        end)
    end

    if StartCastTimer then
        StartCastTimer()
    end

    if not InCombatLockdown() then
        if db.enableClickAnywhereReel then
            activeBindingMode = "REEL"
            ClearOverrideBindings(reelButton)
            SetOverrideBinding(reelButton, true, "BUTTON2", "INTERACTTARGET")
        else
            activeBindingMode = "NONE"
            ClearOverrideBindings(reelButton)
        end
    end
end

local function StopFishingChannel()
    if not isChannelingFishing then return end
    isChannelingFishing = false

    if StopCastTimer then
        StopCastTimer()
    end

    local db = GetDB()
    if db.enableSoundBoost then
        pcall(function()
            if savedCVarSound ~= nil then SetCVar("Sound_EnableSFX", savedCVarSound) end
            if savedCVarBG ~= nil then SetCVar("Sound_EnableSoundWhenGameIsInBG", savedCVarBG) end
        end)
        savedCVarSound = nil
        savedCVarBG = nil
    end

    if not InCombatLockdown() then
        activeBindingMode = "NONE"
        ClearOverrideBindings(reelButton)
    end

    UpdateFishingClickBinding()
end

-- Global mouse handling & periodic state check for Single-Click / Double-Click Cast
local mouseFrame = CreateFrame("Frame")
mouseFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
mouseFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
mouseFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
local elapsedAccum = 0
mouseFrame:SetScript("OnUpdate", function(self, elapsed)
    if UpdateCastTimerDisplay then
        UpdateCastTimerDisplay(elapsed)
    end
    elapsedAccum = elapsedAccum + elapsed
    if elapsedAccum >= 0.08 then
        elapsedAccum = 0
        UpdateFishingClickBinding()
    end
end)
mouseFrame:SetScript("OnEvent", function(self, event, buttonName)
    if event == "PLAYER_REGEN_DISABLED" then
        activeBindingMode = "NONE"
        if doubleClickTimer then doubleClickTimer:Cancel(); doubleClickTimer = nil end
        lastRightClickTime = 0
        if not InCombatLockdown() then
            ClearOverrideBindings(reelButton)
        end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateFishingClickBinding()
        return
    end

    if event == "GLOBAL_MOUSE_DOWN" and buttonName == "RightButton" then
        local db = GetDB()
        if not db.enabled or InCombatLockdown() or not IsFishingPoleEquipped() then return end
        if isChannelingFishing then return end -- In channel, REEL binding handles it!

        -- Double-Click mode branch:
        if db.enableSingleClick == false and db.enableDoubleClick then
            if not CanFishRightNow(db) then return end

            local now = GetTime()
            local delay = db.doubleClickDelay or 0.4

            if activeBindingMode == "ARMED" and lastRightClickTime > 0 and (now - lastRightClickTime < delay) then
                -- This is the SECOND click! The binding was already ARMED, so BUTTON2 is already bound to TF_FishingCastButton!
                -- Blizzard's input engine triggers TF_FishingCastButton right now!
                if doubleClickTimer then doubleClickTimer:Cancel(); doubleClickTimer = nil end
                lastRightClickTime = 0
                -- Reset after cast begins or timeout
                C_Timer.After(0.3, function()
                    if not isChannelingFishing and activeBindingMode == "ARMED" and not InCombatLockdown() then
                        activeBindingMode = "NONE"
                        ClearOverrideBindings(reelButton)
                    end
                end)
            else
                -- This is the FIRST click! Arm the override binding for the second click:
                lastRightClickTime = now
                activeBindingMode = "ARMED"
                UpdateCastButtonSpell()
                ClearOverrideBindings(reelButton)
                SetOverrideBindingClick(reelButton, true, "BUTTON2", "TF_FishingCastButton")

                if doubleClickTimer then doubleClickTimer:Cancel() end
                doubleClickTimer = C_Timer.NewTimer(delay, function()
                    if activeBindingMode == "ARMED" and not isChannelingFishing and not InCombatLockdown() then
                        activeBindingMode = "NONE"
                        ClearOverrideBindings(reelButton)
                    end
                    lastRightClickTime = 0
                    doubleClickTimer = nil
                end)
            end
        else
            -- Single-click mode:
            UpdateFishingClickBinding()
        end
    end
end)

-- -------------------------------------------------------------------------
-- Floating FishingTime Toggle Icon
-- -------------------------------------------------------------------------
local floatingIcon = CreateFrame("Button", "TimelessForever_FishingIcon", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
floatingIcon:SetSize(36, 36)
floatingIcon:SetFrameStrata("MEDIUM")
floatingIcon:SetFrameLevel(55)
floatingIcon:SetClampedToScreen(true)
floatingIcon:SetMovable(true)
floatingIcon:EnableMouse(true)

if floatingIcon.SetBackdrop then
    floatingIcon:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    floatingIcon:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    floatingIcon:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.9)
else
    local iconBg = floatingIcon:CreateTexture(nil, "BACKGROUND")
    iconBg:SetAllPoints()
    iconBg:SetColorTexture(0, 0, 0, 0.7)
end

local iconTex = floatingIcon:CreateTexture(nil, "ARTWORK")
iconTex:SetPoint("TOPLEFT", floatingIcon, "TOPLEFT", 2, -2)
iconTex:SetPoint("BOTTOMRIGHT", floatingIcon, "BOTTOMRIGHT", -2, 2)
iconTex:SetTexture("Interface\\Icons\\Trade_Fishing")
iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local highlight = floatingIcon:CreateTexture(nil, "HIGHLIGHT")
highlight:SetPoint("TOPLEFT", floatingIcon, "TOPLEFT", 2, -2)
highlight:SetPoint("BOTTOMRIGHT", floatingIcon, "BOTTOMRIGHT", -2, 2)
highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
highlight:SetBlendMode("ADD")

local iconCooldown = CreateFrame("Cooldown", "TimelessForever_FishingIconCooldown", floatingIcon, "CooldownFrameTemplate")
iconCooldown:SetPoint("TOPLEFT", floatingIcon, "TOPLEFT", 2, -2)
iconCooldown:SetPoint("BOTTOMRIGHT", floatingIcon, "BOTTOMRIGHT", -2, 2)
iconCooldown:SetDrawEdge(true)
iconCooldown:SetDrawSwipe(true)
iconCooldown:SetReverse(true)
iconCooldown:Hide()

local castTimerText = floatingIcon:CreateFontString(nil, "OVERLAY")
castTimerText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
castTimerText:SetPoint("CENTER", floatingIcon, "CENTER", 0, 0)
castTimerText:SetTextColor(1, 0.95, 0.2, 1)
castTimerText:SetShadowColor(0, 0, 0, 1)
castTimerText:SetShadowOffset(1, -1)
castTimerText:Hide()

local castBar = CreateFrame("StatusBar", "TimelessForever_FishingCastBar", floatingIcon)
castBar:SetPoint("TOPLEFT", floatingIcon, "BOTTOMLEFT", 0, -2)
castBar:SetPoint("TOPRIGHT", floatingIcon, "BOTTOMRIGHT", 0, -2)
castBar:SetHeight(4)
castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
castBar:SetStatusBarColor(0.2, 0.85, 1.0, 0.95)
castBar:SetMinMaxValues(0, 1)
castBar:SetValue(0)
castBar:Hide()

local castBarBg = castBar:CreateTexture(nil, "BACKGROUND")
castBarBg:SetAllPoints()
castBarBg:SetColorTexture(0, 0, 0, 0.7)

local channelEndTime = 0
local channelDuration = 0

StartCastTimer = function()
    local name, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player")
    if startTimeMS and endTimeMS and endTimeMS > startTimeMS then
        channelDuration = (endTimeMS - startTimeMS) / 1000
        channelEndTime = endTimeMS / 1000
        local startTime = startTimeMS / 1000
        iconCooldown:SetCooldown(startTime, channelDuration)
        iconCooldown:Show()
        castTimerText:Show()
        castBar:SetMinMaxValues(0, channelDuration)
        castBar:SetValue(channelDuration)
        castBar:Show()
    else
        channelDuration = 20
        channelEndTime = GetTime() + 20
        iconCooldown:SetCooldown(GetTime(), 20)
        iconCooldown:Show()
        castTimerText:Show()
        castBar:SetMinMaxValues(0, 20)
        castBar:SetValue(20)
        castBar:Show()
    end
end

StopCastTimer = function()
    channelEndTime = 0
    channelDuration = 0
    castTimerText:Hide()
    castBar:Hide()
    iconCooldown:Clear()
    iconCooldown:Hide()
end

UpdateCastTimerDisplay = function(elapsed)
    if isChannelingFishing and channelEndTime and channelEndTime > 0 then
        local remain = channelEndTime - GetTime()
        if remain > 0 then
            castTimerText:SetText(string.format("%.1f", remain))
            castBar:SetValue(remain)
        else
            StopCastTimer()
        end
    end
end

local function RestoreIconPosition()
    if _G.TimelessForever_ButtonBar then
        return
    end
    local db = GetDB()
    floatingIcon:ClearAllPoints()
    if db.iconPos and db.iconPos.x and db.iconPos.y then
        floatingIcon:SetPoint(
            db.iconPos.point or "CENTER",
            UIParent,
            db.iconPos.relativePoint or "CENTER",
            db.iconPos.x,
            db.iconPos.y
        )
    else
        floatingIcon:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
end

local function UpdateIconVisual()
    local db = GetDB()
    iconTex:SetTexture("Interface\\Icons\\" .. GetResolvedFishingIcon(true))
    if db.showIcon == false then
        floatingIcon:Hide()
    else
        floatingIcon:Show()
    end
    if db.enabled then
        iconTex:SetDesaturated(false)
        floatingIcon:SetAlpha(1.0)
        if floatingIcon.SetBackdropBorderColor then
            floatingIcon:SetBackdropBorderColor(0.0, 0.85, 0.4, 0.9)
        end
    else
        iconTex:SetDesaturated(true)
        floatingIcon:SetAlpha(0.55)
        if floatingIcon.SetBackdropBorderColor then
            floatingIcon:SetBackdropBorderColor(0.35, 0.35, 0.4, 0.8)
        end
    end
    UpdateFishingClickBinding()
end

-- Shift + Left Click & Drag to move Bar smoothly
floatingIcon:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() then
        if _G.TimelessForever_ButtonBar and _G.TimelessForever_ButtonBar.frame then
            local bar = _G.TimelessForever_ButtonBar.frame
            if not (_G.TimelessForever_ButtonBarDB and _G.TimelessForever_ButtonBarDB.locked) then
                bar:StartMoving()
                bar.isDragging = true
                self.isBarMoving = true
            end
        else
            self:StartMoving()
            self.isMoving = true
        end
    end
end)

floatingIcon:SetScript("OnMouseUp", function(self, button)
    if self.isBarMoving then
        local bar = _G.TimelessForever_ButtonBar.frame
        bar:StopMovingOrSizing()
        bar.isDragging = false
        self.isBarMoving = false
        if _G.TimelessForever_ButtonBar.SavePosition then
            _G.TimelessForever_ButtonBar:SavePosition()
        end
        return
    end
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        local db = GetDB()
        db.iconPos = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = x or 0,
            y = y or 100,
        }
        return
    end

    local db = GetDB()
    if button == "RightButton" then
        -- Right click swaps weapon/rod
        if not InCombatLockdown() then
            UpdateMacro()
            secureBtn:Click()
        end
    elseif button == "LeftButton" then
        -- Left click toggles fishing mode
        db.enabled = not db.enabled
        UpdateIconVisual()
        print(string.format("|cff00ccff[Fishing]|r Mode is now %s", db.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
    end
end)

floatingIcon:SetScript("OnEnter", function(self)
    if not InCombatLockdown() then
        activeBindingMode = "NONE"
        if doubleClickTimer then doubleClickTimer:Cancel(); doubleClickTimer = nil end
        lastRightClickTime = 0
        ClearOverrideBindings(reelButton)
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cff00ccffFishing|r", 1, 1, 1)
    local db = GetDB()
    local modeDesc = db.enableSingleClick ~= false and "Single-Click Cast & Reel" or (db.enableDoubleClick and "Double-Click Cast, Click-to-Reel" or "Manual")
    GameTooltip:AddLine(db.enabled and string.format("|cff00ff00Fishing Mode Active (%s)|r", modeDesc) or "|cffff0000Fishing Mode Inactive|r", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Fishing Mode", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cffffffffRight-Click:|r Quick-Swap Rod/Weapon", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cffffffffShift + Drag:|r Move Bar", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    if db.enableSingleClick ~= false then
        GameTooltip:AddLine("|cff00ff00Single-Click Fishing:|r When Fishing Mode is Active, single right-click anywhere in the world to cast & reel in!", 0.2, 1, 0.2, true)
    else
        GameTooltip:AddLine("|cff00ff00Double-Click Fishing:|r When Fishing Mode is Active, double right-click anywhere to cast, single right-click to reel in!", 0.2, 1, 0.2, true)
    end
    GameTooltip:Show()
end)
floatingIcon:SetScript("OnLeave", function()
    GameTooltip:Hide()
    UpdateFishingClickBinding()
end)

-- Register with TimelessForever Button Bar
if _G.TimelessForever_ButtonBar then
    _G.TimelessForever_ButtonBar:RegisterButton("fishing", floatingIcon, 3, 36, 36)
end

-- -------------------------------------------------------------------------
-- Suite Hub Integration
-- -------------------------------------------------------------------------
local function BuildFishingOptions()
    local db = GetDB()
    return {
        header = {
            name = "|TInterface\\Icons\\Trade_Fishing:14:14:0:0|t |cff00ccffFishing|r",
            type = "header",
            order = 1,
        },
        desc = {
            name = "When Fishing Mode is Active with a fishing pole equipped, single right-click anywhere in the world to cast and single right-click to reel in! Use the |cffffd100FishSwap|r macro or floating button to swap between your weapon and fishing pole.\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },
        enabled = {
            name = "Enable Fishing Helper (Fishing Mode Active)",
            desc = "Enable single-click casting and click-anywhere reeling when holding a fishing pole.",
            type = "toggle",
            order = 10,
            get = function() return GetDB().enabled end,
            set = function(_, val)
                GetDB().enabled = val
                UpdateIconVisual()
            end,
        },
        showIcon = {
            name = "Show Floating Fishing Button",
            desc = "Show or hide the floating on-screen fishing toggle & rod-swap button.",
            type = "toggle",
            order = 11,
            get = function() return GetDB().showIcon ~= false end,
            set = function(_, val)
                GetDB().showIcon = val
                UpdateIconVisual()
            end,
        },
        resetIcon = {
            name = "Reset Floating Icon Position",
            desc = "Move the floating fishing button back to the center of the screen.",
            type = "execute",
            order = 12,
            func = function()
                GetDB().iconPos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 100 }
                RestoreIconPosition()
            end,
        },
        behaviorHeader = {
            name = "Casting & Reeling Behavior",
            type = "header",
            order = 20,
        },
        enableSingleClick = {
            name = "Single Right-Click to Cast & Reel (Recommended)",
            desc = "When Fishing Mode is Active and your fishing pole is equipped, a single right-click anywhere in the world casts Fishing, and single right-click reels in when the bobber splashes.",
            type = "toggle",
            width = "full",
            order = 20.5,
            get = function() return GetDB().enableSingleClick ~= false end,
            set = function(_, val)
                local db = GetDB()
                db.enableSingleClick = val
                db.enableDoubleClick = not val
                UpdateFishingClickBinding()
                NotifyOptionsChange()
            end,
        },
        enableDoubleClick = {
            name = "Double Right-Click to Cast (Classic Double-Click)",
            desc = "Require a double right-click anywhere in the world to cast Fishing. Reeling in still only requires a single right-click.",
            type = "toggle",
            width = "full",
            order = 21,
            get = function() return GetDB().enableDoubleClick == true and GetDB().enableSingleClick == false end,
            set = function(_, val)
                local db = GetDB()
                db.enableDoubleClick = val
                db.enableSingleClick = not val
                UpdateFishingClickBinding()
                NotifyOptionsChange()
            end,
        },
        doubleClickDelay = {
            name = "Double-Click Window (Seconds)",
            desc = "Maximum time between right-clicks to trigger a cast when Double-Click mode is active.",
            type = "range",
            order = 22,
            min = 0.2,
            max = 0.8,
            step = 0.05,
            disabled = function() return GetDB().enableSingleClick ~= false end,
            get = function() return GetDB().doubleClickDelay or 0.4 end,
            set = function(_, val) GetDB().doubleClickDelay = val end,
        },
        enableClickAnywhereReel = {
            name = "Single Click-Anywhere Reel In",
            desc = "While channeling Fishing, single right-click anywhere to interact with the bobber and reel in.",
            type = "toggle",
            order = 23,
            get = function() return GetDB().enableClickAnywhereReel end,
            set = function(_, val)
                GetDB().enableClickAnywhereReel = val
                UpdateFishingClickBinding()
            end,
        },
        enableSoundBoost = {
            name = "Boost Sound Effects While Fishing",
            desc = "Temporarily ensure Sound Effects and Background Sound are enabled while channeling Fishing so you never miss the bobber splash.",
            type = "toggle",
            order = 24,
            get = function() return GetDB().enableSoundBoost end,
            set = function(_, val) GetDB().enableSoundBoost = val end,
        },
        macroHeader = {
            name = "Weapon & Rod Swap Macro ('FishSwap') & Icons",
            type = "header",
            order = 30,
        },
        fishingIconSelect = {
            name = "Fishing Swap Icon (All Fishing Icons)",
            desc = "Choose from all World of Warcraft fishing icons (poles, hooks, lures, hats, tackle boxes, and fish) for your 'FishSwap' macro and floating fishing button.",
            type = "select",
            width = "double",
            order = 31,
            values = FISHING_ICON_OPTIONS,
            get = function()
                return GetDB().fishingIcon or "INV_Fishingpole_02"
            end,
            set = function(_, val)
                local d = GetDB()
                d.fishingIcon = val
                if val == "DYNAMIC_TOOLTIP" then
                    d.macroShowTooltip = true
                else
                    d.macroShowTooltip = false
                end
                UpdateIconVisual()
                UpdateMacro()
            end,
        },
        customFishingIcon = {
            name = "Custom Icon Name (if Custom selected)",
            desc = "Enter any WoW icon texture name (e.g. INV_Fishingpole_03 or Trade_Fishing).",
            type = "input",
            width = "normal",
            order = 32,
            get = function()
                return GetDB().customFishingIcon or ""
            end,
            set = function(_, val)
                local d = GetDB()
                d.customFishingIcon = strtrim(val or "")
                d.fishingIcon = "CUSTOM"
                d.macroShowTooltip = false
                UpdateIconVisual()
                UpdateMacro()
            end,
        },
        macroShowTooltip = {
            name = "Override Action Bar Icon with Equipped Weapon/Rod (#showtooltip)",
            desc = "When enabled, adds #showtooltip so your action bar dynamically shows your equipped weapon or fishing pole icon instead of the selected Fishing Icon above.",
            type = "toggle",
            width = "full",
            order = 33,
            get = function()
                local d = GetDB()
                return d.fishingIcon == "DYNAMIC_TOOLTIP" or (d.macroShowTooltip == true)
            end,
            set = function(_, val)
                local d = GetDB()
                d.macroShowTooltip = val and true or false
                if not val and d.fishingIcon == "DYNAMIC_TOOLTIP" then
                    d.fishingIcon = "INV_Fishingpole_02"
                end
                UpdateIconVisual()
                UpdateMacro()
            end,
        },
        updateMacroBtn = {
            name = "Create / Update 'FishSwap' Macro",
            desc = "Scans your bags and equipped weapons and updates the FishSwap macro with your chosen icon.",
            type = "execute",
            order = 34,
            func = function()
                UpdateIconVisual()
                UpdateMacro()
                print("|cff00ccff[TimelessForever Fishing]|r 'FishSwap' macro and icon updated.")
            end,
        },
    }
end

local function RegisterWithSuiteHub()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        pcall(function()
            suite:RegisterModuleTab("fishing", "Fishing", 7, BuildFishingOptions())
        end)
    end
end

local function NotifyOptionsChange()
    local LibStub = _G.LibStub
    if LibStub then
        local reg = LibStub("AceConfigRegistry-3.0", true)
        if reg then
            pcall(reg.NotifyChange, reg, "TimelessForever")
            pcall(reg.NotifyChange, reg, "Timeless")
        end
    end
end

local function SyncFishingHelperWithRod(announce)
    local db = GetDB()
    local rodEquipped = IsFishingPoleEquipped()
    if db.enabled ~= rodEquipped then
        db.enabled = rodEquipped
        if not rodEquipped then
            StopFishingChannel()
        end
        UpdateIconVisual()
        NotifyOptionsChange()
        if announce then
            print(string.format("|cff00ccff[TimelessForever Fishing]|r Enable Fishing Helper: %s", db.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
        end
    else
        UpdateIconVisual()
        NotifyOptionsChange()
    end
end

-- -------------------------------------------------------------------------
-- Main Event Listener
-- -------------------------------------------------------------------------
FishingApp:RegisterEvent("ADDON_LOADED")
FishingApp:RegisterEvent("PLAYER_LOGIN")
FishingApp:RegisterEvent("PLAYER_ENTERING_WORLD")
FishingApp:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
FishingApp:RegisterEvent("BAG_UPDATE_DELAYED")
FishingApp:RegisterEvent("BAG_UPDATE")
FishingApp:RegisterEvent("PLAYER_REGEN_ENABLED")
FishingApp:RegisterEvent("GET_ITEM_INFO_RECEIVED")
FishingApp:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
FishingApp:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
FishingApp:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
FishingApp:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
FishingApp:RegisterEvent("UNIT_SPELLCAST_FAILED")

local function IsFishingChannel()
    local name, _, _, _, _, _, _, spellId = UnitChannelInfo("player")
    if not name then return false end
    local fishingName = GetFishingSpellName()
    if name == fishingName or name == "Fishing" then
        return true
    end
    if spellId then
        for _, id in ipairs(FISHING_SPELL_IDS) do
            if spellId == id then return true end
        end
    end
    if string.find(string.lower(name), "fish") or (fishingName and string.find(string.lower(name), string.lower(fishingName))) then
        return true
    end
    return false
end

FishingApp:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
        RestoreIconPosition()
        UpdateIconVisual()
        SetupRetailSoftInteract()
        UpdateCastButtonSpell()
        UpdateMacro()
        if event == "PLAYER_LOGIN" then
            SyncFishingHelperWithRod(false)
            RegisterWithSuiteHub()
            C_Timer.After(0.5, RegisterWithSuiteHub)
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        if arg1 == "player" then
            if IsFishingChannel() then
                StartFishingChannel()
            end
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        if arg1 == "player" then
            if isChannelingFishing then
                -- For CHANNEL_UPDATE, verify if still channeling
                if event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
                    if not IsFishingChannel() then
                        StopFishingChannel()
                    end
                else
                    StopFishingChannel()
                end
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingMacroUpdate then
            pendingMacroUpdate = false
            UpdateMacro()
        end
        UpdateFishingClickBinding()

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if arg1 == 16 or arg1 == 17 then
            UpdateMacro()
            if arg1 == 16 then
                SyncFishingHelperWithRod(true)
            end
        end

    elseif event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "GET_ITEM_INFO_RECEIVED" then
        UpdateMacro()
        UpdateCastButtonSpell()
    end
end)

-- -------------------------------------------------------------------------
-- Slash Commands
-- -------------------------------------------------------------------------
SLASH_TF_FISHING1 = "/fishingtime"
SLASH_TF_FISHING2 = "/fishing"
SLASH_TF_FISHING3 = "/fish"
SLASH_TF_FISHING4 = "/fishswap"
SLASH_TF_FISHING5 = "/tffish"

SlashCmdList["TF_FISHING"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)%s*$") or ""
    local db = GetDB()
    if cmd == "reset" then
        db.iconPos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 100 }
        db.showIcon = true
        RestoreIconPosition()
        UpdateIconVisual()
        print("|cff00ccff[TimelessForever Fishing]|r Floating icon position reset to screen center!")
        return
    elseif cmd == "icon" or cmd == "hide" or cmd == "show" then
        if cmd == "hide" then
            db.showIcon = false
        elseif cmd == "show" then
            db.showIcon = true
        else
            db.showIcon = (db.showIcon == false)
        end
        UpdateIconVisual()
        print("|cff00ccff[TimelessForever Fishing]|r Floating icon " .. (db.showIcon and "|cff00ff00SHOWN|r" or "|cffff3333HIDDEN|r") .. ".")
        return
    elseif cmd == "config" or cmd == "options" or cmd == "opt" or cmd == "settings" then
        local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
        if suite and suite.OpenSettings then
            suite:OpenSettings("fishing")
            return
        end
    end

    UpdateMacro()
    local rod = db.lastRodName or "|cffff0000None found in bags|r"
    local main = db.lastMainHand or "|cffff0000None recorded|r"
    local off = db.lastOffHand or "|cff888888None|r"
    local castModeStr = db.enableSingleClick ~= false and "|cff00ff00Single Right-Click|r" or (db.enableDoubleClick and "|cff00ff00Double Right-Click|r" or "|cffff0000Disabled|r")

    print("|cff00ccff===== TimelessForever Fishing =====|r")
    print("  |cff00ff00Detected Rod:|r " .. rod)
    print("  |cff00ff00Saved Main Hand:|r " .. main)
    print("  |cff00ff00Saved Off Hand:|r " .. off)
    print("  |cffffff00Casting Mode:|r " .. castModeStr)
    print("  |cffffff00Click-to-Reel:|r " .. (db.enableClickAnywhereReel and "|cff00ff00ACTIVE|r (Right-click anywhere to reel in!)" or "|cffff0000Disabled|r"))
    print("  |cffaaaaaaCommands: /fishing icon (toggle button), /fishing reset, /fishing config|r")
end

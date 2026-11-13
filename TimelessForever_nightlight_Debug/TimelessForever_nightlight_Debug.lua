-- =========================================================================
-- TimelessForever: Nightlight Debug & Testing Panel
-- Part of the Timeless / Typeless Forever Suite
--
-- Standalone debugging tool for TimelessForever_nightlight.
-- Allows simulating any progression tier and testing all 9 class behaviors
-- in real-time without modifying saved character flags.
-- =========================================================================

local ADDON_NAME = ...
local DebugApp = CreateFrame("Frame", "TimelessForever_NightlightDebugApp", UIParent)

local function GetAPI()
    return _G.TimelessForever_NightlightDebugAPI
end

-- -------------------------------------------------------------------------
-- Debug Window Creation
-- -------------------------------------------------------------------------
local debugFrame = CreateFrame("Frame", "NightlightDebugFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
debugFrame:SetSize(490, 520)
debugFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
debugFrame:SetFrameStrata("DIALOG")
debugFrame:SetMovable(true)
debugFrame:EnableMouse(true)
debugFrame:RegisterForDrag("LeftButton")
debugFrame:SetScript("OnDragStart", debugFrame.StartMoving)
debugFrame:SetScript("OnDragStop", debugFrame.StopMovingOrSizing)
debugFrame:Hide()

if debugFrame.SetBackdrop then
    debugFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    debugFrame:SetBackdropColor(0.06, 0.08, 0.12, 0.96)
    debugFrame:SetBackdropBorderColor(0.0, 0.80, 1.0, 0.9)
end

local dbgTitle = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
dbgTitle:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 16, -14)
dbgTitle:SetText("|cff00ccffNightlight|r Debug & Class Testing Panel")

local dbgSub = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dbgSub:SetPoint("TOPLEFT", dbgTitle, "BOTTOMLEFT", 0, -3)
dbgSub:SetText("|cffaaaaaaIn-memory simulation — test tiers & classes without altering saved data|r")

local closeBtn = CreateFrame("Button", nil, debugFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", debugFrame, "TOPRIGHT", -6, -6)

-- Checkbox creation helper
local function CreateDebugCheckbox(label, xOffset, yOffset, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, debugFrame, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", xOffset, yOffset)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.text:SetText(label)
    cb:SetScript("OnClick", function(self)
        setFunc(self:GetChecked())
    end)
    cb:SetScript("OnShow", function(self)
        self:SetChecked(getFunc())
    end)
    return cb
end

-- Row 1: T1 & T2
local cbT1 = CreateDebugCheckbox("Tier 1: Basic Light (Lvl 4+)", 16, -56,
    function() local api = GetAPI(); return api and api.GetTierUnlocked(1) end,
    function(val) local api = GetAPI(); if api then api.SetTierOverride(1, val) end end
)

local cbT2 = CreateDebugCheckbox("Tier 2: Health Dimming (Lvl 10+)", 250, -56,
    function() local api = GetAPI(); return api and api.GetTierUnlocked(2) end,
    function(val) local api = GetAPI(); if api then api.SetTierOverride(2, val) end end
)

-- Row 2: T3 & T4
local cbT3 = CreateDebugCheckbox("Tier 3: Aggro Warning (Lvl 14+)", 16, -82,
    function() local api = GetAPI(); return api and api.GetTierUnlocked(3) end,
    function(val) local api = GetAPI(); if api then api.SetTierOverride(3, val) end end
)

local cbT4 = CreateDebugCheckbox("Tier 4: Class Behaviors (Lvl 20+)", 250, -82,
    function() local api = GetAPI(); return api and api.GetTierUnlocked(4) end,
    function(val) local api = GetAPI(); if api then api.SetTierOverride(4, val) end end
)

-- Row 3: Force Night & Simulate Aggro
local cbNight = CreateDebugCheckbox("Force Night (Simulate Darkness)", 16, -108,
    function() local api = GetAPI(); return api and api.GetNightOverride() == true end,
    function(val) local api = GetAPI(); if api then api.SetNightOverride(val and true or nil) end end
)

local cbForceAggro = CreateDebugCheckbox("Simulate Aggro (Red Center)", 250, -108,
    function() local api = GetAPI(); return api and api.GetForceAggro() == true end,
    function(val) local api = GetAPI(); if api then api.SetForceAggro(val and true or nil) end end
)

-- Row 4: Center Bloom Slider (dedicated row)
local bloomSlider = CreateFrame("Slider", "NightlightDebugBloomSlider", debugFrame, "OptionsSliderTemplate")
bloomSlider:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 30, -152)
bloomSlider:SetSize(430, 16)
bloomSlider:SetMinMaxValues(0.0, 1.0)
bloomSlider:SetValueStep(0.05)
if bloomSlider.SetObeyStepOnDrag then bloomSlider:SetObeyStepOnDrag(true) end
local sLow = _G[bloomSlider:GetName() .. "Low"]
local sHigh = _G[bloomSlider:GetName() .. "High"]
local sText = _G[bloomSlider:GetName() .. "Text"]
if sLow then sLow:SetText("0% (Extinguished)") end
if sHigh then sHigh:SetText("100% (Blinding)") end
if sText then sText:SetText("Center Bloom: 20%") end

bloomSlider:SetScript("OnValueChanged", function(self, val)
    val = math.floor(val * 100 + 0.5) / 100
    local api = GetAPI()
    if api and api.GetDB then
        local db = api.GetDB()
        db.coreBloom = val
        db.coreAlpha = val
        api.UpdateNightlightState()
    end
    local txt = _G[self:GetName() .. "Text"]
    if txt then txt:SetText(string.format("Center Bloom: %d%%", math.floor(val * 100))) end
end)

bloomSlider:SetScript("OnShow", function(self)
    local api = GetAPI()
    local val = 0.20
    if api and api.GetDB then
        local db = api.GetDB()
        val = db.coreBloom or 0.20
    end
    self:SetValue(val)
    local txt = _G[self:GetName() .. "Text"]
    if txt then txt:SetText(string.format("Center Bloom: %d%%", math.floor(val * 100))) end
end)

local function RefreshDebugCheckboxes()
    local api = GetAPI()
    if not api then return end
    cbT1:SetChecked(api.GetTierUnlocked(1))
    cbT2:SetChecked(api.GetTierUnlocked(2))
    cbT3:SetChecked(api.GetTierUnlocked(3))
    cbT4:SetChecked(api.GetTierUnlocked(4))
    cbNight:SetChecked(api.GetNightOverride() == true)
    if cbForceAggro and api.GetForceAggro then
        cbForceAggro:SetChecked(api.GetForceAggro() == true)
    end

    if api.GetDB then
        local db = api.GetDB()
        local bVal = db.coreBloom or 0.20
        bloomSlider:SetValue(bVal)
        local txt = _G[bloomSlider:GetName() .. "Text"]
        if txt then txt:SetText(string.format("Center Bloom: %d%%", math.floor(bVal * 100))) end
    end
end

-- Simulation Buttons Helper
local function CreateSimButton(text, x, y, width, height, func)
    local btn = CreateFrame("Button", nil, debugFrame, "UIPanelButtonTemplate")
    btn:SetSize(width, height or 22)
    btn:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", x, y)
    btn:SetText(text)
    btn:SetScript("OnClick", function()
        func()
        RefreshDebugCheckboxes()
    end)
    return btn
end

-- Row 5: Quick Sim Buttons
CreateSimButton("Sim Lvl 4 (T1)", 16, -188, 108, 22, function()
    local api = GetAPI(); if api then api.UnlockTier(1, true) end
end)
CreateSimButton("Sim Lvl 10 (T2)", 132, -188, 108, 22, function()
    local api = GetAPI(); if api then api.UnlockTier(2, true) end
end)
CreateSimButton("Sim Aggro (T3)", 248, -188, 108, 22, function()
    local api = GetAPI(); if api then api.UnlockTier(3, true) end
end)
CreateSimButton("Sim Lvl 20 (T4)", 364, -188, 108, 22, function()
    local api = GetAPI(); if api then api.UnlockTier(4, true) end
end)

local SelectClassDebug -- Forward declaration

-- Row 6: Reset Buttons
CreateSimButton("Clear Overrides (Use Earned)", 16, -216, 224, 22, function()
    local api = GetAPI()
    if api then
        api.ClearOverrides()
        if SelectClassDebug then SelectClassDebug("reset") end
    end
    print("|cff00ccff[Nightlight Debug]|r Cleared memory overrides. Using earned trainer flags.")
end)

CreateSimButton("Reset Character Saved Flags", 250, -216, 224, 22, function()
    local api = GetAPI()
    if api then
        api.ResetEarnedFlags()
        if SelectClassDebug then SelectClassDebug("reset") end
    end
    print("|cff00ccff[Nightlight Debug]|r Reset all earned progression flags for this character. Nightlight is now dormant.")
end)

-- -------------------------------------------------------------------------
-- Class Behaviors Debug & Simulation Menu (All 9 WoW Forever Classes)
-- -------------------------------------------------------------------------
local dbgClassHeader = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dbgClassHeader:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 16, -248)
dbgClassHeader:SetText("|cff00ccffClass Behaviors Debug Menu (Tier 4)|r")

local dbgClassStatus = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dbgClassStatus:SetPoint("TOPLEFT", dbgClassHeader, "BOTTOMLEFT", 0, -2)
dbgClassStatus:SetText("Simulating: |cff00ff00Live Character Class|r")

-- Row 8 & 9: 9 Class Buttons + Reset
CreateSimButton("Warrior", 16, -288, 86, 22, function() SelectClassDebug("WARRIOR") end)
CreateSimButton("Paladin", 109, -288, 86, 22, function() SelectClassDebug("PALADIN") end)
CreateSimButton("Hunter", 202, -288, 86, 22, function() SelectClassDebug("HUNTER") end)
CreateSimButton("Rogue", 295, -288, 86, 22, function() SelectClassDebug("ROGUE") end)
CreateSimButton("Priest", 388, -288, 86, 22, function() SelectClassDebug("PRIEST") end)

CreateSimButton("Shaman", 16, -314, 86, 22, function() SelectClassDebug("SHAMAN") end)
CreateSimButton("Mage", 109, -314, 86, 22, function() SelectClassDebug("MAGE") end)
CreateSimButton("Warlock", 202, -314, 86, 22, function() SelectClassDebug("WARLOCK") end)
CreateSimButton("Druid", 295, -314, 86, 22, function() SelectClassDebug("DRUID") end)
CreateSimButton("Reset / Live", 388, -314, 86, 22, function() SelectClassDebug("reset") end)

-- Row 10: Dynamic Class Sub-Options
local dbgSubLabel = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dbgSubLabel:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 16, -348)
dbgSubLabel:SetText("|cffffd100Class Options:|r")

local subBtns = {}
for i = 1, 5 do
    local btn = CreateFrame("Button", nil, debugFrame, "UIPanelButtonTemplate")
    btn:SetSize(68, 22)
    btn:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 110 + (i - 1) * 74, -344)
    btn:Hide()
    subBtns[i] = btn
end

-- Row 11: Dynamic Description Area
local dbgClassDesc = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dbgClassDesc:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 16, -374)
dbgClassDesc:SetPoint("BOTTOMRIGHT", debugFrame, "BOTTOMRIGHT", -16, 12)
dbgClassDesc:SetJustifyH("LEFT")
dbgClassDesc:SetJustifyV("TOP")
dbgClassDesc:SetWordWrap(true)
dbgClassDesc:SetText("|cffaaaaaaClick any class button above to preview that class's unique Tier 4 visual behavior in real time.|r")

local CLASS_DEBUG_DATA = {
    ["WARRIOR"] = {
        name = "Warrior",
        desc = "|cffffd100Warrior Tier 4:|r\n• |cffffffffDefensive Stance:|r Guarded iron-amber fortitude tone.\n• |cffffffffBerserker Stance:|r Fierce fiery rage tone with heightened crackle.\n• |cffffffffEnrage / Berserker Rage / Bloodrage:|r Fiery crimson flame surge (+30% brightness).",
        buttons = {
            { label = "Battle", opt = "battle" },
            { label = "Defensive", opt = "defensive" },
            { label = "Berserker", opt = "berserker" },
            { label = "Enrage", opt = "enrage" },
        }
    },
    ["PALADIN"] = {
        name = "Paladin",
        desc = "|cffffd100Paladin Tier 4:|r\n• |cffffffffHoly Radiance Flare:|r Casting Holy Light, Flash of Light, or Judgement unleashes a brilliant holy golden radiance (+45% brightness) that smoothly fades over ~1s.",
        buttons = {
            { label = "Cast Flare", opt = "flare" },
        }
    },
    ["HUNTER"] = {
        name = "Hunter",
        desc = "|cffffd100Hunter Tier 4:|r\n• |cffffffffCompanion Bond:|r Flame is tethered to your beast companion. When your pet dies or is lost, the light drops to 32% brightness, reflecting the broken bond.",
        buttons = {
            { label = "Pet Alive", opt = "alive" },
            { label = "Pet Dead", opt = "dead" },
        }
    },
    ["ROGUE"] = {
        name = "Rogue",
        desc = "|cffffd100Rogue Tier 4:|r\n• |cffffffffCombo Points:|r Progressive focus (+6% brightness per CP). At 5 CP, achieves razor-sharp lethal gold focus (+35% brightness).\n• |cffffffffSprint:|r Swift wind shimmer.",
        buttons = {
            { label = "2 CP", opt = 2 },
            { label = "4 CP", opt = 4 },
            { label = "5 CP (Max)", opt = 5 },
            { label = "Sprint", opt = "sprint" },
            { label = "0 CP", opt = 0 },
        }
    },
    ["PRIEST"] = {
        name = "Priest",
        desc = "|cffffd100Priest Tier 4:|r\n• |cffffffffInner Core Inversion:|r Under Power Word: Shield, the inner center core is completely extinguished (0% alpha), leaving a luminous protective halo ring surrounding the darkness.",
        buttons = {
            { label = "PW: Shield", opt = "shield" },
            { label = "No Shield", opt = "none" },
        }
    },
    ["SHAMAN"] = {
        name = "Shaman",
        desc = "|cffffd100Shaman Tier 4:|r\n• |cffffffffTotem Wedges:|r Active totems project glowing colored wedges around the 4 quadrant sectors (Fire=Orange-Red, Earth=Amber, Water=Aqua, Air=Sky-Blue).",
        buttons = {
            { label = "1 Fire", opt = "1" },
            { label = "2 Earth", opt = "2" },
            { label = "3 Water", opt = "3" },
            { label = "4 All Totems", opt = "4" },
            { label = "0 None", opt = "0" },
        }
    },
    ["MAGE"] = {
        name = "Mage",
        desc = "|cffffd100Mage Tier 4:|r\n• |cffffffffSpec Resonance:|r Torch hue adapts to your active specialization:\n  - Frost: Crisp crystalline ice-white\n  - Fire: Warm incandescent white-red\n  - Arcane: Mystic ethereal violet",
        buttons = {
            { label = "Frost Spec", opt = "frost" },
            { label = "Fire Spec", opt = "fire" },
            { label = "Arcane Spec", opt = "arcane" },
        }
    },
    ["WARLOCK"] = {
        name = "Warlock",
        desc = "|cffffd100Warlock Tier 4:|r\n• |cffffffffVoid Drain Suppression:|r Channeling Drain Soul, Drain Life, Drain Mana, or Health Funnel dims the light by 65%, pulling the flame into the shadow void.",
        buttons = {
            { label = "Void Drain", opt = "drain" },
            { label = "Normal Flame", opt = "normal" },
        }
    },
    ["DRUID"] = {
        name = "Druid",
        desc = "|cffffd100Druid Tier 4:|r\n• |cffffffffShapeshift Hues:|r Forms project primal glows:\n  - Bear: Primal russet earth-amber\n  - Cat: Sleek nocturnal amber (Prowl auto-extinguishes)\n  - Travel: Swift breeze cyan\n  - Moonkin: Astral starry azure\n  - Caster: Warm restorative flora gold",
        buttons = {
            { label = "Bear Form", opt = "bear" },
            { label = "Cat Form", opt = "cat" },
            { label = "Travel Form", opt = "travel" },
            { label = "Moonkin", opt = "moonkin" },
            { label = "Caster Form", opt = "caster" },
        }
    }
}

SelectClassDebug = function(cls, opt)
    local api = GetAPI()
    if not api then return end

    if not cls or cls == "reset" or cls == "none" or cls == "live" then
        api.SetClassSimulation(nil, nil)
        dbgClassStatus:SetText("Simulating: |cff00ff00Live Character Class|r")
        dbgClassDesc:SetText("|cffaaaaaaClick any class button below to preview that class's unique Tier 4 visual behavior in real time.|r")
        for i = 1, 5 do
            subBtns[i]:Hide()
        end
        RefreshDebugCheckboxes()
        return
    end

    cls = cls:upper()
    local data = CLASS_DEBUG_DATA[cls]
    if not data then return end

    local activeOpt = opt
    if activeOpt == nil and data.buttons and data.buttons[1] then
        activeOpt = data.buttons[1].opt
    end

    api.SetClassSimulation(cls, activeOpt)

    local optStr = activeOpt and tostring(activeOpt) or "Default"
    dbgClassStatus:SetText(string.format("Simulating: |cffffd100%s|r (|cff00ff00%s|r)", data.name, optStr))
    dbgClassDesc:SetText(data.desc)

    for i = 1, 5 do
        local btnConfig = data.buttons and data.buttons[i]
        if btnConfig then
            subBtns[i]:SetText(btnConfig.label)
            subBtns[i]:SetScript("OnClick", function()
                SelectClassDebug(cls, btnConfig.opt)
            end)
            subBtns[i]:Show()
        else
            subBtns[i]:Hide()
        end
    end

    RefreshDebugCheckboxes()
end

-- -------------------------------------------------------------------------
-- Command Handling & Bridge Registration
-- -------------------------------------------------------------------------
local function HandleDebugCommand(rest)
    local api = GetAPI()
    if not api then
        print("|cff00ccff[Nightlight Debug]|r Error: TimelessForever_nightlight core addon is not active.")
        return
    end

    local subCmd, arg = (rest or ""):match("^(%S*)%s*(.-)$")
    subCmd = (subCmd or ""):lower()

    if subCmd == "" or subCmd == "frame" then
        RefreshDebugCheckboxes()
        if debugFrame:IsShown() then
            debugFrame:Hide()
        else
            debugFrame:Show()
        end
    elseif subCmd == "show" or subCmd == "open" then
        RefreshDebugCheckboxes()
        debugFrame:Show()
    elseif subCmd == "hide" or subCmd == "close" then
        debugFrame:Hide()
    elseif subCmd == "tier1" then
        local val = (arg == "on" or arg == "1" or arg == "true") and true or (arg == "off" and false or nil)
        api.SetTierOverride(1, val)
        RefreshDebugCheckboxes()
        print(string.format("|cff00ccff[Nightlight Debug]|r Tier 1 override: %s", val == nil and "RESET (Using Earned)" or (val and "FORCE ON" or "FORCE OFF")))
    elseif subCmd == "tier2" then
        local val = (arg == "on" or arg == "1" or arg == "true") and true or (arg == "off" and false or nil)
        api.SetTierOverride(2, val)
        RefreshDebugCheckboxes()
        print(string.format("|cff00ccff[Nightlight Debug]|r Tier 2 override: %s", val == nil and "RESET (Using Earned)" or (val and "FORCE ON" or "FORCE OFF")))
    elseif subCmd == "tier3" then
        local val = (arg == "on" or arg == "1" or arg == "true") and true or (arg == "off" and false or nil)
        api.SetTierOverride(3, val)
        RefreshDebugCheckboxes()
        print(string.format("|cff00ccff[Nightlight Debug]|r Tier 3 override: %s", val == nil and "RESET (Using Earned)" or (val and "FORCE ON" or "FORCE OFF")))
    elseif subCmd == "tier4" then
        local val = (arg == "on" or arg == "1" or arg == "true") and true or (arg == "off" and false or nil)
        api.SetTierOverride(4, val)
        RefreshDebugCheckboxes()
        print(string.format("|cff00ccff[Nightlight Debug]|r Tier 4 override: %s", val == nil and "RESET (Using Earned)" or (val and "FORCE ON" or "FORCE OFF")))
    elseif subCmd == "night" then
        local val = (arg == "on" or arg == "1" or arg == "true") and true or (arg == "off" and false or nil)
        api.SetNightOverride(val)
        RefreshDebugCheckboxes()
        print(string.format("|cff00ccff[Nightlight Debug]|r Force Night override: %s", val == nil and "RESET (Using Clock)" or (val and "FORCE NIGHT" or "FORCE DAY")))
    elseif subCmd == "aggro" then
        local val = (arg == "on" or arg == "1" or arg == "true") and true or (arg == "off" and false or nil)
        if api.SetForceAggro then
            api.SetForceAggro(val)
        end
        RefreshDebugCheckboxes()
        print(string.format("|cff00ccff[Nightlight Debug]|r Force Target Aggro: %s", val == nil and "RESET (Using Live Check)" or (val and "FORCE RED CENTER" or "FORCE OFF")))
    elseif subCmd == "simulate" then
        local tierNum = tonumber(arg)
        if tierNum and tierNum >= 1 and tierNum <= 4 then
            api.UnlockTier(tierNum, true)
            RefreshDebugCheckboxes()
        else
            print("|cff00ccff[Nightlight Debug]|r Usage: /nightlight debug simulate <1|2|3|4>")
        end
    elseif subCmd == "class" then
        local cls, opt = arg:match("^(%S*)%s*(.-)$")
        cls = (cls or ""):lower()
        opt = (opt or ""):lower()
        if opt == "" then opt = nil end
        if cls == "" or cls == "help" then
            print("|cff00ccff[Nightlight Debug]|r Usage: /nightlight debug class <warrior|paladin|hunter|rogue|priest|shaman|mage|warlock|druid|reset> [option]")
            return
        end
        SelectClassDebug(cls, opt)
    elseif subCmd == "reset" then
        api.ClearOverrides()
        SelectClassDebug("reset")
        RefreshDebugCheckboxes()
        print("|cff00ccff[Nightlight Debug]|r All memory overrides cleared. Running pure earned progression.")
    elseif subCmd == "status" then
        local cdata = api.GetCharData and api.GetCharData() or {}
        local simClass, simOpt = api.GetClassSimulation()
        print("|cff00ccff===== Nightlight Debug Status =====|r")
        print(string.format("  Tier 1 Earned: %s (Override: %s)", cdata.tier1_earned and "|cff00ff00YES|r" or "|cffff3333NO|r", tostring(api.GetTierOverride(1))))
        print(string.format("  Tier 2 Earned: %s (Override: %s)", cdata.tier2_earned and "|cff00ff00YES|r" or "|cffff3333NO|r", tostring(api.GetTierOverride(2))))
        print(string.format("  Tier 3 Earned: %s (Override: %s)", cdata.tier3_earned and "|cff00ff00YES|r" or "|cffff3333NO|r", tostring(api.GetTierOverride(3))))
        print(string.format("  Tier 4 Earned: %s (Override: %s)", cdata.tier4_earned and "|cff00ff00YES|r" or "|cffff3333NO|r", tostring(api.GetTierOverride(4))))
        print(string.format("  Class Simulation: %s (Option: %s)", simClass or "|cff00ff00Live Character|r", tostring(simOpt)))
        print(string.format("  Night Override: %s", tostring(api.GetNightOverride())))
    else
        print("|cff00ccff===== Nightlight Debug Commands =====|r")
        print("  |cffffd100/nightlight debug|r - Toggle the debug testing window")
        print("  |cffffd100/nightlight debug tier1 <on|off|reset>|r - Override Tier 1")
        print("  |cffffd100/nightlight debug tier2 <on|off|reset>|r - Override Tier 2")
        print("  |cffffd100/nightlight debug tier3 <on|off|reset>|r - Override Tier 3")
        print("  |cffffd100/nightlight debug tier4 <on|off|reset>|r - Override Tier 4")
        print("  |cffffd100/nightlight debug class <name> [opt]|r - Simulate class behavior")
        print("  |cffffd100/nightlight debug simulate <1|2|3|4>|r - Simulate class trainer unlock")
        print("  |cffffd100/nightlight debug reset|r - Clear all overrides")
    end
end

-- Bridge into Nightlight core
local function RegisterWithCore()
    local api = GetAPI()
    if api and api.RegisterDebugHandler then
        api.RegisterDebugHandler({
            Execute = HandleDebugCommand,
            Open = function()
                RefreshDebugCheckboxes()
                debugFrame:Show()
            end
        })
    end
end

SLASH_TF_NIGHTLIGHT_DEBUG1 = "/nightlightdebug"
SLASH_TF_NIGHTLIGHT_DEBUG2 = "/nldebug"
SlashCmdList["TF_NIGHTLIGHT_DEBUG"] = function(msg)
    HandleDebugCommand(msg)
end

DebugApp:RegisterEvent("PLAYER_LOGIN")
DebugApp:SetScript("OnEvent", function()
    RegisterWithCore()
end)

-- If loaded after PLAYER_LOGIN
RegisterWithCore()

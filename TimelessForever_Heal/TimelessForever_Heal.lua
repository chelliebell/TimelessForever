-- =========================================================================
-- TimelessForever_Heal (Complete Remake From Scratch)
-- Clean, Zero-Taint Mouseover & Click-Cast Healing Unit Frames
-- Supports Classic Era, Classic Beta, Cataclysm/MoP Classic, and Retail
-- =========================================================================

local addonName, addonTable = ...
local TimelessHeal = CreateFrame("Frame", "TimelessForever_HealCoreFrame", UIParent)
_G["TimelessForever_Heal"] = TimelessHeal
_G["TimelessHeal"] = TimelessHeal
_G["ForeverHeal"] = TimelessHeal

local ICON_TEXTURE = "Interface\\AddOns\\TimelessForever_Heal\\Icons\\gamehivehq"
local CHAT_PREFIX = "|cff00ccff[TimelessHeal]|r "
local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"
local STATUSBAR_TEX = "Interface\\TargetingFrame\\UI-StatusBar"

-- =========================================================================
-- 1. API Compatibility Layer (Classic / Beta / Retail)
-- =========================================================================
local UnitExists = _G.UnitExists
local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitPower = _G.UnitPower or _G.UnitMana
local UnitPowerMax = _G.UnitPowerMax or _G.UnitManaMax
local UnitPowerType = _G.UnitPowerType
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsDead = _G.UnitIsDead
local UnitIsGhost = _G.UnitIsGhost
local UnitIsConnected = _G.UnitIsConnected
local UnitInRange = _G.UnitInRange
local UnitIsUnit = _G.UnitIsUnit
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitThreatSituation = _G.UnitThreatSituation
local UnitGetIncomingHeals = _G.UnitGetIncomingHeals
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture
local InCombatLockdown = _G.InCombatLockdown
local IsInRaid = _G.IsInRaid
local IsInGroup = _G.IsInGroup
local GetTime = _G.GetTime

local function SafeGetSpellInfo(spell)
    if not spell or spell == "" then return nil, nil, nil end
    if _G.C_Spell and _G.C_Spell.GetSpellInfo then
        local ok, info = pcall(_G.C_Spell.GetSpellInfo, spell)
        if ok and info then
            return info.name, info.iconID, info.spellID
        end
    end
    if _G.GetSpellInfo then
        local ok, name, _, icon, _, _, _, spellID = pcall(_G.GetSpellInfo, spell)
        if ok and name then
            return name, icon, spellID
        end
    end
    return nil, nil, nil
end

local function SafeIsSpellInRange(spellName, unit)
    if not spellName or not unit then return nil end
    if _G.C_Spell and _G.C_Spell.IsSpellInRange then
        local ok, res = pcall(_G.C_Spell.IsSpellInRange, spellName, unit)
        if ok and res ~= nil then
            return res == true or res == 1
        end
    end
    if _G.IsSpellInRange then
        local ok, res = pcall(_G.IsSpellInRange, spellName, unit)
        if ok and res ~= nil then
            return res == 1 or res == true
        end
    end
    return nil
end

local function SafeGetAura(unit, index, filter)
    if _G.C_UnitAuras and _G.C_UnitAuras.GetAuraDataByIndex then
        local ok, data = pcall(_G.C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if ok and data then
            return data.name, data.icon, data.applications or 0, data.dispelName, data.duration or 0, data.expirationTime or 0, data.sourceUnit, data.spellId
        end
        return nil
    elseif _G.UnitAura then
        local name, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = _G.UnitAura(unit, index, filter)
        return name, icon, count, dispelType, duration, expirationTime, source, spellId
    end
    return nil
end

-- =========================================================================
-- 2. Class Data, Dispels, Smart Rez & Default Click-Cast Bindings
-- =========================================================================
local _, PLAYER_CLASS = UnitClass("player")
PLAYER_CLASS = PLAYER_CLASS or "PRIEST"

local CLASS_COLORS = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    MAGE        = { 0.25, 0.78, 0.92 },
    WARLOCK     = { 0.53, 0.53, 0.93 },
    MONK        = { 0.00, 1.00, 0.60 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

local POWER_COLORS = {
    [0] = { 0.15, 0.48, 0.95 }, -- Mana
    [1] = { 0.90, 0.20, 0.20 }, -- Rage
    [2] = { 1.00, 0.50, 0.25 }, -- Focus
    [3] = { 1.00, 0.90, 0.20 }, -- Energy
    [6] = { 0.00, 0.82, 1.00 }, -- Runic Power
}

local DISPEL_COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.65, 0.15, 1.00 },
    Disease = { 0.75, 0.50, 0.15 },
    Poison  = { 0.15, 0.85, 0.20 },
}

local CLASS_CAN_DISPEL = {
    PRIEST  = { Magic = true, Disease = true },
    PALADIN = { Magic = true, Poison = true, Disease = true },
    DRUID   = { Curse = true, Poison = true, Magic = true },
    SHAMAN  = { Curse = true, Poison = true, Disease = true, Magic = true },
    MONK    = { Magic = true, Poison = true, Disease = true },
    EVOKER  = { Magic = true, Poison = true, Curse = true, Disease = true },
    MAGE    = { Curse = true },
}

local CLASS_RES_SPELL = {
    PRIEST  = "Resurrection",
    PALADIN = "Redemption",
    SHAMAN  = "Ancestral Spirit",
    DRUID   = "Revive",
    MONK    = "Resuscitate",
    EVOKER  = "Return",
}

local CLASS_RANGE_SPELL = {
    PRIEST  = "Flash Heal",
    PALADIN = "Holy Light",
    DRUID   = "Healing Touch",
    SHAMAN  = "Healing Wave",
    MONK    = "Vivify",
    EVOKER  = "Living Flame",
    MAGE    = "Remove Lesser Curse",
}

local CLASS_DEFAULT_SPELLS = {
    PRIEST = {
        ["LeftButton"]        = "Flash Heal",
        ["RightButton"]       = "Power Word: Shield",
        ["MiddleButton"]      = "Renew",
        ["Shift-LeftButton"]  = "Greater Heal",
        ["Shift-RightButton"] = "Prayer of Mending",
        ["Ctrl-LeftButton"]   = "Dispel Magic",
        ["Ctrl-RightButton"]  = "Abolish Disease",
        ["Alt-LeftButton"]    = "Prayer of Healing",
    },
    PALADIN = {
        ["LeftButton"]        = "Flash of Light",
        ["RightButton"]       = "Holy Light",
        ["MiddleButton"]      = "Holy Shock",
        ["Shift-LeftButton"]  = "Blessing of Protection",
        ["Shift-RightButton"] = "Lay on Hands",
        ["Ctrl-LeftButton"]   = "Cleanse",
        ["Alt-LeftButton"]    = "Blessing of Freedom",
    },
    DRUID = {
        ["LeftButton"]        = "Rejuvenation",
        ["RightButton"]       = "Regrowth",
        ["MiddleButton"]      = "Swiftmend",
        ["Shift-LeftButton"]  = "Healing Touch",
        ["Shift-RightButton"] = "Lifebloom",
        ["Ctrl-LeftButton"]   = "Remove Curse",
        ["Ctrl-RightButton"]  = "Abolish Poison",
    },
    SHAMAN = {
        ["LeftButton"]        = "Lesser Healing Wave",
        ["RightButton"]       = "Healing Wave",
        ["MiddleButton"]      = "Chain Heal",
        ["Shift-LeftButton"]  = "Riptide",
        ["Shift-RightButton"] = "Earth Shield",
        ["Ctrl-LeftButton"]   = "Cure Poison",
        ["Ctrl-RightButton"]  = "Cure Disease",
    },
    MONK = {
        ["LeftButton"]        = "Vivify",
        ["RightButton"]       = "Enveloping Mist",
        ["MiddleButton"]      = "Renewing Mist",
        ["Shift-LeftButton"]  = "Soothing Mist",
        ["Ctrl-LeftButton"]   = "Detox",
    },
    EVOKER = {
        ["LeftButton"]        = "Echo",
        ["RightButton"]       = "Reversion",
        ["MiddleButton"]      = "Verdant Embrace",
        ["Ctrl-LeftButton"]   = "Naturalize",
    },
    MAGE = {
        ["Ctrl-LeftButton"]   = "Remove Lesser Curse",
    },
}

local BINDING_SLOTS = {
    { key = "LeftButton",         label = "Left Click",          mod = "NONE",  btnNum = 1, prefix = "" },
    { key = "RightButton",        label = "Right Click",         mod = "NONE",  btnNum = 2, prefix = "" },
    { key = "MiddleButton",       label = "Middle Click",        mod = "NONE",  btnNum = 3, prefix = "" },
    { key = "Button4",            label = "Mouse Button 4",      mod = "NONE",  btnNum = 4, prefix = "" },
    { key = "Button5",            label = "Mouse Button 5",      mod = "NONE",  btnNum = 5, prefix = "" },
    { key = "Shift-LeftButton",   label = "Shift + Left Click",  mod = "SHIFT", btnNum = 1, prefix = "shift-" },
    { key = "Shift-RightButton",  label = "Shift + Right Click", mod = "SHIFT", btnNum = 2, prefix = "shift-" },
    { key = "Shift-MiddleButton", label = "Shift + Middle Click",mod = "SHIFT", btnNum = 3, prefix = "shift-" },
    { key = "Shift-Button4",      label = "Shift + Mouse Btn 4", mod = "SHIFT", btnNum = 4, prefix = "shift-" },
    { key = "Shift-Button5",      label = "Shift + Mouse Btn 5", mod = "SHIFT", btnNum = 5, prefix = "shift-" },
    { key = "Ctrl-LeftButton",    label = "Ctrl + Left Click",   mod = "CTRL",  btnNum = 1, prefix = "ctrl-" },
    { key = "Ctrl-RightButton",   label = "Ctrl + Right Click",  mod = "CTRL",  btnNum = 2, prefix = "ctrl-" },
    { key = "Ctrl-MiddleButton",  label = "Ctrl + Middle Click", mod = "CTRL",  btnNum = 3, prefix = "ctrl-" },
    { key = "Alt-LeftButton",     label = "Alt + Left Click",    mod = "ALT",   btnNum = 1, prefix = "alt-" },
    { key = "Alt-RightButton",    label = "Alt + Right Click",   mod = "ALT",   btnNum = 2, prefix = "alt-" },
    { key = "Alt-MiddleButton",   label = "Alt + Middle Click",  mod = "ALT",   btnNum = 3, prefix = "alt-" },
}

-- =========================================================================
-- 3. Database Initialization & Defaults
-- =========================================================================
local DEFAULT_DB = {
    enabled = true,
    locked = false,
    orientation = "HORIZONTAL", -- "HORIZONTAL" or "VERTICAL"
    columns = 5,
    spacing = 4,
    frameWidth = 98,
    frameHeight = 46,
    powerHeight = 6,
    scale = 1.0,
    outOfRangeAlpha = 0.42,

    showSolo = true,
    showParty = true,
    showRaid = true,
    includePets = false,
    showSelfBar = false,
    showTargetBar = false,

    classColors = true,
    showPowerBar = true,
    showIncomingHeals = true,
    showDispelHighlight = true,
    showHoTs = true,
    showDebuffIcons = true,
    showRoleIcon = true,
    showRaidTarget = true,
    showLeaderIcon = true,
    showThreatBorder = true,
    healthFormat = "PERCENT", -- "PERCENT", "DEFICIT", "CURRENT", "NONE"

    smartResurrection = true,
    hookBlizzFrames = true,
    hideBlizzParty = false,
    menuClickKey = "Alt-RightButton",

    anchor = { point = "CENTER", relativePoint = "CENTER", x = -280, y = -80 },
    selfAnchor = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -165 },
    targetAnchor = { point = "CENTER", relativePoint = "CENTER", x = 150, y = -165 },

    spells = nil, -- Populated from CLASS_DEFAULT_SPELLS on first init
}

local db

local function GetDefaultSpellsForClass()
    local tbl = {}
    for _, slot in ipairs(BINDING_SLOTS) do
        tbl[slot.key] = ""
    end
    local classDefaults = CLASS_DEFAULT_SPELLS[PLAYER_CLASS]
    if classDefaults then
        for k, v in pairs(classDefaults) do
            tbl[k] = v
        end
    end
    if not tbl["Alt-RightButton"] or tbl["Alt-RightButton"] == "" then
        tbl["Alt-RightButton"] = "togglemenu"
    end
    if not tbl["Alt-LeftButton"] or tbl["Alt-LeftButton"] == "" then
        tbl["Alt-LeftButton"] = "target"
    end
    return tbl
end

function TimelessHeal:InitDB()
    if type(_G.TimelessForever_HealDB) ~= "table" then
        if type(_G.TimelessForeverHealDB) == "table" then
            _G.TimelessForever_HealDB = _G.TimelessForeverHealDB
        elseif type(_G.TimelessHealDB) == "table" then
            _G.TimelessForever_HealDB = _G.TimelessHealDB
        elseif type(_G.ForeverHealDB) == "table" then
            _G.TimelessForever_HealDB = _G.ForeverHealDB
        else
            _G.TimelessForever_HealDB = {}
        end
    end

    db = _G.TimelessForever_HealDB
    _G.TimelessForeverHealDB = db
    _G.TimelessHealDB = db
    _G.ForeverHealDB = db

    for k, v in pairs(DEFAULT_DB) do
        if db[k] == nil then
            if type(v) == "table" then
                db[k] = {}
                for subK, subV in pairs(v) do
                    db[k][subK] = subV
                end
            else
                db[k] = v
            end
        end
    end

    if type(db.spells) ~= "table" then
        db.spells = GetDefaultSpellsForClass()
    else
        local hasAny = false
        local hasMenu = false
        for _, slot in ipairs(BINDING_SLOTS) do
            if db.spells[slot.key] == nil then
                db.spells[slot.key] = ""
            elseif db.spells[slot.key] ~= "" then
                hasAny = true
                local low = string.lower(strtrim(db.spells[slot.key]))
                if low == "togglemenu" or low == "menu" then
                    hasMenu = true
                end
            end
        end
        if not hasAny and not db._defaultsInitialized then
            local defaults = GetDefaultSpellsForClass()
            for k, v in pairs(defaults) do
                db.spells[k] = v
            end
            db._defaultsInitialized = true
        elseif not hasMenu then
            local menuKey = db.menuClickKey or "Alt-RightButton"
            if not db.spells[menuKey] or db.spells[menuKey] == "" then
                db.spells[menuKey] = "togglemenu"
            end
        end
    end
end

-- =========================================================================
-- 4. Test Mode Mock Data
-- =========================================================================
local testModeCount = 0 -- 0 = off, 5 = party, 20 = raid
local MOCK_ROSTER = {
    { name = "Aeliana",   class = "PRIEST",      role = "HEALER", hp = 0.94, mp = 0.86, inc = 0.05, dispel = nil,       hot = 139,   leader = true,  raidIcon = 1 },
    { name = "Thorgrim",  class = "WARRIOR",     role = "TANK",   hp = 0.62, mp = 0.45, inc = 0.18, dispel = "Magic",   hot = 17,    threat = 3,     raidIcon = 2 },
    { name = "Sylvan",    class = "HUNTER",      role = "DAMAGER",hp = 0.78, mp = 0.70, inc = 0.00, dispel = "Poison",  hot = nil,   threat = 0 },
    { name = "Kaelen",    class = "MAGE",        role = "DAMAGER",hp = 0.41, mp = 0.32, inc = 0.22, dispel = "Curse",   hot = 139,   threat = 2 },
    { name = "Brielle",   class = "PALADIN",     role = "DAMAGER",hp = 1.00, mp = 0.92, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
    { name = "Morgath",   class = "WARLOCK",     role = "DAMAGER",hp = 0.55, mp = 0.60, inc = 0.10, dispel = "Disease", hot = nil,   threat = 0 },
    { name = "Lyra",      class = "DRUID",       role = "HEALER", hp = 0.89, mp = 0.77, inc = 0.00, dispel = nil,       hot = 774,   threat = 0 },
    { name = "Varek",     class = "ROGUE",       role = "DAMAGER",hp = 0.34, mp = 0.80, inc = 0.15, dispel = "Poison",  hot = nil,   threat = 1 },
    { name = "Zuljin",    class = "SHAMAN",      role = "HEALER", hp = 0.95, mp = 0.64, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
    { name = "Darius",    class = "PALADIN",     role = "TANK",   hp = 0.71, mp = 0.58, inc = 0.12, dispel = "Magic",   hot = 139,   threat = 3 },
    { name = "Faelen",    class = "DRUID",       role = "DAMAGER",hp = 0.84, mp = 0.90, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
    { name = "Ragnar",    class = "WARRIOR",     role = "DAMAGER",hp = 0.49, mp = 0.55, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
    { name = "Nyx",       class = "ROGUE",       role = "DAMAGER",hp = 0.92, mp = 0.75, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
    { name = "Seraphina", class = "PRIEST",      role = "DAMAGER",hp = 0.67, mp = 0.42, inc = 0.08, dispel = "Magic",   hot = nil,   threat = 0 },
    { name = "Grom",      class = "SHAMAN",      role = "DAMAGER",hp = 0.73, mp = 0.51, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
    { name = "Elora",     class = "MAGE",        role = "DAMAGER",hp = 0.00, mp = 0.00, inc = 0.00, dispel = nil,       hot = nil,   dead = true },
    { name = "Bram",      class = "HUNTER",      role = "DAMAGER",hp = 0.88, mp = 0.68, inc = 0.00, dispel = nil,       hot = nil,   oor = true },
    { name = "Cassia",    class = "WARLOCK",     role = "DAMAGER",hp = 0.61, mp = 0.49, inc = 0.00, dispel = "Curse",   hot = nil,   threat = 0 },
    { name = "Toren",     class = "DRUID",       role = "DAMAGER",hp = 0.97, mp = 0.83, inc = 0.00, dispel = nil,       hot = 774,   threat = 0 },
    { name = "Valen",     class = "PALADIN",     role = "HEALER", hp = 0.81, mp = 0.74, inc = 0.00, dispel = nil,       hot = nil,   threat = 0 },
}

-- =========================================================================
-- 5. Unit Frame Factory & Visual Updater
-- =========================================================================
local MAX_GRID_FRAMES = 40
local gridFrames = {}
local selfFrame, targetFrame
local mainContainer, headerBar
local pendingLayoutUpdate = false
local pendingBindingsUpdate = false
local unitMenuDropdown

local function OpenBlizzardUnitMenu(self, unit)
    unit = unit or (self and self.GetAttribute and self:GetAttribute("unit")) or "player"
    if not unit or not UnitExists(unit) then
        unit = "player"
    end

    local which = "TARGET"
    local raidID = nil
    if UnitIsUnit(unit, "player") then
        which = "SELF"
    elseif UnitIsUnit(unit, "vehicle") then
        which = "VEHICLE"
    elseif UnitIsUnit(unit, "pet") then
        which = "PET"
    elseif _G.UnitInRaid and _G.UnitInRaid(unit) then
        which = "RAID_PLAYER"
        raidID = _G.UnitInRaid(unit)
    elseif _G.UnitInParty and _G.UnitInParty(unit) then
        which = "PARTY"
    elseif _G.UnitIsPlayer and _G.UnitIsPlayer(unit) then
        which = "PLAYER"
    end

    -- 1. Modern UnitPopup_OpenMenu API (Classic Beta / Retail / Modern Clients)
    if _G.UnitPopup_OpenMenu then
        local contextData = {
            unit = unit,
            name = UnitName(unit),
            raidTargetIndex = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil,
            fromPlayerFrame = (which == "SELF"),
            fromTargetFrame = (which == "TARGET"),
        }
        local ok = pcall(_G.UnitPopup_OpenMenu, which, contextData)
        if ok then return true end
    end

    -- 2. Native Blizzard PlayerFrameDropDown / TargetFrameDropDown
    if which == "SELF" and _G.PlayerFrameDropDown and _G.ToggleDropDownMenu then
        _G.ToggleDropDownMenu(1, nil, _G.PlayerFrameDropDown, "cursor")
        return true
    end
    if UnitIsUnit(unit, "target") and _G.TargetFrameDropDown and _G.ToggleDropDownMenu then
        _G.ToggleDropDownMenu(1, nil, _G.TargetFrameDropDown, "cursor")
        return true
    end

    -- 3. FriendsDropDown (Used by Blizzard CompactUnitFrame in Classic/Cata/MoP)
    if _G.FriendsDropDown and _G.ToggleDropDownMenu then
        _G.FriendsDropDown.unit = unit
        _G.FriendsDropDown.name = UnitName(unit)
        _G.FriendsDropDown.id = raidID
        _G.FriendsDropDown.displayMode = "MENU"
        if _G.CompactUnitFrameDropDown_Initialize then
            _G.FriendsDropDown.initialize = _G.CompactUnitFrameDropDown_Initialize
        elseif _G.FriendsFrameDropDown_Initialize then
            _G.FriendsDropDown.initialize = _G.FriendsFrameDropDown_Initialize
        elseif _G.UnitPopup_ShowMenu then
            _G.FriendsDropDown.initialize = function(dropdown)
                _G.UnitPopup_ShowMenu(dropdown, which, unit, UnitName(unit))
            end
        end
        _G.ToggleDropDownMenu(1, nil, _G.FriendsDropDown, "cursor")
        return true
    end

    -- 4. Fallback UIDropDownMenuTemplate with UnitPopup_ShowMenu
    if _G.UnitPopup_ShowMenu and _G.UIDropDownMenu_Initialize and _G.ToggleDropDownMenu then
        if not unitMenuDropdown then
            unitMenuDropdown = CreateFrame("Frame", "TimelessHealUnitMenuDropDown", UIParent, "UIDropDownMenuTemplate")
        end
        unitMenuDropdown.unit = unit
        unitMenuDropdown.name = UnitName(unit)
        unitMenuDropdown.id = raidID
        unitMenuDropdown.displayMode = "MENU"
        _G.UIDropDownMenu_Initialize(unitMenuDropdown, function(dropdown)
            _G.UnitPopup_ShowMenu(dropdown, which, unit, UnitName(unit))
        end, "MENU")
        _G.ToggleDropDownMenu(1, nil, unitMenuDropdown, "cursor")
        return true
    end
end

local function FormatHealthValue(cur, maxHp, mode)
    if maxHp <= 0 then return "" end
    if mode == "NONE" then
        return ""
    elseif mode == "DEFICIT" then
        local missing = maxHp - cur
        if missing <= 0 then return "" end
        if missing >= 1000 then
            return string.format("-%.1fk", missing / 1000)
        end
        return string.format("-%d", missing)
    elseif mode == "CURRENT" then
        if cur >= 1000 then
            return string.format("%.1fk", cur / 1000)
        end
        return tostring(cur)
    else -- "PERCENT"
        local pct = math.floor((cur / maxHp) * 100 + 0.5)
        return string.format("%d%%", pct)
    end
end

local function ApplyClickBindingsToButton(btn)
    if not btn or not db or not db.spells then return end
    if InCombatLockdown() then
        pendingBindingsUpdate = true
        return
    end

    btn:RegisterForClicks("AnyUp")

    local resSpell = db.smartResurrection and CLASS_RES_SPELL[PLAYER_CLASS] or nil

    for _, slot in ipairs(BINDING_SLOTS) do
        local spellEntry = strtrim(db.spells[slot.key] or "")
        local attrType = slot.prefix .. "type" .. slot.btnNum
        local attrSpell = slot.prefix .. "spell" .. slot.btnNum
        local attrMacro = slot.prefix .. "macrotext" .. slot.btnNum

        if spellEntry ~= "" then
            if string.sub(spellEntry, 1, 1) == "/" then
                btn:SetAttribute(attrType, "macro")
                btn:SetAttribute(attrMacro, spellEntry)
                btn:SetAttribute(attrSpell, nil)
            elseif string.lower(spellEntry) == "target" then
                btn:SetAttribute(attrType, "target")
                btn:SetAttribute(attrSpell, nil)
                btn:SetAttribute(attrMacro, nil)
            elseif string.lower(spellEntry) == "togglemenu" or string.lower(spellEntry) == "menu" then
                btn:SetAttribute(attrType, "togglemenu")
                btn:SetAttribute(attrSpell, nil)
                btn:SetAttribute(attrMacro, nil)
            elseif resSpell and slot.key == "LeftButton" then
                -- Smart Resurrection macro on Left-Click: casts Rez if dead, otherwise normal heal
                local macroBody = string.format("/cast [@mouseover,dead,help][dead,help] %s; [@mouseover,help,nodead][help,nodead] %s", resSpell, spellEntry)
                btn:SetAttribute(attrType, "macro")
                btn:SetAttribute(attrMacro, macroBody)
                btn:SetAttribute(attrSpell, nil)
            else
                btn:SetAttribute(attrType, "spell")
                btn:SetAttribute(attrSpell, spellEntry)
                btn:SetAttribute(attrMacro, nil)
            end
        else
            -- Fallback default behavior for unbound Left/Right click (including with modifiers)
            if slot.btnNum == 1 then
                btn:SetAttribute(attrType, "target")
            elseif slot.btnNum == 2 then
                btn:SetAttribute(attrType, "togglemenu")
            else
                btn:SetAttribute(attrType, nil)
            end
            btn:SetAttribute(attrSpell, nil)
            btn:SetAttribute(attrMacro, nil)
        end
    end
end

local hookedBlizzFrames = {}

function TimelessHeal:HookBlizzardUnitFrames()
    if not db or not db.hookBlizzFrames then return end
    if InCombatLockdown() then
        pendingBindingsUpdate = true
        return
    end

    local candidates = {
        _G.PlayerFrame,
        _G.TargetFrame,
        _G.FocusFrame,
        _G.PetFrame,
    }
    for i = 1, 4 do
        if _G["PartyMemberFrame" .. i] then table.insert(candidates, _G["PartyMemberFrame" .. i]) end
    end
    for i = 1, 5 do
        if _G["CompactPartyFrameMember" .. i] then table.insert(candidates, _G["CompactPartyFrameMember" .. i]) end
    end
    for i = 1, 40 do
        if _G["CompactRaidFrame" .. i] then table.insert(candidates, _G["CompactRaidFrame" .. i]) end
    end
    for g = 1, 8 do
        for m = 1, 5 do
            local f = _G["CompactRaidGroup" .. g .. "Member" .. m]
            if f then table.insert(candidates, f) end
        end
    end

    for _, frame in ipairs(candidates) do
        if frame and not frame:IsForbidden() then
            ApplyClickBindingsToButton(frame)
            hookedBlizzFrames[frame] = true
        end
    end
end

local function CreateUnitButton(name, parent)
    local btn = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate,BackdropTemplate")
    btn:SetSize(db.frameWidth or 98, db.frameHeight or 46)
    btn:RegisterForClicks("AnyUp")
    btn.menu = OpenBlizzardUnitMenu

    btn:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.07, 0.08, 0.10, 0.92)
    btn:SetBackdropBorderColor(0.18, 0.20, 0.25, 1.0)

    -- Outer Threat / Dispel Border Frame
    local border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    border:SetFrameLevel(btn:GetFrameLevel() + 5)
    border:SetBackdrop({
        edgeFile = WHITE8X8,
        edgeSize = 2,
    })
    border:SetBackdropBorderColor(0, 0, 0, 0)
    btn.border = border

    -- Health Bar
    local hpBar = CreateFrame("StatusBar", nil, btn)
    hpBar:SetStatusBarTexture(STATUSBAR_TEX)
    hpBar:SetMinMaxValues(0, 100)
    hpBar:SetValue(100)
    hpBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    hpBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, (db.showPowerBar and (db.powerHeight or 6) + 2 or 2))
    btn.hpBar = hpBar

    local hpBg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints()
    hpBg:SetTexture(STATUSBAR_TEX)
    hpBg:SetVertexColor(0.12, 0.13, 0.16, 0.9)
    btn.hpBg = hpBg

    -- Incoming Heal Prediction Bar
    local incBar = CreateFrame("StatusBar", nil, hpBar)
    incBar:SetStatusBarTexture(STATUSBAR_TEX)
    incBar:SetStatusBarColor(0.15, 0.90, 0.40, 0.45)
    incBar:SetMinMaxValues(0, 100)
    incBar:SetValue(0)
    incBar:SetAllPoints(hpBar)
    incBar:SetFrameLevel(hpBar:GetFrameLevel() + 1)
    incBar:Hide()
    btn.incBar = incBar

    -- Power / Mana Bar
    local powerBar = CreateFrame("StatusBar", nil, btn)
    powerBar:SetStatusBarTexture(STATUSBAR_TEX)
    powerBar:SetMinMaxValues(0, 100)
    powerBar:SetValue(100)
    powerBar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 2)
    powerBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    powerBar:SetHeight(db.powerHeight or 6)
    btn.powerBar = powerBar

    local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints()
    powerBg:SetTexture(WHITE8X8)
    powerBg:SetVertexColor(0.05, 0.05, 0.08, 0.9)

    -- Text Overlay Frame (above bars so text is always crisp)
    local overlay = CreateFrame("Frame", nil, btn)
    overlay:SetAllPoints(hpBar)
    overlay:SetFrameLevel(hpBar:GetFrameLevel() + 3)
    btn.overlay = overlay

    -- Role Icon (Top-Left)
    local roleIcon = overlay:CreateTexture(nil, "ARTWORK")
    roleIcon:SetSize(12, 12)
    roleIcon:SetPoint("TOPLEFT", overlay, "TOPLEFT", 3, -3)
    roleIcon:Hide()
    btn.roleIcon = roleIcon

    -- Leader Icon (Next to Role Icon)
    local leaderIcon = overlay:CreateTexture(nil, "ARTWORK")
    leaderIcon:SetSize(11, 11)
    leaderIcon:SetPoint("LEFT", roleIcon, "RIGHT", 1, 0)
    leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    leaderIcon:Hide()
    btn.leaderIcon = leaderIcon

    -- Unit Name Text (Top-Left, auto-clipped on the right)
    local nameText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("TOPLEFT", overlay, "TOPLEFT", 4, -3)
    nameText:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -18, -3)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    btn.nameText = nameText

    -- Raid Target Icon (Top-Right)
    local raidIcon = overlay:CreateTexture(nil, "ARTWORK")
    raidIcon:SetSize(13, 13)
    raidIcon:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -3, -3)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    raidIcon:Hide()
    btn.raidIcon = raidIcon

    -- Health / Status Text (Bottom-Right)
    local hpText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpText:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -4, 3)
    hpText:SetJustifyH("RIGHT")
    hpText:SetTextColor(0.95, 0.95, 0.95, 1)
    btn.hpText = hpText

    -- Dispel Badge (Center-Right)
    local dispelBadge = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    dispelBadge:SetSize(16, 16)
    dispelBadge:SetPoint("RIGHT", overlay, "RIGHT", -4, 0)
    dispelBadge:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    })
    dispelBadge:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    dispelBadge:Hide()
    local dispelTex = dispelBadge:CreateTexture(nil, "ARTWORK")
    dispelTex:SetPoint("TOPLEFT", 1, -1)
    dispelTex:SetPoint("BOTTOMRIGHT", -1, 1)
    dispelTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    dispelBadge.icon = dispelTex
    btn.dispelBadge = dispelBadge

    -- HoT / Buff Icons (Bottom-Left row, up to 4)
    btn.hotIcons = {}
    for i = 1, 4 do
        local f = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
        f:SetSize(13, 13)
        f:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 3 + ((i - 1) * 14), 2)
        f:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
        f:SetBackdropColor(0, 0, 0, 0.85)
        f:SetBackdropBorderColor(0.1, 0.8, 0.3, 0.9)
        local tex = f:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 1, -1)
        tex:SetPoint("BOTTOMRIGHT", -1, 1)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f.icon = tex
        local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
        cd:SetAllPoints(tex)
        cd:SetHideCountdownNumbers(true)
        f.cd = cd
        f:Hide()
        btn.hotIcons[i] = f
    end

    -- Debuff Icons (Center-Left, up to 2)
    btn.debuffIcons = {}
    for i = 1, 2 do
        local f = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
        f:SetSize(14, 14)
        f:SetPoint("LEFT", overlay, "LEFT", 4 + ((i - 1) * 15), -1)
        f:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
        f:SetBackdropColor(0, 0, 0, 0.85)
        f:SetBackdropBorderColor(0.85, 0.2, 0.2, 0.95)
        local tex = f:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 1, -1)
        tex:SetPoint("BOTTOMRIGHT", -1, 1)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f.icon = tex
        f:Hide()
        btn.debuffIcons[i] = f
    end

    -- Hover Highlight
    local hl = overlay:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(hpBar)
    hl:SetTexture(WHITE8X8)
    hl:SetVertexColor(1, 1, 1, 0.10)

    -- Tooltip & Hover Scripts
    btn:SetScript("OnEnter", function(self)
        local unit = self:GetAttribute("unit")
        if unit and UnitExists(unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(unit)
            GameTooltip:Show()
        elseif testModeCount > 0 and self.mockData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.mockData.name, 1, 1, 1)
            GameTooltip:AddLine("Test Mode Unit (" .. self.mockData.class .. ")", 0.7, 0.85, 1.0)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ApplyClickBindingsToButton(btn)
    return btn
end

local function UpdateButtonGeometry(btn)
    if not btn then return end
    local w = db.frameWidth or 98
    local h = db.frameHeight or 46
    local ph = db.showPowerBar and (db.powerHeight or 6) or 0
    btn:SetSize(w, h)
    btn.hpBar:ClearAllPoints()
    btn.hpBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    btn.hpBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, ph > 0 and (ph + 3) or 2)
    if ph > 0 then
        btn.powerBar:SetHeight(ph)
        btn.powerBar:Show()
    else
        btn.powerBar:Hide()
    end
end

local function UpdateMockUnitButton(btn, mock)
    if not btn or not mock then return end
    btn.mockData = mock
    UpdateButtonGeometry(btn)

    local c = (db.classColors and CLASS_COLORS[mock.class]) or { 0.15, 0.78, 0.35 }
    btn.hpBar:SetStatusBarColor(c[1], c[2], c[3], 1)
    btn.hpBar:SetMinMaxValues(0, 100)

    local leftPad = 4
    if db.showRoleIcon and mock.role and mock.role ~= "NONE" then
        btn.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        if mock.role == "TANK" then
            btn.roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
            btn.roleIcon:Show()
            leftPad = 17
        elseif mock.role == "HEALER" then
            btn.roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
            btn.roleIcon:Show()
            leftPad = 17
        elseif mock.role == "DAMAGER" then
            btn.roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
            btn.roleIcon:Show()
            leftPad = 17
        else
            btn.roleIcon:Hide()
        end
    else
        btn.roleIcon:Hide()
    end

    if db.showLeaderIcon and mock.leader then
        btn.leaderIcon:ClearAllPoints()
        btn.leaderIcon:SetPoint("TOPLEFT", btn.overlay, "TOPLEFT", leftPad, -3)
        btn.leaderIcon:Show()
        leftPad = leftPad + 13
    else
        btn.leaderIcon:Hide()
    end

    btn.nameText:ClearAllPoints()
    btn.nameText:SetPoint("TOPLEFT", btn.overlay, "TOPLEFT", leftPad, -3)
    btn.nameText:SetPoint("TOPRIGHT", btn.overlay, "TOPRIGHT", -18, -3)
    btn.nameText:SetText(mock.name)
    btn.nameText:SetTextColor(1, 1, 1, 1)

    if db.showRaidTarget and mock.raidIcon then
        SetRaidTargetIconTexture(btn.raidIcon, mock.raidIcon)
        btn.raidIcon:Show()
    else
        btn.raidIcon:Hide()
    end

    if mock.dead then
        btn.hpBar:SetValue(0)
        btn.incBar:Hide()
        btn.hpText:SetText("|cffff4444DEAD|r")
        btn.powerBar:SetValue(0)
    else
        local hpVal = math.floor(mock.hp * 100)
        btn.hpBar:SetValue(hpVal)
        btn.hpText:SetText(FormatHealthValue(hpVal * 40, 4000, db.healthFormat))
        if db.showIncomingHeals and mock.inc and mock.inc > 0 then
            btn.incBar:SetMinMaxValues(0, 100)
            btn.incBar:SetValue(math.min(100, hpVal + math.floor(mock.inc * 100)))
            btn.incBar:Show()
        else
            btn.incBar:Hide()
        end
        btn.powerBar:SetStatusBarColor(0.15, 0.48, 0.95, 1)
        btn.powerBar:SetMinMaxValues(0, 100)
        btn.powerBar:SetValue(math.floor((mock.mp or 0.8) * 100))
    end

    -- Dispel & Threat Border
    local dc = db.showDispelHighlight and mock.dispel and DISPEL_COLORS[mock.dispel]
    if dc then
        btn.border:SetBackdropBorderColor(dc[1], dc[2], dc[3], 1)
        btn.dispelBadge:SetBackdropBorderColor(dc[1], dc[2], dc[3], 1)
        btn.dispelBadge.icon:SetTexture("Interface\\Icons\\Spell_Holy_DispelMagic")
        btn.dispelBadge:Show()
    elseif db.showThreatBorder and mock.threat and mock.threat >= 2 then
        btn.border:SetBackdropBorderColor(1.0, 0.15, 0.15, 0.95)
        btn.dispelBadge:Hide()
    else
        btn.border:SetBackdropBorderColor(0, 0, 0, 0)
        btn.dispelBadge:Hide()
    end

    -- HoT preview
    for i = 1, 4 do
        btn.hotIcons[i]:Hide()
    end
    if db.showHoTs and mock.hot then
        local _, icon = SafeGetSpellInfo(mock.hot)
        btn.hotIcons[1].icon:SetTexture(icon or "Interface\\Icons\\Spell_Holy_Renew")
        btn.hotIcons[1]:Show()
    end

    for i = 1, 2 do
        btn.debuffIcons[i]:Hide()
    end

    btn:SetAlpha(mock.oor and (db.outOfRangeAlpha or 0.42) or 1.0)
end

function TimelessHeal:UpdateUnitButton(btn)
    if not btn then return end
    if testModeCount > 0 and btn.mockData then
        UpdateMockUnitButton(btn, btn.mockData)
        return
    end

    local unit = btn:GetAttribute("unit")
    if not unit or not UnitExists(unit) then return end

    UpdateButtonGeometry(btn)

    local name = UnitName(unit) or unit
    local _, classToken = UnitClass(unit)
    local isConnected = UnitIsConnected(unit)
    local isDead = UnitIsDead(unit)
    local isGhost = UnitIsGhost(unit)
    local curHp = UnitHealth(unit) or 0
    local maxHp = UnitHealthMax(unit) or 1
    if maxHp <= 0 then maxHp = 1 end

    -- Role & Leader Icons
    local leftPad = 4
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or "NONE"
    if db.showRoleIcon and (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
        btn.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        if role == "TANK" then
            btn.roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
        elseif role == "HEALER" then
            btn.roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
        else
            btn.roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
        end
        btn.roleIcon:Show()
        leftPad = 17
    else
        btn.roleIcon:Hide()
    end

    if db.showLeaderIcon and UnitIsGroupLeader and UnitIsGroupLeader(unit) then
        btn.leaderIcon:ClearAllPoints()
        btn.leaderIcon:SetPoint("TOPLEFT", btn.overlay, "TOPLEFT", leftPad, -3)
        btn.leaderIcon:Show()
        leftPad = leftPad + 13
    else
        btn.leaderIcon:Hide()
    end

    btn.nameText:ClearAllPoints()
    btn.nameText:SetPoint("TOPLEFT", btn.overlay, "TOPLEFT", leftPad, -3)
    btn.nameText:SetPoint("TOPRIGHT", btn.overlay, "TOPRIGHT", -18, -3)
    btn.nameText:SetText(name)

    -- Raid Target Icon
    local rtIndex = db.showRaidTarget and GetRaidTargetIndex and GetRaidTargetIndex(unit)
    if rtIndex and rtIndex >= 1 and rtIndex <= 8 then
        SetRaidTargetIconTexture(btn.raidIcon, rtIndex)
        btn.raidIcon:Show()
    else
        btn.raidIcon:Hide()
    end

    -- Health Bar & Status Text
    btn.hpBar:SetMinMaxValues(0, maxHp)
    if not isConnected then
        btn.hpBar:SetValue(maxHp)
        btn.hpBar:SetStatusBarColor(0.4, 0.4, 0.45, 0.85)
        btn.hpText:SetText("|cffaaaaaaOFFLINE|r")
        btn.incBar:Hide()
    elseif isDead or isGhost or UnitIsDeadOrGhost(unit) then
        btn.hpBar:SetValue(0)
        btn.hpBar:SetStatusBarColor(0.25, 0.25, 0.28, 0.85)
        btn.hpText:SetText(isGhost and "|cffaaaaaaGHOST|r" or "|cffff4444DEAD|r")
        btn.incBar:Hide()
    else
        btn.hpBar:SetValue(curHp)
        if db.classColors and classToken and CLASS_COLORS[classToken] then
            local cc = CLASS_COLORS[classToken]
            btn.hpBar:SetStatusBarColor(cc[1], cc[2], cc[3], 1)
        else
            local pct = curHp / maxHp
            local r = pct < 0.5 and 0.95 or (1.0 - (pct - 0.5) * 1.6)
            local g = pct > 0.5 and 0.85 or (pct * 1.7)
            btn.hpBar:SetStatusBarColor(r, g, 0.20, 1)
        end
        btn.hpText:SetText(FormatHealthValue(curHp, maxHp, db.healthFormat))

        -- Incoming Heals
        local inc = (db.showIncomingHeals and UnitGetIncomingHeals and UnitGetIncomingHeals(unit)) or 0
        if inc and inc > 0 and curHp < maxHp then
            btn.incBar:SetMinMaxValues(0, maxHp)
            btn.incBar:SetValue(math.min(maxHp, curHp + inc))
            btn.incBar:Show()
        else
            btn.incBar:Hide()
        end
    end

    -- Power Bar
    if db.showPowerBar then
        local pType = (UnitPowerType and UnitPowerType(unit)) or 0
        local pColor = POWER_COLORS[pType] or POWER_COLORS[0]
        local curP = (UnitPower and UnitPower(unit)) or 0
        local maxP = (UnitPowerMax and UnitPowerMax(unit)) or 1
        if maxP <= 0 then maxP = 1 end
        btn.powerBar:SetStatusBarColor(pColor[1], pColor[2], pColor[3], 1)
        btn.powerBar:SetMinMaxValues(0, maxP)
        btn.powerBar:SetValue((isConnected and not isDead and not isGhost) and curP or 0)
    end

    -- Scan Auras: HoTs (HELPFUL|PLAYER) & Debuffs/Dispels (HARMFUL)
    local hotCount = 0
    if db.showHoTs and isConnected and not isDead and not isGhost then
        for i = 1, 40 do
            local auraName, icon, _, _, duration, expTime, source = SafeGetAura(unit, i, "HELPFUL")
            if not auraName then break end
            if source == "player" and icon then
                hotCount = hotCount + 1
                local hotFrame = btn.hotIcons[hotCount]
                if hotFrame then
                    hotFrame.icon:SetTexture(icon)
                    if duration and duration > 0 and expTime and expTime > 0 then
                        hotFrame.cd:SetCooldown(expTime - duration, duration)
                    else
                        hotFrame.cd:Clear()
                    end
                    hotFrame:Show()
                end
                if hotCount >= 4 then break end
            end
        end
    end
    for i = hotCount + 1, 4 do
        btn.hotIcons[i]:Hide()
    end

    local foundDispelType, foundDispelIcon = nil, nil
    local debuffCount = 0
    local canDispelTable = CLASS_CAN_DISPEL[PLAYER_CLASS]

    if isConnected and not isDead and not isGhost then
        for i = 1, 40 do
            local auraName, icon, _, dispelType = SafeGetAura(unit, i, "HARMFUL")
            if not auraName then break end
            if dispelType and DISPEL_COLORS[dispelType] then
                if not foundDispelType and (not canDispelTable or canDispelTable[dispelType]) then
                    foundDispelType = dispelType
                    foundDispelIcon = icon
                end
            end
            if db.showDebuffIcons and icon and debuffCount < 2 then
                debuffCount = debuffCount + 1
                local dFrame = btn.debuffIcons[debuffCount]
                dFrame.icon:SetTexture(icon)
                if dispelType and DISPEL_COLORS[dispelType] then
                    local dc = DISPEL_COLORS[dispelType]
                    dFrame:SetBackdropBorderColor(dc[1], dc[2], dc[3], 1)
                else
                    dFrame:SetBackdropBorderColor(0.85, 0.2, 0.2, 0.95)
                end
                dFrame:Show()
            end
        end
    end
    for i = debuffCount + 1, 2 do
        btn.debuffIcons[i]:Hide()
    end

    -- Border Priority: Dispel > Threat > None
    if db.showDispelHighlight and foundDispelType and DISPEL_COLORS[foundDispelType] then
        local dc = DISPEL_COLORS[foundDispelType]
        btn.border:SetBackdropBorderColor(dc[1], dc[2], dc[3], 1)
        btn.dispelBadge:SetBackdropBorderColor(dc[1], dc[2], dc[3], 1)
        btn.dispelBadge.icon:SetTexture(foundDispelIcon or "Interface\\Icons\\Spell_Holy_DispelMagic")
        btn.dispelBadge:Show()
    else
        btn.dispelBadge:Hide()
        local threat = (db.showThreatBorder and UnitThreatSituation and UnitThreatSituation(unit)) or 0
        if threat and threat >= 2 then
            if threat >= 3 then
                btn.border:SetBackdropBorderColor(1.0, 0.12, 0.12, 1.0)
            else
                btn.border:SetBackdropBorderColor(1.0, 0.60, 0.10, 0.9)
            end
        else
            btn.border:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end

    -- Range Check Alpha
    local inRange = true
    if not UnitIsUnit(unit, "player") and isConnected then
        local rangeSpell = CLASS_RANGE_SPELL[PLAYER_CLASS]
        local spellInRange = rangeSpell and SafeIsSpellInRange(rangeSpell, unit)
        if spellInRange ~= nil then
            inRange = spellInRange
        elseif UnitInRange then
            local r, checked = UnitInRange(unit)
            if checked then inRange = r end
        end
    end
    btn:SetAlpha(inRange and 1.0 or (db.outOfRangeAlpha or 0.42))
end

-- =========================================================================
-- 6. Main Container, Header Bar, Self/Target Frames & Layout Engine
-- =========================================================================
local function SaveAnchorPosition(frame, anchorTable)
    local point, _, relativePoint, x, y = frame:GetPoint()
    anchorTable.point = point or "CENTER"
    anchorTable.relativePoint = relativePoint or "CENTER"
    anchorTable.x = math.floor((x or 0) + 0.5)
    anchorTable.y = math.floor((y or 0) + 0.5)
end

local function CreateHeaderQuickBtn(parent, label, width, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 18)
    b:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    })
    b:SetBackdropColor(0.12, 0.15, 0.20, 0.95)
    b:SetBackdropBorderColor(0.28, 0.35, 0.45, 1)
    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("CENTER")
    txt:SetText(label)
    b.text = txt
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.28, 0.35, 0.45, 1)
    end)
    b:SetScript("OnClick", onClick)
    return b
end

function TimelessHeal:BuildFrames()
    if mainContainer then return end

    mainContainer = CreateFrame("Frame", "TimelessForever_HealContainer", UIParent)
    mainContainer:SetSize(400, 120)
    mainContainer:SetMovable(true)
    mainContainer:SetClampedToScreen(true)
    mainContainer:SetScale(db.scale or 1.0)

    local anc = db.anchor or DEFAULT_DB.anchor
    mainContainer:SetPoint(anc.point or "CENTER", UIParent, anc.relativePoint or "CENTER", anc.x or -280, anc.y or -80)

    -- Draggable Header Bar (shown when unlocked or in Test Mode)
    headerBar = CreateFrame("Frame", "TimelessForever_HealHeaderBar", mainContainer, "BackdropTemplate")
    headerBar:SetPoint("BOTTOMLEFT", mainContainer, "TOPLEFT", 0, 3)
    headerBar:SetSize(250, 22)
    headerBar:EnableMouse(true)
    headerBar:RegisterForDrag("LeftButton")
    headerBar:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    })
    headerBar:SetBackdropColor(0.05, 0.07, 0.10, 0.92)
    headerBar:SetBackdropBorderColor(0.0, 0.68, 0.95, 0.85)
    headerBar:SetScript("OnDragStart", function()
        if not db.locked then
            mainContainer:StartMoving()
        end
    end)
    headerBar:SetScript("OnDragStop", function()
        mainContainer:StopMovingOrSizing()
        SaveAnchorPosition(mainContainer, db.anchor)
    end)

    local titleTxt = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleTxt:SetPoint("LEFT", headerBar, "LEFT", 6, 0)
    titleTxt:SetText("|cff00ccffTimeless|r|cffffffffHeal|r")

    local lockBtn = CreateHeaderQuickBtn(headerBar, "Lock", 42, function()
        db.locked = true
        TimelessHeal:UpdateLayout()
        print(CHAT_PREFIX .. "Frames |cffff5555LOCKED|r. Type |cffffd100/th|r to configure or unlock.")
    end)
    lockBtn:SetPoint("RIGHT", headerBar, "RIGHT", -3, 0)

    local cfgBtn = CreateHeaderQuickBtn(headerBar, "Config", 48, function()
        TimelessHeal:ToggleConfigWindow()
    end)
    cfgBtn:SetPoint("RIGHT", lockBtn, "LEFT", -3, 0)

    local testBtn = CreateHeaderQuickBtn(headerBar, "Test", 42, function()
        if testModeCount == 0 then
            TimelessHeal:SetTestMode(5)
        elseif testModeCount == 5 then
            TimelessHeal:SetTestMode(20)
        else
            TimelessHeal:SetTestMode(0)
        end
    end)
    testBtn:SetPoint("RIGHT", cfgBtn, "LEFT", -3, 0)
    headerBar.testBtn = testBtn

    -- Pre-allocate 40 Grid Unit Buttons
    for i = 1, MAX_GRID_FRAMES do
        gridFrames[i] = CreateUnitButton("TimelessForever_HealUnitBtn" .. i, mainContainer)
        gridFrames[i]:Hide()
    end

    -- Dedicated Self Bar
    selfFrame = CreateUnitButton("TimelessForever_HealSelfBtn", UIParent)
    selfFrame:SetAttribute("unit", "player")
    selfFrame:SetMovable(true)
    selfFrame:SetClampedToScreen(true)
    local sAnc = db.selfAnchor or DEFAULT_DB.selfAnchor
    selfFrame:SetPoint(sAnc.point or "CENTER", UIParent, sAnc.relativePoint or "CENTER", sAnc.x or 0, sAnc.y or -165)
    selfFrame:RegisterForDrag("LeftButton")
    selfFrame:SetScript("OnDragStart", function(self)
        if not db.locked and IsShiftKeyDown() then self:StartMoving() end
    end)
    selfFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnchorPosition(self, db.selfAnchor)
    end)
    selfFrame:Hide()

    -- Dedicated Target Bar
    targetFrame = CreateUnitButton("TimelessForever_HealTargetBtn", UIParent)
    targetFrame:SetAttribute("unit", "target")
    targetFrame:SetMovable(true)
    targetFrame:SetClampedToScreen(true)
    local tAnc = db.targetAnchor or DEFAULT_DB.targetAnchor
    targetFrame:SetPoint(tAnc.point or "CENTER", UIParent, tAnc.relativePoint or "CENTER", tAnc.x or 150, tAnc.y or -165)
    targetFrame:RegisterForDrag("LeftButton")
    targetFrame:SetScript("OnDragStart", function(self)
        if not db.locked and IsShiftKeyDown() then self:StartMoving() end
    end)
    targetFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnchorPosition(self, db.targetAnchor)
    end)
    targetFrame:Hide()
end

function TimelessHeal:ApplyBlizzardPartyVisibility()
    if InCombatLockdown() then return end
    if db.hideBlizzParty then
        for i = 1, 4 do
            local pf = _G["PartyMemberFrame" .. i]
            if pf then
                pf:UnregisterAllEvents()
                pf:Hide()
            end
        end
        if _G.CompactPartyFrame and not _G.CompactPartyFrame:IsForbidden() then
            _G.CompactPartyFrame:Hide()
        end
    end
end

function TimelessHeal:UpdateAllBindings()
    if InCombatLockdown() then
        pendingBindingsUpdate = true
        return
    end
    pendingBindingsUpdate = false
    for i = 1, MAX_GRID_FRAMES do
        if gridFrames[i] then
            ApplyClickBindingsToButton(gridFrames[i])
        end
    end
    if selfFrame then ApplyClickBindingsToButton(selfFrame) end
    if targetFrame then ApplyClickBindingsToButton(targetFrame) end
    self:HookBlizzardUnitFrames()
end

function TimelessHeal:UpdateLayout()
    if not mainContainer then return end
    if InCombatLockdown() then
        pendingLayoutUpdate = true
        return
    end
    pendingLayoutUpdate = false

    if not db.enabled then
        UnregisterUnitWatch(selfFrame)
        UnregisterUnitWatch(targetFrame)
        selfFrame:Hide()
        targetFrame:Hide()
        for i = 1, MAX_GRID_FRAMES do
            UnregisterUnitWatch(gridFrames[i])
            gridFrames[i]:Hide()
        end
        mainContainer:Hide()
        return
    end

    mainContainer:Show()
    mainContainer:SetScale(db.scale or 1.0)
    selfFrame:SetScale(db.scale or 1.0)
    targetFrame:SetScale(db.scale or 1.0)

    -- Header Bar visibility
    if not db.locked or testModeCount > 0 then
        headerBar:Show()
        if testModeCount > 0 then
            headerBar.testBtn.text:SetText("|cff00ff00Test:" .. testModeCount .. "|r")
        else
            headerBar.testBtn.text:SetText("Test")
        end
    else
        headerBar:Hide()
    end

    local w = db.frameWidth or 98
    local h = db.frameHeight or 46
    local gap = db.spacing or 4
    local cols = math.max(1, db.columns or 5)
    local isHoriz = (db.orientation ~= "VERTICAL")

    -- Build active unit list (or mock units if in Test Mode)
    local units = {}
    if testModeCount > 0 then
        for i = 1, testModeCount do
            units[#units + 1] = "mock" .. i
        end
    else
        local inRaid = IsInRaid and IsInRaid()
        local inGroup = IsInGroup and IsInGroup()

        if inRaid then
            if db.showRaid then
                for i = 1, 40 do
                    local u = "raid" .. i
                    if UnitExists(u) then
                        units[#units + 1] = u
                    end
                end
            end
        elseif inGroup then
            if db.showParty then
                units[#units + 1] = "player"
                for i = 1, 4 do
                    units[#units + 1] = "party" .. i
                end
                if db.includePets then
                    units[#units + 1] = "pet"
                    for i = 1, 4 do
                        units[#units + 1] = "partypet" .. i
                    end
                end
            end
        else
            if db.showSolo then
                units[#units + 1] = "player"
                if db.includePets then
                    units[#units + 1] = "pet"
                end
            end
        end
    end

    for i = 1, MAX_GRID_FRAMES do
        local btn = gridFrames[i]
        local u = units[i]
        UnregisterUnitWatch(btn)
        btn:ClearAllPoints()

        local row, col
        if isHoriz then
            col = (i - 1) % cols
            row = math.floor((i - 1) / cols)
        else
            row = (i - 1) % cols
            col = math.floor((i - 1) / cols)
        end

        btn:SetPoint("TOPLEFT", mainContainer, "TOPLEFT", col * (w + gap), -row * (h + gap))

        if u then
            if testModeCount > 0 then
                btn:SetAttribute("unit", "player")
                btn.mockData = MOCK_ROSTER[((i - 1) % #MOCK_ROSTER) + 1]
                btn:Show()
                UpdateMockUnitButton(btn, btn.mockData)
            else
                btn.mockData = nil
                btn:SetAttribute("unit", u)
                RegisterUnitWatch(btn)
                if UnitExists(u) then
                    btn:Show()
                    self:UpdateUnitButton(btn)
                end
            end
        else
            btn.mockData = nil
            btn:SetAttribute("unit", nil)
            btn:Hide()
        end
    end

    local totalShown = math.max(1, #units)
    local numCols = isHoriz and math.min(cols, totalShown) or math.ceil(totalShown / cols)
    local numRows = isHoriz and math.ceil(totalShown / cols) or math.min(cols, totalShown)
    local totalW = math.max(250, numCols * w + math.max(0, numCols - 1) * gap)
    local totalH = math.max(h, numRows * h + math.max(0, numRows - 1) * gap)
    mainContainer:SetSize(totalW, totalH)
    headerBar:SetWidth(math.max(250, totalW))

    -- Dedicated Self Bar
    UnregisterUnitWatch(selfFrame)
    if db.showSelfBar then
        selfFrame:SetAttribute("unit", "player")
        RegisterUnitWatch(selfFrame)
        selfFrame:Show()
        self:UpdateUnitButton(selfFrame)
    else
        selfFrame:Hide()
    end

    -- Dedicated Target Bar
    UnregisterUnitWatch(targetFrame)
    if db.showTargetBar then
        targetFrame:SetAttribute("unit", "target")
        RegisterUnitWatch(targetFrame)
        self:UpdateUnitButton(targetFrame)
    else
        targetFrame:Hide()
    end

    self:ApplyBlizzardPartyVisibility()
end

function TimelessHeal:UpdateAllVisibleUnits()
    if not db or not db.enabled then return end
    for i = 1, MAX_GRID_FRAMES do
        local btn = gridFrames[i]
        if btn and btn:IsShown() then
            self:UpdateUnitButton(btn)
        end
    end
    if selfFrame and selfFrame:IsShown() then
        self:UpdateUnitButton(selfFrame)
    end
    if targetFrame and targetFrame:IsShown() then
        self:UpdateUnitButton(targetFrame)
    end
end

function TimelessHeal:SetTestMode(count)
    if InCombatLockdown() then
        print(CHAT_PREFIX .. "|cffff5555Cannot toggle Test Mode during combat.|r")
        return
    end
    testModeCount = count or 0
    self:UpdateLayout()
    if testModeCount > 0 then
        print(CHAT_PREFIX .. string.format("Test Mode |cff00ff00ACTIVE (%d units)|r. Drag the top bar to position your grid!", testModeCount))
    else
        print(CHAT_PREFIX .. "Test Mode |cffff5555OFF|r.")
    end
end

-- =========================================================================
-- 7. Standalone 4-Tab Configuration Window (/th, /fh, /tfh)
-- =========================================================================
local configWin
local allGuiWidgets = {}

local function RefreshConfigWidgets()
    for _, w in ipairs(allGuiWidgets) do
        if w.Refresh then w:Refresh() end
    end
    local LibStub = _G.LibStub
    if LibStub then
        local reg = LibStub("AceConfigRegistry-3.0", true)
        if reg then
            pcall(reg.NotifyChange, reg, "TimelessForever")
            pcall(reg.NotifyChange, reg, "Timeless")
        end
    end
end

local function CreateCheckbox(parent, label, x, y, getFn, setFn)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    txt:SetText(label)

    function cb:Refresh()
        self:SetChecked(getFn() and true or false)
    end
    cb:SetScript("OnShow", cb.Refresh)
    cb:SetScript("OnClick", function(self)
        setFn(self:GetChecked() and true or false)
        RefreshConfigWidgets()
    end)
    table.insert(allGuiWidgets, cb)
    return cb
end

local sliderIdx = 0
local function CreateSlider(parent, label, x, y, minV, maxV, stepV, getFn, setFn, fmtFn)
    sliderIdx = sliderIdx + 1
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(240, 44)
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local title = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)

    local valTxt = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valTxt:SetPoint("TOPRIGHT", 0, 0)

    local sName = "TimelessHealCfgSlider_" .. sliderIdx
    local s = CreateFrame("Slider", sName, holder, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 0, -16)
    s:SetPoint("TOPRIGHT", 0, -16)
    s:SetHeight(16)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(stepV)
    s:SetObeyStepOnDrag(true)
    if _G[sName .. "Low"] then _G[sName .. "Low"]:SetText(tostring(minV)) end
    if _G[sName .. "High"] then _G[sName .. "High"]:SetText(tostring(maxV)) end

    local updating = false
    function holder:Refresh()
        local v = getFn()
        updating = true
        s:SetValue(v)
        updating = false
        valTxt:SetText(fmtFn and fmtFn(v) or tostring(v))
    end
    s:SetScript("OnShow", function() holder:Refresh() end)
    s:SetScript("OnValueChanged", function(_, v)
        if updating then return end
        if stepV >= 1 then
            v = math.floor(v + 0.5)
        else
            v = math.floor((v / stepV) + 0.5) * stepV
        end
        valTxt:SetText(fmtFn and fmtFn(v) or tostring(v))
        setFn(v)
    end)

    table.insert(allGuiWidgets, holder)
    return holder
end

local function CreateActionBtn(parent, text, x, y, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetSize(w or 150, h or 24)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

function TimelessHeal:BuildConfigWindow()
    if configWin then return configWin end

    configWin = CreateFrame("Frame", "TimelessForever_HealConfigFrame", UIParent, "BackdropTemplate")
    configWin:SetSize(740, 520)
    configWin:SetPoint("CENTER")
    configWin:SetFrameStrata("DIALOG")
    configWin:SetMovable(true)
    configWin:EnableMouse(true)
    configWin:SetClampedToScreen(true)
    configWin:RegisterForDrag("LeftButton")
    configWin:SetScript("OnDragStart", configWin.StartMoving)
    configWin:SetScript("OnDragStop", configWin.StopMovingOrSizing)
    configWin:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 2,
    })
    configWin:SetBackdropColor(0.06, 0.07, 0.09, 0.97)
    configWin:SetBackdropBorderColor(0.0, 0.65, 0.95, 1.0)
    configWin:Hide()

    -- Title Bar
    local title = configWin:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText("|T" .. ICON_TEXTURE .. ":16:16:0:0|t |cff00ccffTimelessForever|r |cffffffffHeal|r  |cff888888Click-Cast & Raid Frame Studio|r")

    local closeBtn = CreateFrame("Button", nil, configWin, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    -- Top Navigation Tabs
    local tabNames = {
        "1. Click-Casting",
        "2. Grid & Layout",
        "3. Bars & Indicators",
        "4. Presets & Test Mode",
    }
    local tabPages = {}
    local tabBtns = {}

    local function SelectTab(idx)
        for i, page in ipairs(tabPages) do
            if i == idx then
                page:Show()
                tabBtns[i]:SetBackdropColor(0.0, 0.48, 0.78, 0.95)
                tabBtns[i].txt:SetTextColor(1, 1, 1)
            else
                page:Hide()
                tabBtns[i]:SetBackdropColor(0.11, 0.13, 0.17, 0.9)
                tabBtns[i].txt:SetTextColor(0.75, 0.78, 0.82)
            end
        end
        RefreshConfigWidgets()
    end

    for i, name in ipairs(tabNames) do
        local tb = CreateFrame("Button", nil, configWin, "BackdropTemplate")
        tb:SetSize(172, 28)
        tb:SetPoint("TOPLEFT", configWin, "TOPLEFT", 16 + ((i - 1) * 178), -44)
        tb:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
        tb:SetBackdropBorderColor(0.24, 0.28, 0.35, 1)
        local txt = tb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("CENTER")
        txt:SetText(name)
        tb.txt = txt
        tb:SetScript("OnClick", function() SelectTab(i) end)
        tabBtns[i] = tb

        local page = CreateFrame("Frame", nil, configWin, "BackdropTemplate")
        page:SetPoint("TOPLEFT", configWin, "TOPLEFT", 16, -78)
        page:SetPoint("BOTTOMRIGHT", configWin, "BOTTOMRIGHT", -16, 46)
        page:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
        page:SetBackdropColor(0.04, 0.05, 0.07, 0.9)
        page:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
        page:Hide()
        tabPages[i] = page
    end

    -- =====================================================================
    -- TAB 1: Click-Casting (Scrollable Slot Editor + Drag & Drop Spell)
    -- =====================================================================
    local p1 = tabPages[1]
    local p1Desc = p1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p1Desc:SetPoint("TOPLEFT", 12, -10)
    p1Desc:SetText("Drag any spell from your Spellbook, or click |cffffd100Menu|r / |cffffd100Target|r on any row for Blizzard Right-Click Menu / Target!")

    CreateActionBtn(p1, "Right-Click = Blizz Menu", 390, -6, 145, 22, function()
        db.menuClickKey = "RightButton"
        db.spells["RightButton"] = "togglemenu"
        TimelessHeal:UpdateAllBindings()
        RefreshConfigWidgets()
        print(CHAT_PREFIX .. "|cffffd100Right-Click|r is now set to open the |cff00ff00Blizzard Right-Click Menu|r!")
    end)

    CreateActionBtn(p1, "Alt+Right = Blizz Menu", 540, -6, 155, 22, function()
        db.menuClickKey = "Alt-RightButton"
        db.spells["Alt-RightButton"] = "togglemenu"
        TimelessHeal:UpdateAllBindings()
        RefreshConfigWidgets()
        print(CHAT_PREFIX .. "|cffffd100Alt + Right-Click|r is now set to open the |cff00ff00Blizzard Right-Click Menu|r!")
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "TimelessHealClickCastScroll", p1, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", p1, "TOPLEFT", 10, -34)
    scrollFrame:SetPoint("BOTTOMRIGHT", p1, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(660, #BINDING_SLOTS * 32 + 12)
    scrollFrame:SetScrollChild(scrollChild)

    for idx, slot in ipairs(BINDING_SLOTS) do
        local rowY = -6 - ((idx - 1) * 32)
        local row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        row:SetSize(655, 28)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, rowY)
        row:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
        row:SetBackdropColor(0.08, 0.10, 0.13, 0.85)
        row:SetBackdropBorderColor(0.18, 0.20, 0.25, 0.9)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
        lbl:SetWidth(160)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(slot.label)

        local iconBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        iconBtn:SetSize(22, 22)
        iconBtn:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
        iconBtn:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
        iconBtn:SetBackdropBorderColor(0.3, 0.35, 0.4, 1)
        local iconTex = iconBtn:CreateTexture(nil, "ARTWORK")
        iconTex:SetPoint("TOPLEFT", 1, -1)
        iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        eb:SetSize(245, 22)
        eb:SetPoint("LEFT", iconBtn, "RIGHT", 10, 0)
        eb:SetAutoFocus(false)

        local function SaveSlotValue(val)
            val = strtrim(val or "")
            db.spells[slot.key] = val
            TimelessHeal:UpdateAllBindings()
            row:Refresh()
        end

        local function HandleCursorDrop()
            local infoType, id, subType, spellID = GetCursorInfo()
            if infoType == "spell" then
                local sName = SafeGetSpellInfo(spellID or id)
                if sName then
                    ClearCursor()
                    eb:SetText(sName)
                    SaveSlotValue(sName)
                end
            end
        end

        iconBtn:SetScript("OnReceiveDrag", HandleCursorDrop)
        iconBtn:SetScript("OnClick", HandleCursorDrop)
        eb:SetScript("OnReceiveDrag", HandleCursorDrop)

        eb:SetScript("OnEnterPressed", function(self)
            SaveSlotValue(self:GetText())
            self:ClearFocus()
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            SaveSlotValue(self:GetText())
        end)

        CreateActionBtn(row, "Menu", 456, -3, 60, 22, function()
            eb:SetText("togglemenu")
            SaveSlotValue("togglemenu")
            print(CHAT_PREFIX .. "|cffffd100" .. slot.label .. "|r set to open the |cff00ff00Blizzard Right-Click Menu|r!")
        end)

        CreateActionBtn(row, "Target", 520, -3, 60, 22, function()
            eb:SetText("target")
            SaveSlotValue("target")
            print(CHAT_PREFIX .. "|cffffd100" .. slot.label .. "|r set to |cff00ff00Target Unit|r!")
        end)

        CreateActionBtn(row, "Clear", 584, -3, 60, 22, function()
            eb:SetText("")
            SaveSlotValue("")
        end)

        function row:Refresh()
            local cur = (db and db.spells and db.spells[slot.key]) or ""
            if not eb:HasFocus() then
                eb:SetText(cur)
            end
            local low = string.lower(strtrim(cur))
            local _, tex = SafeGetSpellInfo(cur)
            if low == "togglemenu" or low == "menu" then
                iconTex:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
            elseif low == "target" then
                iconTex:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
            elseif tex then
                iconTex:SetTexture(tex)
            elseif cur ~= "" then
                iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            else
                iconTex:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
            end
        end

        table.insert(allGuiWidgets, row)
    end

    -- =====================================================================
    -- TAB 2: Grid & Layout
    -- =====================================================================
    local p2 = tabPages[2]
    CreateCheckbox(p2, "Enable TimelessHeal Unit Frames", 18, -16,
        function() return db.enabled end,
        function(v) db.enabled = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Lock Frame Positions (Hide Drag Header)", 18, -46,
        function() return db.locked end,
        function(v) db.locked = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Show Frames When Solo", 18, -76,
        function() return db.showSolo end,
        function(v) db.showSolo = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Show Frames in Party (5-Man)", 18, -106,
        function() return db.showParty end,
        function(v) db.showParty = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Show Frames in Raid (10-40 Man)", 18, -136,
        function() return db.showRaid end,
        function(v) db.showRaid = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Include Party / Solo Pets", 18, -166,
        function() return db.includePets end,
        function(v) db.includePets = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Show Dedicated Self Bar (Shift+Drag to Move)", 18, -196,
        function() return db.showSelfBar end,
        function(v) db.showSelfBar = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p2, "Show Dedicated Target Bar (Shift+Drag to Move)", 18, -226,
        function() return db.showTargetBar end,
        function(v) db.showTargetBar = v; TimelessHeal:UpdateLayout() end)

    CreateActionBtn(p2, "Orientation: Horizontal", 18, -268, 165, 24, function()
        db.orientation = "HORIZONTAL"
        TimelessHeal:UpdateLayout()
    end)
    CreateActionBtn(p2, "Orientation: Vertical", 190, -268, 165, 24, function()
        db.orientation = "VERTICAL"
        TimelessHeal:UpdateLayout()
    end)

    -- Right Column Sliders on Tab 2
    CreateSlider(p2, "Frame Width", 410, -16, 60, 180, 2,
        function() return db.frameWidth or 98 end,
        function(v) db.frameWidth = v; TimelessHeal:UpdateLayout() end,
        function(v) return v .. " px" end)

    CreateSlider(p2, "Frame Height", 410, -70, 28, 100, 2,
        function() return db.frameHeight or 46 end,
        function(v) db.frameHeight = v; TimelessHeal:UpdateLayout() end,
        function(v) return v .. " px" end)

    CreateSlider(p2, "Mana / Power Bar Height", 410, -124, 3, 16, 1,
        function() return db.powerHeight or 6 end,
        function(v) db.powerHeight = v; TimelessHeal:UpdateLayout() end,
        function(v) return v .. " px" end)

    CreateSlider(p2, "Columns / Units Per Row", 410, -178, 1, 10, 1,
        function() return db.columns or 5 end,
        function(v) db.columns = v; TimelessHeal:UpdateLayout() end)

    CreateSlider(p2, "Grid Spacing", 410, -232, 0, 16, 1,
        function() return db.spacing or 4 end,
        function(v) db.spacing = v; TimelessHeal:UpdateLayout() end,
        function(v) return v .. " px" end)

    CreateSlider(p2, "Overall Frame Scale", 410, -286, 0.6, 1.6, 0.05,
        function() return db.scale or 1.0 end,
        function(v) db.scale = v; TimelessHeal:UpdateLayout() end,
        function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)

    CreateSlider(p2, "Out of Range Opacity", 410, -340, 0.15, 0.90, 0.05,
        function() return db.outOfRangeAlpha or 0.42 end,
        function(v) db.outOfRangeAlpha = v; TimelessHeal:UpdateAllVisibleUnits() end,
        function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)

    -- =====================================================================
    -- TAB 3: Bars & Indicators
    -- =====================================================================
    local p3 = tabPages[3]
    CreateCheckbox(p3, "Class Colored Health Bars", 18, -16,
        function() return db.classColors end,
        function(v) db.classColors = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Mana / Power Bar", 18, -46,
        function() return db.showPowerBar end,
        function(v) db.showPowerBar = v; TimelessHeal:UpdateLayout() end)

    CreateCheckbox(p3, "Show Incoming Heal Prediction Bar", 18, -76,
        function() return db.showIncomingHeals end,
        function(v) db.showIncomingHeals = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Highlight Dispellable Debuffs (Border + Badge)", 18, -106,
        function() return db.showDispelHighlight end,
        function(v) db.showDispelHighlight = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Active Player HoT / Shield Icons", 18, -136,
        function() return db.showHoTs end,
        function(v) db.showHoTs = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Unit Debuff Icons", 18, -166,
        function() return db.showDebuffIcons end,
        function(v) db.showDebuffIcons = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Tank / Healer / DPS Role Icon", 18, -196,
        function() return db.showRoleIcon end,
        function(v) db.showRoleIcon = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Raid Target Marker Icons", 18, -226,
        function() return db.showRaidTarget end,
        function(v) db.showRaidTarget = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Group Leader Crown Icon", 18, -256,
        function() return db.showLeaderIcon end,
        function(v) db.showLeaderIcon = v; TimelessHeal:UpdateAllVisibleUnits() end)

    CreateCheckbox(p3, "Show Aggro / Threat Red Border", 18, -286,
        function() return db.showThreatBorder end,
        function(v) db.showThreatBorder = v; TimelessHeal:UpdateAllVisibleUnits() end)

    -- Right Column on Tab 3
    CreateCheckbox(p3, "Smart Resurrection on Left-Click When Dead", 370, -16,
        function() return db.smartResurrection end,
        function(v) db.smartResurrection = v; TimelessHeal:UpdateAllBindings() end)

    CreateCheckbox(p3, "Also Enable Click-Casting on Blizzard Frames", 370, -46,
        function() return db.hookBlizzFrames end,
        function(v) db.hookBlizzFrames = v; TimelessHeal:HookBlizzardUnitFrames() end)

    CreateCheckbox(p3, "Hide Default Blizzard Party Frames", 370, -76,
        function() return db.hideBlizzParty end,
        function(v) db.hideBlizzParty = v; TimelessHeal:ApplyBlizzardPartyVisibility() end)

    local hfLabel = p3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hfLabel:SetPoint("TOPLEFT", 374, -125)
    hfLabel:SetText("Health Text Format:")

    local hfModes = {
        { label = "Percentage (95%)", val = "PERCENT" },
        { label = "Missing Deficit (-1.2k)", val = "DEFICIT" },
        { label = "Current HP (3.8k)", val = "CURRENT" },
        { label = "Hidden (None)", val = "NONE" },
    }
    for i, m in ipairs(hfModes) do
        CreateActionBtn(p3, m.label, 374, -148 - ((i - 1) * 30), 210, 24, function()
            db.healthFormat = m.val
            TimelessHeal:UpdateAllVisibleUnits()
        end)
    end

    -- =====================================================================
    -- TAB 4: Presets & Test Mode
    -- =====================================================================
    local p4 = tabPages[4]
    local p4H1 = p4:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p4H1:SetPoint("TOPLEFT", 18, -16)
    p4H1:SetText("Interactive Test Mode Preview")

    CreateActionBtn(p4, "Test 5-Man Party", 18, -44, 165, 28, function()
        TimelessHeal:SetTestMode(5)
    end)
    CreateActionBtn(p4, "Test 20-Man Raid", 192, -44, 165, 28, function()
        TimelessHeal:SetTestMode(20)
    end)
    CreateActionBtn(p4, "Stop Test Mode", 366, -44, 150, 28, function()
        TimelessHeal:SetTestMode(0)
    end)

    local p4H2 = p4:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p4H2:SetPoint("TOPLEFT", 18, -96)
    p4H2:SetText("One-Click Layout Presets")

    CreateActionBtn(p4, "Preset: Standard 5-Man Party", 18, -124, 210, 26, function()
        db.orientation = "HORIZONTAL"
        db.columns = 5
        db.frameWidth = 104
        db.frameHeight = 48
        db.spacing = 4
        TimelessHeal:UpdateLayout()
        RefreshConfigWidgets()
    end)

    CreateActionBtn(p4, "Preset: Compact 20/40 Raid Grid", 238, -124, 210, 26, function()
        db.orientation = "HORIZONTAL"
        db.columns = 5
        db.frameWidth = 84
        db.frameHeight = 38
        db.spacing = 3
        TimelessHeal:UpdateLayout()
        RefreshConfigWidgets()
    end)

    CreateActionBtn(p4, "Preset: Vertical Party Stack", 458, -124, 210, 26, function()
        db.orientation = "VERTICAL"
        db.columns = 5
        db.frameWidth = 120
        db.frameHeight = 42
        db.spacing = 4
        TimelessHeal:UpdateLayout()
        RefreshConfigWidgets()
    end)

    local p4H3 = p4:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p4H3:SetPoint("TOPLEFT", 18, -176)
    p4H3:SetText("Position & Profile Reset")

    CreateActionBtn(p4, "Reset Frame Positions to Screen Center", 18, -204, 250, 26, function()
        db.anchor = { point = "CENTER", relativePoint = "CENTER", x = -280, y = -80 }
        db.selfAnchor = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -165 }
        db.targetAnchor = { point = "CENTER", relativePoint = "CENTER", x = 150, y = -165 }
        mainContainer:ClearAllPoints()
        mainContainer:SetPoint("CENTER", UIParent, "CENTER", -280, -80)
        selfFrame:ClearAllPoints()
        selfFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -165)
        targetFrame:ClearAllPoints()
        targetFrame:SetPoint("CENTER", UIParent, "CENTER", 150, -165)
        print(CHAT_PREFIX .. "Frame positions reset.")
    end)

    CreateActionBtn(p4, "Reset All Heal Settings to Defaults", 280, -204, 250, 26, function()
        _G.TimelessForever_HealDB = nil
        _G.TimelessForeverHealDB = nil
        _G.TimelessHealDB = nil
        _G.ForeverHealDB = nil
        TimelessHeal:InitDB()
        TimelessHeal:UpdateAllBindings()
        TimelessHeal:UpdateLayout()
        RefreshConfigWidgets()
        print(CHAT_PREFIX .. "All settings and click-cast bindings restored to defaults.")
    end)

    -- Bottom Footer Bar
    CreateActionBtn(configWin, "Test 5-Man", 16, -486, 110, 24, function()
        TimelessHeal:SetTestMode(testModeCount == 5 and 0 or 5)
    end)
    CreateActionBtn(configWin, "Test 20-Raid", 132, -486, 110, 24, function()
        TimelessHeal:SetTestMode(testModeCount == 20 and 0 or 20)
    end)
    CreateActionBtn(configWin, "Lock / Unlock Frames", 248, -486, 150, 24, function()
        db.locked = not db.locked
        TimelessHeal:UpdateLayout()
        RefreshConfigWidgets()
    end)
    CreateActionBtn(configWin, "Close", 614, -486, 110, 24, function()
        configWin:Hide()
    end)

    configWin:SetScript("OnShow", function()
        SelectTab(1)
    end)

    return configWin
end

function TimelessHeal:ToggleConfigWindow()
    local win = self:BuildConfigWindow()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end

-- =========================================================================
-- 8. TimelessForever Suite Hub Integration (Order 2: "Heal")
-- =========================================================================
local function BuildSuiteOptions()
    return {
        openGui = {
            order = 1,
            type = "execute",
            name = "Open TimelessHeal Click-Cast & Grid Studio (/th)",
            desc = "Opens the full 4-tab TimelessHeal configuration window with drag-and-drop spell binding.",
            width = "double",
            func = function() TimelessHeal:ToggleConfigWindow() end,
        },
        testParty = {
            order = 2,
            type = "execute",
            name = "Toggle 5-Man Test Mode",
            func = function() TimelessHeal:SetTestMode(testModeCount == 5 and 0 or 5) end,
        },
        testRaid = {
            order = 3,
            type = "execute",
            name = "Toggle 20-Man Raid Test",
            func = function() TimelessHeal:SetTestMode(testModeCount == 20 and 0 or 20) end,
        },
        generalHeader = {
            order = 10,
            type = "header",
            name = "General & Visibility",
        },
        enabled = {
            order = 11,
            type = "toggle",
            name = "Enable TimelessHeal Frames",
            get = function() return db and db.enabled end,
            set = function(_, v) db.enabled = v; TimelessHeal:UpdateLayout() end,
        },
        locked = {
            order = 12,
            type = "toggle",
            name = "Lock Frame Positions",
            get = function() return db and db.locked end,
            set = function(_, v) db.locked = v; TimelessHeal:UpdateLayout() end,
        },
        showSolo = {
            order = 13,
            type = "toggle",
            name = "Show When Solo",
            get = function() return db and db.showSolo end,
            set = function(_, v) db.showSolo = v; TimelessHeal:UpdateLayout() end,
        },
        showParty = {
            order = 14,
            type = "toggle",
            name = "Show in Party",
            get = function() return db and db.showParty end,
            set = function(_, v) db.showParty = v; TimelessHeal:UpdateLayout() end,
        },
        showRaid = {
            order = 15,
            type = "toggle",
            name = "Show in Raid",
            get = function() return db and db.showRaid end,
            set = function(_, v) db.showRaid = v; TimelessHeal:UpdateLayout() end,
        },
        classColors = {
            order = 16,
            type = "toggle",
            name = "Class Colored Health Bars",
            get = function() return db and db.classColors end,
            set = function(_, v) db.classColors = v; TimelessHeal:UpdateAllVisibleUnits() end,
        },
        showDispel = {
            order = 17,
            type = "toggle",
            name = "Highlight Dispellable Debuffs",
            get = function() return db and db.showDispelHighlight end,
            set = function(_, v) db.showDispelHighlight = v; TimelessHeal:UpdateAllVisibleUnits() end,
        },
        showHoTs = {
            order = 18,
            type = "toggle",
            name = "Show HoT & Shield Icons",
            get = function() return db and db.showHoTs end,
            set = function(_, v) db.showHoTs = v; TimelessHeal:UpdateAllVisibleUnits() end,
        },
        smartRes = {
            order = 19,
            type = "toggle",
            name = "Smart Resurrection on Left-Click",
            get = function() return db and db.smartResurrection end,
            set = function(_, v) db.smartResurrection = v; TimelessHeal:UpdateAllBindings() end,
        },
        menuClickKey = {
            order = 19.5,
            type = "select",
            width = "double",
            name = "Blizzard Right-Click Menu Binding",
            desc = "Choose which right-click combination opens the standard Blizzard unit menu (Inspect, Whisper, Trade, Leave Party, Raid Target, etc.). Also note that any unbound Right-Click modifier automatically opens the Blizzard menu!",
            values = {
                ["RightButton"]       = "Right-Click (Plain Right-Click)",
                ["Alt-RightButton"]   = "Alt + Right-Click (Recommended)",
                ["Ctrl-RightButton"]  = "Ctrl + Right-Click",
                ["Shift-RightButton"] = "Shift + Right-Click",
            },
            get = function()
                if not db or not db.spells then return "Alt-RightButton" end
                for _, k in ipairs({ "RightButton", "Alt-RightButton", "Ctrl-RightButton", "Shift-RightButton" }) do
                    local v = string.lower(strtrim(db.spells[k] or ""))
                    if v == "togglemenu" or v == "menu" then
                        return k
                    end
                end
                return db.menuClickKey or "Alt-RightButton"
            end,
            set = function(_, val)
                if not db or not db.spells then return end
                local prevKey = db.menuClickKey
                if prevKey and db.spells[prevKey] and (string.lower(db.spells[prevKey]) == "togglemenu" or string.lower(db.spells[prevKey]) == "menu") then
                    db.spells[prevKey] = ""
                end
                db.menuClickKey = val
                db.spells[val] = "togglemenu"
                TimelessHeal:UpdateAllBindings()
                RefreshConfigWidgets()
                print(CHAT_PREFIX .. "Blizzard Right-Click Menu bound to |cffffd100" .. val .. "|r!")
            end,
        },
        sizeHeader = {
            order = 20,
            type = "header",
            name = "Grid Dimensions",
        },
        frameWidth = {
            order = 21,
            type = "range",
            name = "Frame Width",
            min = 60, max = 180, step = 2,
            get = function() return (db and db.frameWidth) or 98 end,
            set = function(_, v) db.frameWidth = v; TimelessHeal:UpdateLayout() end,
        },
        frameHeight = {
            order = 22,
            type = "range",
            name = "Frame Height",
            min = 28, max = 100, step = 2,
            get = function() return (db and db.frameHeight) or 46 end,
            set = function(_, v) db.frameHeight = v; TimelessHeal:UpdateLayout() end,
        },
        columns = {
            order = 23,
            type = "range",
            name = "Columns Per Row",
            min = 1, max = 10, step = 1,
            get = function() return (db and db.columns) or 5 end,
            set = function(_, v) db.columns = v; TimelessHeal:UpdateLayout() end,
        },
        scale = {
            order = 24,
            type = "range",
            name = "Frame Scale",
            min = 0.6, max = 1.6, step = 0.05,
            get = function() return (db and db.scale) or 1.0 end,
            set = function(_, v) db.scale = v; TimelessHeal:UpdateLayout() end,
        },
    }
end

local function RegisterWithSuiteHub()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        pcall(function()
            suite:RegisterModuleTab("heal", "Heal", 2, BuildSuiteOptions())
        end)
    end
end

-- =========================================================================
-- 9. Event Handling, Periodic Range Ticker & Slash Commands
-- =========================================================================
TimelessHeal:RegisterEvent("ADDON_LOADED")
TimelessHeal:RegisterEvent("PLAYER_LOGIN")
TimelessHeal:RegisterEvent("PLAYER_ENTERING_WORLD")
TimelessHeal:RegisterEvent("GROUP_ROSTER_UPDATE")
TimelessHeal:RegisterEvent("PLAYER_REGEN_ENABLED")
TimelessHeal:RegisterEvent("PLAYER_TARGET_CHANGED")
TimelessHeal:RegisterEvent("RAID_TARGET_UPDATE")
TimelessHeal:RegisterEvent("UNIT_HEALTH")
TimelessHeal:RegisterEvent("UNIT_MAXHEALTH")
TimelessHeal:RegisterEvent("UNIT_POWER_UPDATE")
TimelessHeal:RegisterEvent("UNIT_MAXPOWER")
TimelessHeal:RegisterEvent("UNIT_AURA")
TimelessHeal:RegisterEvent("UNIT_HEAL_PREDICTION")
TimelessHeal:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
TimelessHeal:RegisterEvent("UNIT_CONNECTION")

TimelessHeal:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "TimelessForever_Heal") then
        self:InitDB()
    elseif event == "PLAYER_LOGIN" then
        self:InitDB()
        self:BuildFrames()
        self:UpdateAllBindings()
        self:UpdateLayout()
        RegisterWithSuiteHub()
        if _G.C_Timer and _G.C_Timer.NewTicker then
            _G.C_Timer.NewTicker(0.25, function()
                TimelessHeal:UpdateAllVisibleUnits()
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        if mainContainer then
            self:UpdateLayout()
            self:HookBlizzardUnitFrames()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingBindingsUpdate then
            self:UpdateAllBindings()
        end
        if pendingLayoutUpdate then
            self:UpdateLayout()
        end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "RAID_TARGET_UPDATE" then
        self:UpdateAllVisibleUnits()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_POWER_UPDATE"
        or event == "UNIT_MAXPOWER" or event == "UNIT_AURA" or event == "UNIT_HEAL_PREDICTION"
        or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_CONNECTION" then
        if testModeCount > 0 then return end
        for i = 1, MAX_GRID_FRAMES do
            local btn = gridFrames[i]
            if btn and btn:IsShown() and btn:GetAttribute("unit") == arg1 then
                self:UpdateUnitButton(btn)
            end
        end
        if selfFrame and selfFrame:IsShown() and arg1 == "player" then
            self:UpdateUnitButton(selfFrame)
        end
        if targetFrame and targetFrame:IsShown() and arg1 == "target" then
            self:UpdateUnitButton(targetFrame)
        end
    end
end)

SLASH_TIMELESSHEAL1 = "/th"
SLASH_TIMELESSHEAL2 = "/fh"
SLASH_TIMELESSHEAL3 = "/tfh"
SLASH_TIMELESSHEAL4 = "/timelessheal"
SLASH_TIMELESSHEAL5 = "/foreverheal"

SlashCmdList["TIMELESSHEAL"] = function(msg)
    local cmd = string.lower(strtrim(msg or ""))
    if cmd == "test" or cmd == "test5" then
        TimelessHeal:SetTestMode(testModeCount == 5 and 0 or 5)
    elseif cmd == "test20" or cmd == "raid" then
        TimelessHeal:SetTestMode(testModeCount == 20 and 0 or 20)
    elseif cmd == "lock" then
        db.locked = not db.locked
        TimelessHeal:UpdateLayout()
        print(CHAT_PREFIX .. "Frames are now " .. (db.locked and "|cffff5555LOCKED|r" or "|cff00ff00UNLOCKED|r") .. ".")
    elseif cmd == "reset" then
        db.anchor = { point = "CENTER", relativePoint = "CENTER", x = -280, y = -80 }
        if mainContainer then
            mainContainer:ClearAllPoints()
            mainContainer:SetPoint("CENTER", UIParent, "CENTER", -280, -80)
        end
        print(CHAT_PREFIX .. "Grid position reset to screen center.")
    else
        TimelessHeal:ToggleConfigWindow()
    end
end

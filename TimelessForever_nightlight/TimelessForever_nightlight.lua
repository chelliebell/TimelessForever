-- =========================================================================
-- TimelessForever_nightlight
-- Part of the Timeless / Typeless Forever Suite
--
-- Core Concept:
-- - Subtle, night-only cursor light for World of Warcraft.
-- - Activates only at night, remains active in cities.
-- - Uses 50% brightness by default.
-- - Turns off while you are stealthed.
-- - Keeps gameplay information readable without becoming visually distracting.
--
-- Progression & Unlocks:
-- - Dormant on install and does nothing at level 1 (Tier 0).
-- - Tier 1: Basic Light (Level 4+ or learned spell in level 4–6 bracket from class trainer).
-- - Tier 2: Health Dimming (Level 10+ or learned level 9–11 ability from class trainer; dims to 0 at <= 14% HP).
-- - Tier 3: Aggro Warning (Level 14+ or having any taunt/aggro ability; Vivid Red when holding aggro).
-- - Tier 4: Class Behaviors (Level 20+ or learned level 19–22 ability from class trainer).
--
-- Debug / Testing:
-- - Separate in-memory debug mode (/nightlight debug or debug frame)
--   temporarily overrides tier flags for testing without modifying earned flags.
-- =========================================================================

local ADDON_NAME = ...
local NightlightApp = CreateFrame("Frame", "TimelessForever_NightlightFrame", UIParent)
local lightGlowFrame = nil -- Forward declaration for glow container

local TEXTURE_PATH = "Interface\\AddOns\\TimelessForever_nightlight\\Textures\\"
local TEX_DARKNESS_HOLE = TEXTURE_PATH .. "darkness_hole"
local TEX_LIGHT_GLOW    = TEXTURE_PATH .. "light_glow"
local TEX_LIGHT_CORE    = TEXTURE_PATH .. "light_core"
local TEX_TORCH_CURSOR  = TEXTURE_PATH .. "torch_cursor"
local TEX_TOTEM_WEDGE   = TEXTURE_PATH .. "totem_wedge"

-- -------------------------------------------------------------------------
-- Presets & Options
-- -------------------------------------------------------------------------
local COLOR_PRESETS = {
    ["TORCH"]      = { name = "Warm Torchlight (Amber)",     r = 1.00, g = 0.72, b = 0.30 },
    ["CANDLE"]     = { name = "Cozy Candlelight (Soft Gold)", r = 1.00, g = 0.85, b = 0.52 },
    ["CAMPFIRE"]   = { name = "Campfire Ember (Deep Orange)", r = 1.00, g = 0.48, b = 0.16 },
    ["MOONLIGHT"]  = { name = "Elune Moonlight (Silver Blue)",r = 0.55, g = 0.80, b = 1.00 },
    ["HOLY"]       = { name = "Holy Radiance (Warm White)",   r = 1.00, g = 0.95, b = 0.72 },
    ["ARCANE"]     = { name = "Arcane Lantern (Violet)",      r = 0.80, g = 0.48, b = 1.00 },
    ["FEL"]        = { name = "Fel Torch (Emerald Green)",    r = 0.35, g = 1.00, b = 0.42 },
    ["PURE_WHITE"] = { name = "Pure Daylight (White)",        r = 1.00, g = 1.00, b = 1.00 },
    ["CUSTOM"]     = { name = "Custom Color...",              r = 1.00, g = 0.72, b = 0.30 },
}

local COLOR_PRESET_DROPDOWN = {
    ["TORCH"]      = "|cffffb84dWarm Torchlight (Amber)|r",
    ["CANDLE"]     = "|cffffd985Cozy Candlelight (Soft Gold)|r",
    ["CAMPFIRE"]   = "|cffff7a29Campfire Ember (Deep Orange)|r",
    ["MOONLIGHT"]  = "|cff8cccffElune Moonlight (Silver Blue)|r",
    ["HOLY"]       = "|cfffff2b8Holy Radiance (Warm White)|r",
    ["ARCANE"]     = "|cffcc7affArcane Lantern (Violet)|r",
    ["FEL"]        = "|cff59ff6bFel Torch (Emerald Green)|r",
    ["PURE_WHITE"] = "|cffffffffPure Daylight (White)|r",
    ["CUSTOM"]     = "Custom Color Picker...",
}

local LIGHT_MODE_DROPDOWN = {
    ["LANTERN_DARK"]   = "Lantern in the Dark (Darkness + Warm Glow)",
    ["GLOW_ONLY"]      = "Cursor Light Glow Only (No Screen Darkening)",
    ["SPOTLIGHT_ONLY"] = "Flashlight Cutout Only (Darkness + Clear Window)",
}

local LIGHT_MODE_ORDER = { "LANTERN_DARK", "GLOW_ONLY", "SPOTLIGHT_ONLY" }

local TIME_SOURCE_DROPDOWN = {
    ["GAME"]  = "In-Game Server / Realm Time (GetGameTime)",
    ["LOCAL"] = "Local Computer Time (date)",
}

local ICON_OPTIONS = {
    ["INV_Misc_Lantern_01"]   = "|TInterface\\Icons\\INV_Misc_Lantern_01:18:18:0:0|t  Classic Lantern",
    ["INV_Torch_Lit"]         = "|TInterface\\Icons\\INV_Torch_Lit:18:18:0:0|t  Lit Explorers Torch",
    ["INV_Misc_Candle_01"]    = "|TInterface\\Icons\\INV_Misc_Candle_01:18:18:0:0|t  Glowing Candle",
    ["Spell_Holy_ElunesGrace"]= "|TInterface\\Icons\\Spell_Holy_ElunesGrace:18:18:0:0|t  Elune's Moonlight",
    ["Spell_Fire_Incinerate"] = "|TInterface\\Icons\\Spell_Fire_Incinerate:18:18:0:0|t  Blazing Firelight",
    ["Spell_Nature_StarFall"] = "|TInterface\\Icons\\Spell_Nature_StarFall:18:18:0:0|t  Starlight Glow",
}

local STRATA_OPTIONS = {
    ["FULLSCREEN_DIALOG"] = "Topmost (Covers World & UI)",
    ["HIGH"]              = "High (Covers World & Most UI)",
    ["MEDIUM"]            = "Medium (Below Windows/Tooltips)",
    ["BACKGROUND"]        = "Background (World Only, Behind UI)",
}

-- -------------------------------------------------------------------------
-- Database Defaults
-- -------------------------------------------------------------------------
local DB_DEFAULTS = {
    enabled = true,
    mode = "LANTERN_DARK",
    radius = 380,
    darknessAlpha = 0.78,
    glowAlpha = 0.50,            -- 50% default brightness
    coreBloom = 0.20,            -- Center core bloom intensity (0.0 to 1.0; 0 is completely off)
    coreAlpha = 0.20,
    colorPreset = "TORCH",
    customColor = { r = 1.00, g = 0.72, b = 0.30 },
    flickerEnabled = true,
    flickerAmount = 0.20,
    smoothFollow = false,
    smoothSpeed = 18,
    strata = "HIGH",
    showIcon = true,
    buttonIcon = "INV_Misc_Lantern_01",
    iconPos = { point = "CENTER", relativePoint = "CENTER", x = 60, y = 100 },

    -- Core Rules
    activeOnlyAtNight = true,        -- Activates only at night
    stayActiveInCities = true,       -- Remains active in cities & inns
    torchCursorOverlay = true,       -- Shrink & overlay cursor torch mechanic

    -- Realistic IRL Day / Night Cycle Settings
    dayNightCycle = true,            -- Automatically adjust darkness by time of day
    dayNightTimeSource = "GAME",     -- "GAME" or "LOCAL"
    dayDarknessMax = 0.50,          -- Closer to day: caps at max 50%
    nightDarknessMax = 0.85,        -- Night time: deep darkness
    dayNightAmbientAlways = true,   -- Keep world dark at night even if lantern is off
    autoLanternAtNight = false,     -- Auto-light lantern at dusk, extinguish at dawn
    adjustGamma = false,            -- Also adjust engine Gamma CVar
    previewTimeEnabled = false,     -- Test preview slider
    previewTimeHour = 12,           -- 0 - 24 hour preview

    -- Rogue & Stealth Auto-Extinguish Settings
    stealthAutoExtinguish = true,    -- Auto-turn off when entering stealth, turn back on when exiting
    stealthRogueOnly = false,        -- Restrict to Rogues only (or false for all stealth classes)

    -- Per-character progression storage
    characters = {},
}

local function GetDB()
    if type(TimelessForever_NightlightDB) ~= "table" then
        TimelessForever_NightlightDB = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
        if TimelessForever_NightlightDB[k] == nil then
            if type(v) == "table" then
                TimelessForever_NightlightDB[k] = {}
                for tk, tv in pairs(v) do
                    TimelessForever_NightlightDB[k][tk] = tv
                end
            else
                TimelessForever_NightlightDB[k] = v
            end
        end
    end
    TimelessForever_NightlightDB.characters = TimelessForever_NightlightDB.characters or {}
    return TimelessForever_NightlightDB
end

local function GetCharKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Realm"
    return name .. "-" .. realm
end

local function GetCharData()
    local db = GetDB()
    local key = GetCharKey()
    if not db.characters[key] then
        db.characters[key] = {
            tier1_earned = false,
            tier2_earned = false,
            tier3_earned = false,
            tier4_earned = false,
        }
    end
    return db.characters[key]
end

-- -------------------------------------------------------------------------
-- Debug / Testing In-Memory Overrides
-- (Never persisted; allows simulating any tier without leveling)
-- -------------------------------------------------------------------------
local debug_tier1 = nil
local debug_tier2 = nil
local debug_tier3 = nil
local debug_tier4 = nil
local debug_force_night = nil
local debug_sim_class = nil         -- In-memory simulated class (WARRIOR, PALADIN, etc.)
local debug_sim_class_option = nil  -- Sub-option for active simulated class
local debug_force_aggro = nil       -- In-memory force aggro simulation

local CheckHasAggroSpell -- Forward declaration

local function IsTierUnlocked(tier)
    local cdata = GetCharData()
    local level = UnitLevel("player") or 1
    if tier == 1 then
        if debug_tier1 ~= nil then return debug_tier1 end
        if cdata.tier1_earned == true then return true end
        return level >= 4
    elseif tier == 2 then
        if debug_tier2 ~= nil then return debug_tier2 end
        if cdata.tier2_earned == true then return true end
        return level >= 10
    elseif tier == 3 then
        if debug_tier3 ~= nil then return debug_tier3 end
        if cdata.tier3_earned == true then return true end
        if level >= 14 then return true end
        if CheckHasAggroSpell and CheckHasAggroSpell() then return true end
    elseif tier == 4 then
        if debug_sim_class ~= nil then return true end
        if debug_tier4 ~= nil then return debug_tier4 end
        if cdata.tier4_earned == true then return true end
        return level >= 20
    end
    return false
end

local UpdateNightlightState -- Forward declaration

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

local function UnlockTier(tier, announce)
    local cdata = GetCharData()
    local wasUnlocked = IsTierUnlocked(tier)
    if tier == 1 then
        cdata.tier1_earned = true
    elseif tier == 2 then
        cdata.tier2_earned = true
    elseif tier == 3 then
        cdata.tier3_earned = true
    elseif tier == 4 then
        cdata.tier4_earned = true
    end
    if announce and not wasUnlocked then
        if tier == 1 then
            print("|cff00ccff[Nightlight]|r |cffffd100Tier 1 (Basic Light) Unlocked!|r The first spark awakens in the dark.")
        elseif tier == 2 then
            print("|cff00ccff[Nightlight]|r |cffffd100Tier 2 (Health Dimming) Unlocked!|r The flame now pulses with your vitality.")
        elseif tier == 3 then
            print("|cff00ccff[Nightlight]|r |cffffd100Tier 3 (Aggro Red Warning) Unlocked!|r Aggro threat now turns the light vivid red.")
        elseif tier == 4 then
            print("|cff00ccff[Nightlight]|r |cffffd100Tier 4 (Class Behaviors) Unlocked!|r Your class essence flows through the flame.")
        end
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.UI_SPECIAL_QUEST_COMPLETE or 888, "Master")
    end
    if UpdateNightlightState then
        UpdateNightlightState()
    end
    NotifyOptionsChange()
end

CheckHasAggroSpell = function()
    -- Known taunt and threat spell names (Classic & modern)
    local AGGRO_SPELL_NAMES = {
        ["Taunt"] = true,
        ["Growl"] = true,
        ["Righteous Fury"] = true,
        ["Hand of Reckoning"] = true,
        ["Righteous Defense"] = true,
        ["Dark Command"] = true,
        ["Death Grip"] = true,
        ["Mocking Blow"] = true,
        ["Challenging Shout"] = true,
        ["Challenging Roar"] = true,
        ["Distracting Shot"] = true,
        ["Torment"] = true,
        ["Intervene"] = true,
        ["Defensive Stance"] = true,
        ["Bear Form"] = true,
        ["Dire Bear Form"] = true,
    }

    local AGGRO_SPELL_IDS = {
        355,   -- Warrior: Taunt
        6795,  -- Druid: Growl
        5487,  -- Druid: Bear Form
        9634,  -- Druid: Dire Bear Form
        71,    -- Warrior: Defensive Stance
        694,   -- Warrior: Mocking Blow
        1161,  -- Warrior: Challenging Shout
        5209,  -- Druid: Challenging Roar
        25780, -- Paladin: Righteous Fury
        31789, -- Paladin: Righteous Defense
        62124, -- Paladin: Hand of Reckoning
        56222, -- DK: Dark Command
        49576, -- DK: Death Grip
        20736, -- Hunter: Distracting Shot
        3716,  -- Warlock (Pet): Torment
    }

    -- 1. Check IsPlayerSpell / IsSpellKnown by ID
    for _, id in ipairs(AGGRO_SPELL_IDS) do
        if IsPlayerSpell and IsPlayerSpell(id) then
            return true
        end
        if IsSpellKnown and IsSpellKnown(id) then
            return true
        end
    end

    -- 2. Check Spellbook by name (Classic Era / standard API)
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local numTabs = GetNumSpellTabs()
        for tab = 1, numTabs do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            if offset and numSpells then
                for i = 1, numSpells do
                    local slot = offset + i
                    local spellName = GetSpellBookItemName(slot, BOOKTYPE_SPELL or "spell")
                    if spellName and AGGRO_SPELL_NAMES[spellName] then
                        return true
                    end
                end
            end
        end
    end

    -- 3. Check C_SpellBook if modern API
    if C_SpellBook and C_SpellBook.GetSpellBookItemName then
        local num = C_SpellBook.GetNumSpellBookItems and C_SpellBook.GetNumSpellBookItems() or 120
        for slot = 1, num do
            local spellName = C_SpellBook.GetSpellBookItemName(slot, Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0)
            if spellName and AGGRO_SPELL_NAMES[spellName] then
                return true
            end
        end
    end

    return false
end

local function CheckAutoUnlockProgression(announce)
    local level = UnitLevel("player") or 1
    local cdata = GetCharData()

    -- Level 4+: Automatically enable Tier 1
    if level >= 4 and not cdata.tier1_earned then
        UnlockTier(1, announce)
    end

    -- Level 10+: Automatically enable Tier 2 (Health Dimming)
    if level >= 10 and not cdata.tier2_earned then
        UnlockTier(2, announce)
    end

    -- Level 14+ OR having an aggro / taunt spell: Automatically enable Tier 3 (Aggro Red)
    if not cdata.tier3_earned then
        if level >= 14 or CheckHasAggroSpell() then
            UnlockTier(3, announce)
        end
    end

    -- Level 20+: Automatically enable Tier 4 (Class Behaviors)
    if level >= 20 and not cdata.tier4_earned then
        UnlockTier(4, announce)
    end
end

-- -------------------------------------------------------------------------
-- Time & City Calculation
-- -------------------------------------------------------------------------
local function GetCurrentHour()
    local db = GetDB()
    if db.previewTimeEnabled then
        return db.previewTimeHour or 12
    end
    -- In-Game Realm / Server Time (GetGameTime)
    local h, m = GetGameTime()
    if h ~= nil and m ~= nil then
        return h + (m / 60)
    end
    local t = date("*t")
    return (t.hour or 12) + ((t.min or 0) / 60)
end

local function IsNightTime()
    if debug_force_night ~= nil then
        return debug_force_night
    end
    local hour = GetCurrentHour()
    -- Night spans dusk to dawn (18:00 - 06:00)
    return (hour >= 18.0 or hour < 6.0)
end

local function IsInCityOrResting()
    return IsResting() == true
end

-- Calculates the natural darkness level based on real-time 24h curve:
local function CalculateCurrentDarkness()
    local db = GetDB()
    if not db.dayNightCycle then
        return math.max(0, math.min(0.98, db.darknessAlpha or 0.78)), 0.5, 12, "Static Mode"
    end

    local hour = GetCurrentHour()
    local dayMax = math.max(0.0, math.min(0.50, db.dayDarknessMax or 0.50))
    local nightMax = math.max(dayMax, math.min(0.98, db.nightDarknessMax or 0.85))

    local angle = (hour - 1.0) * (2.0 * math.pi / 24.0)
    local rawFactor = (math.cos(angle) + 1.0) / 2.0 -- 0.0 at 13:00, 1.0 at 01:00

    local factor = rawFactor * rawFactor * (3.0 - 2.0 * rawFactor)
    local darkness = dayMax + (factor * (nightMax - dayMax))

    local phase = "Daylight"
    if factor >= 0.75 then
        phase = "Deep Night"
    elseif factor >= 0.40 then
        if hour >= 12 and hour < 24 then
            phase = "Evening / Dusk"
        else
            phase = "Dawn / Sunrise"
        end
    else
        phase = "Daytime"
    end

    return darkness, factor, hour, phase
end

-- -------------------------------------------------------------------------
-- Stealth Detection
-- -------------------------------------------------------------------------
local wasLitBeforeStealth = false
local isCurrentlyStealthed = false
local lastStealthCheck = 0

local function CheckIsPlayerStealthed()
    if IsStealthed and IsStealthed() then
        return true
    end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ids = { 1784, 5215, 11327, 1856, 58984, 185313, 115192, 115191 }
        for _, id in ipairs(ids) do
            if C_UnitAuras.GetPlayerAuraBySpellID(id) then
                return true
            end
        end
    end
    if UnitBuff then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == "Stealth" or name == "Prowl" or name == "Vanish" or name == "Shadowmeld" or name == "Shadow Dance" or name == "Subterfuge" then
                return true
            end
        end
    end
    return false
end

local function HandleStealthUpdate()
    local db = GetDB()
    if not db.stealthAutoExtinguish then return end

    local _, class = UnitClass("player")
    if db.stealthRogueOnly and class ~= "ROGUE" then return end

    local stealthed = CheckIsPlayerStealthed()

    if stealthed and not isCurrentlyStealthed then
        isCurrentlyStealthed = true
        if db.enabled then
            wasLitBeforeStealth = true
            db.enabled = false
            if UpdateNightlightState then
                UpdateNightlightState()
            end
            NotifyOptionsChange()
            -- Stealth auto-extinguish visual toggle (silent to prevent chat spam)
        end
    elseif not stealthed and isCurrentlyStealthed then
        isCurrentlyStealthed = false
        if wasLitBeforeStealth then
            wasLitBeforeStealth = false
            db.enabled = true
            if UpdateNightlightState then
                UpdateNightlightState()
            end
            NotifyOptionsChange()
            -- Stealth broken visual relight (silent to prevent chat spam)
        end
    end
end

-- -------------------------------------------------------------------------
-- Active Lighting Decision
-- Evaluates Dormant state, Night/City state, and Stealth
-- -------------------------------------------------------------------------
local function ShouldLightBeActive()
    -- Tier 1 check: Dormant at level 1 until trainer spell learned
    if not IsTierUnlocked(1) then
        return false, "Dormant (Tier 1 Locked — Visit Class Trainer at level 4–6)"
    end

    local db = GetDB()
    if not db.enabled then
        return false, "Manually Extinguished"
    end

    if CheckIsPlayerStealthed() then
        return false, "Stealthed"
    end

    -- Core rule: Activates only at night, remains active in cities
    if db.stayActiveInCities and IsInCityOrResting() then
        return true, "City / Inn (Resting)"
    end

    if db.activeOnlyAtNight then
        if IsNightTime() then
            return true, "Nightfall"
        else
            return false, "Daytime (Sleeps outside cities)"
        end
    end

    return true, "Active"
end

-- -------------------------------------------------------------------------
-- Tier 2: Health-Based Brightness Engine
-- Smoothly dims as health falls, full health = normal 50% brightness
--
-- Note on modern WoW 12.0+ (Midnight / Classic Beta 12.x):
-- UnitHealth() returns protected "secret values" on which Lua cannot perform
-- arithmetic. Modern clients provide C_CurveUtil + UnitHealthPercent(unit, true, curve)
-- which evaluates the health curve natively in C++ and can be passed directly
-- to Frame:SetAlpha().
-- Legacy clients (Classic Era 1.15 / Vanilla) allow direct non-secret arithmetic.
-- -------------------------------------------------------------------------
local smoothedHealthDim = 1.0
local healthDimCurve = nil

local function IsSecret(v)
    return (issecretvalue and issecretvalue(v)) and true or false
end

local function GetHealthDimCurve()
    if healthDimCurve then return healthDimCurve end
    if C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        local ok, curve = pcall(function()
            local c = C_CurveUtil.CreateCurve()
            local curveType = Enum.LuaCurveType.Cubic or Enum.LuaCurveType.Linear or 0
            if c.SetType then c:SetType(curveType) end
            -- Fade curve: at 14% HP (and below), brightness is 0.00
            -- Smooth curve from 100% HP down to 14% HP
            c:AddPoint(0.00, 0.00)
            c:AddPoint(0.14, 0.00)
            c:AddPoint(0.35, 0.22)
            c:AddPoint(0.65, 0.58)
            c:AddPoint(1.00, 1.00)
            return c
        end)
        if ok and curve then
            healthDimCurve = curve
            return healthDimCurve
        end
    end
    return nil
end

local function ApplyHealthDimming(elapsed)
    if not lightGlowFrame then return end

    if not IsTierUnlocked(2) then
        lightGlowFrame:SetAlpha(1.0)
        return
    end

    local targetUnit = "player"
    local _, class = UnitClass("player")
    local effectiveClass = debug_sim_class or class
    if IsTierUnlocked(4) and effectiveClass == "HUNTER" then
        local petDead = false
        if debug_sim_class == "HUNTER" then
            petDead = (debug_sim_class_option == "dead")
        else
            petDead = not UnitExists("pet") or UnitIsDeadOrGhost("pet")
        end
        if petDead then
            lightGlowFrame:SetAlpha(0.32)
            return
        end
        if UnitExists("pet") then
            targetUnit = "pet"
        end
    end

    -- Priority 1: Modern 12.0 Engine Curve (Native C++ curve evaluation on secret health values)
    local curve = GetHealthDimCurve()
    if curve and UnitHealthPercent then
        local ok, secretAlpha = pcall(UnitHealthPercent, targetUnit, true, curve)
        if ok and secretAlpha ~= nil then
            lightGlowFrame:SetAlpha(secretAlpha)
            return
        end
    end

    -- Priority 2: Non-secret health arithmetic (Classic Era / Vanilla / non-secret clients)
    local cur = UnitHealth(targetUnit)
    local mx = UnitHealthMax(targetUnit)
    if not IsSecret(cur) and not IsSecret(mx) and type(cur) == "number" and type(mx) == "number" and mx > 0 then
        local pct = cur / mx
        local targetHpDim = 0.0
        if pct > 0.14 then
            local norm = math.max(0.0, math.min(1.0, (pct - 0.14) / 0.86))
            targetHpDim = norm ^ 1.15
        else
            targetHpDim = 0.0
        end
        if elapsed then
            smoothedHealthDim = smoothedHealthDim + (targetHpDim - smoothedHealthDim) * math.min(1.0, elapsed * 6.0)
        else
            smoothedHealthDim = targetHpDim
        end
        lightGlowFrame:SetAlpha(smoothedHealthDim)
        return
    end

    -- Priority 3: Secret without curve (Direct secret percent passthrough)
    if UnitHealthPercent then
        local ok, secretPct = pcall(UnitHealthPercent, targetUnit)
        if ok and secretPct ~= nil then
            lightGlowFrame:SetAlpha(secretPct)
            return
        end
    end

    -- Default fallback
    lightGlowFrame:SetAlpha(1.0)
end

-- -------------------------------------------------------------------------
-- Tier 3: Class Behaviors State
-- -------------------------------------------------------------------------
local paladinFlareTimer = 0.0
local priestInversionTimer = 0.0

local function GetMageSpecColor()
    local spec = "Frost"
    if GetSpecialization then
        local id = GetSpecialization()
        if id == 1 then spec = "Arcane"
        elseif id == 2 then spec = "Fire"
        elseif id == 3 then spec = "Frost" end
    elseif GetNumTalentTabs then
        local bestPts = -1
        local bestTab = 3
        for t = 1, GetNumTalentTabs() do
            local _, _, pts = GetTalentTabInfo(t)
            if pts and pts > bestPts then
                bestPts = pts
                bestTab = t
            end
        end
        if bestTab == 1 then spec = "Arcane"
        elseif bestTab == 2 then spec = "Fire"
        else spec = "Frost" end
    end

    if spec == "Arcane" then
        return 0.88, 0.70, 1.00 -- White-Purple
    elseif spec == "Fire" then
        return 1.00, 0.55, 0.40 -- White-Red
    else
        return 0.94, 0.98, 1.00 -- Crisp White (Frost)
    end
end

-- -------------------------------------------------------------------------
-- Aggro Detection Engine (Target-Specific)
-- -------------------------------------------------------------------------
local function CheckPlayerHasAggro()
    if debug_force_aggro ~= nil then
        return debug_force_aggro
    end

    -- Only check the player's current target:
    -- If no target, target is dead, or cannot attack player, no aggro warning.
    if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
        return false
    end

    -- 1. Direct Target-of-Target check (instantaneous response)
    if UnitIsUnit("targettarget", "player") then
        return true
    end

    -- 2. Threat engine isTanking boolean (handles spellcasting or abilities where targettarget may temporarily clear)
    if UnitDetailedThreatSituation then
        local ok, isTanking = pcall(UnitDetailedThreatSituation, "player", "target")
        if ok and isTanking == true then
            return true
        end
    end

    -- 3. Threat status check (status 2 = insecurely tanking, 3 = securely tanking)
    if UnitThreatSituation then
        local ok, status = pcall(UnitThreatSituation, "player", "target")
        if ok and status and type(status) == "number" and not IsSecret(status) and status >= 2 then
            return true
        end
    end

    return false
end

-- Returns active color and special modifiers for current class
local function EvaluateClassBehavior(baseR, baseG, baseB, elapsed)
    local r, g, b = baseR, baseG, baseB
    local brightnessMod = 1.0
    local coreInvertAlpha = 1.0
    local totemData = nil
    local _, class = UnitClass("player")
    local effectiveClass = debug_sim_class or class

    -- Tier 4: Class Behaviors (Locked behind Level 20+)
    if IsTierUnlocked(4) then
        if effectiveClass == "WARRIOR" then
            local stance = 1 -- 1=Battle, 2=Defensive, 3=Berserker
            local isEnraged = false
            if debug_sim_class == "WARRIOR" and debug_sim_class_option then
                if debug_sim_class_option == "defensive" then stance = 2
                elseif debug_sim_class_option == "berserker" then stance = 3
                elseif debug_sim_class_option == "enrage" then
                    stance = 3
                    isEnraged = true
                end
            else
                if GetShapeshiftForm then
                    stance = GetShapeshiftForm() or 1
                end
                if UnitBuff then
                    for i = 1, 40 do
                        local name = UnitBuff("player", i)
                        if not name then break end
                        if name == "Enrage" or name == "Berserker Rage" or name == "Bloodrage" then
                            isEnraged = true
                            break
                        end
                    end
                end
            end

            if isEnraged then
                -- Fiery crimson surge
                r, g, b = 1.00, 0.32, 0.12
                brightnessMod = brightnessMod * 1.30
            elseif stance == 2 then
                -- Defensive Stance: Guarded iron-amber fortitude
                r, g, b = 1.00, 0.82, 0.42
                brightnessMod = brightnessMod * 0.95
            elseif stance == 3 then
                -- Berserker Stance: Fierce fiery rage tone
                r, g, b = 1.00, 0.45, 0.20
                brightnessMod = brightnessMod * 1.10
            end

        elseif effectiveClass == "ROGUE" then
            local cp = 0
            local isSprinting = false
            if debug_sim_class == "ROGUE" and debug_sim_class_option then
                if type(debug_sim_class_option) == "number" then
                    cp = debug_sim_class_option
                elseif debug_sim_class_option == "sprint" then
                    isSprinting = true
                end
            else
                if GetComboPoints then
                    cp = GetComboPoints("player", "target") or 0
                end
                if UnitBuff then
                    for i = 1, 40 do
                        local name = UnitBuff("player", i)
                        if not name then break end
                        if name == "Sprint" then
                            isSprinting = true
                            break
                        end
                    end
                end
            end

            if cp > 0 then
                if cp >= 5 then
                    -- 5 Combo Points: Razor-sharp lethal gold focus
                    r, g, b = 1.00, 0.88, 0.25
                    brightnessMod = brightnessMod * 1.35
                else
                    -- 1-4 Combo Points: Progressive focus
                    local ratio = cp / 5.0
                    r = r + (1.00 - r) * (0.30 * ratio)
                    g = g + (0.85 - g) * (0.30 * ratio)
                    b = b * (1.0 - 0.25 * ratio)
                    brightnessMod = brightnessMod * (1.0 + (0.06 * cp))
                end
            end
            if isSprinting then
                -- Wind shimmer
                r = r * 0.85 + 0.15 * 0.70
                g = g * 0.85 + 0.15 * 0.95
                b = b * 0.85 + 0.15 * 1.00
                brightnessMod = brightnessMod * 1.20
            end

        elseif effectiveClass == "DRUID" then
            local form = 0
            if debug_sim_class == "DRUID" and debug_sim_class_option then
                if debug_sim_class_option == "bear" then form = 1
                elseif debug_sim_class_option == "aquatic" then form = 2
                elseif debug_sim_class_option == "cat" then form = 3
                elseif debug_sim_class_option == "travel" then form = 4
                elseif debug_sim_class_option == "moonkin" then form = 5
                elseif debug_sim_class_option == "caster" then form = 0 end
            elseif GetShapeshiftForm then
                form = GetShapeshiftForm() or 0
            end

            if form == 1 then
                -- Bear Form: Primal russet earth-amber
                r, g, b = 0.96, 0.58, 0.22
            elseif form == 2 then
                -- Aquatic Form: Deep oceanic teal
                r, g, b = 0.28, 0.88, 0.90
            elseif form == 3 then
                -- Cat Form: Sleek nocturnal amber
                r, g, b = 1.00, 0.72, 0.28
            elseif form == 4 then
                -- Travel Form: Swift aerodynamic breeze cyan
                r, g, b = 0.75, 0.95, 1.00
            elseif form == 5 then
                -- Moonkin Form: Astral starry indigo
                r, g, b = 0.48, 0.65, 1.00
            else
                -- Humanoid / Caster Form: Natural restorative warm flora glow
                r, g, b = 0.95, 0.88, 0.55
            end

        elseif effectiveClass == "MAGE" then
            if debug_sim_class == "MAGE" and debug_sim_class_option then
                if debug_sim_class_option == "fire" then
                    r, g, b = 1.00, 0.55, 0.40
                elseif debug_sim_class_option == "arcane" then
                    r, g, b = 0.88, 0.70, 1.00
                else
                    r, g, b = 0.94, 0.98, 1.00 -- Frost
                end
            else
                r, g, b = GetMageSpecColor()
            end

        elseif effectiveClass == "WARLOCK" then
            local isDraining = false
            if debug_sim_class == "WARLOCK" and debug_sim_class_option == "drain" then
                isDraining = true
            else
                local channelName = UnitChannelInfo("player")
                if channelName then
                    local l = channelName:lower()
                    if l:find("drain") or l:find("funnel") or l:find("siphon") then
                        isDraining = true
                    end
                end
            end
            if isDraining then
                brightnessMod = brightnessMod * 0.35 -- Light drained
            end

        elseif effectiveClass == "PALADIN" then
            local isCastingHoly = false
            if debug_sim_class == "PALADIN" and debug_sim_class_option == "flare" then
                paladinFlareTimer = 1.0
                debug_sim_class_option = nil -- trigger once
            else
                local castName = UnitCastingInfo("player")
                if castName and (castName:find("Holy Light") or castName:find("Flash of Light")) then
                    isCastingHoly = true
                end
            end
            if isCastingHoly then
                paladinFlareTimer = 1.0
            elseif paladinFlareTimer > 0 and elapsed then
                paladinFlareTimer = math.max(0, paladinFlareTimer - elapsed * 1.5)
            end
            if paladinFlareTimer > 0 then
                local flarePct = paladinFlareTimer
                brightnessMod = brightnessMod * (1.0 + (0.45 * flarePct))
                r = r + (1.0 - r) * 0.35 * flarePct
                g = g + (0.90 - g) * 0.35 * flarePct
                b = b + (0.40 - b) * 0.35 * flarePct
            end

        elseif effectiveClass == "HUNTER" then
            local petDeadOrMissing = false
            if debug_sim_class == "HUNTER" then
                petDeadOrMissing = (debug_sim_class_option == "dead")
            else
                petDeadOrMissing = not UnitExists("pet") or UnitIsDeadOrGhost("pet")
            end
            if petDeadOrMissing then
                brightnessMod = brightnessMod * 0.32
            end

        elseif effectiveClass == "PRIEST" then
            local hasShield = false
            if debug_sim_class == "PRIEST" then
                hasShield = (debug_sim_class_option == "shield")
            else
                if UnitBuff then
                    for i = 1, 40 do
                        local name = UnitBuff("player", i)
                        if not name then break end
                        if name == "Power Word: Shield" then
                            hasShield = true
                            break
                        end
                    end
                elseif C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
                    if C_UnitAuras.GetPlayerAuraBySpellID(17) then
                        hasShield = true
                    end
                end
            end
            if hasShield then
                priestInversionTimer = 1.0
                coreInvertAlpha = 0.0 -- Invert: inner core is completely extinguished (0%)
            else
                if priestInversionTimer > 0 and elapsed then
                    priestInversionTimer = math.max(0, priestInversionTimer - elapsed * 2.0)
                    coreInvertAlpha = 1.0 - priestInversionTimer
                else
                    coreInvertAlpha = 1.0
                end
            end

        elseif effectiveClass == "SHAMAN" then
            totemData = {}
            if debug_sim_class == "SHAMAN" and debug_sim_class_option then
                local numTotems = tonumber(debug_sim_class_option) or 0
                for slot = 1, math.min(4, numTotems) do
                    table.insert(totemData, slot) -- 1=Fire, 2=Earth, 3=Water, 4=Air
                end
            elseif GetTotemInfo then
                for slot = 1, 4 do
                    local haveTotem, name, startTime, duration = GetTotemInfo(slot)
                    if haveTotem and (duration == 0 or (startTime + duration > GetTime())) then
                        table.insert(totemData, slot) -- 1=Fire, 2=Earth, 3=Water, 4=Air
                    end
                end
            end
        end
    end

    -- Tier 3: Aggro Detection (Center Red Warning)
    local hasAggro = false
    if IsTierUnlocked(3) then
        hasAggro = CheckPlayerHasAggro()
    end

    return r, g, b, brightnessMod, coreInvertAlpha, totemData, hasAggro
end

-- -------------------------------------------------------------------------
-- Overlay & Texture Frames
-- -------------------------------------------------------------------------
local canvasFrame = CreateFrame("Frame", "TimelessForever_NightlightCanvas", UIParent)
canvasFrame:SetAllPoints(UIParent)
canvasFrame:SetFrameStrata("HIGH")
canvasFrame:SetFrameLevel(1)
canvasFrame:EnableMouse(false)
canvasFrame:Hide()

-- Ambient background overlay
local ambientBg = canvasFrame:CreateTexture(nil, "BACKGROUND")
ambientBg:SetAllPoints(canvasFrame)
ambientBg:SetColorTexture(0, 0, 0, 0.5)
ambientBg:Hide()

-- Aperture frame following cursor
local holeFrame = CreateFrame("Frame", "TimelessForever_NightlightHole", canvasFrame)
holeFrame:SetSize(380, 380)
holeFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 500, 500)
holeFrame:EnableMouse(false)

local holeTex = holeFrame:CreateTexture(nil, "BACKGROUND")
holeTex:SetAllPoints(holeFrame)
holeTex:SetTexture(TEX_DARKNESS_HOLE)
if holeTex.SetSnapToPixelGrid then
    holeTex:SetSnapToPixelGrid(false)
    holeTex:SetTexelSnappingBias(0)
end

-- 4 surrounding darkness panels
local OVERSCAN = 3000

local topBg = canvasFrame:CreateTexture(nil, "BACKGROUND")
topBg:SetColorTexture(0, 0, 0, 0.78)
topBg:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -OVERSCAN, OVERSCAN)
topBg:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", OVERSCAN, OVERSCAN)
topBg:SetPoint("BOTTOM", holeFrame, "TOP", 0, 0)

local bottomBg = canvasFrame:CreateTexture(nil, "BACKGROUND")
bottomBg:SetColorTexture(0, 0, 0, 0.78)
bottomBg:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -OVERSCAN, -OVERSCAN)
bottomBg:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", OVERSCAN, -OVERSCAN)
bottomBg:SetPoint("TOP", holeFrame, "BOTTOM", 0, 0)

local leftBg = canvasFrame:CreateTexture(nil, "BACKGROUND")
leftBg:SetColorTexture(0, 0, 0, 0.78)
leftBg:SetPoint("TOPLEFT", topBg, "BOTTOMLEFT", 0, 0)
leftBg:SetPoint("BOTTOMLEFT", bottomBg, "TOPLEFT", 0, 0)
leftBg:SetPoint("RIGHT", holeFrame, "LEFT", 0, 0)

local rightBg = canvasFrame:CreateTexture(nil, "BACKGROUND")
rightBg:SetColorTexture(0, 0, 0, 0.78)
rightBg:SetPoint("TOPRIGHT", topBg, "BOTTOMRIGHT", 0, 0)
rightBg:SetPoint("BOTTOMRIGHT", bottomBg, "TOPRIGHT", 0, 0)
rightBg:SetPoint("LEFT", holeFrame, "RIGHT", 0, 0)

for _, tex in ipairs({ topBg, bottomBg, leftBg, rightBg, ambientBg }) do
    if tex.SetSnapToPixelGrid then
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
    end
end

-- Dedicated container frame for all illuminating light textures
lightGlowFrame = CreateFrame("Frame", "TimelessForever_NightlightGlowContainer", holeFrame)
lightGlowFrame:SetAllPoints(holeFrame)
lightGlowFrame:EnableMouse(false)

-- Radial light glow & core
local glowTex = lightGlowFrame:CreateTexture(nil, "ARTWORK")
glowTex:SetPoint("CENTER", lightGlowFrame, "CENTER", 0, 0)
glowTex:SetTexture(TEX_LIGHT_GLOW)
glowTex:SetBlendMode("ADD")

local coreTex = lightGlowFrame:CreateTexture(nil, "OVERLAY")
coreTex:SetPoint("CENTER", lightGlowFrame, "CENTER", 0, 0)
coreTex:SetTexture(TEX_LIGHT_CORE)
coreTex:SetBlendMode("ADD")

-- Shaman Totem Wedges (up to 4 segments around the perimeter)
local totemWedges = {}
local TOTEM_COLORS = {
    [1] = { r = 1.00, g = 0.35, b = 0.05 }, -- Fire (Bright blazing flame)
    [2] = { r = 1.00, g = 0.75, b = 0.15 }, -- Earth (Luminous golden-amber stone)
    [3] = { r = 0.10, g = 0.75, b = 1.00 }, -- Water (Vibrant crystalline azure)
    [4] = { r = 0.80, g = 0.95, b = 1.00 }, -- Air (Electric bright sky-blue)
}

for i = 1, 4 do
    local wedge = lightGlowFrame:CreateTexture(nil, "ARTWORK")
    wedge:SetTexture(TEX_TOTEM_WEDGE)
    wedge:SetBlendMode("ADD")
    wedge:Hide()
    totemWedges[i] = wedge
end

-- -------------------------------------------------------------------------
-- Cursor Torch: Shrink-and-Overlay Mechanic
-- -------------------------------------------------------------------------
local torchCursorOverlay = CreateFrame("Frame", "TimelessForever_NightlightCursorTorch", UIParent)
torchCursorOverlay:SetSize(30, 30)
torchCursorOverlay:SetFrameStrata("TOOLTIP")
torchCursorOverlay:SetFrameLevel(999)
torchCursorOverlay:EnableMouse(false)
torchCursorOverlay:Hide()

local torchCursorTex = torchCursorOverlay:CreateTexture(nil, "OVERLAY")
torchCursorTex:SetAllPoints(torchCursorOverlay)
torchCursorTex:SetTexture(TEX_TORCH_CURSOR)

local function ApplyCursorShrink(enable)
    local db = GetDB()
    if not db.torchCursorOverlay then
        torchCursorOverlay:Hide()
        return
    end

    if enable then
        torchCursorOverlay:Show()
    else
        torchCursorOverlay:Hide()
    end
end

-- -------------------------------------------------------------------------
-- Floating Nightlight Button
-- -------------------------------------------------------------------------
local floatingIcon = CreateFrame("Button", "TimelessForever_NightlightIcon", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
floatingIcon:SetSize(36, 36)
floatingIcon:SetFrameStrata("MEDIUM")
floatingIcon:SetFrameLevel(55)
floatingIcon:SetClampedToScreen(true)
floatingIcon:SetMovable(true)
floatingIcon:EnableMouse(true)
floatingIcon:EnableMouseWheel(true)

if floatingIcon.SetBackdrop then
    floatingIcon:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    floatingIcon:SetBackdropColor(0.05, 0.05, 0.08, 0.90)
    floatingIcon:SetBackdropBorderColor(1.0, 0.75, 0.25, 0.95)
else
    local iconBg = floatingIcon:CreateTexture(nil, "BACKGROUND")
    iconBg:SetAllPoints()
    iconBg:SetColorTexture(0, 0, 0, 0.8)
end

local iconTex = floatingIcon:CreateTexture(nil, "ARTWORK")
iconTex:SetPoint("TOPLEFT", floatingIcon, "TOPLEFT", 2, -2)
iconTex:SetPoint("BOTTOMRIGHT", floatingIcon, "BOTTOMRIGHT", -2, 2)
iconTex:SetTexture("Interface\\Icons\\INV_Misc_Lantern_01")
iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local highlight = floatingIcon:CreateTexture(nil, "HIGHLIGHT")
highlight:SetPoint("TOPLEFT", floatingIcon, "TOPLEFT", 2, -2)
highlight:SetPoint("BOTTOMRIGHT", floatingIcon, "BOTTOMRIGHT", -2, 2)
highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
highlight:SetBlendMode("ADD")

local btnGlow = floatingIcon:CreateTexture(nil, "OVERLAY")
btnGlow:SetPoint("CENTER", floatingIcon, "CENTER", 0, 0)
btnGlow:SetSize(56, 56)
btnGlow:SetTexture(TEX_LIGHT_GLOW)
btnGlow:SetBlendMode("ADD")
btnGlow:Hide()

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
        floatingIcon:SetPoint("CENTER", UIParent, "CENTER", 60, 100)
    end
end

-- -------------------------------------------------------------------------
-- Hardware Gamma CVar Synchronization
-- -------------------------------------------------------------------------
local originalGamma = nil
local function SyncHardwareGamma(factor)
    local db = GetDB()
    if not db.adjustGamma then
        if originalGamma and SetCVar then
            pcall(SetCVar, "gamma", originalGamma)
            originalGamma = nil
        end
        return
    end

    if not originalGamma and GetCVar then
        originalGamma = GetCVar("gamma") or "1.0"
    end

    local gTarget = 1.0 - (factor * 0.40)
    pcall(SetCVar, "gamma", string.format("%.2f", gTarget))
end

-- -------------------------------------------------------------------------
-- Visual Rendering & Real-Time Tracking
-- -------------------------------------------------------------------------
local curX, curY = nil, nil
local flickerTime = 0

local function ApplyLightVisuals(flickerMod, radiusMod, elapsed)
    local db = GetDB()
    flickerMod = flickerMod or 1.0
    radiusMod = radiusMod or 1.0

    local currentDarkness, factor = CalculateCurrentDarkness()
    SyncHardwareGamma(factor)

    local mode = db.mode or "LANTERN_DARK"
    local baseRadius = math.max(80, math.min(1200, db.radius or 380))
    local diameter = baseRadius * 2.0 * radiusMod

    holeFrame:SetSize(diameter, diameter)
    glowTex:SetSize(diameter * 0.92, diameter * 0.92)
    coreTex:SetSize(diameter * 0.44, diameter * 0.44)

    local showDarkness = (mode == "LANTERN_DARK" or mode == "SPOTLIGHT_ONLY") and currentDarkness > 0.005
    local showGlow     = (mode == "LANTERN_DARK" or mode == "GLOW_ONLY")

    if showDarkness then
        holeTex:SetVertexColor(0, 0, 0, currentDarkness)
        topBg:SetColorTexture(0, 0, 0, currentDarkness)
        bottomBg:SetColorTexture(0, 0, 0, currentDarkness)
        leftBg:SetColorTexture(0, 0, 0, currentDarkness)
        rightBg:SetColorTexture(0, 0, 0, currentDarkness)
        holeTex:Show()
        topBg:Show()
        bottomBg:Show()
        leftBg:Show()
        rightBg:Show()
    else
        holeTex:Hide()
        topBg:Hide()
        bottomBg:Hide()
        leftBg:Hide()
        rightBg:Hide()
    end

    if showGlow then
        -- Base color
        local baseR, baseG, baseB
        local preset = COLOR_PRESETS[db.colorPreset or "TORCH"] or COLOR_PRESETS["TORCH"]
        if db.colorPreset == "CUSTOM" and db.customColor then
            baseR = db.customColor.r or 1.0
            baseG = db.customColor.g or 0.72
            baseB = db.customColor.b or 0.30
        else
            baseR, baseG, baseB = preset.r, preset.g, preset.b
        end

        -- Tier 2: Health-Based Dimming (Applied to container frame, native secret-value safe)
        ApplyHealthDimming(elapsed)

        -- Tier 3 & Tier 4: Class Behaviors & Target Aggro
        local r, g, b, classBrightnessMod, coreInvertAlpha, totemData, hasAggro = EvaluateClassBehavior(baseR, baseG, baseB, elapsed)

        -- Default 50% brightness band modulated by class behavior and flicker
        local baseBrightness = 0.50
        local finalBrightness = baseBrightness * classBrightnessMod * flickerMod

        local gAlpha = math.max(0, math.min(1.0, finalBrightness))

        -- Outer edge / halo: Class abilities color & flair
        glowTex:SetVertexColor(r, g, b, gAlpha)
        glowTex:Show()
        lightGlowFrame:Show()

        -- Center: Red Aggro Warning when holding aggro; otherwise normal bloom/hotspot
        if hasAggro then
            -- Center shines with vivid red aggro warning
            coreTex:SetBlendMode("BLEND")
            local aggroAlpha = math.max(0.75, math.min(1.0, finalBrightness * 1.5))
            coreTex:SetVertexColor(1.00, 0.10, 0.10, aggroAlpha)
            coreTex:Show()
        else
            -- Normal center bloom (controlled by setting and class inversion like Priest PW:S)
            coreTex:SetBlendMode("ADD")
            local bloomVal = db.coreBloom
            if bloomVal == nil then bloomVal = 0.20 end
            local cAlpha = math.max(0, math.min(1.0, finalBrightness * bloomVal * coreInvertAlpha))

            if cAlpha > 0.005 then
                coreTex:SetVertexColor(math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, b + 0.10), cAlpha)
                coreTex:Show()
            else
                coreTex:Hide()
            end
        end

        -- Shaman Totem Wedges
        if totemData and #totemData > 0 then
            local count = #totemData
            for idx = 1, 4 do
                local wedge = totemWedges[idx]
                if idx <= count then
                    local slot = totemData[idx]
                    local col = TOTEM_COLORS[slot] or { r = 1, g = 1, b = 1 }
                    wedge:SetSize(diameter * 0.95, diameter * 0.95)
                    wedge:ClearAllPoints()
                    wedge:SetPoint("CENTER", lightGlowFrame, "CENTER", 0, 0)
                    -- Distribute evenly around the 4 quadrant sectors
                    local rotAngle = (idx - 1) * (math.pi * 2.0 / math.max(1, count))
                    if wedge.SetRotation then
                        wedge:SetRotation(rotAngle)
                    end
                    -- Brighter, vivid totem radiance
                    local tAlpha = math.min(1.0, math.max(0.70, gAlpha * 1.6))
                    wedge:SetVertexColor(col.r, col.g, col.b, tAlpha)
                    wedge:Show()
                else
                    wedge:Hide()
                end
            end
        else
            for _, wedge in ipairs(totemWedges) do
                wedge:Hide()
            end
        end
    else
        lightGlowFrame:Hide()
        glowTex:Hide()
        coreTex:Hide()
        for _, wedge in ipairs(totemWedges) do
            wedge:Hide()
        end
    end
end

-- -------------------------------------------------------------------------
-- Active OnUpdate Frame Script
-- -------------------------------------------------------------------------
local function OnLightUpdate(self, elapsed)
    -- Periodic stealth check
    if GetTime() - lastStealthCheck > 0.3 then
        lastStealthCheck = GetTime()
        HandleStealthUpdate()
    end

    local isActive, reason = ShouldLightBeActive()
    local db = GetDB()

    if not isActive then
        ApplyCursorShrink(false)
        -- Inactive / Dormant / Daytime outside cities:
        -- Check if Ambient Day/Night Darkness should remain active for whole screen
        if IsTierUnlocked(1) and db.dayNightCycle and db.dayNightAmbientAlways then
            local currentDarkness, factor = CalculateCurrentDarkness()
            SyncHardwareGamma(factor)
            if currentDarkness > 0.005 then
                canvasFrame:Show()
                holeFrame:Hide()
                topBg:Hide()
                bottomBg:Hide()
                leftBg:Hide()
                rightBg:Hide()
                ambientBg:SetColorTexture(0, 0, 0, currentDarkness)
                ambientBg:Show()
                return
            end
        end
        canvasFrame:Hide()
        return
    end

    -- Light is active: Follow cursor
    ambientBg:Hide()
    holeFrame:Show()

    local rawX, rawY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale <= 0 then scale = 1 end
    local targetX = rawX / scale
    local targetY = rawY / scale

    if db.smoothFollow and curX and curY then
        local speed = db.smoothSpeed or 18
        local factor = math.min(1.0, elapsed * speed)
        curX = curX + (targetX - curX) * factor
        curY = curY + (targetY - curY) * factor
    else
        curX = targetX
        curY = targetY
    end

    holeFrame:ClearAllPoints()
    holeFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", curX, curY)

    -- Cursor Torch Overlay positioning (aligns flame hotspot with mouse pointer)
    if db.torchCursorOverlay then
        ApplyCursorShrink(true)
        torchCursorOverlay:ClearAllPoints()
        torchCursorOverlay:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", curX - 3, curY + 3)
    else
        ApplyCursorShrink(false)
    end

    -- Flicker modulation
    local flickerMod = 1.0
    local radiusMod = 1.0
    if db.flickerEnabled and (db.flickerAmount or 0) > 0 then
        flickerTime = flickerTime + elapsed
        local amt = db.flickerAmount or 0.20
        local wave = math.sin(flickerTime * 6.7) * 0.45
                   + math.sin(flickerTime * 14.3) * 0.35
                   + math.sin(flickerTime * 23.9) * 0.20
        flickerMod = 1.0 + (wave * amt * 0.45)
        radiusMod  = 1.0 + (wave * amt * 0.06)
    end

    ApplyLightVisuals(flickerMod, radiusMod, elapsed)
end

UpdateNightlightState = function()
    local db = GetDB()
    canvasFrame:SetFrameStrata(db.strata or "HIGH")
    iconTex:SetTexture("Interface\\Icons\\" .. (db.buttonIcon or "INV_Misc_Lantern_01"))

    if db.showIcon == false then
        floatingIcon:Hide()
    else
        floatingIcon:Show()
    end

    local isActive, reason = ShouldLightBeActive()

    if isActive then
        curX, curY = nil, nil
        ambientBg:Hide()
        holeFrame:Show()
        canvasFrame:Show()
        canvasFrame:SetScript("OnUpdate", OnLightUpdate)
        ApplyLightVisuals(1.0, 1.0, 0)
        ApplyCursorShrink(true)

        iconTex:SetDesaturated(false)
        floatingIcon:SetAlpha(1.0)
        local preset = COLOR_PRESETS[db.colorPreset or "TORCH"] or COLOR_PRESETS["TORCH"]
        btnGlow:SetVertexColor(preset.r, preset.g, preset.b, 0.65)
        btnGlow:Show()
        if floatingIcon.SetBackdropBorderColor then
            floatingIcon:SetBackdropBorderColor(preset.r, preset.g, preset.b, 0.95)
        end
    else
        btnGlow:Hide()
        iconTex:SetDesaturated(true)
        floatingIcon:SetAlpha(0.60)
        if floatingIcon.SetBackdropBorderColor then
            floatingIcon:SetBackdropBorderColor(0.35, 0.35, 0.40, 0.80)
        end
        ApplyCursorShrink(false)

        -- If Tier 1 is unlocked, keep background darkness on if applicable
        if IsTierUnlocked(1) and db.dayNightCycle and db.dayNightAmbientAlways then
            local currentDarkness, factor = CalculateCurrentDarkness()
            SyncHardwareGamma(factor)
            if currentDarkness > 0.005 then
                holeFrame:Hide()
                topBg:Hide()
                bottomBg:Hide()
                leftBg:Hide()
                rightBg:Hide()
                ambientBg:SetColorTexture(0, 0, 0, currentDarkness)
                ambientBg:Show()
                canvasFrame:Show()
                canvasFrame:SetScript("OnUpdate", OnLightUpdate)
            else
                ambientBg:Hide()
                canvasFrame:SetScript("OnUpdate", nil)
                canvasFrame:Hide()
            end
        else
            ambientBg:Hide()
            canvasFrame:SetScript("OnUpdate", nil)
            canvasFrame:Hide()
        end
    end
end

local function ToggleNightlight(forceState, silent)
    local db = GetDB()
    wasLitBeforeStealth = false

    if not IsTierUnlocked(1) then
        if not silent then
            print("|cff00ccff[Nightlight]|r |cffff8000Dormant:|r Visit your class trainer at level 4–6 to awaken Tier 1.")
        end
        return
    end

    if type(forceState) == "boolean" then
        db.enabled = forceState
    else
        db.enabled = not db.enabled
    end
    UpdateNightlightState()
    NotifyOptionsChange()
    if not silent then
        print(string.format(
            "|cff00ccff[Nightlight]|r Lantern is now %s",
            db.enabled and "|cffffd100LIT (ON)|r" or "|cff888888EXTINGUISHED (OFF)|r"
        ))
    end
end

-- -------------------------------------------------------------------------
-- Floating Icon Scripts
-- -------------------------------------------------------------------------
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
        local point, _, relativePoint, x, y = self:GetPoint()
        local db = GetDB()
        db.iconPos = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = x or 60,
            y = y or 100,
        }
        return
    end

    if button == "LeftButton" then
        ToggleNightlight()
    elseif button == "RightButton" then
        local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
        if suite and suite.OpenSettings then
            suite:OpenSettings("nightlight")
        end
    end
end)

floatingIcon:SetScript("OnMouseWheel", function(self, delta)
    local db = GetDB()
    local step = 25
    db.radius = math.max(100, math.min(900, (db.radius or 380) + (delta * step)))
    if db.enabled then
        ApplyLightVisuals(1.0, 1.0, 0)
    end
    NotifyOptionsChange()
    if GameTooltip:IsOwned(self) then
        self:GetScript("OnEnter")(self)
    end
end)

floatingIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cff00ccffNightlight|r", 1, 1, 1)

    local isT1 = IsTierUnlocked(1)
    local isT2 = IsTierUnlocked(2)
    local isT3 = IsTierUnlocked(3)
    local isT4 = IsTierUnlocked(4)

    if not isT1 then
        GameTooltip:AddLine("|cffff3333Dormant (Level 1)|r", 1, 0.4, 0.4)
        GameTooltip:AddLine("Level 4+ or trainer required to earn Tier 1.", 0.7, 0.7, 0.7, true)
    else
        local isActive, reason = ShouldLightBeActive()
        GameTooltip:AddLine(
            isActive and "|cffffd100Active (Illuminating)|r" or ("|cff888888Sleeping (" .. reason .. ")|r"),
            1, 1, 1
        )
        local unlockedCount = (isT4 and 4) or (isT3 and 3) or (isT2 and 2) or (isT1 and 1) or 0
        GameTooltip:AddLine(string.format("Progression: Tier %d/4 Unlocked", unlockedCount), 0.2, 1, 0.6)
    end

    local currentDarkness, factor, hour, phase = CalculateCurrentDarkness()
    local timeStr = string.format("%02d:%02d", math.floor(hour), math.floor((hour % 1) * 60))
    GameTooltip:AddLine(string.format("Realm Time: |cffffffff%s|r (%s)", timeStr, phase), 1, 0.82, 0.4)
    GameTooltip:AddLine(string.format("City Status: %s", IsInCityOrResting() and "|cff00ff00In Sanctuary|r" or "|cffaaaaaaWilderness|r"), 0.8, 0.8, 0.8)

    if isCurrentlyStealthed then
        GameTooltip:AddLine("|cffff8000Stealthed (Light Suppressed)|r", 1, 0.8, 0.2)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Light On / Off", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffffRight-Click:|r Open Settings Hub", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffffMouse Wheel:|r Adjust Light Radius", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffffShift + Drag:|r Move Bar", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)

floatingIcon:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Register with TimelessForever Button Bar
if _G.TimelessForever_ButtonBar then
    _G.TimelessForever_ButtonBar:RegisterButton("nightlight", floatingIcon, 1, 36, 36)
end

-- -------------------------------------------------------------------------
-- Debug API Bridge (Used by TimelessForever_nightlight_Debug addon)
-- -------------------------------------------------------------------------
local NightlightDebugAPI = {
    GetTierUnlocked = function(tier) return IsTierUnlocked(tier) end,
    SetTierOverride = function(tier, val)
        if tier == 1 then debug_tier1 = val
        elseif tier == 2 then debug_tier2 = val
        elseif tier == 3 then debug_tier3 = val
        elseif tier == 4 then debug_tier4 = val
        end
        UpdateNightlightState()
        NotifyOptionsChange()
    end,
    GetTierOverride = function(tier)
        if tier == 1 then return debug_tier1
        elseif tier == 2 then return debug_tier2
        elseif tier == 3 then return debug_tier3
        elseif tier == 4 then return debug_tier4
        end
    end,
    SetNightOverride = function(val)
        debug_force_night = val
        UpdateNightlightState()
        NotifyOptionsChange()
    end,
    GetNightOverride = function()
        return debug_force_night
    end,
    SetForceAggro = function(val)
        debug_force_aggro = val
        UpdateNightlightState()
        NotifyOptionsChange()
    end,
    GetForceAggro = function()
        return debug_force_aggro
    end,
    SetClassSimulation = function(cls, opt)
        debug_sim_class = cls
        debug_sim_class_option = opt
        if cls ~= nil then
            debug_tier4 = true
            debug_force_night = true
        end
        UpdateNightlightState()
        NotifyOptionsChange()
    end,
    GetClassSimulation = function()
        return debug_sim_class, debug_sim_class_option
    end,
    UnlockTier = function(tier, announce)
        UnlockTier(tier, announce)
    end,
    ResetEarnedFlags = function()
        local c = GetCharData()
        c.tier1_earned = false
        c.tier2_earned = false
        c.tier3_earned = false
        c.tier4_earned = false
        debug_tier1 = nil
        debug_tier2 = nil
        debug_tier3 = nil
        debug_tier4 = nil
        debug_force_night = nil
        debug_force_aggro = nil
        debug_sim_class = nil
        debug_sim_class_option = nil
        UpdateNightlightState()
        NotifyOptionsChange()
    end,
    ClearOverrides = function()
        debug_tier1 = nil
        debug_tier2 = nil
        debug_tier3 = nil
        debug_tier4 = nil
        debug_force_night = nil
        debug_force_aggro = nil
        debug_sim_class = nil
        debug_sim_class_option = nil
        UpdateNightlightState()
        NotifyOptionsChange()
    end,
    GetCharData = function()
        return GetCharData()
    end,
    GetDB = function()
        return GetDB()
    end,
    UpdateNightlightState = function()
        UpdateNightlightState()
    end,
    NotifyOptionsChange = function()
        NotifyOptionsChange()
    end,
    RegisterDebugHandler = function(handler)
        NightlightApp.debugHandler = handler
        NotifyOptionsChange()
    end,
    OpenDebugFrame = function()
        if NightlightApp.debugHandler and NightlightApp.debugHandler.Open then
            NightlightApp.debugHandler.Open()
        end
    end,
}
_G.TimelessForever_NightlightDebugAPI = NightlightDebugAPI

-- -------------------------------------------------------------------------
-- Suite Hub Integration Options
-- -------------------------------------------------------------------------
local function BuildNightlightOptions()
    return {
        header = {
            name = "|TInterface\\Icons\\INV_Misc_Lantern_01:14:14:0:0|t |cff00ccffNightlight|r",
            type = "header",
            order = 1,
        },
        desc = {
            name = "Subtle, night-only cursor light designed to illuminate your mouse pointer at 50% brightness. Earned through progression in 4 natural tiers.\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },

        -- Progression Status Header
        progHeader = {
            name = "Trainer & Level Progression",
            type = "header",
            order = 5,
        },
        progDesc = {
            name = function()
                local t1 = IsTierUnlocked(1) and "|cff00ff00UNLOCKED|r" or "|cffff3333LOCKED (Level 4+ or Trainer)|r"
                local t2 = IsTierUnlocked(2) and "|cff00ff00UNLOCKED|r" or "|cffff3333LOCKED (Level 10+ or Trainer)|r"
                local t3 = IsTierUnlocked(3) and "|cff00ff00UNLOCKED|r" or "|cffff3333LOCKED (Level 14+ or Aggro Spell)|r"
                local t4 = IsTierUnlocked(4) and "|cff00ff00UNLOCKED|r" or "|cffff3333LOCKED (Level 20+ or Trainer)|r"
                return string.format(
                    "• |cffffd100Tier 1 (Basic Light):|r %s\n" ..
                    "• |cffffd100Tier 2 (Health Dimming):|r %s\n" ..
                    "• |cffffd100Tier 3 (Aggro Red Warning):|r %s\n" ..
                    "• |cffffd100Tier 4 (Class Behaviors):|r %s\n",
                    t1, t2, t3, t4
                )
            end,
            type = "description",
            order = 6,
        },
        openDebugBtn = {
            name = "Open Testing Panel",
            desc = "Open the draggable testing panel to simulate tiers and preview class behaviors (requires TimelessForever_nightlight_Debug addon).",
            type = "execute",
            order = 7,
            hidden = function()
                -- Only show up if Debug is enabled and loaded
                if not (NightlightApp.debugHandler ~= nil) then
                    return true
                end
                local db = GetDB()
                if db and db.debugEnabled == false then
                    return true
                end
                return false
            end,
            func = function()
                if NightlightDebugAPI and NightlightDebugAPI.OpenDebugFrame and NightlightApp.debugHandler then
                    NightlightDebugAPI.OpenDebugFrame()
                end
            end,
        },

        -- Core Behavior
        coreHeader = {
            name = "Night & City Rules",
            type = "header",
            order = 10,
        },
        activeOnlyAtNight = {
            name = "Activate Only at Night",
            desc = "Light sleeps during daytime in the wilderness, awakening naturally when night falls.",
            type = "toggle",
            order = 11,
            get = function() return GetDB().activeOnlyAtNight ~= false end,
            set = function(_, val)
                GetDB().activeOnlyAtNight = val
                UpdateNightlightState()
            end,
        },
        stayActiveInCities = {
            name = "Remain Active in Cities & Inns",
            desc = "Keeps Nightlight active in capital cities and taverns where torchlight is always welcomed.",
            type = "toggle",
            order = 12,
            get = function() return GetDB().stayActiveInCities ~= false end,
            set = function(_, val)
                GetDB().stayActiveInCities = val
                UpdateNightlightState()
            end,
        },
        torchCursorOverlay = {
            name = "Cursor Torch Overlay (Shrink-and-Overlay)",
            desc = "Replaces the standard pointer with a small illuminating torch overlay while active.",
            type = "toggle",
            order = 13,
            get = function() return GetDB().torchCursorOverlay ~= false end,
            set = function(_, val)
                GetDB().torchCursorOverlay = val
                UpdateNightlightState()
            end,
        },

        -- Stealth Header
        stealthHeader = {
            name = "Rogue & Stealth Auto-Extinguish",
            type = "header",
            order = 20,
        },
        stealthAutoExtinguish = {
            name = "Auto-Extinguish in Stealth",
            desc = "Turns off the light while stealthed so you remain hidden in the shadows, relighting when stealth ends.",
            type = "toggle",
            order = 21,
            get = function() return GetDB().stealthAutoExtinguish ~= false end,
            set = function(_, val)
                GetDB().stealthAutoExtinguish = val
                HandleStealthUpdate()
            end,
        },
        stealthRogueOnly = {
            name = "Rogue Class Only",
            desc = "Restrict auto-extinguish strictly to Rogues (uncheck to allow Druid Prowl and Shadowmeld).",
            type = "toggle",
            order = 22,
            get = function() return GetDB().stealthRogueOnly == true end,
            set = function(_, val)
                GetDB().stealthRogueOnly = val
                HandleStealthUpdate()
            end,
        },

        -- Light Appearance
        appearanceHeader = {
            name = "Light Appearance & Radius",
            type = "header",
            order = 30,
        },
        radius = {
            name = "Light Radius (Size)",
            desc = "Radius of the illuminated area around your mouse cursor (pixels).",
            type = "range",
            order = 31,
            min = 100,
            max = 900,
            step = 10,
            get = function() return GetDB().radius or 380 end,
            set = function(_, val)
                GetDB().radius = val
                UpdateNightlightState()
            end,
        },
        coreBloom = {
            name = "Center Bloom / Core Hotspot",
            desc = "Intensity of the bright luminous core in the center of the light. Set to 0% to completely eliminate the center glare.",
            type = "range",
            order = 31.5,
            min = 0.0,
            max = 1.0,
            step = 0.05,
            isPercent = true,
            get = function()
                local val = GetDB().coreBloom
                if val == nil then val = 0.20 end
                return val
            end,
            set = function(_, val)
                GetDB().coreBloom = val
                UpdateNightlightState()
            end,
        },
        colorPreset = {
            name = "Light Color Preset",
            desc = "Select default warm light color (overridden by spec colors for Mage Tier 3).",
            type = "select",
            width = "normal",
            order = 32,
            values = COLOR_PRESET_DROPDOWN,
            get = function() return GetDB().colorPreset or "TORCH" end,
            set = function(_, val)
                GetDB().colorPreset = val
                UpdateNightlightState()
            end,
        },
        showIcon = {
            name = "Show Floating Toggle Button",
            desc = "Show or hide the on-screen lantern toggle button.",
            type = "toggle",
            order = 33,
            get = function() return GetDB().showIcon ~= false end,
            set = function(_, val)
                GetDB().showIcon = val
                UpdateNightlightState()
            end,
        },
    }
end

local function RegisterWithSuiteHub()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        pcall(function()
            suite:RegisterModuleTab("nightlight", "Nightlight", 8, BuildNightlightOptions())
        end)
    end
end

-- -------------------------------------------------------------------------
-- Trainer Hook & Spell Learning Detection
-- -------------------------------------------------------------------------
if BuyTrainerService and not NightlightApp.trainerHooked then
    hooksecurefunc("BuyTrainerService", function(serviceIndex)
        if not serviceIndex or not GetTrainerServiceLevelReq then return end
        local reqLevel = GetTrainerServiceLevelReq(serviceIndex)
        if reqLevel then
            if reqLevel >= 4 and reqLevel <= 6 then
                UnlockTier(1, true)
            elseif reqLevel >= 9 and reqLevel <= 11 then
                UnlockTier(2, true)
            elseif reqLevel >= 14 and reqLevel <= 16 then
                UnlockTier(3, true)
            elseif reqLevel >= 19 and reqLevel <= 22 then
                UnlockTier(4, true)
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.2, function() CheckAutoUnlockProgression(true) end)
        else
            CheckAutoUnlockProgression(true)
        end
    end)
    NightlightApp.trainerHooked = true
end

-- -------------------------------------------------------------------------
-- Lifecycle & Event Listeners
-- -------------------------------------------------------------------------
NightlightApp:RegisterEvent("ADDON_LOADED")
NightlightApp:RegisterEvent("PLAYER_LOGIN")
NightlightApp:RegisterEvent("PLAYER_ENTERING_WORLD")
NightlightApp:RegisterEvent("PLAYER_LEVEL_UP")
NightlightApp:RegisterEvent("SPELLS_CHANGED")
NightlightApp:RegisterEvent("UPDATE_STEALTH")
NightlightApp:RegisterEvent("UNIT_AURA")
NightlightApp:RegisterEvent("UNIT_HEALTH")
NightlightApp:RegisterEvent("UNIT_PET")
NightlightApp:RegisterEvent("PLAYER_REGEN_DISABLED")
NightlightApp:RegisterEvent("PLAYER_REGEN_ENABLED")
NightlightApp:RegisterEvent("TRAINER_UPDATE")
NightlightApp:RegisterEvent("PLAYER_TALENT_UPDATE")
NightlightApp:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

NightlightApp:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME or arg1 == "TimelessForever_nightlight" then
            GetDB()
            RestoreIconPosition()
            UpdateNightlightState()
            CheckAutoUnlockProgression(false)
        end
    elseif event == "PLAYER_LOGIN" then
        GetDB()
        RestoreIconPosition()
        CheckAutoUnlockProgression(false)
        UpdateNightlightState()
        RegisterWithSuiteHub()
        HandleStealthUpdate()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, RegisterWithSuiteHub)
            C_Timer.After(0.5, HandleStealthUpdate)
            C_Timer.After(1.0, function() CheckAutoUnlockProgression(false) end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckAutoUnlockProgression(false)
        HandleStealthUpdate()
    elseif event == "PLAYER_LEVEL_UP" then
        CheckAutoUnlockProgression(true)
    elseif event == "SPELLS_CHANGED" then
        CheckAutoUnlockProgression(true)
    elseif event == "UNIT_HEALTH" then
        if arg1 == "player" or arg1 == "pet" then
            ApplyHealthDimming(0)
        end
    elseif event == "UNIT_PET" then
        ApplyHealthDimming(0)
    elseif event == "UPDATE_STEALTH" or (event == "UNIT_AURA" and arg1 == "player") or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        HandleStealthUpdate()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        -- Paladin instant cast flare (Judgement, Holy Shock, etc.)
        local spellName = arg2
        if spellName and (spellName:find("Judgement") or spellName:find("Holy Shock") or spellName:find("Lay on Hands")) then
            paladinFlareTimer = 1.0
        end
    elseif event == "PLAYER_TALENT_UPDATE" then
        -- Update Mage spec live
        if IsTierUnlocked(4) then
            UpdateNightlightState()
        end
    end
end)

-- -------------------------------------------------------------------------
-- Slash Commands
-- -------------------------------------------------------------------------
SLASH_TF_NIGHTLIGHT1 = "/nightlight"
SLASH_TF_NIGHTLIGHT2 = "/tfnl"
SLASH_TF_NIGHTLIGHT3 = "/lantern"

SlashCmdList["TF_NIGHTLIGHT"] = function(msg)
    local raw = strtrim(msg or "")
    local cmd, rest = raw:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    local db = GetDB()

    if cmd == "" or cmd == "toggle" then
        ToggleNightlight()
        return
    elseif cmd == "debug" then
        local sub = (rest or ""):lower():match("^(%S*)")
        if sub == "off" or sub == "disable" then
            db.debugEnabled = false
            NotifyOptionsChange()
            print("|cff00ccff[Nightlight]|r Debug mode disabled. Testing button hidden.")
            if NightlightApp.debugHandler and NightlightApp.debugHandler.Execute then
                NightlightApp.debugHandler.Execute("hide")
            end
            return
        elseif sub == "on" or sub == "enable" then
            db.debugEnabled = true
            NotifyOptionsChange()
            print("|cff00ccff[Nightlight]|r Debug mode enabled.")
            if NightlightApp.debugHandler and NightlightApp.debugHandler.Execute then
                NightlightApp.debugHandler.Execute("show")
            else
                print("|cff00ccff[Nightlight]|r The testing panel is packaged separately in the |cffffd100TimelessForever_nightlight_Debug|r addon.")
                print("  Enable the addon in your WoW AddOns list to access the interactive debug window.")
            end
            return
        end

        if NightlightApp.debugHandler and NightlightApp.debugHandler.Execute then
            db.debugEnabled = true
            NotifyOptionsChange()
            NightlightApp.debugHandler.Execute(rest)
        else
            print("|cff00ccff[Nightlight]|r The testing panel is packaged separately in the |cffffd100TimelessForever_nightlight_Debug|r addon.")
            print("  Enable the addon to access the interactive debug window and /nightlight debug commands.")
        end
        return
    elseif cmd == "stealth" then
        db.stealthAutoExtinguish = not db.stealthAutoExtinguish
        HandleStealthUpdate()
        NotifyOptionsChange()
        print(string.format("|cff00ccff[Nightlight]|r Stealth Auto-Extinguish is now %s", db.stealthAutoExtinguish and "|cff00ff00ENABLED|r" or "|cffff3333DISABLED|r"))
        return
    elseif cmd == "bloom" or cmd == "core" then
        local pct = tonumber(rest)
        if pct then
            if pct > 1.0 then pct = pct / 100.0 end
            pct = math.max(0.0, math.min(1.0, pct))
            db.coreBloom = pct
            db.coreAlpha = pct
            UpdateNightlightState()
            NotifyOptionsChange()
            print(string.format("|cff00ccff[Nightlight]|r Center bloom hotspot set to %d%%.", math.floor(pct * 100)))
        else
            local cur = db.coreBloom
            if cur == nil then cur = 0.20 end
            print(string.format("|cff00ccff[Nightlight]|r Current center bloom: %d%%. Usage: /nightlight bloom <0-100>", math.floor(cur * 100)))
        end
        return
    elseif cmd == "config" or cmd == "options" or cmd == "opt" or cmd == "settings" then
        local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
        if suite and suite.OpenSettings then
            suite:OpenSettings("nightlight")
            return
        end
    elseif cmd == "reset" then
        RestoreIconPosition()
        UpdateNightlightState()
        print("|cff00ccff[Nightlight]|r Position reset.")
        return
    end

    print("|cff00ccff===== Nightlight =====|r")
    print("  |cffffd100/nightlight|r - Toggle light ON / OFF")
    print("  |cffffd100/nightlight bloom <0-100>|r - Adjust center core bloom / hotspot")
    print("  |cffffd100/nightlight stealth|r - Toggle Stealth Auto-Extinguish")
    print("  |cffffd100/nightlight config|r - Open settings hub")
    print("  |cffffd100/nightlight reset|r - Reset icon position")
    if NightlightApp.debugHandler then
        print("  |cffffd100/nightlight debug|r - Open testing panel & class simulator")
    end
end

-- =========================================================================
-- TimelessForever_Barber: Dedicated Barber Shop Fix & UI Scaling Suite
-- =========================================================================

local addonName, addonTable = ...
local TimelessBarber = CreateFrame("Frame")
local ICON = "|TInterface\\Icons\\INV_Misc_Scissors_01:16:16:0:0|t "
_G.TimelessForever_BarberLoaded = true

-- =========================================================================
-- Client Compatibility Polyfills
-- =========================================================================

-- In WoW: Forever & beta clients, opening the barber shop can attempt to index
-- the non-existent CharacterCreateFrame, throwing a Lua error that disables
-- the Accept and Reset buttons. This safe dummy prevents the error entirely.
if not _G.CharacterCreateFrame then
    local dummy = CreateFrame("Frame", "CharacterCreateFrame", UIParent)
    dummy:Hide()
    _G.CharacterCreateFrame = dummy
end

-- =========================================================================
-- Database & Settings
-- =========================================================================

local defaultSettings = {
    scale = 0.75,              -- Default 75% scale (clean & comfortable on high-res)
    enableWheelScaling = true, -- Allow Ctrl + Mouse Wheel to dynamically resize
}

TimelessForever_BarberDB = TimelessForever_BarberDB or TimelessBarberDB or ForeverBarberDB or { settings = {} }
TimelessBarberDB = TimelessForever_BarberDB
ForeverBarberDB = TimelessBarberDB

local function InitDB()
    TimelessBarberDB = TimelessBarberDB or {}
    TimelessBarberDB.settings = TimelessBarberDB.settings or {}

    for k, v in pairs(defaultSettings) do
        if TimelessBarberDB.settings[k] == nil then
            TimelessBarberDB.settings[k] = v
        end
    end
end

-- =========================================================================
-- Barber Shop Core Layout & Scaling Engine
-- =========================================================================

local function ApplyBarberLayout(customScale)
    local bsf = _G["BarberShopFrame"]
    if not bsf then return end

    InitDB()
    local scale = customScale or (TimelessBarberDB and TimelessBarberDB.settings and TimelessBarberDB.settings.scale) or 0.75
    scale = math.max(0.40, math.min(1.20, scale))

    if TimelessBarberDB and TimelessBarberDB.settings then
        TimelessBarberDB.settings.scale = scale
    end

    -- Ensure the frame is locked from dragging so Left-Click rotates the 3D model
    pcall(function() bsf:SetMovable(false) end)
    pcall(function() bsf:RegisterForDrag() end)
    pcall(function() bsf:SetUserPlaced(false) end)

    -- Explicitly set size to match UIParent screen dimensions
    -- This guarantees that bottom, top, and corner anchors for buttons stay intact
    local w, h = UIParent:GetSize()
    if w and h and w > 0 and h > 0 then
        bsf:SetSize(w, h)
    end

    -- Anchor to screen center so scaling shrinks or enlarges symmetrically
    bsf:ClearAllPoints()
    bsf:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bsf:SetScale(scale)

    bsf._timelessBarberConfigured = true
end

local function SetupBarberHooks()
    local bsf = _G["BarberShopFrame"]
    if not bsf or bsf._timelessBarberHooked then return end

    -- OnShow: instantly apply centered scaling
    bsf:HookScript("OnShow", function(self)
        ApplyBarberLayout()
        C_Timer.After(0.05, function()
            ApplyBarberLayout()
        end)
    end)

    -- Ctrl + MouseWheel: dynamically adjust scale while in the chair
    bsf:EnableMouseWheel(true)
    bsf:HookScript("OnMouseWheel", function(self, delta)
        if IsControlKeyDown() and (TimelessBarberDB.settings.enableWheelScaling ~= false) then
            local cur = self:GetScale() or 0.75
            local newScale = cur + (delta * 0.05)
            newScale = math.max(0.40, math.min(1.20, newScale))
            ApplyBarberLayout(newScale)
            print(ICON .. "|cff00ccff[Barber]|r UI Scale: |cffffd100" .. math.floor(newScale * 100 + 0.5) .. "%|r")
        end
    end)

    bsf._timelessBarberHooked = true
    if bsf:IsShown() then
        ApplyBarberLayout()
    end
end

-- =========================================================================
-- Event Lifecycle
-- =========================================================================

TimelessBarber:RegisterEvent("PLAYER_ENTERING_WORLD")
TimelessBarber:RegisterEvent("ADDON_LOADED")
TimelessBarber:RegisterEvent("VARIABLES_LOADED")

TimelessBarber:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName or arg1 == "TimelessForever_Barber" then
            InitDB()
            SetupBarberHooks()
        elseif arg1 == "Blizzard_BarbershopUI" then
            SetupBarberHooks()
            ApplyBarberLayout()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED" then
        InitDB()
        SetupBarberHooks()
        C_Timer.After(0.2, SetupBarberHooks)
        C_Timer.After(1.0, SetupBarberHooks)
    end
end)

-- =========================================================================
-- Slash Commands
-- =========================================================================

SLASH_TIMELESSBARBER1 = "/barber"
SLASH_TIMELESSBARBER2 = "/tfbarber"
SLASH_TIMELESSBARBER3 = "/barberfix"

SlashCmdList["TIMELESSBARBER"] = function(msg)
    local arg = string.lower(string.trim(msg or ""))

    if arg == "reset" then
        ApplyBarberLayout(0.75)
        print(ICON .. "|cff00ccff[Barber]|r Reset to default |cffffd10075%|r scale centered.")
        return
    end

    -- Check if user provided a numeric scale (e.g. "/barber 70" or "/barber 0.7")
    local num = tonumber(arg)
    if not num and arg:find("scale") then
        local part = arg:match("scale%s+(%S+)")
        num = tonumber(part)
    end

    if num then
        if num > 2 then num = num / 100 end -- converts 70 -> 0.70
        ApplyBarberLayout(num)
        print(ICON .. "|cff00ccff[Barber]|r Scale set to: |cffffd100" .. math.floor(num * 100 + 0.5) .. "%|r")
    else
        ApplyBarberLayout()
        local cur = (TimelessBarberDB and TimelessBarberDB.settings and TimelessBarberDB.settings.scale) or 0.75
        print(ICON .. "|cff00ccff[Barber]|r Centered at |cffffd100" .. math.floor(cur * 100 + 0.5) .. "%|r scale.")
        print("  |cffffffff/barber [50-100]|r - Set exact scale percentage (e.g. |cffffd100/barber 65|r)")
        print("  |cffffffffHold Ctrl + Scroll Wheel|r - Smoothly resize UI in the chair")
        print("  |cffffffff/barberaccept|r - Direct shortcut to apply changes")
        print("  |cffffffff/barber reset|r - Reset to 75% default")
    end
end

-- Direct Accept / Confirm command
SLASH_TIMELESSBARBERACCEPT1 = "/barberaccept"
SLASH_TIMELESSBARBERACCEPT2 = "/acceptbarber"

SlashCmdList["TIMELESSBARBERACCEPT"] = function()
    local accepted = false
    if C_BarberShop and C_BarberShop.ApplyCustomizationChoices then
        accepted = C_BarberShop.ApplyCustomizationChoices()
    elseif BarberShopFrameOkayButton and BarberShopFrameOkayButton.Click then
        BarberShopFrameOkayButton:Click()
        accepted = true
    elseif BarberShopFrame and BarberShopFrame.AcceptButton and BarberShopFrame.AcceptButton.Click then
        BarberShopFrame.AcceptButton:Click()
        accepted = true
    end

    if accepted then
        print(ICON .. "|cff00ccff[Barber]|r Barber shop customization applied!")
    else
        print(ICON .. "|cffffd100[Barber]|r No pending barbershop changes or button not found.")
    end
end

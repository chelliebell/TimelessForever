local addonName, addon = ...

-- =========================================================================
-- TimelessForever_Buffs: Core, Keybinds, Minimap Button & Slash Commands
-- =========================================================================

local ICON_PATH = "Interface\\AddOns\\TimelessForever_Buffs\\Media\\Icon.tga"

-- Keybinding Labels in Blizzard Keybindings UI
_G["BINDING_HEADER_BUFFWHEEL"] = "TimelessForever Buffs"
_G["BINDING_NAME_BUFFWHEEL_OPEN"] = "Open / Hold Buff Wheel"
_G["BINDING_NAME_BUFFWHEEL_SETTINGS"] = "Open Buff Wheel Settings"

-- Global Keybind Handlers called by Bindings.xml
function BuffWheel_OnKeyDown()
    addon.OnKeyDown()
end
_G["BuffWheel_OnKeyDown"] = BuffWheel_OnKeyDown

function BuffWheel_OnKeyUp()
    addon.OnKeyUp()
end
_G["BuffWheel_OnKeyUp"] = BuffWheel_OnKeyUp

function BuffWheel_Toggle()
    addon.ToggleWheel()
end
_G["BuffWheel_Toggle"] = BuffWheel_Toggle

function BuffWheel_OpenSettings()
    addon.OpenSettings()
end
_G["BuffWheel_OpenSettings"] = BuffWheel_OpenSettings

-- =========================================================================
-- Minimap Launcher Button
-- =========================================================================
local minimapBtn = nil

function addon.UpdateMinimapButton()
    local db = addon.GetDB()
    if not minimapBtn then return end

    if db.showMinimapButton == false then
        minimapBtn:Hide()
        return
    else
        minimapBtn:Show()
    end

    local angle = db.minimapAngle or 210
    local rad = math.rad(angle)
    local radius = 80
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius

    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    if minimapBtn or not Minimap then return end

    minimapBtn = CreateFrame("Button", "TimelessForever_BuffWheelMinimapButton", Minimap)
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
    icon:SetTexture(ICON_PATH)
    icon:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 7, -6)
    if icon.SetMask then
        pcall(function() icon:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask") end)
    end

    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)

    minimapBtn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            if not mx or not scale or scale == 0 then return end
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if angle < 0 then angle = angle + 360 end
            addon.GetDB().minimapAngle = angle
            addon.UpdateMinimapButton()
        end)
    end)

    minimapBtn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    minimapBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            addon.OpenSettings()
        else
            addon.ToggleWheel()
        end
    end)

    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ccffTimelessForever|r |cffffffffBuffs|r", 1, 1, 1)
        local key = GetBindingKey and GetBindingKey("BUFFWHEEL_OPEN")
        if key then
            GameTooltip:AddLine("Keybind: |cff00ddff" .. key .. "|r", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("Keybind: |cffff6666Not Bound|r (Right-click to set)", 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Buff Wheel", 0.2, 1, 0.2)
        GameTooltip:AddLine("|cffffffffRight-Click:|r Customize Slices & Keybind", 0.2, 1, 0.2)
        GameTooltip:AddLine("|cffffffffDrag:|r Move Minimap Icon", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    minimapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if _G["ForeverMap_RegisterMinimapButton"] and ForeverMapDB and ForeverMapDB.collectIcons then
        pcall(_G["ForeverMap_RegisterMinimapButton"], minimapBtn)
    end

    addon.UpdateMinimapButton()
end

-- =========================================================================
-- Slash Commands (/buffs, /buffwheel, /bw, /tbuffs)
-- =========================================================================
SLASH_BUFFWHEEL1 = "/buffs"
SLASH_BUFFWHEEL2 = "/buffwheel"
SLASH_BUFFWHEEL3 = "/bw"
SLASH_BUFFWHEEL4 = "/tbuffs"

SlashCmdList["BUFFWHEEL"] = function(msg)
    local cmd = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if cmd == "config" or cmd == "settings" or cmd == "options" or cmd == "opt" then
        addon.OpenSettings()
    elseif cmd == "bind" or cmd == "key" or cmd == "keybind" then
        addon.OpenKeybindCapturePopup()
    elseif cmd == "reset" then
        addon.ResetFavorites()
        addon.RefreshWheelLayout()
        print("|cff00ccff[TimelessForever Buffs]|r Favorites wheel reset to class defaults.")
    elseif cmd == "minimap" or cmd == "icon" then
        local db = addon.GetDB()
        db.showMinimapButton = not db.showMinimapButton
        addon.UpdateMinimapButton()
        print("|cff00ccff[TimelessForever Buffs]|r Minimap button " .. (db.showMinimapButton and "|cff00ff00shown|r." or "|cffff5555hidden|r."))
    elseif cmd == "help" then
        print("|cff00ccff[TimelessForever Buffs]|r Commands:")
        print("  |cffffd100/buffs|r or |cffffd100/bw|r - Toggle the Buff Wheel")
        print("  |cffffd100/buffs bind|r - Bind a key or mouse button to the Buff Wheel")
        print("  |cffffd100/buffs settings|r - Open Buffs Tab in TimelessForever Hub")
        print("  |cffffd100/buffs reset|r - Reset Favorites slices to class defaults")
    else
        addon.ToggleWheel()
    end
end

-- =========================================================================
-- Startup & Event Handlers
-- =========================================================================
local loader = CreateFrame("Frame")
local function SafeRegister(evt)
    pcall(function() loader:RegisterEvent(evt) end)
end

SafeRegister("ADDON_LOADED")
SafeRegister("PLAYER_LOGIN")
SafeRegister("SPELLS_CHANGED")
SafeRegister("UNIT_AURA")
SafeRegister("PLAYER_REGEN_DISABLED")
SafeRegister("PLAYER_REGEN_ENABLED")

loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        addon.GetDB()
        addon.InitializeSettings()
    elseif event == "PLAYER_LOGIN" then
        local _, pClass = UnitClass("player")
        if pClass then addon.playerClass = pClass end
        addon.ScanSpellbook()
        CreateMinimapButton()
        addon.RegisterWithSuiteHub()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function()
                addon.RegisterWithSuiteHub()
            end)
        end
    elseif event == "SPELLS_CHANGED" then
        addon.ScanSpellbook()
        if addon.RefreshWheelLayout then
            addon.RefreshWheelLayout()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        addon.CloseWheel()
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.CloseWheel()
    end
end)

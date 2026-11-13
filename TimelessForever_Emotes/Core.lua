local addonName, addon = ...

-- =========================================================================
-- TimelessForever_Emotes Core, Keybind Globals, Minimap Button & Slash Commands
-- =========================================================================

local ICON_PATH = "Interface\\AddOns\\TimelessForever_Emotes\\Media\\Icon.tga"

-- Keybinding Labels in Blizzard Keybindings UI
_G["BINDING_HEADER_EMOTEWHEEL"] = "TimelessForever Emotes"
_G["BINDING_NAME_EMOTEWHEEL_OPEN"] = "Open / Hold Emote Wheel"
_G["BINDING_NAME_EMOTEWHEEL_SETTINGS"] = "Open Emote Wheel Settings"

-- Global Keybind Handlers called by Bindings.xml
function EmoteWheel_OnKeyDown()
    addon.OnKeyDown()
end
_G["EmoteWheel_OnKeyDown"] = EmoteWheel_OnKeyDown

function EmoteWheel_OnKeyUp()
    addon.OnKeyUp()
end
_G["EmoteWheel_OnKeyUp"] = EmoteWheel_OnKeyUp

function EmoteWheel_OpenSettings()
    addon.OpenSettings()
end
_G["EmoteWheel_OpenSettings"] = EmoteWheel_OpenSettings

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

    local angle = db.minimapAngle or 205
    local rad = math.rad(angle)
    local radius = 80
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius

    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    if minimapBtn or not Minimap then return end

    minimapBtn = CreateFrame("Button", "EmoteWheelMinimapButton", Minimap)
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
        GameTooltip:AddLine("|cff00ccffTimelessForever|r |cffffffffEmotes|r", 1, 1, 1)
        local key = GetBindingKey and GetBindingKey("EMOTEWHEEL_OPEN")
        if key then
            GameTooltip:AddLine("Keybind: |cff00ddff" .. key .. "|r", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("Keybind: |cffff6666Not Bound|r (Right-click to set)", 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Emote Wheel", 0.2, 1, 0.2)
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
-- Slash Commands (/emotewheel, /ew, /emotes, /tfemotes)
-- =========================================================================
SLASH_EMOTEWHEEL1 = "/emotewheel"
SLASH_EMOTEWHEEL2 = "/ew"
SLASH_EMOTEWHEEL3 = "/emotes"
SLASH_EMOTEWHEEL4 = "/tfemotes"
SlashCmdList["EMOTEWHEEL"] = function(msg)
    local cmd = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if cmd == "config" or cmd == "settings" or cmd == "options" or cmd == "opt" then
        addon.OpenSettings()
    elseif cmd == "bind" or cmd == "key" or cmd == "keybind" then
        addon.OpenKeybindCapturePopup()
    elseif cmd == "reset" then
        addon.ResetFavorites()
        addon.RefreshSettingsUI()
        addon.RefreshWheelLayout()
        print("|cff00ccff[TimelessForever Emotes]|r Favorites wheel reset to default poses & emotes.")
    elseif cmd == "minimap" or cmd == "icon" then
        local db = addon.GetDB()
        db.showMinimapButton = not db.showMinimapButton
        addon.UpdateMinimapButton()
        print("|cff00ccff[TimelessForever Emotes]|r Minimap button " .. (db.showMinimapButton and "|cff00ff00shown|r." or "|cffff5555hidden|r."))
    elseif cmd == "help" then
        print("|cff00ccff[TimelessForever Emotes]|r Commands:")
        print("  |cffffd100/ew|r or |cffffd100/emotes|r - Toggle the Emote Wheel")
        print("  |cffffd100/ew bind|r - Bind a key or mouse button to the Emote Wheel")
        print("  |cffffd100/ew settings|r (or |cffffd100/tf emotes|r) - Open Emotes Tab in TimelessForever Hub")
        print("  |cffffd100/ew reset|r - Reset Favorites slices to defaults")
    else
        addon.ToggleWheel()
    end
end

-- =========================================================================
-- Startup Initialization
-- =========================================================================
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        addon.GetDB()
        addon.InitializeSettings()
    elseif event == "PLAYER_LOGIN" then
        CreateMinimapButton()
        addon.RegisterWithSuiteHub()
        C_Timer.After(0.5, function()
            addon.RegisterWithSuiteHub()
        end)
    end
end)

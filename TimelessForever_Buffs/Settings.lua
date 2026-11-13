local _, addon = ...

-- =========================================================================
-- TimelessForever_Buffs: Settings & Suite Hub Integration
-- =========================================================================

local settingsFrame = nil
local slotRows = {}
local pickerFrame = nil
local activeSlotToEdit = nil

local MODE_LABELS = {
    ["TOGGLE"] = "Press Keybind to Toggle Open, Left-Click to Cast (Recommended)",
    ["HOLD"]   = "Hold Keybind to Keep Open, Left-Click to Cast, Release to Close",
}

local function NotifySuiteChange()
    local LibStub = _G.LibStub
    if LibStub then
        local reg = LibStub("AceConfigRegistry-3.0", true)
        if reg then
            pcall(reg.NotifyChange, reg, "TimelessForever")
            pcall(reg.NotifyChange, reg, "Timeless")
        end
    end
end

local function GetCurrentKeybindText()
    if type(GetBindingKey) == "function" then
        local key1, key2 = GetBindingKey("BUFFWHEEL_OPEN")
        if key1 and key2 then
            return key1 .. " / " .. key2
        elseif key1 then
            return key1
        end
    end
    return nil
end

local function SetWheelKeybind(newKey)
    if InCombatLockdown() then
        print("|cff00ccff[TimelessForever Buffs]|r Cannot change keybindings while in combat.")
        return false
    end
    local old1, old2 = GetBindingKey("BUFFWHEEL_OPEN")
    if old1 then SetBinding(old1, nil) end
    if old2 then SetBinding(old2, nil) end
    if newKey and newKey ~= "" and newKey ~= "ESCAPE" then
        SetBinding(newKey, "BUFFWHEEL_OPEN")
    end
    if SaveBindings and GetCurrentBindingSet then
        pcall(SaveBindings, GetCurrentBindingSet())
    end
    if addon.RefreshSettingsUI then
        addon.RefreshSettingsUI()
    end
    NotifySuiteChange()
    return true
end

-- =========================================================================
-- Interactive Keybind Capture Popup
-- =========================================================================
local keyCapturePopup = nil

function addon.OpenKeybindCapturePopup()
    if InCombatLockdown() then
        print("|cff00ccff[TimelessForever Buffs]|r Cannot change keybindings while in combat.")
        return
    end
    if not keyCapturePopup then
        keyCapturePopup = CreateFrame("Button", "TF_BuffsKeyCapturePopup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        keyCapturePopup:SetSize(380, 130)
        keyCapturePopup:SetPoint("CENTER")
        keyCapturePopup:SetFrameStrata("FULLSCREEN_DIALOG")
        keyCapturePopup:SetFrameLevel(200)
        keyCapturePopup:EnableMouse(true)
        keyCapturePopup:EnableKeyboard(true)
        keyCapturePopup:RegisterForClicks("AnyUp")

        local bg = keyCapturePopup:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.06, 0.08, 0.12, 0.96)

        local border = keyCapturePopup:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", 2, -2)
        border:SetColorTexture(0.0, 0.8, 1.0, 0.85)

        local title = keyCapturePopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -22)
        title:SetText("|cff00ccffBind Buff Wheel Key|r")

        local prompt = keyCapturePopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        prompt:SetPoint("TOP", title, "BOTTOM", 0, -14)
        prompt:SetText("Press any key or mouse button now...\n|cff888888(Press ESC to cancel)|r")

        local clearBtn = CreateFrame("Button", nil, keyCapturePopup, "UIPanelButtonTemplate")
        clearBtn:SetSize(110, 24)
        clearBtn:SetPoint("BOTTOM", 0, 14)
        clearBtn:SetText("Clear Binding")
        clearBtn:SetScript("OnClick", function()
            SetWheelKeybind(nil)
            keyCapturePopup:Hide()
        end)

        keyCapturePopup:SetScript("OnKeyDown", function(self, key)
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" or key == "UNKNOWN" then
                return
            end
            if key == "ESCAPE" then
                self:Hide()
                return
            end
            local prefix = ""
            if IsAltKeyDown() then prefix = prefix .. "ALT-" end
            if IsControlKeyDown() then prefix = prefix .. "CTRL-" end
            if IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
            SetWheelKeybind(prefix .. key)
            self:Hide()
        end)

        keyCapturePopup:SetScript("OnClick", function(self, button)
            if button == "LeftButton" or button == "RightButton" then
                return
            end
            local bindName = button
            if button == "MiddleButton" then bindName = "BUTTON3" end
            SetWheelKeybind(bindName)
            self:Hide()
        end)
    end
    keyCapturePopup:Show()
end

-- =========================================================================
-- Helper for ScrollsPicker Settings Integration
-- =========================================================================
local function GetScrollsDB()
    if type(ScrollsPickerDB) ~= "table" then
        ScrollsPickerDB = {}
    end
    return ScrollsPickerDB
end

-- =========================================================================
-- Sub-Tab 1: Radial Buff Wheel Options
-- =========================================================================
local function BuildWheelOptions()
    local wheelArgs = {
        header = {
            name = "|TInterface\\AddOns\\TimelessForever_Buffs\\Media\\Icon:14:14:0:0|t |cff00ccffRadial Buff Wheel|r",
            type = "header",
            order = 1,
        },
        desc = {
            name = "Radial menu auto-detecting your class buffs, armors, seals, blessings, shouts, and weapon imbues with active duration tracking.\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },
        -- Group 1: Actions & Keybind
        actionsGroup = {
            name = "Quick Actions & Keybind",
            type = "group",
            inline = true,
            order = 10,
            args = {
                openWheelBtn = {
                    name = "Open Buff Wheel Now",
                    desc = "Pull up the Buff Wheel on screen right now to test it.",
                    type = "execute",
                    order = 1,
                    width = "normal",
                    func = function()
                        addon.OpenWheel()
                    end,
                },
                bindKeyBtn = {
                    name = function()
                        local k = GetCurrentKeybindText()
                        return k and ("Keybind: " .. k .. " (Click to Change)") or "Bind Key (Currently Unbound)"
                    end,
                    desc = "Click to press any key or mouse button to bind to the Buff Wheel.",
                    type = "execute",
                    width = "double",
                    order = 2,
                    func = function()
                        addon.OpenKeybindCapturePopup()
                    end,
                },
            },
        },
        -- Group 2: Wheel Behavior & Controls
        behaviorGroup = {
            name = "Wheel Behavior & Controls",
            type = "group",
            inline = true,
            order = 20,
            args = {
                mode = {
                    name = "Keybind Interaction Mode",
                    desc = "Choose how the keybind interacts with the Buff Wheel.",
                    type = "select",
                    width = "full",
                    order = 1,
                    values = MODE_LABELS,
                    get = function() return addon.GetDB().mode or "TOGGLE" end,
                    set = function(_, val)
                        addon.GetDB().mode = val
                        addon.RefreshSettingsUI()
                    end,
                },
                sliceCount = {
                    name = "Favorites Slices (4 – 12)",
                    desc = "Number of buff slices displayed on the Favorites wheel page.",
                    type = "range",
                    order = 2,
                    width = "normal",
                    min = 4,
                    max = 12,
                    step = 1,
                    get = function() return addon.GetDB().sliceCount or 8 end,
                    set = function(_, val)
                        addon.GetDB().sliceCount = val
                        addon.RefreshWheelLayout()
                        addon.RefreshSettingsUI()
                        NotifySuiteChange()
                    end,
                },
                scale = {
                    name = "Wheel Scale",
                    desc = "Adjust the overall size of the Buff Wheel.",
                    type = "range",
                    order = 3,
                    width = "normal",
                    min = 0.70,
                    max = 1.50,
                    step = 0.05,
                    isPercent = true,
                    get = function() return addon.GetDB().scale or 1.0 end,
                    set = function(_, val)
                        addon.GetDB().scale = val
                        addon.RefreshWheelLayout()
                        addon.RefreshSettingsUI()
                    end,
                },
                spawnAtCursor = {
                    name = "Spawn at Cursor",
                    desc = "When checked, the wheel opens centered on your mouse. When unchecked, it opens in screen center.",
                    type = "toggle",
                    width = "normal",
                    order = 4,
                    get = function() return addon.GetDB().spawnAtCursor ~= false end,
                    set = function(_, val)
                        addon.GetDB().spawnAtCursor = val
                        addon.RefreshSettingsUI()
                    end,
                },
                closeOnCast = {
                    name = "Close After Casting",
                    desc = "Automatically close the Buff Wheel after casting a buff.",
                    type = "toggle",
                    width = "normal",
                    order = 5,
                    get = function() return addon.GetDB().closeOnCast ~= false end,
                    set = function(_, val)
                        addon.GetDB().closeOnCast = val
                        addon.RefreshSettingsUI()
                    end,
                },
                soundEffects = {
                    name = "Audio Ticks",
                    desc = "Play subtle UI audio ticks when hovering slices or casting buffs.",
                    type = "toggle",
                    width = "normal",
                    order = 6,
                    get = function() return addon.GetDB().soundEffects ~= false end,
                    set = function(_, val)
                        addon.GetDB().soundEffects = val
                        addon.RefreshSettingsUI()
                    end,
                },
                showMinimapButton = {
                    name = "Dedicated Minimap Button",
                    desc = "Show or hide a standalone minimap icon for the Buff Wheel.",
                    type = "toggle",
                    width = "normal",
                    order = 7,
                    get = function() return addon.GetDB().showMinimapButton == true end,
                    set = function(_, val)
                        addon.GetDB().showMinimapButton = val
                        if addon.UpdateMinimapButton then addon.UpdateMinimapButton() end
                        addon.RefreshSettingsUI()
                    end,
                },
            },
        },
        -- Group 3: Favorites Slices
        favoritesGroup = {
            name = "Favorites Wheel Slices (Slots 1 – 12)",
            type = "group",
            inline = true,
            order = 30,
            args = {
                favDesc = {
                    name = "Assign any buff, armor, seal, or weapon imbue to your Favorites slices. Slices beyond your chosen slice count are disabled.\n",
                    type = "description",
                    order = 1,
                },
                resetFavs = {
                    name = "Reset Favorites to Class Defaults",
                    desc = "Restores the default buffs for your class.",
                    type = "execute",
                    width = "normal",
                    order = 2,
                    func = function()
                        addon.ResetFavorites()
                        addon.RefreshWheelLayout()
                        addon.RefreshSettingsUI()
                        NotifySuiteChange()
                    end,
                },
            },
        },
    }

    -- Add 12 compact slice dropdowns (2-column grid layout)
    for i = 1, 12 do
        wheelArgs.favoritesGroup.args["slot" .. i] = {
            name = "Slice #" .. i,
            desc = "Choose the Buff for Slice #" .. i .. " on your Favorites wheel.",
            type = "select",
            width = "normal",
            order = 10 + i,
            values = addon.BUFF_DROPDOWN_VALUES,
            disabled = function() return i > (addon.GetDB().sliceCount or 8) end,
            get = function()
                return addon.GetDB().favorites[i] or (addon.BUFF_CATALOG[1] and addon.BUFF_CATALOG[1].id)
            end,
            set = function(_, val)
                addon.GetDB().favorites[i] = val
                addon.RefreshWheelLayout()
                addon.RefreshSettingsUI()
            end,
        }
    end

    return wheelArgs
end

-- =========================================================================
-- Sub-Tab 2: Stat Scrolls (ScrollsPicker) Options
-- =========================================================================
local function BuildScrollsOptions()
    return {
        header = {
            name = "|TInterface\\Icons\\INV_Scroll_02:14:14:0:0|t |cff00e5ffScrollsPicker|r (Classic Stat Scrolls)",
            type = "header",
            order = 1,
        },
        desc = {
            name = "Scans your bags for all stat scrolls (Agility, Strength, Stamina, Intellect, Spirit, Protection I–IV), displays remaining counts, missing status, and enables 1-click usage.\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },
        -- Group 1: Actions
        actionsGroup = {
            name = "Quick Actions",
            type = "group",
            inline = true,
            order = 10,
            args = {
                openScrollsBtn = {
                    name = "Open ScrollsPicker UI",
                    desc = "Toggle the ScrollsPicker window on screen right now.",
                    type = "execute",
                    width = "normal",
                    order = 1,
                    func = function()
                        if _G.ScrollsPicker and _G.ScrollsPicker.ToggleUI then
                            _G.ScrollsPicker.ToggleUI()
                        elseif SlashCmdList and SlashCmdList["SCROLLSPICKER"] then
                            SlashCmdList["SCROLLSPICKER"]("")
                        end
                    end,
                },
                scanBagsBtn = {
                    name = "Re-Scan Bags & Buffs",
                    desc = "Forces an immediate inventory and aura scan to refresh all scroll counts.",
                    type = "execute",
                    width = "normal",
                    order = 2,
                    func = function()
                        if _G.ScrollsPicker and _G.ScrollsPicker.UpdateAll then
                            _G.ScrollsPicker.UpdateAll()
                            if _G.ScrollsPicker.CheckAutoVisibility then
                                _G.ScrollsPicker.CheckAutoVisibility()
                            end
                        end
                        print("|cff00e5ff[ScrollsPicker]|r Bags and player buffs re-scanned.")
                    end,
                },
                resetPosBtn = {
                    name = "Reset Window Position",
                    desc = "Resets the ScrollsPicker window position back to screen center.",
                    type = "execute",
                    width = "normal",
                    order = 3,
                    func = function()
                        local sdb = GetScrollsDB()
                        sdb.point = "CENTER"
                        sdb.relativePoint = "CENTER"
                        sdb.xOfs = 0
                        sdb.yOfs = 20
                        local frame = _G.ScrollsPickerFrame
                        if frame then
                            frame:ClearAllPoints()
                            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
                        end
                        print("|cff00e5ff[ScrollsPicker]|r Window position reset to center.")
                    end,
                },
            },
        },
        -- Group 2: Smart Automation
        automationGroup = {
            name = "Smart Automation (Auto-Popup & Auto-Hide)",
            type = "group",
            inline = true,
            order = 20,
            args = {
                autoShowMissing = {
                    name = "Auto-Show UI When Buff Missing",
                    desc = "Automatically pops up the ScrollsPicker window if you carry a scroll in your bags whose buff is NOT currently active on you.",
                    type = "toggle",
                    width = "full",
                    order = 1,
                    get = function() return GetScrollsDB().autoShowMissingBuffs ~= false end,
                    set = function(_, val)
                        GetScrollsDB().autoShowMissingBuffs = val
                        if _G.ScrollsPicker and _G.ScrollsPicker.CheckAutoVisibility then
                            _G.ScrollsPicker.CheckAutoVisibility()
                        end
                    end,
                },
                autoHideBuffed = {
                    name = "Auto-Hide UI When All Buffs Active",
                    desc = "Automatically hides the ScrollsPicker window as soon as all scrolls in your bags have their buffs active on you.",
                    type = "toggle",
                    width = "full",
                    order = 2,
                    get = function() return GetScrollsDB().autoHideWhenBuffed ~= false end,
                    set = function(_, val)
                        GetScrollsDB().autoHideWhenBuffed = val
                        if _G.ScrollsPicker and _G.ScrollsPicker.CheckAutoVisibility then
                            _G.ScrollsPicker.CheckAutoVisibility()
                        end
                    end,
                },
                hideActiveBuffs = {
                    name = "Hide Already Buffed Stats from List",
                    desc = "Hides individual stat rows that are already active on you so the picker only shows scrolls you still need to cast.",
                    type = "toggle",
                    width = "full",
                    order = 3,
                    get = function() return GetScrollsDB().hideActiveBuffs == true end,
                    set = function(_, val)
                        GetScrollsDB().hideActiveBuffs = val
                        if _G.ScrollsPicker and _G.ScrollsPicker.UpdateAll then
                            _G.ScrollsPicker.UpdateAll()
                        end
                    end,
                },
            },
        },
        -- Group 3: Appearance & Display
        displayGroup = {
            name = "Display & Appearance",
            type = "group",
            inline = true,
            order = 30,
            args = {
                hideMissing = {
                    name = "Hide Missing Ranks",
                    desc = "When enabled, scroll ranks that you don't have in your bags are completely hidden so only available scrolls are shown side-by-side.",
                    type = "toggle",
                    width = "normal",
                    order = 1,
                    get = function() return GetScrollsDB().hideMissingRanks ~= false end,
                    set = function(_, val)
                        GetScrollsDB().hideMissingRanks = val
                        if _G.ScrollsPicker and _G.ScrollsPicker.UpdateAll then
                            _G.ScrollsPicker.UpdateAll()
                        end
                    end,
                },
                showMinimapButton = {
                    name = "Show Minimap Button",
                    desc = "Show or hide the dedicated ScrollsPicker minimap button.",
                    type = "toggle",
                    width = "normal",
                    order = 2,
                    get = function() return GetScrollsDB().showMinimapButton ~= false end,
                    set = function(_, val)
                        GetScrollsDB().showMinimapButton = val
                        if _G.ScrollsPicker and _G.ScrollsPicker.UpdateMinimapButton then
                            _G.ScrollsPicker.UpdateMinimapButton()
                        end
                    end,
                },
                scale = {
                    name = "ScrollsPicker Window Scale",
                    desc = "Adjust the size of the ScrollsPicker window on screen.",
                    type = "range",
                    width = "normal",
                    order = 3,
                    min = 0.70,
                    max = 1.50,
                    step = 0.05,
                    isPercent = true,
                    get = function() return GetScrollsDB().scale or 1.0 end,
                    set = function(_, val)
                        GetScrollsDB().scale = val
                        local frame = _G.ScrollsPickerFrame
                        if frame then
                            frame:SetScale(val)
                        end
                    end,
                },
            },
        },
    }
end

-- =========================================================================
-- TimelessForever Suite Hub Tab ("Buffs") - Clean Sub-Tabs Structure
-- =========================================================================
local function BuildSuiteTabOptions()
    return {
        wheel = {
            name = "Radial Buff Wheel",
            type = "group",
            order = 1,
            args = BuildWheelOptions(),
        },
        scrolls = {
            name = "Stat Scrolls (ScrollsPicker)",
            type = "group",
            order = 2,
            args = BuildScrollsOptions(),
        },
    }
end

function addon.RegisterWithSuiteHub()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        pcall(function()
            suite:RegisterModuleTab("buffs", "Buffs", 7.5, BuildSuiteTabOptions())
        end)
    end
end

function addon.RefreshSettingsUI()
    local LibStub = _G.LibStub
    if LibStub then
        local reg = LibStub("AceConfigRegistry-3.0", true)
        if reg then
            pcall(reg.NotifyChange, reg, "TimelessForever")
            pcall(reg.NotifyChange, reg, "Timeless")
        end
    end
end

function addon.InitializeSettings()
    addon.RegisterWithSuiteHub()
end

function addon.OpenSettings(subKey)
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.OpenSettings then
        suite:OpenSettings("buffs", subKey or "wheel")
        return
    end
    addon.OpenKeybindCapturePopup()
end

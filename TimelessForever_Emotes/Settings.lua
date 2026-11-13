local _, addon = ...

-- =========================================================================
-- TimelessForever_Emotes Settings & Suite Hub Integration
-- Registers the "Emotes" tab inside TimelessForever Hub AND provides a
-- visual Slice Editor + Keybind Capture modal.
-- =========================================================================

local settingsFrame = nil
local slotRows = {}
local pickerFrame = nil
local activeSlotToEdit = nil

local MODE_LABELS = {
    ["BOTH"]   = "Smart Hybrid (Hold & Release OR Quick-Tap to Toggle)",
    ["HOLD"]   = "Hold Keybind, Hover Slice & Release to Emote",
    ["TOGGLE"] = "Press Keybind to Toggle Open, Left-Click to Emote",
}

local MODE_ORDER = { "BOTH", "HOLD", "TOGGLE" }

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
        local key1, key2 = GetBindingKey("EMOTEWHEEL_OPEN")
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
        print("|cff00ccff[TimelessForever Emotes]|r Cannot change keybindings while in combat.")
        return false
    end
    local old1, old2 = GetBindingKey("EMOTEWHEEL_OPEN")
    if old1 then SetBinding(old1, nil) end
    if old2 then SetBinding(old2, nil) end
    if newKey and newKey ~= "" and newKey ~= "ESCAPE" then
        SetBinding(newKey, "EMOTEWHEEL_OPEN")
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
-- Standalone Interactive Keybind Capture Popup (Triggered from Hub or Editor)
-- =========================================================================
local keyCapturePopup = nil

function addon.OpenKeybindCapturePopup()
    if InCombatLockdown() then
        print("|cff00ccff[TimelessForever Emotes]|r Cannot change keybindings while in combat.")
        return
    end
    if not keyCapturePopup then
        keyCapturePopup = CreateFrame("Button", "TF_EmotesKeyCapturePopup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
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
        title:SetText("|cff00ccffBind Emote Wheel Key|r")

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
-- TimelessForever Suite Hub Tab ("Emotes")
-- =========================================================================
local function BuildSuiteTabOptions()
    local args = {
        header = {
            name = "|TInterface\\AddOns\\TimelessForever_Emotes\\Media\\Icon:14:14:0:0|t |cff00ccffTimelessForever|r Emotes (Radial Emote Wheel)",
            type = "header",
            order = 1,
        },
        desc = {
            name = "Press or hold your Emote Wheel keybind anywhere to pull up an interactive radial wheel with Poses (|cffffd100Sit|r, |cffffd100Lie Down|r, |cffffd100Sleep|r, |cffffd100Stand|r, |cffffd100Kneel|r), Greetings, Dances, Voice Emotes, and Tactical calls.\n",
            type = "description",
            order = 2,
            fontSize = "medium",
        },
        openWheelBtn = {
            name = "Open Emote Wheel Now",
            desc = "Pull up the Emote Wheel on screen right now to test it.",
            type = "execute",
            order = 3,
            func = function()
                addon.OpenWheel()
            end,
        },
        bindKeyBtn = {
            name = function()
                local k = GetCurrentKeybindText()
                return k and ("Keybind: " .. k .. " (Click to Change)") or "Bind Key (Currently Unbound)"
            end,
            desc = "Click to press any key or mouse button to bind to the Emote Wheel.",
            type = "execute",
            width = "double",
            order = 4,
            func = function()
                addon.OpenKeybindCapturePopup()
            end,
        },
        behaviorHeader = {
            name = "Wheel Behavior & Appearance",
            type = "header",
            order = 10,
        },
        mode = {
            name = "Keybind Interaction Mode",
            desc = "Choose how the keybind interacts with the Emote Wheel.",
            type = "select",
            width = "double",
            order = 11,
            values = MODE_LABELS,
            get = function() return addon.GetDB().mode or "BOTH" end,
            set = function(_, val)
                addon.GetDB().mode = val
                addon.RefreshSettingsUI()
            end,
        },
        sliceCount = {
            name = "Favorites Wheel Slice Count",
            desc = "Number of emote slices displayed on the Favorites wheel page (4 to 12).",
            type = "range",
            order = 12,
            min = 4,
            max = 12,
            step = 1,
            get = function() return addon.GetDB().sliceCount or 8 end,
            set = function(_, val)
                addon.GetDB().sliceCount = val
                addon.RefreshWheelLayout()
                addon.RefreshSettingsUI()
            end,
        },
        scale = {
            name = "Wheel Scale",
            desc = "Adjust the overall size of the Emote Wheel.",
            type = "range",
            order = 13,
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
            name = "Spawn Wheel at Mouse Cursor",
            desc = "When enabled, the wheel opens centered on your mouse cursor. When disabled, it opens in the center of your screen.",
            type = "toggle",
            width = "double",
            order = 14,
            get = function() return addon.GetDB().spawnAtCursor ~= false end,
            set = function(_, val)
                addon.GetDB().spawnAtCursor = val
                addon.RefreshSettingsUI()
            end,
        },
        soundEffects = {
            name = "Wheel Hover & Select Sound Effects",
            desc = "Play subtle UI audio ticks when hovering slices or triggering emotes.",
            type = "toggle",
            order = 15,
            get = function() return addon.GetDB().soundEffects ~= false end,
            set = function(_, val)
                addon.GetDB().soundEffects = val
                addon.RefreshSettingsUI()
            end,
        },
        showMinimapButton = {
            name = "Show Dedicated Emotes Minimap Button",
            desc = "Show or hide a dedicated minimap button for Emotes (in addition to the main TimelessForever minimap hub).",
            type = "toggle",
            width = "double",
            order = 16,
            get = function() return addon.GetDB().showMinimapButton == true end,
            set = function(_, val)
                addon.GetDB().showMinimapButton = val
                if addon.UpdateMinimapButton then addon.UpdateMinimapButton() end
                addon.RefreshSettingsUI()
            end,
        },
        favHeader = {
            name = "Customize Favorites Wheel Slices (Slots 1 – 12)",
            type = "header",
            order = 20,
        },
        favDesc = {
            name = "Assign any Pose (|cffffd100Sit|r, |cffffd100Lie Down|r, |cffffd100Sleep|r, |cffffd100Stand|r, |cffffd100Kneel|r) or Emote to each slice on your Favorites wheel:",
            type = "description",
            order = 21,
        },
        resetFavs = {
            name = "Reset Favorites to Default (Sit, Lie Down, Sleep, Dance...)",
            desc = "Restore the default Favorites slices.",
            type = "execute",
            width = "double",
            order = 22,
            func = function()
                addon.ResetFavorites()
                addon.RefreshWheelLayout()
                addon.RefreshSettingsUI()
                NotifySuiteChange()
            end,
        },
    }

    for i = 1, 12 do
        args["slot" .. i] = {
            name = "Slice #" .. i,
            desc = "Choose the Pose or Emote for Slice #" .. i .. " on your Favorites wheel.",
            type = "select",
            width = "double",
            order = 30 + i,
            values = addon.EMOTE_DROPDOWN_VALUES,
            disabled = function() return i > (addon.GetDB().sliceCount or 8) end,
            get = function()
                return addon.GetDB().favorites[i] or addon.DEFAULT_FAVORITES[i] or "SIT"
            end,
            set = function(_, val)
                addon.GetDB().favorites[i] = val
                addon.RefreshWheelLayout()
                addon.RefreshSettingsUI()
            end,
        }
    end

    return args
end

function addon.RegisterWithSuiteHub()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        pcall(function()
            suite:RegisterModuleTab("emotes", "Emotes", 9, BuildSuiteTabOptions())
        end)
    end
end

-- =========================================================================
-- Standalone Visual Slice Editor Fallback
-- =========================================================================
local function OpenEmotePicker(slotIndex)
    activeSlotToEdit = slotIndex

    if not pickerFrame then
        pickerFrame = CreateFrame("Frame", "EmoteWheelCatalogPicker", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        pickerFrame:SetSize(460, 440)
        pickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        pickerFrame:SetFrameLevel(120)
        pickerFrame:EnableMouse(true)
        pickerFrame:SetMovable(true)
        pickerFrame:RegisterForDrag("LeftButton")
        pickerFrame:SetScript("OnDragStart", pickerFrame.StartMoving)
        pickerFrame:SetScript("OnDragStop", pickerFrame.StopMovingOrSizing)
        if pickerFrame.SetBackdrop then
            pickerFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 24,
                insets = { left = 6, right = 6, top = 6, bottom = 6 },
            })
        end

        local bgFallback = pickerFrame:CreateTexture(nil, "BACKGROUND")
        bgFallback:SetAllPoints()
        bgFallback:SetColorTexture(0.08, 0.09, 0.12, 0.96)

        local title = pickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -14)
        title:SetText("Select Emote or Pose for Wheel Slice")
        pickerFrame.Title = title

        local closeBtn = CreateFrame("Button", nil, pickerFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -4, -4)

        local scroll = CreateFrame("ScrollFrame", "EmoteWheelPickerScroll", pickerFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 14, -44)
        scroll:SetPoint("BOTTOMRIGHT", -34, 14)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(400, 100)
        scroll:SetScrollChild(content)
        pickerFrame.Content = content
        pickerFrame.Buttons = {}

        local colWidth = 195
        local rowHeight = 32
        for idx, info in ipairs(addon.EMOTE_CATALOG) do
            local btn = CreateFrame("Button", nil, content)
            btn:SetSize(colWidth, rowHeight - 2)
            local col = (idx - 1) % 2
            local row = math.floor((idx - 1) / 2)
            btn:SetPoint("TOPLEFT", col * (colWidth + 8), -row * rowHeight)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.16, 0.18, 0.24, 0.85)
            btn.Bg = bg

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1.0, 0.82, 0.25, 0.28)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("LEFT", 4, 0)
            icon:SetTexture(info.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("LEFT", icon, "RIGHT", 6, 4)
            text:SetText(info.name)

            local sub = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
            sub:SetPoint("LEFT", icon, "RIGHT", 6, -7)
            sub:SetText("|cff00ccff" .. info.slash .. "|r  |cff888888(" .. info.category .. ")|r")

            btn:SetScript("OnClick", function()
                if activeSlotToEdit then
                    local db = addon.GetDB()
                    db.favorites[activeSlotToEdit] = info.id
                    pickerFrame:Hide()
                    addon.RefreshSettingsUI()
                    addon.RefreshWheelLayout()
                    NotifySuiteChange()
                end
            end)

            pickerFrame.Buttons[idx] = btn
        end

        local totalRows = math.ceil(#addon.EMOTE_CATALOG / 2)
        content:SetHeight(totalRows * rowHeight + 10)
    end

    pickerFrame.Title:SetText("Choose Emote / Pose for Slice #" .. tostring(slotIndex))
    pickerFrame:ClearAllPoints()
    pickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    pickerFrame:Show()
end

function addon.RefreshSettingsUI()
    if not settingsFrame then return end
    local db = addon.GetDB()

    if settingsFrame.KeybindBtn then
        local k = GetCurrentKeybindText() or "|cffff6666Not Bound (Click to Bind)|r"
        settingsFrame.KeybindBtn:SetText("Wheel Keybind:  |cffffd100" .. k .. "|r")
    end

    if settingsFrame.ModeBtn then
        settingsFrame.ModeBtn:SetText("Interaction:  |cff00ddff" .. (MODE_LABELS[db.mode] or MODE_LABELS["BOTH"]) .. "|r")
    end

    if settingsFrame.CursorCheck then
        settingsFrame.CursorCheck:SetChecked(db.spawnAtCursor ~= false)
    end

    if settingsFrame.SoundCheck then
        settingsFrame.SoundCheck:SetChecked(db.soundEffects ~= false)
    end

    if settingsFrame.MinimapCheck then
        settingsFrame.MinimapCheck:SetChecked(db.showMinimapButton == true)
    end

    if settingsFrame.SliceCountLabel then
        settingsFrame.SliceCountLabel:SetText("Favorites Wheel Slices: |cffffd100" .. tostring(db.sliceCount or 8) .. "|r")
    end

    if settingsFrame.ScaleLabel then
        settingsFrame.ScaleLabel:SetText(string.format("Wheel Scale: |cffffd100%d%%|r", math.floor((db.scale or 1.0) * 100 + 0.5)))
    end

    local count = db.sliceCount or 8
    for i = 1, 12 do
        local row = slotRows[i]
        if row then
            local id = db.favorites[i] or addon.DEFAULT_FAVORITES[i] or "SIT"
            local info = addon.EMOTE_BY_ID[id] or addon.EMOTE_CATALOG[1]
            row.Icon:SetTexture(info.icon)
            row.NameText:SetText(string.format("#%d:  |cffffffff%s|r  |cff00ccff(%s)|r", i, info.name, info.slash))
            if i <= count then
                row:SetAlpha(1.0)
                row.ChangeBtn:Enable()
            else
                row:SetAlpha(0.40)
                row.ChangeBtn:Disable()
            end
        end
    end
end

function addon.InitializeSettings()
    addon.RegisterWithSuiteHub()
end

function addon.OpenSettings()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.OpenSettings then
        suite:OpenSettings("emotes")
        return
    end
    addon.OpenKeybindCapturePopup()
end

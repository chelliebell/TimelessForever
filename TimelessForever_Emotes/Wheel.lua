local _, addon = ...

-- =========================================================================
-- TimelessForever_Emotes Interactive Radial UI
-- =========================================================================

local MEDIA_PATH = "Interface\\AddOns\\TimelessForever_Emotes\\Media\\"
local TEX_WHEEL_RING = MEDIA_PATH .. "WheelRing.tga"
local TEX_CENTER_HUB = MEDIA_PATH .. "CenterHub.tga"
local TEX_SOFT_GLOW  = MEDIA_PATH .. "SoftGlow.tga"
local TEX_SLOT_FRAME = MEDIA_PATH .. "SlotFrame.tga"

local WHEEL_SIZE = 370
local SLOT_RADIUS = 128
local DEADZONE_RADIUS = 44
local OUTER_CANCEL_RADIUS = 235
local MAX_SLOTS = 12
local HOLD_THRESHOLD_SEC = 0.20

local wheelFrame = nil
local slotFrames = {}
local pageTabs = {}
local currentPageIndex = 1
local hoveredSliceIndex = nil
local keyDownTime = 0
local isKeyHeld = false
local fadeAlpha = 0

local function PlayTickSound()
    local db = addon.GetDB()
    if not db.soundEffects then return end
    if PlaySound then
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856, "SFX")
    end
end

local function PlaySelectSound()
    local db = addon.GetDB()
    if not db.soundEffects then return end
    if PlaySound then
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION or 852, "SFX")
    end
end

-- Returns list of emote info tables for the active page
local function GetCurrentPageEmotes()
    local db = addon.GetDB()
    local page = addon.WHEEL_PAGES[currentPageIndex] or addon.WHEEL_PAGES[1]
    local list = {}

    if page.isCustom then
        local count = math.max(4, math.min(MAX_SLOTS, db.sliceCount or 8))
        for i = 1, count do
            local id = db.favorites[i] or addon.DEFAULT_FAVORITES[i] or "SIT"
            local info = addon.EMOTE_BY_ID[id] or addon.EMOTE_CATALOG[1]
            list[#list + 1] = info
        end
    else
        local count = math.min(MAX_SLOTS, #page.emotes)
        for i = 1, count do
            local id = page.emotes[i]
            local info = addon.EMOTE_BY_ID[id]
            if info then
                list[#list + 1] = info
            end
        end
    end

    return list, page
end

-- Updates center medallion text, icon, and slice visual states
local function UpdateHighlightVisuals()
    if not wheelFrame then return end
    local db = addon.GetDB()
    local emotes, page = GetCurrentPageEmotes()
    local r, g, b = unpack(page.color or { 1.0, 0.82, 0.25 })

    wheelFrame.RingGlow:SetVertexColor(r, g, b, 0.25)

    local activeEmote = hoveredSliceIndex and emotes[hoveredSliceIndex] or nil

    if activeEmote then
        wheelFrame.CenterIcon:SetTexture(activeEmote.icon)
        wheelFrame.CenterIcon:Show()
        wheelFrame.CenterTitle:SetText(activeEmote.name)
        wheelFrame.CenterTitle:SetTextColor(1, 0.92, 0.45)

        if db.showSlashText then
            local targetSuffix = (activeEmote.category ~= "Poses" and UnitExists("target") and not UnitIsUnit("target", "player"))
                and (" |cff88ccff@" .. (UnitName("target") or "Target") .. "|r")
                or ""
            wheelFrame.CenterSub:SetText("|cff00ddff" .. (activeEmote.slash or "") .. "|r" .. targetSuffix)
        else
            wheelFrame.CenterSub:SetText(activeEmote.category or "")
        end
        if activeEmote.category == "Poses" then
            wheelFrame.CenterHint:SetText("|cffd98cff[Body Pose]|r")
        else
            wheelFrame.CenterHint:SetText(activeEmote.voice and "|cffffb84d[Voice Emote]|r" or "|cffaaaaaa[Animated]|r")
        end
        wheelFrame.CenterGlow:SetVertexColor(r, g, b, 0.55)
    else
        wheelFrame.CenterIcon:SetTexture(page.icon or "Interface\\Icons\\INV_Misc_Coin_01")
        wheelFrame.CenterIcon:Show()
        wheelFrame.CenterTitle:SetText(page.name)
        wheelFrame.CenterTitle:SetTextColor(r, g, b)
        wheelFrame.CenterSub:SetText("Scroll or Click Tabs")
        wheelFrame.CenterHint:SetText("|cff888888Right-Click to Close|r")
        wheelFrame.CenterGlow:SetVertexColor(r, g, b, 0.18)
    end

    for i = 1, MAX_SLOTS do
        local slot = slotFrames[i]
        if slot:IsShown() then
            local isHovered = (i == hoveredSliceIndex)
            if isHovered then
                slot:SetScale(1.22)
                slot.Glow:SetVertexColor(r, g, b, 0.85)
                slot.Glow:Show()
                slot.FrameTex:SetVertexColor(1.0, 0.92, 0.50, 1.0)
                slot.Label:SetTextColor(1.0, 0.95, 0.45)
                slot.SlashLabel:SetTextColor(0.40, 0.90, 1.00)
            else
                slot:SetScale(1.0)
                slot.Glow:Hide()
                slot.FrameTex:SetVertexColor(0.82, 0.78, 0.68, 0.92)
                slot.Label:SetTextColor(0.92, 0.92, 0.92)
                slot.SlashLabel:SetTextColor(0.60, 0.65, 0.72)
            end
        end
    end

    for idx, tab in ipairs(pageTabs) do
        local p = addon.WHEEL_PAGES[idx]
        local pr, pg, pb = unpack(p.color or { 1, 0.82, 0.25 })
        if idx == currentPageIndex then
            tab.Bg:SetColorTexture(pr * 0.35, pg * 0.35, pb * 0.35, 0.92)
            tab.Border:SetVertexColor(pr, pg, pb, 1.0)
            tab.Text:SetTextColor(1, 1, 1)
        else
            tab.Bg:SetColorTexture(0.08, 0.09, 0.12, 0.80)
            tab.Border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
            tab.Text:SetTextColor(0.68, 0.70, 0.75)
        end
    end
end

-- Populates and positions radial slots around the circle
function addon.RefreshWheelLayout()
    if not wheelFrame then return end
    local db = addon.GetDB()
    wheelFrame:SetScale(db.scale or 1.0)

    local emotes, page = GetCurrentPageEmotes()
    local numSlices = #emotes

    for i = 1, MAX_SLOTS do
        local slot = slotFrames[i]
        local info = emotes[i]
        if i <= numSlices and info then
            -- Angle 0 is Top (12 o'clock), moving clockwise
            local angleDeg = (i - 1) * (360 / numSlices)
            local angleRad = math.rad(90 - angleDeg)
            local x = math.cos(angleRad) * SLOT_RADIUS
            local y = math.sin(angleRad) * SLOT_RADIUS

            slot:ClearAllPoints()
            slot:SetPoint("CENTER", wheelFrame, "CENTER", x, y)

            slot.Icon:SetTexture(info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            slot.Label:SetText(info.name)
            slot.SlashLabel:SetText(db.showSlashText and info.slash or "")
            slot.emoteInfo = info
            slot:Show()
        else
            slot.emoteInfo = nil
            slot:Hide()
        end
    end

    if hoveredSliceIndex and hoveredSliceIndex > numSlices then
        hoveredSliceIndex = nil
    end

    UpdateHighlightVisuals()
end

function addon.SwitchWheelPage(deltaOrIndex, isDirect)
    local total = #addon.WHEEL_PAGES
    if isDirect then
        currentPageIndex = math.max(1, math.min(total, deltaOrIndex))
    else
        currentPageIndex = ((currentPageIndex - 1 + deltaOrIndex) % total) + 1
    end
    hoveredSliceIndex = nil
    PlayTickSound()
    addon.RefreshWheelLayout()
end

local function EvaluateMouseAngleSelection()
    if not wheelFrame or not wheelFrame:IsShown() then return end

    -- Don't steal hover if cursor is directly over one of the bottom category tabs
    for _, tab in ipairs(pageTabs) do
        if tab:IsMouseOver() then
            if hoveredSliceIndex ~= nil then
                hoveredSliceIndex = nil
                UpdateHighlightVisuals()
            end
            return
        end
    end
    if wheelFrame.SettingsBtn and wheelFrame.SettingsBtn:IsMouseOver() then
        return
    end

    local wx, wy = wheelFrame:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = wheelFrame:GetEffectiveScale()
    if not wx or not scale or scale == 0 then return end

    cx, cy = cx / scale, cy / scale
    local dx = cx - wx
    local dy = cy - wy
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < DEADZONE_RADIUS or dist > OUTER_CANCEL_RADIUS then
        if hoveredSliceIndex ~= nil then
            hoveredSliceIndex = nil
            UpdateHighlightVisuals()
        end
        return
    end

    local emotes = GetCurrentPageEmotes()
    local numSlices = #emotes
    if numSlices == 0 then return end

    -- Compute clockwise angle from 12 o'clock (0..360)
    local angleFromTop = (90 - math.deg(math.atan2(dy, dx))) % 360
    local sliceWidth = 360 / numSlices
    local index = math.floor(((angleFromTop + (sliceWidth / 2)) % 360) / sliceWidth) + 1

    if index ~= hoveredSliceIndex then
        hoveredSliceIndex = index
        PlayTickSound()
        UpdateHighlightVisuals()
    end
end

local function TriggerHoveredEmote(closeAfter)
    local emotes = GetCurrentPageEmotes()
    local activeEmote = hoveredSliceIndex and emotes[hoveredSliceIndex]
    if activeEmote then
        PlaySelectSound()
        addon.PerformEmoteByInfo(activeEmote)
        if closeAfter then
            addon.CloseWheel()
        end
        return true
    end
    return false
end

local function CreateWheelUI()
    if wheelFrame then return wheelFrame end

    wheelFrame = CreateFrame("Button", "EmoteWheelMainFrame", UIParent)
    wheelFrame:SetSize(WHEEL_SIZE, WHEEL_SIZE)
    wheelFrame:SetFrameStrata("DIALOG")
    wheelFrame:SetFrameLevel(50)
    wheelFrame:EnableMouse(true)
    wheelFrame:EnableMouseWheel(true)
    wheelFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    wheelFrame:Hide()

    -- Allow Escape key to close the wheel cleanly
    tinsert(UISpecialFrames, "EmoteWheelMainFrame")

    -- Soft radial aura behind the ring
    local ringGlow = wheelFrame:CreateTexture(nil, "BACKGROUND")
    ringGlow:SetSize(WHEEL_SIZE + 50, WHEEL_SIZE + 50)
    ringGlow:SetPoint("CENTER")
    ringGlow:SetTexture(TEX_SOFT_GLOW)
    ringGlow:SetBlendMode("ADD")
    wheelFrame.RingGlow = ringGlow

    -- Main Wheel Ring Texture
    local ringTex = wheelFrame:CreateTexture(nil, "BORDER")
    ringTex:SetSize(WHEEL_SIZE, WHEEL_SIZE)
    ringTex:SetPoint("CENTER")
    ringTex:SetTexture(TEX_WHEEL_RING)
    wheelFrame.RingTex = ringTex

    -- Center Glow
    local centerGlow = wheelFrame:CreateTexture(nil, "ARTWORK")
    centerGlow:SetSize(165, 165)
    centerGlow:SetPoint("CENTER")
    centerGlow:SetTexture(TEX_SOFT_GLOW)
    centerGlow:SetBlendMode("ADD")
    wheelFrame.CenterGlow = centerGlow

    -- Center Hub Medallion
    local hubTex = wheelFrame:CreateTexture(nil, "ARTWORK")
    hubTex:SetSize(118, 118)
    hubTex:SetPoint("CENTER")
    hubTex:SetTexture(TEX_CENTER_HUB)
    wheelFrame.HubTex = hubTex

    -- Center Preview Icon
    local centerIcon = wheelFrame:CreateTexture(nil, "OVERLAY")
    centerIcon:SetSize(30, 30)
    centerIcon:SetPoint("CENTER", wheelFrame, "CENTER", 0, 22)
    centerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    wheelFrame.CenterIcon = centerIcon

    -- Center Title Text
    local centerTitle = wheelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    centerTitle:SetPoint("CENTER", wheelFrame, "CENTER", 0, -4)
    centerTitle:SetText("EmoteWheel")
    wheelFrame.CenterTitle = centerTitle

    -- Center Sub Text (/command or target)
    local centerSub = wheelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    centerSub:SetPoint("TOP", centerTitle, "BOTTOM", 0, -3)
    centerSub:SetText("")
    wheelFrame.CenterSub = centerSub

    -- Center Hint
    local centerHint = wheelFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    centerHint:SetPoint("TOP", centerSub, "BOTTOM", 0, -2)
    centerHint:SetText("")
    wheelFrame.CenterHint = centerHint

    -- Create Slice Slot Frames
    for i = 1, MAX_SLOTS do
        local slot = CreateFrame("Button", nil, wheelFrame)
        slot:SetSize(56, 56)
        slot:EnableMouse(false) -- Handled seamlessly by radial angle math on parent

        local glow = slot:CreateTexture(nil, "BACKGROUND")
        glow:SetSize(88, 88)
        glow:SetPoint("CENTER")
        glow:SetTexture(TEX_SOFT_GLOW)
        glow:SetBlendMode("ADD")
        glow:Hide()
        slot.Glow = glow

        local icon = slot:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("CENTER")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.Icon = icon

        local frameTex = slot:CreateTexture(nil, "OVERLAY")
        frameTex:SetSize(56, 56)
        frameTex:SetPoint("CENTER")
        frameTex:SetTexture(TEX_SLOT_FRAME)
        slot.FrameTex = frameTex

        local label = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", slot, "BOTTOM", 0, 2)
        label:SetShadowOffset(1, -1)
        label:SetShadowColor(0, 0, 0, 1)
        slot.Label = label

        local slashLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
        slashLabel:SetPoint("TOP", label, "BOTTOM", 0, -1)
        slashLabel:SetShadowOffset(1, -1)
        slashLabel:SetShadowColor(0, 0, 0, 1)
        slot.SlashLabel = slashLabel

        slotFrames[i] = slot
    end

    -- Category Page Switcher Pills along bottom of the wheel (5 categories + Customize button)
    local tabBar = CreateFrame("Frame", nil, wheelFrame)
    tabBar:SetSize(460, 26)
    tabBar:SetPoint("TOP", wheelFrame, "BOTTOM", 0, -8)

    local tabWidth = 80
    local spacing = 4
    local totalWidth = (#addon.WHEEL_PAGES * tabWidth) + ((#addon.WHEEL_PAGES - 1) * spacing)
    local startX = -totalWidth / 2 + (tabWidth / 2) - 38

    for idx, page in ipairs(addon.WHEEL_PAGES) do
        local tab = CreateFrame("Button", nil, tabBar)
        tab:SetSize(tabWidth, 24)
        tab:SetPoint("CENTER", tabBar, "CENTER", startX + (idx - 1) * (tabWidth + spacing), 0)

        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.14, 0.85)
        tab.Bg = bg

        local border = tab:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(1, 1, 1, 0.25)
        tab.Border = border

        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText(page.shortName or page.name:match("^%S+"))
        tab.Text = text

        tab:SetScript("OnClick", function()
            addon.SwitchWheelPage(idx, true)
        end)

        pageTabs[idx] = tab
    end

    -- Quick Settings Gear Button next to tabs
    local settingsBtn = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
    settingsBtn:SetSize(74, 24)
    settingsBtn:SetPoint("LEFT", pageTabs[#pageTabs], "RIGHT", 6, 0)
    settingsBtn:SetText("Customize")
    settingsBtn:SetScript("OnClick", function()
        addon.CloseWheel()
        addon.OpenSettings()
    end)
    wheelFrame.SettingsBtn = settingsBtn

    -- Mouse Click & Scroll Handlers
    wheelFrame:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            addon.SwitchWheelPage(-1, false)
        else
            addon.SwitchWheelPage(1, false)
        end
    end)

    wheelFrame:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            addon.CloseWheel()
            return
        end
        if button == "LeftButton" then
            local db = addon.GetDB()
            local triggered = TriggerHoveredEmote(db.closeOnTrigger ~= false)
            if not triggered then
                -- Clicking inside the center hub cycles category pages
                local wx, wy = wheelFrame:GetCenter()
                local cx, cy = GetCursorPosition()
                local scale = wheelFrame:GetEffectiveScale()
                if wx and scale and scale > 0 then
                    cx, cy = cx / scale, cy / scale
                    local dist = math.sqrt((cx - wx) ^ 2 + (cy - wy) ^ 2)
                    if dist <= DEADZONE_RADIUS then
                        addon.SwitchWheelPage(1, false)
                    else
                        addon.CloseWheel()
                    end
                end
            end
        end
    end)

    wheelFrame:SetScript("OnUpdate", function(self, elapsed)
        if fadeAlpha < 1.0 then
            fadeAlpha = math.min(1.0, fadeAlpha + elapsed * 9.0)
            self:SetAlpha(fadeAlpha)
        end
        EvaluateMouseAngleSelection()
    end)

    return wheelFrame
end

-- =========================================================================
-- Public Open / Close / Keybind State Machine
-- =========================================================================

function addon.OpenWheel()
    local frame = CreateWheelUI()
    local db = addon.GetDB()

    frame:SetScale(db.scale or 1.0)
    frame:ClearAllPoints()

    if db.spawnAtCursor then
        local cx, cy = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        if scale and scale > 0 then
            cx, cy = cx / scale, cy / scale
            -- Clamp within screen bounds so slices don't clip off-screen
            local uiW = UIParent:GetWidth() / (db.scale or 1.0)
            local uiH = UIParent:GetHeight() / (db.scale or 1.0)
            local margin = (WHEEL_SIZE / 2) + 35
            cx = math.max(margin, math.min(uiW - margin, cx))
            cy = math.max(margin + 25, math.min(uiH - margin, cy))
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    hoveredSliceIndex = nil
    fadeAlpha = 0.15
    frame:SetAlpha(fadeAlpha)
    addon.RefreshWheelLayout()
    frame:Show()
end

function addon.CloseWheel()
    isKeyHeld = false
    if wheelFrame and wheelFrame:IsShown() then
        wheelFrame:Hide()
    end
end

function addon.ToggleWheel()
    if wheelFrame and wheelFrame:IsShown() then
        addon.CloseWheel()
    else
        addon.OpenWheel()
    end
end

function addon.OnKeyDown()
    local db = addon.GetDB()
    keyDownTime = GetTime()
    isKeyHeld = true

    if db.mode == "TOGGLE" then
        addon.ToggleWheel()
        return
    end

    -- For "HOLD" or "BOTH":
    if wheelFrame and wheelFrame:IsShown() then
        if not TriggerHoveredEmote(true) then
            addon.CloseWheel()
        end
        isKeyHeld = false
    else
        addon.OpenWheel()
    end
end

function addon.OnKeyUp()
    if not isKeyHeld then return end
    isKeyHeld = false

    local db = addon.GetDB()
    if db.mode == "TOGGLE" then
        return
    end

    if not wheelFrame or not wheelFrame:IsShown() then
        return
    end

    local heldDuration = GetTime() - keyDownTime

    if db.mode == "HOLD" then
        TriggerHoveredEmote(true)
        addon.CloseWheel()
    else
        -- "BOTH" (Smart Hybrid):
        if hoveredSliceIndex ~= nil then
            TriggerHoveredEmote(true)
            addon.CloseWheel()
        elseif heldDuration >= HOLD_THRESHOLD_SEC then
            addon.CloseWheel()
        end
    end
end

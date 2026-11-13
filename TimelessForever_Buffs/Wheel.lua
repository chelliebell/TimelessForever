local _, addon = ...

-- =========================================================================
-- TimelessForever_Buffs: Interactive Radial Buff Wheel & Secure Buttons
-- =========================================================================

local MEDIA_PATH = "Interface\\AddOns\\TimelessForever_Buffs\\Media\\"
local TEX_WHEEL_RING = MEDIA_PATH .. "WheelRing.tga"
local TEX_CENTER_HUB = MEDIA_PATH .. "CenterHub.tga"
local TEX_SOFT_GLOW  = MEDIA_PATH .. "SoftGlow.tga"
local TEX_SLOT_FRAME = MEDIA_PATH .. "SlotFrame.tga"

local WHEEL_SIZE = 380
local SLOT_RADIUS = 132
local DEADZONE_RADIUS = 46
local OUTER_CANCEL_RADIUS = 240
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

local function PlayCastSound()
    local db = addon.GetDB()
    if not db.soundEffects then return end
    if PlaySound then
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.SPELL_CLICK or 848, "SFX")
    end
end

-- Formats remaining seconds nicely (e.g. 52s, 14m, 1.5h)
local function FormatDuration(seconds)
    if not seconds or seconds <= 0 then return "" end
    if seconds < 60 then
        return string.format("%ds", math.floor(seconds))
    elseif seconds < 3600 then
        return string.format("%dm", math.floor(seconds / 60))
    else
        return string.format("%.1fh", seconds / 3600)
    end
end

-- Filters buffs for the active category page
local function GetCurrentPageBuffs()
    local db = addon.GetDB()
    local page = addon.WHEEL_PAGES[currentPageIndex] or addon.WHEEL_PAGES[1]
    local list = {}

    if page.isCustom then
        -- Favorites Wheel (4 to 12 user-customized slots)
        local count = math.max(4, math.min(MAX_SLOTS, db.sliceCount or 8))
        for i = 1, count do
            local id = db.favorites[i]
            local info = (id and addon.BUFF_BY_ID[id]) or addon.BUFF_CATALOG[1]
            list[#list + 1] = info
        end
    elseif page.isClassDynamic then
        -- Known class buffs from spellbook scan
        local known = addon.ScanSpellbook()
        for i = 1, math.min(MAX_SLOTS, #known) do
            list[#list + 1] = known[i]
        end
        if #list == 0 then
            -- If no spells learned yet or low level, show class catalog defaults
            for _, b in ipairs(addon.BUFF_CATALOG) do
                if b.class == addon.playerClass or b.class == "ALL" then
                    list[#list + 1] = b
                    if #list >= MAX_SLOTS then break end
                end
            end
        end
    else
        -- Filtered by category (Self, Raid, Aura/Weapon)
        for _, b in ipairs(addon.BUFF_CATALOG) do
            if b.class == addon.playerClass or b.class == "ALL" then
                local match = false
                if type(page.categoryFilter) == "table" then
                    for _, cat in ipairs(page.categoryFilter) do
                        if b.category == cat then match = true; break end
                    end
                elseif b.category == page.categoryFilter then
                    match = true
                end
                if match then
                    list[#list + 1] = b
                    if #list >= MAX_SLOTS then break end
                end
            end
        end
    end

    return list, page
end

-- Updates center medallion, aura timers, checkmarks, and hover glows
local function UpdateHighlightVisuals()
    if not wheelFrame then return end
    local db = addon.GetDB()
    local buffs, page = GetCurrentPageBuffs()
    local r, g, b = unpack(page.color or { 1.0, 0.82, 0.25 })

    wheelFrame.RingGlow:SetVertexColor(r, g, b, 0.25)

    local activeBuff = hoveredSliceIndex and buffs[hoveredSliceIndex] or nil

    local targetUnit = (UnitExists("target") and not UnitIsUnit("target", "player") and UnitCanAssist("player", "target")) and "target" or "player"

    if activeBuff then
        wheelFrame.CenterIcon:SetTexture(activeBuff.icon)
        wheelFrame.CenterIcon:Show()
        wheelFrame.CenterTitle:SetText(activeBuff.name)
        wheelFrame.CenterTitle:SetTextColor(1, 0.95, 0.45)

        local checkUnit = activeBuff.isSelfOnly and "player" or targetUnit
        local ok, isActive, duration, expTime = pcall(addon.GetBuffStatus, activeBuff, checkUnit)
        if not ok then isActive, duration, expTime = false, 0, 0 end

        if isActive then
            local remain = expTime and expTime > 0 and (expTime - GetTime()) or duration
            local timeStr = remain > 0 and (" (" .. FormatDuration(remain) .. ")") or ""
            wheelFrame.CenterSub:SetText("|cff00ff00[ACTIVE]|r" .. timeStr .. (checkUnit == "target" and " on Target" or ""))
        else
            wheelFrame.CenterSub:SetText("|cffff8844[NOT ACTIVE]|r — Click to Cast")
        end

        local castTargetStr = activeBuff.isSelfOnly and "|cff88ccffCast on Self|r" or (targetUnit == "target" and ("|cff88ccffCast on " .. (UnitName("target") or "Target") .. "|r") or "|cff88ccffCast on Self / Friendly|r")
        wheelFrame.CenterHint:SetText(castTargetStr)
        wheelFrame.CenterGlow:SetVertexColor(r, g, b, 0.55)
    else
        wheelFrame.CenterIcon:SetTexture(page.icon or "Interface\\Icons\\INV_Misc_Coin_01")
        wheelFrame.CenterIcon:Show()
        wheelFrame.CenterTitle:SetText(page.name)
        wheelFrame.CenterTitle:SetTextColor(r, g, b)
        wheelFrame.CenterSub:SetText("Scroll Wheel or Click Tabs")
        wheelFrame.CenterHint:SetText("|cff888888Right-Click or ESC to Close|r")
        wheelFrame.CenterGlow:SetVertexColor(r, g, b, 0.18)
    end

    -- Update slice frames: icons, aura checkmarks, cooldowns, hover states
    for i = 1, MAX_SLOTS do
        local slot = slotFrames[i]
        if slot:IsShown() and slot.buffInfo then
            local info = slot.buffInfo
            local isHovered = (i == hoveredSliceIndex)
            local checkUnit = info.isSelfOnly and "player" or targetUnit
            local ok, isActive, duration, expTime, stacks = pcall(addon.GetBuffStatus, info, checkUnit)
            if not ok then isActive, duration, expTime, stacks = false, 0, 0, 1 end

            -- Aura Status text (Checkmark or remaining duration)
            if isActive then
                slot.Checkmark:Show()
                if expTime and expTime > 0 then
                    local remain = expTime - GetTime()
                    if remain > 0 then
                        slot.StatusText:SetText(FormatDuration(remain))
                        slot.StatusText:SetTextColor(0.2, 1.0, 0.4)
                    else
                        slot.StatusText:SetText("")
                    end
                else
                    slot.StatusText:SetText("")
                end
                slot.Icon:SetDesaturated(false)
            else
                slot.Checkmark:Hide()
                slot.StatusText:SetText("|cffff5533MISSING|r")
                slot.StatusText:SetTextColor(1.0, 0.45, 0.3)
                -- Slightly dim missing buffs so active ones stand out
                slot.Icon:SetDesaturated(false)
            end

            -- Update Cooldown spinner if on CD
            if GetSpellCooldown and info.spellName then
                local start, cdDur = GetSpellCooldown(info.spellName)
                if start and start > 0 and cdDur and cdDur > 1.5 then
                    slot.Cooldown:SetCooldown(start, cdDur)
                    slot.Cooldown:Show()
                else
                    slot.Cooldown:Hide()
                end
            end

            if isHovered then
                slot:SetScale(1.22)
                slot.Glow:SetVertexColor(r, g, b, 0.85)
                slot.Glow:Show()
                slot.FrameTex:SetVertexColor(1.0, 0.92, 0.50, 1.0)
                slot.Label:SetTextColor(1.0, 0.95, 0.45)
            else
                slot:SetScale(1.0)
                slot.Glow:Hide()
                if isActive then
                    slot.FrameTex:SetVertexColor(0.2, 0.95, 0.5, 0.95)
                    slot.Label:SetTextColor(0.95, 0.95, 0.95)
                else
                    slot.FrameTex:SetVertexColor(0.80, 0.75, 0.65, 0.88)
                    slot.Label:SetTextColor(0.85, 0.85, 0.85)
                end
            end
        end
    end

    -- Tab visual selection
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

-- Refresh layout and update SecureActionButtonTemplate attributes
function addon.RefreshWheelLayout()
    if not wheelFrame then return end
    local db = addon.GetDB()
    wheelFrame:SetScale(db.scale or 1.0)

    local buffs, page = GetCurrentPageBuffs()
    local numSlices = #buffs

    for i = 1, MAX_SLOTS do
        local slot = slotFrames[i]
        local info = buffs[i]
        if i <= numSlices and info then
            local angleDeg = (i - 1) * (360 / numSlices)
            local angleRad = math.rad(90 - angleDeg)
            local x = math.cos(angleRad) * SLOT_RADIUS
            local y = math.sin(angleRad) * SLOT_RADIUS

            slot:ClearAllPoints()
            slot:SetPoint("CENTER", wheelFrame, "CENTER", x, y)

            slot.Icon:SetTexture(info.icon or "Interface\\Icons\\Spell_Holy_MagicalSentry")
            slot.Label:SetText(info.name)
            slot.buffInfo = info
            slot:Show()
        else
            slot.buffInfo = nil
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
            if not InCombatLockdown() then
                wheelFrame:SetAttribute("macrotext", nil)
                wheelFrame:SetAttribute("macrotext1", nil)
            end
            UpdateHighlightVisuals()
        end
        return
    end

    local buffs = GetCurrentPageBuffs()
    local numSlices = #buffs
    if numSlices == 0 then return end

    local angleFromTop = (90 - math.deg(math.atan2(dy, dx))) % 360
    local sliceWidth = 360 / numSlices
    local index = math.floor(((angleFromTop + (sliceWidth / 2)) % 360) / sliceWidth) + 1

    if index ~= hoveredSliceIndex then
        hoveredSliceIndex = index
        local activeBuff = buffs[index]
        if activeBuff and not InCombatLockdown() then
            local macro = addon.GetCastMacroText(activeBuff)
            wheelFrame:SetAttribute("type", "macro")
            wheelFrame:SetAttribute("type1", "macro")
            wheelFrame:SetAttribute("macrotext", macro)
            wheelFrame:SetAttribute("macrotext1", macro)
        end
        PlayTickSound()
        UpdateHighlightVisuals()
    end
end

local function CreateWheelUI()
    if wheelFrame then return wheelFrame end

    wheelFrame = CreateFrame("Button", "TimelessForever_BuffWheelMainFrame", UIParent, "SecureActionButtonTemplate")
    wheelFrame:SetSize(WHEEL_SIZE, WHEEL_SIZE)
    wheelFrame:SetFrameStrata("DIALOG")
    wheelFrame:SetFrameLevel(50)
    wheelFrame:EnableMouse(true)
    wheelFrame:EnableMouseWheel(true)
    wheelFrame:RegisterForClicks("AnyDown", "AnyUp")
    wheelFrame:SetAttribute("type", "macro")
    wheelFrame:SetAttribute("type1", "macro")
    wheelFrame:Hide()

    if wheelFrame.SetPropagateKeyboardInput then
        wheelFrame:EnableKeyboard(true)
        wheelFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                addon.CloseWheel()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)
    else
        tinsert(UISpecialFrames, "TimelessForever_BuffWheelMainFrame")
    end

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
    centerIcon:SetSize(32, 32)
    centerIcon:SetPoint("CENTER", wheelFrame, "CENTER", 0, 22)
    centerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    wheelFrame.CenterIcon = centerIcon

    -- Center Title Text
    local centerTitle = wheelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    centerTitle:SetPoint("CENTER", wheelFrame, "CENTER", 0, -4)
    centerTitle:SetText("BuffWheel")
    wheelFrame.CenterTitle = centerTitle

    -- Center Sub Text (Active/Missing & Duration)
    local centerSub = wheelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    centerSub:SetPoint("TOP", centerTitle, "BOTTOM", 0, -3)
    centerSub:SetText("")
    wheelFrame.CenterSub = centerSub

    -- Center Hint
    local centerHint = wheelFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    centerHint:SetPoint("TOP", centerSub, "BOTTOM", 0, -2)
    centerHint:SetText("")
    wheelFrame.CenterHint = centerHint

    -- Create Slice Slot Frames (Visual elements, mouse handled by parent Secure wheelFrame)
    for i = 1, MAX_SLOTS do
        local slot = CreateFrame("Button", nil, wheelFrame)
        slot:SetSize(56, 56)
        slot:EnableMouse(false)

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

        -- Cooldown spinner overlay
        local cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        cd:SetAllPoints(icon)
        cd:Hide()
        slot.Cooldown = cd

        local frameTex = slot:CreateTexture(nil, "OVERLAY")
        frameTex:SetSize(56, 56)
        frameTex:SetPoint("CENTER")
        frameTex:SetTexture(TEX_SLOT_FRAME)
        slot.FrameTex = frameTex

        -- Active Checkmark badge in top-right of slot
        local checkmark = slot:CreateTexture(nil, "OVERLAY", nil, 6)
        checkmark:SetSize(18, 18)
        checkmark:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -2, -2)
        checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        checkmark:Hide()
        slot.Checkmark = checkmark

        -- Spell Name label
        local label = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", slot, "BOTTOM", 0, 2)
        label:SetShadowOffset(1, -1)
        label:SetShadowColor(0, 0, 0, 1)
        slot.Label = label

        -- Status duration text below spell name
        local statusText = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
        statusText:SetPoint("TOP", label, "BOTTOM", 0, -1)
        statusText:SetShadowOffset(1, -1)
        statusText:SetShadowColor(0, 0, 0, 1)
        slot.StatusText = statusText

        slotFrames[i] = slot
    end

    -- Bottom Category Tabs
    local tabBar = CreateFrame("Frame", nil, wheelFrame)
    tabBar:SetSize(470, 26)
    tabBar:SetPoint("TOP", wheelFrame, "BOTTOM", 0, -8)

    local tabWidth = 80
    local spacing = 4
    local totalWidth = (#addon.WHEEL_PAGES * tabWidth) + ((#addon.WHEEL_PAGES - 1) * spacing)
    local startX = -totalWidth / 2 + (tabWidth / 2) - 40

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

    -- Quick Settings button
    local settingsBtn = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
    settingsBtn:SetSize(76, 24)
    settingsBtn:SetPoint("LEFT", pageTabs[#pageTabs], "RIGHT", 6, 0)
    settingsBtn:SetText("Customize")
    settingsBtn:SetScript("OnClick", function()
        addon.CloseWheel()
        addon.OpenSettings()
    end)
    wheelFrame.SettingsBtn = settingsBtn

    -- Mouse Scroll Wheel
    wheelFrame:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            addon.SwitchWheelPage(-1, false)
        else
            addon.SwitchWheelPage(1, false)
        end
    end)

    wheelFrame:HookScript("OnClick", function(self, button)
        if button == "RightButton" then
            addon.CloseWheel()
            return
        end
        if button == "LeftButton" then
            if hoveredSliceIndex ~= nil then
                PlayCastSound()
                local db = addon.GetDB()
                if db.closeOnCast ~= false then
                    if C_Timer and C_Timer.After then
                        C_Timer.After(0.18, function()
                            addon.CloseWheel()
                        end)
                    else
                        addon.CloseWheel()
                    end
                end
            else
                local wx, wy = self:GetCenter()
                local cx, cy = GetCursorPosition()
                local scale = self:GetEffectiveScale()
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

    local updateAccum = 0
    wheelFrame:SetScript("OnUpdate", function(self, elapsed)
        if fadeAlpha < 1.0 then
            fadeAlpha = math.min(1.0, fadeAlpha + elapsed * 9.0)
            self:SetAlpha(fadeAlpha)
        end
        EvaluateMouseAngleSelection()

        updateAccum = updateAccum + elapsed
        if updateAccum >= 0.20 then
            updateAccum = 0
            UpdateHighlightVisuals()
        end
    end)

    return wheelFrame
end

-- =========================================================================
-- Public Open / Close / Keybind Logic
-- =========================================================================

function addon.OpenWheel()
    if InCombatLockdown() then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Timeless Buffs]|r Radial buff wheel is disabled during combat.")
        end
        return
    end

    local frame = CreateWheelUI()
    local db = addon.GetDB()

    frame:SetScale(db.scale or 1.0)
    frame:ClearAllPoints()

    if db.spawnAtCursor then
        local cx, cy = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        if scale and scale > 0 then
            cx, cy = cx / scale, cy / scale
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
    if not InCombatLockdown() then
        frame:SetAttribute("type", "macro")
        frame:SetAttribute("type1", "macro")
        frame:SetAttribute("macrotext", nil)
        frame:SetAttribute("macrotext1", nil)

        if SetOverrideBindingClick then
            local key1, key2 = GetBindingKey("BUFFWHEEL_OPEN")
            if key1 then
                SetOverrideBindingClick(frame, true, key1, "TimelessForever_BuffWheelMainFrame", "LeftButton")
            end
            if key2 then
                SetOverrideBindingClick(frame, true, key2, "TimelessForever_BuffWheelMainFrame", "LeftButton")
            end
        end
    end
    addon.RefreshWheelLayout()
    frame:Show()
end

function addon.CloseWheel()
    isKeyHeld = false
    if not wheelFrame or not wheelFrame:IsShown() then return end
    if ClearOverrideBindings and not InCombatLockdown() then
        ClearOverrideBindings(wheelFrame)
    end
    if InCombatLockdown() then
        wheelFrame:SetAlpha(0)
        wheelFrame:EnableMouse(false)
    else
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
    if InCombatLockdown() then return end
    local db = addon.GetDB()
    keyDownTime = GetTime()
    isKeyHeld = true

    if db.mode == "HOLD" then
        if not (wheelFrame and wheelFrame:IsShown()) then
            addon.OpenWheel()
        end
    else
        addon.ToggleWheel()
    end
end

function addon.OnKeyUp()
    if not isKeyHeld then return end
    isKeyHeld = false

    local db = addon.GetDB()
    if db.mode == "HOLD" then
        addon.CloseWheel()
    end
end

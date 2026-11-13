local addonName, ns = ...

local contextMenu = nil
local dialog = nil

-- Dialog state
local currentClickMapID = nil
local currentClickX = nil
local currentClickY = nil
local editingBookmark = nil
local selectedIconKey = ns.DEFAULT_ICON_KEY
local selectedCategory = "All"

--------------------------------------------------------------------------------
-- Helper UI styling
--------------------------------------------------------------------------------

local function SetBackdrop(frame, bgAlpha, borderAlpha)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.12, bgAlpha or 0.96)
    frame:SetBackdropBorderColor(0.9, 0.75, 0.2, borderAlpha or 1.0)
end

--------------------------------------------------------------------------------
-- Context Menu (Optional 2-choice menu)
--------------------------------------------------------------------------------

local function CreateContextMenu()
    if contextMenu then return contextMenu end

    local menu = CreateFrame("Button", "TimelessForever_BookmarksContextMenu", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    menu:SetSize(200, 92)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(600)
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    SetBackdrop(menu, 0.98, 1.0)

    -- Header text (Zone & coords)
    local header = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOP", 0, -8)
    header:SetTextColor(1, 0.82, 0)
    menu.header = header

    -- Button: Add Bookmark
    local btnAdd = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    btnAdd:SetSize(180, 24)
    btnAdd:SetPoint("TOP", header, "BOTTOM", 0, -6)
    btnAdd:SetText("+ Add Bookmark Here")
    btnAdd:SetScript("OnClick", function()
        menu:Hide()
        ns.ShowCreateDialog(currentClickMapID, currentClickX, currentClickY)
    end)
    menu.btnAdd = btnAdd

    -- Button: Zoom Out
    local btnZoom = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    btnZoom:SetSize(180, 22)
    btnZoom:SetPoint("TOP", btnAdd, "BOTTOM", 0, -3)
    btnZoom:SetText("- Zoom Out")
    btnZoom:SetScript("OnClick", function()
        menu:Hide()
        if WorldMapFrame and WorldMapFrame.NavigateToParentMap then
            WorldMapFrame:NavigateToParentMap()
        end
    end)
    menu.btnZoom = btnZoom

    contextMenu = menu
    return menu
end

function ns.ShowContextMenu(mapID, x, y)
    local menu = CreateContextMenu()
    currentClickMapID = mapID
    currentClickX = x
    currentClickY = y

    local zoneName = ns.GetZoneName(mapID)
    menu.header:SetText(string.format("%s (%s)", zoneName, ns.FormatCoords(x, y)))

    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    menu:ClearAllPoints()
    menu:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / scale, cy / scale)
    menu:Show()
end

--------------------------------------------------------------------------------
-- Main Bookmark Dialog (Create / Edit)
--------------------------------------------------------------------------------

local iconButtons = {}

local function RefreshIconGrid()
    if not dialog then return end

    local filtered = {}
    for _, icon in ipairs(ns.ICONS) do
        if selectedCategory == "All" or icon.category == selectedCategory then
            table.insert(filtered, icon)
        end
    end

    local cols = 7
    local btnSize = 34
    local spacing = 6
    local startX = 20
    local startY = -150

    for i, icon in ipairs(filtered) do
        local btn = iconButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, dialog)
            btn:SetSize(btnSize, btnSize)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.12, 0.12, 0.16, 0.8)
            btn.bg = bg

            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", 4, -4)
            tex:SetPoint("BOTTOMRIGHT", -4, 4)
            btn.icon = tex

            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints()
            border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            border:SetBlendMode("ADD")
            border:Hide()
            btn.border = border

            local selGlow = btn:CreateTexture(nil, "OVERLAY")
            selGlow:SetAllPoints()
            selGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            selGlow:SetBlendMode("ADD")
            selGlow:Hide()
            btn.selGlow = selGlow

            btn:SetScript("OnEnter", function(self)
                self.border:Show()
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(self.iconData and self.iconData.name or "Icon", 1, 0.82, 0)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                self.border:Hide()
                if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
            end)
            btn:SetScript("OnClick", function(self)
                if self.iconData then
                    selectedIconKey = self.iconData.key
                    dialog.previewIcon:SetTexture(self.iconData.texture)
                    if self.iconData.color then
                        dialog.previewIcon:SetVertexColor(self.iconData.color[1], self.iconData.color[2], self.iconData.color[3], 1)
                    else
                        dialog.previewIcon:SetVertexColor(1, 1, 1, 1)
                    end
                    dialog.previewLabel:SetText(self.iconData.name)
                    RefreshIconGrid()
                end
            end)

            iconButtons[i] = btn
        end

        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", dialog, "TOPLEFT", startX + col * (btnSize + spacing), startY - row * (btnSize + spacing))
        btn.iconData = icon
        btn.icon:SetTexture(icon.texture)
        if icon.color then
            btn.icon:SetVertexColor(icon.color[1], icon.color[2], icon.color[3], 1)
        else
            btn.icon:SetVertexColor(1, 1, 1, 1)
        end

        if icon.key == selectedIconKey then
            btn.selGlow:Show()
            btn.bg:SetColorTexture(0.3, 0.5, 0.8, 0.8)
        else
            btn.selGlow:Hide()
            btn.bg:SetColorTexture(0.12, 0.12, 0.16, 0.8)
        end

        btn:Show()
    end

    for i = #filtered + 1, #iconButtons do
        iconButtons[i]:Hide()
    end
end

local function CreateDialog()
    if dialog then return dialog end

    local dlg = CreateFrame("Frame", "TimelessForever_BookmarksDialog", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    dlg:SetSize(360, 420)
    dlg:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    dlg:SetFrameStrata("TOOLTIP")
    dlg:SetFrameLevel(500)
    dlg:SetClampedToScreen(true)
    dlg:EnableMouse(true)
    dlg:SetMovable(true)
    dlg:RegisterForDrag("LeftButton")
    dlg:SetScript("OnDragStart", dlg.StartMoving)
    dlg:SetScript("OnDragStop", dlg.StopMovingOrSizing)
    SetBackdrop(dlg, 0.98, 1.0)

    -- Header title
    local title = dlg:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", 0, -14)
    title:SetTextColor(1, 0.82, 0)
    dlg.title = title

    -- Subtitle / Location
    local sub = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -4)
    sub:SetTextColor(0.8, 0.8, 0.8)
    dlg.sub = sub

    -- Close Button
    local close = CreateFrame("Button", nil, dlg, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() dlg:Hide() end)

    -- Title Label
    local lblTitle = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblTitle:SetPoint("TOPLEFT", 20, -52)
    lblTitle:SetText("Label / Title:")
    lblTitle:SetTextColor(1, 0.82, 0)

    -- Title EditBox
    local ebTitle = CreateFrame("EditBox", nil, dlg, "InputBoxTemplate")
    ebTitle:SetSize(315, 22)
    ebTitle:SetPoint("TOPLEFT", lblTitle, "BOTTOMLEFT", 4, -4)
    ebTitle:SetAutoFocus(true)
    dlg.ebTitle = ebTitle

    -- Notes Label
    local lblNote = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblNote:SetPoint("TOPLEFT", 20, -100)
    lblNote:SetText("Note / Description (Optional):")
    lblNote:SetTextColor(0.8, 0.8, 0.8)

    -- Note EditBox
    local ebNote = CreateFrame("EditBox", nil, dlg, "InputBoxTemplate")
    ebNote:SetSize(315, 22)
    ebNote:SetPoint("TOPLEFT", lblNote, "BOTTOMLEFT", 4, -4)
    ebNote:SetAutoFocus(false)
    dlg.ebNote = ebNote

    -- Category filter tabs
    local catBtns = {}
    local catX = 20
    for _, cat in ipairs(ns.ICON_CATEGORIES) do
        local catBtn = CreateFrame("Button", nil, dlg)
        catBtn:SetSize(52, 18)
        catBtn:SetPoint("TOPLEFT", dlg, "TOPLEFT", catX, -148)

        local btnText = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetAllPoints()
        btnText:SetText(cat)
        catBtn.text = btnText

        catBtn:SetScript("OnClick", function()
            selectedCategory = cat
            for _, b in ipairs(catBtns) do
                b.text:SetTextColor(0.6, 0.6, 0.6)
            end
            btnText:SetTextColor(1, 0.82, 0)
            RefreshIconGrid()
        end)
        table.insert(catBtns, catBtn)
        catX = catX + 54
    end
    dlg.catBtns = catBtns

    -- Selected Preview frame
    local previewBox = CreateFrame("Frame", nil, dlg, BackdropTemplateMixin and "BackdropTemplate" or nil)
    previewBox:SetSize(320, 36)
    previewBox:SetPoint("BOTTOM", dlg, "BOTTOM", 0, 52)
    if previewBox.SetBackdrop then
        previewBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        previewBox:SetBackdropColor(0.05, 0.05, 0.08, 0.8)
        previewBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    end

    local pIcon = previewBox:CreateTexture(nil, "ARTWORK")
    pIcon:SetSize(24, 24)
    pIcon:SetPoint("LEFT", 8, 0)
    dlg.previewIcon = pIcon

    local pLabel = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pLabel:SetPoint("LEFT", pIcon, "RIGHT", 8, 0)
    pLabel:SetText("Yellow Pin")
    dlg.previewLabel = pLabel

    -- Save Button
    local btnSave = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
    btnSave:SetSize(110, 24)
    btnSave:SetPoint("BOTTOMLEFT", 20, 16)
    btnSave:SetText("Save Bookmark")
    btnSave:SetScript("OnClick", function()
        local titleText = dlg.ebTitle:GetText()
        local noteText = dlg.ebNote:GetText()

        if editingBookmark then
            ns.UpdateBookmark(editingBookmark.id, titleText, selectedIconKey, noteText)
        else
            ns.AddBookmark(currentClickMapID, currentClickX, currentClickY, titleText, selectedIconKey, noteText)
        end
        dlg:Hide()
    end)
    dlg.btnSave = btnSave

    -- Cancel Button
    local btnCancel = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
    btnCancel:SetSize(80, 24)
    btnCancel:SetPoint("LEFT", btnSave, "RIGHT", 6, 0)
    btnCancel:SetText("Cancel")
    btnCancel:SetScript("OnClick", function() dlg:Hide() end)

    -- Zoom Out Button (in case they clicked to zoom out)
    local btnZoom = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
    btnZoom:SetSize(80, 24)
    btnZoom:SetPoint("LEFT", btnCancel, "RIGHT", 6, 0)
    btnZoom:SetText("Zoom Out")
    btnZoom:SetScript("OnClick", function()
        dlg:Hide()
        if WorldMapFrame and WorldMapFrame.NavigateToParentMap then
            WorldMapFrame:NavigateToParentMap()
        end
    end)
    dlg.btnZoom = btnZoom

    -- Delete Button (when editing existing)
    local btnDelete = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
    btnDelete:SetSize(60, 24)
    btnDelete:SetPoint("BOTTOMRIGHT", -20, 16)
    btnDelete:SetText("Delete")
    btnDelete:SetScript("OnClick", function()
        if editingBookmark then
            ns.DeleteBookmark(editingBookmark.id)
            dlg:Hide()
        end
    end)
    dlg.btnDelete = btnDelete

    -- Enter key saves
    ebTitle:SetScript("OnEnterPressed", function()
        btnSave:GetScript("OnClick")(btnSave)
    end)
    ebNote:SetScript("OnEnterPressed", function()
        btnSave:GetScript("OnClick")(btnSave)
    end)

    dlg:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    dialog = dlg
    return dlg
end

function ns.ShowCreateDialog(mapID, x, y)
    local dlg = CreateDialog()
    editingBookmark = nil
    currentClickMapID = mapID
    currentClickX = x
    currentClickY = y
    selectedIconKey = ns.DEFAULT_ICON_KEY
    selectedCategory = "All"

    dlg.title:SetText("New Map Bookmark")
    dlg.sub:SetText(string.format("%s (%s)", ns.GetZoneName(mapID), ns.FormatCoords(x, y)))
    dlg.ebTitle:SetText("")
    dlg.ebNote:SetText("")
    dlg.btnDelete:Hide()
    dlg.btnZoom:Show()
    dlg.btnSave:SetText("Save Bookmark")

    local iconInfo = ns.GetIconInfo(selectedIconKey)
    dlg.previewIcon:SetTexture(iconInfo.texture)
    if iconInfo.color then
        dlg.previewIcon:SetVertexColor(iconInfo.color[1], iconInfo.color[2], iconInfo.color[3], 1)
    else
        dlg.previewIcon:SetVertexColor(1, 1, 1, 1)
    end
    dlg.previewLabel:SetText(iconInfo.name)

    RefreshIconGrid()
    dlg:Show()
    dlg.ebTitle:SetFocus()

    if PlaySound then pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN or 856) end
end

function ns.ShowEditDialog(bm)
    if not bm then return end
    local dlg = CreateDialog()
    editingBookmark = bm
    currentClickMapID = bm.mapID
    currentClickX = bm.x
    currentClickY = bm.y
    selectedIconKey = bm.iconKey or ns.DEFAULT_ICON_KEY
    selectedCategory = "All"

    dlg.title:SetText("Edit Map Bookmark")
    dlg.sub:SetText(string.format("%s (%s)", ns.GetZoneName(bm.mapID), ns.FormatCoords(bm.x, bm.y)))
    dlg.ebTitle:SetText(bm.title or "")
    dlg.ebNote:SetText(bm.note or "")
    dlg.btnDelete:Show()
    dlg.btnZoom:Hide()
    dlg.btnSave:SetText("Update")

    local iconInfo = ns.GetIconInfo(selectedIconKey)
    dlg.previewIcon:SetTexture(iconInfo.texture)
    if iconInfo.color then
        dlg.previewIcon:SetVertexColor(iconInfo.color[1], iconInfo.color[2], iconInfo.color[3], 1)
    else
        dlg.previewIcon:SetVertexColor(1, 1, 1, 1)
    end
    dlg.previewLabel:SetText(iconInfo.name)

    RefreshIconGrid()
    dlg:Show()
    dlg.ebTitle:SetFocus()
    dlg.ebTitle:HighlightText()

    if PlaySound then pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN or 856) end
end

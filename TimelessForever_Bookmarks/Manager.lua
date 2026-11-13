local addonName, ns = ...

local managerFrame = nil
local listRows = {}
local filterZoneOnly = false
local searchQuery = ""

--------------------------------------------------------------------------------
-- Helpers
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

local function GetCurrentPlayerMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
    return nil
end

local function FilteredBookmarks()
    local all = ns.GetAllBookmarks()
    local playerMapID = GetCurrentPlayerMapID()
    local result = {}

    local q = strlower(strtrim(searchQuery))

    for _, bm in ipairs(all) do
        local matchZone = true
        if filterZoneOnly and playerMapID and bm.mapID ~= playerMapID then
            matchZone = false
        end

        local matchSearch = true
        if q ~= "" then
            local titleMatch = bm.title and strlower(bm.title):find(q, 1, true)
            local noteMatch = bm.note and strlower(bm.note):find(q, 1, true)
            local zoneName = strlower(ns.GetZoneName(bm.mapID))
            local zoneMatch = zoneName:find(q, 1, true)
            matchSearch = titleMatch or noteMatch or zoneMatch
        end

        if matchZone and matchSearch then
            table.insert(result, bm)
        end
    end

    table.sort(result, function(a, b)
        return (a.created or 0) > (b.created or 0)
    end)

    return result
end

function ns.RefreshManagerList()
    if not managerFrame or not managerFrame:IsShown() then return end

    local bookmarks = FilteredBookmarks()
    local scrollChild = managerFrame.scrollChild
    local rowHeight = 44
    local startY = 0

    for i, bm in ipairs(bookmarks) do
        local row = listRows[i]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, BackdropTemplateMixin and "BackdropTemplate" or nil)
            row:SetSize(380, rowHeight)
            if row.SetBackdrop then
                row:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 10, edgeSize = 10,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                row:SetBackdropColor(0.12, 0.12, 0.16, 0.8)
                row:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.7)
            end

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(28, 28)
            icon:SetPoint("LEFT", 8, 0)
            row.icon = icon

            -- Title fontstring
            local title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
            title:SetWidth(180)
            title:SetJustifyH("LEFT")
            title:SetWordWrap(false)
            row.title = title

            -- Subtitle (Zone & Coords)
            local subtitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            subtitle:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
            subtitle:SetWidth(180)
            subtitle:SetJustifyH("LEFT")
            subtitle:SetWordWrap(false)
            subtitle:SetTextColor(0.7, 0.7, 0.7)
            row.subtitle = subtitle

            -- Track Button
            local btnTrack = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            btnTrack:SetSize(42, 20)
            btnTrack:SetPoint("RIGHT", -106, 0)
            btnTrack:SetText("Track")
            btnTrack:SetScript("OnClick", function()
                if row.bm then ns.TrackBookmark(row.bm) end
            end)
            row.btnTrack = btnTrack

            -- Show Map Button
            local btnMap = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            btnMap:SetSize(36, 20)
            btnMap:SetPoint("LEFT", btnTrack, "RIGHT", 3, 0)
            btnMap:SetText("Map")
            btnMap:SetScript("OnClick", function()
                if row.bm and row.bm.mapID then
                    if not WorldMapFrame:IsShown() then ToggleWorldMap() end
                    if WorldMapFrame and WorldMapFrame.SetMapID then
                        WorldMapFrame:SetMapID(row.bm.mapID)
                    end
                end
            end)
            row.btnMap = btnMap

            -- Edit Button
            local btnEdit = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            btnEdit:SetSize(32, 20)
            btnEdit:SetPoint("LEFT", btnMap, "RIGHT", 3, 0)
            btnEdit:SetText("Edit")
            btnEdit:SetScript("OnClick", function()
                if row.bm then ns.ShowEditDialog(row.bm) end
            end)
            row.btnEdit = btnEdit

            -- Delete Button
            local btnDel = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            btnDel:SetSize(26, 20)
            btnDel:SetPoint("LEFT", btnEdit, "RIGHT", 3, 0)
            btnDel:SetText("X")
            btnDel:SetScript("OnClick", function()
                if row.bm then ns.DeleteBookmark(row.bm.id) end
            end)
            row.btnDel = btnDel

            listRows[i] = row
        end

        row.bm = bm
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * (rowHeight + 4)))

        local iconInfo = ns.GetIconInfo(bm.iconKey)
        row.icon:SetTexture(iconInfo.texture)
        local color = bm.color or iconInfo.color
        if color then
            row.icon:SetVertexColor(color[1], color[2], color[3], 1)
        else
            row.icon:SetVertexColor(1, 1, 1, 1)
        end

        row.title:SetText(bm.title or "Bookmark")
        row.subtitle:SetText(string.format("%s (%s)", ns.GetZoneName(bm.mapID), ns.FormatCoords(bm.x, bm.y)))
        row:Show()
    end

    for i = #bookmarks + 1, #listRows do
        listRows[i]:Hide()
    end

    scrollChild:SetHeight(math.max(1, #bookmarks * (rowHeight + 4)))
    managerFrame.statusText:SetText(string.format("Total Bookmarks: %d", #ns.GetAllBookmarks()))
end

local function CreateManagerFrame()
    if managerFrame then return managerFrame end

    local mf = CreateFrame("Frame", "TimelessForever_BookmarksManager", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    mf:SetSize(440, 500)
    mf:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    mf:SetFrameStrata("TOOLTIP")
    mf:SetFrameLevel(400)
    mf:SetClampedToScreen(true)
    mf:EnableMouse(true)
    mf:SetMovable(true)
    mf:RegisterForDrag("LeftButton")
    mf:SetScript("OnDragStart", mf.StartMoving)
    mf:SetScript("OnDragStop", mf.StopMovingOrSizing)
    SetBackdrop(mf, 0.98, 1.0)

    -- Header
    local title = mf:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cff00ccffTimelessForever|r Bookmarks")
    title:SetTextColor(1, 0.82, 0)

    -- Close Button
    local close = CreateFrame("Button", nil, mf, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() mf:Hide() end)

    -- Search Box
    local search = CreateFrame("EditBox", nil, mf, "InputBoxTemplate")
    search:SetSize(180, 20)
    search:SetPoint("TOPLEFT", 16, -38)
    search:SetAutoFocus(false)
    search:SetText("")
    search:HookScript("OnTextChanged", function(self)
        searchQuery = self:GetText()
        ns.RefreshManagerList()
    end)
    local sLbl = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sLbl:SetPoint("LEFT", 4, 0)
    sLbl:SetText("Search...")
    search:HookScript("OnEditFocusGained", function() sLbl:Hide() end)
    search:HookScript("OnEditFocusLost", function(self) if self:GetText() == "" then sLbl:Show() end end)
    mf.searchBox = search

    -- Filter Zone Checkbox
    local cbZone = CreateFrame("CheckButton", nil, mf, "UICheckButtonTemplate")
    cbZone:SetSize(22, 22)
    cbZone:SetPoint("LEFT", search, "RIGHT", 14, 0)
    cbZone.text:SetText("Current Zone")
    cbZone.text:SetFontObject("GameFontNormalSmall")
    cbZone:SetScript("OnClick", function(self)
        filterZoneOnly = self:GetChecked()
        ns.RefreshManagerList()
    end)
    mf.cbZone = cbZone

    -- Add current location button
    local btnAddHere = CreateFrame("Button", nil, mf, "UIPanelButtonTemplate")
    btnAddHere:SetSize(60, 22)
    btnAddHere:SetPoint("TOPRIGHT", -16, -37)
    btnAddHere:SetText("+ Here")
    btnAddHere:SetScript("OnClick", function()
        if ns.HBD then
            local x, y, mapID = ns.HBD:GetPlayerZonePosition()
            if mapID and x and y then
                ns.ShowCreateDialog(mapID, x, y)
            else
                print("|cff00ccff[Bookmarks]|r Could not determine current player position.")
            end
        end
    end)

    -- Scroll Frame for list
    local scrollFrame = CreateFrame("ScrollFrame", "TimelessForever_BookmarksScrollFrame", mf, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -66)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 40)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(380, 1)
    scrollFrame:SetScrollChild(scrollChild)
    mf.scrollChild = scrollChild

    -- Status bar at bottom
    local status = mf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", 18, 16)
    status:SetTextColor(0.7, 0.7, 0.7)
    mf.statusText = status

    -- Settings Toggle Button (Cycle Right-Click behavior)
    local btnSettings = CreateFrame("Button", nil, mf, "UIPanelButtonTemplate")
    btnSettings:SetSize(130, 22)
    btnSettings:SetPoint("BOTTOMRIGHT", -16, 12)
    
    local function UpdateSettingsBtnText()
        local b = ns.db and ns.db.settings and ns.db.settings.clickBehavior or "direct"
        local bLabel = (b == "direct" and "Direct") or (b == "menu" and "Menu") or "Shift-Click"
        btnSettings:SetText("Click: " .. bLabel)
    end
    UpdateSettingsBtnText()

    btnSettings:SetScript("OnClick", function()
        if not ns.db or not ns.db.settings then return end
        local curr = ns.db.settings.clickBehavior or "direct"
        if curr == "direct" then
            ns.db.settings.clickBehavior = "menu"
        elseif curr == "menu" then
            ns.db.settings.clickBehavior = "modifier"
        else
            ns.db.settings.clickBehavior = "direct"
        end
        UpdateSettingsBtnText()
        print("|cff00ccff[Bookmarks]|r Map click behavior set to: |cffffffff" .. ns.db.settings.clickBehavior .. "|r")
    end)
    btnSettings:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Right-Click Behavior", 1, 0.82, 0)
        GameTooltip:AddLine("Click to cycle between:", 1, 1, 1)
        GameTooltip:AddLine(" * Direct: Right-click directly opens Bookmark dialog (Default)", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" * Menu: Right-click shows [Add Bookmark / Zoom Out]", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" * Shift-Click: Plain right-click zooms out; Shift+Right-click bookmarks", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btnSettings:SetScript("OnLeave", function() GameTooltip:Hide() end)

    mf:SetScript("OnShow", function()
        ns.RefreshManagerList()
    end)

    managerFrame = mf
    return mf
end

function ns.ToggleManager()
    local mf = CreateManagerFrame()
    if mf:IsShown() then
        mf:Hide()
    else
        mf:Show()
    end
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

SLASH_TFBOOKMARKS1 = "/bm"
SLASH_TFBOOKMARKS2 = "/bookmark"
SLASH_TFBOOKMARKS3 = "/bookmarks"
SLASH_TFBOOKMARKS4 = "/tfbm"

SlashCmdList["TFBOOKMARKS"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = strlower(cmd or "")

    if cmd == "add" then
        if ns.HBD then
            local x, y, mapID = ns.HBD:GetPlayerZonePosition()
            if mapID and x and y then
                ns.ShowCreateDialog(mapID, x, y)
                if arg and strtrim(arg) ~= "" and dialog and dialog.ebTitle then
                    dialog.ebTitle:SetText(strtrim(arg))
                end
            else
                print("|cff00ccff[Bookmarks]|r Could not determine your location.")
            end
        end
    elseif cmd == "clear" then
        if ns.db then
            wipe(ns.db.bookmarks)
            ns.RefreshPins()
            ns.RefreshManagerList()
            print("|cff00ccff[Bookmarks]|r All bookmarks cleared.")
        end
    elseif cmd == "help" then
        print("|cff00ccffTimelessForever Bookmarks Commands:|r")
        print("  |cffffffff/bm|r - Open the Bookmarks Manager")
        print("  |cffffffff/bm add [label]|r - Add bookmark at your current location")
        print("  |cffffffff/bm clear|r - Delete all bookmarks")
        print("  |cffffffffRight-click|r anywhere on the map to place a bookmark")
    else
        ns.ToggleManager()
    end
end

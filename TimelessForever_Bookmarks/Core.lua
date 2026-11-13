local addonName, ns = ...

-- Libraries
local LibStub = _G.LibStub
local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
local HBDPins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)

ns.PIN_REF = "TimelessForever_Bookmarks"
ns.HBD = HBD
ns.HBDPins = HBDPins

-- Events frame
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

local function InitDB()
    if not TimelessForever_BookmarksDB then
        TimelessForever_BookmarksDB = {}
    end
    local db = TimelessForever_BookmarksDB
    if not db.bookmarks then db.bookmarks = {} end
    if not db.nextId then db.nextId = 1 end
    if not db.settings then
        db.settings = {
            showOnMinimap = true,
            minimapPinScale = 1.0,
            worldmapPinScale = 1.2,
            clickBehavior = "direct", -- "direct" (instantly open dialog), "menu", "modifier"
            showMapButton = true,
        }
    else
        -- Default to "direct" so right-clicking the map opens the dialog immediately
        if db.settings.clickBehavior == "menu" then
            db.settings.clickBehavior = "direct"
        end
    end
    ns.db = db
end

-- Helper: Get zone name
function ns.GetZoneName(mapID)
    if not mapID then return "Unknown Zone" end
    local info = C_Map and C_Map.GetMapInfo(mapID)
    return info and info.name or ("Map " .. tostring(mapID))
end

-- Format coords
function ns.FormatCoords(x, y)
    if not x or not y then return "--, --" end
    return string.format("%.1f, %.1f", x * 100, y * 100)
end

-- Round coord
local function Round(v)
    return math.floor((v or 0) * 1e4 + 0.5) / 1e4
end

--------------------------------------------------------------------------------
-- Bookmark Data Operations
--------------------------------------------------------------------------------

function ns.GetAllBookmarks()
    return ns.db and ns.db.bookmarks or {}
end

function ns.GetBookmarksForMap(mapID)
    local results = {}
    if not ns.db or not ns.db.bookmarks then return results end
    for _, bm in ipairs(ns.db.bookmarks) do
        if bm.mapID == mapID then
            table.insert(results, bm)
        end
    end
    return results
end

function ns.GetBookmark(id)
    if not ns.db or not ns.db.bookmarks then return nil end
    for _, bm in ipairs(ns.db.bookmarks) do
        if bm.id == id then return bm end
    end
    return nil
end

function ns.AddBookmark(mapID, x, y, title, iconKey, note, color)
    if not ns.db then return end
    title = strtrim(title or "")
    if title == "" then
        title = ns.GetZoneName(mapID) .. " Marker"
    end

    local bm = {
        id = ns.db.nextId,
        mapID = mapID,
        x = Round(x),
        y = Round(y),
        title = title,
        iconKey = iconKey or ns.DEFAULT_ICON_KEY,
        note = strtrim(note or ""),
        color = color,
        created = time(),
    }
    ns.db.nextId = ns.db.nextId + 1
    table.insert(ns.db.bookmarks, bm)

    ns.RefreshPins()
    if ns.RefreshManagerList then ns.RefreshManagerList() end

    print(string.format("|cff00ccff[Bookmarks]|r Saved: |cffffffff%s|r (%s at %s)", 
        bm.title, ns.GetZoneName(bm.mapID), ns.FormatCoords(bm.x, bm.y)))
    return bm
end

function ns.UpdateBookmark(id, title, iconKey, note, color)
    local bm = ns.GetBookmark(id)
    if not bm then return end
    if title and strtrim(title) ~= "" then bm.title = strtrim(title) end
    if iconKey then bm.iconKey = iconKey end
    if note ~= nil then bm.note = strtrim(note) end
    if color ~= nil then bm.color = color end

    ns.RefreshPins()
    if ns.RefreshManagerList then ns.RefreshManagerList() end
    print(string.format("|cff00ccff[Bookmarks]|r Updated bookmark: |cffffffff%s|r", bm.title))
end

function ns.DeleteBookmark(id)
    if not ns.db or not ns.db.bookmarks then return end
    for i, bm in ipairs(ns.db.bookmarks) do
        if bm.id == id then
            local title = bm.title
            table.remove(ns.db.bookmarks, i)
            ns.RefreshPins()
            if ns.RefreshManagerList then ns.RefreshManagerList() end
            print(string.format("|cff00ccff[Bookmarks]|r Removed bookmark: |cffffffff%s|r", title))
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- Waypoint / SuperTracking
--------------------------------------------------------------------------------

function ns.TrackBookmark(bm)
    if not bm then return end
    local mapID, x, y = bm.mapID, bm.x, bm.y
    local name = bm.title or ns.GetZoneName(mapID)

    local setBlizz = false
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        if not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(mapID) then
            local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
            local ok = pcall(C_Map.SetUserWaypoint, point)
            if ok then
                setBlizz = true
                if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
                end
            end
        end
    end

    local tomtom = _G.TomTom
    if tomtom and tomtom.AddWaypoint then
        pcall(tomtom.AddWaypoint, tomtom, mapID, x, y, { title = name, from = "TimelessForever_Bookmarks" })
    end

    print(string.format("|cff00ccff[Bookmarks]|r Tracking: |cffffffff%s|r (%s at %s)",
        name, ns.GetZoneName(mapID), ns.FormatCoords(x, y)))
end

--------------------------------------------------------------------------------
-- Pin Frames & Rendering
--------------------------------------------------------------------------------

local worldmapPinPool = {}
local minimapPinPool = {}
local activeWorldPins = {}
local activeMiniPins = {}

local function OnPinEnter(pin)
    local bm = pin.bookmark
    if not bm then return end

    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    local iconInfo = ns.GetIconInfo(bm.iconKey)
    local iconTex = iconInfo and iconInfo.texture or "Interface\\Minimap\\Ping\\ping5"

    GameTooltip:AddLine(string.format("|T%s:18:18:0:0|t  %s", iconTex, bm.title or "Bookmark"), 1, 0.82, 0)
    GameTooltip:AddLine(string.format("%s (%s)", ns.GetZoneName(bm.mapID), ns.FormatCoords(bm.x, bm.y)), 0.8, 0.8, 0.8)

    if bm.note and bm.note ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(bm.note, 1, 1, 1, true)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Set Waypoint / Track", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff00ff00Right-Click:|r Edit Bookmark", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff00ff00Shift-Click:|r Share in Chat", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff00ff00Alt-Click:|r Delete Bookmark", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function OnPinLeave(pin)
    if GameTooltip:IsOwned(pin) then
        GameTooltip:Hide()
    end
end

local function OnPinClick(pin, button)
    local bm = pin.bookmark
    if not bm then return end

    if IsAltKeyDown() then
        ns.DeleteBookmark(bm.id)
        if GameTooltip:IsOwned(pin) then GameTooltip:Hide() end
        return
    end

    if button == "LeftButton" then
        if IsShiftKeyDown() then
            local chat = (ChatFrameUtil and ChatFrameUtil.GetActiveWindow) or _G.ChatEdit_GetActiveWindow
            local text = string.format("[Bookmark: %s - %s (%s)]", bm.title, ns.GetZoneName(bm.mapID), ns.FormatCoords(bm.x, bm.y))
            if chat and chat() and chat():IsShown() then
                chat():Insert(text)
            else
                local eb = LAST_ACTIVE_CHAT_EDIT_BOX or DEFAULT_CHAT_FRAME.editBox
                if eb and eb:IsShown() then
                    eb:Insert(text)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Bookmarks]|r " .. text)
                end
            end
        else
            ns.TrackBookmark(bm)
        end
    elseif button == "RightButton" then
        ns.ShowEditDialog(bm)
        if GameTooltip:IsOwned(pin) then GameTooltip:Hide() end
    end
end

local function CreatePinFrame(isMinimap)
    local pin = CreateFrame("Button", nil, UIParent)
    pin:SetSize(isMinimap and 18 or 24, isMinimap and 18 or 24)
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    pin.icon = icon

    local glow = pin:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints()
    glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    glow:SetBlendMode("ADD")
    pin.glow = glow

    pin:SetScript("OnEnter", OnPinEnter)
    pin:SetScript("OnLeave", OnPinLeave)
    pin:SetScript("OnClick", OnPinClick)

    return pin
end

function ns.RefreshPins()
    if not HBDPins then return end

    HBDPins:RemoveAllWorldMapIcons(ns.PIN_REF)
    HBDPins:RemoveAllMinimapIcons(ns.PIN_REF)

    for _, p in ipairs(activeWorldPins) do p:Hide(); table.insert(worldmapPinPool, p) end
    wipe(activeWorldPins)

    for _, p in ipairs(activeMiniPins) do p:Hide(); table.insert(minimapPinPool, p) end
    wipe(activeMiniPins)

    if not ns.db or not ns.db.bookmarks then return end

    local worldScale = (ns.db.settings and ns.db.settings.worldmapPinScale) or 1.2
    local miniScale = (ns.db.settings and ns.db.settings.minimapPinScale) or 1.0
    local showMini = ns.db.settings and ns.db.settings.showOnMinimap ~= false

    for _, bm in ipairs(ns.db.bookmarks) do
        local iconInfo = ns.GetIconInfo(bm.iconKey)
        local tex = iconInfo and iconInfo.texture or "Interface\\Minimap\\Ping\\ping5"
        local color = bm.color or (iconInfo and iconInfo.color)

        -- World Map pin
        local wPin = table.remove(worldmapPinPool) or CreatePinFrame(false)
        wPin.bookmark = bm
        wPin:SetSize(24 * worldScale, 24 * worldScale)
        wPin.icon:SetTexture(tex)
        if color then
            wPin.icon:SetVertexColor(color[1], color[2], color[3], 1)
        else
            wPin.icon:SetVertexColor(1, 1, 1, 1)
        end
        wPin:Show()
        table.insert(activeWorldPins, wPin)

        HBDPins:AddWorldMapIconMap(ns.PIN_REF, wPin, bm.mapID, bm.x, bm.y, 2)

        -- Minimap pin
        if showMini then
            local mPin = table.remove(minimapPinPool) or CreatePinFrame(true)
            mPin.bookmark = bm
            mPin:SetSize(18 * miniScale, 18 * miniScale)
            mPin.icon:SetTexture(tex)
            if color then
                mPin.icon:SetVertexColor(color[1], color[2], color[3], 1)
            else
                mPin.icon:SetVertexColor(1, 1, 1, 1)
            end
            mPin:Show()
            table.insert(activeMiniPins, mPin)

            HBDPins:AddMinimapIconMap(ns.PIN_REF, mPin, bm.mapID, bm.x, bm.y, true)
        end
    end
end

--------------------------------------------------------------------------------
-- Robust Map Coordinates Calculation (OpenMap, Leatrix, Ellesmere, Blizzard)
--------------------------------------------------------------------------------

function ns.GetCursorMapPosition()
    local mapID, x, y

    -- Priority 1: OpenMap stitched world coordinates
    if OpenMapAPI and OpenMapAPI.IsStitched and OpenMapAPI.IsStitched() then
        local u, v = OpenMapAPI.CursorPosition()
        if u and v then
            local zID = OpenMapAPI.MapAt(u, v)
            if zID then
                local zx, zy = OpenMapAPI.MapFromWorld(zID, u, v)
                if zx and zy and zx >= 0 and zx <= 1 and zy >= 0 and zy <= 1 then
                    mapID, x, y = zID, zx, zy
                end
            end
        end
    end

    -- Priority 2: WorldMapFrame GetNormalizedCursorPosition
    if not mapID and WorldMapFrame and WorldMapFrame:IsShown() then
        local curMapID = WorldMapFrame:GetMapID()
        if curMapID then
            local curX, curY = WorldMapFrame:GetNormalizedCursorPosition()
            if curX and curY and curX >= 0 and curX <= 1 and curY >= 0 and curY <= 1 then
                if C_Map and C_Map.GetMapInfoAtPosition then
                    local sub = C_Map.GetMapInfoAtPosition(curMapID, curX, curY)
                    if sub and sub.mapID and sub.mapID ~= curMapID then
                        local l, r, t, b = C_Map.GetMapRectOnMap(sub.mapID, curMapID)
                        if l and r and t and b and r > l and b > t then
                            local sx = (curX - l) / (r - l)
                            local sy = (curY - t) / (b - t)
                            if sx >= 0 and sx <= 1 and sy >= 0 and sy <= 1 then
                                curMapID = sub.mapID
                                curX = sx
                                curY = sy
                            end
                        end
                    end
                end
                mapID, x, y = curMapID, curX, curY
            end
        end
    end

    -- Priority 3: Direct Canvas pixel calculation
    if not mapID and WorldMapFrame and WorldMapFrame:IsShown() then
        local curMapID = WorldMapFrame:GetMapID()
        local canvas = WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
        if curMapID and canvas then
            local cursorX, cursorY = GetCursorPosition()
            local scale = canvas:GetEffectiveScale()
            local left = canvas:GetLeft()
            local top = canvas:GetTop()
            local width = canvas:GetWidth()
            local height = canvas:GetHeight()
            if left and top and width and height and width > 0 and height > 0 then
                local cx = (cursorX / scale - left) / width
                local cy = (top - cursorY / scale) / height
                if cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1 then
                    mapID, x, y = curMapID, cx, cy
                end
            end
        end
    end

    -- Priority 4: Player current position fallback
    if not mapID and ns.HBD then
        local px, py, pMapID = ns.HBD:GetPlayerZonePosition()
        if pMapID and px and py then
            mapID, x, y = pMapID, px, py
        end
    end

    return mapID, x, y
end

--------------------------------------------------------------------------------
-- Right Click Interception & Drag Detection
--------------------------------------------------------------------------------

local mouseDownInfo = nil
local lastClickHandledTime = 0

function ns.HandleMapRightClick()
    local mapID, x, y = ns.GetCursorMapPosition()
    if not mapID or not x or not y then
        return false
    end

    local settings = ns.db and ns.db.settings or {}
    local behavior = settings.clickBehavior or "direct"

    -- Shift + Right Click ALWAYS directly opens create dialog
    if IsShiftKeyDown() then
        ns.ShowCreateDialog(mapID, x, y)
        lastClickHandledTime = GetTime()
        return true
    end

    if behavior == "direct" then
        ns.ShowCreateDialog(mapID, x, y)
        lastClickHandledTime = GetTime()
        return true
    elseif behavior == "menu" then
        ns.ShowContextMenu(mapID, x, y)
        lastClickHandledTime = GetTime()
        return true
    elseif behavior == "modifier" then
        -- Only with modifier (handled above by Shift)
        return false
    end

    ns.ShowCreateDialog(mapID, x, y)
    lastClickHandledTime = GetTime()
    return true
end

local hooked = false
local function HookWorldMap()
    if hooked or not WorldMapFrame then return end
    hooked = true

    -- Hook ScrollContainer for drag detection and backup mouse-up trigger
    if WorldMapFrame.ScrollContainer then
        WorldMapFrame.ScrollContainer:HookScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                local cx, cy = GetCursorPosition()
                mouseDownInfo = { x = cx, y = cy, time = GetTime() }
            end
        end)

        WorldMapFrame.ScrollContainer:HookScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                C_Timer.After(0.01, function()
                    if (GetTime() - lastClickHandledTime) < 0.15 then
                        mouseDownInfo = nil
                        return
                    end
                    if mouseDownInfo then
                        local cx, cy = GetCursorPosition()
                        local dist = math.abs(cx - mouseDownInfo.x) + math.abs(cy - mouseDownInfo.y)
                        mouseDownInfo = nil
                        if dist <= 14 then
                            ns.HandleMapRightClick()
                        end
                    end
                end)
            else
                mouseDownInfo = nil
            end
        end)
    end

    -- Hook WorldMapFrame.OnCanvasClicked
    if WorldMapFrame.OnCanvasClicked then
        local orig_OnCanvasClicked = WorldMapFrame.OnCanvasClicked
        WorldMapFrame.OnCanvasClicked = function(self, button, cursorX, cursorY)
            if button == "RightButton" then
                local handled = ns.HandleMapRightClick()
                if handled then
                    mouseDownInfo = nil
                    return
                end
            end
            return orig_OnCanvasClicked(self, button, cursorX, cursorY)
        end
    end

    -- Also insert at front of canvasClickHandlers
    if WorldMapFrame.canvasClickHandlers then
        table.insert(WorldMapFrame.canvasClickHandlers, 1, function(self, button, cursorX, cursorY)
            if button == "RightButton" then
                local handled = ns.HandleMapRightClick()
                if handled then
                    mouseDownInfo = nil
                    return true
                end
            end
            return false
        end)
    end

    -- Refresh pins when map changes
    if WorldMapFrame.RegisterCallback then
        pcall(WorldMapFrame.RegisterCallback, WorldMapFrame, "OnMapChanged", function()
            C_Timer.After(0.05, ns.RefreshPins)
        end)
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
    elseif event == "PLAYER_LOGIN" then
        InitDB()
        HookWorldMap()
        C_Timer.After(0.5, HookWorldMap)
        C_Timer.After(1.0, ns.RefreshPins)
        print("|cff00ccffTimelessForever Bookmarks|r ready! Right-click anywhere on the map to add a bookmark.")
    end
end)

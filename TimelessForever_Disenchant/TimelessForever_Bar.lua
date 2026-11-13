-- =========================================================================
-- TimelessForever_Bar
-- Unified Utility Button Bar for TimelessForever Suite Modules
-- Groups: Nightlight, Disenchant, Fishing
-- =========================================================================

local addonName, addonTable = ...

if _G.TimelessForever_ButtonBar then
    return
end

local Bar = {}
_G.TimelessForever_ButtonBar = Bar
_G.TF_ButtonBar = Bar

local BUTTON_SIZE = 36
local BUTTON_GAP = 5
local PADDING_H = 6
local PADDING_V = 6

-- Default configuration
local defaults = {
    pos = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -180, y = 220 },
    orientation = "HORIZONTAL", -- "HORIZONTAL" or "VERTICAL"
    locked = false,
    hidden = false,
}

local function InitDB()
    if type(_G.TimelessForever_ButtonBarDB) ~= "table" then
        _G.TimelessForever_ButtonBarDB = {}
    end
    for k, v in pairs(defaults) do
        if _G.TimelessForever_ButtonBarDB[k] == nil then
            if type(v) == "table" then
                _G.TimelessForever_ButtonBarDB[k] = CopyTable and CopyTable(v) or { point = v.point, relPoint = v.relPoint, x = v.x, y = v.y }
            else
                _G.TimelessForever_ButtonBarDB[k] = v
            end
        end
    end
end

-- Create the master Bar frame
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local barFrame = CreateFrame("Frame", "TimelessForever_ButtonBarFrame", UIParent, backdropTemplate)
barFrame:SetSize(PADDING_H * 2 + BUTTON_SIZE * 3 + BUTTON_GAP * 2, PADDING_V * 2 + BUTTON_SIZE)
barFrame:SetFrameStrata("MEDIUM")
barFrame:SetFrameLevel(50)
barFrame:SetClampedToScreen(true)
barFrame:SetMovable(true)
barFrame:EnableMouse(true)
barFrame:RegisterForDrag("LeftButton")

-- Styling
if barFrame.SetBackdrop then
    barFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    barFrame:SetBackdropColor(0.06, 0.07, 0.10, 0.88)
    barFrame:SetBackdropBorderColor(0.20, 0.60, 0.90, 0.65)
else
    local bg = barFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.07, 0.10, 0.88)
end

-- Hover title
local barTitle = barFrame:CreateFontString(nil, "OVERLAY")
barTitle:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
barTitle:SetPoint("BOTTOMLEFT", barFrame, "TOPLEFT", 2, 3)
barTitle:SetTextColor(0.20, 0.75, 1.0, 0.9)
barTitle:SetText("Timeless Bar")
barTitle:Hide()

barFrame:SetScript("OnEnter", function(self)
    if not (_G.TimelessForever_ButtonBarDB and _G.TimelessForever_ButtonBarDB.locked) then
        barTitle:Show()
    end
end)

barFrame:SetScript("OnLeave", function(self)
    if not self.isDragging then
        barTitle:Hide()
    end
end)

Bar.buttons = {}
Bar.frame = barFrame

function Bar:SavePosition()
    local point, _, relPoint, x, y = barFrame:GetPoint()
    InitDB()
    _G.TimelessForever_ButtonBarDB.pos = {
        point = point or defaults.pos.point,
        relPoint = relPoint or defaults.pos.relPoint,
        x = x or defaults.pos.x,
        y = y or defaults.pos.y,
    }
end

function Bar:RestorePosition()
    InitDB()
    barFrame:ClearAllPoints()
    local pos = _G.TimelessForever_ButtonBarDB.pos or defaults.pos
    barFrame:SetPoint(pos.point or "BOTTOMRIGHT", UIParent, pos.relPoint or "BOTTOMRIGHT", pos.x or -180, pos.y or 220)
    if _G.TimelessForever_ButtonBarDB.hidden then
        barFrame:Hide()
    end
end

barFrame:SetScript("OnDragStart", function(self)
    InitDB()
    if _G.TimelessForever_ButtonBarDB.locked then return end
    self:StartMoving()
    self.isDragging = true
    barTitle:Show()
end)

barFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self.isDragging = false
    barTitle:Hide()
    Bar:SavePosition()
end)

function Bar:RegisterButton(id, button, order, width, height)
    if not button then return end
    width = width or BUTTON_SIZE
    height = height or BUTTON_SIZE

    button:SetParent(barFrame)
    button:SetSize(width, height)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(barFrame:GetFrameLevel() + 5)

    Bar.buttons[id] = {
        id = id,
        button = button,
        order = order or 10,
        width = width,
        height = height,
    }

    Bar:UpdateLayout()

    if not button.tfBarHooked then
        button:HookScript("OnShow", function() Bar:UpdateLayout() end)
        button:HookScript("OnHide", function() Bar:UpdateLayout() end)
        button.tfBarHooked = true
    end
end

function Bar:UpdateLayout()
    InitDB()
    if _G.TimelessForever_ButtonBarDB.hidden then
        barFrame:Hide()
        return
    end

    local ordered = {}
    for id, data in pairs(Bar.buttons) do
        if data.button and (data.button:IsShown() or data.button.IsShown == nil) then
            table.insert(ordered, data)
        end
    end
    table.sort(ordered, function(a, b) return a.order < b.order end)

    local count = #ordered
    if count == 0 then
        barFrame:Hide()
        return
    end

    barFrame:Show()
    local isVertical = (_G.TimelessForever_ButtonBarDB.orientation == "VERTICAL")

    if isVertical then
        local offsetY = -PADDING_V
        local maxWidth = BUTTON_SIZE
        for i, data in ipairs(ordered) do
            local btn = data.button
            btn:ClearAllPoints()
            btn:SetPoint("TOP", barFrame, "TOP", 0, offsetY)
            offsetY = offsetY - data.height - BUTTON_GAP
            if data.width > maxWidth then maxWidth = data.width end
        end
        local totalHeight = -offsetY - BUTTON_GAP + PADDING_V
        local totalWidth = maxWidth + PADDING_H * 2
        barFrame:SetSize(totalWidth, totalHeight)
    else
        local offsetX = PADDING_H
        local maxHeight = BUTTON_SIZE
        for i, data in ipairs(ordered) do
            local btn = data.button
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", barFrame, "LEFT", offsetX, 0)
            offsetX = offsetX + data.width + BUTTON_GAP
            if data.height > maxHeight then maxHeight = data.height end
        end
        local totalWidth = offsetX - BUTTON_GAP + PADDING_H
        local totalHeight = maxHeight + PADDING_V * 2
        barFrame:SetSize(totalWidth, totalHeight)
    end
end

-- Suite Hub Settings Integration
local function RegisterSuiteTab()
    local suite = _G.TimelessForeverSuite or _G.TimelessSuite or _G.ForeverSuite
    if suite and suite.RegisterModuleTab then
        local barArgs = {
            header = {
                name = "|TInterface\\Icons\\INV_Misc_Gear_01:14:14:0:0|t |cff00ccffTimeless|r Button Bar",
                type = "header",
                order = 1,
            },
            desc = {
                name = "Unified floating action bar grouping Nightlight, Disenchant, and Fishing buttons together.\n\n" ..
                       "|cff00ff00Shift + Left-Click & Drag:|r Move the bar anywhere on screen.\n" ..
                       "|cff00ff00/tfbar:|r Toggle show/hide the bar.\n" ..
                       "|cff00ff00/tfbar reset:|r Reset bar position to default.\n",
                type = "description",
                order = 2,
                fontSize = "medium",
            },
            layoutHeader = {
                name = "Bar Layout & Controls",
                type = "header",
                order = 3,
            },
            orientation = {
                name = "Orientation",
                desc = "Choose whether buttons are arranged horizontally in a row or vertically in a column.",
                type = "select",
                order = 4,
                values = {
                    ["HORIZONTAL"] = "Horizontal Row",
                    ["VERTICAL"] = "Vertical Column",
                },
                get = function()
                    InitDB()
                    return _G.TimelessForever_ButtonBarDB.orientation or "HORIZONTAL"
                end,
                set = function(_, val)
                    InitDB()
                    _G.TimelessForever_ButtonBarDB.orientation = val
                    Bar:UpdateLayout()
                end,
            },
            locked = {
                name = "Lock Bar Position",
                desc = "Locks the bar in place so it cannot be moved by accident.",
                type = "toggle",
                order = 5,
                get = function()
                    InitDB()
                    return _G.TimelessForever_ButtonBarDB.locked or false
                end,
                set = function(_, val)
                    InitDB()
                    _G.TimelessForever_ButtonBarDB.locked = val
                end,
            },
            hidden = {
                name = "Hide Entire Bar",
                desc = "Hides the floating bar and all grouped buttons.",
                type = "toggle",
                order = 6,
                get = function()
                    InitDB()
                    return _G.TimelessForever_ButtonBarDB.hidden or false
                end,
                set = function(_, val)
                    InitDB()
                    _G.TimelessForever_ButtonBarDB.hidden = val
                    if val then
                        barFrame:Hide()
                    else
                        barFrame:Show()
                        Bar:UpdateLayout()
                    end
                end,
            },
            resetBtn = {
                name = "Reset Position to Default",
                desc = "Resets the button bar position back to the default bottom-right location.",
                type = "execute",
                order = 7,
                func = function()
                    InitDB()
                    _G.TimelessForever_ButtonBarDB.pos = CopyTable and CopyTable(defaults.pos) or { point = defaults.pos.point, relPoint = defaults.pos.relPoint, x = defaults.pos.x, y = defaults.pos.y }
                    _G.TimelessForever_ButtonBarDB.hidden = false
                    Bar:RestorePosition()
                    Bar:UpdateLayout()
                end,
            },
        }
        suite:RegisterModuleTab("bar", "Button Bar", 8, barArgs)
    end
end

-- Slash commands
local function SlashHandler(msg)
    local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
    InitDB()
    if cmd == "reset" then
        _G.TimelessForever_ButtonBarDB.pos = CopyTable and CopyTable(defaults.pos) or { point = defaults.pos.point, relPoint = defaults.pos.relPoint, x = defaults.pos.x, y = defaults.pos.y }
        _G.TimelessForever_ButtonBarDB.hidden = false
        Bar:RestorePosition()
        Bar:UpdateLayout()
        print("|cff00ccff[Timeless Bar]|r Position reset to default.")
    elseif cmd == "lock" then
        _G.TimelessForever_ButtonBarDB.locked = true
        print("|cff00ccff[Timeless Bar]|r Bar is now |cffff4444LOCKED|r.")
    elseif cmd == "unlock" then
        _G.TimelessForever_ButtonBarDB.locked = false
        print("|cff00ccff[Timeless Bar]|r Bar is now |cff00ff00UNLOCKED|r (Shift+Drag to move).")
    elseif cmd == "vertical" or cmd == "vert" then
        _G.TimelessForever_ButtonBarDB.orientation = "VERTICAL"
        Bar:UpdateLayout()
        print("|cff00ccff[Timeless Bar]|r Layout set to |cff00ff00VERTICAL|r.")
    elseif cmd == "horizontal" or cmd == "horiz" then
        _G.TimelessForever_ButtonBarDB.orientation = "HORIZONTAL"
        Bar:UpdateLayout()
        print("|cff00ccff[Timeless Bar]|r Layout set to |cff00ff00HORIZONTAL|r.")
    elseif cmd == "toggle" or cmd == "" then
        _G.TimelessForever_ButtonBarDB.hidden = not _G.TimelessForever_ButtonBarDB.hidden
        if _G.TimelessForever_ButtonBarDB.hidden then
            barFrame:Hide()
            print("|cff00ccff[Timeless Bar]|r Bar is now |cffff4444HIDDEN|r (/tfbar to show).")
        else
            barFrame:Show()
            Bar:UpdateLayout()
            print("|cff00ccff[Timeless Bar]|r Bar is now |cff00ff00SHOWN|r.")
        end
    else
        print("|cff00ccff[Timeless Bar]|r Commands:")
        print("  |cffffd100/tfbar|r - Toggle show/hide")
        print("  |cffffd100/tfbar reset|r - Reset position to default")
        print("  |cffffd100/tfbar lock|r / |cffffd100unlock|r - Lock or unlock dragging")
        print("  |cffffd100/tfbar horizontal|r / |cffffd100vertical|r - Switch layout orientation")
    end
end

SLASH_TFBUTTONBAR1 = "/tfbar"
SLASH_TFBUTTONBAR2 = "/timelessbar"
SLASH_TFBUTTONBAR3 = "/buttonbar"
SlashCmdList["TFBUTTONBAR"] = SlashHandler

-- Event listener
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    InitDB()
    Bar:RestorePosition()
    Bar:UpdateLayout()
    RegisterSuiteTab()
end)

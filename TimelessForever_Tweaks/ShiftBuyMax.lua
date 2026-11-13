--[[
    ShiftBuyMax
    Replaces Blizzard's vendor split UI with a custom purchase popup:
      - Buy MAX (up to 900000000000000) | Buy 20 | Buy 10 | Buy 1
      - Or Set Custom Amount (editbox up to 900000000000000, stepper, slider, live cost preview)
    Compatible with Vanilla, Classic Era, Cataclysm, Dragonflight / Forever (1.60.1 / 16001), and ExtendedVendorForever.
]]

local addonName, SBM = ...

if _G.ShiftBuyMaxLoaded then return end
_G.ShiftBuyMaxLoaded = true

local MAX_STACK_SIZE = 900000000000000

local defaults = {
    enabled = true,
    showTooltip = true,
    chatFeedback = true,
}
ShiftBuyMaxDB = ShiftBuyMaxDB or {}

-- ---------------------------------------------------------------------------
-- Safe Compatibility Adapters (Dragonflight / Epoch / Vanilla / Classic)
-- ---------------------------------------------------------------------------
local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ShiftBuyMax]|r " .. tostring(msg))
    end
end

local function itemAPI(name)
    return (C_Item and C_Item[name]) or _G[name]
end

local function SafeGetMerchantItemInfo(index)
    if not index or index <= 0 then return nil end
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
        if ok and info then
            local name = info.name
            local texture = info.texture
            local available = info.numAvailable
            if info.currencyID and CurrencyContainerUtil and CurrencyContainerUtil.GetCurrencyContainerInfo then
                pcall(function()
                    name, texture, available = CurrencyContainerUtil.GetCurrencyContainerInfo(
                        info.currencyID, available, name, texture, nil)
                end)
            end
            return name, texture, info.price or 0, info.stackCount or 1, available or -1,
                info.isPurchasable, info.isUsable, info.hasExtendedCost
        end
    end
    if type(GetMerchantItemInfo) == "function" then
        local ok, name, texture, price, stackCount, numAvail, isPurchasable, isUsable, extCost = pcall(GetMerchantItemInfo, index)
        if ok then
            return name, texture, price or 0, stackCount or 1, numAvail or -1, isPurchasable, isUsable, extCost
        end
    end
    return nil
end

local function SafeGetMerchantItemLink(index)
    if not index or index <= 0 then return nil end
    if type(GetMerchantItemLink) == "function" then
        local ok, link = pcall(GetMerchantItemLink, index)
        if ok and link then return link end
    end
    if C_MerchantFrame and C_MerchantFrame.GetItemLink then
        local ok, link = pcall(C_MerchantFrame.GetItemLink, index)
        if ok and link then return link end
    end
    return nil
end

local function SafeGetItemInfo(linkOrId)
    if not linkOrId then return nil end
    local fn = itemAPI("GetItemInfo")
    if fn then
        local ok, a, b, c, d, e, f, g, h, i, j = pcall(fn, linkOrId)
        if ok and a then return a, b, c, d, e, f, g, h, i, j end
    end
    return nil
end

-- Max stack size configured to 900000000000000
local function SafeGetItemStackSize(index)
    return MAX_STACK_SIZE
end

local function SafeGetItemCount(linkOrId)
    if not linkOrId then return 0 end
    local fn = itemAPI("GetItemCount")
    if fn then
        local ok, count = pcall(fn, linkOrId, false, false, false, false)
        if ok and count then return count end
    end
    return 0
end

local function SafeGetMerchantItemCostInfo(index)
    if not index or index <= 0 then return 0 end
    if C_MerchantFrame and C_MerchantFrame.GetItemCostInfo then
        local ok, count = pcall(C_MerchantFrame.GetItemCostInfo, index)
        if ok and count then return count end
    end
    if type(GetMerchantItemCostInfo) == "function" then
        local ok, count = pcall(GetMerchantItemCostInfo, index)
        if ok and count then return count end
    end
    return 0
end

local function SafeGetMerchantItemCostItem(index, costIndex)
    if not index or index <= 0 then return nil, 0, nil, nil end
    if C_MerchantFrame and C_MerchantFrame.GetItemCostItem then
        local ok, texture, amount, link, currencyName = pcall(C_MerchantFrame.GetItemCostItem, index, costIndex)
        if ok then return texture, amount, link, currencyName end
    end
    if type(GetMerchantItemCostItem) == "function" then
        local ok, texture, amount, link, currencyName = pcall(GetMerchantItemCostItem, index, costIndex)
        if ok then return texture, amount, link, currencyName end
    end
    return nil, 0, nil, nil
end

local function SafeGetItemQualityColor(quality)
    if C_Item and C_Item.GetItemQualityColor then
        local ok, r, g, b = pcall(C_Item.GetItemQualityColor, quality or 1)
        if ok and r then return r, g, b end
    end
    if type(GetItemQualityColor) == "function" then
        local ok, r, g, b = pcall(GetItemQualityColor, quality or 1)
        if ok and r then return r, g, b end
    end
    return 1, 1, 1
end

local function SafeGetMoney()
    if type(GetMoney) == "function" then
        local ok, m = pcall(GetMoney)
        if ok and m then return m end
    end
    return 0
end

local function SafeBuyMerchantItem(index, qty)
    if not index or not qty or qty <= 0 then return end
    if type(BuyMerchantItem) == "function" then
        local ok = pcall(BuyMerchantItem, index, qty)
        if ok then return end
    end
    if C_MerchantFrame and C_MerchantFrame.BuyMerchantItem then
        pcall(C_MerchantFrame.BuyMerchantItem, index, qty)
    end
end

local function safeGetScript(frame, scriptName)
    if not frame or type(frame.GetScript) ~= "function" then return nil end
    local ok, value = pcall(frame.GetScript, frame, scriptName)
    if ok then return value end
    return nil
end

local function FormatCoins(copper)
    if not copper or copper < 0 then copper = 0 end
    copper = math.floor(copper + 0.5)
    if copper > 1e12 then
        local g = math.floor(copper / 10000)
        return string.format("|cffffd700%.0fg|r", g)
    end
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        local ok, str = pcall(C_CurrencyInfo.GetCoinTextureString, copper)
        if ok and str then return str end
    end
    if type(GetCoinTextureString) == "function" then
        local ok, str = pcall(GetCoinTextureString, copper)
        if ok and str then return str end
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    local str = ""
    if g > 0 then str = str .. string.format("|cffffd700%.0fg|r ", g) end
    if s > 0 or g > 0 then str = str .. string.format("|cffc7c7cf%ds|r ", s) end
    str = str .. string.format("|cffeda55f%dc|r", c)
    return str
end

-- Returns purchase info with max stack set to 900000000000000
local function GetItemPurchaseInfo(index, isTestMode)
    if isTestMode then
        return {
            index = 1, isTest = true,
            name = "Refreshing Spring Water",
            texture = "Interface\\Icons\\INV_Drink_07",
            link = "|cffffffff[Refreshing Spring Water]|r",
            price = 25, stackCount = 5, maxStack = MAX_STACK_SIZE,
            numAvailable = -1, maxPurchasable = MAX_STACK_SIZE, maxPossible = MAX_STACK_SIZE,
            canAffordTotal = MAX_STACK_SIZE, playerMoney = SafeGetMoney() or 100000,
            minStep = 5, color = { r=1, g=1, b=1 },
        }
    end
    if not index or index <= 0 then return nil end

    local name, texture, price, stackCount, numAvail, isPurchasable, isUsable, extCost = SafeGetMerchantItemInfo(index)
    local link = SafeGetMerchantItemLink(index)
    local maxStack = MAX_STACK_SIZE

    if not name and link then
        local itemName = SafeGetItemInfo(link)
        name = itemName
    end

    price = price or 0
    stackCount = stackCount or 1
    if stackCount < 1 then stackCount = 1 end
    numAvail = numAvail or -1

    local quality = 1
    if link then
        local _, _, q = SafeGetItemInfo(link)
        if q then quality = q end
    end
    local r, g, b = SafeGetItemQualityColor(quality)

    -- Vendor limited stock (if vendor only has e.g. 5)
    local maxPossible = maxStack
    if numAvail and numAvail > 0 then
        maxPossible = numAvail * stackCount
    elseif numAvail == 0 then
        maxPossible = 0
    end

    local playerMoney = SafeGetMoney()

    return {
        index = index,
        name = name or "Merchant Item",
        texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        link = link,
        price = price,
        stackCount = stackCount,
        maxStack = maxStack,
        numAvailable = numAvail,
        maxPurchasable = maxPossible,
        maxPossible = maxPossible,
        canAffordTotal = maxPossible,
        playerMoney = playerMoney,
        minStep = stackCount > 1 and stackCount or 1,
        color = { r=r, g=g, b=b },
    }
end

local function ExecutePurchase(index, quantity, isTest)
    if isTest then
        Print(string.format("Test: would buy %s x Refreshing Spring Water", string.format("%.0f", quantity)))
        return
    end
    if not index or not quantity or quantity <= 0 then return end

    SafeBuyMerchantItem(index, quantity)

    if ShiftBuyMaxDB.chatFeedback then
        local info = GetItemPurchaseInfo(index)
        if info then
            local costStr = ""
            if info.price > 0 then
                costStr = " for " .. FormatCoins((quantity / info.stackCount) * info.price)
            end
            Print(string.format("Bought %s x%s%s", info.link or info.name, string.format("%.0f", quantity), costStr))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Popup Frame Creation
-- ---------------------------------------------------------------------------
local popup = CreateFrame("Frame", "ShiftBuyMaxPopupFrame", UIParent,
    BackdropTemplateMixin and "BackdropTemplate" or nil)
popup:SetSize(360, 335)
popup:SetPoint("CENTER")
popup:SetFrameStrata("DIALOG")
popup:SetMovable(true)
popup:EnableMouse(true)
popup:SetClampedToScreen(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
popup:Hide()
tinsert(UISpecialFrames, "ShiftBuyMaxPopupFrame")

popup:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left=7, right=7, top=7, bottom=7 },
})

-- Header
local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
title:SetPoint("TOP", 0, -14)
title:SetText("|cffffd200ShiftBuyMax|r")

local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
xBtn:SetPoint("TOPRIGHT", -3, -3)
xBtn:SetScript("OnClick", function() popup:Hide() end)

-- Item Banner
local iconBtn = CreateFrame("Button", nil, popup)
iconBtn:SetSize(40, 40)
iconBtn:SetPoint("TOPLEFT", 18, -40)

local icon = iconBtn:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints()

local iconBorder = iconBtn:CreateTexture(nil, "OVERLAY")
iconBorder:SetSize(46, 46)
iconBorder:SetPoint("CENTER")
iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
iconBorder:SetBlendMode("ADD")
iconBorder:SetVertexColor(1, 1, 1, .4)

iconBtn:SetScript("OnEnter", function()
    if not popup.info or not popup.info.index then return end
    GameTooltip:SetOwner(iconBtn, "ANCHOR_RIGHT")
    if popup.info.isTest then
        GameTooltip:SetText("Refreshing Spring Water", 1, 1, 1)
        GameTooltip:AddLine("Restores 436 mana over 30 sec.", 1, 1, 1, true)
    else
        GameTooltip:SetMerchantItem(popup.info.index)
    end
    GameTooltip:Show()
end)
iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local nameText = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
nameText:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", 10, -2)
nameText:SetPoint("RIGHT", popup, "RIGHT", -16, 0)
nameText:SetJustifyH("LEFT")
nameText:SetWordWrap(false)

local subText = popup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
subText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
subText:SetPoint("RIGHT", popup, "RIGHT", -16, 0)
subText:SetJustifyH("LEFT")
subText:SetWordWrap(false)

local div1 = popup:CreateTexture(nil, "ARTWORK")
div1:SetHeight(1)
div1:SetPoint("TOPLEFT", 16, -90)
div1:SetPoint("TOPRIGHT", -16, -90)
div1:SetColorTexture(1, 1, 1, .15)

-- Quick-Buy Section
local quickLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
quickLabel:SetPoint("TOPLEFT", 20, -98)
quickLabel:SetText("QUICK PURCHASE")
quickLabel:SetTextColor(.9, .8, .3, 1)

local btnMax = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btnMax:SetSize(100, 24)
btnMax:SetPoint("TOPLEFT", 20, -118)
btnMax:SetText("Buy MAX")

local btn20 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btn20:SetSize(68, 24)
btn20:SetPoint("LEFT", btnMax, "RIGHT", 6, 0)
btn20:SetText("Buy 20")

local btn10 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btn10:SetSize(68, 24)
btn10:SetPoint("LEFT", btn20, "RIGHT", 6, 0)
btn10:SetText("Buy 10")

local btn1 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btn1:SetSize(62, 24)
btn1:SetPoint("LEFT", btn10, "RIGHT", 6, 0)
btn1:SetText("Buy 1")

-- Custom Amount Section
local divLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
divLabel:SetPoint("TOPLEFT", 20, -149)
divLabel:SetText("OR SET AMOUNT")
divLabel:SetTextColor(.9, .8, .3, 1)

local btnSub10 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btnSub10:SetSize(36, 26)
btnSub10:SetPoint("TOPLEFT", 16, -169)
btnSub10:SetText("-10")

local btnSub1 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btnSub1:SetSize(28, 26)
btnSub1:SetPoint("LEFT", btnSub10, "RIGHT", 3, 0)
btnSub1:SetText("-")

local ebFrame = CreateFrame("Frame", nil, popup,
    BackdropTemplateMixin and "BackdropTemplate" or nil)
ebFrame:SetSize(130, 26)
ebFrame:SetPoint("LEFT", btnSub1, "RIGHT", 5, 0)
ebFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 },
})
ebFrame:SetBackdropColor(0, 0, 0, .7)
ebFrame:SetBackdropBorderColor(.6, .6, .6, 1)

local eb = CreateFrame("EditBox", nil, ebFrame)
eb:SetAllPoints()
eb:SetFontObject("GameFontHighlight")
eb:SetJustifyH("CENTER")
eb:SetNumeric(true)
eb:SetMaxLetters(20)
eb:SetAutoFocus(false)
eb:EnableMouse(true)
eb:EnableMouseWheel(true)

local btnAdd1 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btnAdd1:SetSize(28, 26)
btnAdd1:SetPoint("LEFT", ebFrame, "RIGHT", 5, 0)
btnAdd1:SetText("+")

local btnAdd10 = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btnAdd10:SetSize(36, 26)
btnAdd10:SetPoint("LEFT", btnAdd1, "RIGHT", 3, 0)
btnAdd10:SetText("+10")

local btnAddMax = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
btnAddMax:SetSize(52, 26)
btnAddMax:SetPoint("LEFT", btnAdd10, "RIGHT", 4, 0)
btnAddMax:SetText("MAX")

-- Slider
local slider = CreateFrame("Slider", "ShiftBuyMaxSlider", popup,
    BackdropTemplateMixin and "BackdropTemplate" or nil)
slider:SetSize(308, 14)
slider:SetPoint("TOP", 0, -206)
slider:SetOrientation("HORIZONTAL")
slider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left=3, right=3, top=6, bottom=6 },
})
local thumb = slider:CreateTexture(nil, "ARTWORK")
thumb:SetSize(28, 28)
thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
slider:SetThumbTexture(thumb)
slider:SetMinMaxValues(1, MAX_STACK_SIZE)
slider:SetValueStep(1)

local sliderMin = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sliderMin:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
sliderMin:SetText("1")
local sliderMax = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sliderMax:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
sliderMax:SetText("900000000000000")

-- Cost Preview
local costLbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
costLbl:SetPoint("TOPLEFT", 22, -238)
costLbl:SetText("Total Cost:")
local costVal = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
costVal:SetPoint("LEFT", costLbl, "RIGHT", 8, 0)

local moneyLbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
moneyLbl:SetPoint("TOPLEFT", costLbl, "BOTTOMLEFT", 0, -6)
moneyLbl:SetText("Your Money:")
local moneyVal = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
moneyVal:SetPoint("LEFT", moneyLbl, "RIGHT", 8, 0)

-- Bottom Action Buttons
local buyBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
buyBtn:SetSize(130, 28)
buyBtn:SetPoint("BOTTOMLEFT", 24, 16)
buyBtn:SetText("Buy")

local cancelBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
cancelBtn:SetSize(100, 28)
cancelBtn:SetPoint("BOTTOMRIGHT", -24, 16)
cancelBtn:SetText("Cancel")
cancelBtn:SetScript("OnClick", function() popup:Hide() end)

-- ---------------------------------------------------------------------------
-- UI Logic
-- ---------------------------------------------------------------------------
local updating = false

local function Refresh(amt)
    if updating or not popup.info then return end
    updating = true

    local info = popup.info
    local maxLim = info.maxPossible or MAX_STACK_SIZE

    amt = tonumber(amt) or info.minStep
    if amt < info.minStep then amt = info.minStep end
    if amt > maxLim then amt = maxLim end
    if info.stackCount > 1 then
        amt = math.floor(amt / info.stackCount) * info.stackCount
        if amt < info.stackCount then amt = info.stackCount end
    end

    popup.amount = amt
    eb:SetText(string.format("%.0f", amt))
    slider:SetValue(amt)

    local totalCost = (amt / info.stackCount) * info.price
    costVal:SetText(FormatCoins(totalCost))
    moneyVal:SetText(FormatCoins(info.playerMoney))

    if info.numAvailable == 0 then
        costVal:SetText("|cffff3333Sold Out|r")
        buyBtn:SetText("Sold Out")
        buyBtn:Disable()
    else
        buyBtn:SetText("Buy")
        buyBtn:Enable()
    end

    updating = false
end

eb:SetScript("OnTextChanged", function(self, user)
    if not user or updating then return end
    local v = tonumber(self:GetText())
    if v then Refresh(v) end
end)
eb:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    if buyBtn:IsEnabled() then buyBtn:Click() end
end)
eb:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    popup:Hide()
end)
eb:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
    ebFrame:SetBackdropBorderColor(1, .82, 0, 1)
end)
eb:SetScript("OnEditFocusLost", function(self)
    self:HighlightText(0, 0)
    ebFrame:SetBackdropBorderColor(.6, .6, .6, 1)
end)
eb:SetScript("OnMouseWheel", function(self, d)
    local step = popup.info and popup.info.minStep or 1
    Refresh((tonumber(self:GetText()) or step) + d * step)
end)
slider:SetScript("OnValueChanged", function(self, v, user)
    if not user or updating then return end
    Refresh(math.floor(v + .5))
end)

btnSub10:SetScript("OnClick", function()
    local step = (popup.info and popup.info.minStep or 1) * 10
    Refresh((popup.amount or 1) - step)
end)
btnSub1:SetScript("OnClick", function()
    local step = popup.info and popup.info.minStep or 1
    Refresh((popup.amount or 1) - step)
end)
btnAdd1:SetScript("OnClick", function()
    local step = popup.info and popup.info.minStep or 1
    Refresh((popup.amount or 1) + step)
end)
btnAdd10:SetScript("OnClick", function()
    local step = (popup.info and popup.info.minStep or 1) * 10
    Refresh((popup.amount or 1) + step)
end)
btnAddMax:SetScript("OnClick", function()
    Refresh(MAX_STACK_SIZE)
end)

btnMax:SetScript("OnClick", function()
    if not popup.info then return end
    ExecutePurchase(popup.itemIndex, popup.info.maxPossible, popup.info.isTest)
    popup:Hide()
end)
btn20:SetScript("OnClick", function()
    if not popup.info then return end
    local qty = 20
    if popup.info.stackCount > 1 then qty = math.floor(20 / popup.info.stackCount) * popup.info.stackCount end
    if qty < popup.info.minStep then qty = popup.info.minStep end
    ExecutePurchase(popup.itemIndex, qty, popup.info.isTest)
    popup:Hide()
end)
btn10:SetScript("OnClick", function()
    if not popup.info then return end
    local qty = 10
    if popup.info.stackCount > 1 then qty = math.floor(10 / popup.info.stackCount) * popup.info.stackCount end
    if qty < popup.info.minStep then qty = popup.info.minStep end
    ExecutePurchase(popup.itemIndex, qty, popup.info.isTest)
    popup:Hide()
end)
btn1:SetScript("OnClick", function()
    if not popup.info then return end
    ExecutePurchase(popup.itemIndex, popup.info.minStep, popup.info.isTest)
    popup:Hide()
end)
buyBtn:SetScript("OnClick", function()
    if not popup.info or not popup.amount then return end
    ExecutePurchase(popup.itemIndex, popup.amount, popup.info.isTest)
    popup:Hide()
end)

-- ---------------------------------------------------------------------------
-- Open Popup Dialog
-- ---------------------------------------------------------------------------
local function OpenPopup(index, anchor, isTestMode)
    local info = GetItemPurchaseInfo(index, isTestMode)
    if not info then return end

    popup.itemIndex = index
    popup.info = info

    if StackSplitFrame and StackSplitFrame:IsShown() then
        StackSplitFrame:Hide()
    end

    icon:SetTexture(info.texture)
    nameText:SetText(info.name)
    nameText:SetTextColor(info.color.r, info.color.g, info.color.b)

    local sub = string.format("Max Stack: %.0f", info.maxStack)
    if info.stackCount > 1 then sub = sub .. string.format(" | Pack: %d", info.stackCount) end
    if info.numAvailable and info.numAvailable > 0 then sub = sub .. string.format(" | Stock: %d", info.numAvailable * info.stackCount) end
    if info.price > 0 then sub = sub .. " | " .. FormatCoins(info.price) .. (info.stackCount > 1 and " /pack" or " each") end
    subText:SetText(sub)

    btnMax:SetText("Buy MAX")
    btnMax:Enable()

    btn20:SetText("Buy 20")
    btn20:Enable()

    btn10:SetText("Buy 10")
    btn10:Enable()

    btn1:SetText(info.stackCount > 1 and string.format("Buy %d", info.stackCount) or "Buy 1")
    btn1:Enable()

    local sMax = info.maxPossible
    slider:SetMinMaxValues(info.minStep, sMax)
    slider:SetValueStep(info.minStep)
    sliderMin:SetText(tostring(info.minStep))
    sliderMax:SetText(string.format("%.0f", sMax))

    Refresh(sMax)

    popup:ClearAllPoints()
    if anchor and anchor.IsVisible and anchor:IsVisible() then
        popup:SetPoint("LEFT", anchor, "RIGHT", 14, 0)
    elseif MerchantFrame and MerchantFrame:IsShown() then
        popup:SetPoint("LEFT", MerchantFrame, "RIGHT", 14, 0)
    else
        popup:SetPoint("CENTER")
    end

    popup:Show()
    eb:SetFocus()
    eb:HighlightText()
    pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN or 839)
end

-- ---------------------------------------------------------------------------
-- Interception Logic
-- ---------------------------------------------------------------------------
local function IsChatFocused()
    local chat = (ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow())
        or (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow())
    if chat and chat.HasFocus and chat:HasFocus() then return true end
    for i = 1, (NUM_CONTAINER_FRAMES or 10) do
        local cf = _G["ChatFrame" .. i .. "EditBox"]
        if cf and cf.IsVisible and cf:IsVisible() and cf.HasFocus and cf:HasFocus() then return true end
    end
    return false
end

local function TryIntercept(self, mouseButton)
    if not ShiftBuyMaxDB.enabled then return false end
    if not MerchantFrame or not MerchantFrame:IsShown() then return false end
    if (MerchantFrame.selectedTab or 1) ~= 1 then return false end -- only tab 1 (merchant goods)
    if InCombatLockdown and InCombatLockdown() then return false end

    -- Do not intercept Ctrl-click (DressUp preview)
    if IsModifiedClick and IsModifiedClick("DRESSUP") then return false end

    -- Must be Shift or SPLITSTACK modifier
    local isSplit = (IsModifiedClick and IsModifiedClick("SPLITSTACK")) or IsShiftKeyDown()
    if not isSplit then return false end

    -- If a chat input box is active, let linking work normally
    if IsChatFocused() then return false end

    local id = self and self.GetID and self:GetID()
    if not id or id <= 0 then return false end

    OpenPopup(id, self)
    return true
end

-- Wrap button OnClick
local function WrapButton(btn)
    if not btn or type(btn.SetScript) ~= "function" then return end
    if btn.IsObjectType and not btn:IsObjectType("Button") then return end
    if btn._sbm_wrapped then return end
    btn._sbm_wrapped = true

    local origClick = safeGetScript(btn, "OnClick")
    btn:SetScript("OnClick", function(self, mouseButton, ...)
        if TryIntercept(self, mouseButton) then return end
        if origClick then return origClick(self, mouseButton, ...) end
    end)
end

local function WrapButtonForce(btn)
    if not btn or type(btn.SetScript) ~= "function" then return end
    if btn.IsObjectType and not btn:IsObjectType("Button") then return end
    btn._sbm_wrapped = nil
    WrapButton(btn)
end

local function WrapAll()
    local count = math.max(MERCHANT_ITEMS_PER_PAGE or 10, (EVF and EVF.merchantItemButtonCount) or 60)
    for i = 1, count do
        local itemBtn = _G["MerchantItem" .. i .. "ItemButton"]
        if itemBtn then WrapButtonForce(itemBtn) end

        local row = _G["MerchantItem" .. i]
        if row and row.IsObjectType and row:IsObjectType("Button") then
            WrapButtonForce(row)
        end
    end
end

-- Global hook fallbacks
local _origOnModClick = MerchantItemButton_OnModifiedClick
MerchantItemButton_OnModifiedClick = function(self, button, ...)
    if TryIntercept(self, button) then return end
    if _origOnModClick then return _origOnModClick(self, button, ...) end
end

local _origOnClick = MerchantItemButton_OnClick
MerchantItemButton_OnClick = function(self, button, ...)
    if (IsShiftKeyDown() or (IsModifiedClick and IsModifiedClick("SPLITSTACK"))) and TryIntercept(self, button) then return end
    if _origOnClick then return _origOnClick(self, button, ...) end
end

-- Intercept OpenStackSplitFrame directly
if type(OpenStackSplitFrame) == "function" then
    local _origOpenStackSplitFrame = OpenStackSplitFrame
    OpenStackSplitFrame = function(maxStack, parent, anchor, anchorTo, ...)
        if ShiftBuyMaxDB.enabled and MerchantFrame and MerchantFrame:IsShown() and (MerchantFrame.selectedTab or 1) == 1 then
            local isMerchant = false
            if parent then
                local nm = parent.GetName and parent:GetName()
                if nm and nm:find("MerchantItem") then
                    isMerchant = true
                elseif parent:GetParent() == MerchantFrame or (parent:GetParent() and parent:GetParent().GetName and parent:GetParent():GetName() and parent:GetParent():GetName():find("Merchant")) then
                    isMerchant = true
                end
            end
            if isMerchant and parent and parent.GetID then
                local id = parent:GetID()
                if id and id > 0 then
                    OpenPopup(id, parent)
                    return
                end
            end
        end
        return _origOpenStackSplitFrame(maxStack, parent, anchor, anchorTo, ...)
    end
end

-- Fallback StackSplitFrame OnShow hook
if StackSplitFrame and StackSplitFrame.HookScript then
    pcall(function()
        StackSplitFrame:HookScript("OnShow", function(self)
            if not ShiftBuyMaxDB.enabled then return end
            if not MerchantFrame or not MerchantFrame:IsShown() then return end
            if (MerchantFrame.selectedTab or 1) ~= 1 then return end
            local owner = self.owner
            if owner and owner.GetID then
                local id = owner:GetID()
                if id and id > 0 then
                    self:Hide()
                    OpenPopup(id, owner)
                end
            end
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- Tooltip Hint
-- ---------------------------------------------------------------------------
local function TooltipHint(tooltip)
    if not ShiftBuyMaxDB.showTooltip or not ShiftBuyMaxDB.enabled then return end
    if not MerchantFrame or not MerchantFrame:IsShown() or (MerchantFrame.selectedTab or 1) ~= 1 then return end
    local focus = (GetMouseFoci and GetMouseFoci()[1]) or (GetMouseFocus and GetMouseFocus())
    if not focus or not focus.GetName then return end
    local nm = focus:GetName()
    if not nm or not nm:match("^MerchantItem%d+") then return end
    local id = focus.GetID and focus:GetID()
    if not id or id <= 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("|cff00ff00Shift + Click:|r", "|cffffffffShiftBuyMax popup|r")
    tooltip:Show()
end

pcall(function()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            TooltipHint(tooltip)
        end)
    elseif GameTooltip and GameTooltip.HookScript then
        local hasScript = false
        pcall(function() hasScript = GameTooltip:HasScript("OnTooltipSetItem") end)
        if hasScript then
            GameTooltip:HookScript("OnTooltipSetItem", TooltipHint)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local evtFrame = CreateFrame("Frame")
evtFrame:RegisterEvent("ADDON_LOADED")
evtFrame:RegisterEvent("MERCHANT_SHOW")
evtFrame:RegisterEvent("MERCHANT_CLOSED")

evtFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            for k, v in pairs(defaults) do
                if ShiftBuyMaxDB[k] == nil then ShiftBuyMaxDB[k] = v end
            end
        end
        if arg1 == "ExtendedVendorForever" and EVF and type(EVF.RestoreMerchantButtonScripts) == "function" then
            hooksecurefunc(EVF, "RestoreMerchantButtonScripts", function(_, i)
                WrapButtonForce(_G["MerchantItem" .. tostring(i) .. "ItemButton"])
                local row = _G["MerchantItem" .. tostring(i)]
                if row and row.IsObjectType and row:IsObjectType("Button") then
                    WrapButtonForce(row)
                end
            end)
        end
    elseif event == "MERCHANT_SHOW" then
        WrapAll()
        if EVF and type(EVF.RestoreMerchantButtonScripts) == "function" and not EVF._sbm_hooked then
            EVF._sbm_hooked = true
            hooksecurefunc(EVF, "RestoreMerchantButtonScripts", function(_, i)
                WrapButtonForce(_G["MerchantItem" .. tostring(i) .. "ItemButton"])
                local row = _G["MerchantItem" .. tostring(i)]
                if row and row.IsObjectType and row:IsObjectType("Button") then
                    WrapButtonForce(row)
                end
            end)
        end
    elseif event == "MERCHANT_CLOSED" then
        if popup:IsShown() then popup:Hide() end
    end
end)

if type(MerchantFrame_UpdateMerchantInfo) == "function" then
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo", WrapAll)
end

-- ---------------------------------------------------------------------------
-- Slash Commands
-- ---------------------------------------------------------------------------
SLASH_SHIFTBUYMAX1 = "/sbm"
SLASH_SHIFTBUYMAX2 = "/shiftbuymax"
SLASH_SHIFTBUYMAX3 = "/shiftbuy"

SlashCmdList["SHIFTBUYMAX"] = function(msg)
    local text = msg and (strtrim and strtrim(msg) or msg:match("^%s*(.-)%s*$")) or ""
    local cmd = strsplit(" ", text)
    cmd = cmd and cmd:lower() or ""

    if cmd == "test" or cmd == "preview" then
        if MerchantFrame and MerchantFrame:IsShown() then
            OpenPopup(1, _G["MerchantItem1ItemButton"])
        else
            OpenPopup(nil, nil, true)
        end
    elseif cmd == "toggle" then
        ShiftBuyMaxDB.enabled = not ShiftBuyMaxDB.enabled
        Print("Addon: " .. (ShiftBuyMaxDB.enabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
    elseif cmd == "chat" then
        ShiftBuyMaxDB.chatFeedback = not ShiftBuyMaxDB.chatFeedback
        Print("Chat feedback: " .. (ShiftBuyMaxDB.chatFeedback and "|cff00ff00On|r" or "|cffff0000Off|r"))
    elseif cmd == "tooltip" then
        ShiftBuyMaxDB.showTooltip = not ShiftBuyMaxDB.showTooltip
        Print("Tooltip hints: " .. (ShiftBuyMaxDB.showTooltip and "|cff00ff00On|r" or "|cffff0000Off|r"))
    else
        Print("|cffffd200ShiftBuyMax v1.7|r  —  /sbm [test | toggle | chat | tooltip]")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ccff/sbm test|r  Preview the popup dialog")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ccff/sbm toggle|r  Enable / disable")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ccff/sbm chat|r  Toggle purchase chat message")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ccff/sbm tooltip|r  Toggle tooltip hint")
    end
end

-- Startup initialization
for k, v in pairs(defaults) do
    if ShiftBuyMaxDB[k] == nil then ShiftBuyMaxDB[k] = v end
end
Print("|cffffd200v1.7|r loaded! Max Stack: |cff00ff00900,000,000,000,000|r. Hold |cff00ff00Shift|r at vendor or type |cff00ccff/sbm test|r.")

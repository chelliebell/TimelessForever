--[[
    TimelessForever_Disenchant
    --------------------------------------------------------------------------------
    Right-click green, blue, and epic gear in bags to disenchant without equipping!
    Features:
      - Intercepts Right-Click via a secure action button overlay so gear NEVER equips.
      - Disenchants Green (Uncommon), Blue (Rare), and Epic gear seamlessly.
      - Auto-activates when visiting the Mailbox (or toggleable on/off anytime).
      - Auto-loots disenchant materials (Dust, Essences, Shards, Crystals).
      - Equipment Set protection to prevent destroying saved sets.
      - Floating / Bag Docked toggle button with status glow.
      - Slash commands: /de, /disenchant, /tfde
]]

local addonName, addonTable = ...

-- Global check
if _G.TimelessForever_Disenchant_Loaded then return end
_G.TimelessForever_Disenchant_Loaded = true

-- ---------------------------------------------------------------------------
-- Configuration & Database
-- ---------------------------------------------------------------------------
local defaults = {
    enabled = true,
    disenchantGreen = true,
    disenchantBlue = true,
    disenchantEpic = true,
    autoEnableAtMailbox = true,
    autoLootMaterials = true,
    protectEquipmentSets = true,
    showTooltipHint = true,
    showSlotGlow = true,
    buttonPos = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -180, y = 220 },
}

TimelessForever_DisenchantDB = TimelessForever_DisenchantDB or {}

local function InitDB()
    for k, v in pairs(defaults) do
        if TimelessForever_DisenchantDB[k] == nil then
            if type(v) == "table" then
                TimelessForever_DisenchantDB[k] = CopyTable and CopyTable(v) or { point = v.point, relPoint = v.relPoint, x = v.x, y = v.y }
            else
                TimelessForever_DisenchantDB[k] = v
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Compatibility Helpers (Retail / Dragonflight / Vanilla / Classic / Forever)
-- ---------------------------------------------------------------------------
local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Disenchant]|r " .. tostring(msg))
    end
end

local function GetDisenchantSpellInfo()
    local spellID = 13262
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name, info.iconID or 136222
        end
    end
    if type(GetSpellInfo) == "function" then
        local name, _, icon = GetSpellInfo(spellID)
        if name then
            return name, icon or "Interface\\Icons\\Spell_Holy_RemoveCurse"
        end
    end
    return "Disenchant", "Interface\\Icons\\Spell_Holy_RemoveCurse"
end

local function PlayerKnowsDisenchant()
    -- Always allow if user has addon enabled; prevents false-negatives across client versions
    if TimelessForever_DisenchantDB.enabled then return true end
    local spellName = GetDisenchantSpellInfo()
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, 13262)
        if ok and known then return true end
    end
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(IsSpellKnown, 13262)
        if ok and known then return true end
    end
    return true
end

local function SafeGetContainerItemInfo(bag, slot)
    if not bag or not slot then return nil end

    local link, quality, itemID, locked

    -- 1. Try to get item link directly
    if C_Container and C_Container.GetContainerItemLink then
        local ok, l = pcall(C_Container.GetContainerItemLink, bag, slot)
        if ok and l then link = l end
    end
    if not link and type(GetContainerItemLink) == "function" then
        local ok, l = pcall(GetContainerItemLink, bag, slot)
        if ok and l then link = l end
    end

    -- 2. Try ContainerItemInfo
    if C_Container and C_Container.GetContainerItemInfo then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if ok and info then
            link = link or info.hyperlink
            quality = info.quality
            itemID = info.itemID
            locked = info.isLocked
        end
    end
    if type(GetContainerItemInfo) == "function" then
        local ok, res1, res2, res3, res4 = pcall(GetContainerItemInfo, bag, slot)
        if ok then
            locked = locked or res3
            if quality == nil and type(res4) == "number" then
                quality = res4
            end
        end
    end

    -- 3. Resolve quality and itemID from link if needed
    if link then
        if not itemID then
            local idStr = link:match("item:(%d+)")
            if idStr then itemID = tonumber(idStr) end
        end
        if quality == nil then
            if C_Item and C_Item.GetItemInfo then
                local ok, _, _, q = pcall(C_Item.GetItemInfo, link)
                if ok and q then quality = q end
            end
            if quality == nil and type(GetItemInfo) == "function" then
                local ok, _, _, q = pcall(GetItemInfo, link)
                if ok and q then quality = q end
            end
        end
    end

    return link, quality, itemID, locked
end

local function IsEquippableGear(itemLink, itemID)
    if not itemLink and not itemID then return false end
    if type(IsEquippableItem) == "function" then
        local ok, isEquip = pcall(IsEquippableItem, itemLink or itemID)
        if ok and isEquip ~= nil then return isEquip end
    end
    if C_Item and C_Item.IsEquippableItem then
        local ok, isEquip = pcall(C_Item.IsEquippableItem, itemLink or itemID)
        if ok and isEquip ~= nil then return isEquip end
    end
    local equipLoc
    if type(GetItemInfo) == "function" then
        local ok, _, _, _, _, _, _, _, loc = pcall(GetItemInfo, itemLink or itemID)
        if ok and loc then equipLoc = loc end
    end
    return equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP"
end

local function IsSavedInEquipmentSet(bag, slot)
    if not TimelessForever_DisenchantDB.protectEquipmentSets then return false end
    if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs and EquipmentManager_UnpackLocation then
        local ok, setIDs = pcall(C_EquipmentSet.GetEquipmentSetIDs)
        if ok and setIDs then
            for _, setID in ipairs(setIDs) do
                local locs = C_EquipmentSet.GetItemLocations(setID)
                if locs then
                    for _, loc in pairs(locs) do
                        if loc then
                            local player, bank, bags, voidStorage, slotLoc, bagLoc = EquipmentManager_UnpackLocation(loc)
                            if bags and bagLoc == bag and slotLoc == slot then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Resolve bag and slot index from any bag button or addon button
local function ResolveBagAndSlot(btn)
    if not btn then return nil, nil end

    -- Check if btn is our own secure overlay frame
    if btn.currentBag ~= nil and btn.currentSlot ~= nil then
        return btn.currentBag, btn.currentSlot
    end

    -- Method 1: ContainerFrameCombinedBags / Modern WoW methods
    if btn.GetBagID and btn.GetID then
        local ok1, b = pcall(btn.GetBagID, btn)
        local ok2, s = pcall(btn.GetID, btn)
        if ok1 and ok2 and type(b) == "number" and type(s) == "number" and b >= 0 and s > 0 then
            return b, s
        end
    end
    -- Method 2: ContainerFrameXItemY / EllesmereUIBags parent ID
    local parent = btn:GetParent()
    if parent and parent.GetID and btn.GetID then
        local ok1, b = pcall(parent.GetID, parent)
        local ok2, s = pcall(btn.GetID, btn)
        if ok1 and ok2 and type(b) == "number" and type(s) == "number" and b >= 0 and b <= 5 and s > 0 then
            return b, s
        end
    end
    -- Method 3: Bag addon properties (Bagnon, Baganator, ArkInventory, ElvUI, LiteBag)
    if btn.bagID ~= nil and btn.slotIndex ~= nil then return btn.bagID, btn.slotIndex end
    if btn.bagId ~= nil and btn.slotId ~= nil then return btn.bagId, btn.slotId end
    if btn.bag ~= nil and btn.slot ~= nil then return btn.bag, btn.slot end
    if btn.bagID ~= nil and btn.slotID ~= nil then return btn.bagID, btn.slotID end

    -- Method 4: Name parsing
    local name = btn:GetName()
    if name then
        local c, i = name:match("ContainerFrame(%d+)Item(%d+)")
        if c and i then
            return tonumber(c) - 1, tonumber(i)
        end
    end
    return nil, nil
end

-- ---------------------------------------------------------------------------
-- Secure Action Button Engine
-- ---------------------------------------------------------------------------
local deSpellName, deSpellIcon = GetDisenchantSpellInfo()
local isDisenchantLootPending = false

local secureOverlay = CreateFrame("Button", "TF_DisenchantSecureOverlay", UIParent, "SecureActionButtonTemplate")
secureOverlay:SetFrameStrata("TOOLTIP")
secureOverlay:EnableMouse(true)
secureOverlay:RegisterForClicks("AnyUp", "AnyDown")
secureOverlay:Hide()

-- Subtle glowing highlight border
local glowBorder = secureOverlay:CreateTexture(nil, "OVERLAY")
glowBorder:SetAllPoints()
glowBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glowBorder:SetBlendMode("ADD")
glowBorder:SetVertexColor(0.2, 0.9, 1.0, 0.85)

-- Small corner indicator icon
local badgeIcon = secureOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
badgeIcon:SetSize(16, 16)
badgeIcon:SetPoint("TOPRIGHT", secureOverlay, "TOPRIGHT", -2, -2)
badgeIcon:SetTexture(deSpellIcon)

local function IsItemEligibleForDisenchant(bag, slot)
    if not TimelessForever_DisenchantDB.enabled then return false end
    if InCombatLockdown() then return false end
    if not PlayerKnowsDisenchant() then return false end

    local link, quality, itemID, locked = SafeGetContainerItemInfo(bag, slot)
    if not link or locked then return false end

    -- Check Quality: 2 = Green (Uncommon), 3 = Blue (Rare), 4 = Epic
    if quality == 2 and not TimelessForever_DisenchantDB.disenchantGreen then return false end
    if quality == 3 and not TimelessForever_DisenchantDB.disenchantBlue then return false end
    if quality == 4 and not TimelessForever_DisenchantDB.disenchantEpic then return false end
    if quality < 2 or quality > 4 then return false end

    -- Check if equippable gear (armor/weapon/trinket/shield)
    if not IsEquippableGear(link, itemID) then return false end

    -- Equipment set safety
    if IsSavedInEquipmentSet(bag, slot) then return false end

    return true, link, quality
end

local function UpdateItemTooltip(bag, slot)
    if not bag or not slot then return end

    GameTooltip:SetOwner(secureOverlay, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local populated = false
    -- Attempt 1: Standard SetBagItem
    local setBag = (C_Container and C_Container.GetContainerItemInfo and GameTooltip.SetBagItem) or GameTooltip.SetBagItem
    if setBag then
        local ok = pcall(setBag, GameTooltip, bag, slot)
        if ok and GameTooltip:NumLines() and GameTooltip:NumLines() > 0 then
            populated = true
        end
    end

    -- Attempt 2: Fallback to hyperlink if SetBagItem didn't populate lines
    if not populated then
        local link = SafeGetContainerItemInfo(bag, slot)
        if link and GameTooltip.SetHyperlink then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
            if ok and GameTooltip:NumLines() and GameTooltip:NumLines() > 0 then
                populated = true
            end
        end
    end

    -- Add the Disenchant indicator line at the bottom
    if TimelessForever_DisenchantDB.showTooltipHint then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00[Right-Click]: Disenchant|r |cffaaaaaa(Will NOT Equip)|r", 0, 1, 0)
    end

    GameTooltip:Show()

    -- Comparison tooltips if shift is held or default compare is on
    if type(GameTooltip_ShowCompareItem) == "function" then
        pcall(GameTooltip_ShowCompareItem, GameTooltip)
    end
end

local isHidingOverlay = false
local function HideSecureOverlay()
    if InCombatLockdown() or isHidingOverlay then return end
    isHidingOverlay = true

    if secureOverlay:IsShown() then
        secureOverlay:Hide()
    end
    secureOverlay:ClearAllPoints()
    secureOverlay.currentBag = nil
    secureOverlay.currentSlot = nil
    secureOverlay.currentButton = nil
    if GameTooltip:IsOwned(secureOverlay) then
        GameTooltip:Hide()
    end

    isHidingOverlay = false
end

local function AttachSecureOverlay(targetButton, bag, slot)
    if InCombatLockdown() then return end
    if not targetButton or not bag or not slot then return end

    deSpellName, deSpellIcon = GetDisenchantSpellInfo()
    badgeIcon:SetTexture(deSpellIcon)

    secureOverlay.currentBag = bag
    secureOverlay.currentSlot = slot
    secureOverlay.currentButton = targetButton

    secureOverlay:ClearAllPoints()
    secureOverlay:SetAllPoints(targetButton)
    secureOverlay:SetFrameLevel(targetButton:GetFrameLevel() + 25)

    local macro = string.format("/cast %s\n/use %d %d", deSpellName, bag, slot)
    local _, _, itemID = SafeGetContainerItemInfo(bag, slot)
    if itemID then
        macro = string.format("/cast %s\n/use %d %d\n/use item:%d", deSpellName, bag, slot, itemID)
    end

    -- Configure both generic and RightButton attributes for maximum compatibility
    secureOverlay:SetAttribute("type", "macro")
    secureOverlay:SetAttribute("type-RightButton", "macro")
    secureOverlay:SetAttribute("type2", "macro")
    secureOverlay:SetAttribute("macrotext", macro)
    secureOverlay:SetAttribute("macrotext-RightButton", macro)
    secureOverlay:SetAttribute("macrotext2", macro)

    -- Also assign spell and target attributes
    secureOverlay:SetAttribute("spell", deSpellName)
    secureOverlay:SetAttribute("spell-RightButton", deSpellName)
    secureOverlay:SetAttribute("spell2", deSpellName)
    secureOverlay:SetAttribute("target-bag", bag)
    secureOverlay:SetAttribute("target-bag-RightButton", bag)
    secureOverlay:SetAttribute("target-bag2", bag)
    secureOverlay:SetAttribute("target-slot", slot)
    secureOverlay:SetAttribute("target-slot-RightButton", slot)
    secureOverlay:SetAttribute("target-slot2", slot)
    secureOverlay:SetAttribute("target-item", string.format("%d %d", bag, slot))

    secureOverlay:Show()

    -- Display full item tooltip with stats and Disenchant hint
    UpdateItemTooltip(bag, slot)
end

-- OnEnter: Ensure tooltip is always refreshed if cursor hovers the overlay
secureOverlay:SetScript("OnEnter", function(self)
    if self.currentBag and self.currentSlot then
        UpdateItemTooltip(self.currentBag, self.currentSlot)
    end
end)

-- PreClick: If user Left-Clicks, perform standard pickup so dragging items is unaffected
secureOverlay:SetScript("PreClick", function(self, button, down)
    if button == "LeftButton" and not down then
        if self.currentBag and self.currentSlot then
            local pickupFunc = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
            if pickupFunc then
                pcall(pickupFunc, self.currentBag, self.currentSlot)
            end
        end
        HideSecureOverlay()
    end
end)

-- PostClick: When right-clicked to disenchant, dismiss overlay immediately on mouse up
secureOverlay:SetScript("PostClick", function(self, button, down)
    if button == "RightButton" and not down then
        isDisenchantLootPending = true
        local link = SafeGetContainerItemInfo(self.currentBag, self.currentSlot)
        Print(string.format("Disenchanting %s...", link or "gear"))
        HideSecureOverlay()
    end
end)

-- OnLeave: Dismiss overlay when mouse leaves
secureOverlay:SetScript("OnLeave", function(self)
    if isHidingOverlay then return end
    HideSecureOverlay()
end)

-- ---------------------------------------------------------------------------
-- Container Frame Slot Hooking
-- ---------------------------------------------------------------------------
local function OnItemSlotEnter(btn)
    if InCombatLockdown() then return end
    if not TimelessForever_DisenchantDB.enabled then return end

    local bag, slot = ResolveBagAndSlot(btn)
    if not bag or not slot then return end

    local eligible = IsItemEligibleForDisenchant(bag, slot)
    if eligible then
        AttachSecureOverlay(btn, bag, slot)
    end
end

-- Hook default container frames and template
local function HookContainerSlots()
    -- Hook standard ContainerFrameItemButtons
    for i = 1, 13 do
        local frameName = "ContainerFrame" .. i
        for j = 1, 36 do
            local btn = _G[frameName .. "Item" .. j]
            if btn and not btn.tfHookedDE then
                btn:HookScript("OnEnter", OnItemSlotEnter)
                btn.tfHookedDE = true
            end
        end
    end

    -- Hook Dragonflight / 10.0+ Combined Bags
    if ContainerFrameCombinedBags then
        for j = 1, 150 do
            local btn = _G["ContainerFrameCombinedBagsItem" .. j]
            if btn and not btn.tfHookedDE then
                btn:HookScript("OnEnter", OnItemSlotEnter)
                btn.tfHookedDE = true
            end
        end
    end
end

-- Universal Tooltip post-call fallback for any bag addon (Bagnon, Baganator, ElvUI, etc.)
local function OnTooltipUpdated(tooltip)
    if InCombatLockdown() then return end
    if not TimelessForever_DisenchantDB.enabled then return end

    local mouseFocus = (GetMouseFoci and GetMouseFoci()[1]) or (GetMouseFocus and GetMouseFocus())
    if not mouseFocus or mouseFocus == secureOverlay then return end

    local bag, slot = ResolveBagAndSlot(mouseFocus)
    if bag and slot then
        local eligible = IsItemEligibleForDisenchant(bag, slot)
        if eligible and secureOverlay.currentButton ~= mouseFocus then
            AttachSecureOverlay(mouseFocus, bag, slot)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Mailbox Integration
-- ---------------------------------------------------------------------------
local mailboxButton = nil

local function CreateMailboxButton()
    if not MailFrame or mailboxButton then return end

    mailboxButton = CreateFrame("Button", "TF_DisenchantMailboxToggle", MailFrame, "UIPanelButtonTemplate")
    mailboxButton:SetSize(110, 22)
    mailboxButton:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -40, -32)
    mailboxButton:SetText(TimelessForever_DisenchantDB.enabled and "|cff00ff00DE: ON|r" or "|cffff4444DE: OFF|r")

    mailboxButton:SetScript("OnClick", function()
        TimelessForever_DisenchantDB.enabled = not TimelessForever_DisenchantDB.enabled
        mailboxButton:SetText(TimelessForever_DisenchantDB.enabled and "|cff00ff00DE: ON|r" or "|cffff4444DE: OFF|r")
        Print(TimelessForever_DisenchantDB.enabled and "Disenchant Mode |cff00ff00ENABLED|r (Right-click gear in bags to disenchant)." or "Disenchant Mode |cffff4444DISABLED|r.")
        if not TimelessForever_DisenchantDB.enabled then HideSecureOverlay() end
        if TF_DisenchantFloatingButton then TF_DisenchantFloatingButton:UpdateVisuals() end
    end)

    mailboxButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cff00ccffDisenchant|r")
        GameTooltip:AddLine("Click to toggle Right-Click Disenchant mode on or off.", 1, 1, 1)
        GameTooltip:AddLine("When ON, right-clicking Green/Blue/Epic gear in bags will instantly cast Disenchant without equipping!", 0, 1, 0, true)
        GameTooltip:Show()
    end)
    mailboxButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ---------------------------------------------------------------------------
-- Auto-Loot Disenchant Drops
-- ---------------------------------------------------------------------------
local function AutoLootDisenchant()
    if not TimelessForever_DisenchantDB.autoLootMaterials then return end
    if not isDisenchantLootPending then return end

    local numLoot = (GetNumLootItems and GetNumLootItems()) or 0
    if numLoot > 0 then
        for i = 1, numLoot do
            local lootLink = GetLootSlotLink and GetLootSlotLink(i)
            local _, lootName, lootQty = GetLootSlotInfo(i)
            if LootSlot then
                LootSlot(i)
            end
            if lootLink or lootName then
                local display = lootLink or lootName
                local qty = (lootQty and lootQty > 1) and (" x" .. lootQty) or ""
                Print("Looted: " .. display .. qty)
            end
        end
        if CloseLoot then
            CloseLoot()
        end
        isDisenchantLootPending = false
    end
end

-- ---------------------------------------------------------------------------
-- Floating / Bag Toggle Button
-- ---------------------------------------------------------------------------
local function CreateFloatingToggleButton()
    local btn = CreateFrame("Button", "TF_DisenchantFloatingButton", UIParent, "BackdropTemplate")
    btn:SetSize(36, 36)
    local pos = TimelessForever_DisenchantDB.buttonPos or defaults.buttonPos
    btn:SetPoint(pos.point or "BOTTOMRIGHT", UIParent, pos.relPoint or "BOTTOMRIGHT", pos.x or -180, pos.y or 220)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetClampedToScreen(true)

    -- Icon texture
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    icon:SetTexture(deSpellIcon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Border / backdrop
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropColor(0.05, 0.05, 0.08, 0.90)
    end

    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    highlight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")

    -- Status Glow
    local statusGlow = btn:CreateTexture(nil, "OVERLAY")
    statusGlow:SetAllPoints()
    statusGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    statusGlow:SetBlendMode("ADD")
    btn.statusGlow = statusGlow

    function btn:UpdateVisuals()
        if TimelessForever_DisenchantDB.enabled then
            btn.icon:SetDesaturated(false)
            btn.icon:SetVertexColor(1, 1, 1)
            btn.statusGlow:Show()
            if btn.SetBackdropBorderColor then
                btn:SetBackdropBorderColor(0, 1, 0, 1)
            end
        else
            btn.icon:SetDesaturated(true)
            btn.icon:SetVertexColor(0.6, 0.6, 0.6)
            btn.statusGlow:Hide()
            if btn.SetBackdropBorderColor then
                btn:SetBackdropBorderColor(1, 0, 0, 0.7)
            end
        end
        if mailboxButton then
            mailboxButton:SetText(TimelessForever_DisenchantDB.enabled and "|cff00ff00DE: ON|r" or "|cffff4444DE: OFF|r")
        end
    end

    btn:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            if _G.TimelessForever_ButtonBar and _G.TimelessForever_ButtonBar.frame then
                local bar = _G.TimelessForever_ButtonBar.frame
                if not (_G.TimelessForever_ButtonBarDB and _G.TimelessForever_ButtonBarDB.locked) then
                    bar:StartMoving()
                    bar.isDragging = true
                    self.isBarMoving = true
                end
            else
                self:StartMoving()
                self.isMoving = true
            end
        end
    end)

    btn:SetScript("OnDragStop", function(self)
        if self.isBarMoving then
            local bar = _G.TimelessForever_ButtonBar.frame
            bar:StopMovingOrSizing()
            bar.isDragging = false
            self.isBarMoving = false
            if _G.TimelessForever_ButtonBar.SavePosition then
                _G.TimelessForever_ButtonBar:SavePosition()
            end
            return
        end
        if self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
            local point, _, relPoint, x, y = self:GetPoint()
            TimelessForever_DisenchantDB.buttonPos = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)

    btn:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            TimelessForever_DisenchantDB.enabled = not TimelessForever_DisenchantDB.enabled
            self:UpdateVisuals()
            Print(TimelessForever_DisenchantDB.enabled and "Disenchant Mode |cff00ff00ENABLED|r. Right-click gear in bags to disenchant without equipping!" or "Disenchant Mode |cffff4444DISABLED|r.")
            if not TimelessForever_DisenchantDB.enabled then HideSecureOverlay() end
        elseif mouseButton == "RightButton" then
            -- Print quick settings status
            Print("Current Settings:")
            Print(string.format("  Green: %s | Blue: %s | Epic: %s",
                TimelessForever_DisenchantDB.disenchantGreen and "|cff00ff00ON|r" or "|cffff4444OFF|r",
                TimelessForever_DisenchantDB.disenchantBlue and "|cff00ff00ON|r" or "|cffff4444OFF|r",
                TimelessForever_DisenchantDB.disenchantEpic and "|cff00ff00ON|r" or "|cffff4444OFF|r"
            ))
            Print(string.format("  Auto-Loot: %s | Protect Sets: %s",
                TimelessForever_DisenchantDB.autoLootMaterials and "|cff00ff00ON|r" or "|cffff4444OFF|r",
                TimelessForever_DisenchantDB.protectEquipmentSets and "|cff00ff00ON|r" or "|cffff4444OFF|r"
            ))
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ccffDisenchant|r")
        GameTooltip:AddLine(string.format("Status: %s", TimelessForever_DisenchantDB.enabled and "|cff00ff00ACTIVE (Ready to Disenchant)|r" or "|cffff4444INACTIVE|r"))
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Disenchant Mode", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Show Settings Summary", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Shift + Drag:|r Move Bar", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("When ACTIVE, right-clicking any Green/Blue/Epic gear in your bags casts Disenchant and NEVER equips it!", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:UpdateVisuals()

    -- Register with TimelessForever Button Bar
    if _G.TimelessForever_ButtonBar then
        _G.TimelessForever_ButtonBar:RegisterButton("disenchant", btn, 2, 36, 36)
    end
end

-- ---------------------------------------------------------------------------
-- Slash Commands
-- ---------------------------------------------------------------------------
local function HandleSlashCommands(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    arg = (arg or ""):lower()

    if cmd == "toggle" or cmd == "" then
        TimelessForever_DisenchantDB.enabled = not TimelessForever_DisenchantDB.enabled
        Print(TimelessForever_DisenchantDB.enabled and "Disenchant Mode |cff00ff00ENABLED|r." or "Disenchant Mode |cffff4444DISABLED|r.")
        if TF_DisenchantFloatingButton then TF_DisenchantFloatingButton:UpdateVisuals() end
        if not TimelessForever_DisenchantDB.enabled then HideSecureOverlay() end
    elseif cmd == "green" then
        TimelessForever_DisenchantDB.disenchantGreen = not TimelessForever_DisenchantDB.disenchantGreen
        Print("Disenchant Green gear: " .. (TimelessForever_DisenchantDB.disenchantGreen and "|cff00ff00ENABLED|r" or "|cffff4444DISABLED|r"))
    elseif cmd == "blue" then
        TimelessForever_DisenchantDB.disenchantBlue = not TimelessForever_DisenchantDB.disenchantBlue
        Print("Disenchant Blue gear: " .. (TimelessForever_DisenchantDB.disenchantBlue and "|cff00ff00ENABLED|r" or "|cffff4444DISABLED|r"))
    elseif cmd == "epic" then
        TimelessForever_DisenchantDB.disenchantEpic = not TimelessForever_DisenchantDB.disenchantEpic
        Print("Disenchant Epic gear: " .. (TimelessForever_DisenchantDB.disenchantEpic and "|cff00ff00ENABLED|r" or "|cffff4444DISABLED|r"))
    elseif cmd == "loot" then
        TimelessForever_DisenchantDB.autoLootMaterials = not TimelessForever_DisenchantDB.autoLootMaterials
        Print("Auto-loot materials: " .. (TimelessForever_DisenchantDB.autoLootMaterials and "|cff00ff00ENABLED|r" or "|cffff4444DISABLED|r"))
    elseif cmd == "test" then
        local mouseFocus = (GetMouseFoci and GetMouseFoci()[1]) or (GetMouseFocus and GetMouseFocus())
        if not mouseFocus then
            Print("Mouse is not hovering over any frame.")
            return
        end
        local bag, slot = ResolveBagAndSlot(mouseFocus)
        Print(string.format("Hovered: %s", mouseFocus:GetName() or "Anonymous Frame"))
        Print(string.format("Resolved: Bag %s | Slot %s", tostring(bag), tostring(slot)))
        if bag and slot then
            local link, quality, itemID, locked = SafeGetContainerItemInfo(bag, slot)
            Print(string.format("Item: %s (ID: %s, Quality: %s, Locked: %s)", tostring(link), tostring(itemID), tostring(quality), tostring(locked)))
            local isEquip = IsEquippableGear(link, itemID)
            Print(string.format("IsEquippable: %s", tostring(isEquip)))
            local eligible = IsItemEligibleForDisenchant(bag, slot)
            Print(string.format("Eligible for Disenchant: %s", tostring(eligible)))
            Print(string.format("Overlay attributes: type=%s, macrotext=%s", tostring(secureOverlay:GetAttribute("type")), tostring(secureOverlay:GetAttribute("macrotext"))))
        else
            Print("Could not resolve bag/slot from hovered frame.")
            local p = mouseFocus:GetParent()
            if p then
                Print(string.format("Parent Frame: %s (ID: %s)", p:GetName() or "Anonymous", tostring(p:GetID())))
            end
        end
    elseif cmd == "reset" then
        TimelessForever_DisenchantDB.buttonPos = CopyTable and CopyTable(defaults.buttonPos) or { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -180, y = 220 }
        if TF_DisenchantFloatingButton then
            TF_DisenchantFloatingButton:ClearAllPoints()
            TF_DisenchantFloatingButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -180, 220)
        end
        Print("Button position reset.")
    else
        Print("Commands: /de [toggle | green | blue | epic | loot | test | reset]")
    end
end

SLASH_TFDISENCHANT1 = "/de"
SLASH_TFDISENCHANT2 = "/disenchant"
SLASH_TFDISENCHANT3 = "/tfde"
SlashCmdList["TFDISENCHANT"] = HandleSlashCommands

-- ---------------------------------------------------------------------------
-- Event Frame
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame", "TF_DisenchantEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("LOOT_READY")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName == addonName then
            InitDB()
        end
    elseif event == "PLAYER_LOGIN" then
        InitDB()
        HookContainerSlots()
        CreateFloatingToggleButton()
        CreateMailboxButton()

        -- Hook GameTooltip for dynamic bag addons
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipUpdated)
        elseif GameTooltip and GameTooltip.HookScript then
            GameTooltip:HookScript("OnTooltipSetItem", OnTooltipUpdated)
        end

        Print("Loaded! Right-click Green/Blue/Epic gear in bags to disenchant without equipping. Type |cff00ff00/de|r for options.")

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- In combat: instantly hide secure button to prevent interface taint
        HideSecureOverlay()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Out of combat
    elseif event == "MAIL_SHOW" then
        CreateMailboxButton()
        if TimelessForever_DisenchantDB.autoEnableAtMailbox and not TimelessForever_DisenchantDB.enabled then
            TimelessForever_DisenchantDB.enabled = true
            if TF_DisenchantFloatingButton then TF_DisenchantFloatingButton:UpdateVisuals() end
            Print("Mailbox opened: Disenchant Mode |cff00ff00ACTIVATED|r! Right-click gear in bags to disenchant.")
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellID = ...
        if unit == "player" then
            local spellName = GetDisenchantSpellInfo()
            if spellID == 13262 or (type(spellID) == "string" and spellID == spellName) then
                isDisenchantLootPending = true
            end
        end
    elseif event == "LOOT_OPENED" or event == "LOOT_READY" then
        AutoLootDisenchant()
    elseif event == "BAG_UPDATE" then
        HookContainerSlots()
    end
end)

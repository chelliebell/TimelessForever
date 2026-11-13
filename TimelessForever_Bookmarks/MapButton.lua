local addonName, ns = ...

local mapButton = nil

local function CreateMapButton()
    if mapButton or not WorldMapFrame then return end

    local btn = CreateFrame("Button", "TimelessForever_BookmarksMapButton", WorldMapFrame, "UIPanelButtonTemplate")
    btn:SetSize(84, 22)
    btn:SetFrameStrata("FULLSCREEN_DIALOG")
    btn:SetFrameLevel(500)
    btn:SetText("Bookmarks")

    -- Position near top right of world map
    if WorldMapFrameCloseButton then
        btn:SetPoint("RIGHT", WorldMapFrameCloseButton, "LEFT", -4, 0)
    elseif WorldMapFrame.BorderFrame and WorldMapFrame.BorderFrame.CloseButton then
        btn:SetPoint("RIGHT", WorldMapFrame.BorderFrame.CloseButton, "LEFT", -4, 0)
    else
        btn:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -36, -4)
    end

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ns.ToggleManager()
        elseif button == "RightButton" then
            local mapID, x, y = ns.GetCursorMapPosition()
            if mapID and x and y then
                ns.ShowCreateDialog(mapID, x, y)
            else
                ns.ToggleManager()
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("|cff00ccffTimelessForever Bookmarks|r", 1, 0.82, 0)
        GameTooltip:AddLine("Left-Click: Open Bookmarks Manager", 1, 1, 1)
        GameTooltip:AddLine("Right-Click on map: Place bookmark at cursor", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + Right-Click: Instant bookmark creation", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    mapButton = btn
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    C_Timer.After(0.5, CreateMapButton)
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function()
            C_Timer.After(0.1, CreateMapButton)
        end)
    end
end)

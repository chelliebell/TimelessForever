local addonName, ns = ...

ns.ICONS = {
    -- Pins
    { key = "pin_red", name = "Red Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 1, 0.25, 0.25 } },
    { key = "pin_blue", name = "Blue Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 0.25, 0.65, 1 } },
    { key = "pin_green", name = "Green Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 0.35, 1, 0.35 } },
    { key = "pin_yellow", name = "Yellow Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 1, 0.85, 0.1 } },
    { key = "pin_purple", name = "Purple Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 0.8, 0.4, 1 } },
    { key = "pin_orange", name = "Orange Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 1, 0.55, 0.1 } },
    { key = "pin_cyan", name = "Cyan Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 0.2, 0.9, 1 } },
    { key = "pin_white", name = "White Pin", category = "Pins", texture = "Interface\\Minimap\\Ping\\ping5", color = { 1, 1, 1 } },

    -- Raid Targets
    { key = "raid_star", name = "Star", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" },
    { key = "raid_circle", name = "Circle", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" },
    { key = "raid_diamond", name = "Diamond", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" },
    { key = "raid_triangle", name = "Triangle", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" },
    { key = "raid_moon", name = "Moon", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" },
    { key = "raid_square", name = "Square", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" },
    { key = "raid_cross", name = "Cross", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    { key = "raid_skull", name = "Skull", category = "Raid Targets", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },

    -- Places & Travel
    { key = "place_camp", name = "Campfire", category = "Places", texture = "Interface\\Icons\\INV_Misc_Campfire" },
    { key = "place_inn", name = "Inn / Rest", category = "Places", texture = "Interface\\Minimap\\Tracking\\Innkeeper" },
    { key = "place_portal", name = "Portal", category = "Places", texture = "Interface\\Icons\\Spell_Arcane_PortalIronForge" },
    { key = "place_flight", name = "Flight Master", category = "Places", texture = "Interface\\Minimap\\Tracking\\FlightMaster" },
    { key = "place_cave", name = "Cave / Dungeon", category = "Places", texture = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker" },
    { key = "place_mailbox", name = "Mailbox", category = "Places", texture = "Interface\\Minimap\\Tracking\\Mailbox" },
    { key = "place_bank", name = "Bank", category = "Places", texture = "Interface\\Minimap\\Tracking\\Banker" },
    { key = "place_repair", name = "Anvil / Repair", category = "Places", texture = "Interface\\Minimap\\Tracking\\Repair" },

    -- Gathering & Resources
    { key = "res_herb", name = "Herb / Flower", category = "Gathering", texture = "Interface\\Icons\\INV_Misc_Herb_01" },
    { key = "res_mine", name = "Mining / Ore", category = "Gathering", texture = "Interface\\Icons\\INV_Pick_02" },
    { key = "res_fish", name = "Fishing Pool", category = "Gathering", texture = "Interface\\Icons\\Trade_Fishing" },
    { key = "res_skin", name = "Skinning", category = "Gathering", texture = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    { key = "res_chest", name = "Treasure Chest", category = "Gathering", texture = "Interface\\Icons\\INV_Box_01" },

    -- Combat & Points of Interest
    { key = "combat_swords", name = "Crossed Swords", category = "Combat", texture = "Interface\\Icons\\INV_Sword_04" },
    { key = "combat_shield", name = "Shield", category = "Combat", texture = "Interface\\Icons\\INV_Shield_06" },
    { key = "combat_boss", name = "Boss / Rare", category = "Combat", texture = "Interface\\Icons\\Spell_Shadow_DeathScream" },
    { key = "combat_danger", name = "Danger / Bomb", category = "Combat", texture = "Interface\\Icons\\INV_Misc_Bomb_01" },
    { key = "combat_eye", name = "Eye / Lookout", category = "Combat", texture = "Interface\\Icons\\INV_Misc_Eye_01" },
    { key = "combat_quest", name = "Quest / Mystery", category = "Combat", texture = "Interface\\Icons\\INV_Misc_QuestionMark" },
    { key = "combat_star", name = "Guidance Star", category = "Combat", texture = "Interface\\Icons\\Spell_Holy_HolyGuidance" },
}

-- Fast lookup by key
ns.ICON_BY_KEY = {}
for _, icon in ipairs(ns.ICONS) do
    ns.ICON_BY_KEY[icon.key] = icon
end

-- Default icon fallback
ns.DEFAULT_ICON_KEY = "pin_yellow"

function ns.GetIconInfo(key)
    return ns.ICON_BY_KEY[key] or ns.ICON_BY_KEY[ns.DEFAULT_ICON_KEY]
end

-- Categories list
ns.ICON_CATEGORIES = { "All", "Pins", "Raid Targets", "Places", "Gathering", "Combat" }

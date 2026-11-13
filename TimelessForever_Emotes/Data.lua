local _, addon = ...

-- =========================================================================
-- Emote Catalog & Default Categories (Poses, Sit, Lie Down, Stand, etc.)
-- =========================================================================

addon.EMOTE_CATALOG = {
    -- Poses & Rest (Sit, Lie Down, Sleep, Stand, Kneel, Cower, Eat, Drink, Read)
    { id = "SIT",        name = "Sit",           slash = "/sit",        token = "SIT",        func = "SitStandOrDescendStart", icon = "Interface\\Icons\\Hunter_Pet_Boar",                   category = "Poses",     desc = "Sit down on the ground or chair (or stand up)", voice = false },
    { id = "LIEDOWN",    name = "Lie Down",      slash = "/laydown",    token = "LAYDOWN",    icon = "Interface\\Icons\\Spell_Holy_Restoration",            category = "Poses",     desc = "Lie down flat on the ground",                   voice = false },
    { id = "SLEEP",      name = "Sleep",         slash = "/sleep",      token = "SLEEP",      icon = "Interface\\Icons\\Spell_Nature_Sleep",                category = "Poses",     desc = "Lie down and go to sleep (Zzz)",                voice = false },
    { id = "STAND",      name = "Stand Up",      slash = "/stand",      token = "STAND",      icon = "Interface\\Icons\\Ability_Rogue_Sprint",              category = "Poses",     desc = "Stand back up on your feet",                    voice = false },
    { id = "KNEEL",      name = "Kneel",         slash = "/kneel",      token = "KNEEL",      icon = "Interface\\Icons\\Spell_Holy_Renew",                  category = "Poses",     desc = "Kneel down on one knee",                        voice = false },
    { id = "COWER",      name = "Cower",         slash = "/cower",      token = "COWER",      icon = "Interface\\Icons\\Spell_Shadow_PsychicScream",        category = "Poses",     desc = "Cower in fear",                                 voice = false },
    { id = "EAT",        name = "Eat",           slash = "/eat",        token = "EAT",        icon = "Interface\\Icons\\INV_Misc_Food_15",                  category = "Poses",     desc = "Mime eating a meal",                            voice = false },
    { id = "DRINK",      name = "Drink",         slash = "/drink",      token = "DRINK",      icon = "Interface\\Icons\\INV_Drink_05",                      category = "Poses",     desc = "Raise a drink in a toast",                      voice = false },
    { id = "READ",       name = "Read Map/Book", slash = "/read",       token = "READ",       icon = "Interface\\Icons\\INV_Misc_Book_09",                  category = "Poses",     desc = "Open a scroll/map and read",                    voice = false },
    { id = "TALK",       name = "Talk",          slash = "/talk",       token = "TALK",       icon = "Interface\\Icons\\Spell_Holy_Silence",                category = "Poses",     desc = "Play talking gesture animation",                voice = false },
    { id = "LISTEN",     name = "Listen",        slash = "/listen",     token = "LISTEN",     icon = "Interface\\Icons\\Spell_Holy_MindVision",             category = "Poses",     desc = "Listen intently",                               voice = false },
    { id = "TIRED",      name = "Tired / Yawn",  slash = "/tired",      token = "TIRED",      icon = "Interface\\Icons\\Spell_Shadow_MindSteal",            category = "Poses",     desc = "Act tired and exhausted",                       voice = false },

    -- Greetings & Social
    { id = "WAVE",       name = "Wave",          slash = "/wave",       token = "WAVE",       icon = "Interface\\Icons\\Ability_Hunter_OneWithNature",      category = "Greetings", desc = "Wave at your target or nearby players",         voice = false },
    { id = "HELLO",      name = "Hello",         slash = "/hello",      token = "HELLO",      icon = "Interface\\Icons\\INV_Misc_Note_01",                  category = "Greetings", desc = "Greet with a friendly voice hello",              voice = true },
    { id = "BOW",        name = "Bow",           slash = "/bow",        token = "BOW",        icon = "Interface\\Icons\\INV_Misc_Cape_18",                  category = "Greetings", desc = "Bow graciously",                                 voice = false },
    { id = "SALUTE",     name = "Salute",        slash = "/salute",     token = "SALUTE",     icon = "Interface\\Icons\\Ability_Warrior_Revenge",           category = "Greetings", desc = "Stand at attention and salute",                  voice = false },
    { id = "BYE",        name = "Goodbye",       slash = "/bye",        token = "BYE",        icon = "Interface\\Icons\\Spell_Arcane_TeleportOrgrimmar",    category = "Greetings", desc = "Wave goodbye with voice line",                   voice = true },
    { id = "WELCOME",    name = "You're Welcome",slash = "/welcome",    token = "WELCOME",    icon = "Interface\\Icons\\Spell_Holy_MindVision",             category = "Greetings", desc = "Say you're welcome",                             voice = true },
    { id = "HAIL",       name = "Hail",          slash = "/hail",       token = "HAIL",       icon = "Interface\\Icons\\INV_BannerPVP_02",                  category = "Greetings", desc = "Hail those around you",                          voice = false },
    { id = "CURTSEY",    name = "Curtsey",       slash = "/curtsey",    token = "CURTSEY",    icon = "Interface\\Icons\\INV_Shirt_16",                      category = "Greetings", desc = "Curtsey politely",                               voice = false },

    -- Friendly & Positive
    { id = "CHEER",      name = "Cheer",         slash = "/cheer",      token = "CHEER",      icon = "Interface\\Icons\\Ability_Warrior_BattleShout",       category = "Friendly",  desc = "Raise your arms and cheer aloud",                voice = true },
    { id = "APPLAUD",    name = "Applause",      slash = "/applaud",    token = "APPLAUD",    icon = "Interface\\Icons\\Spell_Holy_SealOfValor",            category = "Friendly",  desc = "Clap and applaud enthusiastically",              voice = true },
    { id = "THANK",      name = "Thank You",     slash = "/thank",      token = "THANK",      icon = "Interface\\Icons\\INV_Misc_Gift_01",                  category = "Friendly",  desc = "Express gratitude with voice line",              voice = true },
    { id = "CONGRATS",   name = "Congrats",      slash = "/congrats",   token = "CONGRATS",   icon = "Interface\\Icons\\INV_Jewelry_Talisman_07",           category = "Friendly",  desc = "Congratulate someone (with voice)",              voice = true },
    { id = "HUG",        name = "Hug",           slash = "/hug",        token = "HUG",        icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",        category = "Friendly",  desc = "Give a warm hug",                                voice = false },
    { id = "KISS",       name = "Blow Kiss",     slash = "/kiss",       token = "KISS",       icon = "Interface\\Icons\\INV_ValentinesBoxOfChocolates02",   category = "Friendly",  desc = "Blow a kiss",                                    voice = true },
    { id = "FLIRT",      name = "Flirt",         slash = "/flirt",      token = "FLIRT",      icon = "Interface\\Icons\\Spell_BrokenHeart",                 category = "Friendly",  desc = "Deliver a race-specific flirt line",             voice = true },
    { id = "LOVE",       name = "Love",          slash = "/love",       token = "LOVE",       icon = "Interface\\Icons\\INV_ValentinesCard01",              category = "Friendly",  desc = "Show your love and affection",                   voice = false },
    { id = "SMILE",      name = "Smile",         slash = "/smile",      token = "SMILE",      icon = "Interface\\Icons\\Spell_Holy_EmotionHappy",           category = "Friendly",  desc = "Smile warmly",                                   voice = false },
    { id = "HIGHFIVE",   name = "High Five",     slash = "/highfive",   token = "HIGHFIVE",   icon = "Interface\\Icons\\Spell_Holy_DivineSpirit",           category = "Friendly",  desc = "Give a high five",                               voice = false },

    -- Animated & Fun
    { id = "DANCE",      name = "Dance",         slash = "/dance",      token = "DANCE",      icon = "Interface\\Icons\\Spell_Shadow_Charm",                category = "Animated",  desc = "Bust out your signature dance moves",            voice = false },
    { id = "TRAIN",      name = "Choo Choo!",    slash = "/train",      token = "TRAIN",      icon = "Interface\\Icons\\INV_Gizmo_02",                      category = "Animated",  desc = "Do the chugga-chugga train sound",               voice = true },
    { id = "SILLY",      name = "Tell Joke",     slash = "/silly",      token = "SILLY",      icon = "Interface\\Icons\\INV_Mask_01",                       category = "Animated",  desc = "Tell a random race joke",                        voice = true },
    { id = "FLEX",       name = "Flex",          slash = "/flex",       token = "FLEX",       icon = "Interface\\Icons\\Ability_GolemThunderClap",          category = "Animated",  desc = "Flex your muscles",                              voice = false },
    { id = "POINT",      name = "Point",         slash = "/point",      token = "POINT",      icon = "Interface\\Icons\\Ability_Hunter_SniperShot",         category = "Animated",  desc = "Point forward or at your target",                voice = false },
    { id = "ROAR",       name = "Roar",          slash = "/roar",       token = "ROAR",       icon = "Interface\\Icons\\Ability_Druid_ChallangingRoar",     category = "Animated",  desc = "Let out a fierce bestial roar",                  voice = true },
    { id = "BEG",        name = "Beg",           slash = "/beg",        token = "BEG",        icon = "Interface\\Icons\\INV_Misc_Coin_05",                  category = "Animated",  desc = "Drop to your knees and beg",                     voice = true },

    -- Reactions
    { id = "LAUGH",      name = "Laugh",         slash = "/laugh",      token = "LAUGH",      icon = "Interface\\Icons\\Spell_Shadow_LaughingSkull",        category = "Reactions", desc = "Laugh out loud",                                 voice = true },
    { id = "CHUCKLE",    name = "Chuckle",       slash = "/chuckle",    token = "CHUCKLE",    icon = "Interface\\Icons\\Spell_Shadow_LaughingSkull",        category = "Reactions", desc = "Chuckle heartily",                               voice = true },
    { id = "GIGGLE",     name = "Giggle",        slash = "/giggle",     token = "GIGGLE",     icon = "Interface\\Icons\\INV_Misc_Flower_02",                category = "Reactions", desc = "Giggle playfully",                               voice = true },
    { id = "CRY",        name = "Cry",           slash = "/cry",        token = "CRY",        icon = "Interface\\Icons\\Spell_Shadow_LifeDrain",            category = "Reactions", desc = "Sob and cry aloud",                              voice = true },
    { id = "SIGH",       name = "Sigh",          slash = "/sigh",       token = "SIGH",       icon = "Interface\\Icons\\Spell_Frost_WindWalkOn",            category = "Reactions", desc = "Let out a long sigh",                            voice = true },
    { id = "SHRUG",      name = "Shrug",         slash = "/shrug",      token = "SHRUG",      icon = "Interface\\Icons\\INV_Misc_QuestionMark",             category = "Reactions", desc = "Shrug in confusion",                             voice = false },
    { id = "FACEPALM",   name = "Facepalm",      slash = "/facepalm",   token = "FACEPALM",   icon = "Interface\\Icons\\Spell_Shadow_MindSteal",            category = "Reactions", desc = "Palm your face in disbelief",                    voice = false },
    { id = "GASP",       name = "Gasp",          slash = "/gasp",       token = "GASP",       icon = "Interface\\Icons\\Spell_Shadow_Possession",           category = "Reactions", desc = "Gasp in shock",                                  voice = true },
    { id = "BLUSH",      name = "Blush",         slash = "/blush",      token = "BLUSH",      icon = "Interface\\Icons\\Spell_Fire_Fire",                   category = "Reactions", desc = "Blush shyly",                                    voice = false },
    { id = "CLAP",       name = "Clap",          slash = "/clap",       token = "CLAP",       icon = "Interface\\Icons\\Ability_ThunderClap",               category = "Reactions", desc = "Clap your hands",                                voice = true },
    { id = "YES",        name = "Nod Yes",       slash = "/yes",        token = "YES",        icon = "Interface\\Icons\\Spell_ChargePositive",              category = "Reactions", desc = "Nod in agreement",                               voice = true },
    { id = "NO",         name = "Shake No",      slash = "/no",         token = "NO",         icon = "Interface\\Icons\\Spell_ChargeNegative",              category = "Reactions", desc = "Shake your head no",                             voice = true },
    { id = "BORED",      name = "Bored",         slash = "/bored",      token = "BORED",      icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",           category = "Reactions", desc = "Yawn and act bored",                             voice = true },
    { id = "CONFUSED",   name = "Confused",      slash = "/confused",   token = "CONFUSED",   icon = "Interface\\Icons\\Spell_Shadow_MindRot",              category = "Reactions", desc = "Scratch your head in confusion",                 voice = false },

    -- Combat & Tactical Voice
    { id = "CHARGE",     name = "Charge!",       slash = "/charge",     token = "CHARGE",     icon = "Interface\\Icons\\Ability_Warrior_Charge",            category = "Combat",    desc = "Order the group to charge!",                     voice = true },
    { id = "FLEE",       name = "Flee!",         slash = "/flee",       token = "FLEE",       icon = "Interface\\Icons\\Ability_Rogue_Sprint",              category = "Combat",    desc = "Yell for everyone to flee!",                     voice = true },
    { id = "FOLLOW",     name = "Follow Me",     slash = "/followme",   token = "FOLLOW",     icon = "Interface\\Icons\\Ability_Hunter_MendPet",            category = "Combat",    desc = "Motion for players to follow you",               voice = true },
    { id = "WAIT",       name = "Wait Here",     slash = "/wait",       token = "WAIT",       icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",           category = "Combat",    desc = "Ask everyone to wait",                           voice = true },
    { id = "HEALME",     name = "Heal Me!",      slash = "/healme",     token = "HEALME",     icon = "Interface\\Icons\\Spell_Holy_FlashHeal",              category = "Combat",    desc = "Call out for healing!",                          voice = true },
    { id = "OOM",        name = "Out of Mana",   slash = "/oom",        token = "OOM",        icon = "Interface\\Icons\\INV_Potion_76",                     category = "Combat",    desc = "Announce low mana",                              voice = true },
    { id = "ATTACKTARGET", name = "Attack!",     slash = "/attacktarget", token = "ATTACKTARGET", icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath", category = "Combat",    desc = "Tell everyone to attack your target",            voice = true },
    { id = "HELPME",     name = "Help Me!",      slash = "/helpme",     token = "HELPME",     icon = "Interface\\Icons\\Spell_Holy_AshesToAshes",           category = "Combat",    desc = "Cry out for assistance!",                        voice = true },
    { id = "OPENFIRE",   name = "Open Fire!",    slash = "/openfire",   token = "OPENFIRE",   icon = "Interface\\Icons\\Ability_Marksmanship",              category = "Combat",    desc = "Give the signal to open fire",                   voice = true },

    -- Taunts & Rivalry
    { id = "TAUNT",      name = "Taunt",         slash = "/taunt",      token = "TAUNT",      icon = "Interface\\Icons\\Spell_Nature_Reincarnation",        category = "Taunts",    desc = "Make a taunting gesture",                        voice = true },
    { id = "CHICKEN",    name = "Chicken",       slash = "/chicken",    token = "CHICKEN",    icon = "Interface\\Icons\\Spell_Magic_PolymorphChicken",      category = "Taunts",    desc = "Flap your arms and squawk like a chicken",       voice = true },
    { id = "RASP",       name = "Raspberry",     slash = "/rasp",       token = "RASP",       icon = "Interface\\Icons\\Ability_Creature_Cursed_04",        category = "Taunts",    desc = "Blow a rude raspberry",                          voice = true },
    { id = "RUDE",       name = "Rude",          slash = "/rude",       token = "RUDE",       icon = "Interface\\Icons\\Ability_Rogue_FeignDeath",          category = "Taunts",    desc = "Make a rude gesture",                            voice = false },
    { id = "SPIT",       name = "Spit",          slash = "/spit",       token = "SPIT",       icon = "Interface\\Icons\\Ability_Creature_Poison_02",        category = "Taunts",    desc = "Spit on the ground",                             voice = false },
    { id = "SLAP",       name = "Slap",          slash = "/slap",       token = "SLAP",       icon = "Interface\\Icons\\INV_Gauntlets_05",                  category = "Taunts",    desc = "Slap across the face",                           voice = false },
    { id = "THREATEN",   name = "Threaten",      slash = "/threaten",   token = "THREATEN",   icon = "Interface\\Icons\\Ability_Racial_BloodRage",          category = "Taunts",    desc = "Threaten with wrath",                            voice = false },
    { id = "CACKLE",     name = "Cackle",        slash = "/cackle",     token = "CACKLE",     icon = "Interface\\Icons\\Spell_Shadow_RagingScream",         category = "Taunts",    desc = "Cackle maniacally",                              voice = true },
    { id = "VIOLIN",     name = "Tiny Violin",   slash = "/violin",     token = "VIOLIN",     icon = "Interface\\Icons\\INV_Misc_Drum_01",                  category = "Taunts",    desc = "Play the world's smallest violin",               voice = true },
    { id = "BOO",        name = "Boo",           slash = "/boo",        token = "BOO",        icon = "Interface\\Icons\\Spell_Shadow_Haunting",             category = "Taunts",    desc = "Boo and jeer",                                   voice = true },
}

-- Map by ID for O(1) lookup, plus dropdown table for AceConfig
addon.EMOTE_BY_ID = {}
addon.EMOTE_DROPDOWN_VALUES = {}
for _, info in ipairs(addon.EMOTE_CATALOG) do
    addon.EMOTE_BY_ID[info.id] = info
    local iconTag = info.icon and ("|T" .. info.icon .. ":16:16:0:0|t ") or ""
    addon.EMOTE_DROPDOWN_VALUES[info.id] = string.format("%s%s  |cff888888(%s - %s)|r", iconTag, info.name, info.slash, info.category)
end

-- Default Favorites Wheel: Includes Sit, Lie Down, Sleep,Kneel, Dance, Wave, Cheer, Laugh, Bow, Salute, Point, Train!
addon.DEFAULT_FAVORITES = {
    "SIT",
    "LIEDOWN",
    "SLEEP",
    "DANCE",
    "WAVE",
    "KNEEL",
    "CHEER",
    "LAUGH",
    "BOW",
    "SALUTE",
    "POINT",
    "TRAIN",
}

addon.WHEEL_PAGES = {
    {
        id = "FAVORITES",
        name = "Favorites",
        shortName = "Favorites",
        color = { 1.00, 0.82, 0.25 },
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        isCustom = true,
    },
    {
        id = "POSES",
        name = "Poses & Rest",
        shortName = "Poses & Sit",
        color = { 0.85, 0.58, 1.00 },
        icon = "Interface\\Icons\\Spell_Nature_Sleep",
        emotes = { "SIT", "LIEDOWN", "SLEEP", "STAND", "KNEEL", "COWER", "EAT", "DRINK", "READ", "TALK", "LISTEN", "TIRED" },
    },
    {
        id = "GREETINGS",
        name = "Social & Friendly",
        shortName = "Social",
        color = { 0.30, 0.90, 0.50 },
        icon = "Interface\\Icons\\INV_Misc_Gift_01",
        emotes = { "WAVE", "HELLO", "BOW", "SALUTE", "THANK", "CHEER", "APPLAUD", "CONGRATS", "HUG", "KISS", "FLIRT", "BYE" },
    },
    {
        id = "ANIMATED",
        name = "Fun & Reactions",
        shortName = "Fun & Dance",
        color = { 0.35, 0.78, 1.00 },
        icon = "Interface\\Icons\\Spell_Shadow_Charm",
        emotes = { "DANCE", "TRAIN", "SILLY", "LAUGH", "CRY", "SHRUG", "FACEPALM", "FLEX", "ROAR", "YES", "NO", "BEG" },
    },
    {
        id = "COMBAT",
        name = "Tactical & Taunts",
        shortName = "Tactical",
        color = { 1.00, 0.38, 0.32 },
        icon = "Interface\\Icons\\Ability_Warrior_Charge",
        emotes = { "CHARGE", "FOLLOW", "WAIT", "HEALME", "OOM", "FLEE", "TAUNT", "CHICKEN", "VIOLIN", "CACKLE", "RUDE", "THREATEN" },
    },
}

-- =========================================================================
-- Database Initialization
-- =========================================================================

local DB_DEFAULTS = {
    mode = "BOTH",               -- "HOLD", "TOGGLE", "BOTH"
    spawnAtCursor = true,        -- True: opens at mouse cursor; False: opens at screen center
    scale = 1.0,                 -- Overall wheel scale (0.7 to 1.5)
    sliceCount = 8,              -- Number of slices on the Favorites wheel (4 to 12)
    soundEffects = true,         -- Play subtle UI tick sounds on hover/trigger
    closeOnTrigger = true,       -- Close wheel after performing an emote in Toggle mode
    showSlashText = true,        -- Show /command under emote name in center hub
    showMinimapButton = false,   -- Suite has its own hub minimap button; optional standalone minimap icon
    minimapAngle = 205,          -- Default minimap angle
    defaultPage = 1,             -- Starting page index (1 = Favorites)
    favorites = nil,             -- Populated from addon.DEFAULT_FAVORITES
    schemaVersion = 2,           -- Bumped so Sit & Lie Down populate on Favorites
}

function addon.GetDB()
    if type(TimelessForever_EmotesDB) ~= "table" then
        TimelessForever_EmotesDB = type(EmoteWheelDB) == "table" and EmoteWheelDB or {}
    end
    EmoteWheelDB = TimelessForever_EmotesDB

    for k, v in pairs(DB_DEFAULTS) do
        if TimelessForever_EmotesDB[k] == nil then
            if type(v) == "table" then
                TimelessForever_EmotesDB[k] = {}
                for tk, tv in pairs(v) do
                    TimelessForever_EmotesDB[k][tk] = tv
                end
            else
                TimelessForever_EmotesDB[k] = v
            end
        end
    end

    -- Upgrade schema v1 -> v2 so Sit, Lie Down, Sleep, Kneel are in the default Favorites
    if (TimelessForever_EmotesDB.schemaVersion or 1) < 2 then
        TimelessForever_EmotesDB.schemaVersion = 2
        TimelessForever_EmotesDB.favorites = nil
    end

    if type(TimelessForever_EmotesDB.favorites) ~= "table" or #TimelessForever_EmotesDB.favorites == 0 then
        TimelessForever_EmotesDB.favorites = {}
        for i, id in ipairs(addon.DEFAULT_FAVORITES) do
            TimelessForever_EmotesDB.favorites[i] = id
        end
    end

    for i = 1, 12 do
        local id = TimelessForever_EmotesDB.favorites[i]
        if not id or not addon.EMOTE_BY_ID[id] then
            TimelessForever_EmotesDB.favorites[i] = addon.DEFAULT_FAVORITES[i] or "SIT"
        end
    end
    return TimelessForever_EmotesDB
end

function addon.ResetFavorites()
    local db = addon.GetDB()
    db.favorites = {}
    for i, id in ipairs(addon.DEFAULT_FAVORITES) do
        db.favorites[i] = id
    end
    db.sliceCount = 8
end

-- =========================================================================
-- Safe Emote & Pose Execution (Sit, Lie Down, Stand, Sleep, DoEmote)
-- =========================================================================

function addon.PerformEmoteByInfo(info)
    if not info then return end

    -- Special handling for Sit ("SIT") so sitting works even with no target or when toggling stand
    if info.id == "SIT" then
        if type(DoEmote) == "function" then
            local ok = pcall(DoEmote, "SIT")
            if ok then return true end
        end
        if type(SitStandOrDescendStart) == "function" then
            pcall(SitStandOrDescendStart)
            return true
        end
    end

    -- Special handling for Lie Down ("LIEDOWN" -> LAYDOWN / LIE)
    if info.id == "LIEDOWN" and type(DoEmote) == "function" then
        local ok = pcall(DoEmote, "LAYDOWN")
        if ok then return true end
        local ok2 = pcall(DoEmote, "LIE")
        if ok2 then return true end
    end

    local targetUnit = nil
    if UnitExists("target") and not UnitIsUnit("target", "player") then
        -- Poses like SIT, LIEDOWN, SLEEP, STAND, KNEEL should not change pose into a chat-only target text if untargeted is desired,
        -- but DoEmote handles both cleanly. For pure body poses, pass nil target so the character always performs the physical pose!
        if info.category ~= "Poses" then
            targetUnit = "target"
        end
    end

    -- 1. Primary: DoEmote(token, target)
    if type(DoEmote) == "function" and info.token then
        local ok = pcall(DoEmote, info.token, targetUnit)
        if ok then
            return true
        end
    end

    -- 2. Fallback: ChatFrame EditBox command execution
    if info.slash and ChatFrame_OpenChat then
        local editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend() or DEFAULT_CHAT_FRAME.editBox
        if editBox then
            ChatEdit_ActivateChat(editBox)
            editBox:SetText(info.slash)
            ChatEdit_SendText(editBox, 0)
            return true
        end
    end

    return false
end

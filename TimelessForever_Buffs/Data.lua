local _, addon = ...

-- =========================================================================
-- TimelessForever_Buffs: Complete WoW Buff & Aura Catalog
-- =========================================================================

local _, playerClass = UnitClass("player")
addon.playerClass = playerClass or "WARRIOR"

addon.BUFF_CATALOG = {
    -- ---------------------------------------------------------------------
    -- PRIEST
    -- ---------------------------------------------------------------------
    {
        id = "PW_FORTITUDE",
        name = "Power Word: Fortitude",
        spellName = "Power Word: Fortitude",
        altSpells = { "Prayer of Fortitude" },
        checkAuras = { "Power Word: Fortitude", "Prayer of Fortitude" },
        icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
        class = "PRIEST",
        category = "Raid",
        isSelfOnly = false,
        desc = "Increases Stamina of target friendly player or party.",
    },
    {
        id = "INNER_FIRE",
        name = "Inner Fire",
        spellName = "Inner Fire",
        checkAuras = { "Inner Fire" },
        icon = "Interface\\Icons\\Spell_Holy_InnerFire",
        class = "PRIEST",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases your Armor and Attack Power / Spell Power.",
    },
    {
        id = "DIVINE_SPIRIT",
        name = "Divine Spirit",
        spellName = "Divine Spirit",
        altSpells = { "Prayer of Spirit" },
        checkAuras = { "Divine Spirit", "Prayer of Spirit" },
        icon = "Interface\\Icons\\Spell_Holy_DivineSpirit",
        class = "PRIEST",
        category = "Raid",
        isSelfOnly = false,
        desc = "Increases Spirit of target friendly player or party.",
    },
    {
        id = "SHADOW_PROTECTION",
        name = "Shadow Protection",
        spellName = "Shadow Protection",
        altSpells = { "Prayer of Shadow Protection" },
        checkAuras = { "Shadow Protection", "Prayer of Shadow Protection" },
        icon = "Interface\\Icons\\Spell_Shadow_AntiShadow",
        class = "PRIEST",
        category = "Raid",
        isSelfOnly = false,
        desc = "Increases Shadow Resistance of target friendly player.",
    },
    {
        id = "FEAR_WARD",
        name = "Fear Ward",
        spellName = "Fear Ward",
        checkAuras = { "Fear Ward" },
        icon = "Interface\\Icons\\Spell_Holy_Excorcism",
        class = "PRIEST",
        category = "Raid",
        isSelfOnly = false,
        desc = "Wards the target against the next Fear effect.",
    },
    {
        id = "PW_SHIELD",
        name = "Power Word: Shield",
        spellName = "Power Word: Shield",
        checkAuras = { "Power Word: Shield" },
        icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",
        class = "PRIEST",
        category = "Raid",
        isSelfOnly = false,
        desc = "Draws on the soul to absorb damage for 30 sec.",
    },
    {
        id = "LEVITATE",
        name = "Levitate",
        spellName = "Levitate",
        checkAuras = { "Levitate" },
        icon = "Interface\\Icons\\Spell_Holy_LayOnHands",
        class = "PRIEST",
        category = "Utility",
        isSelfOnly = false,
        desc = "Levitates the target, allowing water walking and slow falling.",
    },
    {
        id = "SHADOWFORM",
        name = "Shadowform",
        spellName = "Shadowform",
        checkAuras = { "Shadowform" },
        icon = "Interface\\Icons\\Spell_Shadow_Shadowform",
        class = "PRIEST",
        category = "Self",
        isSelfOnly = true,
        desc = "Assume a Shadowform, increasing shadow damage and physical defense.",
    },
    {
        id = "VAMPIRIC_EMBRACE",
        name = "Vampiric Embrace",
        spellName = "Vampiric Embrace",
        checkAuras = { "Vampiric Embrace" },
        icon = "Interface\\Icons\\Spell_Shadow_UnsummonBuilding",
        class = "PRIEST",
        category = "Self",
        isSelfOnly = true,
        desc = "Afflicts your shadow damage to heal party members.",
    },
    {
        id = "INNER_FOCUS",
        name = "Inner Focus",
        spellName = "Inner Focus",
        checkAuras = { "Inner Focus" },
        icon = "Interface\\Icons\\Spell_Frost_WindWalkOn",
        class = "PRIEST",
        category = "Self",
        isSelfOnly = true,
        desc = "Reduces the mana cost of your next spell by 100%.",
    },

    -- ---------------------------------------------------------------------
    -- MAGE
    -- ---------------------------------------------------------------------
    {
        id = "ARCANE_INTELLECT",
        name = "Arcane Intellect",
        spellName = "Arcane Intellect",
        altSpells = { "Arcane Brilliance" },
        checkAuras = { "Arcane Intellect", "Arcane Brilliance" },
        icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
        class = "MAGE",
        category = "Raid",
        isSelfOnly = false,
        desc = "Infuses the target with brilliance, increasing Intellect.",
    },
    {
        id = "ICE_ARMOR",
        name = "Ice Armor",
        spellName = "Ice Armor",
        altSpells = { "Frost Armor" },
        checkAuras = { "Ice Armor", "Frost Armor" },
        icon = "Interface\\Icons\\Spell_Frost_FrostArmor02",
        class = "MAGE",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases Armor and slows melee attackers' movement.",
    },
    {
        id = "MAGE_ARMOR",
        name = "Mage Armor",
        spellName = "Mage Armor",
        checkAuras = { "Mage Armor" },
        icon = "Interface\\Icons\\Spell_MageArmor",
        class = "MAGE",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases magic resistance and lets mana regenerate while casting.",
    },
    {
        id = "MOLTEN_ARMOR",
        name = "Molten Armor",
        spellName = "Molten Armor",
        checkAuras = { "Molten Armor" },
        icon = "Interface\\Icons\\Ability_Mage_MoltenArmor",
        class = "MAGE",
        category = "Self",
        isSelfOnly = true,
        desc = "Causes fire damage to attackers and increases critical strike chance.",
    },
    {
        id = "ICE_BARRIER",
        name = "Ice Barrier",
        spellName = "Ice Barrier",
        checkAuras = { "Ice Barrier" },
        icon = "Interface\\Icons\\Spell_Ice_Lament",
        class = "MAGE",
        category = "Self",
        isSelfOnly = true,
        desc = "Shields you in ice, absorbing damage and preventing pushback.",
    },
    {
        id = "MANA_SHIELD",
        name = "Mana Shield",
        spellName = "Mana Shield",
        checkAuras = { "Mana Shield" },
        icon = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility",
        class = "MAGE",
        category = "Self",
        isSelfOnly = true,
        desc = "Absorbs physical damage using mana.",
    },
    {
        id = "DAMPEN_MAGIC",
        name = "Dampen Magic",
        spellName = "Dampen Magic",
        checkAuras = { "Dampen Magic" },
        icon = "Interface\\Icons\\Spell_Nature_AbolishMagic",
        class = "MAGE",
        category = "Raid",
        isSelfOnly = false,
        desc = "Dampens magic against target, reducing spell damage and healing taken.",
    },
    {
        id = "AMPLIFY_MAGIC",
        name = "Amplify Magic",
        spellName = "Amplify Magic",
        checkAuras = { "Amplify Magic" },
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        class = "MAGE",
        category = "Raid",
        isSelfOnly = false,
        desc = "Amplifies magic on target, increasing spell damage and healing taken.",
    },
    {
        id = "SLOW_FALL",
        name = "Slow Fall",
        spellName = "Slow Fall",
        checkAuras = { "Slow Fall" },
        icon = "Interface\\Icons\\Spell_Magic_FeatherFall",
        class = "MAGE",
        category = "Utility",
        isSelfOnly = false,
        desc = "Slows the fall speed of target friendly player.",
    },
    {
        id = "ARCANE_POWER",
        name = "Arcane Power",
        spellName = "Arcane Power",
        checkAuras = { "Arcane Power" },
        icon = "Interface\\Icons\\Spell_Nature_Lightning",
        class = "MAGE",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases spell damage by 30% and mana cost by 30%.",
    },

    -- ---------------------------------------------------------------------
    -- DRUID
    -- ---------------------------------------------------------------------
    {
        id = "MARK_OF_THE_WILD",
        name = "Mark of the Wild",
        spellName = "Mark of the Wild",
        altSpells = { "Gift of the Wild" },
        checkAuras = { "Mark of the Wild", "Gift of the Wild" },
        icon = "Interface\\Icons\\Spell_Nature_Regeneration",
        class = "DRUID",
        category = "Raid",
        isSelfOnly = false,
        desc = "Increases Armor, all attributes, and all resistances.",
    },
    {
        id = "THORNS",
        name = "Thorns",
        spellName = "Thorns",
        checkAuras = { "Thorns" },
        icon = "Interface\\Icons\\Spell_Nature_Thorns",
        class = "DRUID",
        category = "Raid",
        isSelfOnly = false,
        desc = "Sprouts thorns on target, dealing nature damage to attackers.",
    },
    {
        id = "OMEN_OF_CLARITY",
        name = "Omen of Clarity",
        spellName = "Omen of Clarity",
        checkAuras = { "Omen of Clarity", "Clearcasting" },
        icon = "Interface\\Icons\\Spell_Nature_CrystalBall",
        class = "DRUID",
        category = "Self",
        isSelfOnly = true,
        desc = "Enter a focused trance; melee attacks may cause next spell to cost 0 mana/energy.",
    },
    {
        id = "BARKSKIN",
        name = "Barkskin",
        spellName = "Barkskin",
        checkAuras = { "Barkskin" },
        icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem",
        class = "DRUID",
        category = "Self",
        isSelfOnly = true,
        desc = "Skin becomes as tough as bark, reducing damage taken by 20%.",
    },
    {
        id = "NATURES_GRASP",
        name = "Nature's Grasp",
        spellName = "Nature's Grasp",
        checkAuras = { "Nature's Grasp" },
        icon = "Interface\\Icons\\Spell_Nature_NaturesWrath",
        class = "DRUID",
        category = "Self",
        isSelfOnly = true,
        desc = "Entangles enemies with roots upon receiving melee strikes.",
    },
    {
        id = "TIGERS_FURY",
        name = "Tiger's Fury",
        spellName = "Tiger's Fury",
        checkAuras = { "Tiger's Fury" },
        icon = "Interface\\Icons\\Ability_Mount_JungleTiger",
        class = "DRUID",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases physical damage for 6 sec.",
    },
    {
        id = "DASH",
        name = "Dash",
        spellName = "Dash",
        checkAuras = { "Dash" },
        icon = "Interface\\Icons\\Ability_Druid_Dash",
        class = "DRUID",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases movement speed in Cat Form by 50% for 15 sec.",
    },

    -- ---------------------------------------------------------------------
    -- PALADIN
    -- ---------------------------------------------------------------------
    {
        id = "BLESSING_OF_MIGHT",
        name = "Blessing of Might",
        spellName = "Blessing of Might",
        altSpells = { "Greater Blessing of Might" },
        checkAuras = { "Blessing of Might", "Greater Blessing of Might" },
        icon = "Interface\\Icons\\Spell_Holy_FistOfJustice",
        class = "PALADIN",
        category = "Raid",
        isSelfOnly = false,
        desc = "Blesses target player, increasing Attack Power.",
    },
    {
        id = "BLESSING_OF_WISDOM",
        name = "Blessing of Wisdom",
        spellName = "Blessing of Wisdom",
        altSpells = { "Greater Blessing of Wisdom" },
        checkAuras = { "Blessing of Wisdom", "Greater Blessing of Wisdom" },
        icon = "Interface\\Icons\\Spell_Holy_SealOfWisdom",
        class = "PALADIN",
        category = "Raid",
        isSelfOnly = false,
        desc = "Blesses target player, restoring mana every 5 sec.",
    },
    {
        id = "BLESSING_OF_KINGS",
        name = "Blessing of Kings",
        spellName = "Blessing of Kings",
        altSpells = { "Greater Blessing of Kings" },
        checkAuras = { "Blessing of Kings", "Greater Blessing of Kings" },
        icon = "Interface\\Icons\\Spell_Magic_MageArmor",
        class = "PALADIN",
        category = "Raid",
        isSelfOnly = false,
        desc = "Blesses target player, increasing all stats by 10%.",
    },
    {
        id = "BLESSING_OF_SANCTUARY",
        name = "Blessing of Sanctuary",
        spellName = "Blessing of Sanctuary",
        altSpells = { "Greater Blessing of Sanctuary" },
        checkAuras = { "Blessing of Sanctuary", "Greater Blessing of Sanctuary" },
        icon = "Interface\\Icons\\Spell_Nature_LightningShield",
        class = "PALADIN",
        category = "Raid",
        isSelfOnly = false,
        desc = "Reduces damage taken from all sources by flat amount.",
    },
    {
        id = "BLESSING_OF_SALVATION",
        name = "Blessing of Salvation",
        spellName = "Blessing of Salvation",
        altSpells = { "Greater Blessing of Salvation" },
        checkAuras = { "Blessing of Salvation", "Greater Blessing of Salvation" },
        icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation",
        class = "PALADIN",
        category = "Raid",
        isSelfOnly = false,
        desc = "Reduces threat generated by target player by 30%.",
    },
    {
        id = "DEVOTION_AURA",
        name = "Devotion Aura",
        spellName = "Devotion Aura",
        checkAuras = { "Devotion Aura" },
        icon = "Interface\\Icons\\Spell_Holy_DevotionAura",
        class = "PALADIN",
        category = "Aura",
        isSelfOnly = true,
        desc = "Gives additional armor to nearby party members.",
    },
    {
        id = "RETRIBUTION_AURA",
        name = "Retribution Aura",
        spellName = "Retribution Aura",
        checkAuras = { "Retribution Aura" },
        icon = "Interface\\Icons\\Spell_Holy_AuraOfLight",
        class = "PALADIN",
        category = "Aura",
        isSelfOnly = true,
        desc = "Causes Holy damage to anyone who attacks party members.",
    },
    {
        id = "CONCENTRATION_AURA",
        name = "Concentration Aura",
        spellName = "Concentration Aura",
        checkAuras = { "Concentration Aura" },
        icon = "Interface\\Icons\\Spell_Holy_MindSooth",
        class = "PALADIN",
        category = "Aura",
        isSelfOnly = true,
        desc = "Reduces casting pushback by 35% for party members.",
    },
    {
        id = "CRUSADER_AURA",
        name = "Crusader Aura",
        spellName = "Crusader Aura",
        checkAuras = { "Crusader Aura" },
        icon = "Interface\\Icons\\Spell_Holy_CrusaderAura",
        class = "PALADIN",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases mounted movement speed by 20% for party members.",
    },
    {
        id = "RIGHTEOUS_FURY",
        name = "Righteous Fury",
        spellName = "Righteous Fury",
        checkAuras = { "Righteous Fury" },
        icon = "Interface\\Icons\\Spell_Holy_SealOfFury",
        class = "PALADIN",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases threat generated by your Holy attacks by 60%.",
    },
    {
        id = "SEAL_OF_RIGHTEOUSNESS",
        name = "Seal of Righteousness",
        spellName = "Seal of Righteousness",
        checkAuras = { "Seal of Righteousness" },
        icon = "Interface\\Icons\\Ability_ThunderBolt",
        class = "PALADIN",
        category = "Aura",
        isSelfOnly = true,
        desc = "Fills you with holy spirit, dealing holy damage on each melee strike.",
    },
    {
        id = "SEAL_OF_COMMAND",
        name = "Seal of Command",
        spellName = "Seal of Command",
        checkAuras = { "Seal of Command" },
        icon = "Interface\\Icons\\Ability_Warrior_InnerRage",
        class = "PALADIN",
        category = "Aura",
        isSelfOnly = true,
        desc = "Melee attacks have a chance to deal 70% weapon damage as Holy.",
    },

    -- ---------------------------------------------------------------------
    -- WARLOCK
    -- ---------------------------------------------------------------------
    {
        id = "DEMON_ARMOR",
        name = "Demon Armor",
        spellName = "Demon Armor",
        altSpells = { "Demon Skin" },
        checkAuras = { "Demon Armor", "Demon Skin" },
        icon = "Interface\\Icons\\Spell_Shadow_RagingScream",
        class = "WARLOCK",
        category = "Self",
        isSelfOnly = true,
        desc = "Protects the caster, increasing armor and health regeneration.",
    },
    {
        id = "FEL_ARMOR",
        name = "Fel Armor",
        spellName = "Fel Armor",
        checkAuras = { "Fel Armor" },
        icon = "Interface\\Icons\\Spell_Shadow_FelMageArmor",
        class = "WARLOCK",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases your spell damage and healing received by 20%.",
    },
    {
        id = "UNENDING_BREATH",
        name = "Unending Breath",
        spellName = "Unending Breath",
        checkAuras = { "Unending Breath" },
        icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
        class = "WARLOCK",
        category = "Utility",
        isSelfOnly = false,
        desc = "Allows the target to breathe underwater for 10 min.",
    },
    {
        id = "DETECT_INVISIBILITY",
        name = "Detect Invisibility",
        spellName = "Detect Invisibility",
        altSpells = { "Detect Lesser Invisibility" },
        checkAuras = { "Detect Invisibility", "Detect Lesser Invisibility" },
        icon = "Interface\\Icons\\Spell_Shadow_DetectInvisibility",
        class = "WARLOCK",
        category = "Utility",
        isSelfOnly = false,
        desc = "Grants the target the ability to detect invisible creatures.",
    },
    {
        id = "SOUL_LINK",
        name = "Soul Link",
        spellName = "Soul Link",
        checkAuras = { "Soul Link" },
        icon = "Interface\\Icons\\Spell_Shadow_GatherShadows",
        class = "WARLOCK",
        category = "Self",
        isSelfOnly = true,
        desc = "20% of damage taken by the caster is transferred to their demon.",
    },
    {
        id = "SHADOW_WARD",
        name = "Shadow Ward",
        spellName = "Shadow Ward",
        checkAuras = { "Shadow Ward" },
        icon = "Interface\\Icons\\Spell_Shadow_AntiShadow",
        class = "WARLOCK",
        category = "Self",
        isSelfOnly = true,
        desc = "Absorbs Shadow damage for 30 sec.",
    },

    -- ---------------------------------------------------------------------
    -- SHAMAN
    -- ---------------------------------------------------------------------
    {
        id = "LIGHTNING_SHIELD",
        name = "Lightning Shield",
        spellName = "Lightning Shield",
        checkAuras = { "Lightning Shield" },
        icon = "Interface\\Icons\\Spell_Nature_LightningShield",
        class = "SHAMAN",
        category = "Self",
        isSelfOnly = true,
        desc = "Surrounds you with lightning orbs, dealing nature damage to attackers.",
    },
    {
        id = "WATER_SHIELD",
        name = "Water Shield",
        spellName = "Water Shield",
        checkAuras = { "Water Shield" },
        icon = "Interface\\Icons\\Ability_Shaman_WaterShield",
        class = "SHAMAN",
        category = "Self",
        isSelfOnly = true,
        desc = "Surrounds you with water globes, restoring mana when attacked.",
    },
    {
        id = "EARTH_SHIELD",
        name = "Earth Shield",
        spellName = "Earth Shield",
        checkAuras = { "Earth Shield" },
        icon = "Interface\\Icons\\Spell_Nature_SkinofEarth",
        class = "SHAMAN",
        category = "Raid",
        isSelfOnly = false,
        desc = "Shields friendly target with earthen plates, healing when attacked.",
    },
    {
        id = "WINDFURY_WEAPON",
        name = "Windfury Weapon",
        spellName = "Windfury Weapon",
        isWeaponImbue = true,
        icon = "Interface\\Icons\\Spell_Nature_Cyclone",
        class = "SHAMAN",
        category = "Weapon",
        isSelfOnly = true,
        desc = "Imbues your main-hand weapon with the wind for extra strikes.",
    },
    {
        id = "FLAMETONGUE_WEAPON",
        name = "Flametongue Weapon",
        spellName = "Flametongue Weapon",
        isWeaponImbue = true,
        icon = "Interface\\Icons\\Spell_Fire_FlameTounge",
        class = "SHAMAN",
        category = "Weapon",
        isSelfOnly = true,
        desc = "Imbues weapon with fire, dealing extra fire damage on hit.",
    },
    {
        id = "FROSTBRAND_WEAPON",
        name = "Frostbrand Weapon",
        spellName = "Frostbrand Weapon",
        isWeaponImbue = true,
        icon = "Interface\\Icons\\Spell_Frost_FrostBrand",
        class = "SHAMAN",
        category = "Weapon",
        isSelfOnly = true,
        desc = "Imbues weapon with frost, slowing enemy movement on hit.",
    },
    {
        id = "ROCKBITER_WEAPON",
        name = "Rockbiter Weapon",
        spellName = "Rockbiter Weapon",
        isWeaponImbue = true,
        icon = "Interface\\Icons\\Spell_Nature_RockBiter",
        class = "SHAMAN",
        category = "Weapon",
        isSelfOnly = true,
        desc = "Imbues weapon with earth, greatly increasing attack power and threat.",
    },
    {
        id = "WATER_WALKING",
        name = "Water Walking",
        spellName = "Water Walking",
        checkAuras = { "Water Walking" },
        icon = "Interface\\Icons\\Spell_Frost_WindWalkOn",
        class = "SHAMAN",
        category = "Utility",
        isSelfOnly = false,
        desc = "Allows target friendly player to walk across water.",
    },
    {
        id = "WATER_BREATHING",
        name = "Water Breathing",
        spellName = "Water Breathing",
        checkAuras = { "Water Breathing" },
        icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
        class = "SHAMAN",
        category = "Utility",
        isSelfOnly = false,
        desc = "Allows target friendly player to breathe underwater.",
    },

    -- ---------------------------------------------------------------------
    -- WARRIOR
    -- ---------------------------------------------------------------------
    {
        id = "BATTLE_SHOUT",
        name = "Battle Shout",
        spellName = "Battle Shout",
        checkAuras = { "Battle Shout" },
        icon = "Interface\\Icons\\Ability_Warrior_BattleShout",
        class = "WARRIOR",
        category = "Raid",
        isSelfOnly = true,
        desc = "Increases melee attack power of all party members.",
    },
    {
        id = "COMMANDING_SHOUT",
        name = "Commanding Shout",
        spellName = "Commanding Shout",
        checkAuras = { "Commanding Shout" },
        icon = "Interface\\Icons\\Ability_Warrior_RallyingCry",
        class = "WARRIOR",
        category = "Raid",
        isSelfOnly = true,
        desc = "Increases maximum health of all party members.",
    },
    {
        id = "BERSERKER_RAGE",
        name = "Berserker Rage",
        spellName = "Berserker Rage",
        checkAuras = { "Berserker Rage" },
        icon = "Interface\\Icons\\Spell_Nature_AncestralGuardian",
        class = "WARRIOR",
        category = "Self",
        isSelfOnly = true,
        desc = "Enter a berserker rage, becoming immune to Fear and Incapacitate.",
    },
    {
        id = "BLOODRAGE",
        name = "Bloodrage",
        spellName = "Bloodrage",
        checkAuras = { "Bloodrage" },
        icon = "Interface\\Icons\\Ability_Racial_BloodRage",
        class = "WARRIOR",
        category = "Self",
        isSelfOnly = true,
        desc = "Generates 20 Rage at the cost of health.",
    },
    {
        id = "SHIELD_BLOCK",
        name = "Shield Block",
        spellName = "Shield Block",
        checkAuras = { "Shield Block" },
        icon = "Interface\\Icons\\Ability_Defend",
        class = "WARRIOR",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases chance to block attacks by 75% for 5 sec.",
    },

    -- ---------------------------------------------------------------------
    -- ROGUE
    -- ---------------------------------------------------------------------
    {
        id = "STEALTH",
        name = "Stealth",
        spellName = "Stealth",
        checkAuras = { "Stealth", "Prowl", "Shadowmeld", "Vanish" },
        icon = "Interface\\Icons\\Ability_Stealth",
        class = "ROGUE",
        category = "Self",
        isSelfOnly = true,
        desc = "Conceals you in the shadows until cancelled or detected.",
    },
    {
        id = "SPRINT",
        name = "Sprint",
        spellName = "Sprint",
        checkAuras = { "Sprint" },
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        class = "ROGUE",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases movement speed by 70% for 15 sec.",
    },
    {
        id = "EVASION",
        name = "Evasion",
        spellName = "Evasion",
        checkAuras = { "Evasion" },
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWard",
        class = "ROGUE",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases dodge chance by 50% for 15 sec.",
    },
    {
        id = "BLADE_FLURRY",
        name = "Blade Flurry",
        spellName = "Blade Flurry",
        checkAuras = { "Blade Flurry" },
        icon = "Interface\\Icons\\Ability_Warrior_PunishingBlow",
        class = "ROGUE",
        category = "Self",
        isSelfOnly = true,
        desc = "Increases attack speed by 20% and strikes an extra nearby enemy.",
    },

    -- ---------------------------------------------------------------------
    -- HUNTER
    -- ---------------------------------------------------------------------
    {
        id = "ASPECT_OF_THE_HAWK",
        name = "Aspect of the Hawk",
        spellName = "Aspect of the Hawk",
        checkAuras = { "Aspect of the Hawk", "Aspect of the Dragonhawk" },
        icon = "Interface\\Icons\\Spell_Nature_RavenForm",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "The hunter takes on the aspect of a hawk, increasing ranged attack power.",
    },
    {
        id = "ASPECT_OF_THE_MONKEY",
        name = "Aspect of the Monkey",
        spellName = "Aspect of the Monkey",
        checkAuras = { "Aspect of the Monkey" },
        icon = "Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases dodge chance by 8%.",
    },
    {
        id = "ASPECT_OF_THE_CHEETAH",
        name = "Aspect of the Cheetah",
        spellName = "Aspect of the Cheetah",
        checkAuras = { "Aspect of the Cheetah" },
        icon = "Interface\\Icons\\Ability_Mount_JungleTiger",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases movement speed by 30%. Being hit dazes you for 4 sec.",
    },
    {
        id = "ASPECT_OF_THE_PACK",
        name = "Aspect of the Pack",
        spellName = "Aspect of the Pack",
        checkAuras = { "Aspect of the Pack" },
        icon = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases movement speed of nearby party members by 30%.",
    },
    {
        id = "ASPECT_OF_THE_WILD",
        name = "Aspect of the Wild",
        spellName = "Aspect of the Wild",
        checkAuras = { "Aspect of the Wild" },
        icon = "Interface\\Icons\\Spell_Nature_ProtectionformNature",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases nature resistance for party members.",
    },
    {
        id = "ASPECT_OF_THE_VIPER",
        name = "Aspect of the Viper",
        spellName = "Aspect of the Viper",
        checkAuras = { "Aspect of the Viper" },
        icon = "Interface\\Icons\\Ability_Hunter_AspectOfTheViper",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "Ranged auto-attacks regenerate mana.",
    },
    {
        id = "TRUESHOT_AURA",
        name = "Trueshot Aura",
        spellName = "Trueshot Aura",
        checkAuras = { "Trueshot Aura" },
        icon = "Interface\\Icons\\Ability_TrueShot",
        class = "HUNTER",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases attack power for nearby party members.",
    },

    -- ---------------------------------------------------------------------
    -- DEATH KNIGHT
    -- ---------------------------------------------------------------------
    {
        id = "HORN_OF_WINTER",
        name = "Horn of Winter",
        spellName = "Horn of Winter",
        checkAuras = { "Horn of Winter" },
        icon = "Interface\\Icons\\INV_Misc_Horn_02",
        class = "DEATHKNIGHT",
        category = "Raid",
        isSelfOnly = true,
        desc = "Increases total Strength and Agility of all party members.",
    },
    {
        id = "BONE_SHIELD",
        name = "Bone Shield",
        spellName = "Bone Shield",
        checkAuras = { "Bone Shield" },
        icon = "Interface\\Icons\\INV_Chest_Cloth_17",
        class = "DEATHKNIGHT",
        category = "Self",
        isSelfOnly = true,
        desc = "Surrounds the death knight with whirling bones, reducing damage taken by 20%.",
    },
    {
        id = "BLOOD_PRESENCE",
        name = "Blood Presence",
        spellName = "Blood Presence",
        checkAuras = { "Blood Presence" },
        icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence",
        class = "DEATHKNIGHT",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases damage by 15% and heals you for 4% of damage dealt.",
    },
    {
        id = "FROST_PRESENCE",
        name = "Frost Presence",
        spellName = "Frost Presence",
        checkAuras = { "Frost Presence" },
        icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
        class = "DEATHKNIGHT",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases Stamina and armor contribution, increasing threat.",
    },
    {
        id = "UNHOLY_PRESENCE",
        name = "Unholy Presence",
        spellName = "Unholy Presence",
        checkAuras = { "Unholy Presence" },
        icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence",
        class = "DEATHKNIGHT",
        category = "Aura",
        isSelfOnly = true,
        desc = "Increases attack and movement speed, and reduces global cooldown.",
    },
    {
        id = "PATH_OF_FROST",
        name = "Path of Frost",
        spellName = "Path of Frost",
        checkAuras = { "Path of Frost" },
        icon = "Interface\\Icons\\Spell_DeathKnight_PathOfFrost",
        class = "DEATHKNIGHT",
        category = "Utility",
        isSelfOnly = true,
        desc = "Freezes water beneath party members, allowing them to walk across water.",
    },
}

-- Map by ID and Dropdown values
addon.BUFF_BY_ID = {}
addon.BUFF_DROPDOWN_VALUES = {}
for _, info in ipairs(addon.BUFF_CATALOG) do
    addon.BUFF_BY_ID[info.id] = info
    local iconTag = info.icon and ("|T" .. info.icon .. ":16:16:0:0|t ") or ""
    addon.BUFF_DROPDOWN_VALUES[info.id] = string.format("%s%s  |cff888888(%s)|r", iconTag, info.name, info.class)
end

-- =========================================================================
-- Dynamic Spellbook Scanner (Detects which buffs player actually has learned)
-- =========================================================================

addon.knownBuffIDs = {}
addon.knownBuffList = {}

function addon.ScanSpellbook()
    local _, pClass = UnitClass("player")
    if pClass then addon.playerClass = pClass end

    addon.knownBuffIDs = {}
    addon.knownBuffList = {}

    local knownSpellNames = {}

    -- Scan modern C_SpellBook or legacy spell tabs
    if C_SpellBook and C_SpellBook.GetNumSpellBookItems and C_SpellBook.GetSpellBookItemName then
        local num = C_SpellBook.GetNumSpellBookItems() or 120
        for slot = 1, num do
            local name = C_SpellBook.GetSpellBookItemName(slot, Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0)
            if name and name ~= "" then
                knownSpellNames[name:lower()] = true
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local numTabs = GetNumSpellTabs()
        for tab = 1, numTabs do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            if offset and numSpells then
                for i = 1, numSpells do
                    local slot = offset + i
                    local name = GetSpellBookItemName(slot, BOOKTYPE_SPELL or "spell")
                    if name and name ~= "" then
                        knownSpellNames[name:lower()] = true
                    end
                end
            end
        end
    end

    -- Match against catalog
    for _, info in ipairs(addon.BUFF_CATALOG) do
        local isKnown = false
        if knownSpellNames[info.spellName:lower()] then
            isKnown = true
        elseif info.altSpells then
            for _, alt in ipairs(info.altSpells) do
                if knownSpellNames[alt:lower()] then
                    isKnown = true
                    break
                end
            end
        end

        -- Fallback check for IsPlayerSpell / IsSpellKnown
        if not isKnown and IsSpellKnown then
            local ok, known = pcall(IsSpellKnown, info.spellName)
            if ok and known then isKnown = true end
        end

        if isKnown then
            addon.knownBuffIDs[info.id] = true
            table.insert(addon.knownBuffList, info)
        end
    end

    return addon.knownBuffList
end

-- Generates default favorites based on what buffs player knows for their class
function addon.GetDefaultClassFavorites()
    local favs = {}
    local classBuffs = {}

    for _, info in ipairs(addon.BUFF_CATALOG) do
        if info.class == addon.playerClass or info.class == "ALL" then
            table.insert(classBuffs, info)
        end
    end

    for i = 1, math.min(12, #classBuffs) do
        table.insert(favs, classBuffs[i].id)
    end

    -- Fill remaining up to 8 if needed
    while #favs < 8 and #classBuffs > 0 do
        table.insert(favs, classBuffs[1].id)
    end

    return favs
end

-- =========================================================================
-- Active Buff & Aura Detection
-- =========================================================================

function addon.GetBuffStatus(buffInfo, unit)
    if not buffInfo then return false, 0, 0 end
    unit = unit or "player"

    -- 1. Check weapon enchants for Shaman imbues & Rogue poisons
    if buffInfo.isWeaponImbue and unit == "player" then
        if GetWeaponEnchantInfo then
            local hasMain, mainExp, _, _, hasOff, offExp = GetWeaponEnchantInfo()
            if hasMain then
                local remainSec = (mainExp or 0) / 1000
                return true, 1800, GetTime() + remainSec, 1
            elseif hasOff then
                local remainSec = (offExp or 0) / 1000
                return true, 1800, GetTime() + remainSec, 1
            end
        end
        return false, 0, 0
    end

    -- 2. Check UnitAuras / UnitBuff
    local checkNames = buffInfo.checkAuras or { buffInfo.spellName }
    local checkLookup = {}
    for _, name in ipairs(checkNames) do
        checkLookup[name:lower()] = true
    end

    -- Check modern C_UnitAuras
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if ok then
                if not aura then break end
                local auraName = nil
                pcall(function() auraName = aura.name end)
                if auraName and checkLookup[auraName:lower()] then
                    local dur = 0
                    local exp = 0
                    local stacks = 1
                    pcall(function() dur = aura.duration or 0 end)
                    pcall(function() exp = aura.expirationTime or 0 end)
                    pcall(function() stacks = aura.applications or 1 end)
                    return true, dur, exp, stacks
                end
            end
            -- If pcall failed (e.g. secret/private aura blocked by engine), safely continue
        end
    elseif UnitBuff then
        for i = 1, 40 do
            local ok, name, icon, count, debuffType, duration, expirationTime = pcall(UnitBuff, unit, i)
            if ok then
                if not name then break end
                if checkLookup[name:lower()] then
                    return true, duration or 0, expirationTime or 0, count or 1
                end
            end
        end
    end

    return false, 0, 0
end

-- =========================================================================
-- Wheel Pages Definitions
-- =========================================================================

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
        id = "CLASS",
        name = "Known Class Buffs",
        shortName = "My Buffs",
        color = { 0.25, 0.85, 1.00 },
        icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
        isClassDynamic = true,
    },
    {
        id = "SELF_ARMORS",
        name = "Armors & Self Buffs",
        shortName = "Armors",
        color = { 0.90, 0.55, 0.25 },
        icon = "Interface\\Icons\\Spell_Holy_InnerFire",
        categoryFilter = "Self",
    },
    {
        id = "RAID_PARTY",
        name = "Raid & Party Buffs",
        shortName = "Party/Raid",
        color = { 0.35, 0.95, 0.50 },
        icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
        categoryFilter = "Raid",
    },
    {
        id = "AURAS_IMBUES",
        name = "Auras & Imbues",
        shortName = "Auras/Imbues",
        color = { 0.80, 0.45, 1.00 },
        icon = "Interface\\Icons\\Spell_Holy_DevotionAura",
        categoryFilter = { "Aura", "Weapon", "Utility" },
    },
}

-- =========================================================================
-- Database & SavedVariables
-- =========================================================================

local DB_DEFAULTS = {
    mode = "TOGGLE",              -- "TOGGLE" (recommended), "HOLD"
    spawnAtCursor = true,        -- True: opens at mouse cursor; False: opens at screen center
    scale = 1.0,                 -- Overall wheel scale (0.7 to 1.5)
    sliceCount = 8,              -- Number of slices on the Favorites wheel (4 to 12)
    soundEffects = true,         -- Play subtle UI audio ticks on hover/cast
    closeOnCast = true,          -- Close wheel after casting a buff
    showDurationText = true,     -- Show remaining buff duration / checkmark on slices
    showMinimapButton = false,   -- Optional standalone minimap icon
    minimapAngle = 210,
    defaultPage = 1,
    favorites = nil,             -- Auto-populated from player class
}

function addon.GetDB()
    if type(TimelessForever_BuffsDB) ~= "table" then
        TimelessForever_BuffsDB = type(BuffWheelDB) == "table" and BuffWheelDB or {}
    end
    BuffWheelDB = TimelessForever_BuffsDB

    for k, v in pairs(DB_DEFAULTS) do
        if TimelessForever_BuffsDB[k] == nil then
            if type(v) == "table" then
                TimelessForever_BuffsDB[k] = {}
                for tk, tv in pairs(v) do
                    TimelessForever_BuffsDB[k][tk] = tv
                end
            else
                TimelessForever_BuffsDB[k] = v
            end
        end
    end

    if type(TimelessForever_BuffsDB.favorites) ~= "table" or #TimelessForever_BuffsDB.favorites == 0 then
        TimelessForever_BuffsDB.favorites = addon.GetDefaultClassFavorites()
    end

    -- Ensure valid entries
    for i = 1, 12 do
        local id = TimelessForever_BuffsDB.favorites[i]
        if not id or not addon.BUFF_BY_ID[id] then
            local def = addon.GetDefaultClassFavorites()
            TimelessForever_BuffsDB.favorites[i] = def[i] or def[1] or "PW_FORTITUDE"
        end
    end

    return TimelessForever_BuffsDB
end

function addon.ResetFavorites()
    local db = addon.GetDB()
    db.favorites = addon.GetDefaultClassFavorites()
    db.sliceCount = 8
end

-- =========================================================================
-- Smart Macro Generator for Secure Action Buttons
-- =========================================================================

function addon.GetCastMacroText(buffInfo)
    if not buffInfo then return "" end

    local spell = buffInfo.spellName

    -- For Shaman weapon imbues / enchants:
    if buffInfo.isWeaponImbue then
        return "/dismount [mounted]\n/cast " .. spell .. "\n/use 16"
    end

    -- For Druid shapeshift safety (automatically cancels form for caster spells):
    local cancelForm = ""
    if addon.playerClass == "DRUID" and buffInfo.id ~= "TIGERS_FURY" and buffInfo.id ~= "DASH" then
        cancelForm = "/cancelform [form]\n"
    end

    -- For self-only buffs (armors, shields, stances, aspects):
    if buffInfo.isSelfOnly then
        return "/dismount [mounted]\n" .. cancelForm .. "/cast [@player] " .. spell
    else
        -- For targetable raid/party buffs:
        return "/dismount [mounted]\n" .. cancelForm .. "/cast [help,nodead][@player] " .. spell
    end
end

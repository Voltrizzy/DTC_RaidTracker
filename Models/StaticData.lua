local folderName, DTC = ...
DTC.Static = {}

-- 1. Expansion Names
DTC.Static.EXPANSION_NAMES = {
    [0]="Classic", [1]="Burning Crusade", [2]="Wrath of the Lich King", 
    [3]="Cataclysm", [4]="Mists of Pandaria", [5]="Warlords of Draenor", 
    [6]="Legion", [7]="Battle for Azeroth", [8]="Shadowlands", 
    [9]="Dragonflight", [10]="The War Within", [11]="Midnight"
}

-- 2. Raid List (Map Exp ID -> List of Raid Names)
DTC.Static.RAID_DATA = {
    [0] = { "Molten Core", "Blackwing Lair", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas", "Onyxia's Lair" },
    [1] = { "Karazhan", "Gruul's Lair", "Magtheridon's Lair", "Serpentshrine Cavern", "The Eye", "Mount Hyjal", "Black Temple", "Sunwell Plateau" },
    [2] = { "Naxxramas (WotLK)", "Ulduar", "Trial of the Crusader", "Icecrown Citadel", "Ruby Sanctum", "Obsidian Sanctum", "Eye of Eternity", "Vault of Archavon" },
    [3] = { "Bastion of Twilight", "Blackwing Descent", "Throne of the Four Winds", "Firelands", "Dragon Soul", "Baradin Hold" },
    [4] = { "Mogu'shan Vaults", "Heart of Fear", "Terrace of Endless Spring", "Throne of Thunder", "Siege of Orgrimmar" },
    [5] = { "Highmaul", "Blackrock Foundry", "Hellfire Citadel" },
    [6] = { "Emerald Nightmare", "Trial of Valor", "Nighthold", "Tomb of Sargeras", "Antorus, the Burning Throne" },
    [7] = { "Uldir", "Battle of Dazar'alor", "Crucible of Storms", "The Eternal Palace", "Ny'alotha" },
    [8] = { "Castle Nathria", "Sanctum of Domination", "Sepulcher of the First Ones" },
    [9] = { "Vault of the Incarnates", "Aberrus, the Shadowed Crucible", "Amirdrassil, the Dream's Hope" },
    [10] = { "Nerub-ar Palace", "Liberation of Undermine", "Manaforge Omega" },
    [11] = { "The Voidspire", "The Dreamrift", "March on Quel'Danas" }
}

-- 3. Boss Lists (Map Raid Name -> List of Boss Names)
DTC.Static.BOSS_DATA = {
    -- MIDNIGHT (Patch 12.0)
    ["The Voidspire"] = { "Imperator Averzian", "Vorasius", "Fallen-King Salhadaar", "Vaelgor & Ezzorak", "Lightblinded Vanguard", "Crown of the Cosmos" },
    ["The Dreamrift"] = { "Chimaerus, the Undreamt God" },
    ["March on Quel'Danas"] = { "Belo'ren, Child of Al'ar", "Midnight Falls" },

    -- THE WAR WITHIN (Patches 11.0 - 11.2)
    ["Nerub-ar Palace"] = { "Ulgrax the Devourer", "The Bloodbound Horror", "Sikran", "Rasha'nan", "Eggtender Ovi'nax", "Nexus-Princess Ky'veza", "The Silken Court", "Queen Ansurek" },
    ["Liberation of Undermine"] = { "Vexie and the Geargrinders", "Cauldron of Carnage", "Rik Reverb", "Stix Bunkjunker", "Sprocketmonger Lockenstock", "The One-Armed Bandit", "Mug'Zee, Heads of Security", "Chrome King Gallywix" },
    ["Manaforge Omega"] = { "Plexus Sentinel", "Loom'ithar", "Soulbinder Naazindhri", "Forgeweaver Araz", "The Soul Hunters", "Fractillus", "Nexus-King Salhadaar", "Dimensius, the All-Devouring" },

    -- DRAGONFLIGHT
    ["Amirdrassil, the Dream's Hope"] = { "Gnarlroot", "Igira the Cruel", "Volcoross", "Council of Dreams", "Larodar, Keeper of the Flame", "Nymue", "Smolderon", "Tindral Sageswift", "Fyrakk the Blazing" },
    ["Aberrus, the Shadowed Crucible"] = { "Kazzara", "The Amalgamation Chamber", "The Forgotten Experiments", "Assault of the Zaqali", "Rashok", "The Vigilant Steward, Zskarn", "Magmorax", "Echo of Neltharion", "Scalecommander Sarkareth" },
    ["Vault of the Incarnates"] = { "Eranog", "Terros", "The Primal Council", "Sennarth", "Dathea", "Kurog Grimtotem", "Broodkeeper Diurna", "Raszageth" },

    -- SHADOWLANDS
    ["Sepulcher of the First Ones"] = { "Vigilant Guardian", "Skolex", "Artificer Xy'mox", "Dausegne", "Prototype Pantheon", "Lihuvim", "Halondrus", "Anduin Wrynn", "Lords of Dread", "Rygelon", "The Jailer" },
    ["Sanctum of Domination"] = { "The Tarragrue", "Eye of the Jailer", "The Nine", "Remnant of Ner'zhul", "Soulrender Dormazain", "Painsmith Raznal", "Guardian of the First Ones", "Fatescribe Roh-Kalo", "Kel'Thuzad", "Sylvanas Windrunner" },
    ["Castle Nathria"] = { "Shriekwing", "Huntsman Altimor", "Sun King's Salvation", "Artificer Xy'mox", "Hungering Destroyer", "Lady Inerva Darkvein", "Council of Blood", "Sludgefist", "Stone Legion Generals", "Sire Denathrius" },

    -- BATTLE FOR AZEROTH
    ["Ny'alotha"] = { "Wrathion", "Maut", "Prophet Skitra", "Dark Inquisitor Xanesh", "The Hivemind", "Shad'har the Insatiable", "Drest'agath", "Il'gynoth", "Vexiona", "Ra-den the Despoiled", "Carapace of N'Zoth", "N'Zoth the Corruptor" },
    ["The Eternal Palace"] = { "Abyssal Commander Sivara", "Blackwater Behemoth", "Radiance of Azshara", "Lady Ashvane", "Orgozoa", "The Queen's Court", "Za'qul", "Queen Azshara" },
    ["Crucible of Storms"] = { "The Restless Cabal", "Uu'nat" },
    ["Battle of Dazar'alor"] = { "Champion of the Light", "Grong", "Jadefire Masters", "Opulence", "Conclave of the Chosen", "King Rastakhan", "High Tinker Mekkatorque", "Stormwall Blockade", "Lady Jaina Proudmoore" },
    ["Uldir"] = { "Taloc", "MOTHER", "Fetid Devourer", "Zek'voz", "Vectis", "Zul", "Mythrax", "G'huun" },

    -- LEGION
    ["Antorus, the Burning Throne"] = { "Garothi Worldbreaker", "Felhounds of Sargeras", "Antoran High Command", "Portal Keeper Hasabel", "Eonar", "Imonar the Soulhunter", "Kin'garoth", "Varimathras", "Coven of Shivarra", "Aggramar", "Argus the Unmaker" },
    ["Tomb of Sargeras"] = { "Goroth", "Demonic Inquisition", "Harjatan", "Mistress Sassz'ine", "Sisters of the Moon", "Desolate Host", "Maiden of Vigilance", "Fallen Avatar", "Kil'jaeden" },
    ["The Nighthold"] = { "Skorpyron", "Chronomatic Anomaly", "Trilliax", "Spellblade Aluriel", "Star Augur Etraeus", "High Botanist Tel'arn", "Krosus", "Tichondrius", "Elisande", "Gul'dan" },
    ["Trial of Valor"] = { "Odyn", "Guarm", "Helya" },
    ["Emerald Nightmare"] = { "Nythendra", "Il'gynoth", "Elerethe Renferal", "Ursoc", "Dragons of Nightmare", "Cenarius", "Xavius" },

    -- WARLORDS OF DRAENOR
    ["Hellfire Citadel"] = { "Hellfire Assault", "Iron Reaver", "Kormrok", "Hellfire High Council", "Kilrogg Deadeye", "Gorefiend", "Shadow-Lord Iskar", "Socrates", "Tyrant Velhari", "Fel Lord Zakuun", "Xhul'horac", "Mannoroth", "Archimonde" },
    ["Blackrock Foundry"] = { "Gruul", "Oregorger", "Blast Furnace", "Hans'gar and Franzok", "Flamebender Ka'graz", "Kromog", "Beastlord Darmac", "Operator Thogar", "Iron Maidens", "Blackhand" },
    ["Highmaul"] = { "Kargath Bladefist", "The Butcher", "Tectus", "Brackenspore", "Twin Ogron", "Ko'ragh", "Imperator Mar'gok" },

    -- MISTS OF PANDARIA
    ["Siege of Orgrimmar"] = { "Immerseus", "Fallen Protectors", "Norushen", "Sha of Pride", "Galakras", "Iron Juggernaut", "Kor'kron Dark Shaman", "General Nazgrim", "Malkorok", "Spoils of Pandaria", "Thok the Bloodthirsty", "Siegecrafter Blackfuse", "Paragons of the Klaxxi", "Garrosh Hellscream" },
    ["Throne of Thunder"] = { "Jin'rokh", "Horridon", "Council of Elders", "Tortos", "Megaera", "Ji-Kun", "Durumu", "Primordius", "Dark Animus", "Iron Qon", "Twin Consorts", "Lei Shen", "Ra-den" },
    ["Terrace of Endless Spring"] = { "Protectors of the Endless", "Tsulong", "Lei Shi", "Sha of Fear" },
    ["Heart of Fear"] = { "Imperial Vizier Zor'lok", "Blade Lord Ta'yak", "Garalon", "Wind Lord Mel'jarak", "Amber-Shaper Un'sok", "Grand Empress Shek'zara" },
    ["Mogu'shan Vaults"] = { "The Stone Guard", "Feng the Accursed", "Gara'jal the Spiritbinder", "The Spirit Kings", "Elegon", "Will of the Emperor" },

    -- CATACLYSM
    ["Dragon Soul"] = { "Morchok", "Warlord Zon'ozz", "Yor'sahj the Unsleeping", "Hagara the Stormbinder", "Ultraxion", "Warmaster Blackhorn", "Spine of Deathwing", "Madness of Deathwing" },
    ["Firelands"] = { "Beth'tilac", "Lord Rhyolith", "Alysrazor", "Shannox", "Baleroc", "Majordomo Staghelm", "Ragnaros" },
    ["Throne of the Four Winds"] = { "Conclave of Wind", "Al'Akir" },
    ["Blackwing Descent"] = { "Magmaw", "Omnotron Defense System", "Maloriak", "Atramedes", "Chimaeron", "Nefarian" },
    ["Bastion of Twilight"] = { "Halfus Wyrmbreaker", "Valiona and Theralion", "Ascendant Council", "Cho'gall", "Sinestra" },
    ["Baradin Hold"] = { "Argaloth", "Occu'thar", "Alizabal" },

    -- WRATH OF THE LICH KING
    ["The Ruby Sanctum"] = { "Halion" },
    ["Icecrown Citadel"] = { "Lord Marrowgar", "Lady Deathwhisper", "Gunship Battle", "Deathbringer Saurfang", "Festergut", "Rotface", "Professor Putricide", "Blood Prince Council", "Blood-Queen Lana'thel", "Valithria Dreamwalker", "Sindragosa", "The Lich King" },
    ["Onyxia's Lair"] = { "Onyxia" },
    ["Trial of the Crusader"] = { "Northrend Beasts", "Lord Jaraxxus", "Faction Champions", "Twin Val'kyr", "Anub'arak" },
    ["Ulduar"] = { "Flame Leviathan", "Ignis", "Razorscale", "XT-002", "Assembly of Iron", "Kologarn", "Auriaya", "Hodir", "Thorim", "Freya", "Mimiron", "General Vezax", "Yogg-Saron", "Algalon" },
    ["The Eye of Eternity"] = { "Malygos" },
    ["The Obsidian Sanctum"] = { "Sartharion" },
    ["Naxxramas (WotLK)"] = { "Anub'Rekhan", "Faerlina", "Maexxna", "Noth", "Heigan", "Loatheb", "Instructor Razuvious", "Gothik", "Four Horsemen", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" },
    ["Vault of Archavon"] = { "Archavon", "Emalon", "Koralon", "Toravon" },

    -- BURNING CRUSADE
    ["Sunwell Plateau"] = { "Kalecgos", "Brutallus", "Felmyst", "Eredar Twins", "M'uru", "Kil'jaeden" },
    ["Black Temple"] = { "Naj'entus", "Supremus", "Shade of Akama", "Teron Gorefiend", "Gurtogg Bloodboil", "Reliquary of Souls", "Mother Shahraz", "Illidari Council", "Illidan Stormrage" },
    ["Mount Hyjal"] = { "Rage Winterchill", "Anetheron", "Kaz'rogal", "Azgalor", "Archimonde" },
    ["The Eye"] = { "Al'ar", "Void Reaver", "High Astromancer Solarian", "Kael'thas Sunstrider" },
    ["Serpentshrine Cavern"] = { "Hydross", "The Lurker Below", "Leotheras the Blind", "Fathom-Lord Karathress", "Morogrim Tidewalker", "Lady Vashj" },
    ["Magtheridon's Lair"] = { "Magtheridon" },
    ["Gruul's Lair"] = { "High King Maulgar", "Gruul" },
    ["Karazhan"] = { "Attumen", "Moroes", "Maiden", "Opera", "Curator", "Terestian", "Aran", "Netherspite", "Chess", "Prince Malchezaar", "Nightbane" },

    -- CLASSIC
    ["Naxxramas"] = { "Anub'Rekhan", "Faerlina", "Maexxna", "Noth", "Heigan", "Loatheb", "Instructor Razuvious", "Gothik", "Four Horsemen", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" },
    ["Temple of Ahn'Qiraj"] = { "Skeram", "Bug Trio", "Sartura", "Fankriss", "Viscidus", "Huhuran", "Twin Emperors", "Ouro", "C'Thun" },
    ["Ruins of Ahn'Qiraj"] = { "Kurinnaxx", "Rajaxx", "Moam", "Buru", "Ayamiss", "Ossirian" },
    ["Blackwing Lair"] = { "Razorgore", "Vaelastrasz", "Broodlord Lashlayer", "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian" },
    ["Molten Core"] = { "Lucifron", "Magmadar", "Gehennas", "Garr", "Shazzrah", "Baron Geddon", "Sulfuron Harbinger", "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros" }
}

-- 4. Difficulties
DTC.Static.DIFFICULTIES = {
    [0] = {"Normal"}, [1] = {"Normal"}, [2] = {"10m Normal", "25m Normal", "10m Heroic", "25m Heroic"}, 
    ["DEFAULT"] = {"LFR", "Normal", "Heroic", "Mythic", "10m Normal", "25m Normal", "10m Heroic", "25m Heroic"}
}

-- Helper to safely get boss list
function DTC.Static:GetBossList(raidName)
    if not raidName then return {} end
    local list = self.BOSS_DATA[raidName]
    if list then return list end
    return {}
end
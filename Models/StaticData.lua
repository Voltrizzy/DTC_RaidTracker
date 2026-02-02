local folderName, DTC = ...
DTC.Static = {}

-- 1. Expansion Names
DTC.Static.EXPANSION_NAMES = {
    [0]=DTC.L["Classic"], [1]=DTC.L["Burning Crusade"], [2]=DTC.L["Wrath of the Lich King"], 
    [3]=DTC.L["Cataclysm"], [4]=DTC.L["Mists of Pandaria"], [5]=DTC.L["Warlords of Draenor"], 
    [6]=DTC.L["Legion"], [7]=DTC.L["Battle for Azeroth"], [8]=DTC.L["Shadowlands"], 
    [9]=DTC.L["Dragonflight"], [10]=DTC.L["The War Within"], [11]=DTC.L["Midnight"]
}

-- 2. Raid List (Map Exp ID -> List of Raid Names)
DTC.Static.RAID_DATA = {
    [0] = { DTC.L["Molten Core"], DTC.L["Blackwing Lair"], DTC.L["Ruins of Ahn'Qiraj"], DTC.L["Temple of Ahn'Qiraj"], DTC.L["Naxxramas"], DTC.L["Onyxia's Lair"] },
    [1] = { DTC.L["Karazhan"], DTC.L["Gruul's Lair"], DTC.L["Magtheridon's Lair"], DTC.L["Serpentshrine Cavern"], DTC.L["The Eye"], DTC.L["Mount Hyjal"], DTC.L["Black Temple"], DTC.L["Sunwell Plateau"] },
    [2] = { DTC.L["Naxxramas (WotLK)"], DTC.L["Ulduar"], DTC.L["Trial of the Crusader"], DTC.L["Icecrown Citadel"], DTC.L["Ruby Sanctum"], DTC.L["Obsidian Sanctum"], DTC.L["Eye of Eternity"], DTC.L["Vault of Archavon"] },
    [3] = { DTC.L["Bastion of Twilight"], DTC.L["Blackwing Descent"], DTC.L["Throne of the Four Winds"], DTC.L["Firelands"], DTC.L["Dragon Soul"], DTC.L["Baradin Hold"] },
    [4] = { DTC.L["Mogu'shan Vaults"], DTC.L["Heart of Fear"], DTC.L["Terrace of Endless Spring"], DTC.L["Throne of Thunder"], DTC.L["Siege of Orgrimmar"] },
    [5] = { DTC.L["Highmaul"], DTC.L["Blackrock Foundry"], DTC.L["Hellfire Citadel"] },
    [6] = { DTC.L["Emerald Nightmare"], DTC.L["Trial of Valor"], DTC.L["Nighthold"], DTC.L["Tomb of Sargeras"], DTC.L["Antorus, the Burning Throne"] },
    [7] = { DTC.L["Uldir"], DTC.L["Battle of Dazar'alor"], DTC.L["Crucible of Storms"], DTC.L["The Eternal Palace"], DTC.L["Ny'alotha"] },
    [8] = { DTC.L["Castle Nathria"], DTC.L["Sanctum of Domination"], DTC.L["Sepulcher of the First Ones"] },
    [9] = { DTC.L["Vault of the Incarnates"], DTC.L["Aberrus, the Shadowed Crucible"], DTC.L["Amirdrassil, the Dream's Hope"] },
    [10] = { DTC.L["Nerub-ar Palace"], DTC.L["Liberation of Undermine"], DTC.L["Manaforge Omega"] },
    [11] = { DTC.L["The Voidspire"], DTC.L["The Dreamrift"], DTC.L["March on Quel'Danas"] }
}

-- 3. Boss Lists (Map Raid Name -> List of Boss Names)
DTC.Static.BOSS_DATA = {
    -- MIDNIGHT (Patch 12.0)
    [DTC.L["The Voidspire"]] = { DTC.L["Imperator Averzian"], DTC.L["Vorasius"], DTC.L["Fallen-King Salhadaar"], DTC.L["Vaelgor & Ezzorak"], DTC.L["Lightblinded Vanguard"], DTC.L["Crown of the Cosmos"] },
    [DTC.L["The Dreamrift"]] = { DTC.L["Chimaerus, the Undreamt God"] },
    [DTC.L["March on Quel'Danas"]] = { DTC.L["Belo'ren, Child of Al'ar"], DTC.L["Midnight Falls"] },

    -- THE WAR WITHIN (Patches 11.0 - 11.2)
    [DTC.L["Nerub-ar Palace"]] = { DTC.L["Ulgrax the Devourer"], DTC.L["The Bloodbound Horror"], DTC.L["Sikran"], DTC.L["Rasha'nan"], DTC.L["Eggtender Ovi'nax"], DTC.L["Nexus-Princess Ky'veza"], DTC.L["The Silken Court"], DTC.L["Queen Ansurek"] },
    [DTC.L["Liberation of Undermine"]] = { DTC.L["Vexie and the Geargrinders"], DTC.L["Cauldron of Carnage"], DTC.L["Rik Reverb"], DTC.L["Stix Bunkjunker"], DTC.L["Sprocketmonger Lockenstock"], DTC.L["The One-Armed Bandit"], DTC.L["Mug'Zee, Heads of Security"], DTC.L["Chrome King Gallywix"] },
    [DTC.L["Manaforge Omega"]] = { DTC.L["Plexus Sentinel"], DTC.L["Loom'ithar"], DTC.L["Soulbinder Naazindhri"], DTC.L["Forgeweaver Araz"], DTC.L["The Soul Hunters"], DTC.L["Fractillus"], DTC.L["Nexus-King Salhadaar"], DTC.L["Dimensius, the All-Devouring"] },

    -- DRAGONFLIGHT
    [DTC.L["Amirdrassil, the Dream's Hope"]] = { DTC.L["Gnarlroot"], DTC.L["Igira the Cruel"], DTC.L["Volcoross"], DTC.L["Council of Dreams"], DTC.L["Larodar, Keeper of the Flame"], DTC.L["Nymue"], DTC.L["Smolderon"], DTC.L["Tindral Sageswift"], DTC.L["Fyrakk the Blazing"] },
    [DTC.L["Aberrus, the Shadowed Crucible"]] = { DTC.L["Kazzara"], DTC.L["The Amalgamation Chamber"], DTC.L["The Forgotten Experiments"], DTC.L["Assault of the Zaqali"], DTC.L["Rashok"], DTC.L["The Vigilant Steward, Zskarn"], DTC.L["Magmorax"], DTC.L["Echo of Neltharion"], DTC.L["Scalecommander Sarkareth"] },
    [DTC.L["Vault of the Incarnates"]] = { DTC.L["Eranog"], DTC.L["Terros"], DTC.L["The Primal Council"], DTC.L["Sennarth"], DTC.L["Dathea"], DTC.L["Kurog Grimtotem"], DTC.L["Broodkeeper Diurna"], DTC.L["Raszageth"] },

    -- SHADOWLANDS
    [DTC.L["Sepulcher of the First Ones"]] = { DTC.L["Vigilant Guardian"], DTC.L["Skolex"], DTC.L["Artificer Xy'mox"], DTC.L["Dausegne"], DTC.L["Prototype Pantheon"], DTC.L["Lihuvim"], DTC.L["Halondrus"], DTC.L["Anduin Wrynn"], DTC.L["Lords of Dread"], DTC.L["Rygelon"], DTC.L["The Jailer"] },
    [DTC.L["Sanctum of Domination"]] = { DTC.L["The Tarragrue"], DTC.L["Eye of the Jailer"], DTC.L["The Nine"], DTC.L["Remnant of Ner'zhul"], DTC.L["Soulrender Dormazain"], DTC.L["Painsmith Raznal"], DTC.L["Guardian of the First Ones"], DTC.L["Fatescribe Roh-Kalo"], DTC.L["Kel'Thuzad"], DTC.L["Sylvanas Windrunner"] },
    [DTC.L["Castle Nathria"]] = { DTC.L["Shriekwing"], DTC.L["Huntsman Altimor"], DTC.L["Sun King's Salvation"], DTC.L["Artificer Xy'mox"], DTC.L["Hungering Destroyer"], DTC.L["Lady Inerva Darkvein"], DTC.L["Council of Blood"], DTC.L["Sludgefist"], DTC.L["Stone Legion Generals"], DTC.L["Sire Denathrius"] },

    -- BATTLE FOR AZEROTH
    [DTC.L["Ny'alotha"]] = { DTC.L["Wrathion"], DTC.L["Maut"], DTC.L["Prophet Skitra"], DTC.L["Dark Inquisitor Xanesh"], DTC.L["The Hivemind"], DTC.L["Shad'har the Insatiable"], DTC.L["Drest'agath"], DTC.L["Il'gynoth"], DTC.L["Vexiona"], DTC.L["Ra-den the Despoiled"], DTC.L["Carapace of N'Zoth"], DTC.L["N'Zoth the Corruptor"] },
    [DTC.L["The Eternal Palace"]] = { DTC.L["Abyssal Commander Sivara"], DTC.L["Blackwater Behemoth"], DTC.L["Radiance of Azshara"], DTC.L["Lady Ashvane"], DTC.L["Orgozoa"], DTC.L["The Queen's Court"], DTC.L["Za'qul"], DTC.L["Queen Azshara"] },
    [DTC.L["Crucible of Storms"]] = { DTC.L["The Restless Cabal"], DTC.L["Uu'nat"] },
    [DTC.L["Battle of Dazar'alor"]] = { DTC.L["Champion of the Light"], DTC.L["Grong"], DTC.L["Jadefire Masters"], DTC.L["Opulence"], DTC.L["Conclave of the Chosen"], DTC.L["King Rastakhan"], DTC.L["High Tinker Mekkatorque"], DTC.L["Stormwall Blockade"], DTC.L["Lady Jaina Proudmoore"] },
    [DTC.L["Uldir"]] = { DTC.L["Taloc"], DTC.L["MOTHER"], DTC.L["Fetid Devourer"], DTC.L["Zek'voz"], DTC.L["Vectis"], DTC.L["Zul"], DTC.L["Mythrax"], DTC.L["G'huun"] },

    -- LEGION
    [DTC.L["Antorus, the Burning Throne"]] = { DTC.L["Garothi Worldbreaker"], DTC.L["Felhounds of Sargeras"], DTC.L["Antoran High Command"], DTC.L["Portal Keeper Hasabel"], DTC.L["Eonar"], DTC.L["Imonar the Soulhunter"], DTC.L["Kin'garoth"], DTC.L["Varimathras"], DTC.L["Coven of Shivarra"], DTC.L["Aggramar"], DTC.L["Argus the Unmaker"] },
    [DTC.L["Tomb of Sargeras"]] = { DTC.L["Goroth"], DTC.L["Demonic Inquisition"], DTC.L["Harjatan"], DTC.L["Mistress Sassz'ine"], DTC.L["Sisters of the Moon"], DTC.L["Desolate Host"], DTC.L["Maiden of Vigilance"], DTC.L["Fallen Avatar"], DTC.L["Kil'jaeden"] },
    [DTC.L["The Nighthold"]] = { DTC.L["Skorpyron"], DTC.L["Chronomatic Anomaly"], DTC.L["Trilliax"], DTC.L["Spellblade Aluriel"], DTC.L["Star Augur Etraeus"], DTC.L["High Botanist Tel'arn"], DTC.L["Krosus"], DTC.L["Tichondrius"], DTC.L["Elisande"], DTC.L["Gul'dan"] },
    [DTC.L["Trial of Valor"]] = { DTC.L["Odyn"], DTC.L["Guarm"], DTC.L["Helya"] },
    [DTC.L["Emerald Nightmare"]] = { DTC.L["Nythendra"], DTC.L["Il'gynoth"], DTC.L["Elerethe Renferal"], DTC.L["Ursoc"], DTC.L["Dragons of Nightmare"], DTC.L["Cenarius"], DTC.L["Xavius"] },

    -- WARLORDS OF DRAENOR
    [DTC.L["Hellfire Citadel"]] = { DTC.L["Hellfire Assault"], DTC.L["Iron Reaver"], DTC.L["Kormrok"], DTC.L["Hellfire High Council"], DTC.L["Kilrogg Deadeye"], DTC.L["Gorefiend"], DTC.L["Shadow-Lord Iskar"], DTC.L["Socrates"], DTC.L["Tyrant Velhari"], DTC.L["Fel Lord Zakuun"], DTC.L["Xhul'horac"], DTC.L["Mannoroth"], DTC.L["Archimonde"] },
    [DTC.L["Blackrock Foundry"]] = { DTC.L["Gruul"], DTC.L["Oregorger"], DTC.L["Blast Furnace"], DTC.L["Hans'gar and Franzok"], DTC.L["Flamebender Ka'graz"], DTC.L["Kromog"], DTC.L["Beastlord Darmac"], DTC.L["Operator Thogar"], DTC.L["Iron Maidens"], DTC.L["Blackhand"] },
    [DTC.L["Highmaul"]] = { DTC.L["Kargath Bladefist"], DTC.L["The Butcher"], DTC.L["Tectus"], DTC.L["Brackenspore"], DTC.L["Twin Ogron"], DTC.L["Ko'ragh"], DTC.L["Imperator Mar'gok"] },

    -- MISTS OF PANDARIA
    [DTC.L["Siege of Orgrimmar"]] = { DTC.L["Immerseus"], DTC.L["Fallen Protectors"], DTC.L["Norushen"], DTC.L["Sha of Pride"], DTC.L["Galakras"], DTC.L["Iron Juggernaut"], DTC.L["Kor'kron Dark Shaman"], DTC.L["General Nazgrim"], DTC.L["Malkorok"], DTC.L["Spoils of Pandaria"], DTC.L["Thok the Bloodthirsty"], DTC.L["Siegecrafter Blackfuse"], DTC.L["Paragons of the Klaxxi"], DTC.L["Garrosh Hellscream"] },
    [DTC.L["Throne of Thunder"]] = { DTC.L["Jin'rokh"], DTC.L["Horridon"], DTC.L["Council of Elders"], DTC.L["Tortos"], DTC.L["Megaera"], DTC.L["Ji-Kun"], DTC.L["Durumu"], DTC.L["Primordius"], DTC.L["Dark Animus"], DTC.L["Iron Qon"], DTC.L["Twin Consorts"], DTC.L["Lei Shen"], DTC.L["Ra-den"] },
    [DTC.L["Terrace of Endless Spring"]] = { DTC.L["Protectors of the Endless"], DTC.L["Tsulong"], DTC.L["Lei Shi"], DTC.L["Sha of Fear"] },
    [DTC.L["Heart of Fear"]] = { DTC.L["Imperial Vizier Zor'lok"], DTC.L["Blade Lord Ta'yak"], DTC.L["Garalon"], DTC.L["Wind Lord Mel'jarak"], DTC.L["Amber-Shaper Un'sok"], DTC.L["Grand Empress Shek'zara"] },
    [DTC.L["Mogu'shan Vaults"]] = { DTC.L["The Stone Guard"], DTC.L["Feng the Accursed"], DTC.L["Gara'jal the Spiritbinder"], DTC.L["The Spirit Kings"], DTC.L["Elegon"], DTC.L["Will of the Emperor"] },

    -- CATACLYSM
    [DTC.L["Dragon Soul"]] = { DTC.L["Morchok"], DTC.L["Warlord Zon'ozz"], DTC.L["Yor'sahj the Unsleeping"], DTC.L["Hagara the Stormbinder"], DTC.L["Ultraxion"], DTC.L["Warmaster Blackhorn"], DTC.L["Spine of Deathwing"], DTC.L["Madness of Deathwing"] },
    [DTC.L["Firelands"]] = { DTC.L["Beth'tilac"], DTC.L["Lord Rhyolith"], DTC.L["Alysrazor"], DTC.L["Shannox"], DTC.L["Baleroc"], DTC.L["Majordomo Staghelm"], DTC.L["Ragnaros"] },
    [DTC.L["Throne of the Four Winds"]] = { DTC.L["Conclave of Wind"], DTC.L["Al'Akir"] },
    [DTC.L["Blackwing Descent"]] = { DTC.L["Magmaw"], DTC.L["Omnotron Defense System"], DTC.L["Maloriak"], DTC.L["Atramedes"], DTC.L["Chimaeron"], DTC.L["Nefarian"] },
    [DTC.L["Bastion of Twilight"]] = { DTC.L["Halfus Wyrmbreaker"], DTC.L["Valiona and Theralion"], DTC.L["Ascendant Council"], DTC.L["Cho'gall"], DTC.L["Sinestra"] },
    [DTC.L["Baradin Hold"]] = { DTC.L["Argaloth"], DTC.L["Occu'thar"], DTC.L["Alizabal"] },

    -- WRATH OF THE LICH KING
    [DTC.L["The Ruby Sanctum"]] = { DTC.L["Halion"] },
    [DTC.L["Icecrown Citadel"]] = { DTC.L["Lord Marrowgar"], DTC.L["Lady Deathwhisper"], DTC.L["Gunship Battle"], DTC.L["Deathbringer Saurfang"], DTC.L["Festergut"], DTC.L["Rotface"], DTC.L["Professor Putricide"], DTC.L["Blood Prince Council"], DTC.L["Blood-Queen Lana'thel"], DTC.L["Valithria Dreamwalker"], DTC.L["Sindragosa"], DTC.L["The Lich King"] },
    [DTC.L["Onyxia's Lair"]] = { DTC.L["Onyxia"] },
    [DTC.L["Trial of the Crusader"]] = { DTC.L["Northrend Beasts"], DTC.L["Lord Jaraxxus"], DTC.L["Faction Champions"], DTC.L["Twin Val'kyr"], DTC.L["Anub'arak"] },
    [DTC.L["Ulduar"]] = { DTC.L["Flame Leviathan"], DTC.L["Ignis"], DTC.L["Razorscale"], DTC.L["XT-002"], DTC.L["Assembly of Iron"], DTC.L["Kologarn"], DTC.L["Auriaya"], DTC.L["Hodir"], DTC.L["Thorim"], DTC.L["Freya"], DTC.L["Mimiron"], DTC.L["General Vezax"], DTC.L["Yogg-Saron"], DTC.L["Algalon"] },
    [DTC.L["The Eye of Eternity"]] = { DTC.L["Malygos"] },
    [DTC.L["The Obsidian Sanctum"]] = { DTC.L["Sartharion"] },
    [DTC.L["Naxxramas (WotLK)"]] = { DTC.L["Anub'Rekhan"], DTC.L["Faerlina"], DTC.L["Maexxna"], DTC.L["Noth"], DTC.L["Heigan"], DTC.L["Loatheb"], DTC.L["Instructor Razuvious"], DTC.L["Gothik"], DTC.L["Four Horsemen"], DTC.L["Patchwerk"], DTC.L["Grobbulus"], DTC.L["Gluth"], DTC.L["Thaddius"], DTC.L["Sapphiron"], DTC.L["Kel'Thuzad"] },
    [DTC.L["Vault of Archavon"]] = { DTC.L["Archavon"], DTC.L["Emalon"], DTC.L["Koralon"], DTC.L["Toravon"] },

    -- BURNING CRUSADE
    [DTC.L["Sunwell Plateau"]] = { DTC.L["Kalecgos"], DTC.L["Brutallus"], DTC.L["Felmyst"], DTC.L["Eredar Twins"], DTC.L["M'uru"], DTC.L["Kil'jaeden"] },
    [DTC.L["Black Temple"]] = { DTC.L["Naj'entus"], DTC.L["Supremus"], DTC.L["Shade of Akama"], DTC.L["Teron Gorefiend"], DTC.L["Gurtogg Bloodboil"], DTC.L["Reliquary of Souls"], DTC.L["Mother Shahraz"], DTC.L["Illidari Council"], DTC.L["Illidan Stormrage"] },
    [DTC.L["Mount Hyjal"]] = { DTC.L["Rage Winterchill"], DTC.L["Anetheron"], DTC.L["Kaz'rogal"], DTC.L["Azgalor"], DTC.L["Archimonde"] },
    [DTC.L["The Eye"]] = { DTC.L["Al'ar"], DTC.L["Void Reaver"], DTC.L["High Astromancer Solarian"], DTC.L["Kael'thas Sunstrider"] },
    [DTC.L["Serpentshrine Cavern"]] = { DTC.L["Hydross"], DTC.L["The Lurker Below"], DTC.L["Leotheras the Blind"], DTC.L["Fathom-Lord Karathress"], DTC.L["Morogrim Tidewalker"], DTC.L["Lady Vashj"] },
    [DTC.L["Magtheridon's Lair"]] = { DTC.L["Magtheridon"] },
    [DTC.L["Gruul's Lair"]] = { DTC.L["High King Maulgar"], DTC.L["Gruul"] },
    [DTC.L["Karazhan"]] = { DTC.L["Attumen"], DTC.L["Moroes"], DTC.L["Maiden"], DTC.L["Opera"], DTC.L["Curator"], DTC.L["Terestian"], DTC.L["Aran"], DTC.L["Netherspite"], DTC.L["Chess"], DTC.L["Prince Malchezaar"], DTC.L["Nightbane"] },

    -- CLASSIC
    [DTC.L["Naxxramas"]] = { DTC.L["Anub'Rekhan"], DTC.L["Faerlina"], DTC.L["Maexxna"], DTC.L["Noth"], DTC.L["Heigan"], DTC.L["Loatheb"], DTC.L["Instructor Razuvious"], DTC.L["Gothik"], DTC.L["Four Horsemen"], DTC.L["Patchwerk"], DTC.L["Grobbulus"], DTC.L["Gluth"], DTC.L["Thaddius"], DTC.L["Sapphiron"], DTC.L["Kel'Thuzad"] },
    [DTC.L["Temple of Ahn'Qiraj"]] = { DTC.L["Skeram"], DTC.L["Bug Trio"], DTC.L["Sartura"], DTC.L["Fankriss"], DTC.L["Viscidus"], DTC.L["Huhuran"], DTC.L["Twin Emperors"], DTC.L["Ouro"], DTC.L["C'Thun"] },
    [DTC.L["Ruins of Ahn'Qiraj"]] = { DTC.L["Kurinnaxx"], DTC.L["Rajaxx"], DTC.L["Moam"], DTC.L["Buru"], DTC.L["Ayamiss"], DTC.L["Ossirian"] },
    [DTC.L["Blackwing Lair"]] = { DTC.L["Razorgore"], DTC.L["Vaelastrasz"], DTC.L["Broodlord Lashlayer"], DTC.L["Firemaw"], DTC.L["Ebonroc"], DTC.L["Flamegor"], DTC.L["Chromaggus"], DTC.L["Nefarian"] },
    [DTC.L["Molten Core"]] = { DTC.L["Lucifron"], DTC.L["Magmadar"], DTC.L["Gehennas"], DTC.L["Garr"], DTC.L["Shazzrah"], DTC.L["Baron Geddon"], DTC.L["Sulfuron Harbinger"], DTC.L["Golemagg the Incinerator"], DTC.L["Majordomo Executus"], DTC.L["Ragnaros"] }
}

-- 4. Difficulties
DTC.Static.DIFFICULTIES = {
    [0] = {DTC.L["Normal"]}, [1] = {DTC.L["Normal"]}, [2] = {DTC.L["10m Normal"], DTC.L["25m Normal"], DTC.L["10m Heroic"], DTC.L["25m Heroic"]}, 
    ["DEFAULT"] = {DTC.L["LFR"], DTC.L["Normal"], DTC.L["Heroic"], DTC.L["Mythic"], DTC.L["10m Normal"], DTC.L["25m Normal"], DTC.L["10m Heroic"], DTC.L["25m Heroic"]}
}

-- Helper to safely get boss list
function DTC.Static:GetBossList(raidName)
    if not raidName then return {} end
    local list = self.BOSS_DATA[raidName]
    if list then return list end
    return {}
end
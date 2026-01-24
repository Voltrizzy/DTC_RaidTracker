-- 1. INITIALIZATION
local DTC_VERSION = "3.3.0" -- Voter Tracking History
local DTC_PREFIX = "DTCTRACKER"
local f = CreateFrame("Frame")
local isBossFight = false
local currentVotes = {} 
local currentVoters = {} -- New: Tracks list of voters per target
local myVotesLeft = 3
local viewMode = "NICK" 
local lastBossName = "No Recent Boss"
local votingOpen = false 

-- Selection State
local selTime = "ALL"  -- "ALL", "TODAY", "TRIPS"
local selExp = "ALL"
local selRaid = "ALL"
local selBoss = "ALL"

-- CONSTANTS
local EXPANSION_NAMES = {
    [0]="Classic", [1]="Burning Crusade", [2]="Wrath of the Lich King", 
    [3]="Cataclysm", [4]="Mists of Pandaria", [5]="Warlords of Draenor", 
    [6]="Legion", [7]="Battle for Azeroth", [8]="Shadowlands", 
    [9]="Dragonflight", [10]="The War Within", [11]="Midnight"
}

-- STATIC DATA: Full Raid & Boss List
local STATIC_DATA = {
    [0] = {
        ["Molten Core"]={"Lucifron","Magmadar","Gehennas","Garr","Shazzrah","Baron Geddon","Sulfuron Harbinger","Golemagg","Majordomo Executus","Ragnaros"},
        ["Blackwing Lair"]={"Razorgore","Vaelastrasz","Broodlord Lashlayer","Firemaw","Ebonroc","Flamegor","Chromaggus","Nefarian"},
        ["Ruins of Ahn'Qiraj"]={"Kurinnaxx","General Rajaxx","Moam","Buru","Ayamiss","Ossirian"},
        ["Temple of Ahn'Qiraj"]={"Prophet Skeram","Battleguard Sartura","Fankriss","Huhuran","Twin Emperors","C'Thun","Ouro","Viscidus","Bug Trio"},
        ["Naxxramas"]={"Anub'rekhan","Faerlina","Maexxna","Noth","Heigan","Loatheb","Instructor Razuvious","Gothik","Four Horsemen","Patchwerk","Grobbulus","Gluth","Thaddius","Sapphiron","Kel'Thuzad"},
        ["Onyxia's Lair"]={"Onyxia"}
    },
    [1] = {
        ["Karazhan"]={"Attumen","Moroes","Maiden","Opera","Curator","Illhoof","Shade of Aran","Netherspite","Chess","Prince Malchezaar","Nightbane"},
        ["Gruul's Lair"]={"High King Maulgar","Gruul"},
        ["Magtheridon's Lair"]={"Magtheridon"},
        ["Serpentshrine Cavern"]={"Hydross","Lurker Below","Leotheras","Fathom-Lord Karathress","Morogrim Tidewalker","Lady Vashj"},
        ["The Eye"]={"Al'ar","Void Reaver","High Astromancer Solarian","Kael'thas Sunstrider"},
        ["Mount Hyjal"]={"Rage Winterchill","Anetheron","Kaz'rogal","Azgalor","Archimonde"},
        ["Black Temple"]={"Naj'entus","Supremus","Shade of Akama","Teron Gorefiend","Gurtogg Bloodboil","Reliquary of Souls","Mother Shahraz","Illidari Council","Illidan Stormrage"},
        ["Sunwell Plateau"]={"Kalecgos","Brutallus","Felmyst","Eredar Twins","M'uru","Kil'jaeden"}
    },
    [2] = {
        ["Naxxramas (WotLK)"]={"Anub'rekhan","Faerlina","Maexxna","Noth","Heigan","Loatheb","Razuvious","Gothik","Four Horsemen","Patchwerk","Grobbulus","Gluth","Thaddius","Sapphiron","Kel'Thuzad"},
        ["Ulduar"]={"Flame Leviathan","Ignis","Razorscale","XT-002","Iron Council","Kologarn","Auriaya","Hodir","Thorim","Freya","Mimiron","General Vezax","Yogg-Saron","Algalon"},
        ["Trial of the Crusader"]={"Northrend Beasts","Lord Jaraxxus","Faction Champions","Twin Val'kyr","Anub'arak"},
        ["Icecrown Citadel"]={"Marrowgar","Deathwhisper","Gunship","Saurfang","Festergut","Rotface","Putricide","Blood Prince Council","Blood-Queen Lana'thel","Valithria","Sindragosa","The Lich King"},
        ["Ruby Sanctum"]={"Halion"}, ["Obsidian Sanctum"]={"Sartharion"}, ["Eye of Eternity"]={"Malygos"}
    },
    [3] = {
        ["Bastion of Twilight"]={"Halfus","Valiona & Theralion","Ascendant Council","Cho'gall","Sinestra"},
        ["Blackwing Descent"]={"Magmaw","Omnotron","Maloriak","Atramedes","Chimaeron","Nefarian"},
        ["Throne of the Four Winds"]={"Conclave of Wind","Al'Akir"},
        ["Firelands"]={"Beth'tilac","Lord Rhyolith","Alysrazor","Shannox","Baleroc","Majordomo Staghelm","Ragnaros"},
        ["Dragon Soul"]={"Morchok","Warlord Zon'ozz","Yor'sahj","Hagara","Ultraxion","Warmaster Blackhorn","Spine of Deathwing","Madness of Deathwing"}
    },
    [4] = {
        ["Mogu'shan Vaults"]={"Stone Guard","Feng","Gara'jal","Spirit Kings","Elegon","Will of the Emperor"},
        ["Heart of Fear"]={"Vizier Zor'lok","Blade Lord Ta'yak","Garalon","Wind Lord Mel'jarak","Amber-Shaper Un'sok","Grand Empress Shek'zeer"},
        ["Terrace of Endless Spring"]={"Protectors of the Endless","Tsulong","Lei Shi","Sha of Fear"},
        ["Throne of Thunder"]={"Jin'rokh","Horridon","Council of Elders","Tortos","Megaera","Ji-Kun","Durumu","Primordius","Dark Animus","Iron Qon","Twin Consorts","Lei Shen","Ra-den"},
        ["Siege of Orgrimmar"]={"Immerseus","Protectors","Norushen","Sha of Pride","Galakras","Iron Juggernaut","Dark Shaman","General Nazgrim","Malkorok","Spoils","Thok","Siegecrafter Blackfuse","Paragons","Garrosh Hellscream"}
    },
    [5] = {
        ["Highmaul"]={"Kargath","The Butcher","Tectus","Brackenspore","Twin Ogron","Ko'ragh","Imperator Mar'gok"},
        ["Blackrock Foundry"]={"Gruul","Oregorger","Blast Furnace","Hans'gar & Franzok","Flamebender Ka'graz","Kromog","Beastlord Darmac","Operator Thogar","Iron Maidens","Blackhand"},
        ["Hellfire Citadel"]={"Hellfire Assault","Iron Reaver","Kormrok","Council","Kilrogg","Gorefiend","Iskar","Socrethar","Velhari","Zakuun","Xhul'horac","Mannoroth","Archimonde"}
    },
    [6] = {
        ["Emerald Nightmare"]={"Nythendra","Il'gynoth","Elerethe Renferal","Ursoc","Dragons of Nightmare","Cenarius","Xavius"},
        ["Trial of Valor"]={"Odyn","Guarm","Helya"},
        ["Nighthold"]={"Skorpyron","Anomaly","Trilliax","Spellblade Aluriel","Tichondrius","Krosus","Tel'arn","Star Augur","Elisande","Gul'dan"},
        ["Tomb of Sargeras"]={"Goroth","Demonic Inquisition","Harjatan","Sisters","Mistress Sassz'ine","Desolate Host","Maiden","Fallen Avatar","Kil'jaeden"},
        ["Antorus, the Burning Throne"]={"Garothi","Felhounds","Antoran High Command","Eonar","Portal Keeper Hasabel","Imonar","Kin'garoth","Varimathras","Coven of Shivarra","Aggramar","Argus"}
    },
    [7] = {
        ["Uldir"]={"Taloc","MOTHER","Fetid Devourer","Zek'voz","Vectis","Zul","Mythrax","G'huun"},
        ["Battle of Dazar'alor"]={"Champion of the Light","Jadefire Masters","Grong","Opulence","Conclave","Rastakhan","Mekkatorque","Stormwall Blockade","Jaina Proudmoore"},
        ["Crucible of Storms"]={"Restless Cabal","Uu'nat"},
        ["The Eternal Palace"]={"Sivara","Radiance","Behemoth","Ashvane","Orgozoa","Queen's Court","Za'qul","Azshara"},
        ["Ny'alotha"]={"Wrathion","Maut","Skitra","Xanesh","Vexiona","Hivemind","Ra-den","Shad'har","Drest'agath","Il'gynoth","Carapace","N'Zoth"}
    },
    [8] = {
        ["Castle Nathria"]={"Shriekwing","Huntsman","Hungering Destroyer","Lady Inerva","Sun King","Artificer Xy'mox","Council of Blood","Sludgefist","Stone Legion Generals","Sire Denathrius"},
        ["Sanctum of Domination"]={"Tarragrue","Eye of the Jailer","The Nine","Remnant of Ner'zhul","Soulrender","Painsmith","Guardian","Fatescribe","Kel'Thuzad","Sylvanas"},
        ["Sepulcher of the First Ones"]={"Vigilant Guardian","Skolex","Xy'mox","Dausegne","Pantheon","Lihuvim","Halondrus","Anduin","Lords of Dread","Rygelon","Jailer"}
    },
    [9] = {
        ["Vault of the Incarnates"]={"Eranog","Terros","Primal Council","Sennarth","Dathea","Kurog","Diurna","Raszageth"},
        ["Aberrus, the Shadowed Crucible"]={"Kazzara","Amalgamation","Forgotten Experiments","Assault","Rashok","Zskarn","Magmorax","Neltharion","Sarkareth"},
        ["Amirdrassil, the Dream's Hope"]={"Gnarlroot","Igira","Volcoross","Council of Dreams","Larodar","Nymue","Smolderon","Tindral","Fyrakk"}
    },
    [10] = {
        ["Nerub-ar Palace"]={"Ulgrax","Bloodbound Horror","Sikran","Rasha'nan","Broodtwister","Ky'veza","Silken Court","Ansurek"},
        ["Liberation of Undermine"]={"Vexie and the Geargrinders", "Cauldron of Carnage", "Rik Reverb", "Stix Bunkjunker", "Sprocketmonger Lockenstock", "The One-Armed Bandit", "Mug'Zee, Heads of Security", "Chrome King Gallywix"},
        ["Manaforge Omega"]={"Plexus Sentinel", "Loom'ithar", "Soulbinder Naazindhri", "Forgeweaver Araz", "The Soul Hunters", "Fractillus", "Nexus-King Salhadaar", "Dimensius, the All-Devouring"}
    },
    [11] = {
        ["The Voidspire"]={"Imperator Averzian", "Vorasius", "Fallen-King Salhadaar", "Vaelgor & Ezzorak", "Lightblinded Vanguard", "Crown of the Cosmos"},
        ["The Dreamrift"]={"Chimaerus, the Undreamt God"},
        ["March on Quel'Danas"]={"Belo'ren, Child of Al'ar", "Midnight Falls"}
    }
}

-- STATIC POPUPS
StaticPopupDialogs["DTC_RESET_CONFIRM"] = {
    text = "LEADER: Reset SCORE data? (Identities will be kept).",
    button1 = "Confirm", button2 = "Cancel",
    OnAccept = function()
        local savedIds = DTCRaidDB.identities or {}
        local savedSettings = DTCRaidDB.settings or {}
        DTCRaidDB = { global={}, raids={}, bosses={}, trips={}, expMap={}, raidMap={}, dates={}, history={}, identities=savedIds, settings=savedSettings }
        if DTC_RefreshLeaderboard then DTC_RefreshLeaderboard() end
        print("|cFFFF0000DTC:|r Scores wiped.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_SELF_RESET_CONFIRM"] = {
    text = "Reset your LOCAL data? (Useful if desynced).",
    button1 = "Confirm", button2 = "Cancel",
    OnAccept = function()
        local savedSettings = DTCRaidDB.settings or {}
        DTCRaidDB = { global={}, raids={}, bosses={}, trips={}, expMap={}, raidMap={}, dates={}, history={}, identities={}, settings=savedSettings }
        if DTC_RefreshLeaderboard then DTC_RefreshLeaderboard() end
        print("|cFFFF0000DTC:|r Local data reset.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- 2. LOADING & HELPERS
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")

function DTC_GetExpansionForRaid(raidName)
    for expID, raids in pairs(STATIC_DATA) do
        for rName, _ in pairs(raids) do
            if rName == raidName then return tostring(expID) end
        end
    end
    return "11" 
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "DTC_RaidTracker" then
            C_ChatInfo.RegisterAddonMessagePrefix(DTC_PREFIX)
            DTCRaidDB = DTCRaidDB or {}
            DTCRaidDB.global = DTCRaidDB.global or {}
            DTCRaidDB.raids = DTCRaidDB.raids or {}
            DTCRaidDB.bosses = DTCRaidDB.bosses or {}
            DTCRaidDB.trips = DTCRaidDB.trips or {} 
            DTCRaidDB.expMap = DTCRaidDB.expMap or {}
            DTCRaidDB.raidMap = DTCRaidDB.raidMap or {}
            DTCRaidDB.dates = DTCRaidDB.dates or {}
            DTCRaidDB.history = DTCRaidDB.history or {}
            DTCRaidDB.identities = DTCRaidDB.identities or {}
            DTCRaidDB.settings = DTCRaidDB.settings or {}
            
            self:RegisterEvent("CHAT_MSG_ADDON")
            self:RegisterEvent("ENCOUNTER_END")
            print("|cFFFFD700DTC Tracker|r " .. DTC_VERSION .. " loaded.")
        end
    elseif event == "PLAYER_LOGOUT" then
        if DTC_MainFrame then DTCRaidDB.settings.votePos = {DTC_MainFrame:GetPoint()} end
        if DTC_LeaderboardFrame then
            DTCRaidDB.settings.lbPos = {DTC_LeaderboardFrame:GetPoint()}
            DTCRaidDB.settings.lbSize = {DTC_LeaderboardFrame:GetWidth(), DTC_LeaderboardFrame:GetHeight()}
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, sender = ...
        if prefix == DTC_PREFIX then DTC_HandleComm(msg, sender) end
    elseif event == "ENCOUNTER_END" then
        local _, encounterName, _, _, success = ...
        if success == 1 then
            lastBossName = encounterName
            votingOpen = true 
            currentVotes = {}
            currentVoters = {} -- Reset voter tracking
            myVotesLeft = 3
            C_Timer.After(2, function() DTC_OpenVotingWindow() end)
        end
    end
end)

-- 3. COMMS
function DTC_HandleComm(msg, sender)
    sender = Ambiguate(sender, "none") 
    local player = UnitName("player")
    local action, data = strsplit(":", msg, 2)
    
    if action == "VOTE" then
        if sender ~= player then
            currentVotes[data] = (currentVotes[data] or 0) + 1
            -- Track Voter
            currentVoters[data] = currentVoters[data] or {}
            table.insert(currentVoters[data], sender)
            
            if DTC_MainFrame and DTC_MainFrame:IsShown() then DTC_RefreshVotingList() end
        end
    elseif action == "FINALIZE" then
        local target, points, boss, raidName, dateStr = strsplit(",", data)
        points = tonumber(points)
        
        DTCRaidDB.global[target] = (DTCRaidDB.global[target] or 0) + points
        DTCRaidDB.raids[raidName] = DTCRaidDB.raids[raidName] or {}
        DTCRaidDB.raids[raidName][target] = (DTCRaidDB.raids[raidName][target] or 0) + points
        DTCRaidDB.bosses[boss] = DTCRaidDB.bosses[boss] or {}
        DTCRaidDB.bosses[boss][target] = (DTCRaidDB.bosses[boss][target] or 0) + points
        
        local expID = DTC_GetExpansionForRaid(raidName) 
        DTCRaidDB.expMap[expID] = DTCRaidDB.expMap[expID] or {}
        DTCRaidDB.expMap[expID][raidName] = true
        DTCRaidDB.raidMap[raidName] = DTCRaidDB.raidMap[raidName] or {}
        DTCRaidDB.raidMap[raidName][boss] = true

        DTCRaidDB.dates[dateStr] = DTCRaidDB.dates[dateStr] or {}
        DTCRaidDB.dates[dateStr][target] = (DTCRaidDB.dates[dateStr][target] or 0) + points

        -- RETRIEVE VOTERS from local store (everyone saw the VOTE msgs)
        local votersList = ""
        if currentVoters[target] then
            votersList = table.concat(currentVoters[target], ", ")
        end

        table.insert(DTCRaidDB.history, 1, {b = boss, w = target, p = points, d = dateStr, r = raidName, v = votersList})
        if #DTCRaidDB.history > 2000 then table.remove(DTCRaidDB.history) end

        votingOpen = false
        if DTC_MainFrame and DTC_MainFrame:IsShown() then
            DTC_MainFrame.title:SetText("Results: " .. (lastBossName or "Boss"))
            DTC_RefreshVotingList()
        end
        
    elseif action == "VER_QUERY" then
        C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VER_RESP:" .. DTC_VERSION, "RAID")
    elseif action == "VER_RESP" then
        print(string.format("|cFFFFD700DTC Ver:|r %s is running version %s", sender, data))
    elseif action == "SYNC_START" then
        DTCRaidDB.global = {}; DTCRaidDB.raids = {}; DTCRaidDB.bosses = {}; DTCRaidDB.trips = {}
        DTCRaidDB.dates = {}; DTCRaidDB.history = {}; DTCRaidDB.identities = {}
        DTCRaidDB.expMap = {}; DTCRaidDB.raidMap = {}
        print("|cFFFFD700DTC:|r Sync started from " .. sender)
    elseif action == "SYNC_DATA" then
        DTC_ProcessSyncChunk(data)
    elseif action == "SYNC_END" then
        DTC_RefreshLeaderboard()
        print("|cFFFFD700DTC:|r Sync complete.")
    end
end

-- 4. VOTING UI
function DTC_CreateUI()
    if DTC_MainFrame then return end
    local frame = CreateFrame("Frame", "DTC_MainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(350, 480); 
    frame:SetClampedToScreen(true)
    
    if DTCRaidDB.settings and DTCRaidDB.settings.votePos then
        local p = DTCRaidDB.settings.votePos
        frame:SetPoint(p[1], UIParent, p[2], p[4], p[5])
    else
        frame:SetPoint("CENTER")
    end

    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        DTCRaidDB.settings.votePos = {self:GetPoint()}
    end)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); frame.title:SetPoint("TOP", 0, -15); frame.title:SetText("Disney Trip Voting")

    local sf = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 15, -50); sf:SetPoint("BOTTOMRIGHT", -35, 100)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(300, 1); sf:SetScrollChild(content)
    frame.content = content

    frame.finalizeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.finalizeBtn:SetSize(110, 25); frame.finalizeBtn:SetPoint("BOTTOMLEFT", 15, 15); frame.finalizeBtn:SetText("Finalize")
    frame.finalizeBtn:SetScript("OnClick", function()
        local raidName = GetInstanceInfo()
        local dStr = date("%Y-%m-%d")
        for p, v in pairs(currentVotes) do
            if not p:find("_VOTED_BY_ME") and v > 0 then
                C_ChatInfo.SendAddonMessage(DTC_PREFIX, "FINALIZE:"..p..","..v..","..lastBossName..","..raidName..","..dStr, "RAID")
            end
        end
        votingOpen = false; DTC_RefreshVotingList()
    end)

    frame.announceBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.announceBtn:SetSize(110, 25); frame.announceBtn:SetPoint("BOTTOMLEFT", 130, 15); frame.announceBtn:SetText("Announce")
    frame.announceBtn:SetScript("OnClick", function()
        local sorted = {}; for p, v in pairs(currentVotes) do if not p:find("_VOTED_BY_ME") and v > 0 then table.insert(sorted, {n=p, v=v}) end end
        table.sort(sorted, function(a,b) return a.v > b.v end)
        SendChatMessage("--- DTC Results: " .. lastBossName .. " ---", "RAID")
        for i=1, math.min(3, #sorted) do 
            local dispName = sorted[i].n; local nick = DTCRaidDB.identities[dispName]
            if nick then dispName = dispName .. " ("..nick..")" end
            SendChatMessage(i .. ". " .. dispName .. " (" .. sorted[i].v .. " pts)", "RAID") 
        end
    end)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(70, 25); closeBtn:SetPoint("BOTTOMRIGHT", -15, 15); closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.votesLeftText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.votesLeftText:SetPoint("BOTTOMLEFT", 15, 50)
    frame:Hide()
end

function DTC_OpenVotingWindow()
    DTC_CreateUI()
    if DTC_MainFrame:IsShown() then DTC_MainFrame:Hide() return end
    DTC_MainFrame.title:SetText("Voting: " .. lastBossName)
    DTC_MainFrame:Show()
    DTC_RefreshVotingList()
end

function DTC_RefreshVotingList()
    local content = DTC_MainFrame.content
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    local isLeader = UnitIsGroupLeader("player")
    DTC_MainFrame.finalizeBtn:SetShown(isLeader and votingOpen)
    DTC_MainFrame.announceBtn:SetShown(isLeader and (lastBossName ~= "No Recent Boss"))

    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(300, 30); row:SetPoint("TOPLEFT", 0, -(i-1)*32)
            local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameTxt:SetPoint("LEFT", 5, 0); nameTxt:SetText(name)
            local nick = DTCRaidDB.identities[name]
            if nick then nameTxt:SetText(name .. " |cFF88AAFF("..nick..")|r") end

            local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            btn:SetSize(60, 20); btn:SetPoint("RIGHT", -5, 0); btn:SetText("Vote")
            if not votingOpen or myVotesLeft == 0 or currentVotes[name.."_VOTED_BY_ME"] then btn:Disable() end
            btn:SetScript("OnClick", function()
                local pName = UnitName("player")
                currentVotes[name] = (currentVotes[name] or 0) + 1
                myVotesLeft = myVotesLeft - 1; currentVotes[name.."_VOTED_BY_ME"] = true
                -- Optimistic Voter Tracking (Me)
                currentVoters[name] = currentVoters[name] or {}
                table.insert(currentVoters[name], pName)
                
                C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VOTE:"..name, "RAID"); DTC_RefreshVotingList()
            end)
            local count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            count:SetPoint("RIGHT", -70, 0); count:SetText(currentVotes[name] or "0")
        end
    end
    if votingOpen then DTC_MainFrame.votesLeftText:SetText("Votes Left: " .. myVotesLeft)
    else DTC_MainFrame.votesLeftText:SetText("|cFFFF0000VOTING LOCKED / READ ONLY|r") end
end

-- 5. CONFIG GUI
function DTC_CreateConfigUI()
    if DTC_ConfigFrame then return end
    local cf = CreateFrame("Frame", "DTC_ConfigFrame", UIParent, "BackdropTemplate")
    cf:SetSize(400, 500); cf:SetPoint("CENTER")
    cf:SetMovable(true); cf:EnableMouse(true); cf:RegisterForDrag("LeftButton")
    cf:SetScript("OnDragStart", cf.StartMoving); cf:SetScript("OnDragStop", cf.StopMovingOrSizing)
    cf:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    cf:SetBackdropColor(0, 0, 0, 0.95)
    
    local title = cf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15); title:SetText("DTC Identity Config")
    local sub = cf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOP", 0, -35); sub:SetText("Assign Nicknames (Auto-Saves on Enter/Exit)")

    local sf = CreateFrame("ScrollFrame", nil, cf, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 20, -60); sf:SetPoint("BOTTOMRIGHT", -30, 40)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(350, 1); sf:SetScrollChild(content)
    cf.content = content

    local closeBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 25); closeBtn:SetPoint("BOTTOM", 0, 10); closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() cf:Hide() end)
    cf.Refresh = function() DTC_RefreshConfigList() end; cf:Hide()
end

function DTC_RefreshConfigList()
    local content = DTC_ConfigFrame.content
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    local roster = {}; local rosterMap = {}
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, classFileName = GetRaidRosterInfo(i)
        if name then table.insert(roster, {name=name, class=classFileName}); rosterMap[name] = true end
    end
    table.sort(roster, function(a,b) return a.name < b.name end)
    local others = {}
    for charName, nick in pairs(DTCRaidDB.identities) do
        if not rosterMap[charName] then table.insert(others, {name=charName, class="PRIEST"}) end
    end
    table.sort(others, function(a,b) return a.name < b.name end)
    local yOffset = 0
    local h1 = content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); h1:SetPoint("TOPLEFT", 0, yOffset); h1:SetText("Current Group"); yOffset = yOffset - 20
    for _, p in ipairs(roster) do DTC_CreateConfigRow(content, p.name, p.class, yOffset); yOffset = yOffset - 25 end
    yOffset = yOffset - 15
    if #others > 0 then
        local h2 = content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); h2:SetPoint("TOPLEFT", 0, yOffset); h2:SetText("Other Saved Characters"); yOffset = yOffset - 20
        for _, p in ipairs(others) do DTC_CreateConfigRow(content, p.name, nil, yOffset); yOffset = yOffset - 25 end
    end
end

function DTC_CreateConfigRow(parent, name, classFile, y)
    local row = CreateFrame("Frame", nil, parent); row:SetSize(320, 24); row:SetPoint("TOPLEFT", 0, y)
    local color = classFile and RAID_CLASS_COLORS[classFile] or {r=0.6,g=0.6,b=0.6}
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); label:SetPoint("LEFT", 5, 0); label:SetText(name); label:SetTextColor(color.r, color.g, color.b)
    local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); eb:SetSize(140, 20); eb:SetPoint("RIGHT", -5, 0); eb:SetAutoFocus(false)
    eb:SetText(DTCRaidDB.identities[name] or "")
    local function Save() local txt = eb:GetText(); if txt == "" then DTCRaidDB.identities[name] = nil else DTCRaidDB.identities[name] = txt end end
    eb:SetScript("OnEnterPressed", function(self) Save(); self:ClearFocus() end); eb:SetScript("OnEditFocusLost", function(self) Save() end)
end

-- ============================================================================
-- 6. LEADERBOARD UI
-- ============================================================================

-- Function Handlers for Menu Selections
local function DTC_SelectTime(self)
    local arg1 = self.arg1; if not arg1 then return end
    selTime = arg1; selExp = "ALL"; selRaid = "ALL"; selBoss = "ALL"
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddTime, arg1 == "ALL" and "All Time" or (arg1 == "TODAY" and "Today" or "Trips Won"))
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddExp, "Expansion")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, "Raid")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, "Boss")
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectExp(self)
    local arg1 = self.arg1; if not arg1 then return end
    selExp = arg1; selRaid = "ALL"; selBoss = "ALL"
    local txt = (arg1 == "ALL") and "Expansion" or EXPANSION_NAMES[tonumber(arg1)]
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddExp, txt)
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, "Raid")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, "Boss")
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectRaid(self)
    local arg1 = self.arg1; if not arg1 then return end
    selRaid = arg1; selBoss = "ALL"
    local txt = (arg1 == "ALL") and "Raid" or arg1
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, txt)
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, "Boss")
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectBoss(self)
    local arg1 = self.arg1; if not arg1 then return end
    selBoss = arg1; local txt = (arg1 == "ALL") and "Boss" or arg1
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, txt)
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

-- Menu Initializers
function DTC_InitTimeMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Time"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectTime; info.checked = (selTime == "ALL"); UIDropDownMenu_AddButton(info, level)
    info.text = "Today"; info.arg1 = "TODAY"; info.value = "TODAY"; info.func = DTC_SelectTime; info.checked = (selTime == "TODAY"); UIDropDownMenu_AddButton(info, level)
    info.text = "Trips Won"; info.arg1 = "TRIPS"; info.value = "TRIPS"; info.func = DTC_SelectTime; info.checked = (selTime == "TRIPS"); UIDropDownMenu_AddButton(info, level)
end

function DTC_InitExpMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "None"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectExp; info.checked = (selExp == "ALL"); UIDropDownMenu_AddButton(info, level)
    for i = 11, 0, -1 do
        info.text = EXPANSION_NAMES[i]; info.arg1 = tostring(i); info.value = tostring(i); info.func = DTC_SelectExp; info.checked = (selExp == tostring(i)); UIDropDownMenu_AddButton(info, level)
    end
end

function DTC_InitRaidMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    if selExp == "ALL" then
        info.text = "Select Expansion First"; info.notCheckable = true; info.disabled = true; UIDropDownMenu_AddButton(info, level)
        return
    end
    info.text = "None"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectRaid; info.checked = (selRaid == "ALL"); UIDropDownMenu_AddButton(info, level)
    if STATIC_DATA[tonumber(selExp)] then
        local rNames = {}
        for rName, _ in pairs(STATIC_DATA[tonumber(selExp)]) do table.insert(rNames, rName) end
        table.sort(rNames)
        for _, rName in ipairs(rNames) do
            info.text = rName; info.arg1 = rName; info.value = rName; info.func = DTC_SelectRaid; info.checked = (selRaid == rName); UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DTC_InitBossMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    if selRaid == "ALL" then
        info.text = "Select Raid First"; info.notCheckable = true; info.disabled = true; UIDropDownMenu_AddButton(info, level)
        return
    end
    info.text = "None"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectBoss; info.checked = (selBoss == "ALL"); UIDropDownMenu_AddButton(info, level)
    if STATIC_DATA[tonumber(selExp)] and STATIC_DATA[tonumber(selExp)][selRaid] then
        for _, bName in ipairs(STATIC_DATA[tonumber(selExp)][selRaid]) do
            info.text = bName; info.arg1 = bName; info.value = bName; info.func = DTC_SelectBoss; info.checked = (selBoss == bName); UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DTC_CreateLeaderboardUI()
    if DTC_LeaderboardFrame then return end
    local lb = CreateFrame("Frame", "DTC_LeaderboardFrame", UIParent, "BackdropTemplate")
    
    local w, h = 850, 600
    if DTCRaidDB.settings and DTCRaidDB.settings.lbSize then w, h = unpack(DTCRaidDB.settings.lbSize) end
    lb:SetSize(w, h)
    if DTCRaidDB.settings and DTCRaidDB.settings.lbPos then local p = DTCRaidDB.settings.lbPos; lb:SetPoint(p[1], UIParent, p[2], p[4], p[5]) else lb:SetPoint("CENTER") end

    lb:SetClampedToScreen(true); lb:SetMovable(true); lb:EnableMouse(true); lb:RegisterForDrag("LeftButton"); lb:SetResizable(true); lb:SetResizeBounds(600, 400, 1200, 900)
    lb:SetScript("OnDragStart", lb.StartMoving)
    lb:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); DTCRaidDB.settings.lbPos = {self:GetPoint()} end)

    lb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    lb:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    lb.title = lb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); lb.title:SetPoint("TOP", 0, -15); lb.title:SetText("DTC Leaderboard")

    -- RESIZER
    local resizer = CreateFrame("Button", nil, lb)
    resizer:SetSize(16, 16); resizer:SetPoint("BOTTOMRIGHT", -10, 10)
    resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizer:SetScript("OnMouseDown", function() lb:StartSizing("BOTTOMRIGHT") end)
    resizer:SetScript("OnMouseUp", function() lb:StopMovingOrSizing(); DTCRaidDB.settings.lbSize = {lb:GetWidth(), lb:GetHeight()} end)

    -- 1. TIME DROPDOWN
    local ddTime = CreateFrame("Frame", "DTC_TimeDD", lb, "UIDropDownMenuTemplate")
    ddTime:SetPoint("TOPLEFT", -5, -40); UIDropDownMenu_SetWidth(ddTime, 110)
    UIDropDownMenu_Initialize(ddTime, DTC_InitTimeMenu)
    UIDropDownMenu_SetText(ddTime, "All Time"); lb.ddTime = ddTime

    -- 2. EXPANSION DROPDOWN
    local ddExp = CreateFrame("Frame", "DTC_ExpDD", lb, "UIDropDownMenuTemplate")
    ddExp:SetPoint("LEFT", ddTime, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddExp, 160)
    UIDropDownMenu_Initialize(ddExp, DTC_InitExpMenu)
    UIDropDownMenu_SetText(ddExp, "Expansion"); lb.ddExp = ddExp

    -- 3. RAID DROPDOWN
    local ddRaid = CreateFrame("Frame", "DTC_RaidDD", lb, "UIDropDownMenuTemplate")
    ddRaid:SetPoint("LEFT", ddExp, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddRaid, 160)
    UIDropDownMenu_Initialize(ddRaid, DTC_InitRaidMenu)
    UIDropDownMenu_SetText(ddRaid, "Raid"); lb.ddRaid = ddRaid

    -- 4. BOSS DROPDOWN
    local ddBoss = CreateFrame("Frame", "DTC_BossDD", lb, "UIDropDownMenuTemplate")
    ddBoss:SetPoint("LEFT", ddRaid, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddBoss, 160)
    UIDropDownMenu_Initialize(ddBoss, DTC_InitBossMenu)
    UIDropDownMenu_SetText(ddBoss, "Boss"); lb.ddBoss = ddBoss

    -- View Mode Toggle
    lb.viewToggle = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate")
    lb.viewToggle:SetSize(120, 22); lb.viewToggle:SetPoint("TOPRIGHT", -20, -45); lb.viewToggle:SetText("View: NICKNAMES")
    lb.viewToggle:SetScript("OnClick", function()
        viewMode = (viewMode == "NICK") and "CHAR" or "NICK"
        lb.viewToggle:SetText("View: " .. (viewMode == "NICK" and "NICKNAMES" or "CHARACTERS"))
        DTC_RefreshLeaderboard()
    end)

    local sf = CreateFrame("ScrollFrame", nil, lb, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 15, -80); sf:SetPoint("BOTTOMRIGHT", -30, 50)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 1); sf:SetScrollChild(content)
    lb.content = content

    -- BUTTONS
    lb.syncBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.syncBtn:SetSize(80, 22); lb.syncBtn:SetPoint("BOTTOMLEFT", 15, 15); lb.syncBtn:SetText("Sync All")
    lb.syncBtn:SetScript("OnClick", function() if UnitIsGroupLeader("player") then DTC_BroadcastFullSync() end end)

    lb.verBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.verBtn:SetSize(90, 22); lb.verBtn:SetPoint("BOTTOMLEFT", 100, 15); lb.verBtn:SetText("Ver Check")
    lb.verBtn:SetScript("OnClick", function() if UnitIsGroupLeader("player") then C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VER_QUERY", "RAID") end end)
    
    lb.configBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.configBtn:SetSize(90, 22); lb.configBtn:SetPoint("BOTTOMLEFT", 195, 15); lb.configBtn:SetText("Config IDs")
    lb.configBtn:SetScript("OnClick", function() if UnitIsGroupLeader("player") then DTC_CreateConfigUI(); DTC_ConfigFrame:Show(); DTC_ConfigFrame:Hide(); DTC_CreateConfigUI(); DTC_ConfigFrame:Show(); DTC_RefreshConfigList() end end)

    -- Announce
    lb.announceBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.announceBtn:SetSize(90, 22); lb.announceBtn:SetPoint("BOTTOMLEFT", 290, 15); lb.announceBtn:SetText("Announce")
    lb.announceBtn:SetScript("OnClick", function()
        local data = DTC_GetSortedData() 
        local t = (selBoss~="ALL" and selBoss) or (selRaid~="ALL" and selRaid) or (selExp~="ALL" and EXPANSION_NAMES[tonumber(selExp)]) or "All Time"
        if selTime == "TODAY" then t = t .. " (Today)" end
        SendChatMessage("--- DTC: " .. t .. " [" .. viewMode .. "] ---", "RAID")
        for i=1, math.min(10, #data) do SendChatMessage(i .. ". " .. data[i].n .. ": " .. data[i].v, "RAID") end
    end)

    -- AWARD TRIP
    lb.awardBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.awardBtn:SetSize(100, 22); lb.awardBtn:SetPoint("LEFT", lb.announceBtn, "RIGHT", 5, 0); lb.awardBtn:SetText("Award Trip")
    lb.awardBtn:SetScript("OnClick", function()
        local data = DTC_GetSortedData()
        if #data > 0 then
            local winnerName = data[1].n 
            DTCRaidDB.trips[winnerName] = (DTCRaidDB.trips[winnerName] or 0) + 1
            SendChatMessage("--- DTC DISNEY TRIP AWARD ---", "RAID")
            SendChatMessage("CONGRATULATIONS " .. winnerName .. "! You have won a trip to Disney!", "RAID")
            C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:TRIP,"..winnerName..","..DTCRaidDB.trips[winnerName], "RAID")
            DTC_RefreshLeaderboard()
        else
            print("|cFFFF0000DTC:|r No votes found to award.")
        end
    end)

    lb.exportBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.exportBtn:SetSize(100, 22); lb.exportBtn:SetPoint("BOTTOMLEFT", 495, 15); lb.exportBtn:SetText("Export CSV")
    lb.exportBtn:SetScript("OnClick", function()
        local exportBuffer = { "Date,Raid,Boss,Winner,Points,Voters" }
        for _, h in ipairs(DTCRaidDB.history) do table.insert(exportBuffer, string.format("%s,%s,%s,%s,%d,%s", h.d, h.r or "?", h.b, h.w, h.p, h.v or "")) end
        local str = table.concat(exportBuffer, "\n")
        local eb = CreateFrame("EditBox", nil, lb, "InputBoxTemplate"); eb:SetSize(570, 30); eb:SetPoint("BOTTOM", 0, -35); eb:SetText(str); eb:HighlightText(); eb:SetFocus()
    end)

    lb.closeBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.closeBtn:SetSize(60, 22); lb.closeBtn:SetPoint("BOTTOMRIGHT", -30, 15); lb.closeBtn:SetText("Close")
    lb.closeBtn:SetScript("OnClick", function() lb:Hide() end)

    lb.selfResetBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.selfResetBtn:SetSize(80, 22); lb.selfResetBtn:SetPoint("RIGHT", lb.closeBtn, "LEFT", -10, 0); lb.selfResetBtn:SetText("Self Reset")
    lb.selfResetBtn:SetScript("OnClick", function() StaticPopup_Show("DTC_SELF_RESET_CONFIRM") end)

    lb.resetBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.resetBtn:SetSize(80, 22); lb.resetBtn:SetPoint("RIGHT", lb.selfResetBtn, "LEFT", -10, 0); lb.resetBtn:SetText("Reset DB")
    lb.resetBtn:SetScript("OnClick", function() if UnitIsGroupLeader("player") then StaticPopup_Show("DTC_RESET_CONFIRM") end end)

    lb:Hide()
end

function DTC_BroadcastFullSync()
    C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_START", "RAID")
    for p, v in pairs(DTCRaidDB.global) do C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:GLOB,"..p..","..v, "RAID") end
    for raid, players in pairs(DTCRaidDB.raids) do for p, v in pairs(players) do C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:RAID,"..raid..","..p..","..v, "RAID") end end
    for boss, players in pairs(DTCRaidDB.bosses) do for p, v in pairs(players) do C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:BOSS,"..boss..","..p..","..v, "RAID") end end
    for c, n in pairs(DTCRaidDB.identities) do C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:ID,"..c..","..n, "RAID") end
    for p, v in pairs(DTCRaidDB.trips) do C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:TRIP,"..p..","..v, "RAID") end
    for _, h in ipairs(DTCRaidDB.history) do C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:HIST,"..h.b..","..h.w..","..h.p..","..h.d..","..(h.r or "?"), "RAID") end
    C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_END", "RAID")
end

function DTC_ProcessSyncChunk(data)
    local type, p1, p2, p3, p4, p5 = strsplit(",", data)
    if type == "GLOB" then DTCRaidDB.global[p1] = tonumber(p2)
    elseif type == "RAID" then DTCRaidDB.raids[p1] = DTCRaidDB.raids[p1] or {}; DTCRaidDB.raids[p1][p2] = tonumber(p3)
    elseif type == "BOSS" then DTCRaidDB.bosses[p1] = DTCRaidDB.bosses[p1] or {}; DTCRaidDB.bosses[p1][p2] = tonumber(p3)
    elseif type == "ID" then DTCRaidDB.identities[p1] = p2
    elseif type == "TRIP" then DTCRaidDB.trips[p1] = tonumber(p2)
    elseif type == "HIST" then table.insert(DTCRaidDB.history, {b=p1, w=p2, p=tonumber(p3), d=p4, r=p5}) end
end

-- DATA AGGREGATION & LOGIC
function DTC_GetSortedData()
    if selTime == "TRIPS" then
        local displayData = {}
        for p, v in pairs(DTCRaidDB.trips) do
            local key = p
            if viewMode == "NICK" and DTCRaidDB.identities[p] then key = DTCRaidDB.identities[p] end
            displayData[key] = (displayData[key] or 0) + v
        end
        local sorted = {}
        for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end
        table.sort(sorted, function(a,b) return a.v > b.v end)
        return sorted
    end

    local rawData = {}
    
    -- "All Time" Queries
    if selTime == "ALL" then
        if selExp == "ALL" then
            rawData = DTCRaidDB.global
        else
            -- Expansion Selected
            if selRaid == "ALL" then
                -- Sum all raids in this expansion
                local raidsInExp = STATIC_DATA[tonumber(selExp)] or {}
                for rName, _ in pairs(raidsInExp) do
                    if DTCRaidDB.raids[rName] then
                        for p, v in pairs(DTCRaidDB.raids[rName]) do rawData[p] = (rawData[p] or 0) + v end
                    end
                end
            else
                -- Raid Selected
                if selBoss == "ALL" then
                    rawData = DTCRaidDB.raids[selRaid] or {}
                else
                    -- Boss Selected
                    rawData = DTCRaidDB.bosses[selBoss] or {}
                end
            end
        end
        
    -- "Today" Queries
    else 
        local today = date("%Y-%m-%d")
        for _, h in ipairs(DTCRaidDB.history) do
            if h.d == today then
                local expMatch = (selExp == "ALL")
                if not expMatch then
                    local raids = STATIC_DATA[tonumber(selExp)] or {}
                    if raids[h.r] then expMatch = true end
                end
                
                local raidMatch = (selRaid == "ALL" or h.r == selRaid)
                local bossMatch = (selBoss == "ALL" or h.b == selBoss)
                
                if expMatch and raidMatch and bossMatch then
                    rawData[h.w] = (rawData[h.w] or 0) + h.p
                end
            end
        end
    end

    local displayData = {}
    
    -- MAC vs PINK LOGIC (Before Display)
    for charName, val in pairs(rawData) do
        local key = charName
        if viewMode == "NICK" and DTCRaidDB.identities[charName] then key = DTCRaidDB.identities[charName] end
        displayData[key] = (displayData[key] or 0) + val
    end
    
    local macScore = displayData["Mac"]
    local pinkScore = displayData["Pink"]
    
    if macScore and pinkScore then
        if macScore >= pinkScore then
            displayData["Mac"] = pinkScore - 1
        end
    end

    local sorted = {}
    for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end
    table.sort(sorted, function(a,b) return a.v > b.v end)
    return sorted
end

function DTC_RefreshLeaderboard()
    DTC_CreateLeaderboardUI()
    local content = DTC_LeaderboardFrame.content
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    local isLeader = UnitIsGroupLeader("player")
    local isHistory = (selExp == "HISTORY") -- Wait, logic check: HISTORY is typically separate. 
    -- With the new filter system, History Log was removed from dropdown to focus on filters.
    -- If user wants history, we can add it back or assume export is enough.
    -- Re-adding history check just in case legacy state exists, but standard flow uses filters.
    
    DTC_LeaderboardFrame.syncBtn:SetShown(isLeader)
    DTC_LeaderboardFrame.verBtn:SetShown(isLeader)
    DTC_LeaderboardFrame.configBtn:SetShown(isLeader)
    DTC_LeaderboardFrame.resetBtn:SetShown(isLeader)
    DTC_LeaderboardFrame.announceBtn:SetShown(isLeader)
    
    -- Award Trip Button Logic: Only Show if (Leader + Raid Level Summary)
    local isRaidLevel = (selExp ~= "ALL" and selRaid ~= "ALL" and selBoss == "ALL")
    DTC_LeaderboardFrame.awardBtn:SetShown(isLeader and isRaidLevel)
    
    -- Dependency Logic for Dropdowns
    if selExp == "ALL" then
        UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddRaid)
        UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddBoss)
    else
        UIDropDownMenu_EnableDropDown(DTC_LeaderboardFrame.ddRaid)
        if selRaid == "ALL" then
            UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddBoss)
        else
            UIDropDownMenu_EnableDropDown(DTC_LeaderboardFrame.ddBoss)
        end
    end

    local data = DTC_GetSortedData()
    for i, item in ipairs(data) do
        local row = CreateFrame("Frame", nil, content); row:SetSize(600, 20); row:SetPoint("TOPLEFT", 0, -(i-1)*22)
        local t = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("LEFT", 5, 0)
        t:SetText(item.n .. ": " .. item.v)
    end
    
    -- If we wanted a pure "History Log" view mode, we would add it to Time Dropdown as "HISTORY".
    -- But current request was for detailed vote tracking inside the history log data structure.
end

-- 7. SLASH COMMANDS
SLASH_DTC1 = "/dtc"
SlashCmdList["DTC"] = function(msg)
    local cmd = msg:match("^(%S*)"):lower()
    if cmd == "vote" then DTC_OpenVotingWindow()
    elseif cmd == "lb" then DTC_CreateLeaderboardUI(); if DTC_LeaderboardFrame:IsShown() then DTC_LeaderboardFrame:Hide() else DTC_RefreshLeaderboard(); DTC_LeaderboardFrame:Show() end
    elseif cmd == "config" then
        if UnitIsGroupLeader("player") then DTC_CreateConfigUI(); if DTC_ConfigFrame:IsShown() then DTC_ConfigFrame:Hide() else DTC_ConfigFrame:Show(); DTC_RefreshConfigList() end
        else print("|cFFFF0000DTC Error:|r Leader Only.") end
    elseif cmd == "reset" then StaticPopup_Show("DTC_SELF_RESET_CONFIRM")
    elseif cmd == "ver" then print("|cFFFFD700DTC:|r Version: " .. DTC_VERSION)
    else
        print("|cFFFFD700DTC Commands:|r")
        print("  |cFF00FF00/dtc vote|r   - Toggle Voting")
        print("  |cFF00FF00/dtc lb|r     - Toggle Leaderboard")
        print("  |cFF00FF00/dtc reset|r  - Reset local data")
        print("  |cFF00FF00/dtc ver|r    - Check version")
        if UnitIsGroupLeader("player") then print("  |cFFFF0000/dtc config|r - Configure Nicknames |cFFFF0000(Leader Only)|r") end
    end
end
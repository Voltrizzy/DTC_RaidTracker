-- 1. INITIALIZATION
local DTC_VERSION = "6.4.1" -- UI Layout Tweak
local DTC_PREFIX = "DTCTRACKER"
local f = CreateFrame("Frame")
local isBossFight = false
local currentVotes = {} 
local currentVoters = {} 
local addonUsers = {}
local myVotesLeft = 3
local viewMode = "NICK" 
local lastBossName = "No Recent Boss"
local votingOpen = false 
local isTestMode = false 

-- Forward Declarations
DTC_RefreshLeaderboard = nil
DTC_RefreshHistory = nil
DTC_CreateLeaderboardUI = nil
DTC_CreateHistoryUI = nil

-- Selection State (Leaderboard)
local selTime = "ALL"; local selExp = "ALL"; local selRaid = "ALL"; local selBoss = "ALL"; local selDiff = "ALL"

-- Selection State (History/Purge/Sync)
local hSelDate = "ALL"; local hSelName = "ALL" 
local pSelExp = "ALL"; local pSelRaid = "ALL"; local pSelDiff = "ALL"; local pSelDate = "ALL"
local sSelExp = "ALL"; local sSelRaid = "ALL"; local sSelDiff = "ALL"; local sSelDate = "ALL"

-- CONSTANTS
local EXPANSION_NAMES = {
    [0]="Classic", [1]="Burning Crusade", [2]="Wrath of the Lich King", 
    [3]="Cataclysm", [4]="Mists of Pandaria", [5]="Warlords of Draenor", 
    [6]="Legion", [7]="Battle for Azeroth", [8]="Shadowlands", 
    [9]="Dragonflight", [10]="The War Within", [11]="Midnight"
}

local EXP_DIFFICULTIES = {
    [0] = {"Normal"},
    [1] = {"Normal"},
    [2] = {"10m Normal", "25m Normal", "10m Heroic", "25m Heroic"}, 
    ["DEFAULT"] = {"LFR", "Normal", "Heroic", "Mythic", "10m Normal", "25m Normal", "10m Heroic", "25m Heroic"}
}

-- FULL STATIC DATA
local STATIC_DATA = {
    [0] = { ["Molten Core"]={"Lucifron","Magmadar","Gehennas","Garr","Shazzrah","Baron Geddon","Sulfuron Harbinger","Golemagg","Majordomo Executus","Ragnaros"}, ["Blackwing Lair"]={"Razorgore","Vaelastrasz","Broodlord Lashlayer","Firemaw","Ebonroc","Flamegor","Chromaggus","Nefarian"}, ["Ruins of Ahn'Qiraj"]={"Kurinnaxx","General Rajaxx","Moam","Buru","Ayamiss","Ossirian"}, ["Temple of Ahn'Qiraj"]={"Prophet Skeram","Battleguard Sartura","Fankriss","Huhuran","Twin Emperors","C'Thun","Ouro","Viscidus","Bug Trio"}, ["Naxxramas"]={"Anub'rekhan","Faerlina","Maexxna","Noth","Heigan","Loatheb","Instructor Razuvious","Gothik","Four Horsemen","Patchwerk","Grobbulus","Gluth","Thaddius","Sapphiron","Kel'Thuzad"}, ["Onyxia's Lair"]={"Onyxia"} },
    [1] = { ["Karazhan"]={"Attumen","Moroes","Maiden","Opera","Curator","Illhoof","Shade of Aran","Netherspite","Chess","Prince Malchezaar","Nightbane"}, ["Gruul's Lair"]={"High King Maulgar","Gruul"}, ["Magtheridon's Lair"]={"Magtheridon"}, ["Serpentshrine Cavern"]={"Hydross","Lurker Below","Leotheras","Fathom-Lord Karathress","Morogrim Tidewalker","Lady Vashj"}, ["The Eye"]={"Al'ar","Void Reaver","High Astromancer Solarian","Kael'thas Sunstrider"}, ["Mount Hyjal"]={"Rage Winterchill","Anetheron","Kaz'rogal","Azgalor","Archimonde"}, ["Black Temple"]={"Naj'entus","Supremus","Shade of Akama","Teron Gorefiend","Gurtogg Bloodboil","Reliquary of Souls","Mother Shahraz","Illidari Council","Illidan Stormrage"}, ["Sunwell Plateau"]={"Kalecgos","Brutallus","Felmyst","Eredar Twins","M'uru","Kil'jaeden"} },
    [2] = { ["Naxxramas (WotLK)"]={"Anub'rekhan","Faerlina","Maexxna","Noth","Heigan","Loatheb","Razuvious","Gothik","Four Horsemen","Patchwerk","Grobbulus","Gluth","Thaddius","Sapphiron","Kel'Thuzad"}, ["Ulduar"]={"Flame Leviathan","Ignis","Razorscale","XT-002","Iron Council","Kologarn","Auriaya","Hodir","Thorim","Freya","Mimiron","General Vezax","Yogg-Saron","Algalon"}, ["Trial of the Crusader"]={"Northrend Beasts","Lord Jaraxxus","Faction Champions","Twin Val'kyr","Anub'arak"}, ["Icecrown Citadel"]={"Marrowgar","Deathwhisper","Gunship","Saurfang","Festergut","Rotface","Putricide","Blood Prince Council","Blood-Queen Lana'thel","Valithria","Sindragosa","The Lich King"}, ["Ruby Sanctum"]={"Halion"}, ["Obsidian Sanctum"]={"Sartharion"}, ["Eye of Eternity"]={"Malygos"} },
    [3] = { ["Bastion of Twilight"]={"Halfus","Valiona & Theralion","Ascendant Council","Cho'gall","Sinestra"}, ["Blackwing Descent"]={"Magmaw","Omnotron","Maloriak","Atramedes","Chimaeron","Nefarian"}, ["Throne of the Four Winds"]={"Conclave of Wind","Al'Akir"}, ["Firelands"]={"Beth'tilac","Lord Rhyolith","Alysrazor","Shannox","Baleroc","Majordomo Staghelm","Ragnaros"}, ["Dragon Soul"]={"Morchok","Warlord Zon'ozz","Yor'sahj","Hagara","Ultraxion","Warmaster Blackhorn","Spine of Deathwing","Madness of Deathwing"} },
    [4] = { ["Mogu'shan Vaults"]={"Stone Guard","Feng","Gara'jal","Spirit Kings","Elegon","Will of the Emperor"}, ["Heart of Fear"]={"Vizier Zor'lok","Blade Lord Ta'yak","Garalon","Wind Lord Mel'jarak","Amber-Shaper Un'sok","Grand Empress Shek'zeer"}, ["Terrace of Endless Spring"]={"Protectors of the Endless","Tsulong","Lei Shi","Sha of Fear"}, ["Throne of Thunder"]={"Jin'rokh","Horridon","Council of Elders","Tortos","Megaera","Ji-Kun","Durumu","Primordius","Dark Animus","Iron Qon","Twin Consorts","Lei Shen","Ra-den"}, ["Siege of Orgrimmar"]={"Immerseus","Protectors","Norushen","Sha of Pride","Galakras","Iron Juggernaut","Dark Shaman","General Nazgrim","Malkorok","Spoils","Thok","Siegecrafter Blackfuse","Paragons","Garrosh Hellscream"} },
    [5] = { ["Highmaul"]={"Kargath","The Butcher","Tectus","Brackenspore","Twin Ogron","Ko'ragh","Imperator Mar'gok"}, ["Blackrock Foundry"]={"Gruul","Oregorger","Blast Furnace","Hans'gar & Franzok","Flamebender Ka'graz","Kromog","Beastlord Darmac","Operator Thogar","Iron Maidens","Blackhand"}, ["Hellfire Citadel"]={"Hellfire Assault","Iron Reaver","Kormrok","Council","Kilrogg","Gorefiend","Iskar","Socrethar","Velhari","Zakuun","Xhul'horac","Mannoroth","Archimonde"} },
    [6] = { ["Emerald Nightmare"]={"Nythendra","Il'gynoth","Elerethe Renferal","Ursoc","Dragons of Nightmare","Cenarius","Xavius"}, ["Trial of Valor"]={"Odyn","Guarm","Helya"}, ["Nighthold"]={"Skorpyron","Anomaly","Trilliax","Spellblade Aluriel","Tichondrius","Krosus","Tel'arn","Star Augur","Elisande","Gul'dan"}, ["Tomb of Sargeras"]={"Goroth","Demonic Inquisition","Harjatan","Sisters","Mistress Sassz'ine","Desolate Host","Maiden","Fallen Avatar","Kil'jaeden"}, ["Antorus, the Burning Throne"]={"Garothi","Felhounds","Antoran High Command","Eonar","Portal Keeper Hasabel","Imonar","Kin'garoth","Varimathras","Coven of Shivarra","Aggramar","Argus"} },
    [7] = { ["Uldir"]={"Taloc","MOTHER","Fetid Devourer","Zek'voz","Vectis","Zul","Mythrax","G'huun"}, ["Battle of Dazar'alor"]={"Champion of the Light","Jadefire Masters","Grong","Opulence","Conclave","Rastakhan","Mekkatorque","Stormwall Blockade","Jaina Proudmoore"}, ["Crucible of Storms"]={"Restless Cabal","Uu'nat"}, ["The Eternal Palace"]={"Sivara","Radiance","Behemoth","Ashvane","Orgozoa","Queen's Court","Za'qul","Azshara"}, ["Ny'alotha"]={"Wrathion","Maut","Skitra","Xanesh","Vexiona","Hivemind","Ra-den","Shad'har","Drest'agath","Il'gynoth","Carapace","N'Zoth"} },
    [8] = { ["Castle Nathria"]={"Shriekwing","Huntsman","Hungering Destroyer","Lady Inerva","Sun King","Artificer Xy'mox","Council of Blood","Sludgefist","Stone Legion Generals","Sire Denathrius"}, ["Sanctum of Domination"]={"Tarragrue","Eye of the Jailer","The Nine","Remnant of Ner'zhul","Soulrender","Painsmith","Guardian","Fatescribe","Kel'Thuzad","Sylvanas"}, ["Sepulcher of the First Ones"]={"Vigilant Guardian","Skolex","Xy'mox","Dausegne","Pantheon","Lihuvim","Halondrus","Anduin","Lords of Dread","Rygelon","Jailer"} },
    [9] = { ["Vault of the Incarnates"]={"Eranog","Terros","Primal Council","Sennarth","Dathea","Kurog","Diurna","Raszageth"}, ["Aberrus, the Shadowed Crucible"]={"Kazzara","Amalgamation","Forgotten Experiments","Assault","Rashok","Zskarn","Magmorax","Neltharion","Sarkareth"}, ["Amirdrassil, the Dream's Hope"]={"Gnarlroot","Igira","Volcoross","Council of Dreams","Larodar","Nymue","Smolderon","Tindral","Fyrakk"} },
    [10] = { ["Nerub-ar Palace"]={"Ulgrax","Bloodbound Horror","Sikran","Rasha'nan","Broodtwister","Ky'veza","Silken Court","Ansurek"}, ["Liberation of Undermine"]={"Vexie and the Geargrinders", "Cauldron of Carnage", "Rik Reverb", "Stix Bunkjunker", "Sprocketmonger Lockenstock", "The One-Armed Bandit", "Mug'Zee, Heads of Security", "Chrome King Gallywix"}, ["Manaforge Omega"]={"Plexus Sentinel", "Loom'ithar", "Soulbinder Naazindhri", "Forgeweaver Araz", "The Soul Hunters", "Fractillus", "Nexus-King Salhadaar", "Dimensius, the All-Devouring"} },
    [11] = { ["The Voidspire"]={"Imperator Averzian", "Vorasius", "Fallen-King Salhadaar", "Vaelgor & Ezzorak", "Lightblinded Vanguard", "Crown of the Cosmos"}, ["The Dreamrift"]={"Chimaerus, the Undreamt God"}, ["March on Quel'Danas"]={"Belo'ren, Child of Al'ar", "Midnight Falls"} }
}

-- STATIC POPUPS
StaticPopupDialogs["DTC_RESET_CONFIRM"] = {
    text = "LEADER: Reset ALL SCORE data? (Identities will be kept).",
    button1 = "Confirm", button2 = "Cancel",
    OnAccept = function()
        local savedIds = DTCRaidDB.identities or {}
        local savedSettings = DTCRaidDB.settings or {}
        local savedClasses = DTCRaidDB.classes or {}
        DTCRaidDB = { global={}, raids={}, bosses={}, trips={}, expMap={}, raidMap={}, dates={}, history={}, identities=savedIds, classes=savedClasses, settings=savedSettings }
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
        DTCRaidDB = { global={}, raids={}, bosses={}, trips={}, expMap={}, raidMap={}, dates={}, history={}, identities={}, classes={}, settings=savedSettings }
        if DTC_RefreshLeaderboard then DTC_RefreshLeaderboard() end
        print("|cFFFF0000DTC:|r Local data reset.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_PURGE_CONFIRM"] = {
    text = "Are you sure you want to PURGE matching history entries? This cannot be undone.",
    button1 = "Purge", button2 = "Cancel",
    OnAccept = function() DTC_PurgeMatchingHistory() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- 2. LOADING & HELPERS
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

function DTC_GetExpansionForRaid(raidName)
    for expID, raids in pairs(STATIC_DATA) do for rName, _ in pairs(raids) do if rName == raidName then return tostring(expID) end end end
    return "10" 
end

function DTC_GetAnnounceName(name)
    local nick = DTCRaidDB.identities[name]
    local fmt = DTCRaidDB.settings.announceFormat or "BOTH"
    if not nick then return name end
    if fmt == "CHAR" then return name elseif fmt == "NICK" then return nick else return name .. " (" .. nick .. ")" end
end

function DTC_EnsureNicknames()
    if not IsInGroup() then return end
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, classFileName = GetRaidRosterInfo(i)
        if name then
            if classFileName then DTCRaidDB.classes[name] = classFileName end 
            if not DTCRaidDB.identities[name] then
                DTCRaidDB.identities[name] = name 
            end
        end
    end
end

function DTC_RebuildAggregates()
    DTCRaidDB.global = {}; DTCRaidDB.raids = {}; DTCRaidDB.bosses = {}; DTCRaidDB.trips = DTCRaidDB.trips or {}
    for _, h in ipairs(DTCRaidDB.history) do
        local pts = h.p or 0; local winner = h.w
        DTCRaidDB.global[winner] = (DTCRaidDB.global[winner] or 0) + pts
        DTCRaidDB.raids[h.r] = DTCRaidDB.raids[h.r] or {}; DTCRaidDB.raids[h.r][winner] = (DTCRaidDB.raids[h.r][winner] or 0) + pts
        DTCRaidDB.bosses[h.b] = DTCRaidDB.bosses[h.b] or {}; DTCRaidDB.bosses[h.b][winner] = (DTCRaidDB.bosses[h.b][winner] or 0) + pts
    end
    if DTC_RefreshLeaderboard then DTC_RefreshLeaderboard() end
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
            DTCRaidDB.history = DTCRaidDB.history or {}
            DTCRaidDB.identities = DTCRaidDB.identities or {}
            DTCRaidDB.classes = DTCRaidDB.classes or {}
            DTCRaidDB.settings = DTCRaidDB.settings or {}
            
            -- Defaults
            DTCRaidDB.settings.awardMsg = DTCRaidDB.settings.awardMsg or "CONGRATULATIONS %s! You have won an all expenses paid trip to Disney World!"
            DTCRaidDB.settings.announceFormat = DTCRaidDB.settings.announceFormat or "BOTH"
            DTCRaidDB.settings.voteSortMode = DTCRaidDB.settings.voteSortMode or "ROLE"
            DTCRaidDB.settings.voteAnnounceHeader = DTCRaidDB.settings.voteAnnounceHeader or "--- DTC Results: %s ---"
            DTCRaidDB.settings.voteFinalizeMsg = DTCRaidDB.settings.voteFinalizeMsg or "Voting has been finalized for %s!"
            
            DTCRaidDB.settings.voteWinMsg = DTCRaidDB.settings.voteWinMsg or "Congrats %s on getting the most votes!"
            DTCRaidDB.settings.voteRunnerUpMsg = DTCRaidDB.settings.voteRunnerUpMsg or "%s are right on your heels! Don't let up!"
            DTCRaidDB.settings.voteLowMsg = DTCRaidDB.settings.voteLowMsg or "%s, step your game up if you want a shot at Disney World!"
            if DTCRaidDB.settings.voteLowEnabled == nil then DTCRaidDB.settings.voteLowEnabled = true end
            
            DTC_InitOptionsPanel()
            DTC_EnsureNicknames() 
            self:RegisterEvent("CHAT_MSG_ADDON")
            self:RegisterEvent("ENCOUNTER_END")
            print("|cFFFFD700DTC Tracker|r " .. DTC_VERSION .. " loaded.")
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        DTC_EnsureNicknames()
    elseif event == "PLAYER_LOGOUT" then
        if DTC_MainFrame then DTCRaidDB.settings.votePos = {DTC_MainFrame:GetPoint()} end
        if DTC_LeaderboardFrame then DTCRaidDB.settings.lbPos = {DTC_LeaderboardFrame:GetPoint()}; DTCRaidDB.settings.lbSize = {DTC_LeaderboardFrame:GetWidth(), DTC_LeaderboardFrame:GetHeight()} end
        if DTC_HistoryFrame then DTCRaidDB.settings.histPos = {DTC_HistoryFrame:GetPoint()}; DTCRaidDB.settings.histSize = {DTC_HistoryFrame:GetWidth(), DTC_HistoryFrame:GetHeight()} end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, sender = ...
        if prefix == DTC_PREFIX then DTC_HandleComm(msg, sender) end
    elseif event == "ENCOUNTER_END" then
        local _, encounterName, _, _, success = ...
        if success == 1 then
            lastBossName = encounterName; votingOpen = true; isTestMode = false; currentVotes = {}; currentVoters = {}; myVotesLeft = 3
            C_ChatInfo.SendAddonMessage(DTC_PREFIX, "PING_ADDON", "RAID")
            C_Timer.After(2, function() DTC_OpenVotingWindow() end)
        end
    end
end)

-- 3. COMMS
function DTC_HandleComm(msg, sender)
    sender = Ambiguate(sender, "none"); local player = UnitName("player"); local action, data = strsplit(":", msg, 2)
    if action == "VOTE" then
        if sender ~= player then currentVotes[data] = (currentVotes[data] or 0) + 1; currentVoters[sender] = true; if DTC_MainFrame and DTC_MainFrame:IsShown() then DTC_RefreshVotingList() end end
    elseif action == "FINALIZE" then
        local target, points, boss, raidName, dateStr, diffName = strsplit(",", data); points = tonumber(points)
        table.insert(DTCRaidDB.history, 1, {b = boss, w = target, p = points, d = dateStr, r = raidName, v = "", diff = diffName})
        if #DTCRaidDB.history > 2000 then table.remove(DTCRaidDB.history) end
        DTC_RebuildAggregates()
        votingOpen = false
        if DTC_MainFrame and DTC_MainFrame:IsShown() then DTC_MainFrame.title:SetText("Results: " .. (lastBossName or "Boss")); DTC_RefreshVotingList() end
    elseif action == "PING_ADDON" then C_ChatInfo.SendAddonMessage(DTC_PREFIX, "PONG_ADDON", "RAID")
    elseif action == "PONG_ADDON" then addonUsers[sender] = true; if DTC_MainFrame and DTC_MainFrame:IsShown() then DTC_RefreshVotingList() end
    elseif action == "SYNC_PUSH" then
        DTC_ProcessSyncChunk(data)
    end
end

function DTC_ProcessSyncChunk(data)
    local b, w, p, d, r, diff = strsplit(",", data)
    if b and w and p then
         table.insert(DTCRaidDB.history, {b=b, w=w, p=tonumber(p), d=d, r=r, diff=diff})
         DTC_RebuildAggregates()
         print("|cFFFFD700DTC:|r Received sync data entry.")
    end
end

-- 4. VOTING UI (Role Based)
function DTC_OpenVotingWindow() 
    DTC_CreateUI()
    if DTC_MainFrame:IsShown() then DTC_MainFrame:Hide() return end
    DTC_MainFrame.title:SetText("Voting: " .. (lastBossName or "Test"))
    DTC_MainFrame:Show()
    DTC_RefreshVotingList() 
end

function DTC_CreateUI()
    if DTC_MainFrame then return end
    local frame = CreateFrame("Frame", "DTC_MainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(350, 480); frame:SetClampedToScreen(true)
    if DTCRaidDB.settings and DTCRaidDB.settings.votePos then local p = DTCRaidDB.settings.votePos; frame:SetPoint(p[1], UIParent, p[2], p[4], p[5]) else frame:SetPoint("CENTER") end
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); DTCRaidDB.settings.votePos = {self:GetPoint()} end)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); frame.title:SetPoint("TOP", 0, -15); frame.title:SetText("Disney Trip Voting")

    local sf = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 15, -50); sf:SetPoint("BOTTOMRIGHT", -35, 100)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(300, 1); sf:SetScrollChild(content)
    frame.content = content

    frame.finalizeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.finalizeBtn:SetSize(110, 25); frame.finalizeBtn:SetPoint("BOTTOMLEFT", 15, 15); frame.finalizeBtn:SetText("Finalize")
    frame.finalizeBtn:SetScript("OnClick", function()
        if isTestMode then print("|cFFFFD700DTC:|r Cannot finalize in Test Mode."); return end
        local raidName = GetInstanceInfo()
        local _, _, _, _, _, _, _, _, _, difficultyName = GetInstanceInfo()
        local dStr = date("%Y-%m-%d")
        
        for p, v in pairs(currentVotes) do
            if not p:find("_VOTED_BY_ME") and v > 0 then 
                C_ChatInfo.SendAddonMessage(DTC_PREFIX, "FINALIZE:"..p..","..v..","..lastBossName..","..raidName..","..dStr..","..(difficultyName or "Normal"), "RAID") 
            end
        end
        local msg = DTCRaidDB.settings.voteFinalizeMsg:format(lastBossName or "Boss")
        SendChatMessage(msg, "RAID")
        votingOpen = false; DTC_RefreshVotingList()
    end)

    frame.announceBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.announceBtn:SetSize(110, 25); frame.announceBtn:SetPoint("BOTTOMLEFT", 130, 15); frame.announceBtn:SetText("Announce")
    frame.announceBtn:SetScript("OnClick", function()
        if isTestMode then print("|cFFFFD700DTC:|r Test Announcement: Results printed locally."); return end
        local sorted = {}; for p, v in pairs(currentVotes) do if not p:find("_VOTED_BY_ME") and v > 0 then table.insert(sorted, {n=p, v=v}) end end
        table.sort(sorted, function(a,b) return a.v > b.v end)
        
        -- Header
        local head = DTCRaidDB.settings.voteAnnounceHeader:format(lastBossName or "Boss")
        SendChatMessage(head, "RAID")
        
        -- List
        for i=1, math.min(3, #sorted) do 
            local dName = DTC_GetAnnounceName(sorted[i].n)
            SendChatMessage(i .. ". " .. dName .. " (" .. sorted[i].v .. " pts)", "RAID") 
        end
        
        -- Winner Msg
        if #sorted >= 1 then
            local winName = DTC_GetAnnounceName(sorted[1].n)
            SendChatMessage(DTCRaidDB.settings.voteWinMsg:format(winName), "RAID")
        end
        
        -- Runners Up
        if #sorted >= 2 then
            local runners = DTC_GetAnnounceName(sorted[2].n)
            if sorted[3] then runners = runners .. " & " .. DTC_GetAnnounceName(sorted[3].n) end
            SendChatMessage(DTCRaidDB.settings.voteRunnerUpMsg:format(runners), "RAID")
        end
        
        -- Low Votes
        if DTCRaidDB.settings.voteLowEnabled and #sorted > 0 then
            local minScore = sorted[#sorted].v
            local losers = {}
            for i = #sorted, 1, -1 do
                if sorted[i].v == minScore then table.insert(losers, DTC_GetAnnounceName(sorted[i].n)) else break end
            end
            local loserString = table.concat(losers, ", ")
            SendChatMessage(DTCRaidDB.settings.voteLowMsg:format(loserString), "RAID")
        end
    end)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"); closeBtn:SetSize(70, 25); closeBtn:SetPoint("BOTTOMRIGHT", -15, 15); closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.votesLeftText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.votesLeftText:SetPoint("BOTTOMLEFT", 15, 50)
    frame:Hide()
end

function DTC_RefreshVotingList()
    local content = DTC_MainFrame.content
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    local isLeader = UnitIsGroupLeader("player")
    DTC_MainFrame.finalizeBtn:SetShown((isLeader or isTestMode) and votingOpen)
    DTC_MainFrame.announceBtn:SetShown((isLeader or isTestMode) and (lastBossName ~= "No Recent Boss"))

    local tanks, healers, dps, all = {}, {}, {}, {}
    local roleMap = { ["TANK"]=tanks, ["HEALER"]=healers, ["DAMAGER"]=dps, ["NONE"]=dps }

    if isTestMode then
        local t1={name="TestMage", class="MAGE"}; local t2={name="TestTank", class="WARRIOR"}; local t3={name="TestHeal", class="PRIEST"}
        table.insert(dps, t1); table.insert(tanks, t2); table.insert(healers, t3)
        table.insert(all, t1); table.insert(all, t2); table.insert(all, t3)
    else
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, classFileName, _, online, _, role = GetRaidRosterInfo(i)
            if name then 
                if classFileName then DTCRaidDB.classes[name] = classFileName end
                local t = {name=name, class=classFileName}
                if roleMap[role] then table.insert(roleMap[role], t) else table.insert(dps, t) end
                table.insert(all, t)
            end
        end
    end

    local yOffset = 0
    local function RenderSection(title, list)
        if #list == 0 then return end
        if title ~= "" then
            local h = content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); h:SetPoint("TOPLEFT", 5, yOffset); h:SetText(title)
            yOffset = yOffset - 20
        end
        table.sort(list, function(a,b) return a.name < b.name end)
        for _, p in ipairs(list) do
            local row = CreateFrame("Frame", nil, content); row:SetSize(300, 24); row:SetPoint("TOPLEFT", 0, yOffset)
            
            local status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); status:SetPoint("LEFT", 0, 0)
            if currentVoters[p.name] then status:SetText("|cFF00FF00✔|r")
            elseif addonUsers[p.name] then status:SetText("|cFFFF0000✖|r")
            else status:SetText("|cFF888888?|r") end
            
            local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); nameTxt:SetPoint("LEFT", 15, 0); 
            local color = RAID_CLASS_COLORS[p.class] or {r=1,g=1,b=1}
            nameTxt:SetTextColor(color.r, color.g, color.b)
            local dName = p.name
            local nick = DTCRaidDB.identities[p.name]
            if nick then dName = p.name .. " ("..nick..")" end
            nameTxt:SetText(dName)
            
            local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate"); btn:SetSize(50, 20); btn:SetPoint("RIGHT", -5, 0); btn:SetText("Vote")
            if not votingOpen or myVotesLeft == 0 or currentVotes[p.name.."_VOTED_BY_ME"] then btn:Disable() end
            btn:SetScript("OnClick", function()
                currentVotes[p.name] = (currentVotes[p.name] or 0) + 1; myVotesLeft = myVotesLeft - 1; currentVotes[p.name.."_VOTED_BY_ME"] = true
                currentVoters[UnitName("player")] = true
                if not isTestMode then C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VOTE:"..p.name, "RAID") end
                DTC_RefreshVotingList()
            end)
            local count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal"); count:SetPoint("RIGHT", -60, 0); count:SetText(currentVotes[p.name] or "0")
            yOffset = yOffset - 24
        end
        yOffset = yOffset - 10
    end

    if DTCRaidDB.settings.voteSortMode == "ALPHA" then
        RenderSection("", all)
    else
        RenderSection("TANKS", tanks); RenderSection("HEALERS", healers); RenderSection("DPS / OTHERS", dps)
    end
    
    if votingOpen then DTC_MainFrame.votesLeftText:SetText("Votes Left: " .. myVotesLeft) else DTC_MainFrame.votesLeftText:SetText("|cFFFF0000LOCKED|r") end
end

-- 5. CONFIG OPTIONS (Strict Container Separation)
local function CreateGroupBox(parent, title, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    local t = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 10, -10) 
    t:SetText(title)
    return frame
end

function DTC_PurgeMatchingHistory()
    local kept = {}; local count = 0
    for _, h in ipairs(DTCRaidDB.history) do
        local match = true
        if pSelExp ~= "ALL" then local raids = STATIC_DATA[tonumber(pSelExp)] or {}; if not raids[h.r] then match = false end end
        if pSelRaid ~= "ALL" and h.r ~= pSelRaid then match = false end
        if pSelDiff ~= "ALL" and h.diff ~= pSelDiff then match = false end
        if pSelDate ~= "ALL" and h.d ~= pSelDate then match = false end
        if match then count = count + 1 else table.insert(kept, h) end
    end
    DTCRaidDB.history = kept
    DTC_RebuildAggregates()
    print("|cFFFFD700DTC:|r Purged " .. count .. " matching entries.")
end

function DTC_SendSync(target)
    if not target or target == "" then print("Invalid target"); return end
    print("|cFFFFD700DTC:|r Sending data to " .. target .. "...")
    for _, h in ipairs(DTCRaidDB.history) do
        local match = true
        if sSelExp ~= "ALL" then local raids = STATIC_DATA[tonumber(sSelExp)] or {}; if not raids[h.r] then match = false end end
        if sSelRaid ~= "ALL" and h.r ~= sSelRaid then match = false end
        if sSelDiff ~= "ALL" and h.diff ~= sSelDiff then match = false end
        if sSelDate ~= "ALL" and h.d ~= sSelDate then match = false end
        if match then
            local payload = string.format("%s,%s,%d,%s,%s,%s", h.b, h.w, h.p, h.d, h.r, h.diff or "")
            C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_PUSH:"..payload, "WHISPER", target)
        end
    end
    print("|cFFFFD700DTC:|r Sync complete.")
end

local function DTC_SelectPExp(self) pSelExp = self.arg1; pSelRaid="ALL"; pSelDiff="ALL"; UIDropDownMenu_SetText(DTC_PurgeExpDD, self.value); CloseDropDownMenus() end
local function DTC_SelectPRaid(self) pSelRaid = self.arg1; pSelDiff="ALL"; UIDropDownMenu_SetText(DTC_PurgeRaidDD, self.value); CloseDropDownMenus() end
local function DTC_SelectPDiff(self) pSelDiff = self.arg1; UIDropDownMenu_SetText(DTC_PurgeDiffDD, self.value); CloseDropDownMenus() end
local function DTC_SelectPDate(self) pSelDate = self.arg1; UIDropDownMenu_SetText(DTC_PurgeDateDD, self.value); CloseDropDownMenus() end

local function DTC_SelectSExp(self) sSelExp = self.arg1; sSelRaid="ALL"; sSelDiff="ALL"; UIDropDownMenu_SetText(DTC_SyncExpDD, self.value); CloseDropDownMenus() end
local function DTC_SelectSRaid(self) sSelRaid = self.arg1; sSelDiff="ALL"; UIDropDownMenu_SetText(DTC_SyncRaidDD, self.value); CloseDropDownMenus() end
local function DTC_SelectSDiff(self) sSelDiff = self.arg1; UIDropDownMenu_SetText(DTC_SyncDiffDD, self.value); CloseDropDownMenus() end
local function DTC_SelectSDate(self) sSelDate = self.arg1; UIDropDownMenu_SetText(DTC_SyncDateDD, self.value); CloseDropDownMenus() end

function DTC_InitPExp(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectPExp; info.checked=(pSelExp=="ALL"); UIDropDownMenu_AddButton(info, level); for i=11,0,-1 do info.text=EXPANSION_NAMES[i]; info.arg1=tostring(i); info.value=EXPANSION_NAMES[i]; info.func=DTC_SelectPExp; info.checked=(pSelExp==tostring(i)); UIDropDownMenu_AddButton(info, level) end end
function DTC_InitPRaid(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectPRaid; info.checked=(pSelRaid=="ALL"); UIDropDownMenu_AddButton(info, level); if STATIC_DATA[tonumber(pSelExp)] then for rName,_ in pairs(STATIC_DATA[tonumber(pSelExp)]) do info.text=rName; info.arg1=rName; info.value=rName; info.func=DTC_SelectPRaid; info.checked=(pSelRaid==rName); UIDropDownMenu_AddButton(info, level) end end end
function DTC_InitPDiff(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectPDiff; info.checked=(pSelDiff=="ALL"); UIDropDownMenu_AddButton(info, level); local diffs = EXP_DIFFICULTIES[tonumber(pSelExp)] or EXP_DIFFICULTIES["DEFAULT"]; for _, d in ipairs(diffs) do info.text=d; info.arg1=d; info.value=d; info.func=DTC_SelectPDiff; info.checked=(pSelDiff==d); UIDropDownMenu_AddButton(info, level) end end
function DTC_InitPDate(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectPDate; info.checked=(pSelDate=="ALL"); UIDropDownMenu_AddButton(info, level); local seen={}; local list={}; for _,h in ipairs(DTCRaidDB.history) do if not seen[h.d] then seen[h.d]=true; table.insert(list,h.d) end end; table.sort(list, function(a,b) return a>b end); for _,d in ipairs(list) do info.text=d; info.arg1=d; info.value=d; info.func=DTC_SelectPDate; info.checked=(pSelDate==d); UIDropDownMenu_AddButton(info, level) end end

function DTC_InitSExp(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectSExp; info.checked=(sSelExp=="ALL"); UIDropDownMenu_AddButton(info, level); for i=11,0,-1 do info.text=EXPANSION_NAMES[i]; info.arg1=tostring(i); info.value=EXPANSION_NAMES[i]; info.func=DTC_SelectSExp; info.checked=(sSelExp==tostring(i)); UIDropDownMenu_AddButton(info, level) end end
function DTC_InitSRaid(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectSRaid; info.checked=(sSelRaid=="ALL"); UIDropDownMenu_AddButton(info, level); if STATIC_DATA[tonumber(sSelExp)] then for rName,_ in pairs(STATIC_DATA[tonumber(sSelExp)]) do info.text=rName; info.arg1=rName; info.value=rName; info.func=DTC_SelectSRaid; info.checked=(sSelRaid==rName); UIDropDownMenu_AddButton(info, level) end end end
function DTC_InitSDiff(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectSDiff; info.checked=(sSelDiff=="ALL"); UIDropDownMenu_AddButton(info, level); local diffs = EXP_DIFFICULTIES[tonumber(sSelExp)] or EXP_DIFFICULTIES["DEFAULT"]; for _, d in ipairs(diffs) do info.text=d; info.arg1=d; info.value=d; info.func=DTC_SelectSDiff; info.checked=(sSelDiff==d); UIDropDownMenu_AddButton(info, level) end end
function DTC_InitSDate(self, level) local info=UIDropDownMenu_CreateInfo(); info.text="All"; info.arg1="ALL"; info.func=DTC_SelectSDate; info.checked=(sSelDate=="ALL"); UIDropDownMenu_AddButton(info, level); local seen={}; local list={}; for _,h in ipairs(DTCRaidDB.history) do if not seen[h.d] then seen[h.d]=true; table.insert(list,h.d) end end; table.sort(list, function(a,b) return a>b end); for _,d in ipairs(list) do info.text=d; info.arg1=d; info.value=d; info.func=DTC_SelectSDate; info.checked=(sSelDate==d); UIDropDownMenu_AddButton(info, level) end end

function DTC_RefreshNickOptions(content)
    if not content then return end
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    
    local canEdit = UnitIsGroupLeader("player") or (not IsInGroup())
    local keys = {}; for k, _ in pairs(DTCRaidDB.identities) do table.insert(keys, k) end
    for i = 1, GetNumGroupMembers() do 
        local name = GetRaidRosterInfo(i)
        if name and not DTCRaidDB.identities[name] then table.insert(keys, name) end 
    end
    
    local seen = {}; local uniqueKeys = {}
    for _, k in ipairs(keys) do if not seen[k] then seen[k]=true; table.insert(uniqueKeys, k) end end
    table.sort(uniqueKeys)

    local yOffset = 0
    for _, name in ipairs(uniqueKeys) do
        local row = CreateFrame("Frame", nil, content); row:SetSize(520, 24); row:SetPoint("TOPLEFT", 0, yOffset)
        
        local cFile = DTCRaidDB.classes[name] or "PRIEST"
        local color = RAID_CLASS_COLORS[cFile] or {r=0.6,g=0.6,b=0.6}
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); label:SetPoint("LEFT", 5, 0); label:SetWidth(150); label:SetJustifyH("LEFT"); label:SetText(name); label:SetTextColor(color.r, color.g, color.b)
        
        local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); eb:SetSize(200, 20); eb:SetPoint("LEFT", label, "RIGHT", 10, 0); eb:SetAutoFocus(false)
        local val = DTCRaidDB.identities[name]
        if not val or val == "" then val = name end
        eb:SetText(val)
        
        eb:SetEnabled(canEdit); if not canEdit then eb:SetTextColor(0.5, 0.5, 0.5) end
        
        local function Save() 
            local txt = eb:GetText()
            if txt == "" then txt = name end
            DTCRaidDB.identities[name] = txt 
        end
        
        eb:SetScript("OnEnterPressed", function(self) Save(); self:ClearFocus() end)
        eb:SetScript("OnEditFocusLost", function(self) Save() end)
        yOffset = yOffset - 25
    end
end

-- CONFIG DROPDOWN HELPERS
local function DTC_SelectConfigFormat(self) DTCRaidDB.settings.announceFormat = self.arg1; UIDropDownMenu_SetText(DTC_OptionsAnnounceDD, self.value); CloseDropDownMenus() end
function DTC_InitConfigFormatMenu(self, level)
    local info = UIDropDownMenu_CreateInfo(); info.func = DTC_SelectConfigFormat
    info.text = "Character Name"; info.arg1 = "CHAR"; info.value = "Character Name"; info.checked = (DTCRaidDB.settings.announceFormat == "CHAR"); UIDropDownMenu_AddButton(info, level)
    info.text = "Nickname"; info.arg1 = "NICK"; info.value = "Nickname"; info.checked = (DTCRaidDB.settings.announceFormat == "NICK"); UIDropDownMenu_AddButton(info, level)
    info.text = "Both"; info.arg1 = "BOTH"; info.value = "Both"; info.checked = (DTCRaidDB.settings.announceFormat == "BOTH"); UIDropDownMenu_AddButton(info, level)
end

local function DTC_SelectVoteSort(self) DTCRaidDB.settings.voteSortMode = self.arg1; UIDropDownMenu_SetText(DTC_OptionsVoteSortDD, self.value); CloseDropDownMenus() end
function DTC_InitVoteSortMenu(self, level)
    local info = UIDropDownMenu_CreateInfo(); info.func = DTC_SelectVoteSort
    info.text = "Show Players and Roles"; info.arg1 = "ROLE"; info.value = "Show Players and Roles"; info.checked = (DTCRaidDB.settings.voteSortMode == "ROLE"); UIDropDownMenu_AddButton(info, level)
    info.text = "Show Only Players"; info.arg1 = "ALPHA"; info.value = "Show Only Players"; info.checked = (DTCRaidDB.settings.voteSortMode == "ALPHA"); UIDropDownMenu_AddButton(info, level)
end

function DTC_InitOptionsPanel()
    -- IMPORTANT: Create panel without parent to avoid SetPoint crash in 10.x+
    local panel = CreateFrame("Frame", "DTC_OptionsPanel"); panel.name = "DTC Raid Tracker"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText("DTC Raid Tracker")
    
    panel.Tabs = {}
    -- Use UIPanelButtonTemplate instead of PanelTopTabButtonTemplate to fix anchor family crash
    local function CreateTab(id, text, anchor) 
        local t = CreateFrame("Button", "DTC_OptTab"..id, panel, "UIPanelButtonTemplate")
        t:SetID(id); t:SetText(text); t:SetSize(100, 22)
        if id==1 then t:SetPoint("TOPLEFT", 20, -40) else t:SetPoint("LEFT", anchor, "RIGHT", 5, 0) end
        t:SetFrameLevel(panel:GetFrameLevel()+5); table.insert(panel.Tabs, t); return t 
    end
    
    local t1 = CreateTab(1, "General", nil); local t2 = CreateTab(2, "Nicknames", t1); local t3 = CreateTab(3, "Leaderboard", t2); local t4 = CreateTab(4, "History & Sync", t3); local t5 = CreateTab(5, "Voting", t4); panel.numTabs = 5
    
    -- Explicitly create 5 frames (No loops to avoid scope issues)
    local f1 = CreateFrame("Frame", nil, panel); f1:SetSize(600, 500); f1:SetPoint("TOPLEFT", 20, -70)
    local f2 = CreateFrame("Frame", nil, panel); f2:SetSize(600, 500); f2:SetPoint("TOPLEFT", 20, -70); f2:Hide()
    local f3 = CreateFrame("Frame", nil, panel); f3:SetSize(600, 500); f3:SetPoint("TOPLEFT", 20, -70); f3:Hide()
    local f4 = CreateFrame("Frame", nil, panel); f4:SetSize(600, 500); f4:SetPoint("TOPLEFT", 20, -70); f4:Hide()
    local f5 = CreateFrame("Frame", nil, panel); f5:SetSize(600, 500); f5:SetPoint("TOPLEFT", 20, -70); f5:Hide()
    
    local function UpdTabs(id)
        for _,tab in ipairs(panel.Tabs) do if tab:GetID()==id then tab:Disable() else tab:Enable() end end
        f1:Hide(); f2:Hide(); f3:Hide(); f4:Hide(); f5:Hide()
        if id==1 then f1:Show() elseif id==2 then f2:Show(); DTC_RefreshNickOptions(f2.content) elseif id==3 then f3:Show() elseif id==4 then f4:Show() elseif id==5 then f5:Show() end
    end
    for i, t in ipairs(panel.Tabs) do t:SetScript("OnClick", function() UpdTabs(i) end) end; UpdTabs(1)
    
    -- TAB 1: GENERAL
    local b1 = CreateGroupBox(f1, "General Options", 580, 80); b1:SetPoint("TOPLEFT", 0, 0)
    local btnTest = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate"); btnTest:SetSize(140, 24); btnTest:SetPoint("TOPLEFT", 15, -40); btnTest:SetText("Test Vote Window"); btnTest:SetScript("OnClick", function() isTestMode=true; votingOpen=true; lastBossName="Test Boss"; currentVotes={}; myVotesLeft=3; DTC_OpenVotingWindow() end)
    local btnVer = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate"); btnVer:SetSize(140, 24); btnVer:SetPoint("LEFT", btnTest, "RIGHT", 10, 0); btnVer:SetText("Version Check"); btnVer:SetScript("OnClick", function() C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VER_QUERY", "RAID") end)
    
    -- TAB 2: NICKNAMES
    local b2 = CreateGroupBox(f2, "Roster Configuration", 580, 400); b2:SetPoint("TOPLEFT", 0, 0)
    local sf = CreateFrame("ScrollFrame", "DTC_NickScroll", b2, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 10, -35); sf:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 1); sf:SetScrollChild(content); f2.content = content
    
    -- TAB 3: LEADERBOARD
    local b3 = CreateGroupBox(f3, "Announcement Options", 580, 80); b3:SetPoint("TOPLEFT", 0, 0)
    local la = b3:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); la:SetPoint("TOPLEFT", 15, -30); la:SetText("Name Format:")
    local da = CreateFrame("Frame", "DTC_OptionsAnnounceDD", b3, "UIDropDownMenuTemplate"); da:SetPoint("LEFT", la, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(da, 160); UIDropDownMenu_Initialize(da, DTC_InitConfigFormatMenu); local it="Both"; if DTCRaidDB.settings.announceFormat=="CHAR" then it="Character Name" elseif DTCRaidDB.settings.announceFormat=="NICK" then it="Nickname" end; UIDropDownMenu_SetText(da, it)
    local b4 = CreateGroupBox(f3, "Award Configuration", 580, 100); b4:SetPoint("TOPLEFT", b3, "BOTTOMLEFT", 0, -10)
    local lm = b4:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lm:SetPoint("TOPLEFT", 15, -30); lm:SetText("Winning Message (%s = Name):")
    local em = CreateFrame("EditBox", nil, b4, "InputBoxTemplate"); em:SetSize(540, 30); em:SetPoint("TOPLEFT", lm, "BOTTOMLEFT", 0, -10); em:SetAutoFocus(false); em:SetText(DTCRaidDB.settings.awardMsg or ""); em:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.awardMsg=self:GetText() end); em:SetScript("OnEnterPressed", function(self) DTCRaidDB.settings.awardMsg=self:GetText(); self:ClearFocus() end)
    
    -- TAB 4: HISTORY & SYNC
    local b5 = CreateGroupBox(f4, "Database Maintenance", 580, 80); b5:SetPoint("TOPLEFT", 0, 0)
    local btnSR = CreateFrame("Button", nil, b5, "UIPanelButtonTemplate"); btnSR:SetSize(140, 24); btnSR:SetPoint("TOPLEFT", 15, -40); btnSR:SetText("Reset Local Data"); btnSR:SetScript("OnClick", function() StaticPopup_Show("DTC_SELF_RESET_CONFIRM") end)
    
    local b_sync = CreateGroupBox(f4, "Sync Data", 580, 120); b_sync:SetPoint("TOPLEFT", b5, "BOTTOMLEFT", 0, -10)
    local sd1 = CreateFrame("Frame", "DTC_SyncExpDD", b_sync, "UIDropDownMenuTemplate"); sd1:SetPoint("TOPLEFT", 10, -30); UIDropDownMenu_SetWidth(sd1, 120); UIDropDownMenu_Initialize(sd1, DTC_InitSExp); UIDropDownMenu_SetText(sd1, "Expansion")
    local sd2 = CreateFrame("Frame", "DTC_SyncRaidDD", b_sync, "UIDropDownMenuTemplate"); sd2:SetPoint("LEFT", sd1, "RIGHT", -10, 0); UIDropDownMenu_SetWidth(sd2, 120); UIDropDownMenu_Initialize(sd2, DTC_InitSRaid); UIDropDownMenu_SetText(sd2, "Raid")
    local sd3 = CreateFrame("Frame", "DTC_SyncDiffDD", b_sync, "UIDropDownMenuTemplate"); sd3:SetPoint("LEFT", sd2, "RIGHT", -10, 0); UIDropDownMenu_SetWidth(sd3, 80); UIDropDownMenu_Initialize(sd3, DTC_InitSDiff); UIDropDownMenu_SetText(sd3, "Diff")
    local sd4 = CreateFrame("Frame", "DTC_SyncDateDD", b_sync, "UIDropDownMenuTemplate"); sd4:SetPoint("LEFT", sd3, "RIGHT", -10, 0); UIDropDownMenu_SetWidth(sd4, 100); UIDropDownMenu_Initialize(sd4, DTC_InitSDate); UIDropDownMenu_SetText(sd4, "Date")
    
    local lblSync = b_sync:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lblSync:SetPoint("TOPLEFT", 20, -75); lblSync:SetText("Sync to Player (Requires Target):")
    local ebSync = CreateFrame("EditBox", nil, b_sync, "InputBoxTemplate"); ebSync:SetSize(150, 24); ebSync:SetPoint("LEFT", lblSync, "RIGHT", 10, 0); ebSync:SetAutoFocus(false)
    local btnSync2 = CreateFrame("Button", nil, b_sync, "UIPanelButtonTemplate"); btnSync2:SetSize(120, 24); btnSync2:SetPoint("LEFT", ebSync, "RIGHT", 10, 0); btnSync2:SetText("Push Data"); btnSync2:SetScript("OnClick", function() DTC_SendSync(ebSync:GetText()) end)

    local b_purge = CreateGroupBox(f4, "Purge Data", 580, 120); b_purge:SetPoint("TOPLEFT", b_sync, "BOTTOMLEFT", 0, -10)
    local pd1 = CreateFrame("Frame", "DTC_PurgeExpDD", b_purge, "UIDropDownMenuTemplate"); pd1:SetPoint("TOPLEFT", 10, -30); UIDropDownMenu_SetWidth(pd1, 120); UIDropDownMenu_Initialize(pd1, DTC_InitPExp); UIDropDownMenu_SetText(pd1, "Expansion")
    local pd2 = CreateFrame("Frame", "DTC_PurgeRaidDD", b_purge, "UIDropDownMenuTemplate"); pd2:SetPoint("LEFT", pd1, "RIGHT", -10, 0); UIDropDownMenu_SetWidth(pd2, 120); UIDropDownMenu_Initialize(pd2, DTC_InitPRaid); UIDropDownMenu_SetText(pd2, "Raid")
    local pd3 = CreateFrame("Frame", "DTC_PurgeDiffDD", b_purge, "UIDropDownMenuTemplate"); pd3:SetPoint("LEFT", pd2, "RIGHT", -10, 0); UIDropDownMenu_SetWidth(pd3, 80); UIDropDownMenu_Initialize(pd3, DTC_InitPDiff); UIDropDownMenu_SetText(pd3, "Diff")
    local pd4 = CreateFrame("Frame", "DTC_PurgeDateDD", b_purge, "UIDropDownMenuTemplate"); pd4:SetPoint("LEFT", pd3, "RIGHT", -10, 0); UIDropDownMenu_SetWidth(pd4, 100); UIDropDownMenu_Initialize(pd4, DTC_InitPDate); UIDropDownMenu_SetText(pd4, "Date")
    
    local btnP = CreateFrame("Button", nil, b_purge, "UIPanelButtonTemplate"); btnP:SetSize(160, 24); btnP:SetPoint("TOPLEFT", 20, -75); btnP:SetText("Purge Matching Entries"); btnP:SetScript("OnClick", function() StaticPopup_Show("DTC_PURGE_CONFIRM") end)

    -- TAB 5: VOTING
    local b_vOpt = CreateGroupBox(f5, "Voting Options", 580, 80); b_vOpt:SetPoint("TOPLEFT", 0, 0)
    local lblSort = b_vOpt:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lblSort:SetPoint("TOPLEFT", 15, -30); lblSort:SetText("List Format:")
    local daSort = CreateFrame("Frame", "DTC_OptionsVoteSortDD", b_vOpt, "UIDropDownMenuTemplate"); daSort:SetPoint("LEFT", lblSort, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(daSort, 200); UIDropDownMenu_Initialize(daSort, DTC_InitVoteSortMenu); 
    local itSort = "Show Players and Roles"; if DTCRaidDB.settings.voteSortMode == "ALPHA" then itSort = "Show Only Players" end; UIDropDownMenu_SetText(daSort, itSort)

    local b_vAnn = CreateGroupBox(f5, "Announce Configuration", 580, 280); b_vAnn:SetPoint("TOPLEFT", b_vOpt, "BOTTOMLEFT", 0, -10)
    local lblAnn = b_vAnn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lblAnn:SetPoint("TOPLEFT", 15, -30); lblAnn:SetText("Results Header (%s = Boss Name):")
    local ebAnn = CreateFrame("EditBox", nil, b_vAnn, "InputBoxTemplate"); ebAnn:SetSize(540, 20); ebAnn:SetPoint("TOPLEFT", lblAnn, "BOTTOMLEFT", 0, -5); ebAnn:SetAutoFocus(false); ebAnn:SetText(DTCRaidDB.settings.voteAnnounceHeader or ""); ebAnn:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.voteAnnounceHeader=self:GetText() end); ebAnn:SetScript("OnEnterPressed", function(self) DTCRaidDB.settings.voteAnnounceHeader=self:GetText(); self:ClearFocus() end)

    local l1 = b_vAnn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l1:SetPoint("TOPLEFT", ebAnn, "BOTTOMLEFT", 0, -15); l1:SetText("Winner Message (%s = Name):")
    local e1 = CreateFrame("EditBox", nil, b_vAnn, "InputBoxTemplate"); e1:SetSize(540, 20); e1:SetPoint("TOPLEFT", l1, "BOTTOMLEFT", 0, -5); e1:SetAutoFocus(false); e1:SetText(DTCRaidDB.settings.voteWinMsg or ""); e1:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.voteWinMsg=self:GetText() end)

    local l2 = b_vAnn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l2:SetPoint("TOPLEFT", e1, "BOTTOMLEFT", 0, -10); l2:SetText("2nd/3rd Place Message (%s = Names):")
    local e2 = CreateFrame("EditBox", nil, b_vAnn, "InputBoxTemplate"); e2:SetSize(540, 20); e2:SetPoint("TOPLEFT", l2, "BOTTOMLEFT", 0, -5); e2:SetAutoFocus(false); e2:SetText(DTCRaidDB.settings.voteRunnerUpMsg or ""); e2:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.voteRunnerUpMsg=self:GetText() end)

    local l3 = b_vAnn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l3:SetPoint("TOPLEFT", e2, "BOTTOMLEFT", 0, -10); l3:SetText("Lowest Votes Message (%s = Names):")
    local e3 = CreateFrame("EditBox", nil, b_vAnn, "InputBoxTemplate"); e3:SetSize(540, 20); e3:SetPoint("TOPLEFT", l3, "BOTTOMLEFT", 0, -5); e3:SetAutoFocus(false); e3:SetText(DTCRaidDB.settings.voteLowMsg or ""); e3:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.voteLowMsg=self:GetText() end)

    local cbLow = CreateFrame("CheckButton", nil, b_vAnn, "UICheckButtonTemplate"); cbLow:SetPoint("TOPLEFT", e3, "BOTTOMLEFT", -5, -5); cbLow.text:SetText("Enable Lowest Votes Announce"); cbLow:SetChecked(DTCRaidDB.settings.voteLowEnabled); cbLow:SetScript("OnClick", function(self) DTCRaidDB.settings.voteLowEnabled = self:GetChecked() end)

    local b_vFin = CreateGroupBox(f5, "Finalize Configuration", 580, 100); b_vFin:SetPoint("TOPLEFT", b_vAnn, "BOTTOMLEFT", 0, -10)
    local lblFin = b_vFin:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lblFin:SetPoint("TOPLEFT", 15, -30); lblFin:SetText("Finalize Message (%s = Boss Name):")
    local ebFin = CreateFrame("EditBox", nil, b_vFin, "InputBoxTemplate"); ebFin:SetSize(540, 30); ebFin:SetPoint("TOPLEFT", lblFin, "BOTTOMLEFT", 0, -10); ebFin:SetAutoFocus(false); ebFin:SetText(DTCRaidDB.settings.voteFinalizeMsg or ""); ebFin:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.voteFinalizeMsg=self:GetText() end); ebFin:SetScript("OnEnterPressed", function(self) DTCRaidDB.settings.voteFinalizeMsg=self:GetText(); self:ClearFocus() end)

    local cat = Settings.RegisterCanvasLayoutCategory(panel, "DTC Raid Tracker"); Settings.RegisterAddOnCategory(cat); DTC_OptionsCategoryID = cat:GetID()
end

-- 6. LEADERBOARD / HISTORY FUNCTIONS
function DTC_GetSortedData()
    if selTime == "TRIPS" then
        local displayData = {}; for p, v in pairs(DTCRaidDB.trips) do local key = p; if viewMode == "NICK" and DTCRaidDB.identities[p] then key = DTCRaidDB.identities[p] end; displayData[key] = (displayData[key] or 0) + v end
        local sorted = {}; for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end; table.sort(sorted, function(a,b) return a.v > b.v end); return sorted
    end
    local rawData = {}
    if selTime == "ALL" and selDiff == "ALL" then
        if selExp == "ALL" then rawData = DTCRaidDB.global
        else if selRaid == "ALL" then local raids = STATIC_DATA[tonumber(selExp)] or {}; for rName, _ in pairs(raids) do if DTCRaidDB.raids[rName] then for p, v in pairs(DTCRaidDB.raids[rName]) do rawData[p] = (rawData[p] or 0) + v end end end
        else if selBoss == "ALL" then rawData = DTCRaidDB.raids[selRaid] or {} else rawData = DTCRaidDB.bosses[selBoss] or {} end end end
    else 
        local today = date("%Y-%m-%d")
        for _, h in ipairs(DTCRaidDB.history) do
            local pass = true
            if selTime == "TODAY" and h.d ~= today then pass = false end
            if selExp ~= "ALL" then local raids = STATIC_DATA[tonumber(selExp)] or {}; if not raids[h.r] then pass = false end end
            if selRaid ~= "ALL" and h.r ~= selRaid then pass = false end
            if selBoss ~= "ALL" and h.b ~= selBoss then pass = false end
            if selDiff ~= "ALL" and h.diff ~= selDiff then pass = false end
            if pass then rawData[h.w] = (rawData[h.w] or 0) + h.p end
        end
    end
    local displayData = {}
    for charName, val in pairs(rawData) do local key = charName; if viewMode == "NICK" and DTCRaidDB.identities[charName] then key = DTCRaidDB.identities[charName] end; displayData[key] = (displayData[key] or 0) + val end
    local pinkInRaid = false; if IsInGroup() then for i = 1, GetNumGroupMembers() do local name = GetRaidRosterInfo(i); if name and DTCRaidDB.identities[name] == "Pink" then pinkInRaid = true; break end end else local name = UnitName("player"); if name and DTCRaidDB.identities[name] == "Pink" then pinkInRaid = true end end
    if pinkInRaid then local ms = displayData["Mac"]; local ps = displayData["Pink"]; if ms and ps then if ms >= ps then displayData["Mac"] = ps - 1 end end end
    local sorted = {}; for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end; table.sort(sorted, function(a,b) return a.v > b.v end); return sorted
end

function DTC_CreateLeaderboardUI()
    if DTC_LeaderboardFrame then return end
    local lb = CreateFrame("Frame", "DTC_LeaderboardFrame", UIParent, "BackdropTemplate")
    local w, h = 900, 600; if DTCRaidDB.settings and DTCRaidDB.settings.lbSize then w, h = unpack(DTCRaidDB.settings.lbSize) end
    lb:SetSize(w, h); if DTCRaidDB.settings and DTCRaidDB.settings.lbPos then local p = DTCRaidDB.settings.lbPos; lb:SetPoint(p[1], UIParent, p[2], p[4], p[5]) else lb:SetPoint("CENTER") end
    lb:SetClampedToScreen(true); lb:SetMovable(true); lb:EnableMouse(true); lb:RegisterForDrag("LeftButton"); lb:SetResizable(true); lb:SetResizeBounds(600, 400, 1200, 900)
    lb:SetScript("OnDragStart", lb.StartMoving); lb:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); DTCRaidDB.settings.lbPos = {self:GetPoint()} end)
    lb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } }); lb:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    lb.title = lb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); lb.title:SetPoint("TOP", 0, -15); lb.title:SetText("DTC Leaderboard")
    local resizer = CreateFrame("Button", nil, lb); resizer:SetSize(16, 16); resizer:SetPoint("BOTTOMRIGHT", -10, 10); resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); resizer:SetScript("OnMouseDown", function() lb:StartSizing("BOTTOMRIGHT") end); resizer:SetScript("OnMouseUp", function() lb:StopMovingOrSizing(); DTCRaidDB.settings.lbSize = {lb:GetWidth(), lb:GetHeight()} end)

    local ddTime = CreateFrame("Frame", "DTC_TimeDD", lb, "UIDropDownMenuTemplate"); ddTime:SetPoint("TOPLEFT", -5, -40); UIDropDownMenu_SetWidth(ddTime, 110); UIDropDownMenu_Initialize(ddTime, DTC_InitTimeMenu); UIDropDownMenu_SetText(ddTime, "All Time"); lb.ddTime = ddTime
    local ddExp = CreateFrame("Frame", "DTC_ExpDD", lb, "UIDropDownMenuTemplate"); ddExp:SetPoint("LEFT", ddTime, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddExp, 160); UIDropDownMenu_Initialize(ddExp, DTC_InitExpMenu); UIDropDownMenu_SetText(ddExp, "Expansion"); lb.ddExp = ddExp
    local ddRaid = CreateFrame("Frame", "DTC_RaidDD", lb, "UIDropDownMenuTemplate"); ddRaid:SetPoint("LEFT", ddExp, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddRaid, 160); UIDropDownMenu_Initialize(ddRaid, DTC_InitRaidMenu); UIDropDownMenu_SetText(ddRaid, "Raid"); lb.ddRaid = ddRaid
    local ddBoss = CreateFrame("Frame", "DTC_BossDD", lb, "UIDropDownMenuTemplate"); ddBoss:SetPoint("LEFT", ddRaid, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddBoss, 160); UIDropDownMenu_Initialize(ddBoss, DTC_InitBossMenu); UIDropDownMenu_SetText(ddBoss, "Boss"); lb.ddBoss = ddBoss
    local ddDiff = CreateFrame("Frame", "DTC_DiffDD", lb, "UIDropDownMenuTemplate"); ddDiff:SetPoint("LEFT", ddBoss, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddDiff, 110); UIDropDownMenu_Initialize(ddDiff, DTC_InitDiffMenu); UIDropDownMenu_SetText(ddDiff, "Difficulty"); lb.ddDiff = ddDiff

    lb.viewToggle = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.viewToggle:SetSize(120, 22); lb.viewToggle:SetPoint("TOPRIGHT", -20, -45); lb.viewToggle:SetText("View: NICKNAMES")
    lb.viewToggle:SetScript("OnClick", function() viewMode = (viewMode == "NICK") and "CHAR" or "NICK"; lb.viewToggle:SetText("View: " .. (viewMode == "NICK" and "NICKNAMES" or "CHARACTERS")); DTC_RefreshLeaderboard() end)

    local sf = CreateFrame("ScrollFrame", nil, lb, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 15, -80); sf:SetPoint("BOTTOMRIGHT", -30, 50)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 1); sf:SetScrollChild(content); lb.content = content

    lb.configBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.configBtn:SetSize(90, 22); lb.configBtn:SetPoint("BOTTOMLEFT", 15, 15); lb.configBtn:SetText("Config IDs"); lb.configBtn:SetScript("OnClick", function() if Settings and Settings.OpenToCategory then Settings.OpenToCategory(DTC_OptionsCategoryID) else InterfaceOptionsFrame_OpenToCategory("DTC Raid Tracker") end end); lb.configBtn:Hide()
    lb.announceBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.announceBtn:SetSize(90, 22); lb.announceBtn:SetPoint("BOTTOMLEFT", 15, 15); lb.announceBtn:SetText("Announce"); 
    lb.announceBtn:SetScript("OnClick", function() 
        local data = DTC_GetSortedData()
        local t = (selBoss~="ALL" and selBoss) or (selRaid~="ALL" and selRaid) or (selExp~="ALL" and EXPANSION_NAMES[tonumber(selExp)]) or "All Time"
        if selTime == "TODAY" then t = t .. " (Today)" end
        SendChatMessage("--- DTC: " .. t .. " [" .. viewMode .. "] ---", "RAID")
        for i=1, math.min(10, #data) do local dName = DTC_GetAnnounceName(data[i].n); SendChatMessage(i .. ". " .. dName .. ": " .. data[i].v, "RAID") end 
    end)
    lb.awardBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.awardBtn:SetSize(100, 22); lb.awardBtn:SetPoint("LEFT", lb.announceBtn, "RIGHT", 5, 0); lb.awardBtn:SetText("Award Trip"); 
    lb.awardBtn:SetScript("OnClick", function() 
        local data = DTC_GetSortedData()
        if #data > 0 then 
            local winnerName = data[1].n
            DTCRaidDB.trips[winnerName] = (DTCRaidDB.trips[winnerName] or 0) + 1
            SendChatMessage("--- DTC DISNEY TRIP AWARD ---", "RAID")
            local msg = DTCRaidDB.settings.awardMsg:format(DTC_GetAnnounceName(winnerName))
            SendChatMessage(msg, "RAID")
            C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:TRIP,"..winnerName..","..DTCRaidDB.trips[winnerName], "RAID")
            DTC_RefreshLeaderboard() 
        else print("|cFFFF0000DTC:|r No votes found to award.") end 
    end)
    lb.histBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.histBtn:SetSize(80, 22); lb.histBtn:SetPoint("TOPLEFT", lb.configBtn, "BOTTOMLEFT", 0, -2); lb.histBtn:SetText("History"); lb.histBtn:SetScript("OnClick", function() DTC_CreateHistoryUI(); if DTC_HistoryFrame:IsShown() then DTC_HistoryFrame:Hide() else DTC_RefreshHistory(); DTC_HistoryFrame:Show() end end)
    lb.exportBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.exportBtn:SetSize(100, 22); lb.exportBtn:SetPoint("BOTTOMLEFT", 495, 15); lb.exportBtn:SetText("Export CSV"); lb.exportBtn:SetScript("OnClick", function() local exportBuffer = { "Date,Raid,Boss,Winner,Points" }; for _, h in ipairs(DTCRaidDB.history) do table.insert(exportBuffer, string.format("%s,%s,%s,%s,%d", h.d, h.r or "?", h.b, h.w, h.p)) end; local str = table.concat(exportBuffer, "\n"); local eb = CreateFrame("EditBox", nil, lb, "InputBoxTemplate"); eb:SetSize(570, 30); eb:SetPoint("BOTTOM", 0, -35); eb:SetText(str); eb:HighlightText(); eb:SetFocus() end)
    lb.closeBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.closeBtn:SetSize(60, 22); lb.closeBtn:SetPoint("BOTTOMRIGHT", -30, 15); lb.closeBtn:SetText("Close"); lb.closeBtn:SetScript("OnClick", function() lb:Hide() end)
    lb:Hide()
end

function DTC_RefreshHistory()
    if not DTC_HistoryFrame then return end
    local content = DTC_HistoryFrame.content
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    
    local filtered = {}
    for _, h in ipairs(DTCRaidDB.history) do
        local pass = true
        if hSelDate ~= "ALL" and h.d ~= hSelDate then pass = false end
        if hSelName ~= "ALL" and h.w ~= hSelName then pass = false end
        if pass then table.insert(filtered, h) end
    end

    local yOffset = 0
    for _, h in ipairs(filtered) do
        local row = CreateFrame("Frame", nil, content); row:SetSize(800, 20); row:SetPoint("TOPLEFT", 0, yOffset)
        local tDate = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); tDate:SetPoint("LEFT", 0, 0); tDate:SetWidth(80); tDate:SetJustifyH("LEFT"); tDate:SetText(h.d)
        local tRaid = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); tRaid:SetPoint("LEFT", 85, 0); tRaid:SetWidth(130); tRaid:SetJustifyH("LEFT"); tRaid:SetText(h.r)
        local diffText = h.diff or ""
        local tDiff = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); tDiff:SetPoint("LEFT", 220, 0); tDiff:SetWidth(80); tDiff:SetJustifyH("LEFT"); tDiff:SetText(diffText)
        local tBoss = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); tBoss:SetPoint("LEFT", 305, 0); tBoss:SetWidth(130); tBoss:SetJustifyH("LEFT"); tBoss:SetText(h.b)
        local champName = h.w; if DTCRaidDB.identities[h.w] then champName = h.w .. " ("..DTCRaidDB.identities[h.w]..")" end
        local tChamp = row:CreateFontString(nil, "OVERLAY", "GameFontNormal"); tChamp:SetPoint("LEFT", 440, 0); tChamp:SetWidth(100); tChamp:SetJustifyH("LEFT"); tChamp:SetText(champName)
        local tVoters = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); tVoters:SetPoint("LEFT", 550, 0); tVoters:SetJustifyH("LEFT"); tVoters:SetText(h.v or "None")
        yOffset = yOffset - 20
    end
end

function DTC_CreateHistoryUI()
    if DTC_HistoryFrame then return end
    local hf = CreateFrame("Frame", "DTC_HistoryFrame", UIParent, "BackdropTemplate")
    local w, h = 900, 500
    if DTCRaidDB.settings and DTCRaidDB.settings.histSize then w, h = unpack(DTCRaidDB.settings.histSize) end
    hf:SetSize(w, h); if DTCRaidDB.settings and DTCRaidDB.settings.histPos then local p = DTCRaidDB.settings.histPos; hf:SetPoint(p[1], UIParent, p[2], p[4], p[5]) else hf:SetPoint("CENTER") end
    hf:SetClampedToScreen(true); hf:SetMovable(true); hf:EnableMouse(true); hf:RegisterForDrag("LeftButton"); hf:SetResizable(true); hf:SetResizeBounds(600, 300, 1200, 800)
    hf:SetScript("OnDragStart", hf.StartMoving); hf:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); DTCRaidDB.settings.histPos = {self:GetPoint()} end)
    hf:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } }); hf:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    local title = hf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -15); title:SetText("DTC Voting History")
    local resizer = CreateFrame("Button", nil, hf); resizer:SetSize(16, 16); resizer:SetPoint("BOTTOMRIGHT", -10, 10); resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); resizer:SetScript("OnMouseDown", function() hf:StartSizing("BOTTOMRIGHT") end); resizer:SetScript("OnMouseUp", function() hf:StopMovingOrSizing(); DTCRaidDB.settings.histSize = {hf:GetWidth(), hf:GetHeight()} end)

    local ddDate = CreateFrame("Frame", "DTC_HDateDD", hf, "UIDropDownMenuTemplate"); ddDate:SetPoint("TOPLEFT", -5, -40); UIDropDownMenu_SetWidth(ddDate, 120); UIDropDownMenu_Initialize(ddDate, DTC_InitHDateMenu); UIDropDownMenu_SetText(ddDate, "Date"); hf.ddDate = ddDate
    local ddName = CreateFrame("Frame", "DTC_HNameDD", hf, "UIDropDownMenuTemplate"); ddName:SetPoint("LEFT", ddDate, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddName, 120); UIDropDownMenu_Initialize(ddName, DTC_InitHNameMenu); UIDropDownMenu_SetText(ddName, "Name"); hf.ddName = ddName

    local hDate = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hDate:SetPoint("TOPLEFT", 20, -75); hDate:SetText("Date")
    local hRaid = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hRaid:SetPoint("LEFT", hDate, "RIGHT", 50, 0); hRaid:SetText("Raid")
    local hDiff = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hDiff:SetPoint("LEFT", hRaid, "RIGHT", 105, 0); hDiff:SetText("Diff")
    local hBoss = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hBoss:SetPoint("LEFT", hDiff, "RIGHT", 55, 0); hBoss:SetText("Boss")
    local hName = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hName:SetPoint("LEFT", hBoss, "RIGHT", 100, 0); hName:SetText("Name")
    local hVote = hf:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); hVote:SetPoint("LEFT", hName, "RIGHT", 70, 0); hVote:SetText("Voters")

    local sf = CreateFrame("ScrollFrame", nil, hf, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 20, -95); sf:SetPoint("BOTTOMRIGHT", -30, 50)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(800, 1); sf:SetScrollChild(content); hf.content = content

    local closeBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate"); closeBtn:SetSize(80, 25); closeBtn:SetPoint("BOTTOMRIGHT", -20, 15); closeBtn:SetText("Close"); closeBtn:SetScript("OnClick", function() hf:Hide() end)
    local exportBtn = CreateFrame("Button", nil, hf, "UIPanelButtonTemplate"); exportBtn:SetSize(100, 25); exportBtn:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0); exportBtn:SetText("Export CSV"); exportBtn:SetScript("OnClick", function() local exportBuffer = { "Date,Raid,Diff,Boss,Name,Points,Voters" }; for _, h in ipairs(DTCRaidDB.history) do table.insert(exportBuffer, string.format("%s,%s,%s,%s,%s,%d,%s", h.d, h.r, h.diff or "", h.b, h.w, h.p, h.v or "")) end; local str = table.concat(exportBuffer, "\n"); local eb = CreateFrame("EditBox", nil, hf, "InputBoxTemplate"); eb:SetSize(600, 30); eb:SetPoint("BOTTOM", 0, -10); eb:SetText(str); eb:HighlightText(); eb:SetFocus() end)
    hf:Hide()
end

-- Init Menus (Required for Dropdowns)
function DTC_SelectTime(self) selTime=self.arg1; selExp="ALL"; selRaid="ALL"; selBoss="ALL"; selDiff="ALL"; UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddTime, self.value); DTC_RefreshLeaderboard(); CloseDropDownMenus() end
function DTC_SelectExp(self) selExp=self.arg1; selRaid="ALL"; selBoss="ALL"; selDiff="ALL"; UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddExp, self.value); DTC_RefreshLeaderboard(); CloseDropDownMenus() end
function DTC_SelectRaid(self) selRaid=self.arg1; selBoss="ALL"; selDiff="ALL"; UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, self.value); DTC_RefreshLeaderboard(); CloseDropDownMenus() end
function DTC_SelectBoss(self) selBoss=self.arg1; UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, self.value); DTC_RefreshLeaderboard(); CloseDropDownMenus() end
function DTC_SelectDiff(self) selDiff=self.arg1; UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddDiff, self.value); DTC_RefreshLeaderboard(); CloseDropDownMenus() end
function DTC_SelectHDate(self) hSelDate=self.arg1; hSelName="ALL"; UIDropDownMenu_SetText(DTC_HistoryFrame.ddDate, (self.arg1=="ALL") and "Date" or self.arg1); UIDropDownMenu_SetText(DTC_HistoryFrame.ddName, "Name"); DTC_RefreshHistory(); CloseDropDownMenus() end
function DTC_SelectHName(self) hSelName=self.arg1; UIDropDownMenu_SetText(DTC_HistoryFrame.ddName, (self.arg1=="ALL") and "Name" or self.arg1); DTC_RefreshHistory(); CloseDropDownMenus() end

function DTC_InitTimeMenu(self, level) local i=UIDropDownMenu_CreateInfo(); i.text="All Time"; i.arg1="ALL"; i.value="All Time"; i.func=DTC_SelectTime; i.checked=(selTime=="ALL"); UIDropDownMenu_AddButton(i, level); i.text="Today"; i.arg1="TODAY"; i.value="Today"; i.func=DTC_SelectTime; i.checked=(selTime=="TODAY"); UIDropDownMenu_AddButton(i, level); i.text="Trips Won"; i.arg1="TRIPS"; i.value="Trips Won"; i.func=DTC_SelectTime; i.checked=(selTime=="TRIPS"); UIDropDownMenu_AddButton(i, level) end
function DTC_InitExpMenu(self, level) local i=UIDropDownMenu_CreateInfo(); i.text="None"; i.arg1="ALL"; i.value="Expansion"; i.func=DTC_SelectExp; i.checked=(selExp=="ALL"); UIDropDownMenu_AddButton(i, level); for x=11,0,-1 do i.text=EXPANSION_NAMES[x]; i.arg1=tostring(x); i.value=EXPANSION_NAMES[x]; i.func=DTC_SelectExp; i.checked=(selExp==tostring(x)); UIDropDownMenu_AddButton(i, level) end end
function DTC_InitRaidMenu(self, level) local i=UIDropDownMenu_CreateInfo(); if selExp=="ALL" then i.text="Select Exp"; i.disabled=true; UIDropDownMenu_AddButton(i, level); return end; i.text="None"; i.arg1="ALL"; i.value="Raid"; i.func=DTC_SelectRaid; i.checked=(selRaid=="ALL"); UIDropDownMenu_AddButton(i, level); if STATIC_DATA[tonumber(selExp)] then local rs={}; for k,_ in pairs(STATIC_DATA[tonumber(selExp)]) do table.insert(rs,k) end; table.sort(rs); for _,r in ipairs(rs) do i.text=r; i.arg1=r; i.value=r; i.func=DTC_SelectRaid; i.checked=(selRaid==r); UIDropDownMenu_AddButton(i, level) end end end
function DTC_InitBossMenu(self, level) local i=UIDropDownMenu_CreateInfo(); if selRaid=="ALL" then i.text="Select Raid"; i.disabled=true; UIDropDownMenu_AddButton(i, level); return end; i.text="None"; i.arg1="ALL"; i.value="Boss"; i.func=DTC_SelectBoss; i.checked=(selBoss=="ALL"); UIDropDownMenu_AddButton(i, level); if STATIC_DATA[tonumber(selExp)] and STATIC_DATA[tonumber(selExp)][selRaid] then for _,b in ipairs(STATIC_DATA[tonumber(selExp)][selRaid]) do i.text=b; i.arg1=b; i.value=b; i.func=DTC_SelectBoss; i.checked=(selBoss==b); UIDropDownMenu_AddButton(i, level) end end end
function DTC_InitDiffMenu(self, level) local i=UIDropDownMenu_CreateInfo(); if selRaid=="ALL" then i.text="Select Raid"; i.disabled=true; UIDropDownMenu_AddButton(i, level); return end; i.text="All Diffs"; i.arg1="ALL"; i.value="Difficulty"; i.func=DTC_SelectDiff; i.checked=(selDiff=="ALL"); UIDropDownMenu_AddButton(i, level); local ds=EXP_DIFFICULTIES[tonumber(selExp)] or EXP_DIFFICULTIES["DEFAULT"]; for _,d in ipairs(ds) do i.text=d; i.arg1=d; i.value=d; i.func=DTC_SelectDiff; i.checked=(selDiff==d); UIDropDownMenu_AddButton(i, level) end end
function DTC_InitHDateMenu(self, level) local i=UIDropDownMenu_CreateInfo(); i.text="All Dates"; i.arg1="ALL"; i.func=DTC_SelectHDate; i.checked=(hSelDate=="ALL"); UIDropDownMenu_AddButton(i, level); local seen={}; local list={}; for _,h in ipairs(DTCRaidDB.history) do if not seen[h.d] then seen[h.d]=true; table.insert(list,h.d) end end; table.sort(list, function(a,b) return a>b end); for _,d in ipairs(list) do i.text=d; i.arg1=d; i.func=DTC_SelectHDate; i.checked=(hSelDate==d); UIDropDownMenu_AddButton(i, level) end end
function DTC_InitHNameMenu(self, level) local i=UIDropDownMenu_CreateInfo(); i.text="All Names"; i.arg1="ALL"; i.func=DTC_SelectHName; i.checked=(hSelName=="ALL"); UIDropDownMenu_AddButton(i, level); local seen={}; local list={}; for _,h in ipairs(DTCRaidDB.history) do if not seen[h.w] then seen[h.w]=true; table.insert(list,h.w) end end; table.sort(list); for _,n in ipairs(list) do i.text=n; i.arg1=n; i.func=DTC_SelectHName; i.checked=(hSelName==n); UIDropDownMenu_AddButton(i, level) end end

-- 8. SLASH COMMANDS
SLASH_DTC1 = "/dtc"
SlashCmdList["DTC"] = function(msg)
    local cmd = msg:match("^(%S*)"):lower()
    if cmd == "vote" then 
        DTC_OpenVotingWindow()
    elseif cmd == "lb" then 
        DTC_CreateLeaderboardUI()
        if DTC_LeaderboardFrame:IsShown() then 
            DTC_LeaderboardFrame:Hide() 
        else 
            DTC_RefreshLeaderboard()
            DTC_LeaderboardFrame:Show() 
        end
    elseif cmd == "config" then 
        if Settings and Settings.OpenToCategory then 
            Settings.OpenToCategory(DTC_OptionsCategoryID) 
        else 
            InterfaceOptionsFrame_OpenToCategory("DTC Raid Tracker") 
        end
    elseif cmd == "history" then 
        DTC_CreateHistoryUI()
        if DTC_HistoryFrame:IsShown() then 
            DTC_HistoryFrame:Hide() 
        else 
            DTC_RefreshHistory()
            DTC_HistoryFrame:Show() 
        end
    elseif cmd == "reset" then 
        StaticPopup_Show("DTC_SELF_RESET_CONFIRM")
    elseif cmd == "ver" then 
        print("|cFFFFD700DTC:|r Version: " .. DTC_VERSION)
    else 
        print("|cFFFFD700DTC Commands:|r")
        print("  |cFF00FF00/dtc vote|r - Toggle Voting")
        print("  |cFF00FF00/dtc lb|r - Toggle Leaderboard")
        print("  |cFF00FF00/dtc history|r - Open History")
        print("  |cFF00FF00/dtc config|r - Options")
        print("  |cFF00FF00/dtc reset|r - Reset local data")
    end
end

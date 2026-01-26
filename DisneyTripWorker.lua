-- 1. INITIALIZATION
local DTC_VERSION = "4.15.1" -- Updated Default Msg
local DTC_PREFIX = "DTCTRACKER"
local f = CreateFrame("Frame")
local isBossFight = false
local currentVotes = {} 
local currentVoters = {} 
local myVotesLeft = 3
local viewMode = "NICK" 
local lastBossName = "No Recent Boss"
local votingOpen = false 
local isTestMode = false 

-- Selection State (Leaderboard)
local selTime = "ALL"
local selExp = "ALL"
local selRaid = "ALL"
local selBoss = "ALL"
local selDiff = "ALL" 

-- Selection State (History)
local hSelDate = "ALL"
local hSelName = "ALL" 

-- CONSTANTS
local EXPANSION_NAMES = {
    [0]="Classic", [1]="Burning Crusade", [2]="Wrath of the Lich King", 
    [3]="Cataclysm", [4]="Mists of Pandaria", [5]="Warlords of Draenor", 
    [6]="Legion", [7]="Battle for Azeroth", [8]="Shadowlands", 
    [9]="Dragonflight", [10]="The War Within", [11]="Midnight"
}

-- Difficulty Map
local EXP_DIFFICULTIES = {
    [0] = {"Normal"},
    [1] = {"Normal"},
    [2] = {"Normal", "Heroic"}, 
    ["DEFAULT"] = {"LFR", "Normal", "Heroic", "Mythic"}
}

-- STATIC DATA
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

function DTC_GetAnnounceName(name)
    -- This handles the "Name Format" logic
    local nick = DTCRaidDB.identities[name]
    local fmt = DTCRaidDB.settings.announceFormat or "BOTH"
    
    if not nick then return name end
    
    if fmt == "CHAR" then return name
    elseif fmt == "NICK" then return nick
    else return name .. " (" .. nick .. ")" end
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
            
            -- Defaults
            DTCRaidDB.settings.awardMsg = DTCRaidDB.settings.awardMsg or "CONGRATULATIONS %s! You have won an all expenses paid trip to Disney World!"
            DTCRaidDB.settings.announceFormat = DTCRaidDB.settings.announceFormat or "BOTH"
            
            DTC_InitOptionsPanel()
            
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
        if DTC_HistoryFrame then
            DTCRaidDB.settings.histPos = {DTC_HistoryFrame:GetPoint()}
            DTCRaidDB.settings.histSize = {DTC_HistoryFrame:GetWidth(), DTC_HistoryFrame:GetHeight()}
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, sender = ...
        if prefix == DTC_PREFIX then DTC_HandleComm(msg, sender) end
    elseif event == "ENCOUNTER_END" then
        local _, encounterName, _, _, success = ...
        if success == 1 then
            lastBossName = encounterName
            votingOpen = true 
            isTestMode = false
            currentVotes = {}
            currentVoters = {} 
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
            currentVoters[data] = currentVoters[data] or {}
            table.insert(currentVoters[data], sender)
            if DTC_MainFrame and DTC_MainFrame:IsShown() then DTC_RefreshVotingList() end
        end
    elseif action == "FINALIZE" then
        local target, points, boss, raidName, dateStr, diffName = strsplit(",", data)
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

        local votersList = ""
        if currentVoters[target] then votersList = table.concat(currentVoters[target], ", ") end

        table.insert(DTCRaidDB.history, 1, {b = boss, w = target, p = points, d = dateStr, r = raidName, v = votersList, diff = diffName})
        if #DTCRaidDB.history > 2000 then table.remove(DTCRaidDB.history) end

        votingOpen = false
        if DTC_MainFrame and DTC_MainFrame:IsShown() then
            DTC_MainFrame.title:SetText("Results: " .. (lastBossName or "Boss"))
            DTC_RefreshVotingList()
        end
        if DTC_HistoryFrame and DTC_HistoryFrame:IsShown() then DTC_RefreshHistory() end
        
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
        if DTC_HistoryFrame and DTC_HistoryFrame:IsShown() then DTC_RefreshHistory() end
        print("|cFFFFD700DTC:|r Sync complete.")
    end
end

function DTC_ProcessSyncChunk(data)
    local type, p1, p2, p3, p4, p5, p6 = strsplit(",", data)
    if type == "GLOB" then DTCRaidDB.global[p1] = tonumber(p2)
    elseif type == "RAID" then DTCRaidDB.raids[p1] = DTCRaidDB.raids[p1] or {}; DTCRaidDB.raids[p1][p2] = tonumber(p3)
    elseif type == "BOSS" then DTCRaidDB.bosses[p1] = DTCRaidDB.bosses[p1] or {}; DTCRaidDB.bosses[p1][p2] = tonumber(p3)
    elseif type == "ID" then DTCRaidDB.identities[p1] = p2
    elseif type == "TRIP" then DTCRaidDB.trips[p1] = tonumber(p2)
    elseif type == "HIST" then 
        table.insert(DTCRaidDB.history, {b=p1, w=p2, p=tonumber(p3), d=p4, r=p5, diff=p6}) 
    end
end

-- 4. VOTING UI (Popup)
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
        votingOpen = false; DTC_RefreshVotingList()
    end)

    frame.announceBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.announceBtn:SetSize(110, 25); frame.announceBtn:SetPoint("BOTTOMLEFT", 130, 15); frame.announceBtn:SetText("Announce")
    frame.announceBtn:SetScript("OnClick", function()
        if isTestMode then print("|cFFFFD700DTC:|r Test Announcement: Results printed locally."); return end
        local sorted = {}; for p, v in pairs(currentVotes) do if not p:find("_VOTED_BY_ME") and v > 0 then table.insert(sorted, {n=p, v=v}) end end
        table.sort(sorted, function(a,b) return a.v > b.v end)
        SendChatMessage("--- DTC Results: " .. lastBossName .. " ---", "RAID")
        for i=1, math.min(3, #sorted) do 
            local dName = DTC_GetAnnounceName(sorted[i].n)
            SendChatMessage(i .. ". " .. dName .. " (" .. sorted[i].v .. " pts)", "RAID") 
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

    local list = {}
    if isTestMode then
        list = { {name="TestMage", class="MAGE"}, {name="TestWarrior", class="WARRIOR"}, {name="TestPriest", class="PRIEST"} }
    else
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, classFileName = GetRaidRosterInfo(i)
            if name then table.insert(list, {name=name, class=classFileName}) end
        end
    end

    for i, p in ipairs(list) do
        local name = p.name
        local row = CreateFrame("Frame", nil, content); row:SetSize(300, 30); row:SetPoint("TOPLEFT", 0, -(i-1)*32)
        local nameTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); nameTxt:SetPoint("LEFT", 5, 0); 
        
        local color = p.class and RAID_CLASS_COLORS[p.class] or {r=1,g=1,b=1}
        nameTxt:SetTextColor(color.r, color.g, color.b)
        nameTxt:SetText(name)
        
        local nick = DTCRaidDB.identities[name]; if nick then nameTxt:SetText(name .. " |cFF88AAFF("..nick..")|r") end
        
        local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate"); btn:SetSize(60, 20); btn:SetPoint("RIGHT", -5, 0); btn:SetText("Vote")
        if not votingOpen or myVotesLeft == 0 or currentVotes[name.."_VOTED_BY_ME"] then btn:Disable() end
        btn:SetScript("OnClick", function()
            local pName = UnitName("player")
            currentVotes[name] = (currentVotes[name] or 0) + 1; myVotesLeft = myVotesLeft - 1; currentVotes[name.."_VOTED_BY_ME"] = true
            currentVoters[name] = currentVoters[name] or {}; table.insert(currentVoters[name], pName)
            if not isTestMode then C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VOTE:"..name, "RAID") end
            DTC_RefreshVotingList()
        end)
        local count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal"); count:SetPoint("RIGHT", -70, 0); count:SetText(currentVotes[name] or "0")
    end
    if votingOpen then DTC_MainFrame.votesLeftText:SetText("Votes Left: " .. myVotesLeft) else DTC_MainFrame.votesLeftText:SetText("|cFFFF0000VOTING LOCKED / READ ONLY|r") end
end

-- 5. CONFIG OPTIONS
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

function DTC_RefreshNickOptions(content)
    if not content then return end
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    
    local canEdit = UnitIsGroupLeader("player") or (not IsInGroup())
    local keys = {}; for k, _ in pairs(DTCRaidDB.identities) do table.insert(keys, k) end
    for i = 1, GetNumGroupMembers() do local name = GetRaidRosterInfo(i); if name and not DTCRaidDB.identities[name] then table.insert(keys, name) end end
    
    local seen = {}; local uniqueKeys = {}
    for _, k in ipairs(keys) do if not seen[k] then seen[k]=true; table.insert(uniqueKeys, k) end end
    table.sort(uniqueKeys)

    local classMap = {}
    for i = 1, GetNumGroupMembers() do local name, _, _, _, _, classFileName = GetRaidRosterInfo(i); if name then classMap[name] = classFileName end end

    local yOffset = 0
    for _, name in ipairs(uniqueKeys) do
        local row = CreateFrame("Frame", nil, content); row:SetSize(520, 24); row:SetPoint("TOPLEFT", 0, yOffset)
        local cFile = classMap[name] or "PRIEST"
        local color = RAID_CLASS_COLORS[cFile] or {r=0.6,g=0.6,b=0.6}
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); label:SetPoint("LEFT", 5, 0); label:SetWidth(150); label:SetJustifyH("LEFT"); label:SetText(name); label:SetTextColor(color.r, color.g, color.b)
        local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); eb:SetSize(200, 20); eb:SetPoint("LEFT", label, "RIGHT", 10, 0); eb:SetAutoFocus(false); eb:SetText(DTCRaidDB.identities[name] or ""); eb:SetEnabled(canEdit)
        if not canEdit then eb:SetTextColor(0.5, 0.5, 0.5) end
        local function Save() local txt = eb:GetText(); if txt == "" then DTCRaidDB.identities[name] = nil else DTCRaidDB.identities[name] = txt end end
        eb:SetScript("OnEnterPressed", function(self) Save(); self:ClearFocus() end); eb:SetScript("OnEditFocusLost", function(self) Save() end)
        yOffset = yOffset - 25
    end
end

-- CONFIGURATION DROPDOWN HELPERS
local function DTC_SelectConfigFormat(self)
    local arg1 = self.arg1
    if not arg1 then return end
    DTCRaidDB.settings.announceFormat = arg1
    UIDropDownMenu_SetText(DTC_OptionsAnnounceDD, self.value)
    CloseDropDownMenus()
end

function DTC_InitConfigFormatMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.func = DTC_SelectConfigFormat
    info.text = "Character Name"; info.arg1 = "CHAR"; info.value = "Character Name"; info.checked = (DTCRaidDB.settings.announceFormat == "CHAR"); UIDropDownMenu_AddButton(info, level)
    info.text = "Nickname"; info.arg1 = "NICK"; info.value = "Nickname"; info.checked = (DTCRaidDB.settings.announceFormat == "NICK"); UIDropDownMenu_AddButton(info, level)
    info.text = "Both (Char + Nick)"; arg1 = "BOTH"; info.value = "Both (Char + Nick)"; info.checked = (DTCRaidDB.settings.announceFormat == "BOTH"); UIDropDownMenu_AddButton(info, level)
end

function DTC_InitOptionsPanel()
    local panel = CreateFrame("Frame", "DTC_OptionsPanel", UIParent); panel.name = "DTC Raid Tracker"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText("DTC Raid Tracker")
    
    panel.Tabs = {}
    local tab1 = CreateFrame("Button", "DTC_OptTab1", panel, "PanelTopTabButtonTemplate"); tab1:SetID(1); tab1:SetText("General"); tab1:SetPoint("TOPLEFT", 20, -40)
    local tab2 = CreateFrame("Button", "DTC_OptTab2", panel, "PanelTopTabButtonTemplate"); tab2:SetID(2); tab2:SetText("Nicknames"); tab2:SetPoint("LEFT", tab1, "RIGHT", 5, 0)
    local tab3 = CreateFrame("Button", "DTC_OptTab3", panel, "PanelTopTabButtonTemplate"); tab3:SetID(3); tab3:SetText("Leaderboard"); tab3:SetPoint("LEFT", tab2, "RIGHT", 5, 0)
    
    tab1:SetFrameLevel(panel:GetFrameLevel() + 5)
    tab2:SetFrameLevel(panel:GetFrameLevel() + 5)
    tab3:SetFrameLevel(panel:GetFrameLevel() + 5)
    
    table.insert(panel.Tabs, tab1)
    table.insert(panel.Tabs, tab2)
    table.insert(panel.Tabs, tab3)
    panel.numTabs = 3
    
    local frameGen = CreateFrame("Frame", nil, panel); frameGen:SetSize(600, 500); frameGen:SetPoint("TOPLEFT", 20, -70) 
    local frameNick = CreateFrame("Frame", nil, panel); frameNick:SetSize(600, 500); frameNick:SetPoint("TOPLEFT", 20, -70); frameNick:Hide()
    local frameLB = CreateFrame("Frame", nil, panel); frameLB:SetSize(600, 500); frameLB:SetPoint("TOPLEFT", 20, -70); frameLB:Hide()
    
    local function UpdateTabs(id)
        PanelTemplates_SetTab(panel, id)
        frameGen:Hide(); frameNick:Hide(); frameLB:Hide()
        if id == 1 then frameGen:Show()
        elseif id == 2 then frameNick:Show(); DTC_RefreshNickOptions(frameNick.content)
        elseif id == 3 then frameLB:Show() end
    end
    
    tab1:SetScript("OnClick", function() UpdateTabs(1) end)
    tab2:SetScript("OnClick", function() UpdateTabs(2) end)
    tab3:SetScript("OnClick", function() UpdateTabs(3) end)
    UpdateTabs(1) 
    
    -- == GENERAL TAB ==
    local boxMain = CreateGroupBox(frameGen, "General Options", 580, 80); boxMain:SetPoint("TOPLEFT", 0, 0)
    local btnTest = CreateFrame("Button", nil, boxMain, "UIPanelButtonTemplate"); btnTest:SetSize(140, 24); btnTest:SetPoint("TOPLEFT", 15, -40); btnTest:SetText("Test Vote Window"); btnTest:SetScript("OnClick", function() isTestMode = true; votingOpen = true; lastBossName = "Test Boss"; currentVotes = {}; myVotesLeft = 3; DTC_OpenVotingWindow() end)
    local btnVer = CreateFrame("Button", nil, boxMain, "UIPanelButtonTemplate"); btnVer:SetSize(140, 24); btnVer:SetPoint("LEFT", btnTest, "RIGHT", 10, 0); btnVer:SetText("Version Check"); btnVer:SetScript("OnClick", function() C_ChatInfo.SendAddonMessage(DTC_PREFIX, "VER_QUERY", "RAID") end)
    local btnSync = CreateFrame("Button", nil, boxMain, "UIPanelButtonTemplate"); btnSync:SetSize(140, 24); btnSync:SetPoint("LEFT", btnVer, "RIGHT", 10, 0); btnSync:SetText("Broadcast Sync"); btnSync:SetScript("OnClick", function() DTC_BroadcastFullSync() end)
    
    -- == NICKNAME TAB ==
    local boxNick = CreateGroupBox(frameNick, "Roster Configuration", 580, 400); boxNick:SetPoint("TOPLEFT", 0, 0)
    local sf = CreateFrame("ScrollFrame", "DTC_NickScroll", boxNick, "UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT", 10, -35); sf:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 1); sf:SetScrollChild(content); frameNick.content = content

    -- == LEADERBOARD TAB ==
    local boxLB = CreateGroupBox(frameLB, "Leaderboard Options", 580, 80); boxLB:SetPoint("TOPLEFT", 0, 0)
    local btnSelfReset = CreateFrame("Button", nil, boxLB, "UIPanelButtonTemplate"); btnSelfReset:SetSize(140, 24); btnSelfReset:SetPoint("TOPLEFT", 15, -40); btnSelfReset:SetText("Reset Local Data"); btnSelfReset:SetScript("OnClick", function() StaticPopup_Show("DTC_SELF_RESET_CONFIRM") end)
    local btnReset = CreateFrame("Button", nil, boxLB, "UIPanelButtonTemplate"); btnReset:SetSize(160, 24); btnReset:SetPoint("LEFT", btnSelfReset, "RIGHT", 10, 0); btnReset:SetText("Reset Database (Leader)"); btnReset:SetScript("OnClick", function() if UnitIsGroupLeader("player") then StaticPopup_Show("DTC_RESET_CONFIRM") else print("|cFFFF0000DTC:|r Leader Only.") end end)

    -- Announce Format Box
    local boxAnn = CreateGroupBox(frameLB, "Announcement Options", 580, 80); boxAnn:SetPoint("TOPLEFT", boxLB, "BOTTOMLEFT", 0, -10)
    local lblAnn = boxAnn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lblAnn:SetPoint("TOPLEFT", 15, -30); lblAnn:SetText("Name Format:")
    
    local ddAnn = CreateFrame("Frame", "DTC_OptionsAnnounceDD", boxAnn, "UIDropDownMenuTemplate")
    ddAnn:SetPoint("LEFT", lblAnn, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(ddAnn, 160)
    UIDropDownMenu_Initialize(ddAnn, DTC_InitConfigFormatMenu)
    
    local initialText = "Both (Char + Nick)"
    if DTCRaidDB.settings.announceFormat == "CHAR" then initialText = "Character Name"
    elseif DTCRaidDB.settings.announceFormat == "NICK" then initialText = "Nickname" end
    UIDropDownMenu_SetText(ddAnn, initialText)

    -- Award Message Box
    local boxMsg = CreateGroupBox(frameLB, "Award Configuration", 580, 100); boxMsg:SetPoint("TOPLEFT", boxAnn, "BOTTOMLEFT", 0, -10)
    local lblMsg = boxMsg:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lblMsg:SetPoint("TOPLEFT", 15, -30); lblMsg:SetText("Winning Message (Use %s for Name):")
    
    local ebMsg = CreateFrame("EditBox", nil, boxMsg, "InputBoxTemplate")
    ebMsg:SetSize(540, 30); ebMsg:SetPoint("TOPLEFT", lblMsg, "BOTTOMLEFT", 0, -10); ebMsg:SetAutoFocus(false)
    ebMsg:SetText(DTCRaidDB.settings.awardMsg or "")
    ebMsg:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.awardMsg = self:GetText() end)
    ebMsg:SetScript("OnEnterPressed", function(self) DTCRaidDB.settings.awardMsg = self:GetText(); self:ClearFocus() end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "DTC Raid Tracker")
    Settings.RegisterAddOnCategory(category)
    DTC_OptionsCategoryID = category:GetID()
end

-- 6. HISTORY UI (RCLC Style & New Filters)
local function DTC_SelectHDate(self)
    local arg1 = self.arg1; if not arg1 then return end
    hSelDate = arg1; hSelName = "ALL"
    UIDropDownMenu_SetText(DTC_HistoryFrame.ddDate, (arg1=="ALL") and "Date" or arg1)
    UIDropDownMenu_SetText(DTC_HistoryFrame.ddName, "Name")
    DTC_RefreshHistory(); CloseDropDownMenus()
end
local function DTC_SelectHName(self)
    local arg1 = self.arg1; if not arg1 then return end
    hSelName = arg1
    UIDropDownMenu_SetText(DTC_HistoryFrame.ddName, (arg1=="ALL") and "Name" or arg1)
    DTC_RefreshHistory(); CloseDropDownMenus()
end

function DTC_InitHDateMenu(self, level)
    local info = UIDropDownMenu_CreateInfo(); info.text = "All Dates"; info.arg1 = "ALL"; info.func = DTC_SelectHDate; info.checked = (hSelDate == "ALL"); UIDropDownMenu_AddButton(info, level)
    
    local seen = {}; local list = {}
    for _, h in ipairs(DTCRaidDB.history) do
        if not seen[h.d] then seen[h.d]=true; table.insert(list, h.d) end
    end
    table.sort(list, function(a,b) return a > b end) -- Newest first
    for _, d in ipairs(list) do
        info.text = d; info.arg1 = d; info.func = DTC_SelectHDate; info.checked = (hSelDate == d); UIDropDownMenu_AddButton(info, level)
    end
end

function DTC_InitHNameMenu(self, level)
    local info = UIDropDownMenu_CreateInfo(); info.text = "All Names"; info.arg1 = "ALL"; info.func = DTC_SelectHName; info.checked = (hSelName == "ALL"); UIDropDownMenu_AddButton(info, level)
    
    local seen = {}; local list = {}
    for _, h in ipairs(DTCRaidDB.history) do
        if not seen[h.w] then seen[h.w]=true; table.insert(list, h.w) end
    end
    table.sort(list)
    for _, n in ipairs(list) do
        info.text = n; info.arg1 = n; info.func = DTC_SelectHName; info.checked = (hSelName == n); UIDropDownMenu_AddButton(info, level)
    end
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
    hf:SetSize(w, h)
    if DTCRaidDB.settings and DTCRaidDB.settings.histPos then local p = DTCRaidDB.settings.histPos; hf:SetPoint(p[1], UIParent, p[2], p[4], p[5]) else hf:SetPoint("CENTER") end
    hf:SetClampedToScreen(true); hf:SetMovable(true); hf:EnableMouse(true); hf:RegisterForDrag("LeftButton"); hf:SetResizable(true); hf:SetResizeBounds(600, 300, 1200, 800)
    hf:SetScript("OnDragStart", hf.StartMoving); hf:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); DTCRaidDB.settings.histPos = {self:GetPoint()} end)
    hf:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    hf:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    local title = hf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -15); title:SetText("DTC Voting History")
    local resizer = CreateFrame("Button", nil, hf); resizer:SetSize(16, 16); resizer:SetPoint("BOTTOMRIGHT", -10, 10); resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); resizer:SetScript("OnMouseDown", function() hf:StartSizing("BOTTOMRIGHT") end); resizer:SetScript("OnMouseUp", function() hf:StopMovingOrSizing(); DTCRaidDB.settings.histSize = {hf:GetWidth(), hf:GetHeight()} end)

    -- Filters (Date & Name Only)
    local ddDate = CreateFrame("Frame", "DTC_HDateDD", hf, "UIDropDownMenuTemplate"); ddDate:SetPoint("TOPLEFT", -5, -40); UIDropDownMenu_SetWidth(ddDate, 120); UIDropDownMenu_Initialize(ddDate, DTC_InitHDateMenu); UIDropDownMenu_SetText(ddDate, "Date"); hf.ddDate = ddDate
    local ddName = CreateFrame("Frame", "DTC_HNameDD", hf, "UIDropDownMenuTemplate"); ddName:SetPoint("LEFT", ddDate, "RIGHT", -20, 0); UIDropDownMenu_SetWidth(ddName, 120); UIDropDownMenu_Initialize(ddName, DTC_InitHNameMenu); UIDropDownMenu_SetText(ddName, "Name"); hf.ddName = ddName

    -- Headers
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

-- 7. LEADERBOARD UI
function DTC_SelectTime(self)
    local arg1 = self.arg1; if not arg1 then return end
    selTime = arg1; selExp = "ALL"; selRaid = "ALL"; selBoss = "ALL"; selDiff = "ALL"
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddTime, arg1 == "ALL" and "All Time" or (arg1 == "TODAY" and "Today" or "Trips Won"))
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddExp, "Expansion")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, "Raid")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, "Boss")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddDiff, "Difficulty")
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectExp(self)
    local arg1 = self.arg1; if not arg1 then return end
    selExp = arg1; selRaid = "ALL"; selBoss = "ALL"; selDiff = "ALL"
    local txt = (arg1 == "ALL") and "Expansion" or EXPANSION_NAMES[tonumber(arg1)]
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddExp, txt)
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, "Raid")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, "Boss")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddDiff, "Difficulty")
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectRaid(self)
    local arg1 = self.arg1; if not arg1 then return end
    selRaid = arg1; selBoss = "ALL"; selDiff = "ALL"
    local txt = (arg1 == "ALL") and "Raid" or arg1
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddRaid, txt)
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, "Boss")
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddDiff, "Difficulty")
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectBoss(self)
    local arg1 = self.arg1; if not arg1 then return end
    selBoss = arg1; local txt = (arg1 == "ALL") and "Boss" or arg1
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddBoss, txt)
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

local function DTC_SelectDiff(self)
    local arg1 = self.arg1; if not arg1 then return end
    selDiff = arg1; local txt = (arg1 == "ALL") and "Difficulty" or arg1
    UIDropDownMenu_SetText(DTC_LeaderboardFrame.ddDiff, txt)
    DTC_RefreshLeaderboard(); CloseDropDownMenus()
end

function DTC_InitTimeMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Time"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectTime; info.checked = (selTime == "ALL"); UIDropDownMenu_AddButton(info, level)
    info.text = "Today"; info.arg1 = "TODAY"; info.value = "TODAY"; info.func = DTC_SelectTime; info.checked = (selTime == "TODAY"); UIDropDownMenu_AddButton(info, level)
    info.text = "Trips Won"; info.arg1 = "TRIPS"; info.value = "TRIPS"; info.func = DTC_SelectTime; info.checked = (selTime == "TRIPS"); UIDropDownMenu_AddButton(info, level)
end

function DTC_InitExpMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "None"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectExp; info.checked = (selExp == "ALL"); UIDropDownMenu_AddButton(info, level)
    for i = 11, 0, -1 do info.text = EXPANSION_NAMES[i]; info.arg1 = tostring(i); info.value = tostring(i); info.func = DTC_SelectExp; info.checked = (selExp == tostring(i)); UIDropDownMenu_AddButton(info, level) end
end

function DTC_InitRaidMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    if selExp == "ALL" then info.text = "Select Expansion First"; info.notCheckable = true; info.disabled = true; UIDropDownMenu_AddButton(info, level) return end
    info.text = "None"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectRaid; info.checked = (selRaid == "ALL"); UIDropDownMenu_AddButton(info, level)
    if STATIC_DATA[tonumber(selExp)] then
        local rNames = {}
        for rName, _ in pairs(STATIC_DATA[tonumber(selExp)]) do table.insert(rNames, rName) end
        table.sort(rNames)
        for _, rName in ipairs(rNames) do info.text = rName; info.arg1 = rName; info.value = rName; info.func = DTC_SelectRaid; info.checked = (selRaid == rName); UIDropDownMenu_AddButton(info, level) end
    end
end

function DTC_InitBossMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    if selRaid == "ALL" then info.text = "Select Raid First"; info.notCheckable = true; info.disabled = true; UIDropDownMenu_AddButton(info, level) return end
    info.text = "None"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectBoss; info.checked = (selBoss == "ALL"); UIDropDownMenu_AddButton(info, level)
    if STATIC_DATA[tonumber(selExp)] and STATIC_DATA[tonumber(selExp)][selRaid] then
        for _, bName in ipairs(STATIC_DATA[tonumber(selExp)][selRaid]) do info.text = bName; info.arg1 = bName; info.value = bName; info.func = DTC_SelectBoss; info.checked = (selBoss == bName); UIDropDownMenu_AddButton(info, level) end
    end
end

function DTC_InitDiffMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    if selRaid == "ALL" then info.text = "Select Raid First"; info.notCheckable = true; info.disabled = true; UIDropDownMenu_AddButton(info, level) return end
    info.text = "All Diffs"; info.arg1 = "ALL"; info.value = "ALL"; info.func = DTC_SelectDiff; info.checked = (selDiff == "ALL"); UIDropDownMenu_AddButton(info, level)
    
    local diffs = EXP_DIFFICULTIES[tonumber(selExp)] or EXP_DIFFICULTIES["DEFAULT"]
    for _, d in ipairs(diffs) do
        info.text = d; info.arg1 = d; info.value = d; info.func = DTC_SelectDiff; info.checked = (selDiff == d); UIDropDownMenu_AddButton(info, level)
    end
end

function DTC_CreateLeaderboardUI()
    if DTC_LeaderboardFrame then return end
    local lb = CreateFrame("Frame", "DTC_LeaderboardFrame", UIParent, "BackdropTemplate")
    local w, h = 900, 600
    if DTCRaidDB.settings and DTCRaidDB.settings.lbSize then w, h = unpack(DTCRaidDB.settings.lbSize) end
    lb:SetSize(w, h)
    if DTCRaidDB.settings and DTCRaidDB.settings.lbPos then local p = DTCRaidDB.settings.lbPos; lb:SetPoint(p[1], UIParent, p[2], p[4], p[5]) else lb:SetPoint("CENTER") end
    lb:SetClampedToScreen(true); lb:SetMovable(true); lb:EnableMouse(true); lb:RegisterForDrag("LeftButton"); lb:SetResizable(true); lb:SetResizeBounds(600, 400, 1200, 900)
    lb:SetScript("OnDragStart", lb.StartMoving); lb:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); DTCRaidDB.settings.lbPos = {self:GetPoint()} end)
    lb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    lb:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
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

    lb.configBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.configBtn:SetSize(90, 22); lb.configBtn:SetPoint("BOTTOMLEFT", 15, 15); lb.configBtn:SetText("Config IDs"); lb.configBtn:SetScript("OnClick", function() if Settings and Settings.OpenToCategory then Settings.OpenToCategory(DTC_OptionsCategoryID) else InterfaceOptionsFrame_OpenToCategory("DTC Raid Tracker") end end)
    lb.configBtn:Hide()
    
    lb.announceBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.announceBtn:SetSize(90, 22); lb.announceBtn:SetPoint("BOTTOMLEFT", 15, 15); lb.announceBtn:SetText("Announce"); 
    lb.announceBtn:SetScript("OnClick", function() 
        local data = DTC_GetSortedData()
        local t = (selBoss~="ALL" and selBoss) or (selRaid~="ALL" and selRaid) or (selExp~="ALL" and EXPANSION_NAMES[tonumber(selExp)]) or "All Time"
        if selTime == "TODAY" then t = t .. " (Today)" end
        SendChatMessage("--- DTC: " .. t .. " [" .. viewMode .. "] ---", "RAID")
        for i=1, math.min(10, #data) do 
            local dName = DTC_GetAnnounceName(data[i].n)
            SendChatMessage(i .. ". " .. dName .. ": " .. data[i].v, "RAID") 
        end 
    end)
    
    lb.awardBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.awardBtn:SetSize(100, 22); lb.awardBtn:SetPoint("LEFT", lb.announceBtn, "RIGHT", 5, 0); lb.awardBtn:SetText("Award Trip"); 
    lb.awardBtn:SetScript("OnClick", function() 
        local data = DTC_GetSortedData()
        if #data > 0 then 
            local winnerName = data[1].n
            -- Award Logic
            DTCRaidDB.trips[winnerName] = (DTCRaidDB.trips[winnerName] or 0) + 1
            SendChatMessage("--- DTC DISNEY TRIP AWARD ---", "RAID")
            
            -- Format Message with Proper Name
            local dName = DTC_GetAnnounceName(winnerName)
            local msg = DTCRaidDB.settings.awardMsg:format(dName)
            SendChatMessage(msg, "RAID")
            
            C_ChatInfo.SendAddonMessage(DTC_PREFIX, "SYNC_DATA:TRIP,"..winnerName..","..DTCRaidDB.trips[winnerName], "RAID")
            DTC_RefreshLeaderboard() 
        else 
            print("|cFFFF0000DTC:|r No votes found to award.") 
        end 
    end)
    
    lb.closeBtn = CreateFrame("Button", nil, lb, "UIPanelButtonTemplate"); lb.closeBtn:SetSize(60, 22); lb.closeBtn:SetPoint("BOTTOMRIGHT", -30, 15); lb.closeBtn:SetText("Close"); lb.closeBtn:SetScript("OnClick", function() lb:Hide() end)
    lb:Hide()
end

function DTC_RefreshLeaderboard()
    DTC_CreateLeaderboardUI()
    local content = DTC_LeaderboardFrame.content
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    local isLeader = UnitIsGroupLeader("player")
    DTC_LeaderboardFrame.announceBtn:SetShown(isLeader)
    local isRaidLevel = (selExp ~= "ALL" and selRaid ~= "ALL" and selBoss == "ALL")
    DTC_LeaderboardFrame.awardBtn:SetShown(isLeader and isRaidLevel)
    
    if selExp == "ALL" then 
        UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddRaid); 
        UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddBoss);
        UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddDiff)
    else 
        UIDropDownMenu_EnableDropDown(DTC_LeaderboardFrame.ddRaid); 
        if selRaid == "ALL" then 
            UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddBoss)
            UIDropDownMenu_DisableDropDown(DTC_LeaderboardFrame.ddDiff)
        else 
            UIDropDownMenu_EnableDropDown(DTC_LeaderboardFrame.ddBoss)
            UIDropDownMenu_EnableDropDown(DTC_LeaderboardFrame.ddDiff)
        end 
    end

    local data = DTC_GetSortedData()
    for i, item in ipairs(data) do
        local row = CreateFrame("Frame", nil, content); row:SetSize(250, 20); row:SetPoint("TOPLEFT", 0, -(i-1)*22)
        local t = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("LEFT", 5, 0)
        t:SetText(item.n .. ": " .. item.v)
    end
end

function DTC_GetSortedData()
    if selTime == "TRIPS" then
        local displayData = {}; for p, v in pairs(DTCRaidDB.trips) do local key = p; if viewMode == "NICK" and DTCRaidDB.identities[p] then key = DTCRaidDB.identities[p] end; displayData[key] = (displayData[key] or 0) + v end
        local sorted = {}; for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end
        table.sort(sorted, function(a,b) return a.v > b.v end)
        return sorted
    end
    
    local rawData = {}
    
    -- HYBRID LOGIC
    if selTime == "ALL" and selDiff == "ALL" then
        if selExp == "ALL" then rawData = DTCRaidDB.global
        else
            if selRaid == "ALL" then local raidsInExp = STATIC_DATA[tonumber(selExp)] or {}; for rName, _ in pairs(raidsInExp) do if DTCRaidDB.raids[rName] then for p, v in pairs(DTCRaidDB.raids[rName]) do rawData[p] = (rawData[p] or 0) + v end end end
            else if selBoss == "ALL" then rawData = DTCRaidDB.raids[selRaid] or {} else rawData = DTCRaidDB.bosses[selBoss] or {} end end
        end
    else 
        local today = date("%Y-%m-%d")
        for _, h in ipairs(DTCRaidDB.history) do
            local pass = true
            if selTime == "TODAY" and h.d ~= today then pass = false end
            
            if selExp ~= "ALL" then 
                local raids = STATIC_DATA[tonumber(selExp)] or {}; 
                if not raids[h.r] then pass = false end 
            end
            
            if selRaid ~= "ALL" and h.r ~= selRaid then pass = false end
            if selBoss ~= "ALL" and h.b ~= selBoss then pass = false end
            if selDiff ~= "ALL" and h.diff ~= selDiff then pass = false end
            
            if pass then rawData[h.w] = (rawData[h.w] or 0) + h.p end
        end
    end
    
    local displayData = {}
    for charName, val in pairs(rawData) do 
        local key = charName
        if viewMode == "NICK" and DTCRaidDB.identities[charName] then key = DTCRaidDB.identities[charName] end
        displayData[key] = (displayData[key] or 0) + val 
    end
    
    -- MAC vs PINK LOGIC (Roster Check)
    local pinkInRaid = false
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name and DTCRaidDB.identities[name] == "Pink" then pinkInRaid = true; break end
        end
    else
        local name = UnitName("player"); if name and DTCRaidDB.identities[name] == "Pink" then pinkInRaid = true end
    end

    if pinkInRaid then
        local macScore = displayData["Mac"]
        local pinkScore = displayData["Pink"]
        if macScore and pinkScore then if macScore >= pinkScore then displayData["Mac"] = pinkScore - 1 end end
    end

    local sorted = {}; for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end
    table.sort(sorted, function(a,b) return a.v > b.v end)
    return sorted
end

-- 8. SLASH COMMANDS
SLASH_DTC1 = "/dtc"
SlashCmdList["DTC"] = function(msg)
    local cmd = msg:match("^(%S*)"):lower()
    if cmd == "vote" then 
        DTC_OpenVotingWindow()
    elseif cmd == "lb" then 
        DTC_CreateLeaderboardUI()
        if DTC_LeaderboardFrame:IsShown() then DTC_LeaderboardFrame:Hide() else DTC_RefreshLeaderboard(); DTC_LeaderboardFrame:Show() end
    elseif cmd == "config" then 
        if Settings and Settings.OpenToCategory then Settings.OpenToCategory(DTC_OptionsCategoryID) else InterfaceOptionsFrame_OpenToCategory("DTC Raid Tracker") end
    elseif cmd == "history" then 
        DTC_CreateHistoryUI(); if DTC_HistoryFrame:IsShown() then DTC_HistoryFrame:Hide() else DTC_RefreshHistory(); DTC_HistoryFrame:Show() end
    elseif cmd == "reset" then 
        StaticPopup_Show("DTC_SELF_RESET_CONFIRM")
    elseif cmd == "ver" then 
        print("|cFFFFD700DTC:|r Version: " .. DTC_VERSION)
    else
        print("|cFFFFD700DTC Commands:|r")
        print("  |cFF00FF00/dtc vote|r    - Toggle Voting")
        print("  |cFF00FF00/dtc lb|r      - Toggle Leaderboard")
        print("  |cFF00FF00/dtc history|r - Open History Log")
        print("  |cFF00FF00/dtc config|r  - Configure Nicknames")
        print("  |cFF00FF00/dtc reset|r   - Reset local data")
    end
end

local folderName, DTC = ...
_G["DTC_Global"] = DTC 

DTC.VERSION = "7.0.0"
DTC.PREFIX = "DTCTRACKER"

-- Global Test State
DTC.isTestModeLB = false
DTC.isTestModeHist = false

-- Static Popups
StaticPopupDialogs["DTC_RESET_CONFIRM"] = {
    text = "Reset ALL data? This cannot be undone.",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        local s = DTCRaidDB.settings or {}
        DTCRaidDB = { global={}, history={}, trips={}, identities={}, classes={}, settings=s }
        print("|cFFFFD700DTC:|r Database reset.")
        if DTC.LeaderboardUI then DTC.LeaderboardUI:UpdateList() end
        if DTC.HistoryUI then DTC.HistoryUI:UpdateList() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED"); 
f:RegisterEvent("PLAYER_LOGOUT"); 
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- Added to catch zoning into raids

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == folderName then
        DTC:InitDatabase()
        if DTC.Config and DTC.Config.Init then DTC.Config:Init() end
        C_ChatInfo.RegisterAddonMessagePrefix(DTC.PREFIX)
        f:RegisterEvent("CHAT_MSG_ADDON")
        print("|cFFFFD700DTC Tracker|r " .. DTC.VERSION .. " loaded.")
        
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, sender = ...
        if prefix == DTC.PREFIX then 
            local action, data = strsplit(":", msg, 2)
            if DTC.Vote then DTC.Vote:OnComm(action, data, sender) end
            if DTC.History then DTC.History:OnComm(action, data, sender) end
        end
        
    elseif event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" then
        DTC:CheckRosterForNicknames()
    end
end)

function DTC:InitDatabase()
    DTCRaidDB = DTCRaidDB or {}
    DTCRaidDB.global = DTCRaidDB.global or {}
    DTCRaidDB.history = DTCRaidDB.history or {}
    DTCRaidDB.trips = DTCRaidDB.trips or {}
    DTCRaidDB.identities = DTCRaidDB.identities or {}
    DTCRaidDB.classes = DTCRaidDB.classes or {}
    DTCRaidDB.settings = DTCRaidDB.settings or {}
    if DTCRaidDB.settings.voteSortMode == nil then DTCRaidDB.settings.voteSortMode = "ROLE" end
    if DTCRaidDB.settings.lbDetailMode == nil then DTCRaidDB.settings.lbDetailMode = "ALL" end
end

function DTC:ResetDatabase() StaticPopup_Show("DTC_RESET_CONFIRM") end

-- AUTO-POPULATE LOGIC
function DTC:CheckRosterForNicknames()
    if not IsInRaid() then return end
    
    -- 1. Validate Zone
    local name, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceType ~= "raid" then return end -- Must be a raid instance
    
    -- 2. Validate against our Supported Raid List
    -- (This prevents auto-adding from random legacy raids you might solo, if desired, 
    --  or keeps it strictly to the content DTC tracks)
    local isValidRaid = false
    if DTC.Static and DTC.Static.RAID_DATA then
        for expID, raidList in pairs(DTC.Static.RAID_DATA) do
            for _, rName in ipairs(raidList) do
                if rName == name then isValidRaid = true; break end
            end
            if isValidRaid then break end
        end
    end
    
    if not isValidRaid then return end

    -- 3. Populate
    for i = 1, GetNumGroupMembers() do
        local charName, _, _, _, _, classFile = GetRaidRosterInfo(i)
        if charName then
            -- Handle realm names (e.g. "Player-Realm" -> "Player") if you prefer defaults without realms
            -- charName = strsplit("-", charName) 
            
            -- If we don't know this person yet, set default nickname = name
            if not DTCRaidDB.identities[charName] then
                DTCRaidDB.identities[charName] = charName
                -- Optional: print("|cFF00FF00DTC:|r Added " .. charName .. " to database.")
            end
            
            -- Always keep class updated (useful if they changed chars but kept name, rare but possible)
            if classFile then
                DTCRaidDB.classes[charName] = classFile
            end
        end
    end
end

-- SLASH COMMANDS
SLASH_DTC1 = "/dtc"
SlashCmdList["DTC"] = function(msg)
    local cmd = msg:match("^(%S*)"):lower()
    
    if cmd == "vote" then
        if DTC.VoteFrame then DTC.VoteFrame:Toggle() end
    elseif cmd == "lb" then
        DTC.isTestModeLB = false
        if DTC.Leaderboard then DTC.Leaderboard:Toggle() end
    elseif cmd == "history" then
        DTC.isTestModeHist = false
        if DTC.History then DTC.History:Toggle() end
    elseif cmd == "config" then
        if Settings and Settings.OpenToCategory then Settings.OpenToCategory(DTC.OptionsCategoryID) 
        else InterfaceOptionsFrame_OpenToCategory("DTC Raid Tracker") end
    elseif cmd == "reset" then
        DTC:ResetDatabase()
    else
        print("|cFFFFD700DTC Commands:|r /dtc vote, /dtc lb, /dtc history, /dtc config, /dtc reset")
    end
end

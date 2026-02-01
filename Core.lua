-- ============================================================================
-- DTC Raid Tracker - Core.lua
-- ============================================================================
-- This file handles the addon initialization, event handling, database setup,
-- and core utility functions. It serves as the entry point for the addon.

local folderName, DTC = ...
_G["DTC_Global"] = DTC -- Expose DTC to global scope for debugging/external access

DTC.VERSION = "7.3.9"
DTC.PREFIX = "DTCTRACKER"

DTC.isTestModeLB = false
DTC.isTestModeHist = false
DTC.SessionActive = nil
DTC.SessionDecided = false

-- ============================================================================
-- STATIC POPUPS
-- ============================================================================
-- Definitions for confirmation dialogs used throughout the addon.

StaticPopupDialogs["DTC_RESET_CONFIRM"] = {
    text = "Reset ALL data? This cannot be undone.",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        local s = DTCRaidDB.settings or {}
        DTCRaidDB = { global={}, history={}, trips={}, identities={}, guilds={}, classes={}, bribes={}, settings=s }
        print("|cFFFFD700DTC:|r Database reset.")
        if DTC.LeaderboardUI then DTC.LeaderboardUI:UpdateList() end
        if DTC.HistoryUI then DTC.HistoryUI:UpdateList() end
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
        if DTC.Bribe then DTC.Bribe.ActiveTrade = nil end
        if DTC.Bribe and DTC.Bribe.DeclineAll then DTC.Bribe:DeclineAll() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_FORGIVE_CONFIRM"] = {
    text = "Are you sure you want to forgive this debt?",
    button1 = "Yes", button2 = "No",
    OnAccept = function(self, data)
        if DTC.Bribe then DTC.Bribe:ForgiveDebt(data) end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_MARKPAID_CONFIRM"] = {
    text = "Mark this debt as PAID? (No gold will be traded)",
    button1 = "Yes", button2 = "No",
    OnAccept = function(self, data)
        if DTC.Bribe then DTC.Bribe:MarkDebtPaid(data) end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_RESET_SETTINGS_CONFIRM"] = {
    text = "Reset all configuration settings to defaults?",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        DTCRaidDB.settings = {}
        DTC:InitDatabase()
        print("|cFFFFD700DTC:|r Settings reset to defaults.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_CLEAR_BRIBES_CONFIRM"] = {
    text = "Clear all bribe ledger entries? This cannot be undone.",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        DTCRaidDB.bribes = {}
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DTC_START_SESSION"] = {
    text = "Do you want to activate DTC Raid Tracker for this raid?",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        DTC.SessionActive = true
        DTC.SessionDecided = true
        DTC:SyncSessionStatus()
        print("|cFF00FF00DTC:|r Session started.")
    end,
    OnCancel = function()
        DTC.SessionActive = false
        DTC.SessionDecided = true
        DTC:SyncSessionStatus()
        print("|cFFFF0000DTC:|r Session disabled.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = false, preferredIndex = 3,
}

StaticPopupDialogs["DTC_FORCE_START_CONFIRM"] = {
    text = "Force start a new session? This will re-prompt everyone.",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        DTC.SessionDecided = false
        DTC:CheckSessionStart()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED"); 
f:RegisterEvent("PLAYER_LOGOUT"); 
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA") 
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("PLAYER_UNGHOST")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == folderName then
        -- Initialize database and modules when the addon is loaded
        DTC:InitDatabase()
        if DTC.Config and DTC.Config.Init then DTC.Config:Init() end
        C_ChatInfo.RegisterAddonMessagePrefix(DTC.PREFIX)
        f:RegisterEvent("CHAT_MSG_ADDON")
        print("|cFFFFD700DTC Tracker|r " .. DTC.VERSION .. " loaded.")
        DTC:CheckSessionStart()
        
    elseif event == "CHAT_MSG_ADDON" then
        -- Handle incoming addon communication messages
        local prefix, msg, _, sender = ...
        if prefix == DTC.PREFIX then 
            local action, data = strsplit(":", msg, 2)
            if DTC.Vote then DTC.Vote:OnComm(action, data, sender) end
            if DTC.History then DTC.History:OnComm(action, data, sender) end
            if DTC.Leaderboard then DTC.Leaderboard:OnComm(action, data, sender) end
            if DTC.Bribe then DTC.Bribe:OnComm(action, data, sender) end
            
            if action == "SESSION_QUERY" then
                if UnitIsGroupLeader("player") then 
                    DTC:SyncSessionStatus()
                    -- Sync critical settings to the new/reloading player
                    local s = DTCRaidDB.settings
                    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_VOTES:"..(s.votesPerPerson or 3), "RAID")
                    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_FEE:"..(s.corruptionFee or 10), "RAID")
                    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_LIMIT:"..(s.debtLimit or 0), "RAID")
                end
            elseif action == "SESSION_STATUS" then
                DTC.SessionActive = (data == "1")
            end
        end
        
    elseif event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        -- Update roster data and UI lists when group composition or zone changes
        DTC:CheckRosterForNicknames()
        DTC:CheckSessionStart()
        if DTC.VoteFrame and DTC.VoteFrame.UpdateList then DTC.VoteFrame:UpdateList() end
        if DTC.LeaderboardUI and DTC.LeaderboardUI.UpdateList then DTC.LeaderboardUI:UpdateList() end
        if DTC.BribeUI and DTC.BribeUI.UpdateTracker then DTC.BribeUI:UpdateTracker() end
    end
end)

-- ============================================================================
-- DATABASE INITIALIZATION
-- ============================================================================

-- Initializes the SavedVariables table (DTCRaidDB) with default values.
function DTC:InitDatabase()
    DTCRaidDB = DTCRaidDB or {}
    DTCRaidDB.global = DTCRaidDB.global or {}
    DTCRaidDB.history = DTCRaidDB.history or {}
    DTCRaidDB.trips = DTCRaidDB.trips or {}
    DTCRaidDB.identities = DTCRaidDB.identities or {}
    DTCRaidDB.guilds = DTCRaidDB.guilds or {}
    DTCRaidDB.classes = DTCRaidDB.classes or {}
    DTCRaidDB.bribes = DTCRaidDB.bribes or {} 
    DTCRaidDB.settings = DTCRaidDB.settings or {}
    
    if DTCRaidDB.settings.voteSortMode == nil then DTCRaidDB.settings.voteSortMode = "ROLE" end
    if DTCRaidDB.settings.lbDetailMode == nil then DTCRaidDB.settings.lbDetailMode = "ALL" end
    
    -- Default voting win messages
    if DTCRaidDB.settings.voteWinCount == nil then
        DTCRaidDB.settings.voteWinCount = 10
        DTCRaidDB.settings.voteWinMsg_1 = "Congrats to %s for winning the vote!"
        DTCRaidDB.settings.voteWinMsg_2 = "And the winner is... %s!"    
        DTCRaidDB.settings.voteWinMsg_3 = "STOP THE COUNT! %s has taken the lead!"
        DTCRaidDB.settings.voteWinMsg_4 = "The tribe has spoken. %s is the winner!"
        DTCRaidDB.settings.voteWinMsg_5 = "Democracy manifests! %s wins the vote."
        DTCRaidDB.settings.voteWinMsg_6 = "By popular demand, %s takes the crown."
        DTCRaidDB.settings.voteWinMsg_7 = "The people have chosen... wisely? %s wins!"
        DTCRaidDB.settings.voteWinMsg_8 = "Victory! %s is the chosen one."
        DTCRaidDB.settings.voteWinMsg_9 = "Against all odds, %s secures the win."
        DTCRaidDB.settings.voteWinMsg_10 = "Look at me. %s is the captain now."
    end
    
    if DTCRaidDB.settings.voteRunnerUpMsg == nil then DTCRaidDB.settings.voteRunnerUpMsg = "Honorable mention goes to %s." end
    if DTCRaidDB.settings.voteLowMsg == nil then DTCRaidDB.settings.voteLowMsg = "Don't worry %s, there's always next time." end
    if DTCRaidDB.settings.votesPerPerson == nil then DTCRaidDB.settings.votesPerPerson = 3 end
    
    -- Timer Defaults
    if DTCRaidDB.settings.voteTimer == nil then DTCRaidDB.settings.voteTimer = 180 end -- NEW: Voting Window
    if DTCRaidDB.settings.voteRunnerUpEnabled == nil then DTCRaidDB.settings.voteRunnerUpEnabled = true end
    if DTCRaidDB.settings.voteLowEnabled == nil then DTCRaidDB.settings.voteLowEnabled = true end
    if DTCRaidDB.settings.bribeTimer == nil then DTCRaidDB.settings.bribeTimer = 90 end
    if DTCRaidDB.settings.propTimer == nil then DTCRaidDB.settings.propTimer = 90 end
    if DTCRaidDB.settings.lobbyTimer == nil then DTCRaidDB.settings.lobbyTimer = 120 end 
    if DTCRaidDB.settings.corruptionFee == nil then DTCRaidDB.settings.corruptionFee = 10 end
    if DTCRaidDB.settings.debtLimit == nil then DTCRaidDB.settings.debtLimit = 0 end
    
    C_ChatInfo.RegisterAddonMessagePrefix(DTC.PREFIX)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Returns a string formatted with the class color of the given player name.
-- @param name: The name of the player.
function DTC:GetColoredName(name)
    if not name then return "" end
    local lookup = name
    if string.find(name, "-") then lookup = strsplit("-", name) end
    if DTCRaidDB.classes and DTCRaidDB.classes[lookup] then
        local c = RAID_CLASS_COLORS[DTCRaidDB.classes[lookup]]
        if c then return string.format("|cFF%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, name) end
    end
    return name
end

-- Returns "ColoredName (Nickname)" or just "ColoredName" if no nickname exists.
-- Handles class coloring and avoids redundant "Name (Name)" display.
function DTC:GetDisplayColoredName(name)
    local cName = self:GetColoredName(name)
    local nick = DTCRaidDB.identities and DTCRaidDB.identities[name]
    if nick and nick ~= "" and nick ~= name then
        return cName .. " (" .. nick .. ")"
    end
    return cName
end

-- Returns the full name (Name-Realm) of a player if they are in the raid group.
-- Useful for whispering players cross-realm.
function DTC:GetFullName(shortName)
    if not IsInRaid() then return shortName end
    for i=1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            local sName = name
            if string.find(sName, "-") then sName = strsplit("-", sName) end
            if sName == shortName then return name end
        end
    end
    return shortName
end

-- Triggers the database reset confirmation popup.
function DTC:ResetDatabase() StaticPopup_Show("DTC_RESET_CONFIRM") end

-- Checks if the player is currently in a valid raid instance for tracking.
-- Excludes LFR (7, 17) and Timewalking (33).
function DTC:IsValidRaid()
    local name, instanceType, difficultyID = GetInstanceInfo()
    if instanceType ~= "raid" then return false end 
    if difficultyID == 7 or difficultyID == 17 or difficultyID == 33 then return false end 
    
    local isValidRaid = false
    if DTC.Static and DTC.Static.RAID_DATA then
        for expID, raidList in pairs(DTC.Static.RAID_DATA) do
            for _, rName in ipairs(raidList) do
                if rName == name then isValidRaid = true; break end
            end
            if isValidRaid then break end
        end
    end
    return isValidRaid
end

-- Scans the raid roster and populates the identities, classes, and guilds tables.
-- Only runs if in a valid raid.
function DTC:CheckRosterForNicknames()
    if not IsInRaid() then return end
    if not self:IsValidRaid() then return end

    for i = 1, GetNumGroupMembers() do
        local unitID = "raid"..i
        local charName, _, _, _, _, classFile = GetRaidRosterInfo(i)
        
        if charName then
            if string.find(charName, "-") then charName = strsplit("-", charName) end
            if not DTCRaidDB.identities[charName] then DTCRaidDB.identities[charName] = charName end
            if classFile then DTCRaidDB.classes[charName] = classFile end
            
            local guildName, _, _, _ = GetGuildInfo(unitID)
            if guildName then DTCRaidDB.guilds[charName] = guildName else DTCRaidDB.guilds[charName] = "" end
        end
    end
end

function DTC:CheckSessionStart()
    if not self:IsValidRaid() then
        self.SessionActive = nil
        self.SessionDecided = false
        return
    end

    if UnitIsGroupLeader("player") then
        if not self.SessionDecided then
            StaticPopup_Show("DTC_START_SESSION")
        end
    else
        if IsInRaid() and self.SessionActive == nil then
             C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SESSION_QUERY", "RAID")
             self.SessionActive = false -- Assume false until we hear back to prevent spam
        end
    end
end

function DTC:SyncSessionStatus()
    local status = DTC.SessionActive and "1" or "0"
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SESSION_STATUS:"..status, "RAID")
    end
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_DTC1 = "/dtc"
SlashCmdList["DTC"] = function(msg)
    local cmd = msg:match("^(%S*)"):lower()
    
    if DTC:IsValidRaid() and not DTC.SessionActive then
        if cmd ~= "config" and cmd ~= "reset" then
            print("|cFFFF0000DTC:|r Addon is not active for this raid session (Leader disabled or not started).")
            return
        end
    end

    if cmd == "vote" then 
        if DTC.VoteFrame then DTC.VoteFrame:Toggle() end
    elseif cmd == "lb" then 
        DTC.isTestModeLB = false
        if DTC.LeaderboardUI then 
            DTC.LeaderboardUI:Toggle() 
        end
    elseif cmd == "history" then 
        DTC.isTestModeHist = false
        if DTC.HistoryUI then 
            DTC.HistoryUI:Toggle() 
        end
    elseif cmd == "awards" or cmd == "bribes" then
        if DTC.BribeUI then 
            DTC.BribeUI:ToggleTracker() 
        end
    elseif cmd == "config" then
        if Settings and Settings.OpenToCategory then Settings.OpenToCategory(DTC.OptionsCategoryID) 
        else InterfaceOptionsFrame_OpenToCategory("DTC Raid Tracker") end
    elseif cmd == "reset" then 
        DTC:ResetDatabase()
    else 
        print("|cFFFFD700DTC Commands:|r /dtc vote, /dtc lb, /dtc history, /dtc bribes, /dtc config, /dtc reset") 
    end
end

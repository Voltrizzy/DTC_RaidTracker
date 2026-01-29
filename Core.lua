local folderName, DTC = ...
_G["DTC_Global"] = DTC 

DTC.VERSION = "7.0.0-Beta"
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
f:RegisterEvent("ADDON_LOADED"); f:RegisterEvent("PLAYER_LOGOUT"); f:RegisterEvent("GROUP_ROSTER_UPDATE")
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
            -- ROUTING
            if DTC.Vote then DTC.Vote:OnComm(action, data, sender) end
            if DTC.History then DTC.History:OnComm(action, data, sender) end
        end
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
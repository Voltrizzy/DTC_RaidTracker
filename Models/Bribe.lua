-- ============================================================================
-- DTC Raid Tracker - Models/Bribe.lua
-- ============================================================================
-- This file contains the logic for the "Game Theory" module, including Bribes,
-- Propositions, Lobbying, and Debt Tracking. It handles the state of offers,
-- trade interactions, and communication synchronization.

local folderName, DTC = ...
DTC.Bribe = {}

local DELIMITER = "||"

-- State Variables
DTC.Bribe.IncomingQueue = {}      -- Queue for incoming direct bribe offers
DTC.Bribe.PropositionQueue = {}   -- Queue for active propositions (selling votes)
DTC.Bribe.LobbyQueue = {}         -- Queue for active lobby offers (paying for votes)
DTC.Bribe.ActiveTrade = nil       -- Stores details of the currently active trade
DTC.Bribe.PlayerMoneyStart = 0    -- Snapshot of player money before trade opens

-- Initialize event listeners for trade window interactions
function DTC.Bribe:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("TRADE_SHOW")
    f:RegisterEvent("TRADE_CLOSED")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "TRADE_SHOW" then DTC.Bribe:OnTradeShow()
        elseif event == "TRADE_CLOSED" then DTC.Bribe:OnTradeClosed() end
    end)
end

-- =========================================================
-- 1. STANDARD BRIBE LOGIC
-- =========================================================

-- Sends a direct bribe offer to a target player via addon message.
function DTC.Bribe:OfferBribe(targetPlayer, amount)
    if not targetPlayer or not amount or tonumber(amount) <= 0 then return end
    if IsInGroup() and not IsInRaid() then print("|cFFFF0000DTC:|r Bribes are only available in a raid group (or Solo for testing)."); return end
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist!"); return end
    
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot offer bribe. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local payload = string.format("%d", amount)
    local fullTarget = DTC.Utils:GetFullName(targetPlayer)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_OFFER:"..payload, "WHISPER", fullTarget)
    print("|cFF00FF00DTC:|r Offered " .. amount .. "g to " .. targetPlayer)
end

-- Handles receiving a bribe offer. Adds it to the incoming queue and starts a timer.
function DTC.Bribe:ReceiveOffer(sender, amount, isTest)
    if not IsInRaid() and not isTest then return end
    if DTC.Vote and (DTC.Vote.myVotesLeft <= 0 or not DTC.Vote.isOpen) then return end
    if not amount or (tonumber(amount) or 0) <= 0 then return end
    local duration = DTCRaidDB.settings.bribeTimer or 90
    local offer = { id = DTC.Utils:GenerateUniqueID(sender), sender = sender, amount = tonumber(amount), timer = nil, startTime = GetTime() }
    offer.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireOffer(offer.id) end)
    table.insert(self.IncomingQueue, offer)
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

-- Accepts a specific bribe offer, casts the vote, and records the transaction.
function DTC.Bribe:AcceptOffer(offerID)
    local offer, index = self:GetOffer(offerID)
    if not offer then return end
    
    -- SAFETY CHECK: Is voting still open?
    if not DTC.Vote or not DTC.Vote.isOpen then 
        print("|cFFFF0000DTC:|r Voting has ended. Offer expired.")
        self:RemoveOffer(index)
        return
    end

    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist! Cannot incur tax."); return end
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot accept offer. Total debt exceeds limit ("..limit.."g)."); return
    end

    if DTC.Vote and DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(offer.sender)
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s||%d||%s||BRIBE", offer.sender, offer.amount, (boss:gsub(DELIMITER, "")))
        if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID") end
        print("|cFF00FF00DTC:|r Accepted bribe from " .. offer.sender)
        self:TrackBribe(offer.sender, UnitName("player"), offer.amount, boss, "BRIBE")
        if DTC.Vote.myVotesLeft <= 0 then self:DeclineAll() end
    end
    self:RemoveOffer(index)
end

-- Declines a bribe offer, removing it from the queue.
function DTC.Bribe:DeclineOffer(offerID)
    local _, index = self:GetOffer(offerID)
    if index then self:RemoveOffer(index) end
end

-- Callback for when a bribe offer timer expires.
function DTC.Bribe:ExpireOffer(id)
    local _, index = self:GetOffer(id)
    if index then self:RemoveOffer(index) end
end

-- Helper to find an offer in the queue by ID.
function DTC.Bribe:GetOffer(id)
    for i, v in ipairs(self.IncomingQueue) do if v.id == id then return v, i end end
    return nil, nil
end

function DTC.Bribe:RemoveOffer(index)
    if self.IncomingQueue[index] then
        if self.IncomingQueue[index].timer then self.IncomingQueue[index].timer:Cancel() end
        table.remove(self.IncomingQueue, index)
        if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
    end
end

-- =========================================================
-- 2. PROPOSITION LOGIC
-- =========================================================

-- Broadcasts a proposition (selling own vote) to the raid.
function DTC.Bribe:SendProposition(amount)
    if not amount or tonumber(amount) <= 0 then return end
    if IsInGroup() and not IsInRaid() then print("|cFFFF0000DTC:|r Propositions are only available in a raid group (or Solo for testing)."); return end
    self.MyCurrentPropPrice = tonumber(amount)
    if not DTC.Vote or not DTC.Vote.isOpen then print("Voting is closed."); return end
    if DTC.Vote.myVotesLeft <= 0 then print("No votes left to sell!"); return end
    
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist! Cannot incur tax."); return end
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot send proposition. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local payload = string.format("%d", amount)
    if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_OFFER:"..payload, "RAID") end
    print("|cFF00FF00DTC:|r Proposition broadcast: My vote for " .. amount .. "g.")
end

-- Handles receiving a proposition broadcast. Adds it to the proposition queue.
function DTC.Bribe:ReceiveProposition(offerer, amount, isTest)
    if not IsInRaid() and not isTest then return end
    if not DTC.Vote or not DTC.Vote.isOpen then return end
    if offerer == UnitName("player") then return end
    local votesUsed = DTC.Vote:GetVotesCastBy(offerer)
    local maxVotes = DTCRaidDB.settings.votesPerPerson or 3
    if votesUsed >= maxVotes then return end
    if not amount or (tonumber(amount) or 0) <= 0 then return end
    local duration = DTCRaidDB.settings.propTimer or 90
    local prop = { 
        id = DTC.Utils:GenerateUniqueID(offerer), 
        offerer = offerer, 
        amount = tonumber(amount), 
        timer = nil,
        startTime = GetTime(),
        duration = duration
    }
    prop.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireProposition(prop.id) end)
    table.insert(self.PropositionQueue, prop)
    if DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

-- Accepts a proposition, sending a whisper to the offerer to confirm.
function DTC.Bribe:AcceptProposition(propID)
    local prop = self:GetProposition(propID)
    if not prop then return end
    if not DTC.Vote or not DTC.Vote.isOpen then print("Voting is closed."); return end
    
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist!"); return end
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot accept proposition. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local fullTarget = DTC.Utils:GetFullName(prop.offerer)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_ACCEPT", "WHISPER", fullTarget)
end

-- Handles the confirmation from a buyer that they accepted your proposition.
function DTC.Bribe:OnPropositionAcceptedByMe(buyerName)
    if not DTC.Vote or not DTC.Vote.isOpen then return end
    if DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(buyerName)
        local price = self.MyCurrentPropPrice or 0 
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s||%d||%s||PROP", buyerName, price, (boss:gsub(DELIMITER, "")))
        if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID") end
        print("|cFF00FF00DTC:|r Proposition accepted by " .. buyerName .. ". Vote cast!")
        self:TrackBribe(buyerName, UnitName("player"), price, boss, "PROP")
    end
end

-- =========================================================
-- 3. LOBBYING LOGIC
-- =========================================================

-- Broadcasts a lobby offer (paying others to vote for a candidate) to the raid.
function DTC.Bribe:SendLobby(candidate, amount)
    if not candidate or not amount or tonumber(amount) <= 0 then return end
    if IsInGroup() and not IsInRaid() then print("|cFFFF0000DTC:|r Lobbying is only available in a raid group (or Solo for testing)."); return end
    
    if candidate == UnitName("player") then print("|cFFFF0000DTC:|r You cannot lobby for yourself."); return end
    
    if not DTC.Vote or not DTC.Vote.isOpen then print("Voting is closed."); return end
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist! Cannot incur debt/tax."); return end
    
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot lobby. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local payload = string.format("%s||%d", candidate, amount)
    if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "LOBBY_OFFER:"..payload, "RAID") end
    print("|cFF00FF00DTC:|r Lobbying for " .. candidate .. " (" .. amount .. "g) broadcast to raid.")
end

-- Handles receiving a lobby offer. Adds it to the lobby queue.
function DTC.Bribe:ReceiveLobby(lobbyist, candidate, amount, isTest)
    if not IsInRaid() and not isTest then return end
    if lobbyist == UnitName("player") then return end
    if candidate == UnitName("player") then return end
    if lobbyist == candidate then return end -- Prevent self-lobbying
    if DTC.Vote and (DTC.Vote.myVotesLeft <= 0 or not DTC.Vote.isOpen) then return end
    
    local val = tonumber(amount)
    if not val or val <= 0 then return end
    local duration = DTCRaidDB.settings.lobbyTimer or 120
    local lobby = { 
        id = DTC.Utils:GenerateUniqueID(lobbyist) .. "-" .. candidate,
        lobbyist = lobbyist, 
        candidate = candidate, 
        amount = val, 
        timer = nil,
        startTime = GetTime(),
        duration = duration
    }
    lobby.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireLobby(lobby.id) end)
    table.insert(self.LobbyQueue, lobby)
    if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
end

-- Accepts a lobby offer, casting the vote for the candidate and recording the transaction.
function DTC.Bribe:AcceptLobby(lobbyID)
    local lobby, index = self:GetLobby(lobbyID)
    if not lobby then return end
    
    if not DTC.Vote or not DTC.Vote.isOpen then 
        print("|cFFFF0000DTC:|r Voting has ended.")
        self:RemoveLobby(index)
        return
    end
    
    if DTC.Vote and DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(lobby.candidate)
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s||%d||%s||LOBBY", lobby.lobbyist, lobby.amount, (boss:gsub(DELIMITER, "")))
        if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID") end
        print("|cFF00FF00DTC:|r Accepted Lobby from " .. lobby.lobbyist .. " to vote for " .. lobby.candidate)
        self:TrackBribe(lobby.lobbyist, UnitName("player"), lobby.amount, boss, "LOBBY")
        if DTC.Vote.myVotesLeft <= 0 then self:DeclineAll() end
    end
    self:RemoveLobby(index)
end

-- Callback for when a lobby offer timer expires.
function DTC.Bribe:ExpireLobby(id)
    local _, index = self:GetLobby(id)
    if index then
        table.remove(self.LobbyQueue, index)
        if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
    end
end

function DTC.Bribe:GetLobby(id)
    for i, v in ipairs(self.LobbyQueue) do if v.id == id then return v, i end end
    return nil, nil
end

function DTC.Bribe:RemoveLobby(index)
    if self.LobbyQueue[index] then
        if self.LobbyQueue[index].timer then self.LobbyQueue[index].timer:Cancel() end
        table.remove(self.LobbyQueue, index)
        if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
    end
end

-- =========================================================
-- 4. HELPERS
-- =========================================================

-- Records a bribe transaction in the database and handles corruption fee logic.
function DTC.Bribe:TrackBribe(offerer, recipient, amount, boss, bType)
    boss = (boss or "Unknown"):gsub(DELIMITER, "")
    offerer = (offerer or "Unknown"):gsub(DELIMITER, "")
    recipient = (recipient or "Unknown"):gsub(DELIMITER, "")
    local amt = math.floor(tonumber(amount) or 0)
    if amt <= 0 then return end -- Safety check
    local ts = date("%Y-%m-%d %H:%M:%S")
    local entry = { offerer = offerer, recipient = recipient, amount = amt, boss = boss, paid = false, timestamp = ts }
    table.insert(DTCRaidDB.bribes, entry)
    
    -- Corruption Fee Logic
    local feePct = DTCRaidDB.settings.corruptionFee or 10
    if feePct > 0 then
        local fee = math.floor(amt * (feePct / 100))
        if fee > 0 then
            local leader = self:GetLeaderName()
            if leader then
                local feePayer = recipient -- Receiver of funds always pays the tax
                if feePayer and feePayer ~= leader then
                    local feeEntry = { offerer = feePayer, recipient = leader, amount = fee, boss = (boss or "Unknown") .. " (Tax)", paid = false, timestamp = ts }
                    table.insert(DTCRaidDB.bribes, feeEntry)
                end
            end
        end
    end
    
    if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
end

-- Clears all active queues (Incoming, Lobby) and cancels timers.
function DTC.Bribe:DeclineAll()
    for _, offer in ipairs(self.IncomingQueue) do if offer.timer then offer.timer:Cancel() end end
    self.IncomingQueue = {}
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
    
    for _, lobby in ipairs(self.LobbyQueue) do if lobby.timer then lobby.timer:Cancel() end end
    self.LobbyQueue = {}
    if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
end

-- Checks if a player has any unpaid debts for previous bosses.
function DTC.Bribe:HasUnpaidDebt(target)
    local myName = target or UnitName("player")
    local currentBoss = DTC.Vote and DTC.Vote.currentBoss or "Unknown"
    for _, entry in ipairs(DTCRaidDB.bribes) do
        if entry.offerer == myName and not entry.paid and entry.boss ~= currentBoss then return true end
    end
    return false
end

-- Calculates the total amount of unpaid debt for the player.
function DTC.Bribe:GetTotalDebt()
    local myName = UnitName("player")
    local total = 0
    for _, entry in ipairs(DTCRaidDB.bribes or {}) do
        if entry.offerer == myName and not entry.paid then total = total + (entry.amount or 0) end
    end
    return total
end

function DTC.Bribe:ExpireProposition(propID)
    local _, index = self:GetProposition(propID)
    if index then table.remove(self.PropositionQueue, index); if DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end end
end

function DTC.Bribe:GetProposition(id)
    for i, v in ipairs(self.PropositionQueue) do if v.id == id then return v, i end end
    return nil, nil
end

-- Initiates a trade with a player to pay off a debt.
function DTC.Bribe:InitiateTrade(player, amount, dbIndex, isPaying)
    if InCombatLockdown() then print("|cFFFF0000DTC:|r Cannot initiate trade in combat."); return end
    if UnitIsDeadOrGhost("player") then print("|cFFFF0000DTC:|r Cannot initiate trade while dead."); return end
    self.ActiveTrade = { target = player, amount = tonumber(amount) or 0, index = dbIndex, isPaying = isPaying }
    
    -- Attempt to find a UnitID to avoid TargetUnit()
    local unitID
    if player == UnitName("target") then unitID = "target" end
    
    if not unitID then
        if IsInRaid() then
            for i=1, GetNumGroupMembers() do
                local u = "raid"..i
                local name = GetRaidRosterInfo(i)
                if name then
                    local short = name
                    if string.find(name, "-") then short = strsplit("-", name) end
                    if name == player or short == player then unitID = u; break end
                end
            end
        elseif IsInGroup() then
            for i=1, GetNumGroupMembers() - 1 do
                local u = "party"..i
                local name = UnitName(u)
                if name then
                    local short = name
                    if string.find(name, "-") then short = strsplit("-", name) end
                    if name == player or short == player then unitID = u; break end
                end
            end
        end
    end

    if unitID then InitiateTrade(unitID) else TargetUnit(player); InitiateTrade("target") end
end

-- Event handler for TRADE_SHOW. Auto-fills gold if paying.
function DTC.Bribe:OnTradeShow()
    self.PlayerMoneyStart = GetMoney()
    if self.ActiveTrade then
        local target = UnitName("NPC")
        if not target then target = GetUnitName("NPC", false) end
        
        local expected = self.ActiveTrade.target
        
        if target == expected then
            if self.ActiveTrade.isPaying and TradePlayerInputMoneyFrame then 
                MoneyInputFrame_SetMoney(TradePlayerInputMoneyFrame, math.floor(self.ActiveTrade.amount * 10000)) 
            end
        else
            self.ActiveTrade = nil -- Mismatch, clear to prevent accidents
        end
    end
end

-- Event handler for TRADE_CLOSED. Verifies if the trade was successful.
function DTC.Bribe:OnTradeClosed()
    if self.ActiveTrade and self.ActiveTrade.index then
        local moneyEnd = GetMoney()
        local success = false
        local expected = math.floor(self.ActiveTrade.amount * 10000)
        
        if self.ActiveTrade.isPaying then
            if (self.PlayerMoneyStart - moneyEnd) >= expected then success = true end
        else
            if (moneyEnd - self.PlayerMoneyStart) >= expected then success = true end
        end
        
        if success then
            local entry = DTCRaidDB.bribes[self.ActiveTrade.index]
            if entry then 
                entry.paid = true
                PlaySound(1203) -- SOUNDKIT.IG_BACKPACK_COIN_OK
                if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
                
                -- Sync payment status to raid
                local payload = string.format("%s||%s||%d||%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
                if IsInRaid() and not self.ActiveTrade.isPaying then 
                    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID") 
                end
            end
        end
    end
    self.ActiveTrade = nil
end

-- Checks active propositions to see if the offerer has run out of votes.
function DTC.Bribe:CheckPropositionValidity()
    if not DTC.Vote then return end
    local changed = false
    local maxVotes = DTCRaidDB.settings.votesPerPerson or 3
    for i = #self.PropositionQueue, 1, -1 do
        local p = self.PropositionQueue[i]
        local votes = DTC.Vote:GetVotesCastBy(p.offerer)
        if votes >= maxVotes then if p.timer then p.timer:Cancel() end; table.remove(self.PropositionQueue, i); changed = true end
    end
    if changed and DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

-- Announces all outstanding debts to the raid chat (or print if solo).
function DTC.Bribe:AnnounceDebts()
    local debts = {}
    for _, entry in ipairs(DTCRaidDB.bribes or {}) do
        if not entry.paid then table.insert(debts, entry) end
    end
    
    if #debts == 0 then
        print("|cFF00FF00DTC:|r No outstanding debts found.")
        return
    end
    
    local channel = IsInRaid() and "RAID" or "PRINT"
    local header = "--- DTC Debt Report ---"
    if channel == "PRINT" then print(header) else SendChatMessage(header, channel) end
    
    for _, d in ipairs(debts) do
        local msg = string.format("%s owes %s %dg (%s)", d.offerer, d.recipient, d.amount, d.boss)
        if channel == "PRINT" then print(msg) else SendChatMessage(msg, channel) end
    end
end

-- Marks all tax debts owed to the player as paid.
function DTC.Bribe:PayAllTaxes()
    if IsInGroup() and not IsInRaid() then print("|cFFFF0000DTC:|r You must be in a raid group to mark taxes as paid (to ensure sync)."); return end
    local count = 0
    for _, entry in ipairs(DTCRaidDB.bribes or {}) do
        if not entry.paid and entry.boss and string.find(entry.boss, "%(Tax%)") and entry.recipient == UnitName("player") then
            entry.paid = true
            count = count + 1
            
            -- Sync payment status to raid
            local payload = string.format("%s||%s||%d||%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
            if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID") end
        end
    end
    if count > 0 then
        PlaySound(1203)
        print("|cFF00FF00DTC:|r Marked " .. count .. " tax debts as paid.")
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
    else
        print("|cFFFF0000DTC:|r No outstanding tax debts found.")
    end
end

-- Forgives a specific debt entry.
function DTC.Bribe:ForgiveDebt(index)
    if IsInGroup() and not IsInRaid() then print("|cFFFF0000DTC:|r You must be in a raid group to forgive debts."); return end
    local entry = DTCRaidDB.bribes[index]
    if entry then
        if entry.recipient ~= UnitName("player") then return end
        entry.paid = true
        PlaySound(1203)
        print("|cFF00FF00DTC:|r You forgave the debt of " .. entry.offerer .. " (" .. entry.amount .. "g).")
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
        
        -- Sync payment status to raid
        local payload = string.format("%s||%s||%d||%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
        if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID") end
    end
end

-- Manually marks a debt as paid without a trade.
function DTC.Bribe:MarkDebtPaid(index)
    if IsInGroup() and not IsInRaid() then print("|cFFFF0000DTC:|r You must be in a raid group to mark debts as paid."); return end
    local entry = DTCRaidDB.bribes[index]
    if entry then
        if entry.recipient ~= UnitName("player") then return end
        entry.paid = true
        PlaySound(1203)
        print("|cFF00FF00DTC:|r Manually marked debt from " .. entry.offerer .. " as PAID.")
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
        
        -- Sync payment status to raid
        local payload = string.format("%s||%s||%d||%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
        if IsInRaid() then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID") end
    end
end

-- Helper to find the name of the raid leader (Rank 2).
function DTC.Bribe:GetLeaderName()
    if not IsInRaid() then return UnitName("player") end
    for i = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if rank == 2 then
            if name and string.find(name, "-") then name = strsplit("-", name) end
            return name
        end
    end
    return UnitName("player")
end

-- Dispatch table for OnComm actions
local commHandlers = {
    ["BRIBE_OFFER"] = function(self, data, sender) self:ReceiveOffer(sender, data) end,
    ["PROP_OFFER"] = function(self, data, sender) self:ReceiveProposition(sender, data) end,
    ["PROP_ACCEPT"] = function(self, data, sender) self:OnPropositionAcceptedByMe(sender) end,
    ["LOBBY_OFFER"] = function(self, data, sender)
        local cand, amt = DTC.Utils:SplitString(data, DELIMITER)
        self:ReceiveLobby(sender, cand, amt)
    end,
    ["BRIBE_FINAL"] = function(self, data, sender)
        local offerer, amount, boss, bType = DTC.Utils:SplitString(data, DELIMITER)
        self:TrackBribe(offerer, sender, amount, boss, bType)
    end,
    ["DEBT_PAID"] = function(self, data, sender)
        local offerer, recipient, amount, boss = DTC.Utils:SplitString(data, DELIMITER)
        if sender ~= recipient then return end -- Security: Only the creditor can mark debt as paid
        amount = tonumber(amount) or 0
        for _, e in ipairs(DTCRaidDB.bribes) do
            if e.offerer == offerer and e.recipient == recipient and e.amount == amount and e.boss == boss and not e.paid then
                e.paid = true
                if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
                break
            end
        end
    end,
    ["SYNC_LIMIT"] = function(self, data, sender)
        if sender == self:GetLeaderName() then DTCRaidDB.settings.debtLimit = tonumber(data) or 0 end
    end,
    ["SYNC_FEE"] = function(self, data, sender)
        if sender == self:GetLeaderName() then DTCRaidDB.settings.corruptionFee = tonumber(data) or 10 end
    end,
    ["SYNC_TIMERS"] = function(self, data, sender)
        if sender == self:GetLeaderName() then
            local b, p, l = DTC.Utils:SplitString(data, DELIMITER)
            DTCRaidDB.settings.bribeTimer = tonumber(b) or 90
            DTCRaidDB.settings.propTimer = tonumber(p) or 90
            DTCRaidDB.settings.lobbyTimer = tonumber(l) or 120
        end
    end,
    ["SYNC_VOTES"] = function(self, data, sender)
        if sender == self:GetLeaderName() then
            DTCRaidDB.settings.votesPerPerson = tonumber(data) or 3
            if DTC.Vote and DTC.Vote.isOpen then
                local max = DTCRaidDB.settings.votesPerPerson
                local myName = UnitName("player")
                local used = (DTC.Vote.voters and DTC.Vote.voters[myName]) or 0
                DTC.Vote.myVotesLeft = max - used
                if DTC.VoteFrame then DTC.VoteFrame:UpdateList() end
            end
        end
    end,
    ["VOTE"] = function(self, data, sender)
        C_Timer.After(0.5, function() self:CheckPropositionValidity() end)
    end
}

-- Handles incoming addon communication messages for the Bribe module.
function DTC.Bribe:OnComm(action, data, sender)
    -- Sender sanitization handled by Core or passed raw? Core passes raw.
    if sender == UnitName("player") then return end 

    local handler = commHandlers[action]
    if handler then
        handler(self, data, sender)
    end
end

DTC.Bribe:Init()

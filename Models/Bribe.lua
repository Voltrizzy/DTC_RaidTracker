local folderName, DTC = ...
DTC.Bribe = {}

-- State
DTC.Bribe.IncomingQueue = {} 
DTC.Bribe.PropositionQueue = {} 
DTC.Bribe.LobbyQueue = {} -- NEW: {id, lobbyist, candidate, amount, timer}
DTC.Bribe.ActiveTrade = nil  
DTC.Bribe.PlayerMoneyStart = 0

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
function DTC.Bribe:OfferBribe(targetPlayer, amount)
    if not targetPlayer or not amount or tonumber(amount) <= 0 then return end
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist!"); return end
    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_OFFER:"..payload, "WHISPER", targetPlayer)
    print("|cFF00FF00DTC:|r Offered " .. amount .. "g to " .. targetPlayer)
end

function DTC.Bribe:ReceiveOffer(sender, amount)
    if DTC.Vote and DTC.Vote.myVotesLeft <= 0 then return end
    local duration = DTCRaidDB.settings.bribeTimer or 90
    local offer = { id = GetTime(), sender = sender, amount = tonumber(amount), timer = nil }
    offer.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireOffer(offer.id) end)
    table.insert(self.IncomingQueue, offer)
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

function DTC.Bribe:AcceptOffer(offerID)
    local offer, index = self:GetOffer(offerID)
    if not offer then return end
    if DTC.Vote and DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(offer.sender)
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s", offer.sender, offer.amount, boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        print("|cFF00FF00DTC:|r Accepted bribe from " .. offer.sender)
        if DTC.Vote.myVotesLeft <= 0 then self:DeclineAll() end
    end
    self:RemoveOffer(index)
end

-- =========================================================
-- 2. PROPOSITION LOGIC
-- =========================================================
function DTC.Bribe:SendProposition(amount)
    if not amount or tonumber(amount) <= 0 then return end
    if DTC.Vote.myVotesLeft <= 0 then print("No votes left to sell!"); return end
    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_OFFER:"..payload, "RAID")
    print("|cFF00FF00DTC:|r Proposition broadcast: My vote for " .. amount .. "g.")
end

function DTC.Bribe:ReceiveProposition(offerer, amount)
    if offerer == UnitName("player") then return end
    local votesUsed = DTC.Vote:GetVotesCastBy(offerer)
    if votesUsed >= 3 then return end
    local duration = DTCRaidDB.settings.propTimer or 90
    local prop = { id = GetTime() .. "-" .. offerer, offerer = offerer, amount = tonumber(amount), timer = nil }
    prop.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireProposition(prop.id) end)
    table.insert(self.PropositionQueue, prop)
    if DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

function DTC.Bribe:AcceptProposition(propID)
    local prop = self:GetProposition(propID)
    if not prop then return end
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_ACCEPT", "WHISPER", prop.offerer)
end

function DTC.Bribe:OnPropositionAcceptedByMe(buyerName)
    if DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(buyerName)
        local price = self.MyCurrentPropPrice or 0 
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s", buyerName, price, boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        print("|cFF00FF00DTC:|r Proposition accepted by " .. buyerName .. ". Vote cast!")
    end
end

-- =========================================================
-- 3. LOBBYING LOGIC (NEW)
-- =========================================================
function DTC.Bribe:SendLobby(candidate, amount)
    if not candidate or not amount or tonumber(amount) <= 0 then return end
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist!"); return end
    
    -- "I (Lobbyist) pay X gold for votes on Candidate"
    local payload = string.format("%s,%d", candidate, amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "LOBBY_OFFER:"..payload, "RAID")
    print("|cFF00FF00DTC:|r Lobbying for " .. candidate .. " (" .. amount .. "g) broadcast to raid.")
end

function DTC.Bribe:ReceiveLobby(lobbyist, candidate, amount)
    if lobbyist == UnitName("player") then return end
    if DTC.Vote and DTC.Vote.myVotesLeft <= 0 then return end -- No votes, ignore
    
    local duration = DTCRaidDB.settings.lobbyTimer or 120
    local lobby = { 
        id = GetTime() .. "-" .. lobbyist .. "-" .. candidate,
        lobbyist = lobbyist, 
        candidate = candidate, 
        amount = tonumber(amount), 
        timer = nil 
    }
    
    lobby.timer = C_Timer.NewTimer(duration, function() 
        DTC.Bribe:ExpireLobby(lobby.id) 
    end)
    
    table.insert(self.LobbyQueue, lobby)
    if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
end

function DTC.Bribe:AcceptLobby(lobbyID)
    local lobby, index = self:GetLobby(lobbyID)
    if not lobby then return end
    
    if DTC.Vote and DTC.Vote.myVotesLeft > 0 then
        -- 1. Cast Vote for CANDIDATE
        DTC.Vote:CastVote(lobby.candidate)
        
        -- 2. Record Debt: LOBBYIST owes ME (Recipient)
        -- Format: Offerer,Amount,Boss. Sender is Recipient.
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s", lobby.lobbyist, lobby.amount, boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        
        print("|cFF00FF00DTC:|r Accepted Lobby from " .. lobby.lobbyist .. " to vote for " .. lobby.candidate)
        
        if DTC.Vote.myVotesLeft <= 0 then self:DeclineAll() end
    end
    self:RemoveLobby(index)
end

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
-- 4. HELPERS & COMMS
-- =========================================================
function DTC.Bribe:TrackBribe(offerer, recipient, amount, boss)
    local entry = { offerer = offerer, recipient = recipient, amount = tonumber(amount), boss = boss or "Unknown", paid = false, timestamp = date("%H:%M:%S") }
    table.insert(DTCRaidDB.bribes, entry)
    if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
end

function DTC.Bribe:DeclineAll()
    -- Clear Standard Bribes
    for _, offer in ipairs(self.IncomingQueue) do if offer.timer then offer.timer:Cancel() end end
    self.IncomingQueue = {}
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
    
    -- Clear Lobby Offers
    for _, lobby in ipairs(self.LobbyQueue) do if lobby.timer then lobby.timer:Cancel() end end
    self.LobbyQueue = {}
    if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
end

function DTC.Bribe:HasUnpaidDebt()
    local myName = UnitName("player")
    local currentBoss = DTC.Vote and DTC.Vote.currentBoss or "Unknown"
    for _, entry in ipairs(DTCRaidDB.bribes) do
        if entry.offerer == myName and not entry.paid and entry.boss ~= currentBoss then return true end
    end
    return false
end

function DTC.Bribe:ExpireProposition(propID)
    local _, index = self:GetProposition(propID)
    if index then table.remove(self.PropositionQueue, index); if DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end end
end

function DTC.Bribe:GetProposition(id)
    for i, v in ipairs(self.PropositionQueue) do if v.id == id then return v, i end end
    return nil, nil
end

-- Trade Logic (Unchanged but included for completeness)
function DTC.Bribe:InitiateTrade(player, amount, dbIndex)
    self.ActiveTrade = { target = player, amount = amount, index = dbIndex }
    if UnitExists("target") and UnitName("target") == player then InitiateTrade("target")
    else TargetUnit(player); InitiateTrade("target") end
end
function DTC.Bribe:OnTradeShow()
    self.PlayerMoneyStart = GetMoney()
    if self.ActiveTrade then MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, self.ActiveTrade.amount * 10000) end
end
function DTC.Bribe:OnTradeClosed()
    if self.ActiveTrade and self.ActiveTrade.index then
        local moneyEnd = GetMoney()
        local diff = self.PlayerMoneyStart - moneyEnd
        local expected = self.ActiveTrade.amount * 10000
        if diff >= expected then
            local entry = DTCRaidDB.bribes[self.ActiveTrade.index]
            if entry then entry.paid = true; if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end end
        end
    end
    self.ActiveTrade = nil
end

function DTC.Bribe:CheckPropositionValidity()
    local changed = false
    for i = #self.PropositionQueue, 1, -1 do
        local p = self.PropositionQueue[i]
        local votes = DTC.Vote:GetVotesCastBy(p.offerer)
        if votes >= 3 then if p.timer then p.timer:Cancel() end; table.remove(self.PropositionQueue, i); changed = true end
    end
    if changed and DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, _, prefix, msg, _, sender)
    if prefix ~= DTC.PREFIX then return end
    local action, data = strsplit(":", msg, 2)
    if sender == UnitName("player") then return end 

    if action == "BRIBE_OFFER" then DTC.Bribe:ReceiveOffer(sender, data)
    elseif action == "PROP_OFFER" then DTC.Bribe:ReceiveProposition(sender, data)
    elseif action == "PROP_ACCEPT" then DTC.Bribe:OnPropositionAcceptedByMe(sender)
    elseif action == "LOBBY_OFFER" then 
        local cand, amt = strsplit(",", data)
        DTC.Bribe:ReceiveLobby(sender, cand, amt)
    elseif action == "BRIBE_FINAL" then 
        local offerer, amount, boss = strsplit(",", data)
        DTC.Bribe:TrackBribe(offerer, sender, amount, boss)
    elseif action == "VOTE" then C_Timer.After(0.5, function() DTC.Bribe:CheckPropositionValidity() end) end
end)
DTC.Bribe:Init()

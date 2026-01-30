local folderName, DTC = ...
DTC.Bribe = {}

-- State
DTC.Bribe.IncomingQueue = {} 
DTC.Bribe.PropositionQueue = {} -- NEW: List of {offerer, amount, id, timer}
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
-- 1. STANDARD BRIBE LOGIC (Sending Money to get a Vote)
-- =========================================================
function DTC.Bribe:OfferBribe(targetPlayer, amount)
    if not targetPlayer or not amount or tonumber(amount) <= 0 then return end
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist!"); return end

    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_OFFER:"..payload, "WHISPER", targetPlayer)
    print("|cFF00FF00DTC:|r Offered " .. amount .. "g to " .. targetPlayer)
end

function DTC.Bribe:ReceiveOffer(sender, amount)
    if DTC.Vote and DTC.Vote.myVotesLeft <= 0 then return end -- Silent auto-decline
    
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
        -- Offerer (Sender) pays Me (Recipient)
        -- Debt Record: Offerer owes Recipient
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s", offer.sender, offer.amount, boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        
        print("|cFF00FF00DTC:|r Accepted bribe from " .. offer.sender)
        if DTC.Vote.myVotesLeft <= 0 then self:DeclineAll() end
    end
    self:RemoveOffer(index)
end

-- =========================================================
-- 2. PROPOSITION LOGIC (Selling my Vote)
-- =========================================================
function DTC.Bribe:SendProposition(amount)
    if not amount or tonumber(amount) <= 0 then return end
    if DTC.Vote.myVotesLeft <= 0 then print("No votes left to sell!"); return end
    
    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_OFFER:"..payload, "RAID")
    print("|cFF00FF00DTC:|r Proposition broadcast: My vote for " .. amount .. "g.")
end

function DTC.Bribe:ReceiveProposition(offerer, amount)
    -- If this is me, ignore
    if offerer == UnitName("player") then return end
    
    -- Check if this offerer still has votes
    local votesUsed = DTC.Vote:GetVotesCastBy(offerer)
    if votesUsed >= 3 then return end

    local duration = DTCRaidDB.settings.propTimer or 90
    local prop = { 
        id = GetTime() .. "-" .. offerer, -- Unique ID
        offerer = offerer, 
        amount = tonumber(amount), 
        timer = nil 
    }
    
    prop.timer = C_Timer.NewTimer(duration, function() 
        DTC.Bribe:ExpireProposition(prop.id) 
    end)
    
    table.insert(self.PropositionQueue, prop)
    if DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

function DTC.Bribe:AcceptProposition(propID)
    local prop = self:GetProposition(propID)
    if not prop then return end
    
    -- I (the buyer) am accepting. I pay the Offerer. The Offerer votes for ME.
    -- Send Accept Signal to Offerer
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_ACCEPT", "WHISPER", prop.offerer)
end

function DTC.Bribe:OnPropositionAcceptedByMe(buyerName)
    -- I am the Offerer. Someone accepted my proposition.
    -- I must vote for them.
    if DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(buyerName)
        
        -- Find amount from my active proposition logic? 
        -- Simplified: We assume the standard debt tracking happens via BRIBE_FINAL broadcast below
        -- BUT, I need to tell the raid that "Buyer owes Me".
        
        -- Note: We need to know HOW MUCH I sold it for. 
        -- Ideally we store my Active Proposition amount locally.
        -- For simplicity, let's assume I broadcast the debt creation now.
        
        -- WAIT: The Buyer needs to know the amount to create the debt? 
        -- Actually, usually the person accepting the bribe (ME, in this case I am the voter) 
        -- triggers the debt record.
        
        -- Let's fetch my last broadcast amount or just pass it in the protocol?
        -- Let's rely on manual tracking or stored state. 
        -- Better: When I vote, I broadcast "BRIBE_FINAL" just like a normal bribe.
        -- Offerer = Buyer (Payer), Recipient = Me (Voter).
        
        -- We assume the user remembers what they sold it for, or we track "MyCurrentPrice".
        local price = self.MyCurrentPropPrice or 0 
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s", buyerName, price, boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        
        print("|cFF00FF00DTC:|r Proposition accepted by " .. buyerName .. ". Vote cast!")
    else
        print("|cFFFF0000DTC:|r Error: Tried to honor proposition but ran out of votes!")
    end
end

function DTC.Bribe:ExpireProposition(propID)
    local _, index = self:GetProposition(propID)
    if index then
        table.remove(self.PropositionQueue, index)
        if DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
    end
end

function DTC.Bribe:GetProposition(id)
    for i, v in ipairs(self.PropositionQueue) do if v.id == id then return v, i end end
    return nil, nil
end

-- Check votes to remove invalid propositions
function DTC.Bribe:CheckPropositionValidity()
    local changed = false
    for i = #self.PropositionQueue, 1, -1 do
        local p = self.PropositionQueue[i]
        local votes = DTC.Vote:GetVotesCastBy(p.offerer)
        if votes >= 3 then
            if p.timer then p.timer:Cancel() end
            table.remove(self.PropositionQueue, i)
            changed = true
        end
    end
    if changed and DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

-- =========================================================
-- 3. COMMON LOGIC
-- =========================================================
function DTC.Bribe:TrackBribe(offerer, recipient, amount, boss)
    local entry = {
        offerer = offerer, recipient = recipient, amount = tonumber(amount),
        boss = boss or "Unknown", paid = false, timestamp = date("%H:%M:%S")
    }
    table.insert(DTCRaidDB.bribes, entry)
    if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
end

function DTC.Bribe:DeclineAll()
    for _, offer in ipairs(self.IncomingQueue) do if offer.timer then offer.timer:Cancel() end end
    self.IncomingQueue = {}
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

function DTC.Bribe:HasUnpaidDebt()
    local myName = UnitName("player")
    local currentBoss = DTC.Vote and DTC.Vote.currentBoss or "Unknown"
    for _, entry in ipairs(DTCRaidDB.bribes) do
        if entry.offerer == myName and not entry.paid and entry.boss ~= currentBoss then return true end
    end
    return false
end

-- Trade Logic
function DTC.Bribe:InitiateTrade(player, amount, dbIndex)
    self.ActiveTrade = { target = player, amount = amount, index = dbIndex }
    if UnitExists("target") and UnitName("target") == player then InitiateTrade("target")
    else TargetUnit(player); InitiateTrade("target") end
end

function DTC.Bribe:OnTradeShow()
    self.PlayerMoneyStart = GetMoney()
    if self.ActiveTrade then
        local money = self.ActiveTrade.amount * 10000
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, money)
    end
end

function DTC.Bribe:OnTradeClosed()
    if self.ActiveTrade and self.ActiveTrade.index then
        local moneyEnd = GetMoney()
        local diff = self.PlayerMoneyStart - moneyEnd
        local expected = self.ActiveTrade.amount * 10000
        if diff >= expected then
            local entry = DTCRaidDB.bribes[self.ActiveTrade.index]
            if entry then
                entry.paid = true
                print("|cFF00FF00DTC:|r Bribe to " .. entry.recipient .. " marked as PAID.")
                if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
            end
        end
    end
    self.ActiveTrade = nil
end

-- Helpers
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

-- Comms
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, _, prefix, msg, _, sender)
    if prefix ~= DTC.PREFIX then return end
    local action, data = strsplit(":", msg, 2)
    if sender == UnitName("player") then return end 

    if action == "BRIBE_OFFER" then
        DTC.Bribe:ReceiveOffer(sender, data)
        
    elseif action == "PROP_OFFER" then
        DTC.Bribe:ReceiveProposition(sender, data)
        
    elseif action == "PROP_ACCEPT" then
        -- Sender is the Buyer. I am the Offerer.
        DTC.Bribe:OnPropositionAcceptedByMe(sender)
        
    elseif action == "BRIBE_FINAL" then
        local offerer, amount, boss = strsplit(",", data)
        DTC.Bribe:TrackBribe(offerer, sender, amount, boss)
        
    elseif action == "VOTE" then
        -- Whenever a vote happens, check if it invalidates any propositions
        C_Timer.After(0.5, function() DTC.Bribe:CheckPropositionValidity() end)
    end
end)

DTC.Bribe:Init()

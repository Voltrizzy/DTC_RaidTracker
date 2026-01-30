local folderName, DTC = ...
DTC.Bribe = {}

-- State
DTC.Bribe.IncomingQueue = {} 
DTC.Bribe.ActiveTrade = nil  -- {target, amount, dbIndex}
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

-- 1. Sending an Offer
function DTC.Bribe:OfferBribe(targetPlayer, amount)
    if not targetPlayer or not amount or tonumber(amount) <= 0 then return end
    
    -- DEBT CHECK: Cannot offer if you have unpaid bribes from PREVIOUS bosses
    if self:HasUnpaidDebt() then
        print("|cFFFF0000DTC:|r You have unpaid bribes from previous bosses! Settle your debts first.")
        return
    end

    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_OFFER:"..payload, "WHISPER", targetPlayer)
    print("|cFF00FF00DTC:|r Offered " .. amount .. "g to " .. targetPlayer)
end

-- 2. Receiving & Accepting
function DTC.Bribe:ReceiveOffer(sender, amount)
    -- If I have no votes left, auto-decline immediately (silent)
    if DTC.Vote and DTC.Vote.myVotesLeft <= 0 then
        -- Optional: Notify sender "Auto-declined (No votes left)"
        return 
    end

    local offer = {
        id = GetTime(),
        sender = sender,
        amount = tonumber(amount),
        timer = nil
    }
    
    offer.timer = C_Timer.NewTimer(90, function() DTC.Bribe:ExpireOffer(offer.id) end)
    table.insert(self.IncomingQueue, offer)
    
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

function DTC.Bribe:AcceptOffer(offerID)
    local offer, index = self:GetOffer(offerID)
    if not offer then return end
    
    if DTC.Vote and DTC.Vote.myVotesLeft > 0 then
        -- 1. Cast Vote
        DTC.Vote:CastVote(offer.sender)
        
        -- 2. Notify Sender & Raid
        -- Format: Offerer,Amount,BossName
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s", offer.sender, offer.amount, boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        
        print("|cFF00FF00DTC:|r Accepted bribe from " .. offer.sender)
        
        -- 3. Check if we just used our LAST vote
        if DTC.Vote.myVotesLeft <= 0 then
            self:DeclineAll() -- Clear any other pending offers
        end
    else
        print("|cFFFF0000DTC:|r Cannot accept: No votes remaining!")
    end
    
    self:RemoveOffer(index)
end

function DTC.Bribe:DeclineOffer(offerID)
    local _, index = self:GetOffer(offerID)
    if index then self:RemoveOffer(index) end
    print("|cFFFF0000DTC:|r Declined bribe.")
end

function DTC.Bribe:DeclineAll()
    -- Clear all pending offers immediately
    for _, offer in ipairs(self.IncomingQueue) do
        if offer.timer then offer.timer:Cancel() end
    end
    self.IncomingQueue = {}
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

function DTC.Bribe:ExpireOffer(offerID)
    local _, index = self:GetOffer(offerID)
    if index then 
        self:RemoveOffer(index) 
        if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
    end
end

-- 3. Tracking & Debt Logic
function DTC.Bribe:TrackBribe(offerer, recipient, amount, boss)
    local entry = {
        offerer = offerer,
        recipient = recipient,
        amount = tonumber(amount),
        boss = boss or "Unknown",
        paid = false, -- NEW: Track payment status
        timestamp = date("%H:%M:%S")
    }
    table.insert(DTCRaidDB.bribes, entry)
    if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
end

-- Check if player has unpaid bribes from a DIFFERENT boss
function DTC.Bribe:HasUnpaidDebt()
    local myName = UnitName("player")
    local currentBoss = DTC.Vote and DTC.Vote.currentBoss or "Unknown"
    
    for _, entry in ipairs(DTCRaidDB.bribes) do
        if entry.offerer == myName and not entry.paid then
            -- If the bribe is from a PREVIOUS boss, block them.
            -- (We allow unpaid bribes on the CURRENT boss because trade might not have happened yet)
            if entry.boss ~= currentBoss then
                return true
            end
        end
    end
    return false
end

-- 4. Trade Logic (Auto-Mark Paid)
function DTC.Bribe:InitiateTrade(player, amount, dbIndex)
    self.ActiveTrade = { target = player, amount = amount, index = dbIndex }
    
    if UnitExists("target") and UnitName("target") == player then
        InitiateTrade("target")
    else
        TargetUnit(player)
        InitiateTrade("target") 
    end
end

function DTC.Bribe:OnTradeShow()
    self.PlayerMoneyStart = GetMoney()
    
    if self.ActiveTrade then
        -- Auto-fill gold
        local money = self.ActiveTrade.amount * 10000
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, money)
    end
end

function DTC.Bribe:OnTradeClosed()
    -- Heuristic: If money went down by roughly the bribe amount, assume paid.
    -- (This isn't perfect, but prevents needing complex TradeInfo verification)
    if self.ActiveTrade and self.ActiveTrade.index then
        local moneyEnd = GetMoney()
        local diff = self.PlayerMoneyStart - moneyEnd
        local expected = self.ActiveTrade.amount * 10000
        
        -- If we lost at least the bribe amount (allows for tips/rounding), mark paid
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
    for i, v in ipairs(self.IncomingQueue) do
        if v.id == id then return v, i end
    end
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
        
    elseif action == "BRIBE_FINAL" then
        -- Format: Offerer,Amount,Boss. Sender is the Recipient.
        local offerer, amount, boss = strsplit(",", data)
        DTC.Bribe:TrackBribe(offerer, sender, amount, boss)
    end
end)

DTC.Bribe:Init()

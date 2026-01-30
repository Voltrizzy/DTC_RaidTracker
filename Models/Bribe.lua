local folderName, DTC = ...
DTC.Bribe = {}

-- State
DTC.Bribe.IncomingQueue = {} -- List of {sender, amount, timer}
DTC.Bribe.ActiveTrade = nil  -- {target, amount} for auto-fill

function DTC.Bribe:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("TRADE_SHOW")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "TRADE_SHOW" then DTC.Bribe:OnTradeShow() end
    end)
end

-- 1. Sending an Offer
function DTC.Bribe:OfferBribe(targetPlayer, amount)
    if not targetPlayer or not amount or tonumber(amount) <= 0 then return end
    
    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_OFFER:"..payload, "WHISPER", targetPlayer)
    print("|cFF00FF00DTC:|r Offered " .. amount .. "g to " .. targetPlayer)
end

-- 2. Receiving an Offer
function DTC.Bribe:ReceiveOffer(sender, amount)
    -- Create an offer object
    local offer = {
        id = GetTime(), -- Unique ID based on time
        sender = sender,
        amount = tonumber(amount),
        timer = nil
    }
    
    -- Start 90s Timeout
    offer.timer = C_Timer.NewTimer(90, function() 
        DTC.Bribe:ExpireOffer(offer.id)
    end)
    
    table.insert(self.IncomingQueue, offer)
    
    -- Refresh UI to show this new offer
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

-- 3. Accepting/Declining
function DTC.Bribe:AcceptOffer(offerID)
    local offer, index = self:GetOffer(offerID)
    if not offer then return end
    
    -- Check if we have votes left
    if DTC.Vote and DTC.Vote.myVotesLeft > 0 then
        -- 1. Cast Vote
        DTC.Vote:CastVote(offer.sender)
        
        -- 2. Notify Sender (They pay) & Raid (Tracking)
        local payload = string.format("%s,%d", offer.sender, offer.amount) -- "Offerer,Amount"
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        
        print("|cFF00FF00DTC:|r Accepted bribe from " .. offer.sender)
    else
        print("|cFFFF0000DTC:|r Cannot accept bribe: No votes remaining!")
    end
    
    self:RemoveOffer(index)
end

function DTC.Bribe:DeclineOffer(offerID)
    local _, index = self:GetOffer(offerID)
    if index then self:RemoveOffer(index) end
    print("|cFFFF0000DTC:|r Declined bribe.")
end

function DTC.Bribe:ExpireOffer(offerID)
    local _, index = self:GetOffer(offerID)
    if index then 
        self:RemoveOffer(index) 
        -- Refresh UI in case the expired one was showing
        if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
    end
end

-- 4. Tracking & Trading
function DTC.Bribe:TrackBribe(offerer, recipient, amount)
    local entry = {
        offerer = offerer,
        recipient = recipient,
        amount = tonumber(amount),
        timestamp = date("%H:%M:%S")
    }
    table.insert(DTCRaidDB.bribes, entry)
    if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
end

function DTC.Bribe:InitiateTrade(player, amount)
    self.ActiveTrade = { target = player, amount = amount }
    
    if UnitExists("target") and UnitName("target") == player then
        InitiateTrade("target")
    else
        TargetUnit(player)
        -- We can't auto-initiate trade purely from code if not targeting, 
        -- but we can try if they are close. 
        -- User might need to click twice: Once to target, Once to trade.
        InitiateTrade("target") 
    end
end

function DTC.Bribe:OnTradeShow()
    if self.ActiveTrade then
        local target = UnitName("NPC") -- In trade window, 'NPC' returns the other player's name usually
        -- Note: UnitName("NPC") is a quirk, checking "target" is safer if we just targeted them.
        
        local money = self.ActiveTrade.amount * 10000 -- Convert Gold to Copper
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, money)
        self.ActiveTrade = nil -- Consume the auto-fill
    end
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

-- Wire up Comms
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, _, prefix, msg, _, sender)
    if prefix ~= DTC.PREFIX then return end
    local action, data = strsplit(":", msg, 2)
    
    if sender == UnitName("player") then return end -- Ignore self

    if action == "BRIBE_OFFER" then
        DTC.Bribe:ReceiveOffer(sender, data)
        
    elseif action == "BRIBE_FINAL" then
        -- Format: Offerer,Amount. Sender is the Recipient.
        local offerer, amount = strsplit(",", data)
        DTC.Bribe:TrackBribe(offerer, sender, amount)
    end
end)

DTC.Bribe:Init()

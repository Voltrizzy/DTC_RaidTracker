local folderName, DTC = ...
DTC.Bribe = {}

-- State
DTC.Bribe.IncomingQueue = {} 
DTC.Bribe.PropositionQueue = {} 
DTC.Bribe.LobbyQueue = {} 
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
    
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot offer bribe. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local payload = string.format("%d", amount)
    local fullTarget = self:GetFullName(targetPlayer)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_OFFER:"..payload, "WHISPER", fullTarget)
    print("|cFF00FF00DTC:|r Offered " .. amount .. "g to " .. targetPlayer)
end

function DTC.Bribe:ReceiveOffer(sender, amount)
    if DTC.Vote and (DTC.Vote.myVotesLeft <= 0 or not DTC.Vote.isOpen) then return end
    local duration = DTCRaidDB.settings.bribeTimer or 90
    local offer = { id = GetTime() .. "-" .. sender, sender = sender, amount = tonumber(amount), timer = nil, startTime = GetTime() }
    offer.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireOffer(offer.id) end)
    table.insert(self.IncomingQueue, offer)
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
end

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
        local payload = string.format("%s,%d,%s,BRIBE", offer.sender, offer.amount, (boss:gsub(",", "")))
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        print("|cFF00FF00DTC:|r Accepted bribe from " .. offer.sender)
        self:TrackBribe(offer.sender, UnitName("player"), offer.amount, boss, "BRIBE")
        if DTC.Vote.myVotesLeft <= 0 then self:DeclineAll() end
    end
    self:RemoveOffer(index)
end

function DTC.Bribe:DeclineOffer(offerID)
    local _, index = self:GetOffer(offerID)
    if index then self:RemoveOffer(index) end
end

function DTC.Bribe:ExpireOffer(id)
    local _, index = self:GetOffer(id)
    if index then self:RemoveOffer(index) end
end

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
function DTC.Bribe:SendProposition(amount)
    if not amount or tonumber(amount) <= 0 then return end
    self.MyCurrentPropPrice = tonumber(amount)
    if not DTC.Vote or not DTC.Vote.isOpen then print("Voting is closed."); return end
    if DTC.Vote.myVotesLeft <= 0 then print("No votes left to sell!"); return end
    
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist! Cannot incur tax."); return end
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot send proposition. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local payload = string.format("%d", amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_OFFER:"..payload, "RAID")
    print("|cFF00FF00DTC:|r Proposition broadcast: My vote for " .. amount .. "g.")
end

function DTC.Bribe:ReceiveProposition(offerer, amount)
    if not DTC.Vote or not DTC.Vote.isOpen then return end
    if offerer == UnitName("player") then return end
    local votesUsed = DTC.Vote:GetVotesCastBy(offerer)
    if votesUsed >= 3 then return end
    local duration = DTCRaidDB.settings.propTimer or 90
    local prop = { 
        id = GetTime() .. "-" .. offerer, 
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

function DTC.Bribe:AcceptProposition(propID)
    local prop = self:GetProposition(propID)
    if not prop then return end
    if not DTC.Vote or not DTC.Vote.isOpen then print("Voting is closed."); return end
    
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist!"); return end
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot accept proposition. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local fullTarget = self:GetFullName(prop.offerer)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PROP_ACCEPT", "WHISPER", fullTarget)
end

function DTC.Bribe:OnPropositionAcceptedByMe(buyerName)
    if not DTC.Vote or not DTC.Vote.isOpen then return end
    if DTC.Vote.myVotesLeft > 0 then
        DTC.Vote:CastVote(buyerName)
        local price = self.MyCurrentPropPrice or 0 
        local boss = DTC.Vote.currentBoss or "Unknown"
        local payload = string.format("%s,%d,%s,PROP", buyerName, price, (boss:gsub(",", "")))
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        print("|cFF00FF00DTC:|r Proposition accepted by " .. buyerName .. ". Vote cast!")
        self:TrackBribe(buyerName, UnitName("player"), price, boss, "PROP")
    end
end

-- =========================================================
-- 3. LOBBYING LOGIC
-- =========================================================
function DTC.Bribe:SendLobby(candidate, amount)
    if not candidate or not amount or tonumber(amount) <= 0 then return end
    if not DTC.Vote or not DTC.Vote.isOpen then print("Voting is closed."); return end
    if self:HasUnpaidDebt() then print("|cFFFF0000DTC:|r Unpaid debts exist! Cannot incur debt/tax."); return end
    
    local limit = DTCRaidDB.settings.debtLimit or 0
    if limit > 0 and self:GetTotalDebt() >= limit then
        print("|cFFFF0000DTC:|r Cannot lobby. Total debt exceeds limit ("..limit.."g)."); return
    end
    
    local payload = string.format("%s,%d", candidate, amount)
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "LOBBY_OFFER:"..payload, "RAID")
    print("|cFF00FF00DTC:|r Lobbying for " .. candidate .. " (" .. amount .. "g) broadcast to raid.")
end

function DTC.Bribe:ReceiveLobby(lobbyist, candidate, amount)
    if lobbyist == UnitName("player") then return end
    if DTC.Vote and (DTC.Vote.myVotesLeft <= 0 or not DTC.Vote.isOpen) then return end
    
    local duration = DTCRaidDB.settings.lobbyTimer or 120
    local lobby = { 
        id = GetTime() .. "-" .. lobbyist .. "-" .. candidate,
        lobbyist = lobbyist, 
        candidate = candidate, 
        amount = tonumber(amount), 
        timer = nil,
        startTime = GetTime(),
        duration = duration
    }
    lobby.timer = C_Timer.NewTimer(duration, function() DTC.Bribe:ExpireLobby(lobby.id) end)
    table.insert(self.LobbyQueue, lobby)
    if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
end

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
        local payload = string.format("%s,%d,%s,LOBBY", lobby.lobbyist, lobby.amount, (boss:gsub(",", "")))
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "BRIBE_FINAL:"..payload, "RAID")
        print("|cFF00FF00DTC:|r Accepted Lobby from " .. lobby.lobbyist .. " to vote for " .. lobby.candidate)
        self:TrackBribe(lobby.lobbyist, UnitName("player"), lobby.amount, boss, "LOBBY")
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
-- 4. HELPERS
-- =========================================================
function DTC.Bribe:TrackBribe(offerer, recipient, amount, boss, bType)
    boss = (boss or "Unknown"):gsub(",", "")
    local ts = date("%Y-%m-%d %H:%M:%S")
    local entry = { offerer = offerer, recipient = recipient, amount = tonumber(amount), boss = boss, paid = false, timestamp = ts }
    table.insert(DTCRaidDB.bribes, entry)
    
    -- Corruption Fee Logic
    local feePct = DTCRaidDB.settings.corruptionFee or 10
    if feePct > 0 then
        local fee = math.floor(tonumber(amount) * (feePct / 100))
        if fee > 0 then
            local leader = self:GetLeaderName()
            if leader then
                local feePayer = nil
                if bType == "BRIBE" or bType == "PROP" then
                    feePayer = recipient -- Receiver of funds (Voter) pays the tax
                elseif bType == "LOBBY" then
                    feePayer = offerer -- Funder of lobby pays the tax
                end
                if feePayer and feePayer ~= leader then
                    local feeEntry = { offerer = feePayer, recipient = leader, amount = fee, boss = (boss or "Unknown") .. " (Tax)", paid = false, timestamp = ts }
                    table.insert(DTCRaidDB.bribes, feeEntry)
                end
            end
        end
    end
    
    if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
end

function DTC.Bribe:DeclineAll()
    for _, offer in ipairs(self.IncomingQueue) do if offer.timer then offer.timer:Cancel() end end
    self.IncomingQueue = {}
    if DTC.BribeUI then DTC.BribeUI:ShowNextOffer() end
    
    for _, lobby in ipairs(self.LobbyQueue) do if lobby.timer then lobby.timer:Cancel() end end
    self.LobbyQueue = {}
    if DTC.BribeUI then DTC.BribeUI:UpdateLobbyList() end
end

function DTC.Bribe:HasUnpaidDebt(target)
    local myName = target or UnitName("player")
    local currentBoss = DTC.Vote and DTC.Vote.currentBoss or "Unknown"
    for _, entry in ipairs(DTCRaidDB.bribes) do
        if entry.offerer == myName and not entry.paid and entry.boss ~= currentBoss then return true end
    end
    return false
end

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
            if entry then 
                entry.paid = true
                PlaySound(1203) -- SOUNDKIT.IG_BACKPACK_COIN_OK
                if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
                
                -- Sync payment status to raid
                local payload = string.format("%s,%s,%d,%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
                C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID")
            end
        end
    end
    self.ActiveTrade = nil
end

function DTC.Bribe:CheckPropositionValidity()
    if not DTC.Vote then return end
    local changed = false
    for i = #self.PropositionQueue, 1, -1 do
        local p = self.PropositionQueue[i]
        local votes = DTC.Vote:GetVotesCastBy(p.offerer)
        if votes >= 3 then if p.timer then p.timer:Cancel() end; table.remove(self.PropositionQueue, i); changed = true end
    end
    if changed and DTC.BribeUI then DTC.BribeUI:UpdatePropositionList() end
end

function DTC.Bribe:AnnounceDebts()
    local debts = {}
    for _, entry in ipairs(DTCRaidDB.bribes or {}) do
        if not entry.paid then table.insert(debts, entry) end
    end
    
    if #debts == 0 then
        print("|cFF00FF00DTC:|r No outstanding debts found.")
        return
    end
    
    local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or "PRINT")
    local header = "--- DTC Debt Report ---"
    if channel == "PRINT" then print(header) else SendChatMessage(header, channel) end
    
    for _, d in ipairs(debts) do
        local msg = string.format("%s owes %s %dg (%s)", d.offerer, d.recipient, d.amount, d.boss)
        if channel == "PRINT" then print(msg) else SendChatMessage(msg, channel) end
    end
end

function DTC.Bribe:PayAllTaxes()
    local count = 0
    for _, entry in ipairs(DTCRaidDB.bribes or {}) do
        if not entry.paid and entry.boss and string.find(entry.boss, "%(Tax%)") and entry.recipient == UnitName("player") then
            entry.paid = true
            count = count + 1
            
            -- Sync payment status to raid
            local payload = string.format("%s,%s,%d,%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
            C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID")
        end
    end
    if count > 0 then
        print("|cFF00FF00DTC:|r Marked " .. count .. " tax debts as paid.")
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
    else
        print("|cFFFF0000DTC:|r No outstanding tax debts found.")
    end
end

function DTC.Bribe:ForgiveDebt(index)
    local entry = DTCRaidDB.bribes[index]
    if entry then
        if entry.recipient ~= UnitName("player") then return end
        entry.paid = true
        print("|cFF00FF00DTC:|r You forgave the debt of " .. entry.offerer .. " (" .. entry.amount .. "g).")
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
        
        -- Sync payment status to raid
        local payload = string.format("%s,%s,%d,%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID")
    end
end

function DTC.Bribe:MarkDebtPaid(index)
    local entry = DTCRaidDB.bribes[index]
    if entry then
        if entry.recipient ~= UnitName("player") then return end
        entry.paid = true
        print("|cFF00FF00DTC:|r Manually marked debt from " .. entry.offerer .. " as PAID.")
        if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
        
        -- Sync payment status to raid
        local payload = string.format("%s,%s,%d,%s", entry.offerer, entry.recipient, entry.amount, entry.boss)
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "DEBT_PAID:"..payload, "RAID")
    end
end

function DTC.Bribe:GetLeaderName()
    if not IsInGroup() then return UnitName("player") end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if rank == 2 then
                if name and string.find(name, "-") then name = strsplit("-", name) end
                return name
            end
        end
    else
        if UnitIsGroupLeader("player") then return UnitName("player") end
        for i=1, 4 do
            if UnitIsGroupLeader("party"..i) then
                local name = UnitName("party"..i)
                if name and string.find(name, "-") then name = strsplit("-", name) end
                return name
            end
        end
    end
    return UnitName("player")
end

function DTC.Bribe:GetFullName(shortName)
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

function DTC.Bribe:OnComm(action, data, sender)
    -- Sender sanitization handled by Core or passed raw? Core passes raw.
    if sender and string.find(sender, "-") then sender = strsplit("-", sender) end
    if sender == UnitName("player") then return end 

    if action == "BRIBE_OFFER" then DTC.Bribe:ReceiveOffer(sender, data)
    elseif action == "PROP_OFFER" then DTC.Bribe:ReceiveProposition(sender, data)
    elseif action == "PROP_ACCEPT" then DTC.Bribe:OnPropositionAcceptedByMe(sender)
    elseif action == "LOBBY_OFFER" then 
        local cand, amt = strsplit(",", data)
        DTC.Bribe:ReceiveLobby(sender, cand, amt)
    elseif action == "BRIBE_FINAL" then 
        local offerer, amount, boss, bType = strsplit(",", data)
        DTC.Bribe:TrackBribe(offerer, sender, amount, boss, bType)
    elseif action == "DEBT_PAID" then
        local offerer, recipient, amount, boss = strsplit(",", data, 4)
        amount = tonumber(amount)
        for _, e in ipairs(DTCRaidDB.bribes) do
            if e.offerer == offerer and e.recipient == recipient and e.amount == amount and e.boss == boss and not e.paid then
                e.paid = true
                if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
                break
            end
        end
    elseif action == "VOTE" then C_Timer.After(0.5, function() DTC.Bribe:CheckPropositionValidity() end) end
end

DTC.Bribe:Init()

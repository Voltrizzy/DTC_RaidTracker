local folderName, DTC = ...
DTC.BribeUI = {}

function DTC.BribeUI:Init()
    -- 1. Send Bribe
    self.OfferFrame = DTC_BribeOfferPopup
    self.OfferFrame.ConfirmBtn:SetScript("OnClick", function()
        DTC.Bribe:OfferBribe(self.OfferFrame.target, self.OfferFrame.AmountBox:GetText())
        self.OfferFrame:Hide()
    end)
    self.OfferFrame.CancelBtn:SetScript("OnClick", function() self.OfferFrame:Hide() end)
    if self.OfferFrame.SetTitle then self.OfferFrame:SetTitle("Commerce") end

    -- 2. Proposition Input
    self.PropInputFrame = DTC_PropositionInputPopup
    self.PropInputFrame.ConfirmBtn:SetScript("OnClick", function()
        local amt = self.PropInputFrame.AmountBox:GetText()
        DTC.Bribe.MyCurrentPropPrice = tonumber(amt) -- Store for later
        DTC.Bribe:SendProposition(amt)
        self.PropInputFrame:Hide()
    end)
    self.PropInputFrame.CancelBtn:SetScript("OnClick", function() self.PropInputFrame:Hide() end)
    if self.PropInputFrame.SetTitle then self.PropInputFrame:SetTitle("Proposition Bribe") end

    -- 3. Proposition List
    self.PropListFrame = DTC_PropositionListFrame
    if self.PropListFrame.SetTitle then self.PropListFrame:SetTitle("Active Propositions") end

    -- 4. Incoming Bribe
    self.IncomingFrame = DTC_BribeIncomingPopup
    self.IncomingFrame.AcceptBtn:SetScript("OnClick", function() if self.CurrentOfferID then DTC.Bribe:AcceptOffer(self.CurrentOfferID) end end)
    self.IncomingFrame.DeclineBtn:SetScript("OnClick", function() if self.CurrentOfferID then DTC.Bribe:DeclineOffer(self.CurrentOfferID) end end)

    -- 5. Tracker
    self.TrackerFrame = DTC_BribeTrackerFrame
    if self.TrackerFrame.SetTitle then self.TrackerFrame:SetTitle("Bribe History") end
    self.TrackerFrame.ClearBtn:SetScript("OnClick", function() DTCRaidDB.bribes = {}; self:UpdateTracker() end)
    
    -- NEW: 6. Lobby Input
    self.LobbyInputFrame = DTC_LobbyInputPopup
    self.LobbyInputFrame.ConfirmBtn:SetScript("OnClick", function()
        local amt = self.LobbyInputFrame.AmountBox:GetText()
        local cand = self.LobbyInputFrame.candidate
        DTC.Bribe:SendLobby(cand, amt)
        self.LobbyInputFrame:Hide()
    end)
    self.LobbyInputFrame.CancelBtn:SetScript("OnClick", function() self.LobbyInputFrame:Hide() end)
    if self.LobbyInputFrame.SetTitle then self.LobbyInputFrame:SetTitle("Lobbying") end
    
    -- NEW: 7. Lobby List
    self.LobbyListFrame = DTC_LobbyListFrame
    if self.LobbyListFrame.SetTitle then self.LobbyListFrame:SetTitle("Lobbying Offers") end
    
end

-- --- OPENERS ---
function DTC.BribeUI:OpenOfferWindow(targetName)
    if not self.OfferFrame then self:Init() end
    self.OfferFrame.target = targetName
    self.OfferFrame.AmountBox:SetText(""); self.OfferFrame.AmountBox:SetFocus()
    self.OfferFrame.Title:SetText("Bribe: " .. targetName)
    self.OfferFrame:Show()
end

function DTC.BribeUI:OpenPropInput()
    if not self.PropInputFrame then self:Init() end
    self.PropInputFrame.AmountBox:SetText(""); self.PropInputFrame.AmountBox:SetFocus()
    self.PropInputFrame:Show()
end

function DTC.BribeUI:ShowNextOffer()
    if not self.IncomingFrame then self:Init() end
    if #DTC.Bribe.IncomingQueue == 0 then self.IncomingFrame:Hide(); self.CurrentOfferID = nil; return end
    local offer = DTC.Bribe.IncomingQueue[1]
    self.CurrentOfferID = offer.id
    self.IncomingFrame.Desc:SetText(string.format("|cFFFFD700%s|r offers you |cFFFFD700%d Gold|r", offer.sender, offer.amount))
    self.IncomingFrame:Show()
end

-- --- LIST UPDATES ---
function DTC.BribeUI:UpdatePropositionList()
    if not self.PropListFrame then self:Init() end
    local list = DTC.Bribe.PropositionQueue
    
    -- Show window if items exist
    if #list > 0 then self.PropListFrame:Show() else self.PropListFrame:Hide() end
    
    local content = self.PropListFrame.ListScroll.Content
    local kids = {content:GetChildren()}; for _, k in ipairs(kids) do k:Hide(); k:SetParent(nil) end
    
    local yOffset = 0
    for _, prop in ipairs(list) do
        local row = CreateFrame("Frame", nil, content, "DTC_PropRowTemplate")
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        row.Text:SetText(prop.offerer .. " (" .. prop.amount .. "g)")
        
        row.AcceptBtn:SetScript("OnClick", function() DTC.Bribe:AcceptProposition(prop.id) end)
        row.DeclineBtn:SetScript("OnClick", function() 
             -- Local hide only? Or ignore?
             -- Usually "Decline" just hides it from MY screen.
             -- For now let's just trigger a "remove from my list" visual
             DTC.Bribe:ExpireProposition(prop.id)
        end)
        
        -- Logic: If offerer has no votes left (should be caught by model check, but double check here)
        local votes = DTC.Vote:GetVotesCastBy(prop.offerer)
        if votes >= 3 then row.AcceptBtn:Disable() else row.AcceptBtn:Enable() end

        yOffset = yOffset - 25
    end
end

-- NEW
function DTC.BribeUI:UpdateLobbyList()
    if not self.LobbyListFrame then self:Init() end
    local list = DTC.Bribe.LobbyQueue
    if #list > 0 then self.LobbyListFrame:Show() else self.LobbyListFrame:Hide() end
    
    local content = self.LobbyListFrame.ListScroll.Content
    local kids = {content:GetChildren()}; for _, k in ipairs(kids) do k:Hide(); k:SetParent(nil) end
    
    local yOffset = 0
    for _, lobby in ipairs(list) do
        local row = CreateFrame("Frame", nil, content, "DTC_LobbyRowTemplate")
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        -- Text: "[Lobbyist] pays [Amt] for [Candidate]"
        local txt = string.format("|cFFFFD700%s|r pays |cFFFFD700%dg|r for |cFF00FF00%s|r", lobby.lobbyist, lobby.amount, lobby.candidate)
        row.Text:SetText(txt)
        
        row.AcceptBtn:SetScript("OnClick", function() DTC.Bribe:AcceptLobby(lobby.id) end)
        row.DeclineBtn:SetScript("OnClick", function() DTC.Bribe:ExpireLobby(lobby.id) end)
        
        -- Logic: Disable if I have no votes
        if DTC.Vote and DTC.Vote.myVotesLeft > 0 then row.AcceptBtn:Enable() else row.AcceptBtn:Disable() end
        
        yOffset = yOffset - 25
    end
end

function DTC.BribeUI:ToggleTracker()
    if not self.TrackerFrame then self:Init() end
    if self.TrackerFrame:IsShown() then self.TrackerFrame:Hide() else self.TrackerFrame:Show(); self:UpdateTracker() end
end

function DTC.BribeUI:UpdateTracker()
    if not self.TrackerFrame or not self.TrackerFrame:IsShown() then return end
    local content = self.TrackerFrame.ListScroll.Content
    local kids = {content:GetChildren()}; for _, k in ipairs(kids) do k:Hide(); k:SetParent(nil) end
    local yOffset = 0
    local data = DTCRaidDB.bribes or {}
    local sorted = {}; for i, e in ipairs(data) do e.originalIndex=i; table.insert(sorted, e) end
    table.sort(sorted, function(a,b) return a.timestamp > b.timestamp end)
    for _, entry in ipairs(sorted) do
        local row = CreateFrame("Frame", nil, content, "DTC_BribeRowTemplate")
        row:SetPoint("TOPLEFT", 0, yOffset)
        local txt = string.format("%s -> %s (%s)", entry.offerer, entry.recipient, entry.boss or "?")
        row.Text:SetText(txt)
        local status = entry.paid and "|cFF00FF00PAID|r" or "|cFFFF0000OWED|r"
        row.Amount:SetText(entry.amount .. "g  " .. status)
        row.TradeBtn:SetScript("OnClick", function()
            if entry.offerer == UnitName("player") then DTC.Bribe:InitiateTrade(entry.recipient, entry.amount, entry.originalIndex)
            elseif entry.recipient == UnitName("player") then DTC.Bribe:InitiateTrade(entry.offerer, 0, nil) 
            else DTC.Bribe:InitiateTrade(entry.recipient, 0, nil) end
        end)
        if entry.paid then row.TradeBtn:Disable() else row.TradeBtn:Enable() end
        yOffset = yOffset - 25
    end
end

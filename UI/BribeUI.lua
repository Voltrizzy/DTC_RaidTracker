local folderName, DTC = ...
DTC.BribeUI = {}

function DTC.BribeUI:Init()
    -- Offer Popup Init
    self.OfferFrame = DTC_BribeOfferPopup
    self.OfferFrame.ConfirmBtn:SetScript("OnClick", function()
        local amt = self.OfferFrame.AmountBox:GetText()
        local target = self.OfferFrame.target
        DTC.Bribe:OfferBribe(target, amt)
        self.OfferFrame:Hide()
    end)
    self.OfferFrame.CancelBtn:SetScript("OnClick", function() self.OfferFrame:Hide() end)
    if self.OfferFrame.SetTitle then self.OfferFrame:SetTitle("Commerce") end

    -- Incoming Popup Init
    self.IncomingFrame = DTC_BribeIncomingPopup
    self.IncomingFrame.AcceptBtn:SetScript("OnClick", function()
        if self.CurrentOfferID then DTC.Bribe:AcceptOffer(self.CurrentOfferID) end
    end)
    self.IncomingFrame.DeclineBtn:SetScript("OnClick", function()
        if self.CurrentOfferID then DTC.Bribe:DeclineOffer(self.CurrentOfferID) end
    end)
    if self.IncomingFrame.SetTitle then self.IncomingFrame:SetTitle("Incoming Bribe") end

    -- Tracker Init
    self.TrackerFrame = DTC_BribeTrackerFrame
    if self.TrackerFrame.SetTitle then self.TrackerFrame:SetTitle("Bribe History") end
    self.TrackerFrame.ClearBtn:SetScript("OnClick", function() 
        DTCRaidDB.bribes = {} 
        self:UpdateTracker() 
    end)
end

function DTC.BribeUI:OpenOfferWindow(targetName)
    if not self.OfferFrame then self:Init() end
    self.OfferFrame.target = targetName
    self.OfferFrame.AmountBox:SetText("")
    self.OfferFrame.AmountBox:SetFocus()
    self.OfferFrame.Title:SetText("Bribe: " .. targetName)
    self.OfferFrame:Show()
end

function DTC.BribeUI:ShowNextOffer()
    if not self.IncomingFrame then self:Init() end
    
    if #DTC.Bribe.IncomingQueue == 0 then
        self.IncomingFrame:Hide()
        self.CurrentOfferID = nil
        return
    end
    
    local offer = DTC.Bribe.IncomingQueue[1]
    self.CurrentOfferID = offer.id
    
    self.IncomingFrame.Desc:SetText(string.format("|cFFFFD700%s|r offers you |cFFFFD700%d Gold|r", offer.sender, offer.amount))
    self.IncomingFrame:Show()
end

function DTC.BribeUI:ToggleTracker()
    if not self.TrackerFrame then self:Init() end
    if self.TrackerFrame:IsShown() then self.TrackerFrame:Hide() else self.TrackerFrame:Show(); self:UpdateTracker() end
end

function DTC.BribeUI:UpdateTracker()
    if not self.TrackerFrame or not self.TrackerFrame:IsShown() then return end
    
    local content = self.TrackerFrame.ListScroll.Content
    local kids = {content:GetChildren()}
    for _, k in ipairs(kids) do k:Hide(); k:SetParent(nil) end
    
    local yOffset = 0
    local data = DTCRaidDB.bribes or {}
    
    -- Reverse sort to show newest first
    local sorted = {}
    for i, e in ipairs(data) do 
        e.originalIndex = i -- keep track of DB index
        table.insert(sorted, e) 
    end
    table.sort(sorted, function(a,b) return a.timestamp > b.timestamp end)
    
    for _, entry in ipairs(sorted) do
        local row = CreateFrame("Frame", nil, content, "DTC_BribeRowTemplate")
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        -- Text: Offerer -> Recipient (Boss)
        local txt = string.format("%s -> %s (%s)", entry.offerer, entry.recipient, entry.boss or "?")
        row.Text:SetText(txt)
        
        -- Amount & Status
        local status = entry.paid and "|cFF00FF00PAID|r" or "|cFFFF0000OWED|r"
        row.Amount:SetText(entry.amount .. "g  " .. status)
        
        -- Trade Button Logic
        row.TradeBtn:SetScript("OnClick", function()
            -- If I am the Offerer AND it's unpaid, this button helps me pay.
            -- We pass 'entry.originalIndex' so we can mark it paid when trade closes.
            if entry.offerer == UnitName("player") then
                DTC.Bribe:InitiateTrade(entry.recipient, entry.amount, entry.originalIndex)
            elseif entry.recipient == UnitName("player") then
                DTC.Bribe:InitiateTrade(entry.offerer, 0, nil) 
            else
                DTC.Bribe:InitiateTrade(entry.recipient, 0, nil)
            end
        end)
        
        -- Hide Trade button if paid? Or leave it open? 
        -- Leaving enabled is safer in case the "Auto Mark Paid" logic missed it.
        if entry.paid then row.TradeBtn:Disable() else row.TradeBtn:Enable() end
        
        yOffset = yOffset - 25
    end
end

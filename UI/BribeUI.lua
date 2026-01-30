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
    if self.TrackerFrame.SetTitle then self.TrackerFrame:SetTitle("Bribe Tracker") end
    self.TrackerFrame.ClearBtn:SetScript("OnClick", function() 
        DTCRaidDB.bribes = {} 
        self:UpdateTracker() 
    end)
end

-- OFFER FLOW
function DTC.BribeUI:OpenOfferWindow(targetName)
    if not self.OfferFrame then self:Init() end
    self.OfferFrame.target = targetName
    self.OfferFrame.AmountBox:SetText("")
    self.OfferFrame.AmountBox:SetFocus()
    self.OfferFrame.Title:SetText("Bribe: " .. targetName)
    self.OfferFrame:Show()
end

-- INCOMING FLOW
function DTC.BribeUI:ShowNextOffer()
    if not self.IncomingFrame then self:Init() end
    
    if #DTC.Bribe.IncomingQueue == 0 then
        self.IncomingFrame:Hide()
        self.CurrentOfferID = nil
        return
    end
    
    local offer = DTC.Bribe.IncomingQueue[1] -- Show oldest first
    self.CurrentOfferID = offer.id
    
    self.IncomingFrame.Desc:SetText(string.format("|cFFFFD700%s|r offers you |cFFFFD700%d Gold|r", offer.sender, offer.amount))
    self.IncomingFrame:Show()
end

-- TRACKER FLOW
function DTC.BribeUI:ToggleTracker()
    if not self.TrackerFrame then self:Init() end
    if self.TrackerFrame:IsShown() then self.TrackerFrame:Hide() else self.TrackerFrame:Show(); self:UpdateTracker() end
end

function DTC.BribeUI:UpdateTracker()
    if not self.TrackerFrame or not self.TrackerFrame:IsShown() then return end
    
    -- Clean existing
    local content = self.TrackerFrame.ListScroll.Content
    local kids = {content:GetChildren()}
    for _, k in ipairs(kids) do k:Hide(); k:SetParent(nil) end
    
    local yOffset = 0
    local data = DTCRaidDB.bribes or {}
    
    for i, entry in ipairs(data) do
        local row = CreateFrame("Frame", nil, content, "DTC_BribeRowTemplate")
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        local txt = string.format("%s -> %s", entry.offerer, entry.recipient)
        row.Text:SetText(txt)
        row.Amount:SetText(entry.amount .. "g")
        
        -- Logic for Trade Button:
        -- Only enable if *I* am the offerer, and I'm targeting the recipient (or logic to help targeting)
        row.TradeBtn:SetScript("OnClick", function()
            -- If I am the offerer, I need to pay the recipient
            if entry.offerer == UnitName("player") then
                DTC.Bribe:InitiateTrade(entry.recipient, entry.amount)
            elseif entry.recipient == UnitName("player") then
                -- If I am the recipient, maybe I want to trade to demand money? 
                DTC.Bribe:InitiateTrade(entry.offerer, 0) -- Don't autofill money if receiving
            else
                -- Just open trade with whoever
                DTC.Bribe:InitiateTrade(entry.recipient, 0)
            end
        end)
        
        yOffset = yOffset - 25
    end
end

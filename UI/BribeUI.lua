-- ============================================================================
-- DTC Raid Tracker - UI/BribeUI.lua
-- ============================================================================
-- This file manages the various UI components for the Bribe module, including
-- offer popups, the Bribe Ledger (Tracker), and Lobby/Proposition lists.

local folderName, DTC = ...
DTC.BribeUI = {}

local function InjectTitle(f)
    if not f then return end
    if not f.SetTitle then
        -- Prefer existing Title (XML) or TitleText (Template)
        local target = f.Title or f.TitleText
        -- If both exist (e.g. Popups), hide the Template one to prevent overlap
        if f.Title and f.TitleText then f.TitleText:SetText(""); f.TitleText:Hide() end
        
        if not target then
            target = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            target:SetPoint("TOP", 0, -5)
        end
        f.SetTitle = function(self, text) target:SetText(text) end
    end
end

-- Initializes all Bribe UI frames and scripts.
function DTC.BribeUI:Init()
    -- 1. Send Bribe
    self.OfferFrame = DTC_BribeOfferPopup
    if self.OfferFrame then
        InjectTitle(self.OfferFrame)
        self.OfferFrame.ConfirmBtn:SetScript("OnClick", function()
            DTC.Bribe:OfferBribe(self.OfferFrame.target, self.OfferFrame.AmountBox:GetText())
            self.OfferFrame:Hide()
        end)
        self.OfferFrame.CancelBtn:SetScript("OnClick", function() self.OfferFrame:Hide() end)
        if self.OfferFrame.SetTitle then self.OfferFrame:SetTitle("DTC Tracker - Bribe Offer") end
    end

    -- 2. Proposition Input
    self.PropInputFrame = DTC_PropositionInputPopup
    if self.PropInputFrame then
        InjectTitle(self.PropInputFrame)
        self.PropInputFrame.ConfirmBtn:SetScript("OnClick", function()
            local amt = self.PropInputFrame.AmountBox:GetText()
            DTC.Bribe.MyCurrentPropPrice = tonumber(amt) -- Store for later
            DTC.Bribe:SendProposition(amt)
            self.PropInputFrame:Hide()
        end)
        self.PropInputFrame.CancelBtn:SetScript("OnClick", function() self.PropInputFrame:Hide() end)
        if self.PropInputFrame.SetTitle then self.PropInputFrame:SetTitle("Proposition Bribe") end
    end

    -- 3. Proposition List
    self.PropListFrame = DTC_PropositionListFrame
    InjectTitle(self.PropListFrame)
    if self.PropListFrame and self.PropListFrame.SetTitle then self.PropListFrame:SetTitle("DTC Tracker - Proposition") end

    -- 4. Incoming Bribe
    self.IncomingFrame = DTC_BribeIncomingPopup
    if self.IncomingFrame then
        InjectTitle(self.IncomingFrame)
        self.IncomingFrame.AcceptBtn:SetScript("OnClick", function() if self.CurrentOfferID then DTC.Bribe:AcceptOffer(self.CurrentOfferID) end end)
        self.IncomingFrame.DeclineBtn:SetScript("OnClick", function() if self.CurrentOfferID then DTC.Bribe:DeclineOffer(self.CurrentOfferID) end end)
        
        if self.IncomingFrame.TimerBar then
            self.IncomingFrame.TimerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self.IncomingFrame.TimerBar:SetStatusBarColor(0.5, 0.05, 0.05)
        end
    end

    -- 5. Tracker
    self.TrackerFrame = DTC_BribeTrackerFrame
    if self.TrackerFrame then
        InjectTitle(self.TrackerFrame)
        if self.TrackerFrame.SetTitle then self.TrackerFrame:SetTitle("DTC Tracker - Bribe Ledger") end
        self.TrackerFrame.ClearBtn:SetScript("OnClick", function() StaticPopup_Show("DTC_CLEAR_BRIBES_CONFIRM") end)
        
        -- NEW: Filter Dropdown
        self.TrackerFrame.FilterDD = CreateFrame("Frame", "DTC_BribeTrackerFilterDD", self.TrackerFrame, "UIDropDownMenuTemplate")
        self.TrackerFrame.FilterDD:SetPoint("TOPLEFT", 10, -25)
        UIDropDownMenu_SetWidth(self.TrackerFrame.FilterDD, 150)
        UIDropDownMenu_Initialize(self.TrackerFrame.FilterDD, function(frame, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) self.FilterMode = s.arg1; UIDropDownMenu_SetText(frame, s.value); self:UpdateTracker() end
            
            info.text, info.arg1, info.value = "All", "ALL", "All"; info.checked = (self.FilterMode == "ALL"); UIDropDownMenu_AddButton(info, level)
            info.text, info.arg1, info.value = "My Debts", "OWE", "My Debts"; info.checked = (self.FilterMode == "OWE"); UIDropDownMenu_AddButton(info, level)
            info.text, info.arg1, info.value = "Debts Owed to Me", "OWED", "Debts Owed to Me"; info.checked = (self.FilterMode == "OWED"); UIDropDownMenu_AddButton(info, level)
        end)
        UIDropDownMenu_SetText(self.TrackerFrame.FilterDD, "All")
        self.FilterMode = "ALL"

        -- NEW: Sort Dropdown
        self.TrackerFrame.SortDD = CreateFrame("Frame", "DTC_BribeTrackerSortDD", self.TrackerFrame, "UIDropDownMenuTemplate")
        self.TrackerFrame.SortDD:SetPoint("LEFT", self.TrackerFrame.FilterDD, "RIGHT", -20, 0)
        UIDropDownMenu_SetWidth(self.TrackerFrame.SortDD, 110)
        UIDropDownMenu_Initialize(self.TrackerFrame.SortDD, function(frame, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) self.SortMode = s.arg1; UIDropDownMenu_SetText(frame, s.value); self:UpdateTracker() end
            
            info.text, info.arg1, info.value = "Date (Newest)", "DATE_DESC", "Date (Newest)"; info.checked = (self.SortMode == "DATE_DESC"); UIDropDownMenu_AddButton(info, level)
            info.text, info.arg1, info.value = "Date (Oldest)", "DATE_ASC", "Date (Oldest)"; info.checked = (self.SortMode == "DATE_ASC"); UIDropDownMenu_AddButton(info, level)
            info.text, info.arg1, info.value = "Amount (High)", "AMT_DESC", "Amount (High)"; info.checked = (self.SortMode == "AMT_DESC"); UIDropDownMenu_AddButton(info, level)
            info.text, info.arg1, info.value = "Amount (Low)", "AMT_ASC", "Amount (Low)"; info.checked = (self.SortMode == "AMT_ASC"); UIDropDownMenu_AddButton(info, level)
        end)
        UIDropDownMenu_SetText(self.TrackerFrame.SortDD, "Date (Newest)")
        self.SortMode = "DATE_DESC"

        -- NEW: Search Dropdown
        self.TrackerFrame.SearchDD = CreateFrame("Frame", "DTC_BribeTrackerSearchDD", self.TrackerFrame, "UIDropDownMenuTemplate")
        self.TrackerFrame.SearchDD:SetPoint("LEFT", self.TrackerFrame.SortDD, "RIGHT", -10, 0)
        UIDropDownMenu_SetWidth(self.TrackerFrame.SearchDD, 120)
        UIDropDownMenu_Initialize(self.TrackerFrame.SearchDD, function(frame, level)
            local info = UIDropDownMenu_CreateInfo()
            
            info.text = "All Names"
            info.value = nil
            info.func = function(s) 
                self.SearchFilter = nil
                UIDropDownMenu_SetText(frame, "All Names")
                self:UpdateTracker() 
            end
            info.checked = (self.SearchFilter == nil)
            UIDropDownMenu_AddButton(info, level)
            
            local names = {}
            local seen = {}
            local data = DTCRaidDB.bribes or {}
            for _, e in ipairs(data) do
                if e.offerer and not seen[e.offerer] then table.insert(names, e.offerer); seen[e.offerer] = true end
                if e.recipient and not seen[e.recipient] then table.insert(names, e.recipient); seen[e.recipient] = true end
            end
            table.sort(names)
            
            for _, n in ipairs(names) do
                info.text = DTC:GetColoredName(n)
                info.value = n
                info.func = function(s) 
                    self.SearchFilter = s.value
                    UIDropDownMenu_SetText(frame, DTC:GetColoredName(s.value))
                    self:UpdateTracker() 
                end
                info.checked = (self.SearchFilter == n)
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetText(self.TrackerFrame.SearchDD, "All Names")

        -- NEW: Total Debt Label
        self.TrackerFrame.TotalDebt = self.TrackerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self.TrackerFrame.TotalDebt:SetPoint("TOPRIGHT", -20, -30)
        self.TrackerFrame.TotalDebt:SetText("Total Debt: 0g")
        
        self.TrackerFrame.ExportBtn = CreateFrame("Button", nil, self.TrackerFrame, "UIPanelButtonTemplate")
        self.TrackerFrame.ExportBtn:SetSize(80, 20)
        self.TrackerFrame.ExportBtn:SetPoint("BOTTOMRIGHT", -20, 2)
        self.TrackerFrame.ExportBtn:SetText("Export CSV")
        self.TrackerFrame.ExportBtn:SetScript("OnClick", function() self:ShowExportPopup() end)
        
        self.TrackerFrame.AnnounceBtn = CreateFrame("Button", nil, self.TrackerFrame, "UIPanelButtonTemplate")
        self.TrackerFrame.AnnounceBtn:SetSize(120, 22)
        self.TrackerFrame.AnnounceBtn:SetPoint("BOTTOM", 0, 2)
        self.TrackerFrame.AnnounceBtn:SetText("Announce Debts")
        self.TrackerFrame.AnnounceBtn:SetScript("OnClick", function() if DTC.Bribe then DTC.Bribe:AnnounceDebts() end end)
        
        self.TrackerFrame.PayTaxBtn = CreateFrame("Button", nil, self.TrackerFrame, "UIPanelButtonTemplate")
        self.TrackerFrame.PayTaxBtn:SetSize(120, 22)
        self.TrackerFrame.PayTaxBtn:SetPoint("BOTTOMLEFT", 20, 2)
        self.TrackerFrame.PayTaxBtn:SetText("Mark Taxes Paid")
        self.TrackerFrame.PayTaxBtn:SetScript("OnClick", function() if DTC.Bribe then DTC.Bribe:PayAllTaxes() end end)
        self.TrackerFrame.PayTaxBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Mark Taxes Paid")
            GameTooltip:AddLine("Marks all 'Corruption Fee' debts owed to you as PAID.", 1, 1, 1, true)
            GameTooltip:AddLine("Use this after collecting gold from the mailbox or trade.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        self.TrackerFrame.PayTaxBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    -- NEW: 6. Lobby Input
    self.LobbyInputFrame = DTC_LobbyInputPopup
    if self.LobbyInputFrame then
        InjectTitle(self.LobbyInputFrame)
        UIDropDownMenu_SetWidth(self.LobbyInputFrame.CandidateDD, 140)
        UIDropDownMenu_Initialize(self.LobbyInputFrame.CandidateDD, function(frame, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) 
                self.LobbyInputFrame.candidate = s.value
                UIDropDownMenu_SetText(frame, DTC:GetColoredName(s.value)) 
            end
            
            local myName = UnitName("player")
            local candidates = {}
            if IsInRaid() then
                for i = 1, GetNumGroupMembers() do
                    local name = GetRaidRosterInfo(i)
                    if name then
                        if string.find(name, "-") then name = strsplit("-", name) end
                        if name ~= myName then table.insert(candidates, name) end
                    end
                end
            else
                table.insert(candidates, "Mickey"); table.insert(candidates, "Donald"); table.insert(candidates, "Goofy")
            end
            table.sort(candidates)
            
            for _, name in ipairs(candidates) do
                info.text = DTC:GetColoredName(name); info.value = name; info.checked = (self.LobbyInputFrame.candidate == name)
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        self.LobbyInputFrame.ConfirmBtn:SetScript("OnClick", function()
            local amt = self.LobbyInputFrame.AmountBox:GetText()
            local cand = self.LobbyInputFrame.candidate
            if cand then
                DTC.Bribe:SendLobby(cand, amt)
                self.LobbyInputFrame:Hide()
            else
                print("|cFFFF0000DTC:|r Select a candidate.")
            end
        end)
        self.LobbyInputFrame.CancelBtn:SetScript("OnClick", function() self.LobbyInputFrame:Hide() end)
        if self.LobbyInputFrame.SetTitle then self.LobbyInputFrame:SetTitle("Lobbying") end
    end
    
    -- NEW: 7. Lobby List
    self.LobbyListFrame = DTC_LobbyListFrame
    InjectTitle(self.LobbyListFrame)
    if self.LobbyListFrame and self.LobbyListFrame.SetTitle then self.LobbyListFrame:SetTitle("DTC Tracker - Lobby") end
    
end

-- Opens the Bribe Offer window for a specific target.
-- --- OPENERS ---
function DTC.BribeUI:OpenOfferWindow(targetName)
    if not self.OfferFrame then self:Init() end
    if not self.OfferFrame then return end
    self.OfferFrame.target = targetName
    self.OfferFrame.AmountBox:SetText(""); self.OfferFrame.AmountBox:SetFocus()
    self.OfferFrame.Title:SetText("DTC Tracker - Bribe Offer")
    if self.OfferFrame.Label then self.OfferFrame.Label:SetText("Enter Amount for " .. targetName .. " (Gold):") end
    self.OfferFrame:Show()
end

-- Opens the Proposition Input window.
function DTC.BribeUI:OpenPropInput()
    if not self.PropInputFrame then self:Init() end
    if not self.PropInputFrame then return end
    self.PropInputFrame.AmountBox:SetText(""); self.PropInputFrame.AmountBox:SetFocus()
    self.PropInputFrame:Show()
end

-- Opens the Lobby Input window for a specific target.
function DTC.BribeUI:OpenLobbyInput(targetName)
    if not self.LobbyInputFrame then self:Init() end
    if not self.LobbyInputFrame then return end
    self.LobbyInputFrame.AmountBox:SetText(""); self.LobbyInputFrame.AmountBox:SetFocus()
    self.LobbyInputFrame.candidate = targetName
    UIDropDownMenu_SetText(self.LobbyInputFrame.CandidateDD, targetName and DTC:GetColoredName(targetName) or "Select Candidate")
    self.LobbyInputFrame:Show()
end

-- Displays the next incoming bribe offer in the queue.
function DTC.BribeUI:ShowNextOffer()
    if not self.IncomingFrame then self:Init() end
    if not self.IncomingFrame then return end
    if #DTC.Bribe.IncomingQueue == 0 then self.IncomingFrame:Hide(); self.CurrentOfferID = nil; return end
    local offer = DTC.Bribe.IncomingQueue[1]
    self.CurrentOfferID = offer.id
    self.IncomingFrame.Desc:SetText(string.format("|cFFFFD700%s|r offers you |cFFFFD700%s Gold|r", offer.sender, BreakUpLargeNumbers(offer.amount)))
    self.IncomingFrame:Show()
    
    self.IncomingFrame:SetScript("OnUpdate", function(f, elapsed)
        local duration = DTCRaidDB.settings.bribeTimer or 90
        local now = GetTime()
        local start = offer.startTime or now
        local left = (start + duration) - now
        if left < 0 then left = 0 end
        f.TimerBar:SetMinMaxValues(0, duration)
        f.TimerBar:SetValue(left)
    end)
end

-- Updates the list of active propositions.
-- --- LIST UPDATES ---
function DTC.BribeUI:UpdatePropositionList()
    if not self.PropListFrame then self:Init() end
    if not self.PropListFrame then return end
    local list = DTC.Bribe.PropositionQueue
    
    -- Show window if items exist
    if #list > 0 then self.PropListFrame:Show() else self.PropListFrame:Hide() end
    
    local content = self.PropListFrame.ListScroll.Content
    self.propRows = self.propRows or {}
    for _, r in ipairs(self.propRows) do r:Hide() end
    
    local yOffset = 0
    for i, prop in ipairs(list) do
        local row = self.propRows[i]
        if not row then
            row = CreateFrame("Frame", nil, content, "DTC_PropRowTemplate")
            table.insert(self.propRows, row)
        end
        row:SetParent(content)
        row:Show()
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        row.Text:SetText(prop.offerer .. " (" .. BreakUpLargeNumbers(prop.amount) .. "g)")
        
        row.AcceptBtn:SetScript("OnClick", function() DTC.Bribe:AcceptProposition(prop.id) end)
        
        row:SetScript("OnUpdate", function(self, elapsed)
            local now = GetTime()
            local finish = (prop.startTime or now) + (prop.duration or 0)
            local left = finish - now
            if left < 0 then left = 0 end
            self.Timer:SetMinMaxValues(0, prop.duration or 0)
            self.Timer:SetValue(left)
        end)
        
        row.DeclineBtn:SetScript("OnClick", function() 
             -- Local hide only? Or ignore?
             -- Usually "Decline" just hides it from MY screen.
             -- For now let's just trigger a "remove from my list" visual
             DTC.Bribe:ExpireProposition(prop.id)
        end)
        
        -- Logic: If offerer has no votes left (should be caught by model check, but double check here)
        if DTC.Vote then
            local votes = DTC.Vote:GetVotesCastBy(prop.offerer)
            local maxVotes = DTCRaidDB.settings.votesPerPerson or 3
            if votes >= maxVotes then row.AcceptBtn:Disable() else row.AcceptBtn:Enable() end
        else
            row.AcceptBtn:Disable()
        end

        yOffset = yOffset - 25
    end
    content:SetHeight(math.abs(yOffset) + 20)
end

-- Updates the list of active lobby offers.
function DTC.BribeUI:UpdateLobbyList()
    if not self.LobbyListFrame then self:Init() end
    if not self.LobbyListFrame then return end
    local list = DTC.Bribe.LobbyQueue
    if #list > 0 then self.LobbyListFrame:Show() else self.LobbyListFrame:Hide() end
    
    local content = self.LobbyListFrame.ListScroll.Content
    self.lobbyRows = self.lobbyRows or {}
    for _, r in ipairs(self.lobbyRows) do r:Hide() end
    
    local yOffset = 0
    for i, lobby in ipairs(list) do
        local row = self.lobbyRows[i]
        if not row then
            row = CreateFrame("Frame", nil, content, "DTC_LobbyRowTemplate")
            table.insert(self.lobbyRows, row)
        end
        row:SetParent(content)
        row:Show()
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        -- Text: "[Lobbyist] pays [Amt] for [Candidate]"
        local txt = string.format("|cFFFFD700%s|r pays |cFFFFD700%sg|r for |cFF00FF00%s|r", lobby.lobbyist, BreakUpLargeNumbers(lobby.amount), lobby.candidate)
        row.Text:SetText(txt)
        
        row:SetScript("OnUpdate", function(self, elapsed)
            local now = GetTime()
            local finish = (lobby.startTime or now) + (lobby.duration or 0)
            local left = finish - now
            if left < 0 then left = 0 end
            self.Timer:SetMinMaxValues(0, lobby.duration or 0)
            self.Timer:SetValue(left)
        end)
        
        row.AcceptBtn:SetScript("OnClick", function() DTC.Bribe:AcceptLobby(lobby.id) end)
        row.DeclineBtn:SetScript("OnClick", function() DTC.Bribe:ExpireLobby(lobby.id) end)
        
        -- Logic: Disable if I have no votes
        if DTC.Vote and DTC.Vote.myVotesLeft > 0 then row.AcceptBtn:Enable() else row.AcceptBtn:Disable() end
        
        yOffset = yOffset - 25
    end
    content:SetHeight(math.abs(yOffset) + 20)
end

-- Shows the CSV Export popup for the Bribe Ledger.
function DTC.BribeUI:ShowExportPopup()
    local data = DTCRaidDB.bribes or {}
    local buffer = { "Timestamp,Offerer,Recipient,Amount,Boss,Paid" }
    
    local sorted = {}; for _, e in ipairs(data) do table.insert(sorted, e) end
    table.sort(sorted, function(a,b) 
        local tA, tB = a.timestamp or "", b.timestamp or ""
        return tA > tB 
    end)

    local myName = UnitName("player")
    local filter = self.FilterMode or "ALL"
    local search = (self.SearchFilter or ""):lower()

    for _, e in ipairs(sorted) do
        local show = true
        if filter == "OWE" and e.offerer ~= myName then show = false end
        if filter == "OWED" and e.recipient ~= myName then show = false end
        
        if show and search ~= "" then
            local o = (e.offerer or ""):lower()
            local r = (e.recipient or ""):lower()
            if not string.find(o, search, 1, true) and not string.find(r, search, 1, true) then show = false end
        end

        if show then
            table.insert(buffer, string.format("%s,%s,%s,%d,%s,%s",
                e.timestamp or "?", (e.offerer or "?"):gsub(",", ""), (e.recipient or "?"):gsub(",", ""), 
                e.amount or 0, (e.boss or "?"):gsub(",", ""), tostring(e.paid)
            ))
        end
    end
    local str = table.concat(buffer, "\n")

    local p = DTC_BribeExportPopup
    if not p then
        p = CreateFrame("Frame", "DTC_BribeExportPopup", self.TrackerFrame, "DTC_WindowTemplate")
        p:SetSize(500, 300)
        p:SetPoint("CENTER", 0, 0)
        p:SetFrameStrata("DIALOG")
        InjectTitle(p)
        if p.SetTitle then p:SetTitle("Export Bribe Ledger (Ctrl+C)") end
        
        p.Scroll = CreateFrame("ScrollFrame", nil, p, "UIPanelScrollFrameTemplate")
        p.Scroll:SetPoint("TOPLEFT", 10, -30)
        p.Scroll:SetPoint("BOTTOMRIGHT", -30, 10)
        
        p.EditBox = CreateFrame("EditBox", nil, p.Scroll)
        p.EditBox:SetMultiLine(true)
        p.EditBox:SetFontObject(ChatFontNormal)
        p.EditBox:SetWidth(460)
        p.Scroll:SetScrollChild(p.EditBox)
        p.EditBox:SetScript("OnEscapePressed", function() p:Hide() end)
    end
    p.EditBox:SetText(str)
    p.EditBox:HighlightText()
    p:Show()
end

-- Toggles the Bribe Ledger (Tracker) window.
function DTC.BribeUI:ToggleTracker()
    if not self.TrackerFrame then self:Init() end
    if not self.TrackerFrame then return end
    if self.TrackerFrame:IsShown() then self.TrackerFrame:Hide() else self.TrackerFrame:Show(); self:UpdateTracker() end
end

-- Updates the Bribe Ledger list based on current filters and sort settings.
function DTC.BribeUI:UpdateTracker()
    if not self.TrackerFrame or not self.TrackerFrame:IsShown() then return end
    local isLeader = UnitIsGroupLeader("player") and IsInRaid()
    if self.TrackerFrame.PayTaxBtn then self.TrackerFrame.PayTaxBtn:SetShown(isLeader) end
    
    local data = DTCRaidDB.bribes or {}
    
    local displayedDebt = 0

    local content = self.TrackerFrame.ListScroll.Content
    self.rows = self.rows or {}
    for _, r in ipairs(self.rows) do r:Hide() end
    local yOffset = 0
    local rowIndex = 1
    
    local sorted = {}; for i, e in ipairs(data) do table.insert(sorted, { d=e, i=i }) end
    
    local sortMode = self.SortMode or "DATE_DESC"
    table.sort(sorted, function(a,b)
        local dA, dB = a.d, b.d
        if sortMode == "DATE_ASC" then 
            local tA, tB = dA.timestamp or "", dB.timestamp or ""
            if tA ~= tB then return tA < tB end
        elseif sortMode == "AMT_DESC" then 
            if dA.amount ~= dB.amount then return (dA.amount or 0) > (dB.amount or 0) end
        elseif sortMode == "AMT_ASC" then 
            if dA.amount ~= dB.amount then return (dA.amount or 0) < (dB.amount or 0) end
        else 
            local tA, tB = dA.timestamp or "", dB.timestamp or ""
            if tA ~= tB then return tA > tB end
        end
        return a.i < b.i -- Stable sort fallback
    end)
    
    local myName = UnitName("player")
    local filter = self.FilterMode or "ALL"
    local search = (self.SearchFilter or ""):lower()
    
    for _, wrapper in ipairs(sorted) do
        local entry = wrapper.d
        local originalIndex = wrapper.i
        
        local show = true
        if filter == "OWE" and entry.offerer ~= myName then show = false end
        if filter == "OWED" and entry.recipient ~= myName then show = false end
        
        if show and search ~= "" then
            local o = (entry.offerer or ""):lower()
            local r = (entry.recipient or ""):lower()
            if not string.find(o, search, 1, true) and not string.find(r, search, 1, true) then show = false end
        end
        
        if show then
            if not entry.paid then displayedDebt = displayedDebt + (entry.amount or 0) end
            
            local row = self.rows[rowIndex]
            if not row then
                row = CreateFrame("Frame", nil, content, "DTC_BribeRowTemplate")
                row.ForgiveBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.ForgiveBtn:SetSize(60, 22)
                row.ForgiveBtn:SetPoint("RIGHT", row.TradeBtn, "LEFT", -5, 0)
                row.ForgiveBtn:SetText("Forgive")
                
                row.MarkPaidBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.MarkPaidBtn:SetSize(80, 22)
                row.MarkPaidBtn:SetPoint("RIGHT", row.ForgiveBtn, "LEFT", -5, 0)
                row.MarkPaidBtn:SetText("Mark Paid")
                table.insert(self.rows, row)
            end
            row:SetParent(content)
            row:Show()
            row:SetPoint("TOPLEFT", 0, yOffset)
            local txt = string.format("%s -> %s (%s)", DTC:GetColoredName(entry.offerer), DTC:GetColoredName(entry.recipient), entry.boss or "?")
            row.Text:SetText(txt)
            
            if entry.boss and string.find(entry.boss, "%(Tax%)") then
                row.Text:SetTextColor(1, 0.5, 0.2)
            else
                row.Text:SetTextColor(1, 1, 1)
            end
            
            local status = entry.paid and "|cFF00FF00PAID|r" or "|cFFFF0000OWED|r"
            row.Amount:SetText(BreakUpLargeNumbers(entry.amount or 0) .. "g  " .. status)
            row.TradeBtn:SetScript("OnClick", function()
                if entry.offerer == UnitName("player") then 
                    DTC.Bribe:InitiateTrade(entry.recipient, entry.amount, originalIndex, true)
                elseif entry.recipient == UnitName("player") then 
                    DTC.Bribe:InitiateTrade(entry.offerer, entry.amount, originalIndex, false) 
                end
            end)
            
            if entry.paid or (entry.offerer ~= UnitName("player") and entry.recipient ~= UnitName("player")) or UnitIsDeadOrGhost("player") then 
                row.TradeBtn:Disable() 
            else 
                row.TradeBtn:Enable() 
            end
            
            row.ForgiveBtn:SetScript("OnClick", function() StaticPopup_Show("DTC_FORGIVE_CONFIRM", nil, nil, originalIndex) end)
            row.MarkPaidBtn:SetScript("OnClick", function() StaticPopup_Show("DTC_MARKPAID_CONFIRM", nil, nil, originalIndex) end)
            
            if entry.recipient == UnitName("player") and not entry.paid then 
                row.ForgiveBtn:Show(); row.MarkPaidBtn:Show() 
                -- Anchor Amount to left of MarkPaidBtn
                row.Amount:ClearAllPoints()
                row.Amount:SetPoint("RIGHT", row.MarkPaidBtn, "LEFT", -10, 0)
            else 
                row.ForgiveBtn:Hide(); row.MarkPaidBtn:Hide() 
                -- Anchor Amount to left of TradeBtn
                row.Amount:ClearAllPoints()
                row.Amount:SetPoint("RIGHT", row.TradeBtn, "LEFT", -10, 0)
            end
            
            yOffset = yOffset - 25
            rowIndex = rowIndex + 1
        end
    end
    
    if self.TrackerFrame.TotalDebt then self.TrackerFrame.TotalDebt:SetText("Total Debt: " .. BreakUpLargeNumbers(displayedDebt) .. "g") end
    content:SetHeight(math.abs(yOffset) + 20)
end

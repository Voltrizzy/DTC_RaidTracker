-- ============================================================================
-- DTC Raid Tracker - Config.lua
-- ============================================================================
-- This file builds the Interface Options panel for the addon. It handles the
-- layout and logic for all configuration tabs (General, Nicknames, etc.).

local folderName, DTC = ...
DTC.Config = {}
DTC.Config.nicknamePool = { rows = {}, headers = {} }

-- Helper to create a bordered group box.
local function CreateGroupBox(parent, title, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    local t = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 10, -10); t:SetText(title)
    return frame
end

-- Initializes the main configuration panel and tabs.
function DTC.Config:Init()
    DTCRaidDB = DTCRaidDB or {}
    DTCRaidDB.settings = DTCRaidDB.settings or {}

    local panel = CreateFrame("Frame", "DTC_OptionsPanel")
    panel.name = "DTC Raid Tracker"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("DTC Raid Tracker")
    
    panel.Tabs = {}; panel.SubFrames = {}
    
    local function SelectTab(id)
        for i, tab in ipairs(panel.Tabs) do
            if i == id then 
                tab:Disable(); panel.SubFrames[i]:Show()
                if i == 2 then DTC.Config:RefreshNicknames(panel.SubFrames[i].content) end
            else 
                tab:Enable(); panel.SubFrames[i]:Hide()
            end
        end
    end
    
    local function CreateTabButton(id, text, relativeTo)
        local t = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        t:SetID(id); t:SetText(text); t:SetSize(100, 22)
        if id == 1 then t:SetPoint("TOPLEFT", 20, -40) else t:SetPoint("LEFT", relativeTo, "RIGHT", 5, 0) end
        t:SetScript("OnClick", function() SelectTab(id) end)
        table.insert(panel.Tabs, t)
        local f = CreateFrame("Frame", nil, panel)
        f:SetSize(600, 500); f:SetPoint("TOPLEFT", 20, -70); f:Hide()
        table.insert(panel.SubFrames, f)
        return t
    end
    
    CreateTabButton(1, DTC.L["General"], nil)
    CreateTabButton(2, DTC.L["Nicknames"], panel.Tabs[1])
    CreateTabButton(3, DTC.L["Leaderboard"], panel.Tabs[2])
    CreateTabButton(4, DTC.L["History"], panel.Tabs[3])
    CreateTabButton(5, DTC.L["Voting"], panel.Tabs[4])
    CreateTabButton(6, DTC.L["Bribes"], panel.Tabs[5]) 
    
    self:BuildGeneralTab(panel.SubFrames[1])
    self:BuildNicknamesTab(panel.SubFrames[2])
    self:BuildLeaderboardTab(panel.SubFrames[3])
    self:BuildHistoryTab(panel.SubFrames[4])
    self:BuildVotingTab(panel.SubFrames[5])
    self:BuildBribeTab(panel.SubFrames[6])
    
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "DTC Raid Tracker")
    Settings.RegisterAddOnCategory(cat)
    DTC.OptionsCategoryID = cat:GetID()
    SelectTab(1)
end

-- Builds the "General" configuration tab.
function DTC.Config:BuildGeneralTab(frame)
    local box = CreateGroupBox(frame, DTC.L["General Options"], 580, 200)
    box:SetPoint("TOPLEFT", 0, 0)
    
    local btnVote = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnVote:SetSize(140, 24); btnVote:SetPoint("TOPLEFT", 15, -40); btnVote:SetText(DTC.L["Test Vote Window"])
    btnVote:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:StartSession("Test Boss", true) end end)
    
    local btnLB = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnLB:SetSize(140, 24); btnLB:SetPoint("LEFT", btnVote, "RIGHT", 10, 0); btnLB:SetText(DTC.L["Test Leaderboard"])
    btnLB:SetScript("OnClick", function() 
        DTC.isTestModeLB = true 
        if DTC.LeaderboardUI then 
            DTC.LeaderboardUI:Toggle()
            if DTC_LeaderboardFrame and DTC_LeaderboardFrame.SetTitle then DTC_LeaderboardFrame:SetTitle("DTC Tracker - Leaderboard") end
            DTC.LeaderboardUI:UpdateList() 
        end 
    end)
    
    local btnHist = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnHist:SetSize(140, 24); btnHist:SetPoint("LEFT", btnLB, "RIGHT", 10, 0); btnHist:SetText(DTC.L["Test History"])
    btnHist:SetScript("OnClick", function() 
        DTC.isTestModeHist = true
        if DTC.HistoryUI then 
            DTC.HistoryUI:Toggle()
            DTC.HistoryUI:UpdateList() 
        end 
    end)
    
    local btnBribe = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnBribe:SetSize(140, 24); btnBribe:SetPoint("TOPLEFT", 15, -70); btnBribe:SetText(DTC.L["Test Incoming Bribe"])
    btnBribe:SetScript("OnClick", function() 
        if DTC.Bribe then 
            print("Simulating incoming bribe from Mickey...")
            DTC.Bribe:ReceiveOffer("Mickey", 5000, true) 
        end 
    end)
    
    local btnProp = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnProp:SetSize(140, 24); btnProp:SetPoint("LEFT", btnBribe, "RIGHT", 10, 0); btnProp:SetText(DTC.L["Test Proposition"])
    btnProp:SetScript("OnClick", function() 
        if DTC.Bribe then 
            if DTC.Vote and not DTC.Vote.isOpen then print("|cFFFF0000DTC:|r Start a vote session first to test propositions."); return end
            print("Simulating incoming proposition from Donald...")
            DTC.Bribe:ReceiveProposition("Donald", 2500, true) 
        end 
    end)
    
    local btnLobby = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnLobby:SetSize(140, 24); btnLobby:SetPoint("LEFT", btnProp, "RIGHT", 10, 0); btnLobby:SetText(DTC.L["Test Lobbying"])
    btnLobby:SetScript("OnClick", function() 
        if DTC.Bribe then 
            if DTC.Vote and not DTC.Vote.isOpen then print("|cFFFF0000DTC:|r Start a vote session first to test lobbying."); return end
            print("Simulating incoming lobby offer from Goofy...")
            DTC.Bribe:ReceiveLobby("Goofy", "Mickey", 1000, true) 
        end 
    end)
    
    local btnDebts = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnDebts:SetSize(140, 24); btnDebts:SetPoint("TOPLEFT", 15, -100); btnDebts:SetText(DTC.L["Test Debts"])
    btnDebts:SetScript("OnClick", function()
        if DTC.Bribe then
            local me = UnitName("player")
            local target = UnitName("target") or "TestRecipient"
            if target == me then target = "TestRecipient" end
            
            -- Create dummy debts for testing trade window functionality
            DTC.Bribe:TrackBribe(me, target, 100, "Test Boss", "BRIBE")
            DTC.Bribe:TrackBribe(me, target, 200, "Test Boss", "PROP")
            DTC.Bribe:TrackBribe(me, target, 300, "Test Boss", "LOBBY")
            
            local feeEntry = { offerer = target, recipient = me, amount = 50, boss = "Test Boss (Tax)", paid = false, timestamp = date("%Y-%m-%d %H:%M:%S") }
            table.insert(DTCRaidDB.bribes, feeEntry)
            
            if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
            print("Created dummy debts to " .. target .. ".")
        end
    end)

    local btnVer = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnVer:SetSize(140, 24); btnVer:SetPoint("TOPLEFT", 15, -130); btnVer:SetText(DTC.L["Version Check"])
    btnVer:SetScript("OnClick", function() 
        if IsInRaid() then
            C_ChatInfo.SendAddonMessage(DTC.PREFIX, "VER_QUERY", "RAID") 
        else
            print("|cFFFFD700DTC:|r You must be in a raid group to perform a version check.")
        end
    end)

    local btnReset = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnReset:SetSize(140, 24); btnReset:SetPoint("LEFT", btnVer, "RIGHT", 10, 0); btnReset:SetText(DTC.L["Reset to Defaults"])
    btnReset:SetScript("OnClick", function() StaticPopup_Show("DTC_RESET_SETTINGS_CONFIRM") end)

    local btnForceStart = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnForceStart:SetSize(140, 24); btnForceStart:SetPoint("TOPLEFT", 15, -160); btnForceStart:SetText(DTC.L["Force Start Session"])
    btnForceStart:SetScript("OnClick", function() 
        if UnitIsGroupLeader("player") and DTC:IsValidRaid() then
            StaticPopup_Show("DTC_FORCE_START_CONFIRM")
        else
            print("|cFFFF0000DTC:|r You must be in a valid raid instance to start a session.")
        end
    end)
end

-- Builds the "Nicknames" configuration tab.
function DTC.Config:BuildNicknamesTab(frame)
    local box = CreateGroupBox(frame, DTC.L["Roster Configuration"], 580, 400)
    box:SetPoint("TOPLEFT", 0, 0)
    
    local sf = CreateFrame("ScrollFrame", "DTC_ConfigNickScroll", box, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 10, -35); sf:SetPoint("BOTTOMRIGHT", -30, 40)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 1); sf:SetScrollChild(content)
    frame.content = content
    
    local btnSelectAll = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnSelectAll:SetSize(100, 24); btnSelectAll:SetPoint("BOTTOMLEFT", 15, 10); btnSelectAll:SetText(DTC.L["Select All"])
    btnSelectAll:SetScript("OnClick", function()
        for _, r in ipairs(DTC.Config.nicknamePool.rows) do
            if r:IsShown() and r.Check then r.Check:SetChecked(true) end
        end
    end)

    local btnDelSel = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnDelSel:SetSize(120, 24); btnDelSel:SetPoint("LEFT", btnSelectAll, "RIGHT", 10, 0); btnDelSel:SetText(DTC.L["Delete Selected"])
    btnDelSel:SetScript("OnClick", function()
        local changed = false
        for _, r in ipairs(DTC.Config.nicknamePool.rows) do
            if r:IsShown() and r.Check and r.Check:GetChecked() then
                local name = r.Label:GetText()
                if name and DTCRaidDB.identities[name] then
                    DTCRaidDB.identities[name] = nil
                    if DTCRaidDB.guilds then DTCRaidDB.guilds[name] = nil end
                    if DTCRaidDB.classes then DTCRaidDB.classes[name] = nil end
                    changed = true
                end
            end
        end
        if changed then DTC.Config:RefreshNicknames(frame.content) end
    end)
end

-- Refreshes the list of nicknames in the configuration tab.
function DTC.Config:RefreshNicknames(content)
    for _, r in ipairs(self.nicknamePool.rows) do r:Hide() end
    for _, h in ipairs(self.nicknamePool.headers) do h:Hide() end
    
    local roster = {}
    if DTCRaidDB.identities then
        for name, nick in pairs(DTCRaidDB.identities) do
            local guild = DTCRaidDB.guilds and DTCRaidDB.guilds[name]
            if not guild or guild == "" then guild = DTC.L["No Guild"] end
            if not roster[guild] then roster[guild] = {} end
            table.insert(roster[guild], name)
        end
    end
    
    local sortedGuilds = {}
    for g, _ in pairs(roster) do table.insert(sortedGuilds, g) end
    table.sort(sortedGuilds, function(a,b)
        if a == DTC.L["No Guild"] then return false end
        if b == DTC.L["No Guild"] then return true end
        return a < b
    end)
    
    local yOffset = 0
    local hIndex = 1
    local rIndex = 1

    for _, guild in ipairs(sortedGuilds) do
        local hdr = self.nicknamePool.headers[hIndex]
        if not hdr then
            hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            table.insert(self.nicknamePool.headers, hdr)
        end
        hIndex = hIndex + 1
        hdr:SetParent(content)
        hdr:Show()
        hdr:SetPoint("TOPLEFT", 0, yOffset); hdr:SetText(guild); hdr:SetTextColor(1, 0.82, 0)
        yOffset = yOffset - 20
        
        local players = roster[guild]
        table.sort(players)
        
        for _, name in ipairs(players) do
            local row = self.nicknamePool.rows[rIndex]
            if not row then
                row = CreateFrame("Frame", nil, content)
                row:SetSize(520, 24)
                row.Check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                row.Check:SetSize(24, 24); row.Check:SetPoint("LEFT", 0, 0)
                row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.Label:SetPoint("LEFT", row.Check, "RIGHT", 5, 0); row.Label:SetWidth(150); row.Label:SetJustifyH("LEFT")
                row.EditBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                row.EditBox:SetSize(200, 20); row.EditBox:SetPoint("LEFT", row.Label, "RIGHT", 10, 0); row.EditBox:SetAutoFocus(false)
                row.DelBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.DelBtn:SetSize(20, 20); row.DelBtn:SetPoint("LEFT", row.EditBox, "RIGHT", 5, 0); row.DelBtn:SetText("X")
                table.insert(self.nicknamePool.rows, row)
            end
            rIndex = rIndex + 1
            row:Show()
            row.Check:SetChecked(false)
            row:SetSize(520, 24); row:SetPoint("TOPLEFT", 10, yOffset)
            local cFile = (DTCRaidDB.classes and DTCRaidDB.classes[name]) or "PRIEST"
            local color = RAID_CLASS_COLORS[cFile] or {r=0.6,g=0.6,b=0.6}
            row.Label:SetText(name); row.Label:SetTextColor(color.r, color.g, color.b)
            local val = DTCRaidDB.identities[name]
            if not val or val == "" then val = name end
            row.EditBox:SetText(val)
            row.EditBox:SetScript("OnEnterPressed", function(self) 
                local txt = self:GetText():gsub(",", "")
                if txt == "" then txt = name end
                DTCRaidDB.identities[name] = txt; self:SetText(txt); self:ClearFocus() 
            end)
            row.EditBox:SetScript("OnEditFocusLost", function(self) 
                local txt = self:GetText():gsub(",", "")
                if txt == "" then txt = name end
                DTCRaidDB.identities[name] = txt; self:SetText(txt)
            end)
            row.DelBtn:SetScript("OnClick", function() 
                DTCRaidDB.identities[name] = nil
                if DTCRaidDB.guilds then DTCRaidDB.guilds[name] = nil end
                if DTCRaidDB.classes then DTCRaidDB.classes[name] = nil end
                DTC.Config:RefreshNicknames(content)
            end)
            yOffset = yOffset - 25
        end
        yOffset = yOffset - 10
    end
    content:SetHeight(math.abs(yOffset) + 20)
end

-- Builds the "Leaderboard" configuration tab.
function DTC.Config:BuildLeaderboardTab(frame)
    local b1 = CreateGroupBox(frame, DTC.L["Leaderboard Options"], 580, 80)
    b1:SetPoint("TOPLEFT", 0, 0)
    local lbl = b1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", 15, -30); lbl:SetText(DTC.L["Detail Level:"])
    local dd = CreateFrame("Frame", "DTC_ConfigLBDetailDD", b1, "UIDropDownMenuTemplate")
    dd:SetPoint("LEFT", lbl, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(dd, 160)
    local function InitMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(s) DTCRaidDB.settings.lbDetailMode = s.arg1; UIDropDownMenu_SetText(dd, s.value) end
        info.text, info.arg1, info.value = DTC.L["Show All Votes"], "ALL", DTC.L["Show All Votes"]; info.checked = (DTCRaidDB.settings.lbDetailMode == "ALL"); UIDropDownMenu_AddButton(info, level)
        info.text, info.arg1, info.value = DTC.L["Show Only Nickname"], "SIMPLE", DTC.L["Show Only Nickname"]; info.checked = (DTCRaidDB.settings.lbDetailMode == "SIMPLE"); UIDropDownMenu_AddButton(info, level)
    end
    UIDropDownMenu_Initialize(dd, InitMenu)
    UIDropDownMenu_SetText(dd, (DTCRaidDB.settings.lbDetailMode == "SIMPLE") and DTC.L["Show Only Nickname"] or DTC.L["Show All Votes"])
    local b2 = CreateGroupBox(frame, DTC.L["Award Configuration"], 580, 100)
    b2:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    local l2 = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l2:SetPoint("TOPLEFT", 15, -30); l2:SetText(DTC.L["Winning Message (%s = Name):"])
    local e2 = CreateFrame("EditBox", nil, b2, "InputBoxTemplate"); e2:SetSize(540, 30); e2:SetPoint("TOPLEFT", l2, "BOTTOMLEFT", 0, -10); e2:SetAutoFocus(false)
    e2:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings.awardMsg or "") end)
    e2:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.awardMsg = self:GetText() end)
end

-- Builds the "History" configuration tab.
function DTC.Config:BuildHistoryTab(frame)
    local b1 = CreateGroupBox(frame, DTC.L["Database Maintenance"], 580, 80)
    b1:SetPoint("TOPLEFT", 0, 0)
    local btnReset = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate")
    btnReset:SetSize(160, 24); btnReset:SetPoint("TOPLEFT", 15, -40); btnReset:SetText(DTC.L["Reset Local Data"])
    btnReset:SetScript("OnClick", function() StaticPopup_Show("DTC_RESET_CONFIRM") end)
    
    local btnBribeHist = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate")
    btnBribeHist:SetSize(140, 24); btnBribeHist:SetPoint("LEFT", btnReset, "RIGHT", 10, 0); btnBribeHist:SetText(DTC.L["Open Bribe Ledger"])
    btnBribeHist:SetScript("OnClick", function() 
        if DTC.BribeUI then 
            DTC.BribeUI:ToggleTracker() 
            if DTC_BribeTrackerFrame and DTC_BribeTrackerFrame.SetTitle then DTC_BribeTrackerFrame:SetTitle("DTC Tracker - Bribe Ledger") end
        end 
    end)
    
    local function CreateFilterSet(parent, prefix)
        local filters = { exp="ALL", raid="ALL", diff="ALL", date="ALL" }
        local ddExp = CreateFrame("Frame", prefix.."Exp", parent, "UIDropDownMenuTemplate"); ddExp:SetPoint("TOPLEFT", -5, -30); UIDropDownMenu_SetWidth(ddExp, 115) 
        local ddRaid = CreateFrame("Frame", prefix.."Raid", parent, "UIDropDownMenuTemplate"); ddRaid:SetPoint("LEFT", ddExp, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddRaid, 115) 
        local ddDiff = CreateFrame("Frame", prefix.."Diff", parent, "UIDropDownMenuTemplate"); ddDiff:SetPoint("LEFT", ddRaid, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddDiff, 80) 
        local ddDate = CreateFrame("Frame", prefix.."Date", parent, "UIDropDownMenuTemplate"); ddDate:SetPoint("LEFT", ddDiff, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddDate, 100) 
        
        UIDropDownMenu_Initialize(ddExp, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.exp = s.arg1; UIDropDownMenu_SetText(ddExp, s.value); filters.raid = "ALL"; UIDropDownMenu_SetText(ddRaid, DTC.L["All Raids"]) end
            info.text = DTC.L["All Exp"]; info.arg1 = "ALL"; info.value = DTC.L["All Exp"]; UIDropDownMenu_AddButton(info, level)
            if DTC.Static and DTC.Static.EXPANSION_NAMES then
                for i=11,0,-1 do info.text = DTC.Static.EXPANSION_NAMES[i]; info.arg1 = tostring(i); info.value = DTC.Static.EXPANSION_NAMES[i]; UIDropDownMenu_AddButton(info, level) end
            end
        end)
        UIDropDownMenu_SetText(ddExp, DTC.L["All Exp"])
        UIDropDownMenu_Initialize(ddRaid, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.raid = s.arg1; UIDropDownMenu_SetText(ddRaid, s.value) end
            info.text = DTC.L["All Raids"]; info.arg1 = "ALL"; info.value = DTC.L["All Raids"]; UIDropDownMenu_AddButton(info, level)
            if filters.exp ~= "ALL" and DTC.Static and DTC.Static.RAID_DATA and DTC.Static.RAID_DATA[tonumber(filters.exp)] then
                for _, r in ipairs(DTC.Static.RAID_DATA[tonumber(filters.exp)]) do info.text=r; info.arg1=r; info.value=r; UIDropDownMenu_AddButton(info, level) end
            end
        end)
        UIDropDownMenu_SetText(ddRaid, DTC.L["All Raids"])
        UIDropDownMenu_Initialize(ddDiff, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.diff = s.arg1; UIDropDownMenu_SetText(ddDiff, s.value) end
            info.text = DTC.L["All"]; info.arg1 = "ALL"; info.value = DTC.L["All"]; UIDropDownMenu_AddButton(info, level)
            local dList = (DTC.Static and DTC.Static.DIFFICULTIES and DTC.Static.DIFFICULTIES["DEFAULT"]) or {}
            if filters.exp ~= "ALL" and DTC.Static and DTC.Static.DIFFICULTIES and DTC.Static.DIFFICULTIES[tonumber(filters.exp)] then dList = DTC.Static.DIFFICULTIES[tonumber(filters.exp)] end
            for _, d in ipairs(dList) do info.text=d; info.arg1=d; info.value=d; UIDropDownMenu_AddButton(info, level) end
        end)
        UIDropDownMenu_SetText(ddDiff, DTC.L["All"])
        UIDropDownMenu_Initialize(ddDate, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.date = s.arg1; UIDropDownMenu_SetText(ddDate, s.value) end
            info.text = DTC.L["All Dates"]; info.arg1 = "ALL"; info.value = DTC.L["All Dates"]; UIDropDownMenu_AddButton(info, level)
            local dates = DTC.History and DTC.History:GetUniqueMenus() or {}
            for _, d in ipairs(dates) do info.text=d; info.arg1=d; info.value=d; UIDropDownMenu_AddButton(info, level) end
        end)
        UIDropDownMenu_SetText(ddDate, DTC.L["All Dates"])
        return filters
    end
    
    local bSync = CreateGroupBox(frame, DTC.L["Sync Data"], 580, 120)
    bSync:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    local sFilters = CreateFilterSet(bSync, "DTCSync")
    local lblSync = bSync:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lblSync:SetPoint("TOPLEFT", 20, -75); lblSync:SetText(DTC.L["Target Player:"])
    local ebSync = CreateFrame("EditBox", nil, bSync, "InputBoxTemplate"); ebSync:SetSize(150, 24); ebSync:SetPoint("LEFT", lblSync, "RIGHT", 10, 0); ebSync:SetAutoFocus(false)
    local btnSync = CreateFrame("Button", nil, bSync, "UIPanelButtonTemplate"); btnSync:SetSize(120, 24); btnSync:SetPoint("LEFT", ebSync, "RIGHT", 10, 0); btnSync:SetText(DTC.L["Push Data"])
    btnSync:SetScript("OnClick", function() if DTC.History then DTC.History:PushSync(ebSync:GetText(), sFilters) end end)
    
    local bPurge = CreateGroupBox(frame, DTC.L["Purge Data"], 580, 120)
    bPurge:SetPoint("TOPLEFT", bSync, "BOTTOMLEFT", 0, -10)
    local pFilters = CreateFilterSet(bPurge, "DTCPurge")
    local btnPurge = CreateFrame("Button", nil, bPurge, "UIPanelButtonTemplate"); btnPurge:SetSize(160, 24); btnPurge:SetPoint("TOPLEFT", 20, -75); btnPurge:SetText(DTC.L["Purge Matching"])
    btnPurge:SetScript("OnClick", function()
        StaticPopupDialogs["DTC_PURGE_CONFIRM"] = {text = DTC.L["Permanently delete matching entries?"], button1 = DTC.L["Yes"], button2 = DTC.L["No"], OnAccept = function() if DTC.History then DTC.History:PurgeMatching(pFilters) end end, timeout = 0, whileDead = true, hideOnEscape = true}
        StaticPopup_Show("DTC_PURGE_CONFIRM")
    end)
end

-- Builds the "Voting" configuration tab.
function DTC.Config:BuildVotingTab(frame)
    local b1 = CreateGroupBox(frame, DTC.L["Voting Options"], 580, 140)
    b1:SetPoint("TOPLEFT", 0, 0)
    
    local lbl = b1:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lbl:SetPoint("TOPLEFT", 15, -30); lbl:SetText(DTC.L["List Format:"])
    local dd = CreateFrame("Frame", "DTC_ConfigVoteSortDD", b1, "UIDropDownMenuTemplate"); dd:SetPoint("LEFT", lbl, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(dd, 200)
    local function InitMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(s) DTCRaidDB.settings.voteSortMode = s.arg1; UIDropDownMenu_SetText(dd, s.value) end
        info.text, info.arg1, info.value = DTC.L["Show Players and Roles"], "ROLE", DTC.L["Show Players and Roles"]; info.checked = (DTCRaidDB.settings.voteSortMode == "ROLE"); UIDropDownMenu_AddButton(info, level)
        info.text, info.arg1, info.value = DTC.L["Show Only Players"], "ALPHA", DTC.L["Show Only Players"]; info.checked = (DTCRaidDB.settings.voteSortMode == "ALPHA"); UIDropDownMenu_AddButton(info, level)
    end
    UIDropDownMenu_Initialize(dd, InitMenu)
    UIDropDownMenu_SetText(dd, (DTCRaidDB.settings.voteSortMode == "ALPHA") and DTC.L["Show Only Players"] or DTC.L["Show Players and Roles"])

    -- NEW: Voting Timer Slider
    local s = CreateFrame("Slider", "DTC_VoteTimerSlider", b1, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, -75)
    s:SetMinMaxValues(30, 600)
    s:SetValueStep(10)
    s:SetObeyStepOnDrag(true)
    s:SetWidth(200)
    _G[s:GetName() .. "Text"]:SetText(DTC.L["Voting Window Duration"])
    _G[s:GetName() .. "Low"]:SetText("30s")
    _G[s:GetName() .. "High"]:SetText("10m")
    local valLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); valLabel:SetPoint("TOP", s, "BOTTOM", 0, 0)
    s:SetScript("OnValueChanged", function(self, value) 
        if self.isSettingUp then return end
        value = math.floor(value); DTCRaidDB.settings.voteTimer = value; valLabel:SetText(value .. " seconds") 
    end)
    s:SetScript("OnShow", function(self) 
        self.isSettingUp = true
        local val = DTCRaidDB.settings.voteTimer or 180; self:SetValue(val); valLabel:SetText(val .. " seconds") 
        self.isSettingUp = false
    end)

    local sVotes = CreateFrame("Slider", "DTC_VotesPerPersonSlider", b1, "OptionsSliderTemplate")
    sVotes:SetPoint("LEFT", s, "RIGHT", 40, 0)
    sVotes:SetMinMaxValues(1, 10)
    sVotes:SetValueStep(1)
    sVotes:SetObeyStepOnDrag(true)
    sVotes:SetWidth(200)
    _G[sVotes:GetName() .. "Text"]:SetText(DTC.L["Votes Per Person"])
    _G[sVotes:GetName() .. "Low"]:SetText("1")
    _G[sVotes:GetName() .. "High"]:SetText("10")
    local valLabelVotes = sVotes:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); valLabelVotes:SetPoint("TOP", sVotes, "BOTTOM", 0, 0)
    sVotes:SetScript("OnValueChanged", function(self, value) 
        if self.isSettingUp then return end
        value = math.floor(value); DTCRaidDB.settings.votesPerPerson = value; valLabelVotes:SetText(value) 
    end)
    sVotes:SetScript("OnMouseUp", function(self) if IsInRaid() and UnitIsGroupLeader("player") then C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_VOTES:"..DTCRaidDB.settings.votesPerPerson, "RAID") end end)
    sVotes:SetScript("OnShow", function(self) 
        self.isSettingUp = true
        local val = DTCRaidDB.settings.votesPerPerson or 3; self:SetValue(val); valLabelVotes:SetText(val) 
        self.isSettingUp = false
    end)

    -- Reset Button
    local btnReset = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate")
    btnReset:SetSize(120, 22); btnReset:SetPoint("TOPRIGHT", -20, -30); btnReset:SetText(DTC.L["Reset Defaults"])
    
    local b2 = CreateGroupBox(frame, DTC.L["Announce Messages"], 580, 340)
    b2:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    
    local sf = CreateFrame("ScrollFrame", "DTC_ConfigVoteMsgScroll", b2, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 10, -30); sf:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 450); sf:SetScrollChild(content)
    
    local sCount = CreateFrame("Slider", "DTC_VoteMsgCountSlider", content, "OptionsSliderTemplate")
    sCount:SetPoint("TOPLEFT", 20, -35)
    sCount:SetMinMaxValues(1, 10); sCount:SetValueStep(1); sCount:SetObeyStepOnDrag(true); sCount:SetWidth(200)
    _G[sCount:GetName() .. "Text"]:SetText(DTC.L["Active Message Count"])
    _G[sCount:GetName() .. "Low"]:SetText("1"); _G[sCount:GetName() .. "High"]:SetText("10")
    local valLabel = sCount:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); valLabel:SetPoint("TOP", sCount, "BOTTOM", 0, 0)
    
    local btnTest = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btnTest:SetSize(140, 20); btnTest:SetPoint("LEFT", sCount, "RIGHT", 20, 0); btnTest:SetText(DTC.L["Test Announcement"])
    btnTest:SetScript("OnClick", function()
        local count = DTCRaidDB.settings.voteWinCount or 1
        local idx = math.random(1, count)
        local msg = DTCRaidDB.settings["voteWinMsg_"..idx]
        if not msg or msg == "" then msg = DTC.L["Test Message %s"] end
        print("|cFFFFD700DTC Test:|r " .. msg:format(UnitName("player")))
    end)

    local msgBoxes = {}
    local winMsgEBs = {}
    for i = 1, 10 do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(520, 20); row:SetPoint("TOPLEFT", 15, -60 - ((i-1)*25))
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lbl:SetPoint("LEFT", 0, 0); lbl:SetWidth(20); lbl:SetText(i..".")
        local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); eb:SetSize(480, 20); eb:SetPoint("LEFT", lbl, "RIGHT", 5, 0); eb:SetAutoFocus(false)
        local key = "voteWinMsg_" .. i
        eb:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings[key] or "") end)
        eb:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings[key] = self:GetText() end)
        msgBoxes[i] = row
        winMsgEBs[i] = eb
    end

    local function UpdateVis(val)
        DTCRaidDB.settings.voteWinCount = val
        valLabel:SetText(val)
        for i=1,10 do if i<=val then msgBoxes[i]:Show() else msgBoxes[i]:Hide() end end
        content:SetHeight(math.max(480, 60 + (val * 25) + 200))
    end
    sCount:SetScript("OnValueChanged", function(self, v) 
        if self.isSettingUp then return end
        v=math.floor(v); UpdateVis(v) 
    end)
    sCount:SetScript("OnShow", function(self) 
        self.isSettingUp = true
        local v = DTCRaidDB.settings.voteWinCount or 1; self:SetValue(v); UpdateVis(v) 
        self.isSettingUp = false
    end)

    local otherEBs = {}
    local function AddEdit(title, key, y, toggleKey)
        local l = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l:SetPoint("TOPLEFT", 15, y); l:SetText(title)
        local cb = nil
        if toggleKey then
            cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            cb:SetSize(20, 20); cb:SetPoint("LEFT", l, "RIGHT", 10, 0)
            cb:SetScript("OnShow", function(self) self:SetChecked(DTCRaidDB.settings[toggleKey] ~= false) end)
            cb:SetScript("OnClick", function(self) DTCRaidDB.settings[toggleKey] = self:GetChecked() end)
            local t = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("LEFT", cb, "RIGHT", 0, 0); t:SetText(DTC.L["Enable"])
        end
        local e = CreateFrame("EditBox", nil, content, "InputBoxTemplate"); e:SetSize(510, 20); e:SetPoint("TOPLEFT", l, "BOTTOMLEFT", 0, -5); e:SetAutoFocus(false)
        e:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings[key] or "") end); e:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings[key] = self:GetText() end)
        table.insert(otherEBs, {e=e, key=key, cb=cb, toggleKey=toggleKey})
    end
    AddEdit(DTC.L["Runner Up Message:"], "voteRunnerUpMsg", -330, "voteRunnerUpEnabled")
    AddEdit(DTC.L["Lowest Vote Message:"], "voteLowMsg", -375, "voteLowEnabled")

    -- NEW: Secure Mode
    local cbSec = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cbSec:SetSize(24, 24); cbSec:SetPoint("TOPLEFT", 15, -420)
    cbSec:SetScript("OnShow", function(self) self:SetChecked(DTCRaidDB.settings.secureVoteMode) end)
    cbSec:SetScript("OnClick", function(self) DTCRaidDB.settings.secureVoteMode = self:GetChecked() end)
    local lblSec = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblSec:SetPoint("LEFT", cbSec, "RIGHT", 5, 0); lblSec:SetText(DTC.L["Secure Mode (Leader Only Start)"])

    btnReset:SetScript("OnClick", function()
        -- Defaults
        DTCRaidDB.settings.voteSortMode = "ROLE"
        DTCRaidDB.settings.voteTimer = 180
        DTCRaidDB.settings.votesPerPerson = 3
        DTCRaidDB.settings.voteWinCount = 10
        
        DTCRaidDB.settings.voteRunnerUpMsg = "Honorable mention goes to %s."
        DTCRaidDB.settings.voteLowMsg = "Don't worry %s, there's always next time."
        DTCRaidDB.settings.voteRunnerUpEnabled = true
        DTCRaidDB.settings.voteLowEnabled = true
        
        DTCRaidDB.settings.voteWinMsg_1 = "Congrats to %s for winning the vote!"
        DTCRaidDB.settings.voteWinMsg_2 = "And the winner is... %s!"    
        DTCRaidDB.settings.voteWinMsg_3 = "STOP THE COUNT! %s has taken the lead!"
        DTCRaidDB.settings.voteWinMsg_4 = "The tribe has spoken. %s is the winner!"
        DTCRaidDB.settings.voteWinMsg_5 = "Democracy manifests! %s wins the vote."
        DTCRaidDB.settings.voteWinMsg_6 = "By popular demand, %s takes the crown."
        DTCRaidDB.settings.voteWinMsg_7 = "The people have chosen... wisely? %s wins!"
        DTCRaidDB.settings.voteWinMsg_8 = "Victory! %s is the chosen one."
        DTCRaidDB.settings.voteWinMsg_9 = "Against all odds, %s secures the win."
        DTCRaidDB.settings.voteWinMsg_10 = "Look at me. %s is the captain now."
        
        -- Refresh UI
        UIDropDownMenu_SetText(dd, DTC.L["Show Players and Roles"])
        s:SetValue(180)
        sVotes:SetValue(3)
        sCount:SetValue(10)
        
        for i, eb in ipairs(winMsgEBs) do eb:SetText(DTCRaidDB.settings["voteWinMsg_"..i]) end
        for _, item in ipairs(otherEBs) do
            item.e:SetText(DTCRaidDB.settings[item.key])
            if item.cb then item.cb:SetChecked(DTCRaidDB.settings[item.toggleKey]) end
        end
        print(DTC.L["|cFFFFD700DTC:|r Voting settings reset to defaults."])
        if IsInRaid() and UnitIsGroupLeader("player") then
             C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_VOTES:3", "RAID")
        end
    end)
end

-- Builds the "Bribes" configuration tab.
function DTC.Config:BuildBribeTab(frame)
    local box = CreateGroupBox(frame, DTC.L["Timer Settings"], 580, 250)
    box:SetPoint("TOPLEFT", 0, 0)
    
    local function AddSlider(title, key, minVal, maxVal, y, suffix)
        suffix = suffix or " seconds"
        local name = "DTC_ConfigSlider_" .. key
        local s = CreateFrame("Slider", name, box, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, y)
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(5)
        s:SetObeyStepOnDrag(true)
        s:SetWidth(200)
        
        local sText = _G[name.."Text"]
        local sLow = _G[name.."Low"]
        local sHigh = _G[name.."High"]
        
        if sText then sText:SetText(title) end
        if sLow then sLow:SetText(minVal .. (suffix == "%" and "%" or "s")) end
        if sHigh then sHigh:SetText(maxVal .. (suffix == "%" and "%" or "s")) end
        
        local valLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valLabel:SetPoint("TOP", s, "BOTTOM", 0, 0)
        
        s:SetScript("OnValueChanged", function(self, value) 
            if self.isSettingUp then return end
            value = math.floor(value)
            DTCRaidDB.settings[key] = value
            valLabel:SetText(value .. suffix)
        end)
        
        s:SetScript("OnMouseUp", function(self)
            if IsInRaid() and UnitIsGroupLeader("player") then
                if key == "corruptionFee" then
                    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_FEE:"..DTCRaidDB.settings[key], "RAID")
                elseif key == "bribeTimer" or key == "propTimer" or key == "lobbyTimer" then
                    local b, p, l = DTCRaidDB.settings.bribeTimer or 90, DTCRaidDB.settings.propTimer or 90, DTCRaidDB.settings.lobbyTimer or 120
                    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_TIMERS:"..b.."||"..p.."||"..l, "RAID")
                end
            end
        end)
        
        s:SetScript("OnShow", function(self) 
            self.isSettingUp = true
            local val = DTCRaidDB.settings[key] or 90
            if key == "lobbyTimer" then val = DTCRaidDB.settings[key] or 120 end
            if key == "corruptionFee" then val = DTCRaidDB.settings[key] or 10 end
            self:SetValue(val)
            valLabel:SetText(val .. suffix) 
            
            -- Lock Corruption Fee for non-leaders
            if key == "corruptionFee" then
                if UnitIsGroupLeader("player") or not IsInRaid() then
                    self:Enable(); if sLow then sLow:SetTextColor(1,1,1) end; if sHigh then sHigh:SetTextColor(1,1,1) end; if sText then sText:SetTextColor(1,0.82,0) end
                else
                    self:Disable(); if sLow then sLow:SetTextColor(0.5,0.5,0.5) end; if sHigh then sHigh:SetTextColor(0.5,0.5,0.5) end; if sText then sText:SetTextColor(0.5,0.5,0.5) end
                end
            end
            self.isSettingUp = false
        end)
    end
    
    AddSlider(DTC.L["Bribe Offer Expiration"], "bribeTimer", 30, 300, -40)
    AddSlider(DTC.L["Proposition Expiration"], "propTimer", 30, 300, -90)
    AddSlider(DTC.L["Lobbying Expiration"], "lobbyTimer", 30, 300, -140)
    AddSlider(DTC.L["State Corruption Fee (%)"], "corruptionFee", 0, 100, -190, "%")

    local b2 = CreateGroupBox(frame, DTC.L["Debt Management"], 580, 100)
    b2:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -10)
    
    local btnAnnounce = CreateFrame("Button", nil, b2, "UIPanelButtonTemplate")
    btnAnnounce:SetSize(160, 24); btnAnnounce:SetPoint("TOPLEFT", 20, -40); btnAnnounce:SetText(DTC.L["Announce Debts"])
    btnAnnounce:SetScript("OnClick", function() 
        if DTC.Bribe then DTC.Bribe:AnnounceDebts() end 
    end)
    
    local l = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l:SetPoint("TOPLEFT", 20, -70); l:SetText(DTC.L["Debt Limit (Gold, 0 = No Limit):"])
    local e = CreateFrame("EditBox", nil, b2, "InputBoxTemplate"); e:SetSize(100, 20); e:SetPoint("LEFT", l, "RIGHT", 10, 0); e:SetAutoFocus(false)
    
    local function UpdateLimit(self)
        local val = tonumber(self:GetText()) or 0
        if DTCRaidDB.settings.debtLimit ~= val then
            DTCRaidDB.settings.debtLimit = val
            if IsInRaid() then 
                C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_LIMIT:"..val, "RAID") 
            end
        end
    end

    e:SetScript("OnShow", function(self) 
        self:SetText(DTCRaidDB.settings.debtLimit or "0")
        if UnitIsGroupLeader("player") or not IsInRaid() then
            self:Enable(); self:SetTextColor(1, 1, 1)
        else
            self:Disable(); self:SetTextColor(0.5, 0.5, 0.5)
        end
    end)
    
    e:SetScript("OnEditFocusLost", function(self) if UnitIsGroupLeader("player") or not IsInRaid() then UpdateLimit(self) end end)
    e:SetScript("OnEnterPressed", function(self) if UnitIsGroupLeader("player") or not IsInRaid() then UpdateLimit(self); self:ClearFocus() end end)
end

local folderName, DTC = ...
DTC.Config = {}

local function CreateGroupBox(parent, title, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    local t = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 10, -10); t:SetText(title)
    return frame
end

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
    
    CreateTabButton(1, "General", nil)
    CreateTabButton(2, "Nicknames", panel.Tabs[1])
    CreateTabButton(3, "Leaderboard", panel.Tabs[2])
    CreateTabButton(4, "History", panel.Tabs[3])
    CreateTabButton(5, "Voting", panel.Tabs[4])
    CreateTabButton(6, "Bribes", panel.Tabs[5]) 
    
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

function DTC.Config:BuildGeneralTab(frame)
    local box = CreateGroupBox(frame, "General Options", 580, 140)
    box:SetPoint("TOPLEFT", 0, 0)
    
    local btnVote = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnVote:SetSize(140, 24); btnVote:SetPoint("TOPLEFT", 15, -40); btnVote:SetText("Test Vote Window")
    btnVote:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:StartSession("Test Boss", true) end end)
    
    local btnLB = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnLB:SetSize(140, 24); btnLB:SetPoint("LEFT", btnVote, "RIGHT", 10, 0); btnLB:SetText("Test Leaderboard")
    btnLB:SetScript("OnClick", function() DTC.isTestModeLB = true; if DTC.LeaderboardUI then DTC.Leaderboard:Toggle(); DTC.LeaderboardUI:UpdateList() end end)
    
    local btnHist = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnHist:SetSize(140, 24); btnHist:SetPoint("LEFT", btnLB, "RIGHT", 10, 0); btnHist:SetText("Test History")
    btnHist:SetScript("OnClick", function() DTC.isTestModeHist = true; if DTC.HistoryUI then DTC.History:Toggle(); DTC.HistoryUI:UpdateList() end end)
    
    local btnVer = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnVer:SetSize(140, 24); btnVer:SetPoint("TOPLEFT", 15, -70); btnVer:SetText("Version Check")
    btnVer:SetScript("OnClick", function() C_ChatInfo.SendAddonMessage(DTC.PREFIX, "VER_QUERY", "RAID") end)
    
    local btnBribe = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnBribe:SetSize(140, 24); btnBribe:SetPoint("LEFT", btnVer, "RIGHT", 10, 0); btnBribe:SetText("Test Incoming Bribe")
    btnBribe:SetScript("OnClick", function() 
        if DTC.Bribe then 
            print("Simulating incoming bribe from Mickey...")
            DTC.Bribe:ReceiveOffer("Mickey", 5000) 
        end 
    end)
    
    local btnProp = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnProp:SetSize(140, 24); btnProp:SetPoint("LEFT", btnBribe, "RIGHT", 10, 0); btnProp:SetText("Test Proposition")
    btnProp:SetScript("OnClick", function() 
        if DTC.Bribe then 
            if DTC.Vote and not DTC.Vote.isOpen then print("|cFFFF0000DTC:|r Start a vote session first to test propositions."); return end
            print("Simulating incoming proposition from Donald...")
            DTC.Bribe:ReceiveProposition("Donald", 2500) 
        end 
    end)
    
    local btnLobby = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnLobby:SetSize(140, 24); btnLobby:SetPoint("TOPLEFT", 15, -100); btnLobby:SetText("Test Lobbying")
    btnLobby:SetScript("OnClick", function() 
        if DTC.Bribe then 
            if DTC.Vote and not DTC.Vote.isOpen then print("|cFFFF0000DTC:|r Start a vote session first to test lobbying."); return end
            print("Simulating incoming lobby offer from Goofy...")
            DTC.Bribe:ReceiveLobby("Goofy", "Mickey", 1000) 
        end 
    end)
    
    local btnDebts = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btnDebts:SetSize(140, 24); btnDebts:SetPoint("LEFT", btnLobby, "RIGHT", 10, 0); btnDebts:SetText("Test Debts")
    btnDebts:SetScript("OnClick", function()
        if DTC.Bribe then
            local me = UnitName("player")
            local target = UnitName("target") or "TestRecipient"
            if target == me then target = "TestRecipient" end
            
            -- Create dummy debts for testing trade window functionality
            DTC.Bribe:TrackBribe(me, target, 100, "Test Boss", "BRIBE")
            DTC.Bribe:TrackBribe(me, target, 200, "Test Boss", "PROP")
            DTC.Bribe:TrackBribe(me, target, 300, "Test Boss", "LOBBY")
            
            local feeEntry = { offerer = me, recipient = target, amount = 50, boss = "Test Boss (Tax)", paid = false, timestamp = date("%Y-%m-%d %H:%M:%S") }
            table.insert(DTCRaidDB.bribes, feeEntry)
            
            if DTC.BribeUI then DTC.BribeUI:UpdateTracker() end
            print("Created dummy debts to " .. target .. ".")
        end
    end)
end

function DTC.Config:BuildNicknamesTab(frame)
    local box = CreateGroupBox(frame, "Roster Configuration", 580, 400)
    box:SetPoint("TOPLEFT", 0, 0)
    
    local sf = CreateFrame("ScrollFrame", "DTC_ConfigNickScroll", box, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 10, -35); sf:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(540, 1); sf:SetScrollChild(content)
    frame.content = content
end

function DTC.Config:RefreshNicknames(content)
    local kids = {content:GetChildren()}
    for _, child in ipairs(kids) do child:Hide(); child:SetParent(nil) end
    
    local roster = {}
    if DTCRaidDB.identities then
        for name, nick in pairs(DTCRaidDB.identities) do
            local guild = DTCRaidDB.guilds and DTCRaidDB.guilds[name]
            if not guild or guild == "" then guild = "No Guild" end
            if not roster[guild] then roster[guild] = {} end
            table.insert(roster[guild], name)
        end
    end
    
    local sortedGuilds = {}
    for g, _ in pairs(roster) do table.insert(sortedGuilds, g) end
    table.sort(sortedGuilds, function(a,b)
        if a == "No Guild" then return false end
        if b == "No Guild" then return true end
        return a < b
    end)
    
    local yOffset = 0
    for _, guild in ipairs(sortedGuilds) do
        local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("TOPLEFT", 0, yOffset); hdr:SetText(guild); hdr:SetTextColor(1, 0.82, 0)
        yOffset = yOffset - 20
        
        local players = roster[guild]
        table.sort(players)
        
        for _, name in ipairs(players) do
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(520, 24); row:SetPoint("TOPLEFT", 10, yOffset)
            local cFile = (DTCRaidDB.classes and DTCRaidDB.classes[name]) or "PRIEST"
            local color = RAID_CLASS_COLORS[cFile] or {r=0.6,g=0.6,b=0.6}
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 5, 0); label:SetWidth(150); label:SetJustifyH("LEFT")
            label:SetText(name); label:SetTextColor(color.r, color.g, color.b)
            local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            eb:SetSize(200, 20); eb:SetPoint("LEFT", label, "RIGHT", 10, 0); eb:SetAutoFocus(false)
            local val = DTCRaidDB.identities[name]
            if not val or val == "" then val = name end
            eb:SetText(val)
            eb:SetScript("OnEnterPressed", function(self) DTCRaidDB.identities[name] = self:GetText():gsub(",", ""); self:ClearFocus() end)
            eb:SetScript("OnEditFocusLost", function(self) DTCRaidDB.identities[name] = self:GetText():gsub(",", "") end)
            local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            delBtn:SetSize(20, 20); delBtn:SetPoint("LEFT", eb, "RIGHT", 5, 0); delBtn:SetText("X")
            delBtn:SetScript("OnClick", function() 
                DTCRaidDB.identities[name] = nil
                if DTCRaidDB.guilds then DTCRaidDB.guilds[name] = nil end
                if DTCRaidDB.classes then DTCRaidDB.classes[name] = nil end
                DTC.Config:RefreshNicknames(content)
            end)
            yOffset = yOffset - 25
        end
        yOffset = yOffset - 10
    end
end

function DTC.Config:BuildLeaderboardTab(frame)
    local b1 = CreateGroupBox(frame, "Leaderboard Options", 580, 80)
    b1:SetPoint("TOPLEFT", 0, 0)
    local lbl = b1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", 15, -30); lbl:SetText("Detail Level:")
    local dd = CreateFrame("Frame", "DTC_ConfigLBDetailDD", b1, "UIDropDownMenuTemplate")
    dd:SetPoint("LEFT", lbl, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(dd, 160)
    local function InitMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(s) DTCRaidDB.settings.lbDetailMode = s.arg1; UIDropDownMenu_SetText(dd, s.value) end
        info.text, info.arg1, info.value = "Show All Votes", "ALL", "Show All Votes"; info.checked = (DTCRaidDB.settings.lbDetailMode == "ALL"); UIDropDownMenu_AddButton(info, level)
        info.text, info.arg1, info.value = "Show Only Nickname", "SIMPLE", "Show Only Nickname"; info.checked = (DTCRaidDB.settings.lbDetailMode == "SIMPLE"); UIDropDownMenu_AddButton(info, level)
    end
    UIDropDownMenu_Initialize(dd, InitMenu)
    UIDropDownMenu_SetText(dd, (DTCRaidDB.settings.lbDetailMode == "SIMPLE") and "Show Only Nickname" or "Show All Votes")
    local b2 = CreateGroupBox(frame, "Award Configuration", 580, 100)
    b2:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    local l2 = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l2:SetPoint("TOPLEFT", 15, -30); l2:SetText("Winning Message (%s = Name):")
    local e2 = CreateFrame("EditBox", nil, b2, "InputBoxTemplate"); e2:SetSize(540, 30); e2:SetPoint("TOPLEFT", l2, "BOTTOMLEFT", 0, -10); e2:SetAutoFocus(false)
    e2:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings.awardMsg or "") end)
    e2:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.awardMsg = self:GetText() end)
end

function DTC.Config:BuildHistoryTab(frame)
    local b1 = CreateGroupBox(frame, "Database Maintenance", 580, 80)
    b1:SetPoint("TOPLEFT", 0, 0)
    local btnReset = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate")
    btnReset:SetSize(160, 24); btnReset:SetPoint("TOPLEFT", 15, -40); btnReset:SetText("Reset Local Data")
    btnReset:SetScript("OnClick", function() StaticPopup_Show("DTC_RESET_CONFIRM") end)
    
    local btnBribeHist = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate")
    btnBribeHist:SetSize(140, 24); btnBribeHist:SetPoint("LEFT", btnReset, "RIGHT", 10, 0); btnBribeHist:SetText("Open Bribe Ledger")
    btnBribeHist:SetScript("OnClick", function() if DTC.BribeUI then DTC.BribeUI:ToggleTracker() end end)
    
    local function CreateFilterSet(parent, prefix)
        local filters = { exp="ALL", raid="ALL", diff="ALL", date="ALL" }
        local ddExp = CreateFrame("Frame", prefix.."Exp", parent, "UIDropDownMenuTemplate"); ddExp:SetPoint("TOPLEFT", -5, -30); UIDropDownMenu_SetWidth(ddExp, 115) 
        local ddRaid = CreateFrame("Frame", prefix.."Raid", parent, "UIDropDownMenuTemplate"); ddRaid:SetPoint("LEFT", ddExp, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddRaid, 115) 
        local ddDiff = CreateFrame("Frame", prefix.."Diff", parent, "UIDropDownMenuTemplate"); ddDiff:SetPoint("LEFT", ddRaid, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddDiff, 80) 
        local ddDate = CreateFrame("Frame", prefix.."Date", parent, "UIDropDownMenuTemplate"); ddDate:SetPoint("LEFT", ddDiff, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddDate, 100) 
        
        UIDropDownMenu_Initialize(ddExp, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.exp = s.arg1; UIDropDownMenu_SetText(ddExp, s.value); filters.raid = "ALL"; UIDropDownMenu_SetText(ddRaid, "All Raids") end
            info.text = "All Exp"; info.arg1 = "ALL"; info.value = "All Exp"; UIDropDownMenu_AddButton(info, level)
            for i=11,0,-1 do info.text = DTC.Static.EXPANSION_NAMES[i]; info.arg1 = tostring(i); info.value = DTC.Static.EXPANSION_NAMES[i]; UIDropDownMenu_AddButton(info, level) end
        end)
        UIDropDownMenu_SetText(ddExp, "All Exp")
        UIDropDownMenu_Initialize(ddRaid, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.raid = s.arg1; UIDropDownMenu_SetText(ddRaid, s.value) end
            info.text = "All Raids"; info.arg1 = "ALL"; info.value = "All Raids"; UIDropDownMenu_AddButton(info, level)
            if filters.exp ~= "ALL" and DTC.Static.RAID_DATA[tonumber(filters.exp)] then
                for _, r in ipairs(DTC.Static.RAID_DATA[tonumber(filters.exp)]) do info.text=r; info.arg1=r; info.value=r; UIDropDownMenu_AddButton(info, level) end
            end
        end)
        UIDropDownMenu_SetText(ddRaid, "All Raids")
        UIDropDownMenu_Initialize(ddDiff, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.diff = s.arg1; UIDropDownMenu_SetText(ddDiff, s.value) end
            info.text = "All"; info.arg1 = "ALL"; info.value = "All"; UIDropDownMenu_AddButton(info, level)
            local dList = DTC.Static.DIFFICULTIES["DEFAULT"]
            if filters.exp ~= "ALL" and DTC.Static.DIFFICULTIES[tonumber(filters.exp)] then dList = DTC.Static.DIFFICULTIES[tonumber(filters.exp)] end
            for _, d in ipairs(dList) do info.text=d; info.arg1=d; info.value=d; UIDropDownMenu_AddButton(info, level) end
        end)
        UIDropDownMenu_SetText(ddDiff, "All")
        UIDropDownMenu_Initialize(ddDate, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(s) filters.date = s.arg1; UIDropDownMenu_SetText(ddDate, s.value) end
            info.text = "All Dates"; info.arg1 = "ALL"; info.value = "All Dates"; UIDropDownMenu_AddButton(info, level)
            local dates = DTC.History and DTC.History:GetUniqueMenus() or {}
            for _, d in ipairs(dates) do info.text=d; info.arg1=d; info.value=d; UIDropDownMenu_AddButton(info, level) end
        end)
        UIDropDownMenu_SetText(ddDate, "All Dates")
        return filters
    end
    
    local bSync = CreateGroupBox(frame, "Sync Data", 580, 120)
    bSync:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    local sFilters = CreateFilterSet(bSync, "DTCSync")
    local lblSync = bSync:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lblSync:SetPoint("TOPLEFT", 20, -75); lblSync:SetText("Target Player:")
    local ebSync = CreateFrame("EditBox", nil, bSync, "InputBoxTemplate"); ebSync:SetSize(150, 24); ebSync:SetPoint("LEFT", lblSync, "RIGHT", 10, 0); ebSync:SetAutoFocus(false)
    local btnSync = CreateFrame("Button", nil, bSync, "UIPanelButtonTemplate"); btnSync:SetSize(120, 24); btnSync:SetPoint("LEFT", ebSync, "RIGHT", 10, 0); btnSync:SetText("Push Data")
    btnSync:SetScript("OnClick", function() if DTC.History then DTC.History:PushSync(ebSync:GetText(), sFilters) end end)
    
    local bPurge = CreateGroupBox(frame, "Purge Data", 580, 120)
    bPurge:SetPoint("TOPLEFT", bSync, "BOTTOMLEFT", 0, -10)
    local pFilters = CreateFilterSet(bPurge, "DTCPurge")
    local btnPurge = CreateFrame("Button", nil, bPurge, "UIPanelButtonTemplate"); btnPurge:SetSize(160, 24); btnPurge:SetPoint("TOPLEFT", 20, -75); btnPurge:SetText("Purge Matching")
    btnPurge:SetScript("OnClick", function()
        StaticPopupDialogs["DTC_PURGE_CONFIRM"] = {text = "Permanently delete matching entries?", button1 = "Yes", button2 = "No", OnAccept = function() if DTC.History then DTC.History:PurgeMatching(pFilters) end end, timeout = 0, whileDead = true, hideOnEscape = true}
        StaticPopup_Show("DTC_PURGE_CONFIRM")
    end)
end

function DTC.Config:BuildVotingTab(frame)
    local b1 = CreateGroupBox(frame, "Voting Options", 580, 150) -- Increased Height
    b1:SetPoint("TOPLEFT", 0, 0)
    
    local lbl = b1:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lbl:SetPoint("TOPLEFT", 15, -30); lbl:SetText("List Format:")
    local dd = CreateFrame("Frame", "DTC_ConfigVoteSortDD", b1, "UIDropDownMenuTemplate"); dd:SetPoint("LEFT", lbl, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(dd, 200)
    local function InitMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(s) DTCRaidDB.settings.voteSortMode = s.arg1; UIDropDownMenu_SetText(dd, s.value) end
        info.text, info.arg1, info.value = "Show Players and Roles", "ROLE", "Show Players and Roles"; info.checked = (DTCRaidDB.settings.voteSortMode == "ROLE"); UIDropDownMenu_AddButton(info, level)
        info.text, info.arg1, info.value = "Show Only Players", "ALPHA", "Show Only Players"; info.checked = (DTCRaidDB.settings.voteSortMode == "ALPHA"); UIDropDownMenu_AddButton(info, level)
    end
    UIDropDownMenu_Initialize(dd, InitMenu)
    UIDropDownMenu_SetText(dd, (DTCRaidDB.settings.voteSortMode == "ALPHA") and "Show Only Players" or "Show Players and Roles")

    -- NEW: Voting Timer Slider
    local s = CreateFrame("Slider", "DTC_VoteTimerSlider", b1, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, -70)
    s:SetMinMaxValues(30, 600)
    s:SetValueStep(10)
    s:SetObeyStepOnDrag(true)
    s:SetWidth(200)
    _G[s:GetName() .. "Text"]:SetText("Voting Window Duration")
    _G[s:GetName() .. "Low"]:SetText("30s")
    _G[s:GetName() .. "High"]:SetText("10m")
    local valLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); valLabel:SetPoint("TOP", s, "BOTTOM", 0, 0)
    s:SetScript("OnValueChanged", function(self, value) value = math.floor(value); DTCRaidDB.settings.voteTimer = value; valLabel:SetText(value .. " seconds") end)
    s:SetScript("OnShow", function(self) local val = DTCRaidDB.settings.voteTimer or 180; self:SetValue(val); valLabel:SetText(val .. " seconds") end)

    local b2 = CreateGroupBox(frame, "Announce Messages", 580, 450)
    b2:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    
    local sCount = CreateFrame("Slider", "DTC_VoteMsgCountSlider", b2, "OptionsSliderTemplate")
    sCount:SetPoint("TOPLEFT", 20, -30)
    sCount:SetMinMaxValues(1, 10); sCount:SetValueStep(1); sCount:SetObeyStepOnDrag(true); sCount:SetWidth(200)
    _G[sCount:GetName() .. "Text"]:SetText("Active Message Count")
    _G[sCount:GetName() .. "Low"]:SetText("1"); _G[sCount:GetName() .. "High"]:SetText("10")
    local valLabel = sCount:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); valLabel:SetPoint("TOP", sCount, "BOTTOM", 0, 0)
    
    local btnTest = CreateFrame("Button", nil, b2, "UIPanelButtonTemplate")
    btnTest:SetSize(140, 20); btnTest:SetPoint("LEFT", sCount, "RIGHT", 20, 0); btnTest:SetText("Test Announcement")
    btnTest:SetScript("OnClick", function()
        local count = DTCRaidDB.settings.voteWinCount or 1
        local idx = math.random(1, count)
        local msg = DTCRaidDB.settings["voteWinMsg_"..idx]
        if not msg or msg == "" then msg = "Test Message %s" end
        print("|cFFFFD700DTC Test:|r " .. msg:format(UnitName("player")))
    end)

    local msgBoxes = {}
    for i = 1, 10 do
        local row = CreateFrame("Frame", nil, b2)
        row:SetSize(540, 20); row:SetPoint("TOPLEFT", 15, -60 - ((i-1)*25))
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lbl:SetPoint("LEFT", 0, 0); lbl:SetWidth(20); lbl:SetText(i..".")
        local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); eb:SetSize(500, 20); eb:SetPoint("LEFT", lbl, "RIGHT", 5, 0); eb:SetAutoFocus(false)
        local key = "voteWinMsg_" .. i
        eb:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings[key] or "") end)
        eb:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings[key] = self:GetText() end)
        msgBoxes[i] = row
    end

    local function UpdateVis(val)
        DTCRaidDB.settings.voteWinCount = val
        valLabel:SetText(val)
        for i=1,10 do if i<=val then msgBoxes[i]:Show() else msgBoxes[i]:Hide() end end
    end
    sCount:SetScript("OnValueChanged", function(self, v) v=math.floor(v); UpdateVis(v) end)
    sCount:SetScript("OnShow", function(self) local v = DTCRaidDB.settings.voteWinCount or 1; self:SetValue(v); UpdateVis(v) end)

    local function AddEdit(title, key, y, toggleKey)
        local l = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l:SetPoint("TOPLEFT", 15, y); l:SetText(title)
        if toggleKey then
            local cb = CreateFrame("CheckButton", nil, b2, "UICheckButtonTemplate")
            cb:SetSize(20, 20); cb:SetPoint("LEFT", l, "RIGHT", 10, 0)
            cb:SetScript("OnShow", function(self) self:SetChecked(DTCRaidDB.settings[toggleKey] ~= false) end)
            cb:SetScript("OnClick", function(self) DTCRaidDB.settings[toggleKey] = self:GetChecked() end)
            local t = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("LEFT", cb, "RIGHT", 0, 0); t:SetText("Enable")
        end
        local e = CreateFrame("EditBox", nil, b2, "InputBoxTemplate"); e:SetSize(540, 20); e:SetPoint("TOPLEFT", l, "BOTTOMLEFT", 0, -5); e:SetAutoFocus(false)
        e:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings[key] or "") end); e:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings[key] = self:GetText() end)
    end
    AddEdit("Runner Up Message:", "voteRunnerUpMsg", -330, "voteRunnerUpEnabled")
    AddEdit("Lowest Vote Message:", "voteLowMsg", -375, "voteLowEnabled")
end

function DTC.Config:BuildBribeTab(frame)
    local box = CreateGroupBox(frame, "Timer Settings", 580, 250)
    box:SetPoint("TOPLEFT", 0, 0)
    
    local function AddSlider(title, key, minVal, maxVal, y, suffix)
        suffix = suffix or " seconds"
        -- We give the slider a nil name, but we can access sub-regions by key directly 
        -- because 'OptionsSliderTemplate' creates keys .Text, .Low, .High on the object.
        local s = CreateFrame("Slider", nil, box, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 20, y)
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(5)
        s:SetObeyStepOnDrag(true)
        s:SetWidth(200)
        
        -- Use direct references instead of _G lookups
        if s.Text then s.Text:SetText(title) end
        if s.Low then s.Low:SetText(minVal .. (suffix == "%" and "%" or "s")) end
        if s.High then s.High:SetText(maxVal .. (suffix == "%" and "%" or "s")) end
        
        local valLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valLabel:SetPoint("TOP", s, "BOTTOM", 0, 0)
        
        s:SetScript("OnValueChanged", function(self, value) 
            value = math.floor(value)
            DTCRaidDB.settings[key] = value
            valLabel:SetText(value .. suffix)
        end)
        
        s:SetScript("OnShow", function(self) 
            local val = DTCRaidDB.settings[key] or 90
            if key == "lobbyTimer" then val = DTCRaidDB.settings[key] or 120 end
            if key == "corruptionFee" then val = DTCRaidDB.settings[key] or 10 end
            self:SetValue(val)
            valLabel:SetText(val .. suffix) 
        end)
    end
    
    AddSlider("Bribe Offer Expiration", "bribeTimer", 30, 300, -40)
    AddSlider("Proposition Expiration", "propTimer", 30, 300, -90)
    AddSlider("Lobbying Expiration", "lobbyTimer", 30, 300, -140)
    AddSlider("State Corruption Fee (%)", "corruptionFee", 0, 100, -190, "%")

    local b2 = CreateGroupBox(frame, "Debt Management", 580, 100)
    b2:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -10)
    
    local btnAnnounce = CreateFrame("Button", nil, b2, "UIPanelButtonTemplate")
    btnAnnounce:SetSize(160, 24); btnAnnounce:SetPoint("TOPLEFT", 20, -40); btnAnnounce:SetText("Announce Debts")
    btnAnnounce:SetScript("OnClick", function() 
        if DTC.Bribe then DTC.Bribe:AnnounceDebts() end 
    end)
    
    local l = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l:SetPoint("TOPLEFT", 20, -70); l:SetText("Debt Limit (Gold, 0 = No Limit):")
    local e = CreateFrame("EditBox", nil, b2, "InputBoxTemplate"); e:SetSize(100, 20); e:SetPoint("LEFT", l, "RIGHT", 10, 0); e:SetAutoFocus(false)
    e:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings.debtLimit or "0") end)
    e:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings.debtLimit = tonumber(self:GetText()) or 0 end)
    e:SetScript("OnEnterPressed", function(self) DTCRaidDB.settings.debtLimit = tonumber(self:GetText()) or 0; self:ClearFocus() end)
end

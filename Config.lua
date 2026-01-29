local folderName, DTC = ...
DTC.Config = {}

-- Helper to create the gray borders
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

    -- Main Panel
    local panel = CreateFrame("Frame", "DTC_OptionsPanel")
    panel.name = "DTC Raid Tracker"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("DTC Raid Tracker")
    
    panel.Tabs = {}; panel.SubFrames = {}
    
    -- Tab Switching Logic
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
    
    self:BuildGeneralTab(panel.SubFrames[1])
    self:BuildNicknamesTab(panel.SubFrames[2])
    self:BuildLeaderboardTab(panel.SubFrames[3])
    self:BuildHistoryTab(panel.SubFrames[4])
    self:BuildVotingTab(panel.SubFrames[5])
    
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "DTC Raid Tracker")
    Settings.RegisterAddOnCategory(cat)
    DTC.OptionsCategoryID = cat:GetID()
    SelectTab(1)
end

function DTC.Config:BuildGeneralTab(frame)
    local box = CreateGroupBox(frame, "General Options", 580, 100)
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
end

function DTC.Config:BuildNicknamesTab(frame)
    local box = CreateGroupBox(frame, "Roster Configuration", 580, 400)
    box:SetPoint("TOPLEFT", 0, 0)
    local sf = CreateFrame("ScrollFrame", "DTC_ConfigNickScroll", box, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 10, -35); sf:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(540, 1); sf:SetScrollChild(content)
    frame.content = content
end
function DTC.Config:RefreshNicknames(content)
    local kids = {content:GetChildren()}; for _, child in ipairs(kids) do child:Hide(); child:SetParent(nil) end
    local keys = {}; if DTCRaidDB.identities then for k, _ in pairs(DTCRaidDB.identities) do table.insert(keys, k) end end
    if IsInGroup() then for i=1, GetNumGroupMembers() do local n=GetRaidRosterInfo(i); if n and (not DTCRaidDB.identities or not DTCRaidDB.identities[n]) then table.insert(keys, n) end end end
    local seen, unique = {}, {}; for _, k in ipairs(keys) do if not seen[k] then seen[k]=true; table.insert(unique, k) end end
    table.sort(unique)
    local yOffset = 0
    for _, name in ipairs(unique) do
        local row = CreateFrame("Frame", nil, content); row:SetSize(520, 24); row:SetPoint("TOPLEFT", 0, yOffset)
        local cFile = (DTCRaidDB.classes and DTCRaidDB.classes[name]) or "PRIEST"
        local color = RAID_CLASS_COLORS[cFile] or {r=0.6,g=0.6,b=0.6}
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); label:SetPoint("LEFT", 5, 0); label:SetWidth(150); label:SetJustifyH("LEFT")
        label:SetText(name); label:SetTextColor(color.r, color.g, color.b)
        local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate"); eb:SetSize(200, 20); eb:SetPoint("LEFT", label, "RIGHT", 10, 0); eb:SetAutoFocus(false)
        local val = DTCRaidDB.identities and DTCRaidDB.identities[name]; if not val or val == "" then val = name end; eb:SetText(val)
        eb:SetScript("OnEnterPressed", function(self) DTCRaidDB.identities = DTCRaidDB.identities or {}; DTCRaidDB.identities[name] = self:GetText(); self:ClearFocus() end)
        eb:SetScript("OnEditFocusLost", function(self) DTCRaidDB.identities = DTCRaidDB.identities or {}; DTCRaidDB.identities[name] = self:GetText() end)
        yOffset = yOffset - 25
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

-- ============================================================================
-- TAB 4: HISTORY (Updated Layout to Fix Overlap)
-- ============================================================================
function DTC.Config:BuildHistoryTab(frame)
    -- 1. Maintenance Frame
    local b1 = CreateGroupBox(frame, "Database Maintenance", 580, 80)
    b1:SetPoint("TOPLEFT", 0, 0)
    local btnReset = CreateFrame("Button", nil, b1, "UIPanelButtonTemplate")
    btnReset:SetSize(160, 24); btnReset:SetPoint("TOPLEFT", 15, -40); btnReset:SetText("Reset Local Data")
    btnReset:SetScript("OnClick", function() StaticPopup_Show("DTC_RESET_CONFIRM") end)
    
    -- Filter Set Helper (Tuned Widths: 115, 115, 80, 100)
    local function CreateFilterSet(parent, prefix)
        local filters = { exp="ALL", raid="ALL", diff="ALL", date="ALL" }
        
        -- Widths adjusted to fit comfortably in 580px
        local ddExp = CreateFrame("Frame", prefix.."Exp", parent, "UIDropDownMenuTemplate")
        ddExp:SetPoint("TOPLEFT", -5, -30); UIDropDownMenu_SetWidth(ddExp, 115) 
        
        local ddRaid = CreateFrame("Frame", prefix.."Raid", parent, "UIDropDownMenuTemplate")
        ddRaid:SetPoint("LEFT", ddExp, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddRaid, 115) 
        
        local ddDiff = CreateFrame("Frame", prefix.."Diff", parent, "UIDropDownMenuTemplate")
        ddDiff:SetPoint("LEFT", ddRaid, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddDiff, 80) 
        
        local ddDate = CreateFrame("Frame", prefix.."Date", parent, "UIDropDownMenuTemplate")
        ddDate:SetPoint("LEFT", ddDiff, "RIGHT", -15, 0); UIDropDownMenu_SetWidth(ddDate, 100) 
        
        -- Init Functions
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
    
    -- 2. Sync Frame (Aligned)
    local bSync = CreateGroupBox(frame, "Sync Data", 580, 120)
    bSync:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    local sFilters = CreateFilterSet(bSync, "DTCSync")
    
    local lblSync = bSync:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblSync:SetPoint("TOPLEFT", 20, -75); lblSync:SetText("Target Player:")
    
    local ebSync = CreateFrame("EditBox", nil, bSync, "InputBoxTemplate")
    ebSync:SetSize(150, 24); ebSync:SetPoint("LEFT", lblSync, "RIGHT", 10, 0); ebSync:SetAutoFocus(false)
    
    local btnSync = CreateFrame("Button", nil, bSync, "UIPanelButtonTemplate")
    btnSync:SetSize(120, 24); btnSync:SetPoint("LEFT", ebSync, "RIGHT", 10, 0); btnSync:SetText("Push Data")
    btnSync:SetScript("OnClick", function() if DTC.History then DTC.History:PushSync(ebSync:GetText(), sFilters) end end)
    
    -- 3. Purge Frame (Aligned)
    local bPurge = CreateGroupBox(frame, "Purge Data", 580, 120)
    bPurge:SetPoint("TOPLEFT", bSync, "BOTTOMLEFT", 0, -10)
    local pFilters = CreateFilterSet(bPurge, "DTCPurge")
    
    local btnPurge = CreateFrame("Button", nil, bPurge, "UIPanelButtonTemplate")
    btnPurge:SetSize(160, 24); btnPurge:SetPoint("TOPLEFT", 20, -75); btnPurge:SetText("Purge Matching")
    btnPurge:SetScript("OnClick", function()
        StaticPopupDialogs["DTC_PURGE_CONFIRM"] = {text = "Permanently delete matching entries?", button1 = "Yes", button2 = "No", OnAccept = function() if DTC.History then DTC.History:PurgeMatching(pFilters) end end, timeout = 0, whileDead = true, hideOnEscape = true}
        StaticPopup_Show("DTC_PURGE_CONFIRM")
    end)
end

function DTC.Config:BuildVotingTab(frame)
    local b1 = CreateGroupBox(frame, "Voting Options", 580, 80)
    b1:SetPoint("TOPLEFT", 0, 0)
    local lbl = b1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", 15, -30); lbl:SetText("List Format:")
    local dd = CreateFrame("Frame", "DTC_ConfigVoteSortDD", b1, "UIDropDownMenuTemplate")
    dd:SetPoint("LEFT", lbl, "RIGHT", 0, -2); UIDropDownMenu_SetWidth(dd, 200)
    local function InitMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(s) DTCRaidDB.settings.voteSortMode = s.arg1; UIDropDownMenu_SetText(dd, s.value) end
        info.text, info.arg1, info.value = "Show Players and Roles", "ROLE", "Show Players and Roles"; info.checked = (DTCRaidDB.settings.voteSortMode == "ROLE"); UIDropDownMenu_AddButton(info, level)
        info.text, info.arg1, info.value = "Show Only Players", "ALPHA", "Show Only Players"; info.checked = (DTCRaidDB.settings.voteSortMode == "ALPHA"); UIDropDownMenu_AddButton(info, level)
    end
    UIDropDownMenu_Initialize(dd, InitMenu)
    UIDropDownMenu_SetText(dd, (DTCRaidDB.settings.voteSortMode == "ALPHA") and "Show Only Players" or "Show Players and Roles")
    local b2 = CreateGroupBox(frame, "Announce Messages", 580, 200)
    b2:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
    local function AddEdit(title, key, y)
        local l = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); l:SetPoint("TOPLEFT", 15, y); l:SetText(title)
        local e = CreateFrame("EditBox", nil, b2, "InputBoxTemplate"); e:SetSize(540, 20); e:SetPoint("TOPLEFT", l, "BOTTOMLEFT", 0, -5); e:SetAutoFocus(false)
        e:SetScript("OnShow", function(self) self:SetText(DTCRaidDB.settings[key] or "") end); e:SetScript("OnEditFocusLost", function(self) DTCRaidDB.settings[key] = self:GetText() end)
    end
    AddEdit("Winner Message:", "voteWinMsg", -20)
    AddEdit("Runner Up Message:", "voteRunnerUpMsg", -65)
    AddEdit("Lowest Vote Message:", "voteLowMsg", -110)
end
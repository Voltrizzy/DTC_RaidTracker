local folderName, DTC = ...
DTC.LeaderboardUI = {}
local frame, rows = nil, {}

function DTC.LeaderboardUI:Init()
    frame = DTC_LeaderboardFrame
    
    if not frame.SetTitle then
        frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.TitleText:SetPoint("TOP", 0, -5)
        frame.SetTitle = function(self, text) self.TitleText:SetText(text) end
    end

    if frame.SetTitle then frame:SetTitle("DTC Tracker - Leaderboard") end
    
    frame.AwardBtn:SetScript("OnClick", function() self:OnAwardClick() end)
    
    -- Initialize Dropdowns with specific widths
    local function SetupDD(dd, width, initFunc, defaultText)
        UIDropDownMenu_SetWidth(dd, width)
        UIDropDownMenu_Initialize(dd, function(self, level) initFunc(self, level) end)
        UIDropDownMenu_SetText(dd, defaultText)
    end
    
    SetupDD(frame.TimeDD, 110, function(s, l) self:InitTimeMenu(s, l) end, "All Time")
    SetupDD(frame.ExpDD, 160, function(s, l) self:InitExpMenu(s, l) end, "Expansion")
    SetupDD(frame.RaidDD, 160, function(s, l) self:InitRaidMenu(s, l) end, "Raid")
    SetupDD(frame.BossDD, 160, function(s, l) self:InitBossMenu(s, l) end, "Boss")
    SetupDD(frame.DiffDD, 110, function(s, l) self:InitDiffMenu(s, l) end, "Difficulty")
    
    -- Disable dependent menus initially
    UIDropDownMenu_DisableDropDown(frame.RaidDD)
    UIDropDownMenu_DisableDropDown(frame.BossDD)
    UIDropDownMenu_DisableDropDown(frame.DiffDD)
end

function DTC.LeaderboardUI:Toggle()
    if not frame then DTC.LeaderboardUI:Init() end
    if frame:IsShown() then frame:Hide() else frame:Show(); DTC.LeaderboardUI:UpdateList() end
end

function DTC.LeaderboardUI:UpdateList()
    if not frame or not frame:IsShown() then return end
    for _, r in ipairs(rows) do r:Hide() end
    
    local data = DTC.Leaderboard:GetSortedData(DTC.isTestModeLB)
    local content = frame.ListScroll.Content
    local yOffset = 0
    local detailMode = DTCRaidDB.settings.lbDetailMode or "ALL"
    
    for i, item in ipairs(data) do
        local row = self:GetRow(content)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row.Text:SetText(i .. ". " .. DTC:GetColoredName(item.n))
        row.Value:SetText(item.v)
        row.Text:SetTextColor(1, 1, 1)
        row:Show()
        yOffset = yOffset - 20
        
        if detailMode == "ALL" and item.chars then
            for _, char in ipairs(item.chars) do
                local subRow = self:GetRow(content)
                subRow:SetPoint("TOPLEFT", 0, yOffset)
                subRow.Text:SetText("   - " .. DTC:GetColoredName(char.n))
                subRow.Value:SetText(char.v)
                subRow.Text:SetTextColor(0.6, 0.6, 0.6)
                subRow:Show()
                yOffset = yOffset - 16
            end
        end
        yOffset = yOffset - 5
    end
    
    local isLeader = UnitIsGroupLeader("player") or DTC.isTestModeLB
    frame.AwardBtn:SetShown(isLeader)
    content:SetHeight(math.abs(yOffset) + 20)
end

function DTC.LeaderboardUI:GetRow(parent)
    for _, r in ipairs(rows) do if not r:IsShown() then return r end end
    local r = CreateFrame("Frame", nil, parent, "DTC_ListRowTemplate")
    table.insert(rows, r)
    return r
end

-- ============================================================================
-- DROPDOWN LOGIC
-- ============================================================================
function DTC.LeaderboardUI:InitTimeMenu(menu, level)
    local info = UIDropDownMenu_CreateInfo()
    
    info.text = "All Time"
    info.value = "All Time"
    info.checked = (DTC.Leaderboard.Filters.Time == "ALL")
    info.func = function() 
        DTC.Leaderboard.Filters.Time="ALL"
        UIDropDownMenu_SetText(menu, "All Time")
        self:UpdateList() 
    end
    UIDropDownMenu_AddButton(info, level)
    
    info.text = "Trips Won"
    info.value = "Trips Won"
    info.checked = (DTC.Leaderboard.Filters.Time == "TRIPS")
    info.func = function() 
        DTC.Leaderboard.Filters.Time="TRIPS"
        UIDropDownMenu_SetText(menu, "Trips Won")
        self:UpdateList() 
    end
    UIDropDownMenu_AddButton(info, level)
end

function DTC.LeaderboardUI:InitExpMenu(menu, level)
    local info = UIDropDownMenu_CreateInfo()
    
    -- "None/All" Option
    info.text = "All Exp"
    info.value = "All Exp"
    info.checked = (DTC.Leaderboard.Filters.Exp == "ALL")
    info.func = function()
        DTC.Leaderboard.Filters.Exp = "ALL"
        DTC.Leaderboard.Filters.Raid = "ALL"
        DTC.Leaderboard.Filters.Boss = "ALL"
        UIDropDownMenu_SetText(menu, "All Exp")
        UIDropDownMenu_DisableDropDown(frame.RaidDD)
        UIDropDownMenu_DisableDropDown(frame.BossDD)
        UIDropDownMenu_DisableDropDown(frame.DiffDD)
        self:UpdateList()
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- Iterate using DTC.Static.EXPANSION_NAMES
    if DTC.Static and DTC.Static.EXPANSION_NAMES then
        for i=11,0,-1 do
            local name = DTC.Static.EXPANSION_NAMES[i]
            local idStr = tostring(i)
            info.text = name
            info.value = name
            info.checked = (DTC.Leaderboard.Filters.Exp == idStr)
            info.func = function()
                DTC.Leaderboard.Filters.Exp = idStr
                DTC.Leaderboard.Filters.Raid = "ALL"
                UIDropDownMenu_SetText(menu, name)
                UIDropDownMenu_EnableDropDown(frame.RaidDD)
                UIDropDownMenu_SetText(frame.RaidDD, "All Raids")
                self:UpdateList()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DTC.LeaderboardUI:InitRaidMenu(menu, level)
    local info = UIDropDownMenu_CreateInfo()
    
    -- "All Raids"
    info.text = "All Raids"
    info.value = "All Raids"
    info.checked = (DTC.Leaderboard.Filters.Raid == "ALL")
    info.func = function()
        DTC.Leaderboard.Filters.Raid = "ALL"
        UIDropDownMenu_SetText(menu, "All Raids")
        UIDropDownMenu_DisableDropDown(frame.BossDD)
        UIDropDownMenu_DisableDropDown(frame.DiffDD)
        self:UpdateList()
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- Use DTC.Static.RAID_DATA
    local expID = tonumber(DTC.Leaderboard.Filters.Exp)
    if expID and DTC.Static and DTC.Static.RAID_DATA and DTC.Static.RAID_DATA[expID] then
        for _, rName in ipairs(DTC.Static.RAID_DATA[expID]) do
            info.text = rName
            info.value = rName
            info.checked = (DTC.Leaderboard.Filters.Raid == rName)
            info.func = function()
                DTC.Leaderboard.Filters.Raid = rName
                UIDropDownMenu_SetText(menu, rName)
                UIDropDownMenu_EnableDropDown(frame.BossDD)
                UIDropDownMenu_SetText(frame.BossDD, "All Bosses")
                UIDropDownMenu_EnableDropDown(frame.DiffDD)
                self:UpdateList()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DTC.LeaderboardUI:InitBossMenu(menu, level)
    local info = UIDropDownMenu_CreateInfo()
    
    info.text = "All Bosses"
    info.value = "All Bosses"
    info.checked = (DTC.Leaderboard.Filters.Boss == "ALL")
    info.func = function() 
        DTC.Leaderboard.Filters.Boss = "ALL"
        UIDropDownMenu_SetText(menu, "All Bosses")
        self:UpdateList() 
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- Use DTC.Static via the Model helper
    local bosses = DTC.Leaderboard:GetBossList(DTC.Leaderboard.Filters.Raid)
    for _, bName in ipairs(bosses) do
        info.text = bName
        info.value = bName
        info.checked = (DTC.Leaderboard.Filters.Boss == bName)
        info.func = function()
            DTC.Leaderboard.Filters.Boss = bName
            UIDropDownMenu_SetText(menu, bName)
            self:UpdateList()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

function DTC.LeaderboardUI:InitDiffMenu(menu, level)
    local info = UIDropDownMenu_CreateInfo()
    
    info.text = "All Diffs"
    info.value = "All Diffs"
    info.checked = (DTC.Leaderboard.Filters.Diff == "ALL")
    info.func = function() 
        DTC.Leaderboard.Filters.Diff = "ALL"
        UIDropDownMenu_SetText(menu, "All Diffs")
        self:UpdateList() 
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- Use DTC.Static.DIFFICULTIES
    local expID = tonumber(DTC.Leaderboard.Filters.Exp)
    local diffs = (DTC.Static and DTC.Static.DIFFICULTIES and DTC.Static.DIFFICULTIES[expID]) or (DTC.Static and DTC.Static.DIFFICULTIES and DTC.Static.DIFFICULTIES["DEFAULT"]) or {}
    
    for _, dName in ipairs(diffs) do
        info.text = dName
        info.value = dName
        info.checked = (DTC.Leaderboard.Filters.Diff == dName)
        info.func = function() 
            DTC.Leaderboard.Filters.Diff = dName
            UIDropDownMenu_SetText(menu, dName)
            self:UpdateList() 
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

function DTC.LeaderboardUI:OnAwardClick()
    if DTC.isTestModeLB then print("|cFFFF0000DTC:|r Cannot award in Test Mode."); return end
    local data = DTC.Leaderboard:GetSortedData(false)
    if #data > 0 then
        local winner = data[1].n
        DTC.Leaderboard:AwardTrip(winner)
        
        local channel = IsInRaid() and "RAID" or "PRINT"
        local msg = DTCRaidDB.settings.awardMsg or "Congrats %s!"
        if channel == "PRINT" then
            print("--- DTC TRIP AWARDED ---"); print(msg:format(winner))
        else
            SendChatMessage("--- DTC TRIP AWARDED ---", channel)
            SendChatMessage(msg:format(winner), channel)
        end
        self:UpdateList()
    end
end
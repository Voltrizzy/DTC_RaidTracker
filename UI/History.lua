-- ============================================================================
-- DTC Raid Tracker - UI/History.lua
-- ============================================================================
-- This file manages the History UI. It handles displaying past vote records,
-- filtering, and exporting data.

local folderName, DTC = ...
DTC.HistoryUI = {}

local frame
local rows = {} -- Frame pool

-- 1. Initialize
function DTC.HistoryUI:Init()
    frame = DTC_HistoryFrame -- Defined in UI/History.xml
    
    if not frame.SetTitle then
        if not frame.TitleText then
            frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.TitleText:SetPoint("TOP", 0, -5)
        end
        frame.SetTitle = function(self, text) self.TitleText:SetText(text) end
    end

    -- Set Title
    frame:SetTitle(DTC.L["DTC Tracker - History"])
    
    -- Adjust ScrollFrame to fit within header/footer
    if frame.ListScroll then
        frame.ListScroll:ClearAllPoints()
        frame.ListScroll:SetPoint("TOPLEFT", 15, -85)
        frame.ListScroll:SetPoint("BOTTOMRIGHT", -35, 45)
    end
    
    -- Handle Window Closing (Reset Test Mode when closed)
    frame:SetScript("OnHide", function() 
        DTC.isTestModeHist = false 
    end)
    
    -- Export Button
    frame.ExportBtn:SetScript("OnClick", function() self:ShowExportPopup() end)
    
    -- Setup Dropdowns (Set Widths to prevent clumping)
    UIDropDownMenu_SetWidth(frame.DateDD, 130)
    UIDropDownMenu_Initialize(frame.DateDD, function(self, level) 
        DTC.HistoryUI:InitDateMenu(self, level) 
    end)
    UIDropDownMenu_SetText(frame.DateDD, DTC.L["All Dates"])
    
    UIDropDownMenu_SetWidth(frame.NameDD, 130)
    UIDropDownMenu_Initialize(frame.NameDD, function(self, level) 
        DTC.HistoryUI:InitNameMenu(self, level) 
    end)
    UIDropDownMenu_SetText(frame.NameDD, DTC.L["All Names"])
    
    -- Headers
    if not frame.Headers then
        frame.Headers = {}
        local function CreateHeader(text, x)
            local h = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            h:SetPoint("TOPLEFT", 20 + x, -65)
            h:SetText(text)
            return h
        end
        CreateHeader(DTC.L["Date"], 0)
        CreateHeader(DTC.L["Raid"], 85)
        CreateHeader(DTC.L["Diff"], 220)
        CreateHeader(DTC.L["Boss"], 305)
        CreateHeader(DTC.L["Winner"], 440)
        CreateHeader(DTC.L["Voters"], 550)
        frame.Headers = true
    end
end

-- 2. Toggle
function DTC.HistoryUI:Toggle()
    if not frame then DTC.HistoryUI:Init() end
    
    if frame:IsShown() then
        frame:Hide()
    else
        local title = DTC.L["DTC Tracker - History"]
        if DTC.isTestModeHist then title = DTC.L["(Test) "] .. title end
        frame:SetTitle(title)
        
        frame:Show()
        DTC.HistoryUI:UpdateList()
    end
end

-- 3. Update List
function DTC.HistoryUI:UpdateList()
    if not frame or not frame:IsShown() then return end
    
    -- Clean rows
    for _, r in ipairs(rows) do r:Hide() end
    
    -- Get Data
    local data = DTC.History:GetData(DTC.isTestModeHist)
    local content = frame.ListScroll.Content
    local yOffset = 0
    
    for i, h in ipairs(data) do
        local row = rows[i]
        if not row then
            row = CreateFrame("Frame", nil, content, "DTC_ListRowTemplate")
            row:SetSize(800, 20)
            
            row.Date = row.Text 
            row.Date:SetWidth(80) -- Prevent overlap with Raid column
            
            row.Raid = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.Raid:SetPoint("LEFT", 85, 0); row.Raid:SetWidth(130); row.Raid:SetJustifyH("LEFT")
            row.Raid:SetWordWrap(false)
            
            row.Diff = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.Diff:SetPoint("LEFT", 220, 0); row.Diff:SetWidth(80); row.Diff:SetJustifyH("LEFT")
            row.Diff:SetWordWrap(false)
            
            row.Boss = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.Boss:SetPoint("LEFT", 305, 0); row.Boss:SetWidth(130); row.Boss:SetJustifyH("LEFT")
            row.Boss:SetWordWrap(false)
            
            row.Winner = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Winner:SetPoint("LEFT", 440, 0); row.Winner:SetWidth(100); row.Winner:SetJustifyH("LEFT")
            row.Winner:SetWordWrap(false)
            
            row.Voters = row.Value 
            row.Voters:ClearAllPoints()
            row.Voters:SetPoint("LEFT", 550, 0); row.Voters:SetJustifyH("LEFT")
            
            table.insert(rows, row)
        end
        
        row:SetPoint("TOPLEFT", 0, yOffset)
        row.Date:SetText(h.d)
        row.Raid:SetText(h.r)
        row.Diff:SetText(h.diff or "")
        row.Boss:SetText(h.b)
        
        local wName = h.w
        row.Winner:SetText(DTC:GetDisplayColoredName(wName))
        
        row.Voters:SetText(h.v or DTC.L["None"])
        
        row:Show()
        yOffset = yOffset - 20
    end
    content:SetHeight(math.abs(yOffset) + 20)
end

-- 4. CSV Popup
function DTC.HistoryUI:ShowExportPopup()
    local str = DTC.History:GetCSV()
    local p = DTC_ExportPopup
    if not p then
        p = CreateFrame("Frame", "DTC_ExportPopup", frame, "DTC_WindowTemplate")
        p:SetSize(500, 300)
        p:SetPoint("CENTER", 0, 0)
        p:SetFrameStrata("DIALOG")
        if p.SetTitle then p:SetTitle(DTC.L["Export Data (Ctrl+C)"]) 
        elseif p.TitleText then p.TitleText:SetText(DTC.L["Export Data (Ctrl+C)"]) end
        
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

-- 5. Dropdown Init Helpers (Fixed Checkboxes)
function DTC.HistoryUI:InitDateMenu(menu, level)
    local dates = DTC.History:GetUniqueMenus()
    local info = UIDropDownMenu_CreateInfo()
    
    info.text = DTC.L["All Dates"]
    info.value = "ALL"
    info.checked = (DTC.History.Filters.Date == "ALL")
    info.func = function() 
        DTC.History.Filters.Date = "ALL"
        UIDropDownMenu_SetText(menu, DTC.L["All Dates"])
        self:UpdateList() 
    end
    UIDropDownMenu_AddButton(info, level)
    
    for _, d in ipairs(dates) do
        info.text = d
        info.value = d
        info.checked = (DTC.History.Filters.Date == d)
        info.func = function() 
            DTC.History.Filters.Date = d
            UIDropDownMenu_SetText(menu, d)
            self:UpdateList() 
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

function DTC.HistoryUI:InitNameMenu(menu, level)
    local _, names = DTC.History:GetUniqueMenus()
    local info = UIDropDownMenu_CreateInfo()
    
    info.text = DTC.L["All Names"]
    info.value = "ALL"
    info.checked = (DTC.History.Filters.Name == "ALL")
    info.func = function() 
        DTC.History.Filters.Name = "ALL"
        UIDropDownMenu_SetText(menu, DTC.L["All Names"])
        self:UpdateList() 
    end
    UIDropDownMenu_AddButton(info, level)
    
    for _, n in ipairs(names) do
        local colored = DTC:GetDisplayColoredName(n)
        info.text = colored
        info.value = n
        info.checked = (DTC.History.Filters.Name == n)
        info.func = function() 
            DTC.History.Filters.Name = n
            UIDropDownMenu_SetText(menu, colored)
            self:UpdateList() 
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
local folderName, DTC = ...
DTC.VoteFrame = {}
local frame, rows, headers = nil, {}, {}

function DTC.VoteFrame:Init()
    frame = DTC_VoteFrame
    
    frame.FinalizeBtn:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:Finalize() end end)
    frame.AnnounceBtn:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:Announce() end end)
    
    if frame.SetTitle then frame:SetTitle("Voting Window") end
end

function DTC.VoteFrame:Toggle()
    if not frame then self:Init() end
    if frame:IsShown() then frame:Hide() else self:UpdateHeader(); frame:Show(); self:UpdateList() end
end

function DTC.VoteFrame:UpdateHeader()
    if not frame then return end
    local titleText = DTC.Vote and DTC.Vote.currentBoss or "Unknown Boss"
    if DTC.Vote and DTC.Vote.isTestMode then
        titleText = "(Test) " .. titleText
    else
        local _, _, _, _, _, _, _, _, _, diffName = GetInstanceInfo()
        if diffName and diffName ~= "" then titleText = "(" .. diffName .. ") " .. titleText end
    end
    if frame.SetTitle then frame:SetTitle("Voting: " .. titleText) end
end

function DTC.VoteFrame:UpdateList()
    if not frame or not frame:IsShown() then return end
    
    for _, row in ipairs(rows) do row:Hide() end
    for _, hdr in ipairs(headers) do hdr:Hide() end
    
    if not DTC.Vote then return end
    
    local content = frame.ListScroll.Content
    local yOffset = -5
    local isLeader = UnitIsGroupLeader("player") or (DTC.Vote and DTC.Vote.isTestMode)
    
    frame.FinalizeBtn:SetShown(isLeader and DTC.Vote.isOpen)
    frame.AnnounceBtn:SetShown(isLeader)
    
    local roster = DTC.Vote:GetRosterData()
    local sortMode = DTCRaidDB.settings.voteSortMode or "ROLE"
    
    if sortMode == "ALPHA" then
        table.sort(roster, function(a,b) return a.name < b.name end)
        yOffset = self:RenderSection(content, "", roster, yOffset)
    else
        local t, h, d = {}, {}, {}
        for _, p in ipairs(roster) do
            if p.role == "TANK" then table.insert(t, p)
            elseif p.role == "HEALER" then table.insert(h, p)
            else table.insert(d, p) end
        end
        yOffset = self:RenderSection(content, "TANKS", t, yOffset)
        yOffset = self:RenderSection(content, "HEALERS", h, yOffset)
        yOffset = self:RenderSection(content, "DPS / OTHERS", d, yOffset)
    end
    
    if DTC.Vote.isOpen then
        frame.VotesLeft:SetText("Votes: " .. (DTC.Vote.myVotesLeft or 0))
        frame.VotesLeft:SetTextColor(1, 1, 1)
    else
        frame.VotesLeft:SetText("LOCKED")
        frame.VotesLeft:SetTextColor(1, 0, 0)
    end
end

function DTC.VoteFrame:GetHeader(parent)
    for _, h in ipairs(headers) do
        if not h:IsShown() then return h end
    end
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetJustifyH("LEFT")
    h:SetTextColor(1, 0.82, 0)
    table.insert(headers, h)
    return h
end

function DTC.VoteFrame:RenderSection(parent, title, list, yOffset)
    if #list == 0 then return yOffset end
    
    if title ~= "" then
        local hdr = self:GetHeader(parent)
        hdr:SetPoint("TOPLEFT", 5, yOffset)
        hdr:SetText(title)
        hdr:Show()
        yOffset = yOffset - 20
    end
    
    table.sort(list, function(a,b) return a.name < b.name end)
    
    for i, p in ipairs(list) do
        local row = rows[#rows + 1]
        if not row then
            row = CreateFrame("Frame", nil, parent)
            row:SetSize(330, 24)
            
            row.StatusIcon = row:CreateTexture(nil, "OVERLAY")
            row.StatusIcon:SetSize(16, 16)
            row.StatusIcon:SetPoint("LEFT", 0, 0)
            
            row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.Name:SetPoint("LEFT", 20, 0)
            
            row.VoteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.VoteBtn:SetSize(50, 20); row.VoteBtn:SetPoint("RIGHT", -5, 0); row.VoteBtn:SetText("Vote")
            
            row.Count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Count:SetPoint("RIGHT", -60, 0)
            
            table.insert(rows, row)
        end
        
        row:SetPoint("TOPLEFT", 5, yOffset)
        row:Show()
        
        local color = RAID_CLASS_COLORS[p.class] or {r=1,g=1,b=1}
        row.Name:SetTextColor(color.r, color.g, color.b)
        row.Name:SetText(p.nick and (p.name.." ("..p.nick..")") or p.name)
        
        -- UPDATED STATUS LOGIC
        if p.hasVoted then
            -- Voted (Green Check)
            row.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
        elseif not p.hasAddon then
            -- No Addon (Red X)
            row.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
        elseif p.versionMismatch then
            -- Has Addon, Wrong Version (Yellow Alert)
            row.StatusIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
        else
            -- Has Addon, Waiting (Gray Question)
            row.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
        end
        
        row.VoteBtn:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:CastVote(p.name) end end)
        local canVote = DTC.Vote and DTC.Vote.isOpen and (DTC.Vote.myVotesLeft > 0)
        local already = DTC.Vote and DTC.Vote:HasVotedFor(p.name)
        if canVote and not already then row.VoteBtn:Enable() else row.VoteBtn:Disable() end
        
        row.Count:SetText((DTC.Vote and DTC.Vote:GetVoteCount(p.name)) or 0)
        yOffset = yOffset - 24
    end
    return yOffset - 5
end
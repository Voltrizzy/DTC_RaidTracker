-- ============================================================================
-- DTC Raid Tracker - UI/VoteFrame.lua
-- ============================================================================
-- This file manages the main Voting Window UI. It handles rendering the roster,
-- updating vote counts, and providing interaction buttons for Voting, Bribing, and Lobbying.

local folderName, DTC = ...
DTC.VoteFrame = {}
local frame, rows, headers = nil, {}, {}

-- Initializes the Vote Frame UI elements and scripts.
function DTC.VoteFrame:Init()
    frame = DTC_VoteFrame
    
    if not frame.SetTitle then
        if not frame.TitleText then
            frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.TitleText:SetPoint("TOP", 0, -5)
        end
        frame.SetTitle = function(self, text) self.TitleText:SetText(text) end
    end
    
    -- Ensure title doesn't overlap close button
    if frame.TitleText then
        frame.TitleText:SetWidth(frame:GetWidth() - 60)
        frame.TitleText:SetWordWrap(false)
    end
    
    -- Boss Info Label (Inside Frame)
    frame.BossInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.BossInfo:SetPoint("TOP", 0, -30)
    frame.BossInfo:SetWidth(frame:GetWidth() - 20)
    frame.BossInfo:SetWordWrap(false)
    
    -- Adjust ScrollFrame to make room for Boss Info
    if frame.ListScroll then
        frame.ListScroll:ClearAllPoints()
        frame.ListScroll:SetPoint("TOPLEFT", 10, -55)
        frame.ListScroll:SetPoint("BOTTOMRIGHT", -30, 65)
    end

    frame.FinalizeBtn:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:Finalize() end end)
    frame.AnnounceBtn:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:Announce() end end)
    
    if frame.PropBtn then
        frame.PropBtn:SetScript("OnClick", function() if DTC.BribeUI then DTC.BribeUI:OpenPropInput() end end)
    end
    
    -- TIMER ANIMATION
    frame.TimerBar:SetScript("OnUpdate", function(self, elapsed)
        if not DTC.Vote or not DTC.Vote.isOpen then 
            self:SetValue(0)
            return 
        end
        
        local start = DTC.Vote.sessionStartTime or 0
        local duration = DTC.Vote.sessionDuration or 180
        local now = GetTime()
        local remaining = duration - (now - start)
        
        if remaining < 0 then remaining = 0 end
        
        self:SetMinMaxValues(0, duration)
        self:SetValue(remaining)
        self:SetStatusBarColor(0.5, 0.05, 0.05) -- Dark Red
    end)
    
    frame:SetTitle("DTC Tracker - Vote")
end

-- Toggles the visibility of the Vote Frame.
function DTC.VoteFrame:Toggle()
    if not frame then self:Init() end
    if frame:IsShown() then frame:Hide() else self:UpdateHeader(); frame:Show(); self:UpdateList() end
end

-- Updates the window title with the current boss name and difficulty.
function DTC.VoteFrame:UpdateHeader()
    if not frame then return end
    local titleText = DTC.Vote and DTC.Vote.currentBoss or "Unknown Boss"
    if DTC.Vote and DTC.Vote.isTestMode then titleText = "(Test) " .. titleText
    else
        local _, _, _, diffName = GetInstanceInfo()
        if diffName and diffName ~= "" then titleText = "(" .. diffName .. ") " .. titleText end
    end
    frame:SetTitle("DTC Tracker - Vote")
    if frame.BossInfo then frame.BossInfo:SetText(titleText) end
end

-- Refreshes the list of players in the voting window.
function DTC.VoteFrame:UpdateList()
    if not frame or not frame:IsShown() then return end
    for _, row in ipairs(rows) do row:Hide() end
    for _, hdr in ipairs(headers) do hdr:Hide() end
    if not DTC.Vote then return end
    
    local content = frame.ListScroll.Content
    local yOffset = -5
    local isLeader = UnitIsGroupLeader("player") or (DTC.Vote and DTC.Vote.isTestMode)
    local isOpen = DTC.Vote.isOpen
    
    -- UPDATE FOOTER BUTTONS
    -- Dynamically anchor buttons to ensure they stack to the left
    local lastFrame = nil
    local padding = 5
    
    if isLeader and isOpen then
        frame.FinalizeBtn:Show()
        frame.FinalizeBtn:ClearAllPoints()
        frame.FinalizeBtn:SetPoint("BOTTOMLEFT", 5, 32)
        lastFrame = frame.FinalizeBtn
    else
        frame.FinalizeBtn:Hide()
    end
    
    if isLeader then
        frame.AnnounceBtn:Show()
        frame.AnnounceBtn:ClearAllPoints()
        if lastFrame then frame.AnnounceBtn:SetPoint("LEFT", lastFrame, "RIGHT", padding, 0)
        else frame.AnnounceBtn:SetPoint("BOTTOMLEFT", 5, 32) end
        lastFrame = frame.AnnounceBtn
    else
        frame.AnnounceBtn:Hide()
    end
    
    if frame.PropBtn then
        local canProp = isOpen and (DTC.Vote.myVotesLeft > 0)
        if canProp then
            frame.PropBtn:Show()
            frame.PropBtn:ClearAllPoints()
            if lastFrame then frame.PropBtn:SetPoint("LEFT", lastFrame, "RIGHT", padding, 0)
            else frame.PropBtn:SetPoint("BOTTOMLEFT", 5, 32) end
        else
            frame.PropBtn:Hide()
        end
    end
    
    if isOpen then
        local left = DTC.Vote.myVotesLeft or 0
        if left < 0 then left = 0 end
        frame.VotesLeft:SetText("Votes: " .. left)
        frame.VotesLeft:SetTextColor(1, 1, 1)
    else
        frame.VotesLeft:SetText("CLOSED")
        frame.VotesLeft:SetTextColor(1, 0, 0)
    end

    -- RENDER ROWS
    local roster = DTC.Vote:GetRosterData()
    local sortMode = DTCRaidDB.settings.voteSortMode or "ROLE"
    local rowIndex = 1
    
    if sortMode == "ALPHA" then
        table.sort(roster, function(a,b) return a.name < b.name end)
        rowIndex, yOffset = self:RenderSection(content, "", roster, rowIndex, yOffset)
    else
        local t, h, d = {}, {}, {}
        for _, p in ipairs(roster) do
            if p.role == "TANK" then table.insert(t, p)
            elseif p.role == "HEALER" then table.insert(h, p)
            else table.insert(d, p) end
        end
        rowIndex, yOffset = self:RenderSection(content, "TANKS", t, rowIndex, yOffset)
        rowIndex, yOffset = self:RenderSection(content, "HEALERS", h, rowIndex, yOffset)
        rowIndex, yOffset = self:RenderSection(content, "DPS / OTHERS", d, rowIndex, yOffset)
    end

    -- CRITICAL FIX: Resize the content frame so scrolling works and items aren't clipped!
    local totalHeight = math.abs(yOffset) + 20
    content:SetHeight(totalHeight)
end

-- Retrieves or creates a header font string from the pool.
function DTC.VoteFrame:GetHeader(parent)
    for _, h in ipairs(headers) do if not h:IsShown() then return h end end
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetJustifyH("LEFT"); h:SetTextColor(1, 0.82, 0)
    table.insert(headers, h)
    return h
end

-- Renders a section of the player list (e.g., "TANKS", "HEALERS").
function DTC.VoteFrame:RenderSection(parent, title, list, rowIndex, yOffset)
    if #list == 0 then return rowIndex, yOffset end
    if title ~= "" then
        local hdr = self:GetHeader(parent)
        hdr:SetPoint("TOPLEFT", 5, yOffset); hdr:SetText(title); hdr:Show()
        yOffset = yOffset - 20
    end
    
    table.sort(list, function(a,b) return a.name < b.name end)
    
    local hasDebt = DTC.Bribe and DTC.Bribe:HasUnpaidDebt()
    local isOpen = DTC.Vote and DTC.Vote.isOpen
    local myVotesRemaining = DTC.Vote.myVotesLeft > 0
    local isMe = nil

    for i, p in ipairs(list) do
        local row = rows[rowIndex]
        
        if not row then
            row = CreateFrame("Frame", nil, parent)
            row:SetSize(330, 24)
            row.StatusIcon = row:CreateTexture(nil, "OVERLAY"); row.StatusIcon:SetSize(16, 16); row.StatusIcon:SetPoint("LEFT", 0, 0)
            
            row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); row.Name:SetPoint("LEFT", 20, 0)
            row.Name:SetWordWrap(false)
            
            row.DeadbeatIcon = row:CreateTexture(nil, "OVERLAY")
            row.DeadbeatIcon:SetSize(12, 12)
            row.DeadbeatIcon:SetPoint("LEFT", row.Name, "RIGHT", 5, 0)
            row.DeadbeatIcon:SetTexture("Interface\\GroupFrame\\UI-Group-MasterLooter")
            row.DeadbeatIcon:SetVertexColor(1, 0.2, 0.2)

            row.VoteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.VoteBtn:SetSize(50, 20); row.VoteBtn:SetPoint("RIGHT", -5, 0); row.VoteBtn:SetText("Vote")

            row.BribeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.BribeBtn:SetSize(50, 20); row.BribeBtn:SetPoint("RIGHT", row.VoteBtn, "LEFT", -5, 0); row.BribeBtn:SetText("Bribe")

            row.LobbyBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.LobbyBtn:SetSize(50, 20); row.LobbyBtn:SetPoint("RIGHT", row.BribeBtn, "LEFT", -5, 0); row.LobbyBtn:SetText("Lobby")
            
            row.Count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Count:SetPoint("RIGHT", row.LobbyBtn, "LEFT", -10, 0)
            
            -- Prevent Name overlap
            row.Name:SetPoint("RIGHT", row.Count, "LEFT", -25, 0)
            
            table.insert(rows, row)
        end
        
        row:SetPoint("TOPLEFT", 5, yOffset); row:Show()
        row.Name:SetTextColor(1, 1, 1) -- Reset base color, let GetDisplayColoredName handle class colors
        row.Name:SetText(DTC:GetDisplayColoredName(p.name))
        
        if DTC.Bribe and DTC.Bribe:HasUnpaidDebt(p.name) then
            row.DeadbeatIcon:Show()
        else
            row.DeadbeatIcon:Hide()
        end
        
        if p.hasVoted then row.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
        elseif not p.hasAddon then row.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
        elseif p.versionMismatch then row.StatusIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
        else row.StatusIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting") end
        
        isMe = (p.name == UnitName("player"))
        local alreadyVotedFor = DTC.Vote and DTC.Vote:HasVotedFor(p.name)
        local targetVotesCast = DTC.Vote:GetVotesCastBy(p.name)
        local maxVotes = DTCRaidDB.settings.votesPerPerson or 3
        local targetHasVotesLeft = (targetVotesCast < maxVotes)

        -- VOTE
        row.VoteBtn:SetScript("OnClick", function() if DTC.Vote then DTC.Vote:CastVote(p.name) end end)
        if isOpen and myVotesRemaining and not alreadyVotedFor and not isMe then 
            row.VoteBtn:Enable() 
        else 
            row.VoteBtn:Disable() 
        end

        -- BRIBE
        row.BribeBtn:SetScript("OnClick", function() if DTC.BribeUI then DTC.BribeUI:OpenOfferWindow(p.name) end end)
        if isOpen and not isMe and targetHasVotesLeft and not hasDebt then
            row.BribeBtn:Enable()
        else
            row.BribeBtn:Disable()
        end

        -- LOBBY
        row.LobbyBtn:SetScript("OnClick", function() if DTC.BribeUI then DTC.BribeUI:OpenLobbyInput(p.name) end end)
        if isOpen and not isMe and not hasDebt then
            row.LobbyBtn:Enable()
        else
            row.LobbyBtn:Disable()
        end
        
        row.Count:SetText((DTC.Vote and DTC.Vote:GetVoteCount(p.name)) or 0)
        yOffset = yOffset - 24
        rowIndex = rowIndex + 1
    end
    return rowIndex, yOffset - 5
end

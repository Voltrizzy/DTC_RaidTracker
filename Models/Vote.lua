local folderName, DTC = ...
DTC.Vote = {}

-- Local State
DTC.Vote.isOpen = false
DTC.Vote.currentBoss = "Unknown"
DTC.Vote.myVotesLeft = 3
DTC.Vote.votes = {}      -- [Name] = Count (Votes received)
DTC.Vote.voters = {}     -- [Name] = Count (Votes cast by this person)
DTC.Vote.versions = {}   -- [Name] = "x.y.z"
DTC.Vote.myHistory = {}  -- [Name] = true (Who I voted for)
DTC.Vote.isTestMode = false

-- 1. Initialization
function DTC.Vote:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("ENCOUNTER_END")
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "ENCOUNTER_END" then self:OnEncounterEnd(...) end
    end)
end

-- 2. Event Handlers
function DTC.Vote:OnEncounterEnd(encounterID, encounterName, difficultyID, raidSize, endStatus)
    if endStatus ~= 1 then return end
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "raid" then return end
    self:StartSession(encounterName) 
end

-- 3. Session Management
function DTC.Vote:StartSession(bossName, isTest)
    self.isOpen = true
    self.currentBoss = bossName
    self.myVotesLeft = 3
    self.votes = {}
    self.voters = {}      -- Reset to empty
    self.versions = {} 
    self.myHistory = {}
    self.isTestMode = isTest or false
    
    if not isTest then
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PING_ADDON:"..DTC.VERSION, "RAID")
    end
    
    if DTC.VoteFrame then DTC.VoteFrame:Toggle() end
end

function DTC.Vote:EndSession()
    self.isOpen = false
    if DTC.VoteFrame then DTC.VoteFrame:UpdateList() end
end

-- 4. Actions
function DTC.Vote:CastVote(targetName)
    if not self.isOpen or self.myVotesLeft <= 0 then return end
    if targetName == UnitName("player") then print("|cFFFF0000DTC:|r You cannot vote for yourself."); return end
    if self.myHistory[targetName] then return end
    
    self.myVotesLeft = self.myVotesLeft - 1
    self.myHistory[targetName] = true
    
    -- Track that *I* cast a vote (Increment count)
    local myName = UnitName("player")
    self.voters[myName] = (self.voters[myName] or 0) + 1
    
    self.votes[targetName] = (self.votes[targetName] or 0) + 1
    
    if not self.isTestMode then
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "VOTE:"..targetName, "RAID")
    end
    if DTC.VoteFrame then DTC.VoteFrame:UpdateList() end
end

function DTC.Vote:Finalize()
    if not self.isOpen then return end
    local raidInfo = GetInstanceInfo()
    local _, _, _, _, _, _, _, _, _, diffName = GetInstanceInfo()
    local dateStr = date("%Y-%m-%d")
    
    for name, count in pairs(self.votes) do
        if count > 0 then
            local payload = string.format("%s,%d,%s,%s,%s,%s", 
                name, count, self.currentBoss, raidInfo, dateStr, diffName or "Normal")
            if not self.isTestMode then
                C_ChatInfo.SendAddonMessage(DTC.PREFIX, "FINALIZE:"..payload, "RAID")
            end
        end
    end
    
    local bossDisplay = self.currentBoss
    if diffName and diffName ~= "" then bossDisplay = "("..diffName..") " .. self.currentBoss end
    local msg = DTCRaidDB.settings.voteFinalizeMsg or "Voting has been finalized for %s!"
    SendChatMessage(msg:format(bossDisplay), "RAID")
    
    self:EndSession()
end

-- 5. Announcement Logic
function DTC.Vote:Announce()
    local function GetRealNameByNick(targetNick)
        if not DTCRaidDB.identities then return nil end
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name and DTCRaidDB.identities[name] == targetNick then return name end
        end
        for name, _ in pairs(self.votes) do
            if DTCRaidDB.identities[name] == targetNick then return name end
        end
        return nil
    end

    local pinkRealName = GetRealNameByNick("Pink")
    local macRealName = GetRealNameByNick("Mac")
    local sorted = {}
    
    for n, v in pairs(self.votes) do
        local effectiveVotes = v
        if pinkRealName and n == macRealName then
            local pinkVotes = self.votes[pinkRealName] or 0
            if effectiveVotes >= pinkVotes then effectiveVotes = pinkVotes - 1 end
        end
        table.insert(sorted, {name=n, val=effectiveVotes}) 
    end
    
    table.sort(sorted, function(a,b) return a.val > b.val end)
    
    local _, _, _, _, _, _, _, _, _, diffName = GetInstanceInfo()
    local bossDisplay = self.currentBoss
    if diffName and diffName ~= "" then bossDisplay = "("..diffName..") " .. self.currentBoss end
    
    local header = DTCRaidDB.settings.voteAnnounceHeader or "--- DTC Results: %s ---"
    SendChatMessage(header:format(bossDisplay), "RAID")
    
    if pinkRealName and macRealName and self.votes[macRealName] and (self.votes[macRealName] >= (self.votes[pinkRealName] or 0)) then
        SendChatMessage("(Mac Penalty Rule Active: Mac votes capped below Pink)", "RAID")
    end
    
    for i=1, math.min(3, #sorted) do
        local dName = DTC.Utils and DTC.Utils:GetAnnounceName(sorted[i].name) or sorted[i].name
        SendChatMessage(i..". "..dName.." ("..sorted[i].val.." pts)", "RAID")
    end
    
    if sorted[1] then
        local winMsg = DTCRaidDB.settings.voteWinMsg or "Congrats %s!"
        local wName = DTC.Utils and DTC.Utils:GetAnnounceName(sorted[1].name) or sorted[1].name
        SendChatMessage(winMsg:format(wName), "RAID")
    end
end

-- 6. Data Provider
function DTC.Vote:GetRosterData()
    local roster = {}
    if self.isTestMode then
        return {
            {name="Mickey", class="MAGE", role="DAMAGER", hasVoted=true, hasAddon=true, versionMismatch=false},
            {name="Donald", class="WARRIOR", role="TANK", hasVoted=false, hasAddon=true, versionMismatch=true}, 
            {name="Goofy", class="PRIEST", role="HEALER", hasVoted=false, hasAddon=false, versionMismatch=false}
        }
    end
    
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, classFile, _, _, _, role = GetRaidRosterInfo(i)
        if name then
            local nick = DTCRaidDB.identities and DTCRaidDB.identities[name]
            local hasAddon = (self.versions[name] ~= nil)
            local mismatch = false
            if hasAddon and self.versions[name] ~= DTC.VERSION then mismatch = true end
            
            -- Check "hasVoted" (True if count > 0)
            local voteCount = self.voters[name] or 0
            local hasVotedBool = (voteCount > 0)

            table.insert(roster, {
                name = name,
                class = classFile,
                role = role,
                nick = nick,
                hasVoted = hasVotedBool,
                hasAddon = hasAddon,
                versionMismatch = mismatch
            })
        end
    end
    return roster
end

function DTC.Vote:GetVoteCount(name) return self.votes[name] or 0 end
function DTC.Vote:HasVotedFor(name) return self.myHistory[name] end

-- NEW HELPER: Get number of votes cast by a specific player
function DTC.Vote:GetVotesCastBy(name)
    return self.voters[name] or 0
end

-- 7. Comms
function DTC.Vote:OnComm(action, data, sender)
    if action == "VOTE" then
        if sender ~= UnitName("player") then
            local target = data
            self.votes[target] = (self.votes[target] or 0) + 1
            
            -- Increment Voter Count
            self.voters[sender] = (self.voters[sender] or 0) + 1
            
            if DTC.VoteFrame then DTC.VoteFrame:UpdateList() end
        end
        
    elseif action == "PING_ADDON" then
        C_ChatInfo.SendAddonMessage(DTC.PREFIX, "PONG_ADDON:"..DTC.VERSION, "RAID")
        
    elseif action == "PONG_ADDON" then
        self.versions[sender] = data or "Unknown"
        if DTC.VoteFrame then DTC.VoteFrame:UpdateList() end
    end
end

DTC.Vote:Init()

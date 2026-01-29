local folderName, DTC = ...
DTC.History = {}

-- 1. Mock Data
local MOCK_DATA = {
    {d="2026-01-28", r="Nerub-ar Palace", diff="Mythic", b="Queen Ansurek", w="Mickey", p=1, v="20"},
    {d="2026-01-27", r="Nerub-ar Palace", diff="Heroic", b="Silken Court", w="Donald", p=1, v="19"},
    {d="2026-01-20", r="Liberation of Undermine", diff="Normal", b="Gallywix", w="Goofy", p=1, v="5"},
    {d="2026-01-15", r="Liberation of Undermine", diff="LFR", b="Headless Horseman", w="Minnie", p=1, v="2"}
}

DTC.History.Filters = { Date = "ALL", Name = "ALL" }

-- 2. Fetch Data
function DTC.History:GetData(isTestMode)
    if isTestMode then return MOCK_DATA end
    
    local raw = DTCRaidDB.history or {}
    local filtered = {}
    local f = self.Filters
    
    for _, h in ipairs(raw) do
        local pass = true
        if f.Date ~= "ALL" and h.d ~= f.Date then pass = false end
        if f.Name ~= "ALL" and h.w ~= f.Name then pass = false end
        if pass then table.insert(filtered, h) end
    end
    
    table.sort(filtered, function(a,b) return a.d > b.d end)
    return filtered
end

-- 3. Shared Filter Logic (Used by Purge and Sync)
function DTC.History:MatchesFilter(h, f)
    -- Date Filter
    if f.date and f.date ~= "ALL" and h.d ~= f.date then return false end
    
    -- Diff Filter
    if f.diff and f.diff ~= "ALL" and h.diff ~= f.diff then return false end
    
    -- Raid Filter (Specific)
    if f.raid and f.raid ~= "ALL" then
        if h.r ~= f.raid then return false end
    end
    
    -- Expansion Filter (If Raid is ALL, we must check if h.r belongs to Exp)
    if f.exp and f.exp ~= "ALL" and f.raid == "ALL" then
        local expID = tonumber(f.exp)
        local validRaids = DTC.Static and DTC.Static.RAID_DATA[expID]
        if validRaids then
            local isMatch = false
            for _, rName in ipairs(validRaids) do
                if h.r == rName then isMatch = true; break end
            end
            if not isMatch then return false end
        end
    end
    
    return true
end

-- 4. Purge Logic
function DTC.History:PurgeMatching(filters)
    local kept = {}
    local count = 0
    local raw = DTCRaidDB.history or {}
    
    for _, h in ipairs(raw) do
        if self:MatchesFilter(h, filters) then
            count = count + 1 -- Drop it (Purge)
        else
            table.insert(kept, h) -- Keep it
        end
    end
    
    DTCRaidDB.history = kept
    print("|cFFFFD700DTC:|r Purged " .. count .. " entries.")
    
    if DTC.HistoryUI and DTC.HistoryUI.UpdateList then DTC.HistoryUI:UpdateList() end
    if DTC.LeaderboardUI and DTC.LeaderboardUI.UpdateList then DTC.LeaderboardUI:UpdateList() end
end

-- 5. Sync Push Logic
function DTC.History:PushSync(target, filters)
    if not target or target == "" then print("Invalid target."); return end
    
    local raw = DTCRaidDB.history or {}
    local count = 0
    
    print("|cFFFFD700DTC:|r Sending data to " .. target .. "...")
    
    for _, h in ipairs(raw) do
        if self:MatchesFilter(h, filters) then
            -- Format: Boss,Winner,Points,Date,Raid,Diff,Voters
            local payload = string.format("%s,%s,%d,%s,%s,%s,%s", 
                h.b or "?", h.w or "?", h.p or 0, h.d or "?", h.r or "?", h.diff or "", h.v or "")
            
            C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_PUSH:"..payload, "WHISPER", target)
            count = count + 1
        end
    end
    print("|cFFFFD700DTC:|r Sent " .. count .. " entries.")
end

-- 6. Receiver Logic (OnComm)
function DTC.History:OnComm(action, data, sender)
    if action == "SYNC_PUSH" then
        -- Parse CSV: Boss,Winner,Points,Date,Raid,Diff,Voters
        local boss, winner, pts, dateStr, raid, diff, voters = strsplit(",", data)
        
        if boss and winner and dateStr then
            local newEntry = {
                b = boss,
                w = winner,
                p = tonumber(pts) or 0,
                d = dateStr,
                r = raid,
                diff = diff,
                v = voters
            }
            
            -- Prevent Duplicates
            local isDup = false
            for _, h in ipairs(DTCRaidDB.history) do
                if h.d == newEntry.d and h.b == newEntry.b and h.w == newEntry.w and h.r == newEntry.r then
                    isDup = true
                    break
                end
            end
            
            if not isDup then
                table.insert(DTCRaidDB.history, newEntry)
                print("|cFF00FF00DTC:|r Received entry from " .. sender)
                
                -- Refresh UI if open
                if DTC.HistoryUI and DTC.HistoryUI.UpdateList then DTC.HistoryUI:UpdateList() end
            end
        end
    end
end

-- 7. Helpers
function DTC.History:GetUniqueMenus()
    local dates, names = {}, {}
    local seenD, seenN = {}, {}
    for _, h in ipairs(DTCRaidDB.history or {}) do
        if not seenD[h.d] then seenD[h.d]=true; table.insert(dates, h.d) end
        if not seenN[h.w] then seenN[h.w]=true; table.insert(names, h.w) end
    end
    table.sort(dates, function(a,b) return a > b end)
    table.sort(names)
    return dates, names
end

function DTC.History:GetCSV()
    local data = self:GetData(false)
    local buffer = { "Date,Raid,Diff,Boss,Winner,Points,Voters" }
    for _, h in ipairs(data) do
        table.insert(buffer, string.format("%s,%s,%s,%s,%s,%d,%s", h.d, h.r, h.diff, h.b, h.w, h.p, h.v))
    end
    return table.concat(buffer, "\n")
end
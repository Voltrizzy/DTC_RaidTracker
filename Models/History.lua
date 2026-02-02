-- ============================================================================
-- DTC Raid Tracker - Models/History.lua
-- ============================================================================
-- This file contains the logic for managing history data, including fetching,
-- filtering, purging, and synchronizing records between players.

local folderName, DTC = ...
DTC.History = {}

local DELIMITER = "||"

-- 1. Mock Data
local MOCK_DATA = {
    {d="2026-01-28", r="Nerub-ar Palace", diff="Mythic", b="Queen Ansurek", w="Mickey", p=1, v="20"},
    {d="2026-01-27", r="Nerub-ar Palace", diff="Heroic", b="Silken Court", w="Donald", p=1, v="19"},
    {d="2026-01-20", r="Liberation of Undermine", diff="Normal", b="Gallywix", w="Goofy", p=1, v="5"},
    {d="2026-01-15", r="Liberation of Undermine", diff="LFR", b="Headless Horseman", w="Minnie", p=1, v="2"}
}

DTC.History.Filters = { Date = "ALL", Name = "ALL" }

-- 2. Fetch Data
-- Retrieves history data, applying current filters.
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
-- Checks if a history entry matches a given set of filters.
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
-- Permanently deletes history entries that match the given filters.
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
    print(DTC.L["|cFFFFD700DTC:|r Purged %d entries."]:format(count))
    
    if DTC.HistoryUI and DTC.HistoryUI.UpdateList then DTC.HistoryUI:UpdateList() end
    if DTC.LeaderboardUI and DTC.LeaderboardUI.UpdateList then DTC.LeaderboardUI:UpdateList() end
end

-- 5. Sync Push Logic
-- Sends matching history entries to a target player via addon message.
function DTC.History:PushSync(target, filters)
    if not target or target == "" then print(DTC.L["Invalid target."]); return end
    
    local raw = DTCRaidDB.history or {}
    local count = 0
    
    print(DTC.L["|cFFFFD700DTC:|r Sending data to %s..."]:format(target))
    
    for _, h in ipairs(raw) do
        if self:MatchesFilter(h, filters) then
            -- Format: Boss||Winner||Points||Date||Raid||Diff||Voters
            local payload = table.concat({
                (h.b or "?"):gsub(DELIMITER, ""),
                (h.w or "?"):gsub(DELIMITER, ""),
                h.p or 0,
                h.d or "?",
                (h.r or "?"):gsub(DELIMITER, ""),
                h.diff or "",
                (h.v or ""):gsub(DELIMITER, "")
            }, DELIMITER)
            
            local fullTarget = DTC.Utils:GetFullName(target)
            C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_PUSH:"..payload, "WHISPER", fullTarget)
            count = count + 1
        end
    end
    print(DTC.L["|cFFFFD700DTC:|r Sent %d entries."]:format(count))
end

-- 6. Receiver Logic (OnComm)
-- Handles incoming history data synchronization messages.
local commHandlers = {
    ["SYNC_PUSH"] = function(self, data, sender)
        -- Parse DSV: Boss||Winner||Points||Date||Raid||Diff||Voters
        local boss, winner, pts, dateStr, raid, diff, voters = DTC.Utils:SplitString(data, DELIMITER)
        
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
                print(DTC.L["|cFF00FF00DTC:|r Received entry from %s"]:format(sender))
                
                -- Refresh UI if open
                if DTC.HistoryUI and DTC.HistoryUI.UpdateList then DTC.HistoryUI:UpdateList() end
            end
        end
    end,
    ["FINALIZE"] = function(self, data, sender)
        -- payload: name(Winner)||count(Points)||boss||raid||date||diff
        local winner, pts, boss, raid, dateStr, diff = DTC.Utils:SplitString(data, DELIMITER)
        if winner and boss and dateStr then
            local newEntry = {
                b = boss,
                w = winner,
                p = tonumber(pts) or 0,
                d = dateStr,
                r = raid,
                diff = diff,
                v = "?"
            }
            
            local isDup = false
            for _, h in ipairs(DTCRaidDB.history) do
                if h.d == newEntry.d and h.b == newEntry.b and h.w == newEntry.w and h.r == newEntry.r then isDup = true; break end
            end
            
            if not isDup then
                table.insert(DTCRaidDB.history, newEntry)
                if DTC.HistoryUI and DTC.HistoryUI.UpdateList then DTC.HistoryUI:UpdateList() end
                if DTC.LeaderboardUI and DTC.LeaderboardUI.UpdateList then DTC.LeaderboardUI:UpdateList() end
            end
        end
    end
}

function DTC.History:OnComm(action, data, sender)
    if sender and string.find(sender, "-") then sender = strsplit("-", sender) end
    local handler = commHandlers[action]
    if handler then
        handler(self, data, sender)
    end
end

-- 7. Helpers
-- Returns unique lists of dates and winner names for dropdown menus.
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

-- Generates a CSV string of the current history data.
function DTC.History:GetCSV()
    local data = self:GetData(false)
    local buffer = { "Date,Raid,Diff,Boss,Winner,Points,Voters" }
    for _, h in ipairs(data) do
        table.insert(buffer, string.format("%s,%s,%s,%s,%s,%d,%s",
            h.d,
            (h.r or "?"):gsub(",", ""),
            h.diff,
            (h.b or "?"):gsub(",", ""),
            (h.w or "?"):gsub(",", ""),
            h.p,
            (h.v or ""):gsub(",", "")
        ))
    end
    return table.concat(buffer, "\n")
end
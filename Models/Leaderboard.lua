local folderName, DTC = ...
DTC.Leaderboard = {}

DTC.Leaderboard.Filters = {
    Time = "ALL", 
    Exp = "ALL",  
    Raid = "ALL", 
    Boss = "ALL", 
    Diff = "ALL"  
}

function DTC.Leaderboard:GetSortedData(isTestMode)
    if isTestMode then
        return {
            {n="Mickey", v=50, chars={{n="Mickey", v=25}, {n="Steamboat", v=25}}},
            {n="Donald", v=40, chars={{n="Donald", v=40}}},
            {n="Goofy", v=10, chars={{n="Goofy", v=10}}}
        }
    end

    local f = self.Filters
    
    -- TRIPS VIEW
    if f.Time == "TRIPS" then
        local displayData = {}
        for p, v in pairs(DTCRaidDB.trips or {}) do
            local key = DTCRaidDB.identities and DTCRaidDB.identities[p] or p
            displayData[key] = (displayData[key] or 0) + v
        end
        local sorted = {}
        for n, v in pairs(displayData) do table.insert(sorted, {n=n, v=v}) end
        table.sort(sorted, function(a,b) return a.v > b.v end)
        return sorted
    end

    -- AGGREGATE VIEW
    local rawData = {}
    local history = DTCRaidDB.history or {}
    
    -- Filter Set Setup
    local validRaids = nil
    if f.Exp ~= "ALL" and DTC.Static.RAID_DATA[tonumber(f.Exp)] then
        validRaids = {}
        for _, r in ipairs(DTC.Static.RAID_DATA[tonumber(f.Exp)]) do validRaids[r] = true end
    end

    for _, h in ipairs(history) do
        local pass = true
        if validRaids and not validRaids[h.r] then pass = false end
        if f.Raid ~= "ALL" and h.r ~= f.Raid then pass = false end
        if f.Boss ~= "ALL" and h.b ~= f.Boss then pass = false end
        if f.Diff ~= "ALL" and h.diff ~= f.Diff then pass = false end
        
        if pass then rawData[h.w] = (rawData[h.w] or 0) + h.p end
    end

    local nickData = {}
    for charName, val in pairs(rawData) do
        local nick = (DTCRaidDB.identities and DTCRaidDB.identities[charName]) or charName
        if not nickData[nick] then nickData[nick] = { total=0, chars={} } end
        nickData[nick].total = nickData[nick].total + val
        table.insert(nickData[nick].chars, {n=charName, v=val})
    end

    local sorted = {}
    for n, data in pairs(nickData) do table.insert(sorted, {n=n, v=data.total, chars=data.chars}) end
    table.sort(sorted, function(a,b) return a.v > b.v end)
    
    return sorted
end

function DTC.Leaderboard:GetBossList(raidName)
    -- Pull from Static Data
    return DTC.Static:GetBossList(raidName)
end

function DTC.Leaderboard:AwardTrip(winnerNickname)
    DTCRaidDB.trips = DTCRaidDB.trips or {}
    DTCRaidDB.trips[winnerNickname] = (DTCRaidDB.trips[winnerNickname] or 0) + 1
    C_ChatInfo.SendAddonMessage(DTC.PREFIX, "SYNC_DATA:TRIP,"..winnerNickname..","..DTCRaidDB.trips[winnerNickname], "RAID")
    return DTCRaidDB.trips[winnerNickname]
end
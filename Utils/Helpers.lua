local folderName, DTC = ...
DTC.Utils = {}

-- Helper to format names for chat announcements
function DTC.Utils:GetAnnounceName(fullName)
    if not fullName then return "Unknown" end
    
    local canonical = self:GetCanonicalName(fullName)
    -- 1. Check for Nickname Override
    if DTCRaidDB.identities and DTCRaidDB.identities[canonical] and DTCRaidDB.identities[canonical] ~= "" then
        return DTCRaidDB.identities[canonical]
    end
    
    -- 2. Strip Realm Name (e.g. "Player-Realm" -> "Player")
    if string.find(fullName, "-") then
        local name, realm = strsplit("-", fullName)
        return name
    end
    
    return fullName
end

-- Helper to split a string by a multi-character delimiter
function DTC.Utils:SplitString(str, delim)
    local res = {}
    local start = 1
    local dlen = #delim
    while true do
        local pos = string.find(str, delim, start, true)
        if not pos then
            table.insert(res, string.sub(str, start))
            break
        end
        table.insert(res, string.sub(str, start, pos - 1))
        start = pos + dlen
    end
    return unpack(res)
end

-- Helper to check if a sender name corresponds to the raid leader
function DTC.Utils:IsSenderLeader(sender)
    if not IsInRaid() then return true end
    for i = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if rank == 2 then
            if name and string.find(name, "-") then name = strsplit("-", name) end
            return sender == name
        end
    end
    return false
end

-- Helper to generate unique IDs
local lastIDTime = 0
function DTC.Utils:GenerateUniqueID(sender)
    local now = GetTime()
    if now <= lastIDTime then now = lastIDTime + 0.001 end
    lastIDTime = now
    return string.format("%.3f-%s", now, sender or "Unknown")
end

-- Helper to ensure name is Name-Realm
function DTC.Utils:GetCanonicalName(name)
    if not name then return nil end
    if string.find(name, "-") then return name end
    local r = GetRealmName()
    if r then return name .. "-" .. r:gsub(" ", "") end
    return name
end

-- Returns the full name (Name-Realm) of a player if they are in the raid group.
-- Useful for whispering players cross-realm.
function DTC.Utils:GetFullName(shortName)
    if not IsInRaid() then return shortName end
    for i=1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            if self:GetCanonicalName(name) == self:GetCanonicalName(shortName) then return name end
        end
    end
    return shortName
end

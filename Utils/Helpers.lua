local folderName, DTC = ...
DTC.Utils = {}

-- Helper to format names for chat announcements
function DTC.Utils:GetAnnounceName(fullName)
    if not fullName then return "Unknown" end
    
    -- 1. Check for Nickname Override
    if DTCRaidDB.identities and DTCRaidDB.identities[fullName] and DTCRaidDB.identities[fullName] ~= "" then
        return DTCRaidDB.identities[fullName]
    end
    
    -- 2. Strip Realm Name (e.g. "Player-Realm" -> "Player")
    if string.find(fullName, "-") then
        local name, realm = strsplit("-", fullName)
        return name
    end
    
    return fullName

-- Add to your existing table, e.g., DTC.Utils or local Utils
function DTC.Utils.CanOpenVoteWindow()
    local _, instanceType = GetInstanceInfo()

    -- instanceType return values: "none" (Open World), "party" (Dungeon), "raid", "pvp", "arena"

    -- 1. STRICTLY BLOCK 5-man Dungeons
    if instanceType == "party" then
        return false
    end

    -- 2. ALLOW Raids
    if instanceType == "raid" then
        return true
    end

    -- 3. ALLOW Open World (instanceType is "none") for testing
    if instanceType == "none" then
        return true
    end

    -- Default: Block everything else (Scenarios, PVP, Arena) to be safe
    return false
end

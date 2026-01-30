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
end

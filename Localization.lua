local folderName, DTC = ...
DTC.L = {}

-- Metatable to return the key itself if translation is missing
setmetatable(DTC.L, {
    __index = function(t, k) return k end
})
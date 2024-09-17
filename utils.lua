local addonName, addonTable = ...

function addonTable:IsInRaid()
    return GetNumRaidMembers() > 0
end

function addonTable:IsInGroup()
    return GetNumPartyMembers() > 0
end

function addonTable:GetNumGroupMembers()
    local rm = GetNumRaidMembers()
    return (rm > 0 and rm) or GetNumPartyMembers()
end

function addonTable:GetNumSubgroupMembers()
    return GetNumPartyMembers()
end
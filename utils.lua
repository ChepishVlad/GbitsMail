local addonName, addonTable = ...

local class_colors = {
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["PRIEST"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["SHAMAN"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["MAGE"] = { r = 0.41, g = 0.80, b = 0.94 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["DRUID"] = { r = 1.00, g = 0.49, b = 0.04 },
    ["Воин"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["Паладин"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["Охотник"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["Охотница"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["Разбойник"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["Разбойница"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["Жрец"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["Жрица"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["Рыцарь смерти"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["Шаман"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["Шаманка"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["Маг"] = { r = 0.41, g = 0.80, b = 0.94 },
    ["Чернокнижник"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["Чернокнижница"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["Друид"] = { r = 1.00, g = 0.49, b = 0.04 },
}

function addonTable:GetColoredText(class, text)
    local color = class_colors[class]
    if color then
        return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
    else
        return text  -- Если класс не найден, возвращаем обычный текст
    end
end

function addonTable:SortRaiders(raiders, column, ascending)
    table.sort(raiders, function(a, b)
        if ascending then
            return a[column] < b[column]
        else
            return a[column] > b[column]
        end
    end)
end

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------- Raids util functions -------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Function for getting list name of raids
function addonTable:GetRaidNames(raiders)
    local raidNames = {}
    for i, raid in ipairs(raiders) do
        raidNames[i] = raid.raid_name
    end
    return raidNames
end
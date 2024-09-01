local addonName, addonTable = ...

local GBitsRaidManager = LibStub("AceAddon-3.0"):NewAddon("GBitsRaidManager", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceDB = LibStub("AceDB-3.0")

local raids = {}

function GBitsRaidManager:OnInitialize()
    self.db = AceDB:New("RaidMailDB", {
        profile = {
            Raids = {},
        }
    }, true)
    raids = self.db.profile.Raids
    self:CreateMainFrame()
    self:RegisterChatCommand("raidmanager", "ShowFrame")
end

local function GetRaidersList()
    local raiders = {}
    if IsInRaid() then
        local numRaidMembers = GetNumGroupMembers()
        if numRaidMembers > 0 then
            for i = 1, numRaidMembers do
                local name, _, subgroup, _, class, _, _, _, _, _, classFileName = GetRaidRosterInfo(i)
                table.insert(raiders, {
                    ["name"] = name,
                    ["group"] = subgroup,
                    ["class"] = class,
                    ["cashPercent"] = 100,
                    ["bonus"] = 0,
                    ["penalty"] = 0
                })
            end
        end
    else
        print("Вы не в рейде.")
    end
    return raiders
end


-- Функция для сохранения рейда
function GBitsRaidManager:SaveRaid()
    local raidName = self.raidNameEditBox:GetText()
    local raiders = GetRaidersList()

    if #raiders > 0 then
        table.insert(raids, {["raid_name"] = raidName, ["raiders"] = raiders})
        -- Сообщение об успешном сохранении
        print("Рейд успешно сохранен.")

        -- Выводим имена рейдеров (опционально)
        for _, raider in ipairs(raiders) do
            print(string.format("Рейдер: %s, Группа: %d, Класс: %s", raider.name, raider.group, raider.class))
        end
    else
        print("Не удалось сохранить рейд. Вы не в рейде.")
    end
end

-- Получаем список названий рейдов для выпадающего списка
function GBitsRaidManager:GetRaidNames()
    local raidNames = {}
    for i, raid in ipairs(self.db.profile.Raids or {}) do
        raidNames[i] = raid.raid_name
    end
    return raidNames
end

-- Обработка выбора рейда из выпадающего списка
function GBitsRaidManager:OnRaidSelected(index)
    local selectedRaid = self.db.profile.Raids[index]
    if selectedRaid then
        print("Выбран рейд: " .. selectedRaid.raid_name)
        -- Выводим информацию о рейде или делаем другие действия
        self:DisplayRaidInfo(selectedRaid)
    end
end

-- Функция отображения информации о рейде в виде таблицы
function GBitsRaidManager:DisplayRaidInfo(raid)
    -- Очищаем предыдущую информацию
    self.raidInfoGroup:ReleaseChildren()

    -- Заголовки таблицы
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetLayout("Flow")
    headerGroup:SetFullWidth(true)
    self.raidInfoGroup:AddChild(headerGroup)

    local nameHeader = AceGUI:Create("Label")
    nameHeader:SetText("Name")
    nameHeader:SetWidth(150)
    headerGroup:AddChild(nameHeader)

    local groupHeader = AceGUI:Create("Label")
    groupHeader:SetText("Group")
    groupHeader:SetWidth(50)
    headerGroup:AddChild(groupHeader)

    local classHeader = AceGUI:Create("Label")
    classHeader:SetText("Class")
    classHeader:SetWidth(150)
    headerGroup:AddChild(classHeader)

    local bonusHeader = AceGUI:Create("Label")
    bonusHeader:SetText("Bouns")
    bonusHeader:SetWidth("50")
    headerGroup:AddChild(bonusHeader)

    local penaltyHeader = AceGUI:Create("Label")
    penaltyHeader:SetText("Penalty")
    penaltyHeader:SetWidth("50")
    headerGroup:AddChild(penaltyHeader)

    local percentHeader = AceGUI:Create("Label")
    percentHeader:SetText("Cash %")
    percentHeader:SetWidth(50)
    headerGroup:AddChild(percentHeader)

    -- Заполняем таблицу данными рейда
    for _, raider in ipairs(raid.raiders) do
        local rowGroup = AceGUI:Create("SimpleGroup")
        rowGroup:SetLayout("Flow")
        rowGroup:SetFullWidth(true)
        self.raidInfoGroup:AddChild(rowGroup)

        local nameLabel = AceGUI:Create("Label")
        nameLabel:SetText(raider.name)
        nameLabel:SetWidth(150)
        rowGroup:AddChild(nameLabel)

        local groupLabel = AceGUI:Create("Label")
        groupLabel:SetText(tostring(raider.group))
        groupLabel:SetWidth(50)
        rowGroup:AddChild(groupLabel)

        local classLabel = AceGUI:Create("Label")
        classLabel:SetText(raider.class)
        classLabel:SetWidth(150)
        rowGroup:AddChild(classLabel)

        local bonusLabel = AceGUI:Create("Label")
        bonusLabel:SetText(tostring(raider.bonus))
        bonusLabel:SetWidth(50)
        rowGroup:AddChild(bonusLabel)

        local penaltyLabel = AceGUI:Create("Label")
        penaltyLabel:SetText(tostring(raider.penalty))
        penaltyLabel:SetWidth(50)
        rowGroup:AddChild(penaltyLabel)

        local percentLabel = AceGUI:Create("Label")
        percentLabel:SetText(tostring(raider.cashPercent))
        percentLabel:SetWidth(50)
        rowGroup:AddChild(percentLabel)
    end
end


-- Main frame
function GBitsRaidManager:CreateMainFrame()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("GBitsRaidManager")
    frame:SetStatusText("")
    frame:SetLayout("fill")
    frame:SetWidth(800)
    frame:SetHeight(580)
    frame:Hide()
    self.frame = frame

    -- Создание табов
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetTabs({
        {text = "Raids", value = "raids"},
        --{text = "Raid Manager", value = "raidmanager"}
    })
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
        self:SelectGroup(widget, group)
    end)
    tabGroup:SelectTab("raids")
    frame:AddChild(tabGroup)
    --self.tabGroup = tabGroup
end

function GBitsRaidManager:SelectGroup(container, group)
    container:ReleaseChildren()
    if group == "raids" then
        self:CreateRaidsTab(container)
    --elseif group == "raidmanager" then
    --    self:CreateRaidManagerTab(widget)
    end
end

-- Вкладка "Raids"
function GBitsRaidManager:CreateRaidsTab(container)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetLayout("Flow")
    inlineGroup:SetFullWidth(true)
    container:AddChild(inlineGroup)

    local raidNameEditBox = AceGUI:Create("EditBox")
    raidNameEditBox:SetLabel("Название рейда:")
    raidNameEditBox:SetFullWidth(true)
    inlineGroup:AddChild(raidNameEditBox)
    self.raidNameEditBox = raidNameEditBox

    -- Выпадающий список с сохраненными рейдами
    local raidDropdown = AceGUI:Create("Dropdown")
    raidDropdown:SetLabel("Выберите рейд:")
    raidDropdown:SetFullWidth(true)
    raidDropdown:SetList(self:GetRaidNames()) -- Заполняем список названиями рейдов
    raidDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        self:OnRaidSelected(key)
    end)
    inlineGroup:AddChild(raidDropdown)
    self.raidDropdown = raidDropdown

    local saveRaidButton = AceGUI:Create("Button")
    saveRaidButton:SetText("Сохранить рейд")
    saveRaidButton:SetWidth(200)
    saveRaidButton:SetCallback("OnClick", function()
        self:SaveRaid()
    end)
    inlineGroup:AddChild(saveRaidButton)

    -- Группа для отображения информации о рейде (таблица)
    local raidInfoGroup = AceGUI:Create("InlineGroup")
    raidInfoGroup:SetTitle("Информация о рейде")
    raidInfoGroup:SetFullWidth(true)
    raidInfoGroup:SetLayout("List")
    container:AddChild(raidInfoGroup)
    self.raidInfoGroup = raidInfoGroup
end

-- Вкладка "Raid Manager"
function GBitsRaidManager:CreateRaidManagerTab(container)

end

function GBitsRaidManager:ShowFrame()
    self.frame:Show()
end

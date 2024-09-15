local addonName, addonTable = ...

local GBitsRaidManager = LibStub("AceAddon-3.0"):NewAddon("GBitsRaidManager", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceDB = LibStub("AceDB-3.0")

local raids = {}
local sortColumn = "index"
local sortAscending = true


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
                    ["penalty"] = 0,
                    ["base_cash"] = 0,
                    ["cash"] = 0,
                })
            end
        end
    else
        print("Вы не в рейде.")
        return nil, "Вы не в рейде."
    end
    return raiders
end


-- Функция для сохранения рейда
function GBitsRaidManager:SaveRaid()
    local raidName = self.raidNameEditBox:GetText()

    -- Проверяем, существует ли уже рейд с таким именем
    for _, raid in ipairs(self.db.profile.Raids) do
        if raid.raid_name == raidName then
            self.errorLabel:SetText("Рейд с таким названием уже существует.")
            return
        end
    end

    local raiders, errorMsg = GetRaidersList()

    if raiders then
        if raidName and raidName ~= "" then
            table.insert(raids, {
                ["raid_name"] = raidName,
                ["raiders"] = raiders,
                ["total_cash"] = 0
            })
            self.errorLabel:SetText("") -- Очищаем сообщение об ошибке

            -- Сообщение об успешном сохранении
            print("Рейд успешно сохранен.")

            -- Обновляем списки в дропдаунах
            self:UpdateRaidDropdowns()

            -- Выводим имена рейдеров (опционально)
            for _, raider in ipairs(raiders) do
                print(string.format("Рейдер: %s, Группа: %d, Класс: %s", raider.name, raider.group, raider.class))
            end
        else
            self.errorLabel:SetText("Введите название рейда.")
        end
    else
        self.errorLabel:SetText(errorMsg)
    end
end

-- Функция для удаления рейда
function GBitsRaidManager:DeleteRaid()
    local selectedRaidIndex = self.selectedRaidToDelete

    if not selectedRaidIndex then
        self.errorLabel:SetText("Не выбран рейд для удаления.")
        return
    end

    -- Удаляем рейд
    table.remove(self.db.profile.Raids, selectedRaidIndex)
    self:UpdateRaidDropdowns()

    -- Очищаем сообщение об ошибке
    self.errorLabel:SetText("")

    -- Сообщение об успешном удалении
    print("Рейд успешно удален.")
end

function GBitsRaidManager:UpdateCash()
    local selectedRaid = self.updateCashRaidDropdown:GetValue()
    local inputCash = tonumber(self.raidCashBox:GetText())
    local divider = tonumber(self.dividerCashBox:GetText())
    --print(inputCash)

    if selectedRaid and inputCash then
        local raid = self.db.profile.Raids[self.selectedCashRaid]
        -- Обновляем данные рейда
        raid.total_cash = inputCash

        -- Рассчитываем сумму на участника и обновляем данные участников
        local cashPerMember = math.floor(inputCash / divider)
        for _, raider in pairs(raid.raiders) do
            raider.base_cash = cashPerMember
            raider.cash = math.floor(cashPerMember * ((100 - raider.penalty + raider.bonus) / 100))
        end

        self:UpdateRaidInDatabase(raid)
        -- Выводим сообщение об успешном обновлении
        print("Обновлено! Общая сумма рейда: " .. inputCash .. ", сумма на каждого участника: " .. cashPerMember)
    else
        print("Ошибка: Не выбран рейд или введена некорректная сумма")
    end
end


-- Функция для обновления списков в дропдаунах
function GBitsRaidManager:UpdateRaidDropdowns()
    local raidNames = addonTable:GetRaidNames(self.db.profile.Raids or {})
    self.raidDropdown:SetList(raidNames)
    self.updateRaidDropdown:SetList(raidNames)
    self.deleteRaidDropdown:SetList(raidNames)
end

-- Обработка выбора рейда из выпадающего списка
function GBitsRaidManager:OnRaidSelected(index)
    local selectedRaid = self.db.profile.Raids[index]
    if selectedRaid then
        print("Выбран рейд: " .. selectedRaid.raid_name)
        self:DisplayRaidInfo(selectedRaid)
    end
end

-- Функция отображения информации о рейде в виде таблицы
function GBitsRaidManager:DisplayRaidInfo(raid)
    -- Очищаем предыдущую информацию
    self.raidInfoGroup:ReleaseChildren()

    -- Создаем контейнер с прокруткой
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(320)
    --scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")  -- "Fill" позволяет контейнеру занять всё доступное пространство
    self.raidInfoGroup:AddChild(scrollContainer)

    -- Создаем ScrollFrame для вертикальной прокрутки
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")  -- Используем "Flow" для расположения элементов по вертикали
    scrollContainer:AddChild(scrollFrame)

    -- Заголовки таблицы
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetLayout("Flow")
    headerGroup:SetFullWidth(true)
    scrollFrame:AddChild(headerGroup)

    -- Функция для добавления заголовков с сортировкой
    local function AddHeader(labelText, column, width)
        local header = AceGUI:Create("InteractiveLabel")
        header:SetText(labelText)
        header:SetWidth(width)
        header:SetCallback("OnClick", function()
            -- При нажатии меняем направление сортировки и сортируем данные
            if sortColumn == column then
                sortAscending = not sortAscending
            else
                sortColumn = column
                sortAscending = true
            end
            addonTable:SortRaiders(raid.raiders, column, sortAscending)
            self:DisplayRaidInfo(raid) -- Перерисовываем таблицу с отсортированными данными
        end)
        headerGroup:AddChild(header)
    end

    -- Добавляем заголовки
    AddHeader("№", "index", 30)
    AddHeader("Name", "name", 150)
    AddHeader("Group", "group", 50)
    AddHeader("Class", "class", 150)
    AddHeader("Bonus", "bonus", 50)
    AddHeader("Penalty", "penalty", 50)
    AddHeader("Cash %", "cashPercent", 50)
    AddHeader("Cash", "cash", 50)

    -- Заполняем таблицу данными рейда
    for i, raider in ipairs(raid.raiders) do
        -- Дополняем данные для сортировки по "index"
        raider.index = i

        local rowGroup = AceGUI:Create("SimpleGroup")
        rowGroup:SetLayout("Flow")
        rowGroup:SetFullWidth(true)
        scrollFrame:AddChild(rowGroup)

        -- Порядковый номер строки
        local indexLabel = AceGUI:Create("Label")
        indexLabel:SetText(tostring(i))  -- Используем индекс i как порядковый номер
        indexLabel:SetWidth(30)
        rowGroup:AddChild(indexLabel)

        local nameLabel = AceGUI:Create("Label")
        nameLabel:SetText(addonTable:GetColoredText(raider.class, raider.name))
        nameLabel:SetWidth(150)
        rowGroup:AddChild(nameLabel)

        local groupLabel = AceGUI:Create("Label")
        groupLabel:SetText(tostring(raider.group))
        groupLabel:SetWidth(50)
        rowGroup:AddChild(groupLabel)

        local classLabel = AceGUI:Create("Label")
        classLabel:SetText(addonTable:GetColoredText(raider.class, raider.class))
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

        local cashLabel = AceGUI:Create("Label")
        cashLabel:SetText(tostring(raider.cash or 0))
        cashLabel:SetWidth(50)
        rowGroup:AddChild(cashLabel)

        -- Кнопка Edit
        local editButton = AceGUI:Create("Button")
        editButton:SetText("Edit")
        editButton:SetWidth(100)
        rowGroup:AddChild(editButton)

        -- Обработчик нажатия кнопки "Edit"
        editButton:SetCallback("OnClick", function()
            self:OpenEditFrame(raider, raid)
        end)
    end
end

-- Функция для открытия фрейма редактирования персонажа
function GBitsRaidManager:OpenEditFrame(raider, raid)
    -- Создаем фрейм редактирования
    local editFrame = AceGUI:Create("Frame")
    editFrame:SetTitle("Edit Raider: " .. raider.name)
    editFrame:SetLayout("Flow")
    editFrame:SetWidth(300)
    editFrame:SetHeight(250)

    -- Поле Name (не редактируемое)
    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText("Name: " .. raider.name)
    nameLabel:SetWidth(200)
    editFrame:AddChild(nameLabel)

    -- Поле Group (не редактируемое)
    local groupLabel = AceGUI:Create("Label")
    groupLabel:SetText("Group: " .. tostring(raider.group))
    groupLabel:SetWidth(200)
    editFrame:AddChild(groupLabel)

    -- Поле Class (не редактируемое)
    local classLabel = AceGUI:Create("Label")
    classLabel:SetText("Class: " .. raider.class)
    classLabel:SetWidth(200)
    editFrame:AddChild(classLabel)

    -- Поле Bonus (редактируемое)
    local bonusEdit = AceGUI:Create("EditBox")
    bonusEdit:SetLabel("Bonus")
    bonusEdit:SetText(tostring(raider.bonus))
    bonusEdit:SetWidth(200)
    editFrame:AddChild(bonusEdit)

    -- Поле Penalty (редактируемое)
    local penaltyEdit = AceGUI:Create("EditBox")
    penaltyEdit:SetLabel("Penalty")
    penaltyEdit:SetText(tostring(raider.penalty))
    penaltyEdit:SetWidth(200)
    editFrame:AddChild(penaltyEdit)

    -- Кнопка сохранения
    local saveButton = AceGUI:Create("Button")
    saveButton:SetText("Save")
    saveButton:SetWidth(200)
    editFrame:AddChild(saveButton)

    -- Обработчик сохранения
    saveButton:SetCallback("OnClick", function()
        -- Обновляем данные о бонусе и штрафе
        raider.bonus = tonumber(bonusEdit:GetText()) or raider.bonus
        raider.penalty = tonumber(penaltyEdit:GetText()) or raider.penalty
        raider.cashPercent = 100 + raider.bonus - raider.penalty
        raider.cash = math.floor(raider.base_cash * (raider.cashPercent / 100))

        -- Закрыть фрейм редактирования после сохранения
        editFrame:Hide()

        -- Обновляем данные рейда в базе данных
        self:UpdateRaidInDatabase(raid)

        -- Обновить интерфейс после редактирования
        GBitsRaidManager:DisplayRaidInfo(raid)
    end)
end

-- Функция для обновления рейда в базе данных
function GBitsRaidManager:UpdateRaidInDatabase(updatedRaid)
    for i, raid in ipairs(self.db.profile.Raids) do
        if raid.raid_name == updatedRaid.raid_name then
            -- Заменяем старый рейд новым
            self.db.profile.Raids[i] = updatedRaid
            return
        end
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

    -- TODO сейчас тут вызывается исключение - не нашёл способа сделать без него
    frame.frame:SetResizable(false)

    -- Создание табов
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetTabs({
        {text = "Raids", value = "raids"},
        {text = "Raid Manager", value = "raidmanager"}
    })
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
        self:SelectGroup(widget, group)
    end)
    tabGroup:SelectTab("raids")
    frame:AddChild(tabGroup)
end

function GBitsRaidManager:SelectGroup(container, group)
    container:ReleaseChildren()
    if group == "raids" then
        self:CreateRaidsTab(container)
    elseif group == "raidmanager" then
        self:CreateRaidManagerTab(container)
    end
end

-- Вкладка "Raids"
function GBitsRaidManager:CreateRaidsTab(container)
    -- Блок "Добавление рейда"
    local addRaidGroup = AceGUI:Create("InlineGroup")
    addRaidGroup:SetTitle("Добавление рейда")
    addRaidGroup:SetLayout("Flow")
    addRaidGroup:SetFullWidth(true)
    container:AddChild(addRaidGroup)

    local raidNameEditBox = AceGUI:Create("EditBox")
    raidNameEditBox:SetLabel("Название рейда:")
    raidNameEditBox:SetFullWidth(true)
    addRaidGroup:AddChild(raidNameEditBox)
    self.raidNameEditBox = raidNameEditBox

    local saveRaidButton = AceGUI:Create("Button")
    saveRaidButton:SetText("Сохранить рейд")
    saveRaidButton:SetWidth(200)
    saveRaidButton:SetCallback("OnClick", function()
        self:SaveRaid()
    end)
    addRaidGroup:AddChild(saveRaidButton)

    -- Блок "Обновление рейда"
    local updateRaidGroup = AceGUI:Create("InlineGroup")
    updateRaidGroup:SetTitle("Обновление рейда")
    updateRaidGroup:SetLayout("Flow")
    updateRaidGroup:SetFullWidth(true)
    container:AddChild(updateRaidGroup)

    local updateRaidDropdown = AceGUI:Create("Dropdown")
    updateRaidDropdown:SetLabel("Выберите рейд для обновления:")
    updateRaidDropdown:SetFullWidth(true)
    updateRaidDropdown:SetList(addonTable:GetRaidNames(self.db.profile.Raids or {}))
    updateRaidDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        print("Not implemented yet")
    end)
    updateRaidGroup:AddChild(updateRaidDropdown)
    self.updateRaidDropdown = updateRaidDropdown

    local updateRaidButton = AceGUI:Create("Button")
    updateRaidButton:SetText("Обновить рейд")
    updateRaidButton:SetWidth(200)
    updateRaidButton:SetCallback("OnClick", function()
        print("Not implemented yet")
    end)
    updateRaidGroup:AddChild(updateRaidButton)


    -- Блок "Удаление рейда"
    local deleteRaidGroup = AceGUI:Create("InlineGroup")
    deleteRaidGroup:SetTitle("Удаление рейда")
    deleteRaidGroup:SetLayout("Flow")
    deleteRaidGroup:SetFullWidth(true)
    container:AddChild(deleteRaidGroup)

    local deleteRaidDropdown = AceGUI:Create("Dropdown")
    deleteRaidDropdown:SetLabel("Выберите рейд для удаления:")
    deleteRaidDropdown:SetFullWidth(true)
    deleteRaidDropdown:SetList(addonTable:GetRaidNames(self.db.profile.Raids or {}))
    deleteRaidDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        self.selectedRaidToDelete = key
    end)
    deleteRaidGroup:AddChild(deleteRaidDropdown)
    self.deleteRaidDropdown = deleteRaidDropdown

    local deleteRaidButton = AceGUI:Create("Button")
    deleteRaidButton:SetText("Удалить рейд")
    deleteRaidButton:SetWidth(200)
    deleteRaidButton:SetCallback("OnClick", function()
        self:DeleteRaid()
    end)
    deleteRaidGroup:AddChild(deleteRaidButton)



    -- Блок "Cash Raid"
    local updateCashRaidGroup = AceGUI:Create("InlineGroup")
    updateCashRaidGroup:SetTitle("Raids Cash")
    updateCashRaidGroup:SetLayout("Flow")
    updateCashRaidGroup:SetFullWidth(true)
    container:AddChild(updateCashRaidGroup)

    local updateCashRaidDropdown = AceGUI:Create("Dropdown")
    updateCashRaidDropdown:SetLabel("Выберите рейд для обновления суммы:")
    updateCashRaidDropdown:SetList(addonTable:GetRaidNames(self.db.profile.Raids or {}))
    updateCashRaidDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        self.selectedCashRaid = key
    end)
    updateCashRaidGroup:AddChild(updateCashRaidDropdown)
    self.updateCashRaidDropdown = updateCashRaidDropdown

    local raidCashBox = AceGUI:Create("EditBox")
    raidCashBox:SetLabel("Total Cash:")
    raidCashBox:SetWidth(100)
    updateCashRaidGroup:AddChild(raidCashBox)
    self.raidCashBox = raidCashBox

    local dividerCashBox = AceGUI:Create("EditBox")
    dividerCashBox:SetLabel("Делитель:")
    dividerCashBox:SetWidth(100)
    updateCashRaidGroup:AddChild(dividerCashBox)
    self.dividerCashBox = dividerCashBox


    local updateCashRaidButton = AceGUI:Create("Button")
    updateCashRaidButton:SetText("Обновить")
    updateCashRaidButton:SetWidth(100)
    updateCashRaidButton:SetCallback("OnClick", function()
        self:UpdateCash()
    end)
    updateCashRaidGroup:AddChild(updateCashRaidButton)


    -- Блок для сообщений об ошибках
    local errorLabel = AceGUI:Create("Label")
    errorLabel:SetText("")
    errorLabel:SetColor(1, 0, 0) -- Красный цвет для сообщений об ошибках
    errorLabel:SetFullWidth(true)
    container:AddChild(errorLabel)
    self.errorLabel = errorLabel
end

-- Вкладка "Raid Manager"
function GBitsRaidManager:CreateRaidManagerTab(container)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetLayout("Flow")
    inlineGroup:SetFullWidth(true)
    container:AddChild(inlineGroup)

    -- Выпадающий список с сохраненными рейдами
    local raidDropdown = AceGUI:Create("Dropdown")
    raidDropdown:SetLabel("Выберите рейд для отображения:")
    raidDropdown:SetFullWidth(true)
    raidDropdown:SetList(addonTable:GetRaidNames(self.db.profile.Raids or {}))
    raidDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        self:DisplayRaidInfo(self.db.profile.Raids[key])
    end)
    inlineGroup:AddChild(raidDropdown)
    self.raidDropdown = raidDropdown

    -- Группа для отображения информации о рейде (таблица)
    local raidInfoGroup = AceGUI:Create("InlineGroup")
    raidInfoGroup:SetTitle("Информация о рейде")
    raidInfoGroup:SetFullWidth(true)
    raidInfoGroup:SetLayout("List")
    container:AddChild(raidInfoGroup)
    self.raidInfoGroup = raidInfoGroup
end

function GBitsRaidManager:ShowFrame()
    self.frame:Show()
end

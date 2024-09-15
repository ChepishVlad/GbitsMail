local addonName, addonTable = ...

local RaidMail = LibStub("AceAddon-3.0"):NewAddon("RaidMail", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceDB = LibStub("AceDB-3.0")

local mailLogs = {}
local raids = {}
local sortColumn = "index"
local sortAscending = true

function RaidMail:OnInitialize()
    self.db = AceDB:New("RaidMailDB", {
        profile = {
            Raids = {},
            MailLogs = {}
        }
    }, true)
    mailLogs = self.db.profile.MailLogs
    raids = self.db.profile.Raids
    self:CreateMainFrame()
    self:RegisterChatCommand("raidmail", "ShowFrame")
    self:CreateGbitPostButton()
    self.names = {}
    self.cash_list = {}
    -- Register event handlers for mail send success and failure
    self:RegisterEvent("MAIL_SEND_SUCCESS", "OnMailSendSuccess")
    self:RegisterEvent("MAIL_FAILED", "OnMailFailed")
end

-- Переделать позже по людски
local CLASS_COLORS = {
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

local function GetColoredText(class, text)
    local color = CLASS_COLORS[class]
    if color then
        return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
    else
        return text  -- Если класс не найден, возвращаем обычный текст
    end
end

-- Button in mail frame on Sending mail Tab
function RaidMail:CreateGbitPostButton()
    self.gbitPostButton = CreateFrame("Button", "GbitPostButton", SendMailFrame, "UIPanelButtonTemplate")
    self.gbitPostButton:SetText("GbitsMail")
    self.gbitPostButton:SetSize(100, 25)
    self.gbitPostButton:SetPoint("TOPLEFT", SendMailFrame, "TOPRIGHT", -155, -12)
    self.gbitPostButton:SetScript("OnClick", function()
        self:ShowFrame()
    end)
    self.gbitPostButton:Hide()
    local function OnMailFrameOpened()
        if SendMailFrame:IsVisible() then
            self.gbitPostButton:Show()
        else
            self.gbitPostButton:Hide()
        end
    end
    SendMailFrame:HookScript("OnShow", OnMailFrameOpened)
    SendMailFrame:HookScript("OnHide", OnMailFrameOpened)
end

local function SortRaiders(raiders, column, ascending)
    table.sort(raiders, function(a, b)
        if ascending then
            return a[column] < b[column]
        else
            return a[column] > b[column]
        end
    end)
end

-- Event handler for successful mail send
function RaidMail:OnMailSendSuccess()
    if #self.names > 0 then
        local name = self.names[self.currentIndex]
        local amount = self.cash_list[self.currentIndex]
        local successMessage = "Письмо с суммой " .. amount .. " было отправлено " .. name
        print(successMessage)
        table.insert(mailLogs, successMessage)
        self:UpdateLogs()
        self:ProceedToNextMail()
    end
end

-- Event handler for failed mail send
function RaidMail:OnMailFailed()
    if #self.names > 0 then
        local name = self.names[self.currentIndex]
        local errorMessage = "Отправка письма " .. name .. " не удалась."
        print(errorMessage)
        table.insert(mailLogs, errorMessage)
        self:UpdateLogs()
        self:ProceedToNextMail()
    end
end

-- Main frame
function RaidMail:CreateMainFrame()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(addonName)
    frame:SetStatusText("")
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(580)
    frame:Hide()
    self.frame = frame

    -- Tabs creating
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetTabs(
            {
                {text="Рассылка", value="mail"},
                {text="Рейдовая рассылка", value="raid"}
            }
    )
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        self:SelectGroup(container, group)
    end)
    tabGroup:SelectTab("mail")
    frame:AddChild(tabGroup)
end

-- Tabs content
function RaidMail:SelectGroup(container, group)
    container:ReleaseChildren()
    if group == "mail" then
        self:CreateMailTab(container)
    elseif group == "raid" then
        self:CreateRaidTab(container)
    end
end

function RaidMail:CreateRaidTab(container)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetLayout("Flow")
    inlineGroup:SetFullWidth(true)
    container:AddChild(inlineGroup)

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

    -- Группа для отображения информации о рейде (таблица)
    local raidInfoGroup = AceGUI:Create("InlineGroup")
    raidInfoGroup:SetTitle("Информация о рейде")
    raidInfoGroup:SetFullWidth(true)
    raidInfoGroup:SetLayout("List")
    container:AddChild(raidInfoGroup)
    self.raidInfoGroup = raidInfoGroup
end

-- Получаем список названий рейдов для выпадающего списка
function RaidMail:GetRaidNames()
    local raidNames = {}
    for i, raid in ipairs(self.db.profile.Raids or {}) do
        raidNames[i] = raid.raid_name
    end
    return raidNames
end

---- Обработка выбора рейда из выпадающего списка
function RaidMail:OnRaidSelected(index)
    local selectedRaid = self.db.profile.Raids[index]
    if selectedRaid then
        print("Выбран рейд: " .. selectedRaid.raid_name)
        -- Выводим информацию о рейде или делаем другие действия
        self:DisplayRaidInfo(selectedRaid)
    end
end

---- Функция отображения информации о рейде в виде таблицы
function RaidMail:DisplayRaidInfo(raid)
    -- Очищаем предыдущую информацию
    self.raidInfoGroup:ReleaseChildren()

    -- Создаем контейнер с прокруткой
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(320)
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
            SortRaiders(raid.raiders, column, sortAscending)
            self:DisplayRaidInfo(raid) -- Перерисовываем таблицу с отсортированными данными
        end)
        headerGroup:AddChild(header)
    end

    AddHeader("№", "index", 30)
    AddHeader("Name", "name", 150)
    AddHeader("Cash", "cash", 50)

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
        nameLabel:SetText(GetColoredText(raider.class, raider.name))
        nameLabel:SetWidth(150)
        rowGroup:AddChild(nameLabel)

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
function RaidMail:OpenEditFrame(raider, raid)
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

    -- Поле Cash (редактируемое)
    local cashEdit = AceGUI:Create("EditBox")
    cashEdit:SetLabel("Cash")
    cashEdit:SetText(tostring(raider.cash))
    cashEdit:SetWidth(200)
    editFrame:AddChild(cashEdit)

    -- Кнопка сохранения
    local saveButton = AceGUI:Create("Button")
    saveButton:SetText("Save")
    saveButton:SetWidth(200)
    editFrame:AddChild(saveButton)

    -- Обработчик сохранения
    saveButton:SetCallback("OnClick", function()
        raider.cash = tonumber(cashEdit:GetText())
        -- Закрыть фрейм редактирования после сохранения
        editFrame:Hide()

        -- Обновляем данные рейда в базе данных
        self:UpdateRaidInDatabase(raid)

        -- Обновить интерфейс после редактирования
        RaidMail:DisplayRaidInfo(raid)
    end)
end

-- Функция для обновления рейда в базе данных
function RaidMail:UpdateRaidInDatabase(updatedRaid)
    for i, raid in ipairs(self.db.profile.Raids) do
        if raid.raid_name == updatedRaid.raid_name then
            -- Заменяем старый рейд новым
            self.db.profile.Raids[i] = updatedRaid
            return
        end
    end
end


-- Sanding mail tab content
function RaidMail:CreateMailTab(container)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetLayout("Flow")
    inlineGroup:SetFullWidth(true)
    container:AddChild(inlineGroup)

    local subjText = AceGUI:Create("EditBox")
    subjText:SetLabel("Subject")
    subjText:SetFullWidth(true)
    inlineGroup:AddChild(subjText)
    self.subjText = subjText

    -- some trick for getting text from subject field
    subjText:SetCallback("OnTextChanged", function(widget, event, text)
        self.subjTextValue = text
    end)

    local editBoxGroup = AceGUI:Create("SimpleGroup")
    editBoxGroup:SetLayout("Flow")
    editBoxGroup:SetWidth(420)
    inlineGroup:AddChild(editBoxGroup)

    local raidListEditBox1 = AceGUI:Create("MultiLineEditBox")
    raidListEditBox1:SetLabel("Raid members list:")
    raidListEditBox1:SetWidth(200)
    raidListEditBox1:SetNumLines(18)
    editBoxGroup:AddChild(raidListEditBox1)
    self.raidListEditBox1 = raidListEditBox1
    raidListEditBox1.button:Hide()

    local raidListEditBox2 = AceGUI:Create("MultiLineEditBox")
    raidListEditBox2:SetLabel("Cash:")
    raidListEditBox2:SetWidth(200)
    raidListEditBox2:SetNumLines(18)
    editBoxGroup:AddChild(raidListEditBox2)
    self.raidListEditBox2 = raidListEditBox2
    raidListEditBox2.button:Hide()

    local sendButton = AceGUI:Create("Button")
    sendButton:SetText("Send")
    sendButton:SetWidth(100)
    sendButton:SetCallback("OnClick", function()
        self:SendMail()
    end)
    inlineGroup:AddChild(sendButton)

    local stopButton = AceGUI:Create("Button")
    stopButton:SetText("Stop sending")
    stopButton:SetWidth(150)
    stopButton:SetCallback("OnClick", function()
        self:StopSending()
    end)
    inlineGroup:AddChild(stopButton)

    local logButton = AceGUI:Create("Button")
    logButton:SetText("Logs")
    logButton:SetWidth(100)
    logButton:SetCallback("OnClick", function()
        self:ShowMailLogsPopup()
    end)
    inlineGroup:AddChild(logButton)

    local clearLogButton = AceGUI:Create("Button")
    clearLogButton:SetText("Clear logs")
    clearLogButton:SetWidth(100)
    clearLogButton:SetCallback("OnClick", function()
        self:ClearMailLogs()
    end)
    inlineGroup:AddChild(clearLogButton)

    -- Error messages
    local errorMessage = AceGUI:Create("Label")
    errorMessage:SetText("")
    errorMessage:SetWidth(400)
    errorMessage:SetColor(1, 0, 0)
    inlineGroup:AddChild(errorMessage)
    self.errorMessage = errorMessage
end

function RaidMail:StopSending()
    self.currentIndex  = #self.names
    local message = "Рассылка " .. self.subj .. " была остановлена"
    print(message)
    table.insert(mailLogs, message)
end

function RaidMail:GenerateRichTextLogs()
    local richText = ""
    for _, log in ipairs(mailLogs) do
        if log:find("было отправлено") then
            richText = richText .. "|cff00ff00|h" .. log .. "|h|r\n"  -- Green for success
        elseif log:find("не удалась") then
            richText = richText .. "|cffff0000" .. log .. "|r\n"  -- Red for failure
        else
            richText = richText .. log .. "\n"
        end
    end
    return richText
end

function RaidMail:UpdateLogs()
    if self.logsLabel then
        self.logsLabel:SetText(self:GenerateRichTextLogs())
    end
    self.db.profile.MailLogs = mailLogs
end

function RaidMail:ClearMailLogs()
    mailLogs = {}
    self.db.profile.MailLogs = mailLogs
    if self.logsEditBox then
        self.logsEditBox:SetText("")
    end
    print("Логи рассылки очищены.")
end

-- Main window visibility
function RaidMail:ShowFrame()
    self.frame:Show()
end

-- Show Mail Logs Popup
function RaidMail:ShowMailLogsPopup()
    local popupFrame = AceGUI:Create("Frame")
    popupFrame:SetTitle("Логи рассылки")
    popupFrame:SetStatusText("")
    popupFrame:SetLayout("Fill")
    popupFrame:SetWidth(700)
    popupFrame:SetHeight(700)

    -- Создаем MultiLineEditBox для логов
    local logsEditBox = AceGUI:Create("MultiLineEditBox")
    logsEditBox:SetFullWidth(true)
    logsEditBox:SetFullHeight(true)
    logsEditBox:SetText(self:GenerateRichTextLogs())
    logsEditBox:DisableButton(true)  -- Скрыть кнопку "ОК"

    -- Добавляем EditBox в окно поп-апа
    popupFrame:AddChild(logsEditBox)

    -- Обработка закрытия окна
    popupFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)

    -- Сохраняем ссылку для дальнейшего использования
    self.logsEditBox = logsEditBox
end

function RaidMail:SendMail()
    local names = self:ProcessString(self.raidListEditBox1:GetText())
    local cash_list = self:CastCash(self.raidListEditBox2:GetText())
    local subj = self.subjTextValue or "From GbitsMail"
    local self_cash = GetMoney()
    local total_cash = self:SumCashList(cash_list)
    local sum_of_sending = (total_cash * 10000) + (#cash_list * 30)

    if #names == 0 then
        self.errorMessage:SetText("Список рассылки пуст.")
    elseif #names ~= #cash_list then
        self.errorMessage:SetText("Длины списков не равны.")
    elseif self_cash < sum_of_sending then
        local message = ("Недостаточно средств для рассылки всем участникам. Требуется: %dг %dс %dм"):format(sum_of_sending / 100 / 100, (sum_of_sending / 100) % 100, sum_of_sending % 100);
        self.errorMessage:SetText(message)
    else
        self.errorMessage:SetText("")
        self:SendMailToRaid(names, cash_list, subj)
    end
end


-- some helper functions
function RaidMail:ProcessString(input_str)
    local words = {}
    for word in string.gmatch(input_str, "%S+") do
        -- Удаляем часть до символа ` включительно
        local clean_word = string.gsub(word, ".*`", "")
        table.insert(words, clean_word)
    end
    return words
end

function RaidMail:CastCash(inputString)
    local intList = {}
    for line in inputString:gmatch("[^\n]+") do
        local value = ""
        for i = 1, #line do
            local char = line:sub(i, i)
            local el = tonumber(char)
            if el then
                value = value .. el
            end
        end
        if value then
            table.insert(intList, value)
        end
    end
    return intList
end

function RaidMail:SumCashList(cash_list)
    local sum = 0
    for _, value in ipairs(cash_list) do
        sum = sum + tonumber(value)
    end
    return sum
end

function RaidMail:SendMailToRaid(names, cash_list, subj)
    self.subj = subj
    self.currentIndex = 1
    self.names = names
    self.cash_list = cash_list
    table.insert(mailLogs, "Рассылка с темой " .. subj)

    self:SendNextMail()
end

function RaidMail:SendNextMail()
    if self.currentIndex > #self.names then
        print("Все письма отправлены.")
        table.insert(mailLogs, "Все письма отправлены.")
        self:UpdateLogs()
        return
    end

    local name = self.names[self.currentIndex]
    local amount = self.cash_list[self.currentIndex]


    SendMailNameEditBox:SetText(name)
    SetSendMailMoney(amount * 10000)
    SendMail(name, self.subj, "Thank You for the raid. Here is your part of cash.")
end

-- Proceed to the next mail in the list
function RaidMail:ProceedToNextMail()
    self:ScheduleTimer(function()
        self.currentIndex = self.currentIndex + 1
        if self.currentIndex <= #self.names then
            self:SendNextMail()
        else
            local endMessage = string.format("Рассылка %s закончена.", self.subj)
            print(endMessage)
            table.insert(mailLogs, endMessage)
            self:UpdateLogs()
            self.names = {}
        end
    end, 5)
end

RaidMail:OnInitialize()
local addonName, addonTable = ...

local RaidMail = LibStub("AceAddon-3.0"):NewAddon("RaidMail", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Массив для хранения логов
local mailLogs = {}

-- Функция инициализации аддона
function RaidMail:OnInitialize()
    self:CreateMainFrame()
    self:RegisterChatCommand("raidmail", "ShowFrame")
    self:CreateGbitPostButton()
end

-- Создаем главное окно интерфейса
function RaidMail:CreateMainFrame()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(addonName)
    frame:SetStatusText("")
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(550)
    frame:Hide()  -- скрываем окно при создании
    self.frame = frame

    -- Создаем вкладки
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetTabs({{text="Рассылка", value="mail"}, {text="Логи рассылки", value="logs"}})
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        self:SelectGroup(container, group)
    end)
    tabGroup:SelectTab("mail")
    frame:AddChild(tabGroup)
end

-- Создаем кнопку "GbitPost"
function RaidMail:CreateGbitPostButton()
    self.gbitPostButton = CreateFrame("Button", "GbitPostButton", SendMailFrame, "UIPanelButtonTemplate")
    self.gbitPostButton:SetText("GbitsMail")
    self.gbitPostButton:SetSize(100, 25)
    self.gbitPostButton:SetPoint("TOPLEFT", SendMailFrame, "TOPRIGHT", 10, -10)
    self.gbitPostButton:SetScript("OnClick", function()
        self:ShowFrame()
    end)
    self.gbitPostButton:Hide()  -- скрываем кнопку при создании

    -- Обработчик события для отслеживания открытия стандартного окна отправки почты
    local function OnMailFrameOpened()
        if SendMailFrame:IsVisible() then
            self.gbitPostButton:Show()
        else
            self.gbitPostButton:Hide()
        end
    end

    -- Регистрируем обработчик события для открытия стандартного окна отправки почты
    SendMailFrame:HookScript("OnShow", OnMailFrameOpened)
    SendMailFrame:HookScript("OnHide", OnMailFrameOpened)
end

-- Функция для отображения контента в зависимости от выбранной вкладки
function RaidMail:SelectGroup(container, group)
    container:ReleaseChildren()
    if group == "mail" then
        self:CreateMailTab(container)
    elseif group == "logs" then
        self:CreateLogsTab(container)
    end
end

-- Создаем содержимое вкладки "Рассылка"
function RaidMail:CreateMailTab(container)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetLayout("Flow")
    inlineGroup:SetFullWidth(true)
    container:AddChild(inlineGroup)

    local labelGroup = AceGUI:Create("SimpleGroup")
    labelGroup:SetLayout("Flow")
    labelGroup:SetWidth(420) -- Установка ширины группы для размещения двух меток рядом
    inlineGroup:AddChild(labelGroup)

    -- Создаем метку для списка участников рейда
    local raidListLabel = AceGUI:Create("Label")
    raidListLabel:SetText("Список участников рейда:")
    raidListLabel:SetWidth(200)  -- Установка ширины в 200 пикселей
    labelGroup:AddChild(raidListLabel)

    -- Создаем метку для Cash
    local raidListLabel2 = AceGUI:Create("Label")
    raidListLabel2:SetText("Cash:")
    raidListLabel2:SetWidth(200)  -- Установка ширины в 200 пикселей
    labelGroup:AddChild(raidListLabel2)

    local editBoxGroup = AceGUI:Create("SimpleGroup")
    editBoxGroup:SetLayout("Flow")
    editBoxGroup:SetWidth(420) -- Установка ширины группы для размещения двух полей рядом
    inlineGroup:AddChild(editBoxGroup)

    -- Создаем первое многострочное текстовое поле для списка участников рейда
    local raidListEditBox1 = AceGUI:Create("MultiLineEditBox")
    raidListEditBox1:SetLabel("")
    raidListEditBox1:SetWidth(200)
    raidListEditBox1:SetNumLines(20)
    editBoxGroup:AddChild(raidListEditBox1)
    self.raidListEditBox1 = raidListEditBox1

    -- Скрываем кнопку "Принять" у первого поля
    raidListEditBox1.button:Hide()

    -- Создаем второе многострочное текстовое поле для Cash
    local raidListEditBox2 = AceGUI:Create("MultiLineEditBox")
    raidListEditBox2:SetLabel("")
    raidListEditBox2:SetWidth(200)
    raidListEditBox2:SetNumLines(20)
    editBoxGroup:AddChild(raidListEditBox2)
    self.raidListEditBox2 = raidListEditBox2

    -- Скрываем кнопку "Принять" у первого поля
    raidListEditBox2.button:Hide()

    -- Создаем кнопку для отправки сообщения
    local sendButton = AceGUI:Create("Button")
    sendButton:SetText("Отправить")
    sendButton:SetWidth(200)
    sendButton:SetCallback("OnClick", function()
        self:SendMail()
    end)
    inlineGroup:AddChild(sendButton)

    -- Создаем текстовый элемент для отображения сообщений об ошибках
    local errorMessage = AceGUI:Create("Label")
    errorMessage:SetText("")
    errorMessage:SetWidth(200)
    errorMessage:SetColor(1, 0, 0)  -- Установка цвета текста в красный
    inlineGroup:AddChild(errorMessage)
    self.errorMessage = errorMessage
end

-- Создаем содержимое вкладки "Логи рассылки"
function RaidMail:CreateLogsTab(container)
    -- Создаем многострочное текстовое поле для отображения логов
    local logsEditBox = AceGUI:Create("MultiLineEditBox")
    logsEditBox:SetLabel("Логи рассылки")
    logsEditBox:SetFullWidth(true)
    logsEditBox:SetFullHeight(true)
    logsEditBox:SetNumLines(25)
    logsEditBox:SetText(table.concat(mailLogs, "\n"))
    logsEditBox:DisableButton(true)
    container:AddChild(logsEditBox)

    -- Сохраняем ссылку на элемент для обновления
    self.logsEditBox = logsEditBox
end

-- Функция обновления логов
function RaidMail:UpdateLogs()
    if self.logsEditBox then
        self.logsEditBox:SetText(table.concat(mailLogs, "\n"))
    end
end

-- Функция отображения главного окна
function RaidMail:ShowFrame()
    self.frame:Show()
end

-- Функция отправки сообщения
function RaidMail:SendMail()
    local names = self:ProcessString(self.raidListEditBox1:GetText())
    local cash_list = self:CastCash(self.raidListEditBox2:GetText())

    if #names ~= #cash_list then
        self.errorMessage:SetText("Длины списков не равны")
    else
        self.errorMessage:SetText("")
        self:SendMailToRaid(names, cash_list)
    end
end

-- Функция обработки строки
function RaidMail:ProcessString(input_str)
    local words = {}
    for word in string.gmatch(input_str, "%S+") do
        -- Удаляем часть до символа ` включительно
        local clean_word = string.gsub(word, ".*`", "")
        table.insert(words, clean_word)
    end
    return words
end

-- Функция преобразования строки в список чисел
function RaidMail:CastCash(inputString)
    local intList = {}
    for line in inputString:gmatch("[^\n]+") do
        -- Удаляем пробелы и преобразуем в число
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

-- Функция отправки писем с вложенным золотом
function RaidMail:SendMailToRaid(names, cash_list)
    self.currentIndex = 1
    self.names = names
    self.cash_list = cash_list

    self:SendNextMail()
end

-- Функция отправки следующего письма
function RaidMail:SendNextMail()
    if self.currentIndex > #self.names then
        print("Все письма отправлены.")
        table.insert(mailLogs, "Все письма отправлены.")
        self:UpdateLogs()
        return
    end

    local name = self.names[self.currentIndex]
    local amount = self.cash_list[self.currentIndex]

    -- Сохраняем текущее состояние полей
    local previousRecipient = SendMailNameEditBox:GetText()
    local previousMoney = GetSendMailMoney()

    -- Устанавливаем значения для отправки
    SendMailNameEditBox:SetText(name)
    SetSendMailMoney(amount * 10000)
    SendMail(name, "Mail from GbitPost addon", "Here is your cash, Bitch ;)")

    -- Используем таймер для проверки отправки через 1 секунду
    self:ScheduleTimer(function()
        -- Проверяем, изменилось ли состояние полей
        if SendMailNameEditBox:GetText() == "" and GetSendMailMoney() == 0 then
            local successMessage = "Mail with amount " .. amount .. " was sent to " .. name
            print(successMessage)
            table.insert(mailLogs, successMessage)
        else
            local errorMessage = "Failed to send mail to " .. name .. ". Reason: Mail system might be overloaded."
            print(errorMessage)
            table.insert(mailLogs, errorMessage)
        end
        -- Восстанавливаем предыдущее состояние полей
        SendMailNameEditBox:SetText(previousRecipient)
        SetSendMailMoney(previousMoney)

        -- Переходим к следующему письму
        self.currentIndex = self.currentIndex + 1
        self:SendNextMail()
    end, 1)
end

-- Инициализируем аддон
RaidMail:OnInitialize()
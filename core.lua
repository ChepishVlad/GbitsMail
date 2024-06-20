local addonName, addonTable = ...

local RaidMail = LibStub("AceAddon-3.0"):NewAddon("RaidMail", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Функция инициализации аддона
function RaidMail:OnInitialize()
    self:CreateMainFrame()
    self:RegisterChatCommand("raidmail", "ShowFrame")
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
    -- Пока пусто
    local logsLabel = AceGUI:Create("Label")
    logsLabel:SetText("Здесь будут отображаться логи рассылки")
    logsLabel:SetWidth(200)
    container:AddChild(logsLabel)
end

-- Функция отображения главного окна
function RaidMail:ShowFrame()
    self.frame:Show()
end

-- Функция отправки сообщения
function RaidMail:SendMail()
    local names = self:ProcessString(self.raidListEditBox1:GetText())
    local cash_list = self:CastCash(self.raidListEditBox2:GetText())


    --print(#names)
    --print(#cash_list)

    if #names ~= #cash_list then
        self.errorMessage:SetText("Длины списков не равны")
    else
        self.errorMessage:SetText("")
        -- Ваш код для отправки почты
        for i, word in ipairs(names) do
            print(word)
        end
        for i, el in ipairs(cash_list) do
            print(el)
        end
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

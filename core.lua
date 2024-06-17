-- Создаем глобальную переменную для хранения имени аддона
local addonName = "RaidMail"

-- Создаем глобальную переменную для хранения окна интерфейса
local frame = CreateFrame("Frame", "RaidMailFrame", UIParent)
frame:SetSize(500, 460)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- задний фон
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",    -- граница
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},         -- отступы
})
frame:Hide()  -- скрываем окно при создании

---- Создаем текстовое поле для ввода золота
--local goldEditBox = CreateFrame("EditBox", "RaidMailGoldEditBox", frame, "InputBoxTemplate")
--goldEditBox:SetSize(100, 20)
--goldEditBox:SetPoint("TOP", 20, -180)
--goldEditBox:SetAutoFocus(false)
--goldEditBox:EnableMouse(true)
--goldEditBox:SetFontObject(ChatFontNormal)
--goldEditBox:SetTextInsets(8, 8, 8, 8)
--goldEditBox:SetNumeric(true)
--goldEditBox:SetMaxLetters(6)

---- Создаем метку для поля ввода золота
--local goldLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
--goldLabel:SetPoint("BOTTOMLEFT", goldEditBox, "TOPLEFT", 0, 5)
--goldLabel:SetText("Золото:")

-- Создаем метку для списка участников рейда
local raidListLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
raidListLabel:SetPoint("TOPLEFT", 20, -30)
raidListLabel:SetWidth(200)  -- Установка ширины в 200 пикселей
raidListLabel:SetText("Список участников рейда:")

-- Создаем вторую метку для списка участников рейда
local raidListLabel2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
raidListLabel2:SetPoint("LEFT", raidListLabel, "RIGHT", 10, 0)  -- Располагаем справа от первой метки
raidListLabel2:SetWidth(200)  -- Установка ширины в 200 пикселей
raidListLabel2:SetText("Вторая метка:")

-- Создаем первое многострочное текстовое поле для отображения списка участников рейда
local raidListScrollFrame1 = CreateFrame("ScrollFrame", "RaidMailRaidListScrollFrame1", frame, "UIPanelScrollFrameTemplate")
raidListScrollFrame1:SetPoint("TOPLEFT", raidListLabel, "BOTTOMLEFT", 0, -5)
raidListScrollFrame1:SetSize(200, 360) -- Изначальная высота в 4 строки

local raidListEditBox1 = CreateFrame("EditBox", "RaidMailRaidListEditBox1", raidListScrollFrame1)
raidListEditBox1:SetMultiLine(true)
raidListEditBox1:SetFontObject(ChatFontNormal)
raidListEditBox1:SetWidth(200)
raidListEditBox1:SetHeight(360) -- Изначальная высота в 4 строки
raidListEditBox1:SetAutoFocus(false)
raidListEditBox1:EnableMouse(true)
raidListEditBox1:SetTextInsets(8, 8, 8, 8)
raidListScrollFrame1:SetScrollChild(raidListEditBox1)

-- Добавляем границы родительскому фрейму для первого текстового поля
raidListScrollFrame1:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", -- Фоновый файл
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Границы
    edgeSize = 19,
    insets = {left = 4, right = 4, top = 4, bottom = 4}, -- Отступы
})
raidListScrollFrame1:SetBackdropColor(0, 0, 0, 0.5) -- Цвет фона

-- Добавляем полосу прокрутки для первого текстового поля, если содержимое превышает 4 строки
raidListEditBox1:SetScript("OnTextChanged", function(self)
    local numLines = select("#", string.split("\n", self:GetText()))
    local lineHeight = self:GetFontObject():GetLineHeight()
    local maxLines = math.floor(raidListScrollFrame1:GetHeight() / lineHeight - 4)
    if numLines > maxLines then
        raidListScrollFrame1.ScrollBar:Show()
    else
        raidListScrollFrame1.ScrollBar:Hide()
    end
end)

-- Создаем второе многострочное текстовое поле для отображения второго списка участников рейда
local raidListScrollFrame2 = CreateFrame("ScrollFrame", "RaidMailRaidListScrollFrame2", frame, "UIPanelScrollFrameTemplate")
raidListScrollFrame2:SetPoint("LEFT", raidListScrollFrame1, "RIGHT", 20, 0)
raidListScrollFrame2:SetSize(200, 360) -- Изначальная высота в 4 строки

local raidListEditBox2 = CreateFrame("EditBox", "RaidMailRaidListEditBox2", raidListScrollFrame2)
raidListEditBox2:SetMultiLine(true)
raidListEditBox2:SetFontObject(ChatFontNormal)
raidListEditBox2:SetWidth(200)
raidListEditBox2:SetHeight(360) -- Изначальная высота в 4 строки
raidListEditBox2:SetAutoFocus(false)
raidListEditBox2:EnableMouse(true)
raidListEditBox2:SetTextInsets(8, 8, 8, 8)
raidListScrollFrame2:SetScrollChild(raidListEditBox2)

-- Добавляем границы родительскому фрейму для второго текстового поля
raidListScrollFrame2:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", -- Фоновый файл
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Границы
    edgeSize = 19,
    insets = {left = 4, right = 4, top = 4, bottom = 4}, -- Отступы
})
raidListScrollFrame2:SetBackdropColor(0, 0, 0, 0.5) -- Цвет фона

-- Добавляем полосу прокрутки для второго текстового поля, если содержимое превышает 4 строки
raidListEditBox2:SetScript("OnTextChanged", function(self)
    local numLines = select("#", string.split("\n", self:GetText()))
    local lineHeight = self:GetFontObject():GetLineHeight()
    local maxLines = math.floor(raidListScrollFrame2:GetHeight() / lineHeight - 4)
    if numLines > maxLines then
        raidListScrollFrame2.ScrollBar:Show()
    else
        raidListScrollFrame2.ScrollBar:Hide()
    end
end)


-- Создаем кнопку для отправки сообщения
local sendButton = CreateFrame("Button", "RaidMailSendButton", frame, "UIPanelButtonTemplate")
sendButton:SetSize(80, 25)
sendButton:SetPoint("BOTTOMLEFT", 20, 20)
sendButton:SetText("Отправить")
sendButton:SetScript("OnClick", function()
    --local message = editBox:GetText()
    local message = "Some awesome message"
    --local gold = tonumber(goldEditBox:GetText()) or 0
    --local raidList = {}
    --for name in string.gmatch(raidListEditBox:GetText(), "[^\n]+") do
    --    table.insert(raidList, name)
    --end
    --SendMailToRaid(message, gold, raidList)  -- вызываем функцию отправки сообщения с текстом, золотом и списком участников
    names = process_string(raidListEditBox1:GetText())
    cash_list = cast_cash(raidListEditBox2:GetText())
    for i, word in ipairs(names) do
        print(word)
    end
    for i, el in ipairs(cash_list) do
        print(el)
    end
    frame:Hide()  -- скрываем окно после отправки сообщения
end)

-- Создаем кнопку для закрытия фрейма
local closeButton = CreateFrame("Button", "RaidMailCloseButton", frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
closeButton:SetScript("OnClick", function()
    frame:Hide() -- Скрываем фрейм при нажатии на кнопку закрытия
end)

-- Создаем кнопку "GbitPost"
local gbitPostButton = CreateFrame("Button", "GbitPostButton", SendMailFrame, "UIPanelButtonTemplate")
gbitPostButton:SetText("GbitPost")
gbitPostButton:SetSize(100, 25)
gbitPostButton:SetPoint("TOPLEFT", SendMailFrame, "TOPRIGHT", 10, -10)

-- Устанавливаем обработчик события нажатия на кнопку
gbitPostButton:SetScript("OnClick", function()
    frame:Show() -- Показываем наше окно для почтовой рассылки
end)

-- Обработчик события для отслеживания открытия стандартного окна отправки почты
local function OnMailFrameOpened()
    if SendMailFrame:IsVisible() then
        -- Размещаем кнопку "GbitPost" в стандартном окне отправки почты
        gbitPostButton:Show()
    else
        -- Если стандартное окно отправки почты скрыто, скрываем и кнопку "GbitPost"
        gbitPostButton:Hide()
    end
end

-- Регистрируем обработчик события для открытия стандартного окна отправки почты
SendMailFrame:HookScript("OnShow", OnMailFrameOpened)
SendMailFrame:HookScript("OnHide", OnMailFrameOpened)

-- Функция для отправки сообщения на почту выбранным участникам рейда
function SendMailToRaid(message, gold, raidList)
    for _, name in ipairs(raidList) do
        SetSendMailMoney(gold * 10000)
        SendMail(name, "Сообщение от аддона RaidMail", message)
    end
end

-- Обработчик события для отображения окна интерфейса
local function ShowRaidMailFrame()
    frame:Show()
end

-- функция преобразование строки в список имен с отбрасыванием части до символа "`"
function process_string(input_str)
    local words = {}
    for word in string.gmatch(input_str, "%S+") do
        -- Удаляем часть до символа ` включительно
        local clean_word = string.gsub(word, ".*`", "")
        table.insert(words, clean_word)
    end
    return words
end

function cast_cash(inputString)
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

        --print(line)
        --local num = tonumber(line:gsub(" ", ""))
        if value then
            table.insert(intList, value)
        end
    end
    return intList
end

-- Регистрируем команду для отображения окна интерфейса (для тестирования)
SLASH_RAIDMAIL1 = "/raidmail"
SlashCmdList["RAIDMAIL"] = ShowRaidMailFrame

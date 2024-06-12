-- Создаем глобальную переменную для хранения имени аддона
local addonName = "RaidMail"

-- Создаем глобальную переменную для хранения окна интерфейса
local frame = CreateFrame("Frame", "RaidMailFrame", UIParent)
frame:SetSize(300, 260)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- задний фон
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",    -- граница
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},         -- отступы
})
frame:Hide()  -- скрываем окно при создании

-- Создаем многострочное текстовое поле для ввода сообщения
local editBox = CreateFrame("EditBox", "RaidMailEditBox", frame, "InputBoxTemplate")
editBox:SetSize(260, 300)
editBox:SetPoint("TOP", 0, -50)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:EnableMouse(true)
editBox:SetFontObject(ChatFontNormal)
editBox:SetTextInsets(8, 8, 8, 8)

-- Создаем текстовое поле для ввода золота
local goldEditBox = CreateFrame("EditBox", "RaidMailGoldEditBox", frame, "InputBoxTemplate")
goldEditBox:SetSize(100, 20)
goldEditBox:SetPoint("TOP", 0, -180)
goldEditBox:SetAutoFocus(false)
goldEditBox:EnableMouse(true)
goldEditBox:SetFontObject(ChatFontNormal)
goldEditBox:SetTextInsets(8, 8, 8, 8)
goldEditBox:SetNumeric(true)
goldEditBox:SetMaxLetters(6)

-- Создаем метку для поля ввода золота
local goldLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
goldLabel:SetPoint("BOTTOMLEFT", goldEditBox, "TOPLEFT", 0, 5)
goldLabel:SetText("Золото:")

-- Создаем метку для списка участников рейда
local raidListLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
raidListLabel:SetPoint("TOPLEFT", 20, -30)
raidListLabel:SetText("Список участников рейда:")

-- Создаем многострочное текстовое поле для отображения списка участников рейда
local raidListScrollFrame = CreateFrame("ScrollFrame", "RaidMailRaidListScrollFrame", frame, "UIPanelScrollFrameTemplate")
raidListScrollFrame:SetPoint("TOPLEFT", raidListLabel, "BOTTOMLEFT", 0, -5)
raidListScrollFrame:SetSize(260, 100)
local raidListEditBox = CreateFrame("EditBox", "RaidMailRaidListEditBox", raidListScrollFrame)
raidListEditBox:SetMultiLine(true)
raidListEditBox:SetFontObject(ChatFontNormal)
raidListEditBox:SetWidth(260)
raidListEditBox:SetHeight(100)
raidListEditBox:SetAutoFocus(false)
raidListEditBox:EnableMouse(true)
raidListEditBox:SetTextInsets(8, 8, 8, 8)
raidListScrollFrame:SetScrollChild(raidListEditBox)

-- Создаем кнопку для отправки сообщения
local sendButton = CreateFrame("Button", "RaidMailSendButton", frame, "UIPanelButtonTemplate")
sendButton:SetSize(80, 25)
sendButton:SetPoint("BOTTOMLEFT", 20, 20)
sendButton:SetText("Отправить")
sendButton:SetScript("OnClick", function()
    local message = editBox:GetText()
    local gold = tonumber(goldEditBox:GetText()) or 0
    local raidList = {}
    for name in string.gmatch(raidListEditBox:GetText(), "[^\n]+") do
        table.insert(raidList, name)
    end
    SendMailToRaid(message, gold, raidList)  -- вызываем функцию отправки сообщения с текстом, золотом и списком участников
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

-- Регистрируем команду для отображения окна интерфейса (для тестирования)
SLASH_RAIDMAIL1 = "/raidmail"
SlashCmdList["RAIDMAIL"] = ShowRaidMailFrame

local addonName, addonTable = ...

local RaidMail = LibStub("AceAddon-3.0"):NewAddon("RaidMail", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceDB = LibStub("AceDB-3.0")

local mailLogs = {}
local raids = {}

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

local function GetRaidersList()
    local raiders = {}
    if IsInRaid() then
        local numRaidMembers = GetNumGroupMembers()
        if numRaidMembers > 0 then
            for i = 1, numRaidMembers do
                local name, _, subgroup, _, class, _, _, _, _, _, classFileName = GetRaidRosterInfo(i)
                --print(name)
                table.insert(raiders, {["name"] = name, ["group"] = subgroup, ["class"] = class, ["cashPercent"] = 100})
            end
        end
    else
        print("Вы не в рейде.")
    end
    return raiders
end

-- Новая функция для сохранения рейда
function RaidMail:SaveRaid()
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
                {text="Рейд", value="raid"}
            }
    )
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        self:SelectGroup(container, group)
    end)
    tabGroup:SelectTab("mail")
    frame:AddChild(tabGroup)
end

-- "GbitsMail button"
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

-- Получаем список названий рейдов для выпадающего списка
function RaidMail:GetRaidNames()
    local raidNames = {}
    for i, raid in ipairs(self.db.profile.Raids or {}) do
        raidNames[i] = raid.raid_name
    end
    return raidNames
end

-- Обработка выбора рейда из выпадающего списка
function RaidMail:OnRaidSelected(index)
    local selectedRaid = self.db.profile.Raids[index]
    if selectedRaid then
        print("Выбран рейд: " .. selectedRaid.raid_name)
        -- Выводим информацию о рейде или делаем другие действия
        self:DisplayRaidInfo(selectedRaid)
    end
end

-- Функция отображения информации о рейде в виде таблицы
function RaidMail:DisplayRaidInfo(raid)
    -- Очищаем предыдущую информацию
    self.raidInfoGroup:ReleaseChildren()

    -- Заголовки таблицы
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetLayout("Flow")
    headerGroup:SetFullWidth(true)
    self.raidInfoGroup:AddChild(headerGroup)

    local nameHeader = AceGUI:Create("Label")
    nameHeader:SetText("Имя")
    nameHeader:SetWidth(150)
    headerGroup:AddChild(nameHeader)

    local groupHeader = AceGUI:Create("Label")
    groupHeader:SetText("Группа")
    groupHeader:SetWidth(50)
    headerGroup:AddChild(groupHeader)

    local classHeader = AceGUI:Create("Label")
    classHeader:SetText("Класс")
    classHeader:SetWidth(150)
    headerGroup:AddChild(classHeader)

    local percentHeader = AceGUI:Create("Label")
    percentHeader:SetText("% Кэша")
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

        local percentLabel = AceGUI:Create("Label")
        percentLabel:SetText(tostring(raider.cashPercent))
        percentLabel:SetWidth(50)
        rowGroup:AddChild(percentLabel)
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
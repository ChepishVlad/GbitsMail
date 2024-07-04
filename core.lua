local addonName, addonTable = ...

local RaidMail = LibStub("AceAddon-3.0"):NewAddon("RaidMail", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceDB = LibStub("AceDB-3.0")

local mailLogs = {}

function RaidMail:OnInitialize()
    self.db = AceDB:New("RaidMailDB", {
        profile = {
            Raids = {},
            MailLogs = {}
        }
    }, true)
    mailLogs = self.db.profile.MailLogs
    self:CreateMainFrame()
    self:RegisterChatCommand("raidmail", "ShowFrame")
    self:CreateGbitPostButton()

    -- Register event handlers for mail send success and failure
    self:RegisterEvent("MAIL_SEND_SUCCESS", "OnMailSendSuccess")
    self:RegisterEvent("MAIL_FAILED", "OnMailFailed")
end

-- Event handler for successful mail send
function RaidMail:OnMailSendSuccess()
    local name = self.names[self.currentIndex]
    local amount = self.cash_list[self.currentIndex]
    local successMessage = "Письмо с суммой " .. amount .. " было отправлено " .. name
    print(successMessage)
    table.insert(mailLogs, successMessage)
    self:UpdateLogs()
    self:ProceedToNextMail()
end

-- Event handler for failed mail send
function RaidMail:OnMailFailed()
    local name = self.names[self.currentIndex]
    local errorMessage = "Отправка письма " .. name .. " не удалась."
    print(errorMessage)
    table.insert(mailLogs, errorMessage)
    self:UpdateLogs()
    self:ProceedToNextMail()
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

function RaidMail:UpdateLogs()
    if self.logsEditBox then
        self.logsEditBox:SetText(table.concat(mailLogs, "\n"))
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
    popupFrame:SetWidth(500)
    popupFrame:SetHeight(400)

    local logsEditBox = AceGUI:Create("MultiLineEditBox")
    logsEditBox:SetLabel("")
    logsEditBox:SetFullWidth(true)
    logsEditBox:SetFullHeight(true)
    logsEditBox:SetNumLines(20)
    logsEditBox:SetText(table.concat(mailLogs, "\n"))
    logsEditBox:DisableButton(true)
    popupFrame:AddChild(logsEditBox)

    popupFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
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
        end
    end, 5)
end

RaidMail:OnInitialize()
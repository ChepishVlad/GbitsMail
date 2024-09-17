local addonName, addonTable = ...

-- Thx to Yudo for idea
local GetMembers = LibStub("AceAddon-3.0"):NewAddon("GetMembers", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local GetMembersGUI = LibStub("AceGUI-3.0")

function GetMembers:OnInitialize()
    self:AddRaidMembersButtonToSocialFrame()
end

function GetMembers:AddRaidMembersButtonToSocialFrame()
    if not RaidFrame then
        print("Окно рейда не найдено.")
        return
    end

    local raidMembersButton = CreateFrame("Button", "RaidMembersButton", RaidFrame, "UIPanelButtonTemplate")
    raidMembersButton:SetText("Участники")
    raidMembersButton:SetSize(70, 20)
    raidMembersButton:SetPoint("TOPLEFT", RaidFrame, "TOPLEFT", 250, -12)
    raidMembersButton:SetScript("OnClick", function()
        self:ShowRaidMembersPopup()
    end)
end

function GetMembers:ShowRaidMembersPopup()
    if not addonTable:IsInRaid() then
        print("Вы не в рейде.")
        return
    end

    local raidMembers = {}
    for i = 1, addonTable:GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            table.insert(raidMembers, name)
        end
    end

    if #raidMembers > 0 then
        local membersString = table.concat(raidMembers, "\n")

        local popupFrame = GetMembersGUI:Create("Frame")
        popupFrame:SetTitle("Участники рейда")
        popupFrame:SetLayout("Fill")
        popupFrame:SetWidth(300)
        popupFrame:SetHeight(400)

        local membersEditBox = GetMembersGUI:Create("MultiLineEditBox")
        membersEditBox:SetFullWidth(true)
        membersEditBox:SetFullHeight(true)
        membersEditBox:SetText(membersString)
        membersEditBox.button:Hide()

        popupFrame:AddChild(membersEditBox)
        popupFrame:SetCallback("OnClose", function(widget)
            GetMembersGUI:Release(widget)
        end)
    else
        print("В рейде нет участников.")
    end
end


GetMembers:OnInitialize()
GetRaidList = LibStub("AceAddon-3.0"):NewAddon("GetRaidList", "AceConsole-3.0", "AceEvent-3.0","AceTimer-3.0")

SLASH_GET_RAID_NAMES1 = "/grl"

function SlashCmdList.GET_RAID_NAMES()
	local t = {}
	for i = 1, GetNumRaidMembers() do
		tinsert(t, (UnitName("raid"..i)))
	end
	sort(t)
	KEditBox:Show(table.concat(t, "\n"))
end

KEditBox = {}

function GetRaidList:OnInitialize()
end

function GetRaidList:OnEnable()
	playername,_ = UnitName("player")
	local GRLbutton = CreateFrame("Button",nil,RaidFrame,"UIPanelButtonTemplate")
	local buttonText = GRLbutton:CreateFontString()
			buttonText:SetFont("Fonts\\FRIZQT__.TTF", 10, nil)
			buttonText:SetShadowColor(0,0,0,1)
			buttonText:SetShadowOffset(1,-1)
			buttonText:SetText("GetList")
		GRLbutton:SetFontString(buttonText)
		GRLbutton:SetHeight(19)
		GRLbutton:SetWidth(74)
		GRLbutton:SetPoint("TOPLEFT", 74,-15)
		GRLbutton:SetScript("OnClick",function() SlashCmdList.GET_RAID_NAMES() 
	end)
end

function KEditBox:Create()
	local f = CreateFrame("Frame", nil, UIParent, "DialogBoxFrame")
	self.Frame = f
	f:SetPoint("CENTER")
	f:SetSize(600, 500)

	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
		edgeSize = 16,
		insets = { left = 8, right = 6, top = 8, bottom = 8 },
	})
	f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

	-- Movable
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:SetScript("OnMouseDown", function(frame, button)
		if button == "LeftButton" then
			frame:StartMoving()
		end
	end)
	f:SetScript("OnMouseUp", f.StopMovingOrSizing)

	-- ScrollFrame
	local sf = CreateFrame("ScrollFrame", "ChatModsCopyScroll", f, "UIPanelScrollFrameTemplate")
	sf:SetPoint("LEFT", 16, 0)
	sf:SetPoint("RIGHT", -32, 0)
	sf:SetPoint("TOP", 0, -16)
	sf:SetPoint("BOTTOM", f, "BOTTOM", 0, 50)

	-- EditBox
	local eb = CreateFrame("EditBox", nil, sf)
	self.EditBox = eb
	eb:SetSize(sf:GetSize())
	eb:SetMultiLine(true)
	eb:SetAutoFocus(false)
	eb:SetFontObject("ChatFontNormal")
	eb:SetScript("OnEscapePressed", eb.ClearFocus)
	sf:SetScrollChild(eb)

	-- Resizable
	f:SetResizable(true)
	f:SetMinResize(150, 100)
	local rb = CreateFrame("Button", nil, f)
	rb:SetPoint("BOTTOMRIGHT", -6, 7)
	rb:SetSize(16, 16)
	rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	rb:SetScript("OnMouseDown", function(frame, button)
		if button == "LeftButton" then
			f:StartSizing("BOTTOMRIGHT")
			frame:GetHighlightTexture():Hide()
		end
	end)
	rb:SetScript("OnMouseUp", function(frame)
		f:StopMovingOrSizing()
		frame:GetHighlightTexture():Show()
		eb:SetWidth(sf:GetWidth())
	end)
end

function KEditBox:Show(text)
	if not self.EditBox then
		self:Create()
	end
	self.EditBox:SetText(text)
	self.Frame:Show()
end
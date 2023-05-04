--[[
Copyright 2018-2020, Quarq
This file is part of GoPost.
GoPost is distributed under a BSD License.
It is provided AS-IS and all warranties, express or implied, including, but not
limited to, the implied warranties of merchantability or fitness for a particular
purpose, are disclaimed.  See the LICENSE file for full information.
--]]


local Addon = GoPost
local util = Addon.util

local _, namespace = ...
local Strings = namespace.Strings
local L = Strings.L
assert(L)


local HEIGHT = 30

local indent = 0

local BOX_TEXTURE = 132762


local FLYOUT = nil

local ROW_ICON_GAP = 4
local ROW_TO_FLYOUT_GAP = 8


function Addon : OtherMessage_Create(WIDTH)

	local row = CreateFrame("Frame")
	row:SetWidth(WIDTH)
	row:SetHeight(HEIGHT)
	
	row.open = CreateFrame("Button", nil, row)
	row.open:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight2", "ADD")
	row.open:SetAlpha(0.30)
	row.open:SetHeight(HEIGHT)
	row.open:SetPoint("LEFT", row, "LEFT", indent+8+12, 0)
	-- right set below
	row.open:SetScript("OnClick", function() Addon:OtherMessage_OpenMessage(row) end)
	
	row.line = row:CreateTexture(nil, "ARTWORK")
	row.line:SetWidth(1.5)
	row.line:SetHeight(HEIGHT+4)
	row.line:SetColorTexture(0.30, 0.20, 0, 1)
	row.line:SetPoint("LEFT", row, "LEFT", 17, 2) -- this 2 is half of the 4 added to it height
	
	row.sender = row:CreateFontString(nil, "OVERLAY", "GPFont")
	row.sender:SetJustifyH("LEFT")
	row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", indent+8+16, -4)
	row.sender:SetTextColor(0,0,0, 1)
	
	row.subject = row:CreateFontString(nil, "OVERLAY", "GPFont")
	row.subject:SetJustifyH("LEFT")
	row.subject:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", indent+8+16, 4)
	row.subject:SetWidth(WIDTH-(indent+8+16+4+HEIGHT*2/3))
	row.subject:SetTextColor(0,0,0, 1)
	
	row.money = row:CreateFontString(nil, "OVERLAY", "GPNumberFontSmaller")
	row.money:SetJustifyH("RIGHT")
	row.money:SetPoint("BOTTOMRIGHT", row, "RIGHT", -4, 0)
	row.money:SetTextColor(1,1,1, 0.90)
	
	row.icon1 = row:CreateTexture(nil, "ARTWORK")
	row.icon1:SetWidth(HEIGHT*2/3)
	row.icon1:SetHeight(HEIGHT*2/3)
	row.icon1:SetPoint("RIGHT", row, "RIGHT", -ROW_ICON_GAP, 0)
	
	row.icon2 = row:CreateTexture(nil, "ARTWORK")
	row.icon2:SetWidth(HEIGHT*2/3)
	row.icon2:SetHeight(HEIGHT*2/3)
	row.icon2:SetPoint("RIGHT", row.icon1, "LEFT", 0, 0)
	
	row.cod = row:CreateFontString(nil, "OVERLAY", "GPNumberFontSmaller")
	row.cod:SetText("C.O.D.")
	row.cod:SetJustifyH("RIGHT")
	row.cod:SetPoint("RIGHT", row.icon1, "LEFT", 0, 0)
	--row.cod:SetPoint("TOPRIGHT", row.icon1, "TOPRIGHT", 3, 4)
	row.cod:SetTextColor(1,0,0, 1)
	local font, size, _ = row.cod:GetFont()
	row.cod:SetFont(font, size, "OUTLINE")
	
	row.attachments = row:CreateFontString(nil, "OVERLAY", "GPFont")
	row.attachments:SetJustifyH("RIGHT")
	row.attachments:SetPoint("BOTTOMRIGHT", row.icon1, "BOTTOMRIGHT", 2, -4)
	row.attachments:SetTextColor(1,1,1, 1)
	local font, size, _ = row.attachments:GetFont()
	row.attachments:SetFont(font, size, "OUTLINE")
	
	row.lootAll = CreateFrame("Button", nil, row)
	row.lootAll:SetHeight(row.icon1:GetHeight())
	row.lootAll:SetPoint("RIGHT", row.icon1, "RIGHT", 0, 0)
	row.lootAll:SetScript("OnEnter", function() Addon:OtherMessage_Icon_MouseEnter(row) end)
	row.lootAll:SetScript("OnLeave", function() Addon:OtherMessage_Icon_MouseLeave(row) end)
	row.lootAll:SetScript("OnClick", function() Addon:OtherMessage_LootMessage(row) end)
	row.lootAll:SetAlpha(0.30)
	
	row.lootHighlight = row:CreateTexture(nil, "BACKGROUND")
	row.lootHighlight:SetTexture("Interface/Buttons/UI-Listbox-Highlight2")
	row.lootHighlight:SetAlpha(0.30)
	row.lootHighlight:SetBlendMode("ADD")
	row.lootHighlight:SetPoint("BOTTOMRIGHT", row.icon1, "BOTTOMRIGHT", 4, -4)
			
	row.Populate = function (message) self:OtherMessage_Populate(row, message) end
		
	return row

end


function Addon : OtherMessage_Populate(row, message)
	
	row.message = message -- needed for the flyout

	-- sender
	row.sender:SetText(message.sender)
	
	-- subject
	if (message.subject and message.subject:len() > 0) then
		row.subject:SetText(message.subject)
	else
		row.subject:SetText("(no subject)")
	end
	
	-- C.O.D. ?
	if (message.cod and message.cod > 0) then
		row.cod:Show()
	else
		row.cod:Hide()
	end
	
	-- unread messages get OUTLINE font
	local font, size, _ = row.subject:GetFont()
	if (message.opened) then
		row.subject:SetFont(font, size, nil)
		row.subject:SetTextColor(0,0,0, 1)
	else
		row.subject:SetFont(font, size, "OUTLINE")
		row.subject:SetTextColor(1,1,1, 1)
	end
	
	
	if (message.money>0 and message.attachments>0) then
		
		-- second icon gets money texture
		row.icon2:SetTexture("Interface/MINIMAP/TRACKING/Auctioneer")
		row.icon2:SetTexCoord(0,1,0,1)
		
		-- first icon gets attachment texture (single or multi)
		row.icon1:SetTexCoord(2/34, 31/34, 3/34, 32/34)
		if (message.attachments == 1) then
			row.icon1:SetTexture(message.itemTexture)
			if (message.itemCount > 1) then
				row.attachments:SetText(message.itemCount)	-- stack size
			else
				row.attachments:SetText(nil)
			end
		else
			row.icon1:SetTexture(BOX_TEXTURE)
			row.attachments:SetText(message.attachments)	-- number of attachments
		end
		
		-- hover pad covers both icons
		row.lootAll:SetPoint("LEFT", row.icon2, "LEFT", 0, 0)
		row.lootHighlight:SetPoint("TOPLEFT", row.icon2, "TOPLEFT", -4, 4)
		
		-- open button stops at icon2
		row.open:SetPoint("RIGHT", row.icon2, "LEFT", -1, 0)

	elseif (message.money > 0) then
		
		-- second icon has nothing
		row.icon2:SetTexture(nil)

		-- first icon gets money texture
		row.icon1:SetTexture("Interface/MINIMAP/TRACKING/Auctioneer")
		row.icon1:SetTexCoord(0,1,0,1)
		row.attachments:SetText(nil)

		-- hover pad covers only the first icon
		row.lootAll:SetPoint("LEFT", row.icon1, "LEFT", 0, 0)
		row.lootHighlight:SetPoint("TOPLEFT", row.icon1, "TOPLEFT", -4, 4)
		
		-- open button stops at icon1
		row.open:SetPoint("RIGHT", row.icon1, "LEFT", -3, 0)
		
	elseif (message.attachments > 0) then
		
		-- second icon has nothing
		row.icon2:SetTexture(nil)

		-- first icon gets attachment texture (single or multi)
		row.icon1:SetTexCoord(2/34, 31/34, 3/34, 32/34)
		if (message.attachments == 1) then
			row.icon1:SetTexture(message.itemTexture)
			if (message.itemCount > 1) then
				row.attachments:SetText(message.itemCount)	-- stack size
			else
				row.attachments:SetText(nil)
			end
		else
			row.icon1:SetTexture(BOX_TEXTURE)
			row.attachments:SetText(message.attachments)	-- number of attachments
		end

		-- hover pad covers only the first icon
		row.lootAll:SetPoint("LEFT", row.icon1, "LEFT", 0, 0)
		row.lootHighlight:SetPoint("TOPLEFT", row.icon1, "TOPLEFT", -4, 4)
		
		-- open button stops at icon1
		row.open:SetPoint("RIGHT", row.icon1, "LEFT", -3, 0)
		
	else
		
		-- second icon has nothing
		row.icon2:SetTexture(nil)

		-- first icon gets scroll texture
		row.icon1:SetTexture("Interface/ICONS/INV_Scroll_03")
		row.icon1:SetTexCoord(2/34, 31/34, 3/34, 32/34)
		row.attachments:SetText(nil)

		-- hover pad covers only the first icon
		row.lootAll:SetPoint("LEFT", row.icon1, "LEFT", 0, 0)
		row.lootHighlight:SetPoint("TOPLEFT", row.icon1, "TOPLEFT", -4, 4)
		
		-- open button stops at icon1
		row.open:SetPoint("RIGHT", row.icon1, "LEFT", -3, 0)
		
	end
	
	row.lootHighlight:Hide()
	
	if (FLYOUT and FLYOUT:IsShown() and FLYOUT.message and FLYOUT.message.messageID == row.message.messageID) then
		self:OtherMessage_HideFlyout()
		self:OtherMessage_ShowFlyout(row)
	end
end



function Addon : OtherMessage_ShowFlyout(row)

	assert(row)
	assert(row.message)
	
	local message = row.message
	
	-- create it if necessary
	if (FLYOUT == nil) then
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetFrameStrata("DIALOG")
		f:SetWidth(320) -- height depends on message content
		--f:SetBackdrop({ edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=16 })

		local bg = f:CreateTexture(nil, "BACKGROUND")
		bg:SetTexture("Interface/MailFrame/UI-MailFrameBG")
		bg:SetTexCoord(0.03, 0.62, 0.05, 0.60)
		bg:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
		bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
		
		local left = 12
		f.attachments = {}
		for a = 1, ATTACHMENTS_MAX_RECEIVE do
			local att = {}
			
			att.button = CreateFrame("Button", nil, f)
			att.button:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight2", "ADD")
			att.button:SetAlpha(0.30)
			
			att.icon = f:CreateTexture(nil, "ARTWORK")
			att.icon:SetWidth(16)
			att.icon:SetHeight(16)
			att.icon:SetPoint("LEFT", f, "LEFT", left, 0)
			
			att.label = f:CreateFontString(nil, "OVERLAY", "GPFont")
			att.label:SetWidth(f:GetWidth() - left-left-4-att.icon:GetWidth())
			att.label:SetHeight(20)
			att.label:SetJustifyH("LEFT")
			att.label:SetPoint("LEFT", att.icon, "RIGHT", 4, 0)
			
			att.button:SetPoint("LEFT", att.icon, "LEFT", 0, 0)
			att.button:SetPoint("RIGHT", att.label, "RIGHT", 0, 0)
			att.button:SetPoint("TOP", att.label, "TOP", 0, 0)
			att.button:SetPoint("BOTTOM", att.label, "BOTTOM", 0, 0)
			att.button:SetScript("OnClick", function() Addon:FLYOUT_LootItem(a) end)
			att.button:SetScript("OnEnter", function() Addon:FLYOUT_LootItem_MouseEnter(a) end)
			att.button:SetScript("OnLeave", function() Addon:FLYOUT_LootItem_MouseLeave(a) end)
			
			table.insert(f.attachments, att)
		end
		
		f.moneyButton = CreateFrame("Button", nil, f)
		f.moneyButton:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight2", "ADD")
		f.moneyButton:SetAlpha(0.30)
		
		f.money = f:CreateFontString(nil, "OVERLAY", "GPFont")
		f.money:SetHeight(26)
		f.money:SetJustifyH("LEFT")
		f.money:SetPoint("LEFT", f, "LEFT", left, 0)
		
		f.moneyButton:SetHeight(f.money:GetHeight())
		f.moneyButton:SetPoint("LEFT", f.money, "LEFT", 0, 0)
		f.moneyButton:SetPoint("RIGHT", f, "RIGHT", -left, 0)
		
		f.ramp = CreateFrame("Button", nil, f)
		f.ramp:SetWidth(ROW_TO_FLYOUT_GAP + ROW_ICON_GAP)
		f.ramp:SetHeight(20) -- row icon height (not my icon height)
		f.ramp:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, -5)
		
		---- for debugging only
		--local bg = f.ramp:CreateTexture(nil, "BACKGROUND")
		--bg:SetAllPoints(f.ramp)
		--bg:SetColorTexture(1,0,0, 0.66)
		
		FLYOUT = f
	end
	
	-- populate it with this message

	-- but not if it's empty	
	if (message.money == 0 and message.attachments == 0) then
		return
	end

	FLYOUT.message = row.message
	
	local top = -10
	for a = 1, ATTACHMENTS_MAX_RECEIVE do
		local att = FLYOUT.attachments[a]
		
		local itemName, itemID, texture, count, _, _ = GetInboxItem(message.messageID, a)
		if (itemName) then
			
			local link = GetInboxItemLink(message.messageID, a)
			assert(link)
			att.itemLink = link
			--link = link or itemName
			if (count == 1) then
				att.label:SetText(link)
			else
				att.label:SetText(link .. " ("..count..")")
			end
			
			att.icon:SetTexture(texture or "Interface/ICONS/INV_Misc_QuestionMark")
			
			att.button:Show()
			
			att.icon:Show()
			att.label:Show()
			att.icon:SetPoint("TOP", FLYOUT, "TOP", 0, top)
			top = top - att.label:GetHeight()
		else
			att.button:Hide()
			att.icon:Hide()
			att.label:Hide()
		end
	end
	
	if (row.message.money > 0) then
		--FLYOUT.money:SetText(util.color("FF000000", L["Money:  "]) .. util.gold_format(row.message.money))
		FLYOUT.money:SetText(util.black(MONEY_COLON) .. "  " .. util.gold_format(row.message.money))
		FLYOUT.money:Show()
		FLYOUT.money:SetPoint("TOP", FLYOUT, "TOP", 0, top)
		top = top - FLYOUT.money:GetHeight()
		
		FLYOUT.moneyButton:Show()
		FLYOUT.moneyButton:SetScript("OnClick", function() Addon:FLYOUT_LootMoney(row) end)
	elseif (row.message.cod and row.message.cod > 0) then
		--FLYOUT.money:SetText(util.color("FF000000", L["COD Amount Due:  "]) .. util.color("FF000000", util.gold_format(row.message.cod)))
		FLYOUT.money:SetText(util.black(L["COD Amount Due:"] .. "  " .. util.gold_format(row.message.cod)))
		FLYOUT.money:Show()
		FLYOUT.money:SetPoint("TOP", FLYOUT, "TOP", 0, top)
		top = top - FLYOUT.money:GetHeight()
		
		FLYOUT.moneyButton:Hide()
	else
		FLYOUT.money:Hide()
		FLYOUT.moneyButton:Hide()
	end
	
	top = top - 10
	FLYOUT:SetHeight(math.abs(top))
	FLYOUT:SetPoint("TOPLEFT", row, "TOPRIGHT", ROW_TO_FLYOUT_GAP, 0)
	FLYOUT:Show()
	FLYOUT:SetScript("OnUpdate", function() Addon:FLYOUT_OnUpdate(row) end)
end



function Addon : OtherMessage_HideFlyout()
	if (FLYOUT) then
		FLYOUT:Hide()
		FLYOUT:SetScript("OnUpdate", nil)
		FLYOUT.message = nil
	end
end



function Addon : OtherMessage_Icon_MouseEnter(row)
	
	--print("enter", row.sender:GetText(), "\"" .. row.subject:GetText() .. "\"")
	if (FLYOUT and FLYOUT:IsShown()) then
		self:OtherMessage_HideFlyout()
	end
	
	self:OtherMessage_ShowFlyout(row)
	row.lootHighlight:Show()
end



function Addon : OtherMessage_Icon_MouseLeave(row)
	
	--print("leave", row.sender:GetText(), "\"" .. row.subject:GetText() .. "\"")
	row.lootHighlight:Hide()
end



function Addon : FLYOUT_OnUpdate(row)
	if (MouseIsOver(FLYOUT) or MouseIsOver(FLYOUT.ramp) or MouseIsOver(row.icon1) or (row.icon2:IsShown() and MouseIsOver(row.icon2))) then
		-- yay
	else
		self:OtherMessage_HideFlyout()
	end

end


function Addon : FLYOUT_LootItem(attachmentID)
	assert(FLYOUT)
	assert(FLYOUT.message)
	
	TakeInboxItem(FLYOUT.message.messageID, attachmentID)
	
	if (FLYOUT.message.attachments == 1 and FLYOUT.message.money == 0) then
		self:OtherMessage_HideFlyout()
	end
end



function Addon : FLYOUT_LootMoney(row)
	assert(row)
	assert(row.message)
	
	if (FLYOUT.message.attachments == 0) then
		self:OtherMessage_HideFlyout()
	end
	
	TakeInboxMoney(row.message.messageID)
end



function Addon : FLYOUT_LootItem_MouseEnter(attachmentID)

	local att = FLYOUT.attachments[attachmentID]
	assert(att)
	
	GameTooltip:SetOwner(att.button, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", att.button, "TOPRIGHT", 3, 8)
	GameTooltip:SetHyperlink(att.itemLink)
	GameTooltip:Show()
end



function Addon : FLYOUT_LootItem_MouseLeave(attachmentID)

	GameTooltip:Hide()
end



function Addon : OtherMessage_LootMessage(row)
	assert(row)
	assert(row.message)
		
	--print("Looting OtherMessage", row.message.messageID, row.message.section)
	self.Looter:LootMessage(row.message.messageID, row.message.section)
	
	self:UpdateScroller()
end



function Addon : OtherMessage_OpenMessage(row)
	assert(row)
	assert(row.message)
	
	-- from https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/MailFrame.lua
	-- in InboxFrame_OnClick(...), around line 286
	InboxFrame.openMailID = row.message.messageID;
	OpenMailFrame.updateButtonPositions = true;
	OpenMail_Update();
	--OpenMailFrame:Show();
	ShowUIPanel(OpenMailFrame);
	OpenMailFrameInset:SetPoint("TOPLEFT", 4, -80);
	PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN);

	InboxFrame_Update();	
end



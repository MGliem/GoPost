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

local gameversion = select(4, GetBuildInfo())	-- number like 80301 or 11303
if (gameversion) then
	if (gameversion >= 80000) then
		Addon.RETAIL = true
		Addon.CLASSIC = false
	else
		Addon.RETAIL = false
		Addon.CLASSIC = true
	end
else
	Addon.RETAIL = true
	Addon.CLASSIC = false
end


Addon:RegisterEvent("MAIL_SHOW")
Addon:RegisterEvent("MAIL_INBOX_UPDATE")
Addon:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")


function Addon : MAIL_SHOW(arg)
	if (not self.initialized) then
		self:SetFrameStrata("DIALOG")
	
		self:CreateUI()
		assert(self.initialized)
	end
	
	-- show stuff
	self.expanded = {}			-- empty array means no sections expanded
	self.first_update = true	-- handle MAIL_INBOX_UPDATE without delay
	
	-- may GoPost current, depending on setting
	if (Addon.DB.auto) then
		MailFrameTab_OnClick(self.tab1, self.tab1:GetID())
	end

	-- while we're shown, we want to handle these
	-- Looter relies on these to advance it through looting a message (and, therefore, a section)
	-- if one of these is delayed "too long", then this file (Core.lua) will update the scroller while the Looter is still "busy",
	-- leaving the loot buttons disabled.  When the delayed event finally fires, the Looter goes idle, but the buttons are still disabled.
	-- So, we handle these and update the scroller [possibly unnecessarily] when they fire (subject to the same throttling as MAIL_INBOX_UPDATE)
	self:RegisterEvent("BAG_UPDATE_DELAYED")	-- signals well and truely done putting an item in your bag, e.g. looted from mail, and other sources
	self:RegisterEvent("PLAYER_MONEY")			-- signals a change to the player's gold balance, e.g. when looting from mail, and other sources
	self.BAG_UPDATE_DELAYED = function () Addon:UpdateMessages_Throttled() end
	self.PLAYER_MONEY = function () Addon:UpdateMessages_Throttled() end
end



function Addon : PLAYER_INTERACTION_MANAGER_FRAME_HIDE(eventName, ...)
	if eventName ==  Enum.PlayerInteractionType.MailInfo then
		self.Looter:Abort(nil)
		self:Hide()
		
		-- ignore these events now
		self.BAG_UPDATE_DELAYED = nil
		self.PLAYER_MONEY = nil
	end
end



function Addon : MAIL_INBOX_UPDATE(mb, arg2_always_false)

	if (mb) then return end	-- a mail item was clicked with this mouse button

	if (not self.initialized) then
		-- this can happen when hovering the mouse over the "you've got mail" icon on the minimap, if the mailbox hasn't been opened yet
		--print("GoPost bailing on MAIL_INBOX_UPDATE - never initialized")
		return
	end
	
	if (self.first_update) then
		self:UpdateMessages()
		self.first_update = false
	else
		self:UpdateMessages_Throttled()
	end
end



function Addon : UpdateMessages_Throttled()
	if (1) then
		-- this version throttles UI updates to once every 0.5 seconds
		if (self.update_timer == nil) then
			self.update_timer = C_Timer.NewTimer(0.50,
												 function()
													 Addon.update_timer = nil
													 Addon:UpdateMessages()
												 end)
		end

	else

		-- this version resets the timer on each event, so it only updates messages after the last event
		if (self.update_timer) then
			self.update_timer:Cancel()
		end
		self.update_timer = C_Timer.NewTimer(0.50,
											 function()
												 Addon.update_timer = nil
												 Addon:UpdateMessages()
											 end)

	end
end



function Addon : CreateUI()
	
	assert(not self.initialized)

	local debug_offset = 0 --800

	self:SetParent(MailFrame)
	
	self:SetWidth(384-50)
	self:SetHeight(512-1)
	self:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", debug_offset + 0, -1)
	self:SetFrameStrata("DIALOG")
	
	-- filter controls at top
	self.openall = CreateFrame("Button", nil, self, "GPSmallButton")
	self.openall:SetText(L["Open All"])
	self.openall:SetWidth(100)
	self.openall:SetHeight(28)
	self.openall:SetPoint("TOPRIGHT", self, "TOPRIGHT", -20, -27)
	self.openall:SetScript("OnClick",
						   function()
							   Addon.Looter:LootSection("*")
							   assert(Addon.Looter:IsBusy())
							   Addon:UpdateScroller() -- to disable loot buttons
						   end)
	
	-- move this to the left to make room for my "open all" button
	InboxTooMuchMail:SetPoint("TOP", InboxTooMuchMail:GetParent(), "TOP", -58-2, -25) -- Blizz XML has its top at 0, -25
	
	-- bottom has a scroller for messages
	self.scroller = CreateFrame("ScrollFrame", nil, self, "SectionScrollerTemplate")
	self.scroller:SetPoint("TOPLEFT", self, "TOPLEFT", 7, -61-5)
	self.scroller:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -7, 94)
	self.scroller.delegate = {
		SectionScrollerDelegate_NumberOfSections = function(ss) return self:Scroller_NumberOfSections() end,
		SectionScrollerDelegate_GetRowForSection = function(ss, section) return self:Scroller_GetRowForSection(section) end,
		SectionScrollerDelegate_NumberOfItemsInSection = function(ss, section) return self:Scroller_NumberOfItemsInSection(section) end,
		SectionScrollerDelegate_GetRowForItem = function(ss, section, item) return self:Scroller_GetRowForItem(section, item) end,
	}
	
	local bg = self.scroller:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface/MailFrame/UI-MailFrameBG")
	bg:SetTexCoord(0.03, 0.625, 0, 0.68)
	bg:SetPoint("TOPLEFT", self.scroller, "TOPLEFT", 0, 5)
	bg:SetPoint("BOTTOMRIGHT", self.scroller, "BOTTOMRIGHT", 0, 0)

	
	-- add a tab for myself (https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/SharedXML/SharedUIPanelTemplates.lua)
	local tabID = MailFrame.numTabs + 1
	local tab = CreateFrame("Button", "MailFrameTab"..tabID, MailFrame, "FriendsFrameTabTemplate")
	tab:SetID(tabID)
	tab:SetText("GoPost")
	tab:SetPoint("LEFT", _G["MailFrameTab"..(tabID-1)], "RIGHT", -8, 0);
	PanelTemplates_SetNumTabs(MailFrame, tabID);
	PanelTemplates_EnableTab(MailFrame, tabID);
	self.tab1 = tab
	
	self.orig_MailFrameTab_OnClick = MailFrameTab_OnClick;
	MailFrameTab_OnClick = function (tab, index) Addon:MailFrameTab_OnClick(tab, index) end
	
	self.tab1:SetScript("OnClick", function() MailFrameTab_OnClick(tab, tabID) end)

	
	self.initialized = true
end



function Addon : MailFrameTab_OnClick(tab, index)
	
	if (tab == self.tab1) then
		-- switch to Inbox tab, show myself, make my tab look like it's current
		self.orig_MailFrameTab_OnClick(MailFrameTab1, 1)
		self:Show()
		PanelTemplates_SetTab(MailFrame, self.tab1:GetID());
	else
		self.orig_MailFrameTab_OnClick(tab, index)
		self:Hide()
	end
	
	index = index or tab:GetID()
	-- co-exist with "Postal"
	if (index) then
		-- "Postal" puts two button it the top margin, but they remain visible when my tab is shown
		-- (probably "hide only on Send tab" instead of "show only on Inbox tab")
		-- so, I hide them on all but the Inbox tab
		local inbox = (index == 1)
		if (PostalSelectOpenButton) then PostalSelectOpenButton:SetShown(inbox) end
		if (PostalSelectReturnButton) then PostalSelectReturnButton:SetShown(inbox) end
	end
end



--function Addon : SectionForMessage(m)
--	if (self.messages) then
--		local info = self.messages[m]
--		if (info) then
--			return info.section, info.cod
--		end
--	end
--	return nil, 0
--end


function Addon : SectionForMessage(m)
	local _, _, sender, subject, _, amountCOD, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(m)
	if (sender == nil) then
		return nil, nil
	end
	
	if (isGM or sender:find(L[Strings.SENDER_POSTMASTER]) or sender:find(L[Strings.SENDER_VASHREEN])) then

		-- GM, or unlooted items (npc=34337), or bonus roll w/ bags full (npc=54441)
		return "System", amountCOD
	
	elseif (string.match(subject, L[Strings.AUCTION_SOLD_PREFIX])) then
			
		-- subject looks like a seller invoice... is it?
		local invoiceType, itemName, otherPlayer, bid, buyout, deposit, commission = GetInboxInvoiceInfo(m)
		if (invoiceType == "seller") then
			return "Sales", nil
		else
			return "Others", amountCOD
		end
		
		
	elseif (string.match(subject, L[Strings.AUCTION_WON_PREFIX])) then
			
		-- subject looks like a buyer invoice... is it?
		local invoiceType, itemName, otherPlayer, bid, buyout, deposit, commission = GetInboxInvoiceInfo(m)
		if (invoiceType == "buyer") then
			return "Purchases", nil
		else
			return "Others", amountCOD
		end
		
	end
	
	-- count attachments
	local num_attachments = 0
	for a = 1, ATTACHMENTS_MAX_RECEIVE do
		local itemName, itemID, texture, count, _, _ = GetInboxItem(m, a)
		if (itemName) then
			num_attachments = num_attachments + 1
			if (num_attachments > 1) then
				return "Others", amountCOD
			end
		end
	end
	assert(num_attachments == 0 or num_attachments == 1);
	
	if (num_attachments == 0) then
		return "Others", amountCOD
	elseif (string.match(subject, L[Strings.AUCTION_EXPIRED_PREFIX])) then
		return "Expired", nil
	elseif (string.match(subject, L[Strings.AUCTION_CANCELLED_PREFIX])) then
		return "Cancelled", nil
	else -- one attachments, not expired/cancelled auction
		return "Others", amountCOD
	end
end


function Addon : UpdateMessages()
	
	-- clear the index
	self.messages = {} -- by message ID
	self.sections = {}
	for _,group in ipairs(self.groups) do self.sections[group]={} end
			
	-- scan the inbox to fill the index
	local n = GetInboxNumItems()
	for m = 1, n do
		-- save display info about it
		-- packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(m)
		local packageIcon, _, sender, subject, money, amountCOD, _, hasItem, opened, wasReturned, _, _, isGM = GetInboxHeaderInfo(m)
		if (subject == "Retrieving data") then
			-- ignore
		elseif (sender) then
			
			--print("message", m, "sender", sender, "subject", subject);
			
			local info = {}
			info.messageID = m
			info.sender = sender
			info.subject = subject
			info.money = money or 0
			info.attachments = 0
			info.opened = opened
			info.cod = amountCOD

			if (isGM or sender:find(L[Strings.SENDER_POSTMASTER]) or sender:find(L[Strings.SENDER_VASHREEN])) then	-- GM, or unlooted items (npc=34337), or bonus roll w/ bags full (npc=54441)
			
				info.section = "System"
				-- attachments scanned below
			
			elseif (string.match(subject, L[Strings.AUCTION_SOLD_PREFIX])) then
					
				-- subject looks like a seller invoice... is it?
				local invoiceType, itemName, otherPlayer, bid, buyout, deposit, commission = GetInboxInvoiceInfo(m)
				if (invoiceType == "seller") then
					info.section = "Sales"
					info.itemName = itemName
	
					-- must parse the subject to get the stack size
					info.itemCount = string.match(info.subject, Strings.STACK_SIZE_PATTERN) --"%(([0-9]+)%)$") -- does it end with a stack size?
					if (info.itemCount) then
						info.itemCount = 0 + info.itemCount	-- force conversion to number
					else
						info.itemCount = 1	-- no stack size, so assume quantity is 1
					end
					
					-- see if we can get a texture from the item name
					local _, itemLink, _, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(itemName)
					info.itemLink = itemLink
					info.itemTexture = itemTexture
					
					if (Addon.RETAIL) then	-- no C_PetJournal in classic
						-- if no texture and it might be a battle pet, try to get a pet texture
						if (info.itemTexture == nil and (info.itemLink == nil or info.itemLink:find("|Hbattlepet:"))) then
							local speciesID, petID = C_PetJournal.FindPetIDByName(info.itemName)
							if (speciesID) then
								assert(info.itemTexture == nil)
								info.itemTexture = select(2, C_PetJournal.GetPetInfoBySpeciesID(speciesID)) --  name, icon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
							end
						end
					end
				else
					-- not a real invoice
					assert(info.section == nil)
				end
				
			elseif (string.match(subject, L[Strings.AUCTION_WON_PREFIX])) then
					
				-- subject looks like a buyer invoice... is it?
				local invoiceType, itemName, otherPlayer, bid, buyout, deposit, commission = GetInboxInvoiceInfo(m)
				if (invoiceType == "buyer") then
					info.section = "Purchases"
					-- attachments are scanned below
				else
					-- not a real invoice
					assert(info.section == nil)
				end
				
			end

			-- scan attachments
			for a = 1, ATTACHMENTS_MAX_RECEIVE do
				local itemName, itemID, texture, count, _, _ = GetInboxItem(m, a)
				if (itemName) then
					info.attachments = info.attachments + 1
					
					if (info.itemName == nil) then
						info.itemID = itemID
						info.itemName = itemName
						info.itemCount = count
						info.itemTexture = texture
						info.itemLink = GetInboxItemLink(m, a)
					end
				end
			end

			-- mop up
			if (info.section == nil) then
				if (info.attachments == 1) then
					if (string.match(subject, L[Strings.AUCTION_EXPIRED_PREFIX])) then
						info.section = "Expired"
					elseif (string.match(subject, L[Strings.AUCTION_CANCELLED_PREFIX])) then
						info.section = "Cancelled"
					else
						info.section = "Others"
					end
				else
					info.section = "Others"
				end
			end

			assert(info.section)
			self.messages[info.messageID] = info

			-- save it with others in the same section
			--print("message", info.messageID, "is in", section)
			assert(self.sections)
			assert(self.sections[info.section])
			table.insert(self.sections[info.section], info)
		end -- non-nil sender
	end -- message loop
	
	-- on the first update, we may want to expand one/all non-empty groups
	if (self.first_update and (not (self.DB.autoexpand == "none"))) then
		-- see which group(s) contain messages
		local nonempty = {}
		for name,messages in pairs(self.sections) do
			if (#messages > 0) then
				table.insert(nonempty, name)
			end
		end
		-- expand one/all based on the setting
		if (self.DB.autoexpand=="single" and #nonempty == 1) then
			assert(self.first_update and #self.expanded == 0)
			self.expanded[nonempty[1]] = true
		elseif (self.DB.autoexpand=="all" and #nonempty > 0) then
			for _,name in ipairs(nonempty) do
				self.expanded[name] = true
			end
		end
	end
	
	-- update the scroller contents
	self:UpdateScroller()
	
end



function Addon : UpdateScroller()
	
	SectionScroller_UpdateContent(self.scroller)
	
	-- this button is disabled unless we have at least one lootable message in any section except System
	local enabled = false
	for section,messages in pairs(self.sections) do
		if (not (section == "System")) then
			for _,msg in ipairs(messages) do
				enabled = (msg.money > 0 or msg.attachments > 0)
				if (enabled) then break end
			end
			if (enabled) then break end
		end
	end
	
	enabled = enabled and (not self.Looter:IsBusy())

	self.openall:SetEnabled(enabled)
end



local ROW_MARGIN = 16	-- width of the scrollbar, about

local SECTION_NAMES = Addon.groups

function Addon : Scroller_NumberOfSections()
	assert(self.sections)
	return #SECTION_NAMES
end


function Addon : Scroller_GetRowForSection(s)
	
	-- get or create a row for this section
	local section = SECTION_NAMES[s]	-- like "Sales" or "Expired"
	local reuseKey = section
	local row = SectionScroller_GetReusableRow(self.scroller, reuseKey)
	if (row == nil) then
		row = self:HeaderRow_Create(self.scroller:GetWidth() - ROW_MARGIN)
		row.reuseKey = reuseKey
		row:SetScript("OnClick", function() self:HeaderRow_Click(row) end)
	end
	
	-- populate it with the current set of messages
	row.section = section
	row.Populate(self.sections[section])
	
	return row
end


function Addon : Scroller_NumberOfItemsInSection(s)
	
	local section = SECTION_NAMES[s]	-- like "Sales" or "Expired"
	if (self.expanded[section]) then
		local messages = self.sections[section]
		assert(messages)
		return #messages
	else
		return 0
	end
	
end


function Addon : Scroller_GetRowForItem(s, item)

	local section = SECTION_NAMES[s]	-- like "Sales" or "Expired"
	local messages = self.sections[section]
	local message = messages[item]

	local width = self.scroller:GetWidth() - ROW_MARGIN

	local reuseKey
--	if (message.sender == L[Strings.SENDER_AUCTION_HOUSE] and not message.subject:find(L[Strings.AUCTION_OUTBID_PREFIX])) then
	if (section == "Sales" or section == "Purchases" or section == "Expired" or section == "Cancelled") then
		reuseKey = "AuctionMessage"
	else
		reuseKey = "OtherMessage"
		--print("section is "..(section or "(nil)")..", s is "..(s or "(nil)")..", subject is "..(message and message.subject or "(nil)"))
	end
	
	local row = SectionScroller_GetReusableRow(self.scroller, reuseKey)
	if (row == nil) then
		local fn = reuseKey .. "_Create" -- like "AuctionMessage_Create"
		row = self[reuseKey.."_Create"](self, self.scroller:GetWidth() - ROW_MARGIN)
		row.reuseKey = reuseKey
	end
	
	row.Populate(message)
	
	return row
end


function Addon : HeaderRow_Click(row)
	
	if (self.expanded[row.section]) then
		self.expanded[row.section] = nil
	else
		self.expanded[row.section] = true
	end
	
	self:UpdateMessages()
end






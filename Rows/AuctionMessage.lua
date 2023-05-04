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

local HEIGHT = 18

local indent = 4


function Addon : AuctionMessage_Create(WIDTH)

	local row = CreateFrame("Frame")
	row:SetWidth(WIDTH)
	row:SetHeight(HEIGHT)
	
	row.line = row:CreateTexture(nil, "ARTWORK")
	row.line:SetWidth(1.5)
	row.line:SetHeight(HEIGHT+4)
	row.line:SetColorTexture(0.30, 0.20, 0, 1)
	row.line:SetPoint("LEFT", row, "LEFT", 17, 2) -- this 2 is half of the 4 added to it height
	
	row.button = CreateFrame("Button", nil, row)
	row.button:SetPoint("TOPLEFT", row, "TOPLEFT", 26-3, 0) -- left edge between row.line and row.icon
	row.button:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
	row.button:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight2", "ADD")
	row.button:SetAlpha(0.30)
	row.button:SetScript("OnClick", function() Addon:AuctionMessage_Click(row) end)
	
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetWidth(HEIGHT-2)
	row.icon:SetHeight(HEIGHT-2)
	row.icon:SetTexCoord(2/34, 32/34, 2/34, 32/34)
	row.icon:SetPoint("LEFT", row, "LEFT", indent+8+16, 0)
	
	row.label = row:CreateFontString(nil, "OVERLAY", "GPFont")
	row.label:SetJustifyH("LEFT")
	row.label:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
	row.label:SetTextColor(0,0,0, 1)
	
	row.money = row:CreateFontString(nil, "OVERLAY", "GPNumberFontSmaller")
	row.money:SetJustifyH("RIGHT")
	row.money:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	
	row.Populate = function (message) self:AuctionMessage_Populate(row, message) end
		
	return row

end


function Addon : AuctionMessage_Populate(row, message)

	row.message = message
	
	--row.icon:SetTexture(message.itemTexture or "Interface/ICONS/INV_Misc_QuestionMark")
	SetPortraitToTexture(row.icon, message.itemTexture or "Interface/ICONS/INV_Misc_QuestionMark")
		
	if (message.itemName) then
		if (message.itemCount and message.itemCount > 1) then
			row.label:SetText(message.itemName .. " (" .. message.itemCount .. ")")
		else
			row.label:SetText(message.itemName)
		end
	else
		row.label:SetText("(unknown item)") -- probably already looted but message not yet deleted
	end
	
	if (message.section == "Sales" and message.money > 0) then
		row.money:SetText( util.gold_format(message.money, nil, message.money>100*1000*(100*100)) )
		row.money:SetTextColor(1,1,1, 0.90)
		row.money:Show()
	elseif (message.section == "Purchases" and message.money > 0) then
		row.money:SetText( util.gold_format(message.money, nil, message.money>100*1000*(100*100)) )
		row.money:SetTextColor(0,0,0, 1)
		row.money:Show()
	else
		row.money:Hide()
	end
	
end



function Addon : AuctionMessage_Click(row)
	
	-- ignore if we've never been populated
	if (row.message == nil) then return end
	
	--print("Looting AuctionMessage", row.message.messageID, row.message.section)
	self.Looter:LootMessage(row.message.messageID, row.message.section)
	
	self:UpdateScroller()
end




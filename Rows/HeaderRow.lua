--[[
Copyright 2018-2020, Quarq
This file is part of GoPost.
GoPost is distributed under a BSD License.
It is provided AS-IS and all warranties, express or implied, including, but not
limited to, the implied warranties of merchantability or fitness for a particular
purpose, are disclaimed.  See the LICENSE file for full information.
--]]


local _, namespace = ...
local L = namespace.Strings.L
assert(L)

local Addon = GoPost
local util = Addon.util

local HEIGHT = 40

local VERT_OFFSET = -5


function Addon : HeaderRow_Create(WIDTH)

	local row = CreateFrame("Button")
	row:SetWidth(WIDTH)
	row:SetHeight(HEIGHT)
	
	row.divider = row:CreateTexture(nil, "ARTWORK")
	row.divider:SetWidth(WIDTH)
	row.divider:SetHeight(1.5)
	row.divider:SetColorTexture(0,0,0, 0.30)
	row.divider:SetPoint("TOP", row, "TOP", 0, VERT_OFFSET)
	
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetWidth(20)
	row.icon:SetHeight(20)
	row.icon:SetPoint("LEFT", row, "LEFT", 8, VERT_OFFSET)
	
	row.label = row:CreateFontString(nil, "OVERLAY", "GPHeaderFont")
	row.label:SetJustifyH("LEFT")
	row.label:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
	row.label:SetTextColor(0,0,0, 1)
	
	row.button = CreateFrame("Button", nil, row, "GPSmallButton")
	row.button:SetWidth(80)
	row.button:SetHeight(HEIGHT/2)
	row.button:SetPoint("RIGHT", row, "RIGHT", -6, VERT_OFFSET)

	row.money = row:CreateFontString(nil, "OVERLAY", "GPNumberFont")
	row.money:SetJustifyH("RIGHT")
	row.money:SetTextColor(1,1,1, 1)
	row.money:SetPoint("RIGHT", row.button, "LEFT", -4, 0)
	
	row.button:SetScript("OnClick", function() self:HeaderRow_Loot_Click(row) end)
	
	row.Populate = function (messages) self:HeaderRow_Populate(row, messages) end
		
	return row

end


function Addon : HeaderRow_Populate(row, messages)
	
	row.divider:SetShown(not (row.section == "Sales"))
	
	row.icon:SetTexCoord(0,1,0,1)
	if (row.section == "Sales") then
		row.icon:SetTexture("Interface/MINIMAP/TRACKING/Auctioneer")
	elseif (row.section == "Purchases") then
		row.icon:SetTexture("Interface/AddOns/GoPost/textures/crate128")
		--row.icon:SetTexCoord(0/15, 1/15, 13/15, 14/15)
	elseif (row.section == "Cancelled") then
		row.icon:SetTexture("Interface/AddOns/GoPost/textures/redx128")
		--row.icon:SetTexCoord(8/15, 9/15, 6.85/15, 7.85/15)
	elseif (row.section == "Expired") then
		row.icon:SetTexture("Interface/WorldMap/Skull_64")
		row.icon:SetTexCoord(0.025, 0.475, 0.025, 0.475)
	elseif (row.section == "Others") then
		row.icon:SetTexture("Interface/MINIMAP/TRACKING/Mailbox")
	elseif (row.section == "System") then
		row.icon:SetTexture("Interface/CHATFRAME/UI-ChatIcon-WoW")
	else
		row.icon:SetTexture(nil)
	end

	if (#messages > 0) then
		
		row.icon:SetDesaturated(false) -- saturated
		row.icon:SetAlpha(1)
		
		row.label:SetText(L[row.section] .. " (" .. #messages .. ")")
		row.label:SetTextColor(0,0,0, 1)

		if (row.section == "Sales") then
			row.button:SetText(L["Collect"])
		elseif (row.section == "Others" or row.section == "System") then
			row.button:SetText(L["Loot All"])
		else
			row.button:SetText(L["Take Items"]) -- Purchases, Cancelled, Expired
		end
		
		row.button:Hide() -- until we know otherwise
		
		-- tally up money and item attachments
		local money = 0
		local items = 0
		for _,info in ipairs(messages) do
			money = money + info.money
			items = items + (info.attachments or 0)
		end
		
		if (money > 0) then
			local formatted = util.gold_format(money, nil, money>100*1000*(100*100))
			row.money:SetText( formatted )
			row.money:Show()
			row.button:Show()
		else
			row.money:Hide()
		end

		if (items > 0) then
			row.button:Show()
		end

	else
		
		row.icon:SetDesaturated(true)
		row.icon:SetAlpha(0.3)
		
		row.label:SetText(L[row.section])
		row.label:SetTextColor(0,0,0, 0.50)
		
		row.money:Hide()
		row.button:Hide()
		
	end
	
	if (row.section == "System") then
		row.button:Hide()
	end
	
	if (self.Looter:IsBusy()) then
		row.button:Disable()
	else
		row.button:Enable()
	end
end



function Addon : HeaderRow_Loot_Click(row)
	-- ignore if we've never been populated
	if (row.section == nil) then return end
	
	--print("Looting", row.section)
	self.Looter:LootSection(row.section)
	
	self:UpdateScroller()
end




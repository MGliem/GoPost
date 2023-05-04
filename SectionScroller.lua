--[[
Copyright 2018-2020, Quarq
This file is part of GoPost.
GoPost is distributed under a BSD License.
It is provided AS-IS and all warranties, express or implied, including, but not
limited to, the implied warranties of merchantability or fitness for a particular
purpose, are disclaimed.  See the LICENSE file for full information.
--]]


function SectionScroller_OnLoad(scroller)
	
	local bar = CreateFrame("Slider", nil, scroller, "UIPanelScrollBarTemplate")
	bar:SetPoint("TOPRIGHT", scroller, "TOPRIGHT", 0, -bar:GetWidth())
	bar:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", 0, bar:GetWidth())
	bar:SetScript("OnValueChanged", function(self,value) SectionScroller_OnScrollbarValueChanged(self:GetParent(), value) end)
	bar:SetValueStep(1)
	bar.scrollStep = 10		-- bar button scroll distance
	bar:SetMinMaxValues(0, 0)
	scroller.bar = bar
	
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0,0,0, 0.30)
	bg:SetAllPoints(bar)

	local window = CreateFrame("FRAME", nil, scroller)
	window:SetPoint("TOPLEFT", scroller, "TOPLEFT", 0, 0)
	window:SetPoint("BOTTOMRIGHT", scroller, "BOTTOMRIGHT", -scroller.bar:GetWidth(), 0)
	window:SetClipsChildren(true)
	window.contentOffset = 0	-- how far down into the client's data is the top of the visible area
	window.contentHeight = 0	-- total height of client's data
	window.content = {}
	scroller.window = window

	local anchor = CreateFrame("FRAME", nil, window)
	anchor:SetWidth(1)	-- can't be 0-sized... couldn't position relative to it
	anchor:SetHeight(1)
	anchor.offset = 0	-- anchor is above window top by this much
	anchor:SetPoint("BOTTOMLEFT", window, "TOPLEFT", 0, anchor.offset)
	window.anchor = anchor
	


	-- do this AFTER scroller.window is assigned
	-- it triggers the OnValueChanged handler, which assumes the scroller is fully set up
	scroller.bar:SetValue(0)
	
	--print("loaded scroller", scroller)
end


--##   PRIVATE stuff   ##########################################################################################################################################################


local ROW_GAP = 0


local function save_reusable_row(scroller, row, key)
	key = key or ""
	local queue = scroller.reusableRows[key]
	if (queue == nil) then
		queue = { first=1, last=0 }
		scroller.reusableRows[key] = queue
	end
	queue.last = queue.last + 1
	queue[queue.last] = row
	--print("saved reusable \""..key.."\" row, now", queue.last-queue.first+1)
end


local function get_reusable_row(scroller, key)
	-- see if we have a non-empty queue for this reuseKey
	local queue = scroller.reusableRows[key]
	if (queue and queue.last >= queue.first) then
		local row = queue[queue.first]
		assert(row.reuseKey == key)
		queue[queue.first] = nil
		queue.first = queue.first + 1
		--print("reusing a \""..key.."\" row,", queue.last-queue.first+1, "remain")
		return row
	else -- no queue or queue is empty
		return nil
	end
end


local function row_in_window(rowOffset, rowHeight, windowOffset, windowHeight)
	local margin = 0 --rowHeight	-- scrollbar:GetValueStep() * scrollbar:GetStepsPerPage() would be better
	local rowBottom = rowOffset + rowHeight
	local windowBottom = windowOffset + windowHeight
	if (rowOffset >= windowBottom + margin) then
		return false, nil	-- completely below the bottom
	elseif (rowBottom <= windowOffset - margin) then
		return false, nil	-- completely above the top
	else
		local fully = (rowOffset >= windowOffset and rowBottom <= windowBottom)
		return true, fully
	end
end


local function scroll_to(scroller, offset)
	-- clamp the offset
	local window = scroller.window
	local limit = window.contentHeight - window:GetHeight()
	window.contentOffset = math.max(0, math.min(offset, limit))
	
	-- move existing content
	window.anchor:SetPoint("BOTTOMLEFT", window, "TOPLEFT", 0, window.contentOffset)
	
	if (scroller.bar:GetValue() ~= window.contentOffset) then
		scroller.bar:SetValue(window.contentOffset)
	end
	
	-- do not adjust visibility here (for rows scrolling in/out)
end


local function update_row_visibility(scroller)
	local window = scroller.window
	window:SetAllPoints(scroller)

	--print("(SS showing visible content)")
	
	-- scan everything looking for what needs to appear and disappear
	local incoming = {}
	local outgoing = {}
	for r,row in ipairs(window.content) do
		local should_be_visible, fully = row_in_window(row.offset, row.height, window.contentOffset, window:GetHeight())
		--print("content row", r, (should_be_visible and "SHOULD" or "should NOT").." be visible, "..(row.frame and "HAS a frame" or "has NO frame"))
		if (should_be_visible) then
			if (row.frame) then
				row.frame:EnableMouse(fully)
			else
				table.insert(incoming, row)
			end
		else -- should not be visible
			if (row.frame) then
				row.frame:EnableMouse(false)
				table.insert(outgoing, row)
			end
		end
	end
	
	-- recycle the outgoing
	for _,row in ipairs(outgoing) do
		--print("recycling frame for row", r, "at offset", row.offset, "(",row.frame,")")
		save_reusable_row(scroller, row.frame, row.frame.reuseKey)
		row.frame:ClearAllPoints()
		row.frame:Hide()
		row.frame:SetParent(nil) -- could we un-parent him here?
		row.frame:EnableMouse(false)
		row.frame = nil
	end
	
	-- show the incoming
	for r,row in ipairs(incoming) do
		if (row.item) then
			row.frame = scroller.delegate.SectionScrollerDelegate_GetRowForItem(scroller, row.section, row.item)
		else
			row.frame = scroller.delegate.SectionScrollerDelegate_GetRowForSection(scroller, row.section)
		end
		row.frame:SetParent(window)
		row.frame:ClearAllPoints()
		row.frame:SetPoint("TOPLEFT", window.anchor, "BOTTOMLEFT", 0, -row.offset)
		row.frame:Show()
		--print("created frame for row", r, "at offset", row.offset, "(",row.frame,")")

		local should_be_visible, fully = row_in_window(row.offset, row.height, window.contentOffset, window:GetHeight())
		assert(should_be_visible)
		row.frame:EnableMouse(fully)
		--if (not fully and row.frame.label) then print("partial: ", row.frame.label:GetText()) end
	end
end


local function update_content(scroller)
	assert(scroller.delegate)

	scroller.reusableRows = scroller.reusableRows or {}

	local window = scroller.window
	
	-- recycle visible rows for old content
	for _,row in ipairs(window.content) do
		if (row.frame) then
			save_reusable_row(scroller, row.frame, row.frame.reuseKey)
			row.frame:ClearAllPoints()
			row.frame:UnregisterAllEvents()
			row.frame:Hide()
			row.frame:SetParent(nil) -- could we un-parent him here?
			row.frame = nil
		end
	end
	
	--print("(SS sizing all content)")

	-- get new content from delegate
	local newContent = {}
	local newRow
	local newHeight = 0
	local ns = scroller.delegate.SectionScrollerDelegate_NumberOfSections(scroller)
	for s=1, ns do
		newRow = { offset=newHeight, section=s }

		-- need client object just for its height
		local frame = scroller.delegate.SectionScrollerDelegate_GetRowForSection(scroller, s)
		frame:SetParent(window)
		save_reusable_row(scroller, frame, frame.reuseKey) -- recycle it
		
		newRow.height = frame:GetHeight()
		table.insert(newContent, newRow)
		newHeight = newHeight + newRow.height + ROW_GAP
		
		local ni = scroller.delegate.SectionScrollerDelegate_NumberOfItemsInSection(scroller, s)
		for i=1, ni do
			newRow = { offset=newHeight, section=s, item=i }
			
			-- need client object just for its height
			local frame = scroller.delegate.SectionScrollerDelegate_GetRowForItem(scroller, s, i)
			frame:SetParent(window)
			save_reusable_row(scroller, frame, frame.reuseKey) -- recycle it

			newRow.height = frame:GetHeight()
			table.insert(newContent, newRow)
			newHeight = newHeight + newRow.height + ROW_GAP
		end		
	end
	window.content = newContent
	window.contentHeight = newHeight

	-- update scrollbar limits for new contentHeight
	local limit = math.max(0, window.contentHeight - window:GetHeight())
	scroller.bar:SetMinMaxValues(0, limit) -- TODO: update enable states of scroll buttons
	scroller.bar:SetStepsPerPage(math.floor(window:GetHeight() * 0.80 + 0.5))	-- TODO: after this, getter says -27 instead of the value I give it
	
	-- make sure the current window is still valid for the new contentHeight
	if (window.contentOffset > limit) then
		window.contentOffset = limit
		window.anchor:SetPoint("BOTTOMLEFT", window, "TOPLEFT", 0, window.contentOffset)
		
		scroller.bar:SetValue(limit)
	end
	
	if (window.contentHeight <= scroller:GetHeight()) then
		scroller.bar:Hide()
	else
		scroller.bar:Show()
	end

	--print("new content:", #window.content, "rows, height is", window.contentHeight, ", offset is", window.contentOffset)
end


--##   EVENT handlers   ##########################################################################################################################################################


function SectionScroller_OnMouseWheel(scroller, delta)
	if (delta ~= 0) then
		scroll_to(scroller, scroller.window.contentOffset - delta * scroller.bar.scrollStep) -- multiple of the bar button scroll distance
		update_row_visibility(scroller)
	end
end


function SectionScroller_OnScrollbarValueChanged(scroller, value)
	-- called when the slider handle moves AND when the up/down buttons are clicked
	if (value ~= scroller.window.contentOffset) then
		scroll_to(scroller, value)
		update_row_visibility(scroller)
	end
end


--##   PUBLIC API   ##########################################################################################################################################################


function SectionScroller_UpdateContent(scroller)
	update_content(scroller)
	update_row_visibility(scroller)
end


function SectionScroller_GetReusableRow(scroller, reuseKey)
	reuseKey = reuseKey or ""
	return get_reusable_row(scroller, reuseKey)
end


function SectionScroller_SaveReusableRow(scroller, row, reuseKey)
	reuseKey = reuseKey or ""
	return save_reusable_row(scroller, row, reuseKey)
end


function SectionScroller_GetContentHeight(scroller)
	return scroller.window.contentHeight
end


function SectionScroller_GetContentOffset(scroller)
	return scroller.window.contentOffset
end


function SectionScroller_GetContentOffsetLimit(scroller)
	return scroller.window.contentHeight - scroller.window:GetHeight()
end


function SectionScroller_ScrollBy(scroller, delta)
	if (delta ~= 0) then
		scroll_to(scroller, scroller.window.contentOffset + delta)	-- TODO: is this sign correct?
		update_row_visibility(scroller)
	end
end


function SectionScroller_ScrollTo(scroller, offset)
	if (value ~= scroller.window.contentOffset) then
		scroll_to(scroller, offset)
		update_row_visibility(scroller)
	end
end

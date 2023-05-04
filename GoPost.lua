--[[
Copyright 2018-2020, Quarq
This file is part of GoPost.
GoPost is distributed under a BSD License.
It is provided AS-IS and all warranties, express or implied, including, but not
limited to, the implied warranties of merchantability or fitness for a particular
purpose, are disclaimed.  See the LICENSE file for full information.
--]]

GoPost = CreateFrame("FRAME", "GoPost", UIParent)

local Addon = GoPost
Addon:Hide()

Addon.util = Addon.util or {}	-- see Util.lua
local util = Addon.util

local _, namespace = ...
local L = namespace.Strings.L
assert(L)

Addon.version = GetAddOnMetadata(Addon:GetName(), "Version")


Addon.groups = { "Sales", "Purchases", "Cancelled", "Expired", "Others", "System" }

Addon:SetScript("OnEvent", function(self,event,...) if Addon[event] then util.printif(false, "handling:"..event.."()"); Addon[event](self, ...) end end)

Addon:RegisterEvent("ADDON_LOADED")


function Addon : ADDON_LOADED(arg)
	if (not (arg == Addon:GetName())) then
		return
	end
	
	--Addon.player = UnitName("player")
	--Addon.realm = GetRealmName()
	--assert(Addon.realm)
	--assert(Addon.realm:len() > 0)

	assert(not self.loaded)
	self.loaded = true
	--print(Addon:GetName(), "loaded")
	
	-- initialize settings database
	GoPostDB = GoPostDB or {}
	
	-- character-specifics
	Addon.player = UnitName("player")
	GoPostDB[Addon.player] = GoPostDB[Addon.player] or {}
	Addon.DB = GoPostDB[Addon.player]
	
	-- default is to show the GoPost tab when opening the mailbox
	if (Addon.DB.auto == nil) then
		Addon.DB.auto = true
	end

	Addon.DB.autoexpand = Addon.DB.autoexpand or "none"
	
	-- default is to show custom messages in the chat window when looting money/items from AH mails
	Addon.DB.chat = Addon.DB.chat or {}
	for _,g in ipairs(Addon.groups) do Addon.DB.chat[g]=true end

	
	-- define slash commands... the array index must match the substring in the global variables
	SlashCmdList["GOPOST"] = function(msg) self:Slash(msg) end;
	--    v-------^
	SLASH_GOPOST1= "/gopost";
end


function Addon : Slash(msg)

	msg = msg:trim()
	
	local settings = Addon.DB[UnitName("player")]
	if (msg == "version") then
		print("GoPost version", Addon.version)
	elseif (msg == "auto") then
		settings.auto = true
		print("Mailbox will open on GoPost tab")
	elseif (msg == "manual") then
		settings.auto = false
		print("Mailbox will open on Inbox tab")
	elseif (msg:find("^debug ([-A-Za-z0-9_]+)")) then
		-- e.g. /gopost debug LOOTER-EVENTS
		local cat = msg:match("^debug ([-A-Za-z0-9_]+)")
		if (cat:len() > 0) then
			Addon.DB.debug = Addon.DB.debug or {}
			Addon.DB.debug[cat] = not Addon.DB.debug[cat]
			print("GoPost", (Addon.DB.debug[cat] and "debugging" or "NOT debugging"), "\""..cat.."\"")
		end
	elseif (msg == "debug") then
		local first = true
		for k,v in pairs(Addon.DB.debug) do
			if (v) then
				if (first) then
					first = false
					print("GoPost debugging:")
				end
				print("    ", k)
			end
		end
		if (first) then
			print("GoPost debugging nothing")
		end
	elseif (msg:find("^chat (%a+)")) then
		-- "/gopost chat Expired on" to turn on chat messages about Expired items (off also works)
		-- "/gopost chat Expired" to toggle chat messages about Expired items
		-- "/gopost chat all" (or none) to turn all custom chat message on (or off)
		local group = msg:match("^chat (%a+)")
		group = string.lower(group)
		local flag = msg:match("^chat %a+ (%a+)")
		flag = flag and string.lower(flag) or nil
			
		if (group == "all") then
			for _,g in ipairs(Addon.groups) do Addon.DB.chat[g]=true end
			print("GoPost: chat messages are ON for all groups")
		elseif (group == "none") then
			for _,g in ipairs(Addon.groups) do Addon.DB.chat[g]=false end
			print("GoPost: chat messages are OFF for all groups")
		else
			group = group:sub(1,1):upper() .. group:sub(2)
			for _,g in ipairs(Addon.groups) do
				if (g == group) then
					if (flag == "on") then
						flag = true
					elseif (flag == "off") then
						flag = false
					elseif (flag == nil or flag == "") then
						flag = not Addon.DB.chat[group]
					else
						print("GoPost: Use \"/gopost chat "..group.." on\" (or \"off\") to turn "..group.." chat messages on or off")
						return
					end
					Addon.DB.chat[group] = flag
					print("GoPost: chat messages are", (flag and "ON" or "OFF"), "for", group)
					return
				end
			end
			-- group not in Addon.groups
			group = msg:match("^chat (%a+)") -- original text, case unmodified
			print("GoPost: Use \"/gopost chat GROUPNAME\" to toggle chat messages for a group")
			print("GoPost: or \"/gopost chat GROUPNAME on\" (or \"off\") to turn on (or off) chat messages for a group.")
			print("GoPost: or \"/gopost chat all\" (or \"none\") to turn on (or off) chat message for all groups.")
			return
		end
		
	elseif (msg == "expand" or msg:find("^expand (%a+)$")) then
		
		local which = msg:match("^expand (%a+)$")
		if (which == "off" or which == "none") then
			Addon.DB.autoexpand = "none"
		elseif (which == "single") then
			Addon.DB.autoexpand = "single"
		elseif (which == "all") then
			Addon.DB.autoexpand = "all"
		else -- which not specified, so cycle through none-single-all
			if (Addon.DB.autoexpand == "none") then
				Addon.DB.autoexpand = "single"
			elseif (Addon.DB.autoexpand == "single") then
				Addon.DB.autoexpand = "all"
			else
				Addon.DB.autoexpand = "none"
			end
		end
		print("GoPost auto-expanding", string.upper(Addon.DB.autoexpand=="none" and "no" or Addon.DB.autoexpand), "non-empty groups")
	end
	
end



function Addon : debug(cat, ...)
	Addon.DB.debug = Addon.DB.debug or {}
	if (Addon.DB.debug[cat]) then
		print(...)
	end
end


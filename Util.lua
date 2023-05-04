--[[
Copyright 2018-2020, Quarq
This file is part of GoPost.
GoPost is distributed under a BSD License.
It is provided AS-IS and all warranties, express or implied, including, but not
limited to, the implied warranties of merchantability or fitness for a particular
purpose, are disclaimed.  See the LICENSE file for full information.
--]]


string.trim =
	function (s)
		if (s == nil) then
			return nil
		else
			-- this was trim6() at http://lua-users.org/wiki/StringTrim
			return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
		end
	end


local Addon = GoPost

assert(Addon)
assert(Addon.util)

local util = Addon.util




util.printif =
	function (cond, ...)
		if (cond) then
			print(...)
		end
	end


-- comma formats its integer argument
util.comma_format =
	function (num)
		local s = ""
		while (num >= 1000) do
			s = string.format(",%03d", math.fmod(num,1000)) .. s
			num = math.floor(num / 1000)
		end
		s = "" .. num .. s
		return s
	end


util.color =
	function (hexARGB, text)
		return "|c"..hexARGB..text.."|r"
	end
	
util.green	= function (text) return util.color("FF00A800", text) end	-- like the "You receive item: [whatever]" messages
util.white	= function (text) return util.color("FFFFFFFF", text) end
util.black	= function (text) return util.color("FF000000", text) end
util.red	= function (text) return util.color("FFA00000", text) end
	


local MoneyFontSize = 10
local GoldCoin = GetCoinTextureString(100*100, MoneyFontSize):sub(2)
local SilverCoin = GetCoinTextureString(100, MoneyFontSize):sub(2)
local CopperCoin = GetCoinTextureString(1, MoneyFontSize):sub(2)



util.gold_format =
	function (amount, withCoins, goldOnly)
		if (amount == nil or amount == 0) then
			return ""
		elseif (amount < 0) then
			return "-"..gold_format(0-amount, withCoins)
		else
			if (withCoins == nil) then withCoins=true; end
			if (goldOnly == nil) then goldOnly=false; end
			
			local G = withCoins and GoldCoin or "g"
			local S = withCoins and SilverCoin or "s"
			local C = withCoins and CopperCoin or "c"
	
			local g = math.floor(amount/(100*100))
			local s = math.floor(amount/100) % 100
			local c = amount % 100
			local ss = (s<10 and "0" or "") .. s
			local cc = (c<10 and "0" or "") .. c
			if (true) then
				if (goldOnly) then
					return util.comma_format(g)..G
				else
					if (g > 0) then
						return util.comma_format(g)..G .. " " ..ss..S .. " " ..cc..C
					elseif (s > 0) then
						return s..S .. " " ..cc..C
					else
						return c..C
					end
				end
			else
				return util.comma_format(g).. " . " ..ss.. " . " ..cc
			end
		end
	end

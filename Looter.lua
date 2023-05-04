--[[
Copyright 2018-2020, Quarq
This file is part of GoPost.
GoPost is distributed under a BSD License.
It is provided AS-IS and all warranties, express or implied, including, but not
limited to, the implied warranties of merchantability or fitness for a particular
purpose, are disclaimed.  See the LICENSE file for full information.
--]] local Addon = GoPost
local util = Addon.util

local _, namespace = ...
local Strings = namespace.Strings
local L = Strings.L
assert(L)

local Looter = CreateFrame("Frame")
Addon.Looter = Looter

Looter:SetScript("OnEvent", function(self, event, ...)
    if (Looter[event]) then
        Looter[event](self, ...)
    end
end)

function Looter:IsBusy()
    if (self.section or self.messageID) then
        return true
    else
        return false
    end
end

function Looter:Abort(reason)
    if (reason) then
        print(util.color("FFC00000", L["GoPost looting stopped"] .. ":  " .. L[reason]))
    end
    self:Finish()
end

function Looter:Finish()
    self.section = nil
    self.messageID = nil
    assert(not self:IsBusy())

    Addon:debug("LOOTER", "Looter finished")
end

function Looter:LootSection(section)

    if (self:IsBusy()) then
        print("Looter is BUSY:  can't loot message", messageID, "until it finishes with",
            ((self.messageID and ("message " .. self.messageID)) or self.section))
        return
    end

    Addon:debug("LOOTER", "looting", section, "messages")

    self.section = section
    assert(self.messageID == nil) -- cleared by Finish
    self:Continue()
end

function Looter:LootMessage(messageID, section)

    if (self:IsBusy()) then
        print("Looter is BUSY:  can't loot message", messageID, "until it finishes with",
            ((self.messageID and ("message " .. self.messageID)) or self.section))
        return
    end

    assert(messageID)
    assert(section)

    --	Addon:debug("LOOTER", "looting message", messageID, "in section", section)
    self.messageID = messageID
    self.section = section
    self:Continue()
end

local function has_free_space(n)
    assert(n >= 1)
    for b = 0, 4 do
        for s = 1, C_Container.GetContainerNumSlots(b) do
            local itemID = select(10, C_Container.GetContainerItemInfo(b, s))
            if (itemID == nil) then
                n = n - 1
                if (n <= 0) then
                    return true
                end
            end
        end
    end
    return false
end

function Looter:LootItem(messageID, attachmentID)

    assert(false) -- nobody calling this, right?

    if (self:IsBusy()) then
        print("Looter is BUSY:  can't loot item #" .. attachmentID, "in message", messageID, "until it finishes with",
            (self.section or ("message " .. self.messageID)))
        return false
    end

    Addon:debug("LOOTER", "looting attachment #" .. attachmentID, "of message", messageID)

    if (has_free_space(1)) then
        TakeInboxItem(messageID, attachmentID)
        return true
    else
        self:Abort(L["Insufficent bag space"])
        return false
    end
end

function Looter:Continue()

    -- I only need to continue if I'm working on a section or a message
    if (self.section == nil and self.messageID == nil) then
        return
    end

    ---- exactly one is assigned
    -- assert(self.section or self.messageID)
    -- assert(not (self.section and self.messageID))

    if (self.messageID) then

        local money, attachment, finished = self:do_loot_message(self.messageID)
        if (finished) then
            -- doesn't matter whether any money/attachment was taken... we're done
            self:Finish()
            return
        elseif (money or attachment) then
            -- something was taken, so we're waiting for an event, and Continue() will be called again
            assert(self.messageID and not finished)
            return
        else
            assert(false) -- can't happen: if both are nil, then finished was true
        end

    elseif (self.section) then

        -- find highest-index message in my section, containing either money or attachments
        local messageID = nil
        local n, total = GetInboxNumItems()
        for messageID = n, 1, -1 do
            local ms, cod = Addon:SectionForMessage(messageID)
            cod = cod or 0
            if (ms == nil or ms == "System" or cod > 0) then
                -- skip it
            else
                assert(ms)
                assert(not (ms == "System"))
                assert(cod <= 0)

                -- does it match the target section?
                if (self.section == "*" or ms == self.section) then

                    local money, attachment, finished = self:do_loot_message(messageID)

                    -- if we took something, then we're waiting for some event to indicate that it has concluded (PLAYER_MONEY or BAG_UPDATE_DELAYED)
                    -- when that event fires, we'll come back here to look for a message in this section
                    -- the process ends when no more messages match the section
                    if (money or attachment) then
                        assert(self.section)
                        return
                    end
                    -- else we DID NOT take anything:  this message is ignored, the messageID loop continues, and we look for another message matching the section

                end -- if section matches
            end -- if not a System message
        end -- for each message

        -- if we get here, there are no messages in the target section
        -- so, we're done
        self:Finish()

    end
end

-- money, attachmentID, finished = Looter:do_loot_message(messageID)
-- non-nil money or attachmentID means something was looted (at most one of these will be non-nil)
-- finished will be true of there is nothing left to loot after this call (or before this call, in which case money and attachmentID will both be nil)
function Looter:do_loot_message(messageID)

    -- any money lootable?
    local money = select(5, GetInboxHeaderInfo(messageID))
    if (money and money == 0) then
        money = nil
    end

    -- any attachments?
    local attachmentID = nil
    local moreThanOne = false
    for a = 1, ATTACHMENTS_MAX_RECEIVE do
        if (HasInboxItem(messageID, a)) then
            if (attachmentID == nil) then
                attachmentID = a
            else
                moreThanOne = true
                break
            end
        end
    end

    -- take money first
    if (money) then
        assert(money > 0)

        -- looting money from mail doesn't automatically print anything, so we do
        local section = self.section or Addon:SectionForMessage(messageID)
        if (section and Addon.DB.chat[section]) then -- but only if config allows it
            local subject = select(4, GetInboxHeaderInfo(messageID))
            if (section == "Sales") then
                -- get some invoice info
                local _, itemName, otherPlayer, bid, buyout, _, _ = GetInboxInvoiceInfo(messageID);
                local itemLink = itemName and select(2, GetItemInfo(itemName))
                itemLink = itemLink or itemName
                if (otherPlayer == "") then
                    otherPlayer = nil
                end

                -- parse the itemCount from the subject
                local itemCount = string.match(subject, L[Strings.STACK_SIZE_PATTERN]) -- does it end with a stack size?

                if (itemCount) then
                    itemCount = tonumber(itemCount) -- force conversion to number

                else
                    itemCount = 1 -- no stack size, so assume quantity is 1
                end
                assert(itemCount and itemCount > 0)

                -- You receive 85g 49s 90c for [Arkhana]x10 at 8g 99s 99c each (SomeOtherPlayer)
                bid = bid or buyout
                local unitPrice = math.floor(bid / itemCount + 0.5)
                --[[
				local text = util.green("You receive ") .. util.white(util.gold_format(money))
				if (itemLink) then
					text = text .. util.green(" for ") .. itemLink .. util.green(itemCount>1 and ("x"..itemCount) or "")
					text = text .. util.green(" at ") .. util.white(util.gold_format(unitPrice,false)) .. util.green(itemCount>1 and " each" or "")
				end
				--]]
                local text
                if (itemLink) then
                    if (itemCount == 1) then
                        text = string.format(L[Strings.FMT_RECEIVE_MONEY_SINGLE_ITEM],
                            --											 util.white(util.gold_format(money)),
                            util.white(util.gold_format(unitPrice)) .. "|cFF00A800", itemLink, "")
                    else
                        text = string.format(L[Strings.FMT_RECEIVE_MONEY_MULTI_ITEM],
                            util.white(util.gold_format(money)), itemLink,
                            (itemCount > 1 and (" x" .. itemCount) or ""),
                            util.white(util.gold_format(unitPrice, false)))
                    end
                else
                    text = string.format(L[Strings.FMT_RECEIVE_MONEY], util.white(util.gold_format(money)))
                end
                if (otherPlayer) then
                    text = text .. util.green(" (" .. otherPlayer .. ")")
                end
                print(util.green(text))
            elseif (section) then
                local text = util.green("You receive ") .. util.gold_format(money)
                local sender = select(3, GetInboxHeaderInfo(messageID))
                if (sender) then
                    text = text .. util.green(" from " .. sender)
                end
                if (subject:find("^COD Payment: ")) then
                    text = text .. util.green(" (COD payment)")
                end
                print(util.green(text))
            end
        end

        Addon:debug("LOOTER-MONEY", "    message", messageID, "taking money:", util.gold_format(money))
        TakeInboxMoney(messageID)

        self:WaitFor("PLAYER_MONEY", function()
            Looter:Continue()
        end)
        return money, nil, (not attachmentID) -- (took the money), (did not take any attachment), (not done iff any attachment)
    end

    -- if we get here, there's no money
    assert(money == nil)

    -- try an attachment
    if (attachmentID) then
        if (has_free_space(1)) then
            -- want to modify "You receive item: [whatever]" messages
            self:FilterItemMessages({
                messageID = messageID,
                section = self.section
            })

            Addon:debug("LOOTER-ITEMS", "    message", messageID, "taking attachment", attachmentID)
            TakeInboxItem(messageID, attachmentID)

            -- when the item is fully taken, we deactivate our AddMessage hook and continue looting
            self:WaitFor("BAG_UPDATE_DELAYED", function()
                self:FilterItemMessages(nil);
                Looter:Continue()
            end)
            return nil, attachmentID, (not moreThanOne) -- (no money to take), (took an attachment), (not done iff more attachments)
        else
            self:Abort("Insufficent bag space")
            return nil, nil, true -- (no money to take), (did not take attachment), (we're done, cuz no room in bags for any attachments)
        end

        assert(false) -- can't get here
    end

    return nil, nil, true -- (no money to take), (no attachment to take), (we're done)
end

function Looter:WaitFor(event, action)

    Addon:debug("LOOTER-EVENTS", "looter waiting for", event)
    Looter:RegisterEvent(event)
    Looter[event] = function()
        Addon:debug("LOOTER-EVENTS", "looter got", event, "- continuing")
        Looter[event] = nil
        action()
    end
end

function Looter:FilterItemMessages(info)
    -- if we haven't already, hook the default AddMessage function
    if (not self.AddMessage_orig) then
        self.AddMessage_orig = DEFAULT_CHAT_FRAME.AddMessage
        -- DEFAULT_CHAT_FRAME.AddMessage = function (chatFrame, text, red, green, blue, messageId, holdTime) Looter:AddMessage(chatFrame, text, red, green, blue, messageId, holdTime) end
        DEFAULT_CHAT_FRAME.AddMessage = function(chatFrame, text, ...)
            Looter:AddMessage(chatFrame, text, ...)
        end
    end

    -- non-nil table means we want to tweak the message(s)... nil means don't
    assert(info == nil or type(info) == "table")
    self.AddMessage_info = info
end

function Looter:AddMessage(chatFrame, text, ...)
    local info = self.AddMessage_info

    -- should I be tweaking anything?
    if (info and info.messageID) then

        -- is this the chat message that I want to tweak?
        -- local received = string.match(text, Strings.RECEIVE_ITEM_PATTERN)
        -- self.AddMessage_orig(chatFrame, "text is '"..text.."'")
        -- self.AddMessage_orig(chatFrame, "format is '"..LOOT_ITEM_PUSHED_SELF.."'")
        -- self.AddMessage_orig(chatFrame, "pattern is '"..string.gsub(LOOT_ITEM_PUSHED_SELF,"%%s","(.+)").."'")
        local received = string.match(text, string.gsub(LOOT_ITEM_PUSHED_SELF, "%%s", "(.+)"))
        if (received == nil) then
            -- self.AddMessage_orig(chatFrame, "format is '"..LOOT_ITEM_PUSHED_SELF_MULTIPLE.."'")
            -- self.AddMessage_orig(chatFrame, "pattern is '"..string.gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE,"%%sx%%d","(.+)").."'")
            received = string.match(text, string.gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "%%sx%%d", "(.+)"))
        end
        -- self.AddMessage_orig(chatFrame, "capture is '"..(received or "(nil)").."'")
        if (received) then
            -- if last captured char is "." or "。" then strip it
            local last = received:sub(-1)
            if (last == "." or last == "。") then
                received = received:sub(0, -1)
            end
        end

        if (received) then

            -- does config allow modifying chat messages for this group?
            local section = info.section
            -- print("looting message in section "..(section or "(nil)"))
            if (section and Addon.DB.chat[section]) then

                -- the tweak depends on the group
                if (section == "Purchases") then

                    -- figure out item count from subject
                    local subject = select(4, GetInboxHeaderInfo(info.messageID))
                    local itemCount = string.match(subject, L[Strings.STACK_SIZE_PATTERN]) -- does it end with a stack size?
                    if (itemCount) then
                        itemCount = tonumber(itemCount) -- force conversion to number

                    else
                        itemCount = 1 -- no stack size, so assume quantity is 1
                    end
                    assert(itemCount and itemCount > 0)

                    -- need the bid
                    local _, _, otherPlayer, bid, buyout, _, _ = GetInboxInvoiceInfo(info.messageID);
                    if (bid == 0 and buyout > 0) then
                        bid = buyout
                    end
                    assert(bid and bid > 0)
                    if (otherPlayer == "") then
                        otherPlayer = nil
                    end

                    --[[
					if (otherPlayer) then
						text = string.format(Strings.FMT_PURCHASED_ITEM_FROM, received, util.white(util.gold_format(math.floor(bid/itemCount+0.5))), (itemCount>1 and " each" or ""), otherPlayer)
					else
						text = string.format(Strings.FMT_PURCHASED_ITEM, received, util.white(util.gold_format(math.floor(bid/itemCount+0.5))), (itemCount>1 and " each" or ""))
					end
					-- You purchased [whatever] for 10g 00s 00c
					-- You purchased [whatever]x200 for 2g 50s 00c each from SomeOtherPlayer
					--]]
                    text = string.format((itemCount == 1 and Strings.FMT_PURCHASED_SINGLE or
                                             Strings.FMT_PURCHASED_MULTIPLE), received,
                        util.white(util.gold_format(math.floor(bid / itemCount + 0.5))))
                    if (otherPlayer) then
                        text = text .. " (" .. otherPlayer .. ")"
                    end

                    -- and fall through to show it

                elseif (section == "Cancelled" or section == "Expired") then

                    -- tweak it
                    if (section == "Cancelled") then
                        text = string.format(Strings.FMT_CANCELLED_ITEM, received)
                    elseif (section == "Expired") then
                        text = string.format(Strings.FMT_EXPIRED_ITEM, received)
                    end
                    -- You receive cancelled item: [whatever]
                    -- and fall through to show it

                end
                -- else not in group Purchases, Cancelled or Expired

            end
            -- else config does not allow it

        end
        -- else not a "You receive item:" message

    end
    -- else not a chat message I should be tweaking

    -- call the original AddMessage to show the [possibly modified] text
    self.AddMessage_orig(chatFrame, text, ...)
end


--[[
    GrayAutoSell
    Revision: $Id$
    Version: 0.1.4 (3.3.5 compatible)
    By: Thomas T. Cremers <ttcremers@gmail.com> (original)
    Updated for WotLK 3.3.5 by Copilot

    This addon automatically sells poor (gray) items in your bags
    when you open a merchant window.

    License:
        GNU General Public License v2 or later
]]

-- Debugging toggle
local DEBUG = false
local SELL  = true

-- Pool of gray items in bag location ({bag, slot})
grayItemPool = {}

-- Frame for timed pool processing
local poolRunnerFrame = CreateFrame("Frame")

-- Delay between selling each item (seconds)
local sellDelay = 0.2

-- Debug helper
local function debug(text)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

-- Pool runner: sells items one by one with delay
local function poolRunner()
    debug("Pool runner started at: "..GetTime())
    local endTime = GetTime() + sellDelay

    poolRunnerFrame:SetScript("OnUpdate", function(self, elapsed)
        if (endTime < GetTime()) then
            local e = table.remove(grayItemPool)
            if e then
                debug("Processing, bag: "..e.bag.." slot: "..e.slot)
                if SELL then
                    UseContainerItem(e.bag, e.slot)
                else
                    debug("NOT SOLD, SELL=false")
                end
            else
                poolRunnerFrame:SetScript("OnUpdate", nil)
                debug("Pool runner finished at: "..GetTime())
            end
            endTime = GetTime() + sellDelay
        end
    end)
end

-- Initialization
function caInit(self)
    DEFAULT_CHAT_FRAME:AddMessage("Loading GrayAutoSell v0.1.4 'I supply only the finest goods!'")
    self:RegisterEvent("MERCHANT_SHOW")
end

-- Event handler
function caEvent(self, event, ...)
    if event == "MERCHANT_SHOW" then
        -- Scan all bags
        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local _, _, itemID = string.find(itemLink, "item:(%d+):")
                    if itemID then
                        local name, _, rarity = GetItemInfo(itemID)
                        if rarity == 0 then
                            debug("Poor item found: "..(name or "unknown"))
                            table.insert(grayItemPool, {bag = bag, slot = slot})
                        end
                    end
                end
            end
        end
        debug("Gray items found in bag: " .. #grayItemPool)
        poolRunner()
    end
end
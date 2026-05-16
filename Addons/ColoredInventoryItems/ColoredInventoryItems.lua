local addonName = 'ColoredInventoryItems';
local version = '1.4';
local addon = CreateFrame('Button', addonName);

local defaultSlotWidth, defaultSlotHeight = 68, 68;

-- 품질 상수 정의 (3.3.5a)
ITEM_QUALITY_POOR = 0
ITEM_QUALITY_COMMON = 1
ITEM_QUALITY_UNCOMMON = 2
ITEM_QUALITY_RARE = 3
ITEM_QUALITY_EPIC = 4
ITEM_QUALITY_LEGENDARY = 5
ITEM_QUALITY_ARTIFACT = 6
ITEM_QUALITY_HEIRLOOM = 7
ITEM_QUALITY_QUEST = 8 -- 커스텀

-- 품질 색상 테이블
BAG_ITEM_QUALITY_COLORS = {
    [ITEM_QUALITY_POOR]      = {r=.62, g=.62, b=.62},
    [ITEM_QUALITY_COMMON]    = {r=1, g=1, b=1},
    [ITEM_QUALITY_UNCOMMON]  = {r=.12, g=1, b=.0},
    [ITEM_QUALITY_RARE]      = {r=.0, g=.44, b=.87},
    [ITEM_QUALITY_EPIC]      = {r=.64, g=.21, b=.93},
    [ITEM_QUALITY_LEGENDARY] = {r=1, g=.5, b=.0},
    [ITEM_QUALITY_ARTIFACT]  = {r=.9, g=.8, b=.5},
    [ITEM_QUALITY_HEIRLOOM]  = {r=.0, g=.8, b=1},
    [ITEM_QUALITY_QUEST]     = {r=1, g=1, b=0},
}

ciiDefaultConfig = {
    ['bags'] = 1,
    ['bank'] = 1,
    ['char'] = 1,
    ['inspect'] = 1,
    ['merchant'] = 1,
    ['intensity'] = 0.49,
}

addon:RegisterEvent('VARIABLES_LOADED');
addon:RegisterEvent('ADDON_LOADED');
addon:RegisterEvent('PLAYER_ENTERING_WORLD');
addon:RegisterEvent('INSPECT_READY');
addon:RegisterEvent('BAG_UPDATE');
addon:RegisterEvent('BANKFRAME_OPENED');
addon:RegisterEvent('PLAYERBANKSLOTS_CHANGED');

addon:SetScript('OnEvent', function(self, event, arg1) self[event](self, arg1) end);

function addon:VARIABLES_LOADED()
    if (not ciiConfig) then
        ciiConfig = {}
    end
    for k, v in pairs(ciiDefaultConfig) do
        if (not ciiConfig[k]) then
            ciiConfig[k] = ciiDefaultConfig[k];
        end
    end
    for k, v in pairs(ciiConfig) do
        if (not ciiDefaultConfig[k]) then
            ciiConfig[k] = nil;
        end
    end
end

function addon:ADDON_LOADED(arg1)
    if (arg1 == addonName) then
        print('|cFFFFFF00ColoredInventoryItem v' .. version .. ':|cFFFFFFFF Type /cii for configuration');

        hooksecurefunc('ToggleCharacter', function() addon:characterFrame_OnToggle() end);
        hooksecurefunc('ToggleBackpack', function() addon:backpack_OnShow() end);
        hooksecurefunc('ToggleBag', function(id) addon:bag_OnToggle(id) end);
        hooksecurefunc('MerchantFrame_UpdateMerchantInfo', function() addon:merchant_OnUpdate() end);
        hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function() addon:buyback_OnUpdate() end);
    end

	if(arg1 == 'Blizzard_TradeSkillUI') then
        hooksecurefunc('TradeSkillFrame_SetSelection', function(id) addon:tradeskill_OnUpdate(id) end);
    end
end

function addon:PLAYER_ENTERING_WORLD() end

-- 캐릭터 프레임
function addon:characterFrame_OnToggle()
    if (CharacterFrame:IsShown()) then
        addon:characterFrame_OnShow();
    else    
        addon:characterFrame_OnHide();
    end
end

function addon:characterFrame_OnShow()
    addon:RegisterEvent("UNIT_INVENTORY_CHANGED");
    addon:charFrame_UpdateBorders('player', 'Character', ciiConfig.char);
end

function addon:characterFrame_OnHide()
	addon:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function addon:UNIT_INVENTORY_CHANGED()
    addon:charFrame_UpdateBorders('player', 'Character', ciiConfig.char);
end

function addon:BAG_UPDATE(arg1)
    addon:refreshBag(arg1);
end

function addon:INSPECT_READY()
    addon:charFrame_UpdateBorders('target', 'Inspect',  ciiConfig.inspect);
end

function addon:BANKFRAME_OPENED()
    addon:bankbags_UpdateBorders();
end

function addon:PLAYERBANKSLOTS_CHANGED()
    addon:bankbags_UpdateBorders();
end

function addon:backpack_OnShow()
    local containerFrame = _G['ContainerFrame1'];
    if (containerFrame.allBags == true) then
        addon:refreshAllBags()
    end
end

function addon:refreshAllBags()
    for bagId = 0, NUM_BAG_SLOTS do
        OpenBag(bagId);
        addon:refreshBag(bagId);
    end
end

function addon:bag_OnToggle(bagId)
    addon:refreshBag(bagId);
end

-- 가방 슬롯 업데이트
function addon:refreshBag(bagId)
    local frameId = IsBagOpen(bagId);
    if (frameId) then
        local nbSlots = GetContainerNumSlots(bagId);
        for slot = 1, nbSlots do
            local slotFrameId = nbSlots + 1 - slot;
            local slotFrameName = 'ContainerFrame' .. frameId .. 'Item' .. slotFrameId;
            addon:updateContainerSlot(bagId, slot, slotFrameName, ciiConfig.bags);
        end
    end
end

function addon:bankbags_UpdateBorders()
    local container = BANK_CONTAINER;
    for slot = 1, GetContainerNumSlots(container) do
        addon:updateContainerSlot(container, slot, 'BankFrameItem' .. slot, ciiConfig.bank);
    end
end

-- 컨테이너 슬롯 업데이트
function addon:updateContainerSlot(containerId, slotId, slotFrameName, show)
    local show = show or 1;
    local item = _G[slotFrameName];
    if (not item.qborder) then
        item.qborder = addon:createBorder(slotFrameName, item, defaultSlotWidth, defaultSlotHeight);
    end

    local link = GetContainerItemLink(containerId, slotId);
    if (link and show == 1) then
        local itemId = tonumber(string.match(link, "item:(%d+)"));
        local quality = GetItemQuality(itemId);
        if (quality and quality > ITEM_QUALITY_COMMON) then
            local r, g, b = GetQualityColor(quality);
            item.qborder:SetVertexColor(r, g, b);
            item.qborder:SetAlpha(ciiConfig.intensity);
            item.qborder:Show();
        else
            item.qborder:Hide();
        end
    else
        item.qborder:Hide();
    end
end

-- 캐릭터 슬롯 업데이트
local CharacterFrameSlotTypes = {
    'Head','Neck','Shoulder','Back','Chest','Shirt','Tabard','Wrist','Hands','Waist','Legs','Feet',
    'Finger0','Finger1','Trinket0','Trinket1','MainHand','SecondaryHand','Ranged','Ammo',
};

function addon:charFrame_UpdateBorders(unit, frameType, show)
    local show = show or 1;
    for _, charSlot in ipairs(CharacterFrameSlotTypes) do
        local id = GetInventorySlotInfo(charSlot .. 'Slot');
        local quality = GetInventoryItemQuality(unit, id);
        local slotName = frameType .. charSlot .. 'Slot';
        if (_G[slotName]) then
            local slot = _G[slotName];
            if (not slot.qborder) then
                local height, width = defaultSlotHeight, defaultSlotWidth;
                if charSlot == 'Ammo' then height, width = 58, 58 end
                slot.qborder = addon:createBorder(slotName, slot, width, height);
            end
            if (quality and show == 1) then
                local r, g, b = GetQualityColor(quality);
                slot.qborder:SetVertexColor(r, g, b);
                slot.qborder:SetAlpha(ciiConfig.intensity);
                slot.qborder:Show();
            else
                slot.qborder:Hide();
            end
        end
    end
end

-- 상인 관련
function addon:merchant_OnUpdate()
    addon:merchantItems_Update(GetMerchantItemLink);
    addon:merchantMainBuyBack_Update();
end

function addon:buyback_OnUpdate()
    addon:merchantItems_Update(GetBuybackItemLink);
end

function addon:merchantItems_Update(itemLinkFunc)
    for slotId = 1, 12 do
        local slotName = 'MerchantItem' .. slotId .. 'ItemButton';
        local itemFrame = _G[slotName];

        if (not itemFrame.qborder) then
            itemFrame.qborder = addon:createBorder(slotName, itemFrame, defaultSlotWidth, defaultSlotHeight);
        end

        local link = itemLinkFunc(slotId);
        if (link) then
            addon:updateSlotBorderColor(itemFrame, link, ITEM_QUALITY_COMMON);
        else
            itemFrame.qborder:Hide();
        end
    end
end

function addon:merchantMainBuyBack_Update()
    local buybackSlotName = 'MerchantBuyBackItemItemButton';
    local item = _G[buybackSlotName];

    if (not item.qborder) then
        item.qborder = addon:createBorder(buybackSlotName, item, defaultSlotWidth, defaultSlotHeight);
    end

    local lastLink = FindLastBuybackItem();
    if (lastLink) then
        addon:updateSlotBorderColor(item, lastLink, ITEM_QUALITY_COMMON);
    else
        item.qborder:Hide();
    end
end

function addon:updateSlotBorderColor(item, link, minQuality)
    local minQuality = minQuality or ITEM_QUALITY_POOR;
    local itemId = tonumber(string.match(link, "item:(%d+)"));
    local itemQuality = GetItemQuality(itemId);

    if (itemQuality and itemQuality > minQuality) then
        local r, g, b = GetQualityColor(itemQuality);
        item.qborder:SetVertexColor(r, g, b);
        item.qborder:SetAlpha(ciiConfig.intensity);
        item.qborder:Show();
    else
        item.qborder:Hide();
    end
end

function FindLastBuybackItem()
    local lastLink = nil;
    for slotId = 1, 12 do
        local link = GetBuybackItemLink(slotId);
        if (link) then lastLink = link; end
    end
    return lastLink;
end

-- 제작/재료 테두리
function addon:tradeskill_OnUpdate(id)
    addon:updateTradeSkillItem(id);
    addon:updateTradeSkillReagent(id);
end

function addon:updateTradeSkillItem(id)
    local slotName = 'TradeSkillSkillIcon';
    local item = _G[slotName];

    if (not item.qborder) then
        item.qborder = addon:createBorder(slotName, item, defaultSlotWidth, defaultSlotHeight);
    end

    local link = GetTradeSkillItemLink(id);
    if (link) then
        addon:updateSlotBorderColor(item, link, ITEM_QUALITY_COMMON);
    else
        item.qborder:Hide();
    end
end

function addon:updateTradeSkillReagent(id)
    local nb = GetTradeSkillNumReagents(id);
    for index = 1, nb do
        local slotName = 'TradeSkillReagent' .. index;
        local item = _G[slotName];
        
        if (not item.qborder) then
            item.qborder = addon:createBorder(slotName, item, defaultSlotWidth, defaultSlotHeight, -54);
        end

        local link = GetTradeSkillReagentItemLink(id, index);
        if (link) then
            addon:updateSlotBorderColor(item, link, ITEM_QUALITY_COMMON);
        else
            item.qborder:Hide();
        end
    end
end

-- 테두리 생성
function addon:createBorder(name, parent, width, height, x, y)
    local x = x or 0;
    local y = y or 1;

    local border = parent:CreateTexture(name .. 'Quality', 'OVERLAY');
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    border:SetBlendMode('ADD');
    border:SetAlpha(ciiConfig.intensity);
    border:SetHeight(height);
    border:SetWidth(width);
    border:SetPoint('CENTER', parent, 'CENTER', x, y);
    border:Hide();

    return border;
end

-- 품질 색상
function GetQualityColor(quality)
    local q = BAG_ITEM_QUALITY_COLORS[quality];
    return q.r, q.g, q.b;
end

-- 품질 판별 (퀘스트 포함)
function GetItemQuality(itemId)
    local _, _, quality, _, _, itemType = GetItemInfo(itemId);
    if (itemType == "Quest") then
        quality = ITEM_QUALITY_QUEST;
    end
    return quality;
end

-- Slash 명령어
SLASH_CII1 = "/cii"
SlashCmdList["CII"] = function(msg)
    msg = string.lower(msg);
    local _, _, cmd, args = string.find(msg, '%s?(%w+)%s?(.*)')

    if (cmd == 'help' or not cmd) then
        addon:printHelp();
    elseif (cmd == 'bags') then
        ciiConfig.bags = 1 - ciiConfig.bags
        addon:printStatus('Bags', ciiConfig.bags);
    elseif (cmd == 'bank') then
        ciiConfig.bank = 1 - ciiConfig.bank
        addon:printStatus('Bank', ciiConfig.bank);
    elseif (cmd == 'char') then
        ciiConfig.char = 1 - ciiConfig.char
        addon:printStatus('Character', ciiConfig.char);
    elseif (cmd == 'inspect') then
        ciiConfig.inspect = 1 - ciiConfig.inspect
        addon:printStatus('Inspect', ciiConfig.inspect);
    elseif (cmd == 'merchant') then
        ciiConfig.merchant = 1 - ciiConfig.merchant
        addon:printStatus('Merchant', ciiConfig.merchant);
    elseif (cmd == 'intensity' or cmd == 'int') then
        if (not args or args == '') then
            print('Current intensity : ' .. ciiConfig.intensity)
        else
            local value = tonumber(args);
            if (value ~= nil) then
                if (value > 1) then value = 1 end
                if (value < .1) then value = .1 end
                ciiConfig.intensity = value;
            else
                print('Value is not a number');
            end
        end
    end
end

function addon:printStatus(element, status)
    local statustext = (status == 0) and 'hidden' or 'shown';
    print(element .. ' item borders are ' .. statustext)
end

function addon:printHelp()
    print('===== ColorInventoryItems v' .. version .. ' usage:');
    print('/cii help    : this help message');
    print('/cii bags    : toggle item border display in bags. (current = '.. ciiConfig.bags ..')');
    print('/cii bank    : toggle item border display in bank. (current = '.. ciiConfig.bank ..')');
    print('/cii char    : toggle item border display in character frame. (current = '.. ciiConfig.char ..')');
    print('/cii inspect : toggle item border display in inspect frame. (current = '.. ciiConfig.inspect ..')');
    print('/cii merchant : toggle item border display in merchant frame. (current = '.. ciiConfig.merchant ..')');
    print('/cii intensity VALUE or /cii int VALUE :');
    print('        Define border intensity (float VALUE between 0 and 1).')
    print('        default = 0.49, current = ' ..  ciiConfig.intensity);
end

XLGB_Inventory = {}

local XLGB = XLGB_Constants

function XLGB_Inventory:GetEquippedItems()
  local equippedItems = {}
  -- for _, slot in pairs(XLGB_Inventory.validEquippedSlots) do
  local bag = BAG_WORN
  local slot = ZO_GetNextBagSlotIndex(bag)
  while slot do
      local itemLink = GetItemLink(bag, slot)
      if itemLink and itemLink ~= "" then
        local itemID = Id64ToString(GetItemUniqueId(bag, slot))
        local itemData = XLGB_GearSet:CreateItemData(itemLink, itemID)
        table.insert(equippedItems, itemData)
      end
      slot = ZO_GetNextBagSlotIndex(bag, slot)
  end
  return equippedItems
end

function XLGB_Inventory:GetBankBags()
  local bags = {}
  local currentBag = XLGB_Banking and XLGB_Banking.currentBankBag
  if currentBag and currentBag ~= XLGB_Constants.NO_BAG and currentBag ~= BAG_BANK and currentBag ~= BAG_SUBSCRIBER_BANK then
    table.insert(bags, currentBag)
  else
    table.insert(bags, BAG_BANK)
    if IsESOPlusSubscriber() or (GetBagSize(BAG_SUBSCRIBER_BANK) or 0) > 0 then
      table.insert(bags, BAG_SUBSCRIBER_BANK)
    end
  end
  return bags
end

function XLGB_Inventory:GetItemSetInfo(itemLink)
  if not itemLink or itemLink == "" then
    return false, nil, nil
  end
  if LibSets and LibSets.IsSetByItemLink then
    local isSet, setName, setId = LibSets.IsSetByItemLink(itemLink)
    if isSet then
      return true, setName, setId
    end
  end
  local hasSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
  if hasSet and setName and setName ~= "" then
    return true, setName, setId
  end
  return false, nil, nil
end

function XLGB_Inventory:GetCharacterBags()
  return { BAG_BACKPACK, BAG_WORN }
end

function XLGB_Inventory:ForEachItemInBags(bags, callback)
  for _, bag in ipairs(bags) do
    if bag == BAG_WORN then
      local slot = ZO_GetNextBagSlotIndex(bag)
      while slot do
        local itemLink = GetItemLink(bag, slot)
        if itemLink and itemLink ~= "" then
          callback(bag, slot, itemLink)
        end
        slot = ZO_GetNextBagSlotIndex(bag, slot)
      end
    else
      local bagSize = GetBagSize(bag)
      for slot = 0, bagSize - 1 do
        local itemLink = GetItemLink(bag, slot)
        if itemLink and itemLink ~= "" then
          callback(bag, slot, itemLink)
        end
      end
    end
  end
end

function XLGB_Inventory:GetSetsInBags(bags)
  local setsMap = {}
  local setsList = {}

  XLGB_Inventory:ForEachItemInBags(bags, function(bag, slot, itemLink)
    local isSet, setName, setId = XLGB_Inventory:GetItemSetInfo(itemLink)
    if isSet and setName and setName ~= "" then
      local itemID = Id64ToString(GetItemUniqueId(bag, slot))
      if not itemID or itemID == "" or itemID == "0" then
        itemID = itemLink
      end

      local key = setId or setName
      if not setsMap[key] then
        local entry = {
          key = key,
          setId = setId,
          setName = setName,
          items = {},
          itemIdsSet = {}
        }
        setsMap[key] = entry
        table.insert(setsList, entry)
      end

      local entry = setsMap[key]
      if not entry.itemIdsSet[itemID] then
        entry.itemIdsSet[itemID] = true
        table.insert(entry.items, {
          link = itemLink,
          ID = itemID,
          bag = bag,
          slot = slot
        })
      end
    end
  end)

  table.sort(setsList, function(a, b)
    return a.setName < b.setName
  end)

  return setsList, setsMap
end

function XLGB_Inventory:GetSetsInBank()
  return XLGB_Inventory:GetSetsInBags(XLGB_Inventory:GetBankBags())
end

function XLGB_Inventory:GetSetsInInventory()
  return XLGB_Inventory:GetSetsInBags(XLGB_Inventory:GetCharacterBags())
end

function XLGB_Inventory:GetItemsForSetInBags(bags, targetSetId, targetSetName)
  local items = {}
  local seenItemIds = {}

  XLGB_Inventory:ForEachItemInBags(bags, function(bag, slot, itemLink)
    local isSet, setName, setId = XLGB_Inventory:GetItemSetInfo(itemLink)
    local match = false
    if isSet then
      if targetSetId and setId and targetSetId == setId then
        match = true
      elseif targetSetName and setName and targetSetName == setName then
        match = true
      end
    end
    if match then
      local itemID = Id64ToString(GetItemUniqueId(bag, slot))
      if not itemID or itemID == "" or itemID == "0" then
        itemID = itemLink
      end
      if not seenItemIds[itemID] then
        seenItemIds[itemID] = true
        table.insert(items, {
          link = itemLink,
          ID = itemID,
          bag = bag,
          slot = slot
        })
      end
    end
  end)

  return items
end

function XLGB_Inventory:GetBankItemsForSet(targetSetId, targetSetName)
  return XLGB_Inventory:GetItemsForSetInBags(XLGB_Inventory:GetBankBags(), targetSetId, targetSetName)
end

function XLGB_Inventory:GetInventoryItemsForSet(targetSetId, targetSetName)
  return XLGB_Inventory:GetItemsForSetInBags(XLGB_Inventory:GetCharacterBags(), targetSetId, targetSetName)
end

function XLGB_Inventory:GetAllAvailableSets()
  local invSetsList, invSetsMap = XLGB_Inventory:GetSetsInInventory()
  local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)

  if not isBankOpen then
    local result = {}
    for _, invEntry in ipairs(invSetsList) do
      table.insert(result, {
        key = invEntry.key,
        setId = invEntry.setId,
        setName = invEntry.setName,
        items = invEntry.items,
        invItems = invEntry.items,
        bankItems = {},
        source = "bag",
        totalCount = #invEntry.items,
        dropdownLabel = string.format("|t18:18:/esoui/art/tooltips/icon_bag.dds|t %s (%d)", invEntry.setName, #invEntry.items),
      })
    end
    return result
  end

  local bankSetsList, bankSetsMap = XLGB_Inventory:GetSetsInBank()
  local mergedMap = {}
  local allKeys = {}

  for _, invEntry in ipairs(invSetsList) do
    local key = invEntry.key
    if not mergedMap[key] then
      mergedMap[key] = {
        key = key,
        setId = invEntry.setId,
        setName = invEntry.setName,
        invItems = invEntry.items,
        bankItems = {},
      }
      table.insert(allKeys, key)
    else
      mergedMap[key].invItems = invEntry.items
    end
  end

  for _, bankEntry in ipairs(bankSetsList) do
    local key = bankEntry.key
    if not mergedMap[key] then
      mergedMap[key] = {
        key = key,
        setId = bankEntry.setId,
        setName = bankEntry.setName,
        invItems = {},
        bankItems = bankEntry.items,
      }
      table.insert(allKeys, key)
    else
      mergedMap[key].bankItems = bankEntry.items
    end
  end

  local result = {}
  for _, key in ipairs(allKeys) do
    local data = mergedMap[key]
    local numInv = #data.invItems
    local numBank = #data.bankItems

    if numInv > 0 and numBank > 0 then
      local allItems = {}
      local seen = {}
      for _, item in ipairs(data.invItems) do
        if not seen[item.ID] then
          seen[item.ID] = true
          table.insert(allItems, item)
        end
      end
      for _, item in ipairs(data.bankItems) do
        if not seen[item.ID] then
          seen[item.ID] = true
          table.insert(allItems, item)
        end
      end

      -- Combined entry [Tout]
      table.insert(result, {
        key = key,
        setId = data.setId,
        setName = data.setName,
        items = allItems,
        invItems = data.invItems,
        bankItems = data.bankItems,
        source = "both",
        totalCount = #allItems,
        sortOrder = 1,
        dropdownLabel = string.format("|t18:18:/esoui/art/icons/icon_bank.dds|t|t18:18:/esoui/art/tooltips/icon_bag.dds|t %s %s (%d - %d %s, %d %s)", XLGB_GetString("SET_SOURCE_ALL"), data.setName, #allItems, numBank, XLGB_GetString("SET_SOURCE_BANK_LABEL"), numInv, XLGB_GetString("SET_SOURCE_BAG_LABEL")),
      })

      -- Inventory entry [Sac]
      table.insert(result, {
        key = key,
        setId = data.setId,
        setName = data.setName,
        items = data.invItems,
        invItems = data.invItems,
        bankItems = {},
        source = "bag",
        totalCount = numInv,
        sortOrder = 2,
        dropdownLabel = string.format("|t18:18:/esoui/art/tooltips/icon_bag.dds|t %s %s (%d)", XLGB_GetString("SET_SOURCE_BAG"), data.setName, numInv),
      })

      -- Bank entry [Banque]
      table.insert(result, {
        key = key,
        setId = data.setId,
        setName = data.setName,
        items = data.bankItems,
        invItems = {},
        bankItems = data.bankItems,
        source = "bank",
        totalCount = numBank,
        sortOrder = 3,
        dropdownLabel = string.format("|t18:18:/esoui/art/icons/icon_bank.dds|t %s %s (%d)", XLGB_GetString("SET_SOURCE_BANK"), data.setName, numBank),
      })
    elseif numInv > 0 then
      table.insert(result, {
        key = key,
        setId = data.setId,
        setName = data.setName,
        items = data.invItems,
        invItems = data.invItems,
        bankItems = {},
        source = "bag",
        totalCount = numInv,
        sortOrder = 1,
        dropdownLabel = string.format("|t18:18:/esoui/art/tooltips/icon_bag.dds|t %s %s (%d)", XLGB_GetString("SET_SOURCE_BAG"), data.setName, numInv),
      })
    elseif numBank > 0 then
      table.insert(result, {
        key = key,
        setId = data.setId,
        setName = data.setName,
        items = data.bankItems,
        invItems = {},
        bankItems = data.bankItems,
        source = "bank",
        totalCount = numBank,
        sortOrder = 1,
        dropdownLabel = string.format("|t18:18:/esoui/art/icons/icon_bank.dds|t %s %s (%d)", XLGB_GetString("SET_SOURCE_BANK"), data.setName, numBank),
      })
    end
  end

  table.sort(result, function(a, b)
    if a.setName == b.setName then
      return (a.sortOrder or 1) < (b.sortOrder or 1)
    end
    return a.setName < b.setName
  end)

  return result
end

function XLGB_Inventory:Initialize()
end
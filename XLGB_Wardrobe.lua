--[[
  XLGB_Wardrobe.lua

  Module providing seamless integration between XLGearBanker and Wizard's Wardrobe (WW).
  Allows selecting any character, zone, and page from Wizard's Wardrobe,
  viewing the sets and pieces with their current location (Equipped, Bag, Bank, Missing),
  depositing the surplus equipment (the difference) from backpack into the bank,
  withdrawing page gear from the bank, 1-click inventory preparation, and importing into XLGB.
]]--

XLGB_Wardrobe = {}
local WWB = XLGB_Wardrobe

local DEFAULT_ZONE_NAMES = {
  GEN = "General",
  SUB = "Substitutes",
  PVP = "PvP",
  AA = "Aetherian Archive",
  HRC = "Hel Ra Citadel",
  SO = "Sanctum Ophidia",
  MOL = "Maw of Lorkhaj",
  HOF = "Halls of Fabrication",
  AS = "Asylum Sanctorium",
  CR = "Cloudrest",
  SS = "Sunspire",
  KA = "Kyne's Aegis",
  RG = "Rockgrove",
  DSR = "Dreadsail Reef",
  SE = "Sanity's Edge",
  LC = "Lucent Citadel",
  IA = "Infinite Archive",
  EA = "Endless Archive",
  BRP = "Blackrose Prison",
  DSA = "Dragonstar Arena",
  MA = "Maelstrom Arena",
  VH = "Vateshran Hollows",
  OC = "Orsinium / Other",
}

local function getFallbackZoneName(tag)
  if tag == "GEN" then
    return (XLGB_GetString and XLGB_GetString("WW_ZONE_GENERAL")) or "General"
  elseif tag == "SUB" then
    return (XLGB_GetString and XLGB_GetString("WW_ZONE_SUBSTITUTES")) or "Substitutes"
  elseif tag == "OC" then
    return "Orsinium / " .. ((XLGB_GetString and XLGB_GetString("WW_ZONE_OTHER")) or "Other")
  end
  return DEFAULT_ZONE_NAMES[tag] or tag
end

local DEFAULT_TRIAL_TAGS = {
  AA = true, HRC = true, SO = true, MOL = true, HOF = true,
  AS = true, CR = true, SS = true, KA = true, RG = true,
  DSR = true, SE = true, LC = true,
}

local DEFAULT_ARENA_TAGS = {
  BRP = true, DSA = true, MA = true, VH = true, IA = true, EA = true,
}

local ALWAYS_AVAILABLE_ZONES = {
  "GEN",
  "AA", "HRC", "SO", "MOL", "HOF", "AS", "CR", "SS", "KA", "RG", "DSR", "SE", "LC",
  "BRP", "DSA", "MA", "VH", "IA",
  "SUB", "PVP",
}

function WWB:Initialize()
  self.selectedCharId = nil
  self.selectedZoneTag = nil
  self.selectedPageId = nil
  self.activeTab = 1 -- 1 = Needed Gear, 2 = Surplus (Difference)
end

function WWB:GetWWSavedVariables()
  if WizardsWardrobeSV and WizardsWardrobeSV.Default and WizardsWardrobeSV.Default[GetDisplayName()] then
    return WizardsWardrobeSV.Default[GetDisplayName()]
  end
  return nil
end

function WWB:IsWWAvailable()
  local sv = self:GetWWSavedVariables()
  return sv ~= nil
end

-- Resolves actual character storage, handling linked characters and $AccountWide in Wizard's Wardrobe
function WWB:GetCharacterStorage(characterId)
  local wwData = self:GetWWSavedVariables()
  if not wwData or not characterId then return nil, nil end

  local charKey = tostring(characterId)
  local currentCharId = nil
  if GetCurrentCharacterId then
    currentCharId = tostring(Id64ToString(GetCurrentCharacterId()))
  end

  local isCurrent = (currentCharId and charKey == currentCharId) or
                    (WizardsWardrobe and WizardsWardrobe.currentCharacterId and charKey == tostring(WizardsWardrobe.currentCharacterId))

  if isCurrent and WizardsWardrobe and WizardsWardrobe.storage then
    return WizardsWardrobe.storage, WizardsWardrobe.storage
  end

  local charData = wwData[charKey] or wwData[characterId] or wwData[tonumber(characterId)]
  if not charData then return nil, nil end

  -- Resolve $AccountWide if applicable (do not cross-redirect individual characters)
  local selCharId = charData.selectedCharacterId
  if selCharId and selCharId == "$AccountWide" then
    if wwData["$AccountWide"] and wwData["$AccountWide"].accountWideStorage then
      return wwData["$AccountWide"].accountWideStorage, charData
    end
  end

  return charData, charData
end

function WWB:GetCharacters()
  local wwData = self:GetWWSavedVariables()
  if not wwData then return {} end

  local chars = {}
  local currentPlayerName = zo_strformat("<<1>>", GetUnitName("player"))
  local currentCharId = nil
  if GetCurrentCharacterId then
    currentCharId = tostring(Id64ToString(GetCurrentCharacterId()))
  end

  local accountCharMap = {}
  local numChars = GetNumCharacters and GetNumCharacters() or 0
  for i = 1, numChars do
    local name, _, _, _, _, _, id = GetCharacterInfo(i)
    local idStr = tostring(Id64ToString(id))
    accountCharMap[idStr] = zo_strformat("<<1>>", name)
  end

  for charKey, charData in pairs(wwData) do
    if charKey ~= "$AccountWide" and type(charData) == "table" then
      local charIdStr = tostring(charKey)
      local name = accountCharMap[charIdStr]
      if not name and charData["$LastCharacterName"] then
        name = zo_strformat("<<1>>", charData["$LastCharacterName"])
      end
      if not name or name == "" then
        name = XLGB_GetString("WW_CHAR") .. " " .. charIdStr
      end

      local storage = self:GetCharacterStorage(charKey)
      local setupCount = 0
      if storage and storage.setups then
        for _, zoneSetups in pairs(storage.setups) do
          for _, pageSetups in pairs(zoneSetups) do
            if type(pageSetups) == "table" then
              setupCount = setupCount + #pageSetups
            end
          end
        end
      end

      local isCurrent = false
      if currentCharId and charIdStr == currentCharId then
        isCurrent = true
      elseif WizardsWardrobe and WizardsWardrobe.currentCharacterId and charIdStr == tostring(WizardsWardrobe.currentCharacterId) then
        isCurrent = true
      elseif name == currentPlayerName then
        isCurrent = true
      end

      -- Resolve lastZoneTag:
      -- Check active WW selection, WW in-memory storage, active character's SavedVariables, or charData
      local lastZoneTag = nil
      local WW = WizardsWardrobe
      if isCurrent and WW and WW.selection and WW.selection.zone and WW.selection.zone.tag then
        lastZoneTag = WW.selection.zone.tag
      end
      if (not lastZoneTag or lastZoneTag == "") and WW and WW.storage and WW.storage.selectedZoneTag then
        lastZoneTag = WW.storage.selectedZoneTag[charKey] or WW.storage.selectedZoneTag[charIdStr] or WW.storage.selectedZoneTag[tonumber(charKey)]
      end
      if (not lastZoneTag or lastZoneTag == "") and currentCharId and wwData[currentCharId] and wwData[currentCharId].selectedZoneTag then
        lastZoneTag = wwData[currentCharId].selectedZoneTag[charKey] or wwData[currentCharId].selectedZoneTag[charIdStr] or wwData[currentCharId].selectedZoneTag[tonumber(charKey)]
      end
      if (not lastZoneTag or lastZoneTag == "") and charData.selectedZoneTag then
        lastZoneTag = charData.selectedZoneTag[charKey] or charData.selectedZoneTag[charIdStr] or charData.selectedZoneTag[tonumber(charKey)]
      end
      if not lastZoneTag or lastZoneTag == "" then
        lastZoneTag = "GEN"
      end

      table.insert(chars, {
        id = charKey,
        idStr = charIdStr,
        name = name,
        setupCount = setupCount,
        isCurrent = isCurrent,
        lastZoneTag = lastZoneTag,
      })
    end
  end

  table.sort(chars, function(a, b)
    if a.isCurrent ~= b.isCurrent then
      return a.isCurrent
    end
    return a.name < b.name
  end)

  return chars
end

function WWB:GetCharacterName(characterId)
  local charKey = tostring(characterId)
  local numChars = GetNumCharacters and GetNumCharacters() or 0
  for i = 1, numChars do
    local name, _, _, _, _, _, id = GetCharacterInfo(i)
    if tostring(Id64ToString(id)) == charKey then
      return zo_strformat("<<1>>", name)
    end
  end

  local wwData = self:GetWWSavedVariables()
  if wwData then
    local charData = wwData[charKey] or wwData[characterId] or wwData[tonumber(characterId)]
    if charData and charData["$LastCharacterName"] then
      return zo_strformat("<<1>>", charData["$LastCharacterName"])
    end
  end

  local currentPlayerName = zo_strformat("<<1>>", GetUnitName("player"))
  if GetCurrentCharacterId and tostring(Id64ToString(GetCurrentCharacterId())) == charKey then
    return currentPlayerName
  end

  return XLGB_GetString("WW_CHAR") .. " " .. charKey
end

function WWB:GetZones(characterId)
  local storage, charData = self:GetCharacterStorage(characterId)

  local zones = {}
  local seenZones = {}

  local function addZone(tag)
    if not tag or tag == "" or seenZones[tag] then return end
    seenZones[tag] = true

    local name = nil
    local icon = nil
    local category = 99
    local priority = 99

    local WW = WizardsWardrobe
    if WW and WW.zones and WW.zones[tag] then
      local z = WW.zones[tag]
      name = z.name
      icon = z.icon
      category = z.category or 99
      priority = z.priority or 99
    end
    if not name or name == "" then
      name = getFallbackZoneName(tag)
    end
    if not icon or icon == "" then
      icon = "/esoui/art/icons/achievement_u26_skyrim_trial_flavor_2.dds"
    end
    if category == 99 then
      if tag == "GEN" then
        category = 1
      elseif DEFAULT_TRIAL_TAGS[tag] then
        category = 2
      elseif DEFAULT_ARENA_TAGS[tag] then
        category = 5
      else
        category = 10
      end
    end

    local setupCount = 0
    if storage and storage.setups and storage.setups[tag] then
      for pageId, pageSetups in pairs(storage.setups[tag]) do
        if type(pageSetups) == "table" then
          for _, setup in ipairs(pageSetups) do
            if setup and (setup.gear or setup.name) then
              setupCount = setupCount + 1
            end
          end
        end
      end
    end

    table.insert(zones, {
      tag = tag,
      name = name,
      icon = icon,
      category = category,
      priority = priority,
      setupCount = setupCount,
    })
  end

  -- 1. Always add standard Zones / Raids (General, all 13 Trials, Arenas, etc.)
  for _, tag in ipairs(ALWAYS_AVAILABLE_ZONES) do
    addZone(tag)
  end

  -- 2. Also add any registered Trials / Arenas from WizardsWardrobe.zones if available
  local WW = WizardsWardrobe
  if WW and WW.zones then
    for tag, z in pairs(WW.zones) do
      if z and (z.category == (WW.ACTIVITIES and WW.ACTIVITIES.TRIALS) or
                z.category == (WW.ACTIVITIES and WW.ACTIVITIES.ARENAS) or
                z.category == (WW.ACTIVITIES and WW.ACTIVITIES.GENERAL)) then
        addZone(tag)
      end
    end
  end

  -- 3. Add any other zones where this character has setups or pages (e.g. dungeons)
  if storage then
    if storage.setups then
      for tag, pages in pairs(storage.setups) do
        if type(pages) == "table" and next(pages) ~= nil then
          addZone(tag)
        end
      end
    end

    if storage.pages then
      for tag, pages in pairs(storage.pages) do
        if type(pages) == "table" then
          addZone(tag)
        end
      end
    end
  end

  -- Sort: Category first (General -> Trials -> Arenas -> Dungeons/Misc), then Priority/Name
  table.sort(zones, function(a, b)
    if a.category ~= b.category then
      return a.category < b.category
    end
    if a.priority ~= b.priority then
      return a.priority < b.priority
    end
    return a.name < b.name
  end)

  return zones
end

function WWB:GetPages(characterId, zoneTag)
  local storage = self:GetCharacterStorage(characterId)
  if not storage or not zoneTag then return { { id = 1, name = "Page 1" } }, 1 end

  local pages = {}
  local seenPageIds = {}
  local activePageId = 1
  local charKey = tostring(characterId)

  if storage.pages and storage.pages[zoneTag] then
    if storage.pages[zoneTag][0] then
      activePageId = storage.pages[zoneTag][0][charKey] or storage.pages[zoneTag][0][tonumber(characterId)] or 1
    end
    for pageId, pageInfo in pairs(storage.pages[zoneTag]) do
      if pageId ~= 0 and type(pageId) == "number" then
        seenPageIds[pageId] = true
        local name = (pageInfo and pageInfo.name and pageInfo.name ~= "") and pageInfo.name or ("Page " .. tostring(pageId))
        table.insert(pages, {
          id = pageId,
          name = name,
        })
      end
    end
  end

  if storage.setups and storage.setups[zoneTag] then
    for pageId, setups in pairs(storage.setups[zoneTag]) do
      if type(pageId) == "number" and not seenPageIds[pageId] then
        seenPageIds[pageId] = true
        table.insert(pages, {
          id = pageId,
          name = "Page " .. tostring(pageId),
        })
      end
    end
  end

  if #pages == 0 then
    table.insert(pages, { id = 1, name = "Page 1" })
  end

  table.sort(pages, function(a, b)
    return a.id < b.id
  end)

  return pages, activePageId
end

function WWB:GetPageGear(characterId, zoneTag, pageId)
  local storage = self:GetCharacterStorage(characterId)
  if not storage or not zoneTag or not pageId then
    return {}, {}, { total = 0, worn = 0, bag = 0, bank = 0, missing = 0 }
  end

  local neededGearMap = {}
  local pageNum = tonumber(pageId) or 1
  local pageSetups = storage.setups and storage.setups[zoneTag] and (storage.setups[zoneTag][pageId] or (pageNum and storage.setups[zoneTag][pageNum]))

  if pageSetups then
    for setupIdx, setup in ipairs(pageSetups) do
      if setup and setup.gear then
        local setupName = setup.name or ("Setup " .. setupIdx)
        for slotIdx, gear in pairs(setup.gear) do
          if type(gear) == "table" and gear.id and gear.id ~= "" and gear.id ~= "0" then
            local uid = tostring(gear.id)
            if not neededGearMap[uid] then
              neededGearMap[uid] = {
                id = uid,
                link = gear.link or "",
                setups = { setupName },
                slotIndex = slotIdx,
              }
            else
              local alreadyIn = false
              for _, sn in ipairs(neededGearMap[uid].setups) do
                if sn == setupName then alreadyIn = true break end
              end
              if not alreadyIn then
                table.insert(neededGearMap[uid].setups, setupName)
              end
            end
          end
        end
      end
    end
  end

  local stats = { total = 0, worn = 0, bag = 0, bank = 0, missing = 0 }

  -- 1. Scan BAG_WORN
  local wornSize = GetBagSize(BAG_WORN)
  for slot = 0, wornSize - 1 do
    local currentLink = GetItemLink(BAG_WORN, slot)
    if currentLink and currentLink ~= "" then
      local uid = (XLGB_Inventory and XLGB_Inventory.GetSlotUid and XLGB_Inventory:GetSlotUid(BAG_WORN, slot)) or Id64ToString(GetItemUniqueId(BAG_WORN, slot))
      if neededGearMap[uid] then
        neededGearMap[uid].location = "WORN"
        neededGearMap[uid].bag = BAG_WORN
        neededGearMap[uid].slot = slot
        neededGearMap[uid].link = currentLink
      end
    end
  end

  -- 2. Scan BAG_BACKPACK
  local bagSize = GetBagSize(BAG_BACKPACK)
  for slot = 0, bagSize - 1 do
    local currentLink = GetItemLink(BAG_BACKPACK, slot)
    if currentLink and currentLink ~= "" then
      local uid = (XLGB_Inventory and XLGB_Inventory.GetSlotUid and XLGB_Inventory:GetSlotUid(BAG_BACKPACK, slot)) or Id64ToString(GetItemUniqueId(BAG_BACKPACK, slot))
      if neededGearMap[uid] and not neededGearMap[uid].location then
        neededGearMap[uid].location = "BAG"
        neededGearMap[uid].bag = BAG_BACKPACK
        neededGearMap[uid].slot = slot
        neededGearMap[uid].link = currentLink
      end
    end
  end

  -- 3. Scan Bank Bags
  local bankBags = XLGB_Inventory:GetBankBags()
  for _, bankBag in ipairs(bankBags) do
    local bSize = GetBagSize(bankBag)
    for slot = 0, bSize - 1 do
      local currentLink = GetItemLink(bankBag, slot)
      if currentLink and currentLink ~= "" then
        local uid = (XLGB_Inventory and XLGB_Inventory.GetSlotUid and XLGB_Inventory:GetSlotUid(bankBag, slot)) or Id64ToString(GetItemUniqueId(bankBag, slot))
        if neededGearMap[uid] and not neededGearMap[uid].location then
          neededGearMap[uid].location = "BANK"
          neededGearMap[uid].bag = bankBag
          neededGearMap[uid].slot = slot
          neededGearMap[uid].link = currentLink
        end
      end
    end
  end

  -- 4. Group by Set & Compute Stats
  local setsMap = {}
  local setsOrder = {}

  for uid, item in pairs(neededGearMap) do
    if not item.location then
      item.location = "MISSING"
    end

    stats.total = stats.total + 1
    if item.location == "WORN" then
      stats.worn = stats.worn + 1
    elseif item.location == "BAG" then
      stats.bag = stats.bag + 1
    elseif item.location == "BANK" then
      stats.bank = stats.bank + 1
    elseif item.location == "MISSING" then
      stats.missing = stats.missing + 1
    end

    local hasSet, setName = XLGB_Inventory:GetItemSetInfo(item.link)
    if not hasSet or not setName or setName == "" then
      setName = XLGB_GetString("WW_ISOLATED_PIECES")
    end

    if not setsMap[setName] then
      setsMap[setName] = {
        setName = setName,
        items = {},
        bosses = {},
        worn = 0,
        bag = 0,
        bank = 0,
        missing = 0,
      }
      table.insert(setsOrder, setName)
    end

    table.insert(setsMap[setName].items, item)
    if item.setups then
      for _, setupName in ipairs(item.setups) do
        local found = false
        for _, b in ipairs(setsMap[setName].bosses) do
          if b == setupName then found = true break end
        end
        if not found then
          table.insert(setsMap[setName].bosses, setupName)
        end
      end
    end
    if item.location == "WORN" then
      setsMap[setName].worn = setsMap[setName].worn + 1
    elseif item.location == "BAG" then
      setsMap[setName].bag = setsMap[setName].bag + 1
    elseif item.location == "BANK" then
      setsMap[setName].bank = setsMap[setName].bank + 1
    elseif item.location == "MISSING" then
      setsMap[setName].missing = setsMap[setName].missing + 1
    end
  end

  local isolatedName = XLGB_GetString("WW_ISOLATED_PIECES")
  table.sort(setsOrder, function(a, b)
    if a == isolatedName or a == "Pièces isolées / Mythiques" or a == "Isolated Pieces / Mythics" then return false end
    if b == isolatedName or b == "Pièces isolées / Mythiques" or b == "Isolated Pieces / Mythics" then return true end
    return a < b
  end)

  local setsList = {}
  local locOrder = { WORN = 1, BAG = 2, BANK = 3, MISSING = 4 }
  for _, setName in ipairs(setsOrder) do
    local setGroup = setsMap[setName]
    table.sort(setGroup.items, function(a, b)
      local la = locOrder[a.location] or 5
      local lb = locOrder[b.location] or 5
      if la ~= lb then return la < lb end
      return (a.link or "") < (b.link or "")
    end)
    table.insert(setsList, setGroup)
  end

  return neededGearMap, setsList, stats
end

function WWB:GetDifferenceItems(characterId, zoneTag, pageId, qualityFilter, optNeededGearMap)
  local neededGearMap = optNeededGearMap or self:GetPageGear(characterId, zoneTag, pageId)
  local differenceItems = {}
  local filter = qualityFilter or (XLGearBanker.savedVariables and XLGearBanker.savedVariables.wardrobeDepositQualities)

  local bagSize = GetBagSize(BAG_BACKPACK)
  for slot = 0, bagSize - 1 do
    local link = GetItemLink(BAG_BACKPACK, slot)
    if link and link ~= "" then
      if XLGB_Banking:IsEquipmentItem(BAG_BACKPACK, slot, link) then
        local uid = (XLGB_Inventory and XLGB_Inventory.GetSlotUid and XLGB_Inventory:GetSlotUid(BAG_BACKPACK, slot)) or Id64ToString(GetItemUniqueId(BAG_BACKPACK, slot))
        if not neededGearMap[uid] then
          if not filter or XLGB_Banking:IsItemQualityAllowed(BAG_BACKPACK, slot, link, filter) then
            local hasSet, setName = XLGB_Inventory:GetItemSetInfo(link)
            table.insert(differenceItems, {
              bag = BAG_BACKPACK,
              slot = slot,
              ID = uid,
              link = link,
              name = GetItemName(BAG_BACKPACK, slot),
              setName = (hasSet and setName and setName ~= "") and setName or XLGB_GetString("SET_LABEL_NO_SET"),
            })
          end
        end
      end
    end
  end

  table.sort(differenceItems, function(a, b)
    if a.setName ~= b.setName then
      return a.setName < b.setName
    end
    return a.link < b.link
  end)

  return differenceItems
end

function WWB:DepositDifference(characterId, zoneTag, pageId, callback)
  if not XLGB_Banking.bankOpen then
    d(XLGB_GetString("WW_BANK_MUST_BE_OPEN_DEPOSIT"))
    PlaySound(SOUNDS.ABILITY_FAILED)
    if callback then callback(false) end
    return false
  end

  local sV = XLGearBanker.savedVariables
  local diffFilter = sV and sV.wardrobeDepositQualities
  local diffItems = self:GetDifferenceItems(characterId, zoneTag, pageId, diffFilter)
  if #diffItems == 0 then
    d(XLGB_GetString("WW_NO_SURPLUS_FILTER"))
    if callback then callback(true) end
    return true
  end

  d(XLGB_GetString("WW_DEPOSIT_MSG", #diffItems))
  return XLGB_Banking:DepositItemList(diffItems, "WW Surplus", true, function(success)
    if XLGB_UI then XLGB_UI:UpdateWardrobeUI() end
    if callback then callback(success) end
  end, diffFilter)
end

function WWB:WithdrawPageGear(characterId, zoneTag, pageId, callback)
  if not XLGB_Banking.bankOpen then
    d(XLGB_GetString("WW_BANK_MUST_BE_OPEN_WITHDRAW"))
    PlaySound(SOUNDS.ABILITY_FAILED)
    if callback then callback(false) end
    return false
  end

  local sV = XLGearBanker.savedVariables
  local withFilter = sV and sV.wardrobeWithdrawQualities
  local neededGearMap = self:GetPageGear(characterId, zoneTag, pageId)
  local bankItems = {}
  for uid, item in pairs(neededGearMap) do
    if item.location == "BANK" then
      table.insert(bankItems, { ID = item.id, link = item.link })
    end
  end

  if #bankItems == 0 then
    d(XLGB_GetString("WW_NO_ITEMS_TO_WITHDRAW"))
    if callback then callback(true) end
    return true
  end

  d(XLGB_GetString("WW_WITHDRAW_MSG", #bankItems))
  return XLGB_Banking:WithdrawItemList(bankItems, "WW Page", function(success)
    if XLGB_UI then XLGB_UI:UpdateWardrobeUI() end
    if callback then callback(success) end
  end, withFilter)
end

function WWB:PrepareInventory(characterId, zoneTag, pageId, callback)
  if not XLGB_Banking.bankOpen then
    d(XLGB_GetString("WW_BANK_MUST_BE_OPEN_PREPARE"))
    PlaySound(SOUNDS.ABILITY_FAILED)
    if callback then callback(false) end
    return false
  end

  local sV = XLGearBanker.savedVariables
  local withFilter = sV and sV.wardrobeWithdrawQualities
  local diffFilter = sV and sV.wardrobeDepositQualities

  local neededGearMap, sets, stats = self:GetPageGear(characterId, zoneTag, pageId)
  local bankItems = {}
  for uid, item in pairs(neededGearMap) do
    if item.location == "BANK" then
      table.insert(bankItems, { ID = item.id, link = item.link })
    end
  end

  local diffItems = self:GetDifferenceItems(characterId, zoneTag, pageId, diffFilter)

  if #bankItems == 0 and #diffItems == 0 then
    d(XLGB_GetString("WW_PREPARE_READY"))
    if callback then callback(true) end
    return true
  end

  local opWithdraw = (XLGB_GetString and XLGB_GetString("WW_OP_PAGE_WITHDRAW")) or "WW Page (withdraw)"
  local opSurplus = (XLGB_GetString and XLGB_GetString("WW_OP_PAGE_SURPLUS")) or "WW Page (surplus)"

  if #bankItems > 0 then
    self.isPreparingPage = true
    XLGB_Banking:SwitchToJunkTab()
    d(XLGB_GetString("WW_WITHDRAW_MSG", #bankItems))
    XLGB_Banking:WithdrawItemList(bankItems, opWithdraw, function(withdrawn)
      if not withdrawn then
        self.isPreparingPage = false
        XLGB_Banking:RestoreInventoryTab(true)
        if callback then callback(false) end
        return
      end

      zo_callLater(function()
        local updatedDiff = WWB:GetDifferenceItems(characterId, zoneTag, pageId, diffFilter)
        if #updatedDiff > 0 then
          d(XLGB_GetString("WW_DEPOSIT_MSG", #updatedDiff))
          XLGB_Banking:DepositItemList(updatedDiff, opSurplus, true, function(deposited)
            self.isPreparingPage = false
            XLGB_Banking:RestoreInventoryTab(true)
            if XLGB_UI then XLGB_UI:UpdateWardrobeUI() end
            if deposited then
              d(XLGB_GetString("WW_PREPARE_SUCCESS"))
            end
            if callback then callback(deposited) end
          end, diffFilter)
        else
          self.isPreparingPage = false
          XLGB_Banking:RestoreInventoryTab(true)
          if XLGB_UI then XLGB_UI:UpdateWardrobeUI() end
          d(XLGB_GetString("WW_PREPARE_SUCCESS"))
          if callback then callback(true) end
        end
      end, 400)
    end, withFilter)
  else
    self.isPreparingPage = true
    XLGB_Banking:SwitchToJunkTab()
    d(XLGB_GetString("WW_DEPOSIT_MSG", #diffItems))
    XLGB_Banking:DepositItemList(diffItems, opSurplus, true, function(deposited)
      self.isPreparingPage = false
      XLGB_Banking:RestoreInventoryTab(true)
      if XLGB_UI then XLGB_UI:UpdateWardrobeUI() end
      if deposited then
        d(XLGB_GetString("WW_PREPARE_SUCCESS"))
      end
      if callback then callback(deposited) end
    end, diffFilter)
  end
end

function WWB:ImportAsXLGBPage(characterId, zoneTag, pageId)
  local neededGearMap, setsList, stats = self:GetPageGear(characterId, zoneTag, pageId)
  if #setsList == 0 then
    d(XLGB_GetString("WW_IMPORT_NO_DATA"))
    return false
  end

  local charName = self:GetCharacterName(characterId)

  local pages = self:GetPages(characterId, zoneTag)
  local pageName = "Page " .. tostring(pageId)
  for _, p in ipairs(pages) do
    if tostring(p.id) == tostring(pageId) then pageName = p.name break end
  end

  local xlPageName = charName .. " - " .. pageName
  local existingPage = XLGB_Page:GetPage(xlPageName)
  if not existingPage then
    local legacyPage = XLGB_Page:GetPage("[WW] " .. xlPageName)
    if legacyPage then
      XLGB_Page:SetPageName(legacyPage.name, xlPageName)
      existingPage = legacyPage
    end
  end

  if existingPage then
    existingPage.isWW = true
    existingPage.wwZoneTag = zoneTag
    existingPage.wwPageId = pageId
    existingPage.wwCharacterId = characterId
    XLGB_Page:ClearPage(xlPageName)
  else
    local createdName = XLGB_Page:CreatePage()
    if createdName then
      XLGB_Page:SetPageName(createdName, xlPageName)
      local page = XLGB_Page:GetPage(xlPageName)
      if page then
        page.isWW = true
        page.wwZoneTag = zoneTag
        page.wwPageId = pageId
        page.wwCharacterId = characterId
      end
    end
  end

  local importedSetCount = 0
  for _, setGroup in ipairs(setsList) do
    local targetSetName = ""
    local isolatedName = XLGB_GetString("WW_ISOLATED_PIECES")
    local noSetName = XLGB_GetString("SET_LABEL_NO_SET")
    if setGroup.setName == isolatedName or setGroup.setName == noSetName or setGroup.setName == "Pièces isolées / Mythiques" or setGroup.setName == "Sans set" then
      local otherLabel = (XLGB_GetString and XLGB_GetString("WW_ZONE_OTHER")) or "Other"
      targetSetName = charName .. " - " .. pageName .. " (" .. otherLabel .. ")"
    else
      targetSetName = charName .. " - " .. pageName .. " - " .. setGroup.setName
    end

    local gearSet = XLGB_GearSet:FindGearSet(targetSetName)
    if not gearSet then
      local legacySet = XLGB_GearSet:FindGearSet("[WW] " .. targetSetName)
      if legacySet then
        local legIdx = XLGB_GearSet:GetGearSetIndex(legacySet.name)
        if legIdx and legIdx > 0 then
          XLGB_GearSet:EditGearSetName(targetSetName, legIdx)
          gearSet = XLGB_GearSet:FindGearSet(targetSetName)
        end
      end
    end

    if not gearSet then
      XLGB_GearSet:CreateNewGearSet(targetSetName)
      gearSet = XLGB_GearSet:FindGearSet(targetSetName)
    end

    if gearSet then
      gearSet.isWW = true
      gearSet.pageName = xlPageName
      gearSet.baseSetName = setGroup.setName
      gearSet.bosses = setGroup.bosses or {}
      gearSet.wwZoneTag = zoneTag
      gearSet.wwPageId = pageId
      gearSet.wwCharacterId = characterId
    end

    local gsIndex = XLGB_GearSet:GetGearSetIndex(targetSetName)
    if gsIndex and gsIndex > 0 then
      -- Le set ne doit contenir STRICTEMENT que les morceaux requis par cette page.
      -- Sécurité absolue : on ne vide et ne réutilise JAMAIS un set qui n'est pas un import WW
      local sV = XLGearBanker.savedVariables
      if sV and sV.gearSetList and sV.gearSetList[gsIndex] then
        local current = sV.gearSetList[gsIndex]
        if current.isWW or string.sub(current.name or "", 1, 5) == "[WW] " then
          current.items = {}
        end
      end

      if setGroup.items and #setGroup.items > 0 then
        local itemsToAdd = {}
        for _, item in ipairs(setGroup.items) do
          table.insert(itemsToAdd, {
            link = item.link or "",
            ID = item.id or item.ID,
            setups = item.setups,
            _scopedTo = xlPageName,
          })
        end
        XLGB_GearSet:AddItemsToGearSet(itemsToAdd, gsIndex)
      end
    end

    if not XLGB_Page:PageContainsSet(xlPageName, targetSetName) then
      XLGB_Page:AddSetToPage(targetSetName, xlPageName)
    end
    importedSetCount = importedSetCount + 1
  end

  local importedPageIndex = XLGB_Page:GetIndexOfPage(xlPageName)
  if importedPageIndex and XLGearBanker.savedVariables then
    XLGearBanker.savedVariables.displayingPage = importedPageIndex
    XLGearBanker.savedVariables.lastWWPage = importedPageIndex
    XLGearBanker.savedVariables.pageCategoryTab = 2
  end

  if XLGB_UI then
    XLGB_UI:UpdatePageDropdown()
    if importedPageIndex then
      XLGB_UI:SelectPage(importedPageIndex)
    end
    XLGB_UI:UpdateSetDropdown()
    XLGB_UI:UpdateSetScrollList()
    XLGB_UI:ShowPageUI()
  end

  d(XLGB_GetString("WW_IMPORT_SUCCESS", xlPageName, importedSetCount))
  PlaySound(SOUNDS.BOOK_ACQUIRED)
  return true
end

local function matchZoneTag(name)
  if not name or name == "" then return nil end
  local clean = name:lower():gsub("^v", ""):gsub("%s*%(.*%)", ""):gsub("%s+", "")
  for tag, zName in pairs(DEFAULT_ZONE_NAMES) do
    local cleanZName = zName:lower():gsub("%s+", "")
    local cleanTag = tag:lower()
    if clean == cleanTag or clean == cleanZName or clean == ("v" .. cleanTag) then
      return tag
    end
    if string.len(clean) >= 4 and (cleanZName:find(clean, 1, true) or clean:find(cleanZName, 1, true)) then
      return tag
    end
  end
  local WW = WizardsWardrobe
  if WW and WW.zones then
    for tag, z in pairs(WW.zones) do
      if z and z.name then
        local cleanZName = z.name:lower():gsub("%s+", "")
        local cleanTag = tostring(tag):lower()
        if clean == cleanTag or clean == cleanZName or clean == ("v" .. cleanTag) then
          return tag
        end
        if string.len(clean) >= 4 and (cleanZName:find(clean, 1, true) or clean:find(cleanZName, 1, true)) then
          return tag
        end
      end
    end
  end
  return nil
end

function WWB:FindParentPageForSet(gearSet)
  if not gearSet then return nil end
  local sV = XLGearBanker and XLGearBanker.savedVariables
  local pages = sV and sV.pages
  if not pages then return nil end
  local targetName = gearSet.name
  if not targetName or targetName == "" then return nil end
  for _, page in ipairs(pages) do
    if page and page.sets then
      for _, sName in ipairs(page.sets) do
        if sName == targetName then
          return page
        end
      end
    end
  end
  return nil
end

function WWB:GetSetupsForItem(item, gearSet, forceRefresh)
  if not item then return nil end

  local isWWSet = gearSet and (gearSet.isWW or (gearSet.name and string.sub(gearSet.name, 1, 5) == "[WW] "))
  if not isWWSet and gearSet and gearSet.name then
    local parentPage = self:FindParentPageForSet(gearSet)
    if parentPage and (parentPage.isWW or string.sub(parentPage.name or "", 1, 5) == "[WW] ") then
      isWWSet = true
      gearSet.isWW = true
    end
  end

  if isWWSet and gearSet then
    if not gearSet.pageName or not gearSet.wwZoneTag then
      local parentPage = self:FindParentPageForSet(gearSet)
      if parentPage then
        if not gearSet.pageName then gearSet.pageName = parentPage.name end
        if not gearSet.wwZoneTag and parentPage.wwZoneTag then gearSet.wwZoneTag = parentPage.wwZoneTag end
        if not gearSet.wwPageId and parentPage.wwPageId then gearSet.wwPageId = parentPage.wwPageId end
        if not gearSet.wwCharacterId and parentPage.wwCharacterId then gearSet.wwCharacterId = parentPage.wwCharacterId end
      end
    end
  end

  local contextKey = gearSet and (gearSet.pageName or gearSet.name or "") or ""
  if not forceRefresh and item.setups and #item.setups > 0 and (item._scopedTo == contextKey or contextKey == "") then
    return item.setups
  end

  local targetId = item.ID or item.id
  local targetLink = item.link or item.itemLink
  if (not targetId or targetId == "") and (not targetLink or targetLink == "") then
    return nil
  end

  local targetIdStr = targetId and tostring(targetId)
  local wwData = self:GetWWSavedVariables()
  if not wwData then return nil end

  local foundSetups = {}
  local seen = {}

  local function scanStorageSetups(storage, filterZoneTag, filterPageId)
    if not storage or not storage.setups then return end

    local zonesToScan = {}
    if filterZoneTag and storage.setups[filterZoneTag] then
      zonesToScan[filterZoneTag] = storage.setups[filterZoneTag]
    elseif not filterZoneTag and not isWWSet then
      zonesToScan = storage.setups
    else
      return
    end

    for zoneTag, pages in pairs(zonesToScan) do
      if type(pages) == "table" then
        local pagesToScan = {}
        if filterPageId and pages[filterPageId] then
          pagesToScan[filterPageId] = pages[filterPageId]
        elseif not filterPageId then
          pagesToScan = pages
        else
          pagesToScan = pages
        end

        for pageId, pageSetups in pairs(pagesToScan) do
          if type(pageSetups) == "table" then
            for setupIdx, setup in ipairs(pageSetups) do
              if setup and setup.gear then
                local setupName = setup.name or ("Setup " .. setupIdx)
                for slotIdx, gear in pairs(setup.gear) do
                  if type(gear) == "table" and gear.id and gear.id ~= "" and gear.id ~= "0" then
                    local match = false
                    if targetIdStr and tostring(gear.id) == targetIdStr then
                      match = true
                    elseif targetLink and gear.link and gear.link ~= "" and gear.link == targetLink then
                      match = true
                    end
                    if match and not seen[setupName] then
                      seen[setupName] = true
                      table.insert(foundSetups, setupName)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  -- Determine Character and Scoped Zone / Page
  local filterZoneTag = gearSet and gearSet.wwZoneTag
  local filterPageId = gearSet and gearSet.wwPageId
  local characterId = gearSet and gearSet.wwCharacterId
  local storage = characterId and self:GetCharacterStorage(characterId)

  if gearSet and (not storage or not filterZoneTag) then
    local fullName = gearSet.pageName or gearSet.name or ""
    if string.sub(fullName, 1, 5) == "[WW] " then
      fullName = string.sub(fullName, 6)
    end
    local parts = {}
    for part in string.gmatch(fullName .. " - ", "(.-) %- ") do
      local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
      if trimmed ~= "" then
        table.insert(parts, trimmed)
      end
    end

    local charName = parts[1]
    local pageOrZoneName = parts[2]

    if not storage and charName and charName ~= "" then
      local chars = self:GetCharacters()
      for _, ch in ipairs(chars) do
        if ch.name == charName then
          characterId = ch.id
          storage = self:GetCharacterStorage(ch.id)
          break
        end
      end
      if not storage and wwData then
        for cid, cdata in pairs(wwData) do
          if type(cdata) == "table" and cdata["$LastCharacterName"] == charName then
            characterId = tostring(cid)
            storage = self:GetCharacterStorage(cid)
            break
          end
        end
      end
    end

    if storage and not filterZoneTag and pageOrZoneName and pageOrZoneName ~= "" then
      local cleanPageName = pageOrZoneName:gsub("%s*%(.*%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
      local baseClean = cleanPageName:gsub("%s*[%d%-%.%/]+%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")

      if storage.pages then
        for zTag, pTable in pairs(storage.pages) do
          if type(pTable) == "table" then
            for pId, pInfo in pairs(pTable) do
              if pId ~= 0 and type(pInfo) == "table" and pInfo.name then
                if zo_strlower(pInfo.name) == zo_strlower(cleanPageName) then
                  filterZoneTag = zTag
                  filterPageId = pId
                  break
                end
                local basePName = pInfo.name:gsub("%s*[%d%-%.%/]+%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if #baseClean >= 3 and zo_strlower(baseClean) == zo_strlower(basePName) then
                  filterZoneTag = zTag
                  filterPageId = pId
                  break
                end
              end
            end
            if filterZoneTag then break end
          end
        end
      end

      if not filterZoneTag then
        filterZoneTag = matchZoneTag(cleanPageName)
      end

      if not filterZoneTag and storage.setups then
        for zTag, pTable in pairs(storage.setups) do
          if type(pTable) == "table" then
            for pId, setups in pairs(pTable) do
              if type(setups) == "table" then
                for _, s in ipairs(setups) do
                  if s.gear then
                    for _, g in pairs(s.gear) do
                      if type(g) == "table" and ((targetIdStr and tostring(g.id) == targetIdStr) or (targetLink and g.link == targetLink)) then
                        filterZoneTag = zTag
                        filterPageId = pId
                        break
                      end
                    end
                  end
                  if filterZoneTag then break end
                end
              end
              if filterZoneTag then break end
            end
          end
        end
      end

      if filterZoneTag and gearSet then
        gearSet.wwZoneTag = filterZoneTag
        gearSet.wwPageId = filterPageId
        gearSet.wwCharacterId = characterId
      end
    end
  end

  -- Execute Scoped Scan
  if storage then
    scanStorageSetups(storage, filterZoneTag, filterPageId)
  end

  -- Fallback: ONLY if gearSet is NOT a WW set, scan current char storage
  if #foundSetups == 0 and not isWWSet and not storage and not filterZoneTag then
    local currentCharId = GetCurrentCharacterId and tostring(Id64ToString(GetCurrentCharacterId()))
    if currentCharId then
      local curStorage = self:GetCharacterStorage(currentCharId)
      scanStorageSetups(curStorage, nil, nil)
    end
  end

  if #foundSetups > 0 then
    item.setups = foundSetups
    item._scopedTo = contextKey
    return foundSetups
  else
    item.setups = nil
    item._scopedTo = contextKey
    return nil
  end
end

function WWB:EnrichImportedSetsWithSetups()
  local sV = XLGearBanker and XLGearBanker.savedVariables
  if not sV or not sV.gearSetList then return end
  for _, gearSet in ipairs(sV.gearSetList) do
    if gearSet.isWW or string.sub(gearSet.name or "", 1, 5) == "[WW] " then
      if gearSet.items then
        for _, item in ipairs(gearSet.items) do
          self:GetSetupsForItem(item, gearSet, true)
        end
      end
    end
  end
end

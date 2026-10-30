--[[
  XLGB_MenuOverWriter.lua

  It adds an extra entry to the dropdown menu when you right click an item that allows you to add that item to a gearset of choice.

  The following code is heavily inspired by TTC's TamrielTradeCenterPrice.lua
]]--

-- Namespace
XLGB_MenuOverWriter = {}

-- Constants
XLGB = XLGB_Constants
local sV = nil

-- Functions
local function MakeContextMenuEntry_AddItemToGearSet(itemLink, itemID)
  local subEntries = {}
  local totalGearSets = XLGB_GearSet:GetNumberOfGearSets()
  if totalGearSets ~= 0 then
    for i = 1, totalGearSets do
      local gearSetName = XLGB_GearSet:GetGearSet(i).name
      local subEntry = {
        label = gearSetName,
        callback =
          function()
            if (XLGB_GearSet:GetItemIndexInGearSet(itemID, i) == XLGB.ITEM_NOT_IN_SET) then
              XLGB_GearSet:AddItemToGearSet(itemLink, itemID, i)
            else
              d(string.format(XLGB_GetString("CONTEXT_ITEM_ALREADY_IN_SET") or "[XLGB] Item %s is already in '%s'.", itemLink, gearSetName))
            end
          end
      }
      table.insert(subEntries, subEntry)
    end
    AddCustomSubMenuItem(XLGB_GetString("CONTEXT_ADD_ITEM") or XLGB.ADD_ITEM_TO_GEARSET, subEntries)
  end
end

local function MakeContextMenuEntry_RemoveItemFromGearSet(itemLink, itemID)
  local subEntries = {}
  local totalGearSets = XLGB_GearSet:GetNumberOfGearSets()
  if totalGearSets ~= 0 then 
    for i = 1, totalGearSets do
      if (XLGB_GearSet:GetItemIndexInGearSet(itemID, i) ~= XLGB.ITEM_NOT_IN_SET) then
        local gearSetName = XLGB_GearSet:GetGearSet(i).name
        local subEntry = {
          label = gearSetName,
          callback = 
            function()
              XLGB_GearSet:RemoveItemFromGearSet(itemLink, itemID, i)
            end
        }
        table.insert(subEntries, subEntry)
      end
    end
    if (#subEntries ~= 0) then 
      AddCustomSubMenuItem(XLGB_GetString("CONTEXT_REMOVE_ITEM") or XLGB.REMOVE_ITEM_FROM_GEARSET, subEntries)
    end
  end
end

local function MakeContextMenuEntry_AddSetPiecesToGearSet(itemLink)
  local isSet, setName, setId = XLGB_Inventory:GetItemSetInfo(itemLink)
  if not isSet or not setName or setName == "" then return end

  local invItems = XLGB_Inventory:GetInventoryItemsForSet(setId, setName)
  local isBankOpen = (XLGB_Banking and (XLGB_Banking.bankOpen == true or (IsBankOpen and IsBankOpen())))
  local bankItems = (isBankOpen and XLGB_Inventory:GetBankItemsForSet(setId, setName)) or {}

  local totalInv = #invItems
  local totalBank = #bankItems
  if totalInv == 0 and totalBank == 0 then return end

  local function buildSubmenu(itemsToAdd, sourceLabel)
    local subEntries = {}
    local totalGearSets = XLGB_GearSet:GetNumberOfGearSets()
    if totalGearSets > 0 then
      for i = 1, totalGearSets do
        local gearSetName = XLGB_GearSet:GetGearSet(i).name
        local subEntry = {
          label = gearSetName,
          callback = function()
            XLGB_GearSet:AddSetItemsToGearSet(itemsToAdd, setName, i, sourceLabel)
            XLGB_UI:UpdateSetScrollList()
            if XLGB_UI.UpdateSetDropdown then
              XLGB_UI:UpdateSetDropdown()
            end
          end
        }
        table.insert(subEntries, subEntry)
      end
    end

    local createEntry = {
      label = string.format(XLGB_GetString("CONTEXT_CREATE_NEW_SET"), setName),
      callback = function()
        local newName = setName
        local counter = 2
        while not XLGB_GearSet:CreateNewGearSet(newName) do
          newName = string.format("%s (%d)", setName, counter)
          counter = counter + 1
        end
        local newIndex = XLGB_GearSet:GetGearSetIndex(newName)
        if newIndex then
          if sV then
            sV.displayingSet = newIndex
          end
          XLGB_GearSet:AddSetItemsToGearSet(itemsToAdd, setName, newIndex, sourceLabel)
          XLGB_UI:SelectSet(newIndex)
          XLGB_UI:UpdateSetDropdown()
          XLGB_UI:UpdateSetScrollList()
          XLGB_UI:ShowOrHideEditSet()
        end
      end
    }
    table.insert(subEntries, createEntry)

    return subEntries
  end

  local bothLabel = XLGB_GetString("SET_SOURCE_BOTH_LABEL")
  local bagLabel = XLGB_GetString("SET_SOURCE_BAG_LABEL")
  local bankLabel = XLGB_GetString("SET_SOURCE_BANK_LABEL")

  if totalInv > 0 and totalBank > 0 then
    local combinedItems = {}
    local seen = {}
    for _, item in ipairs(invItems) do
      if not seen[item.ID] then
        seen[item.ID] = true
        table.insert(combinedItems, item)
      end
    end
    for _, item in ipairs(bankItems) do
      if not seen[item.ID] then
        seen[item.ID] = true
        table.insert(combinedItems, item)
      end
    end

    AddCustomSubMenuItem(string.format(XLGB_GetString("CONTEXT_ADD_FULL_SET"), setName, #combinedItems), buildSubmenu(combinedItems, bothLabel))
    AddCustomSubMenuItem(string.format(XLGB_GetString("CONTEXT_ADD_BAG_SET"), setName, totalInv), buildSubmenu(invItems, bagLabel))
    AddCustomSubMenuItem(string.format(XLGB_GetString("CONTEXT_ADD_BANK_SET"), setName, totalBank), buildSubmenu(bankItems, bankLabel))
  elseif totalInv > 0 then
    local fmt = isBankOpen and XLGB_GetString("CONTEXT_ADD_BAG_SET") or XLGB_GetString("CONTEXT_ADD_SET")
    AddCustomSubMenuItem(string.format(fmt, setName, totalInv), buildSubmenu(invItems, bagLabel))
  elseif totalBank > 0 then
    AddCustomSubMenuItem(string.format(XLGB_GetString("CONTEXT_ADD_BANK_SET"), setName, totalBank), buildSubmenu(bankItems, bankLabel))
  end
end

local function AddContextMenuEntries(itemLink, itemID, inventorySlot)
  MakeContextMenuEntry_AddItemToGearSet(itemLink, itemID)
  MakeContextMenuEntry_AddSetPiecesToGearSet(itemLink)
  MakeContextMenuEntry_RemoveItemFromGearSet(itemLink, itemID)
  ShowMenu(inventorySlot)
end


local ALLOWED_SLOT_TYPES = {
  [SLOT_TYPE_ITEM] = true,
  [SLOT_TYPE_EQUIPMENT] = true,
  [SLOT_TYPE_BANK_ITEM] = true,
  [SLOT_TYPE_GUILD_BANK_ITEM] = true,
  [SLOT_TYPE_CRAFT_BAG_ITEM] = true,
}

local function OverWriteInventoryShowContextMenuHandler()
  if not LibCustomMenu then return end
  LibCustomMenu:RegisterContextMenu(
      function(inventorySlot, slotActions)
        if not sV or not sV.enableItemContextMenu then return end
        local slotType = ZO_InventorySlot_GetType(inventorySlot)
        if not ALLOWED_SLOT_TYPES[slotType] then return end
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if not bag or not index then return end
        local itemLink = GetItemLink(bag, index)
        if not itemLink or itemLink == "" then return end
        local itemID = Id64ToString(GetItemUniqueId(bag, index))
        if not itemID or itemID == "" or itemID == "0" then
          itemID = itemLink
        end
        easyDebug("Item ID of " .. itemLink .. ": " .. itemID)
        AddContextMenuEntries(itemLink, itemID, inventorySlot)
      end,
      LibCustomMenu.CATEGORY_LATE
    )
  end

function XLGB_MenuOverWriter:Initialize()
  sV = XLGearBanker.savedVariables
  if sV and sV.enableItemContextMenu == nil then
    sV.enableItemContextMenu = false
  end
  OverWriteInventoryShowContextMenuHandler()
end


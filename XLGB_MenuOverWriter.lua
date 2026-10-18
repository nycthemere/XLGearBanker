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
              d("[XLGB] Item " .. itemLink .. " is already in " .. gearSetName)
            end
          end
      }
      table.insert(subEntries, subEntry)
    end
    AddCustomSubMenuItem(XLGB.ADD_ITEM_TO_GEARSET, subEntries)
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
      AddCustomSubMenuItem(XLGB.REMOVE_ITEM_FROM_GEARSET, subEntries)
    end
  end
end

local function MakeContextMenuEntry_AddSetPiecesToGearSet(itemLink)
  local isSet, setName, setId = XLGB_Inventory:GetItemSetInfo(itemLink)
  if not isSet or not setName or setName == "" then return end

  local invItems = XLGB_Inventory:GetInventoryItemsForSet(setId, setName)
  local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)
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
      label = string.format("|c55FF55[+ Nouveau set : %s]|r", setName),
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

    AddCustomSubMenuItem(string.format("XLGB ajouter tout le set (%s - %d pcs)", setName, #combinedItems), buildSubmenu(combinedItems, "inventaire & banque"))
    AddCustomSubMenuItem(string.format("XLGB ajouter set sac (%s - %d pcs)", setName, totalInv), buildSubmenu(invItems, "inventaire"))
    AddCustomSubMenuItem(string.format("XLGB ajouter set banque (%s - %d pcs)", setName, totalBank), buildSubmenu(bankItems, "banque"))
  elseif totalInv > 0 then
    local label = isBankOpen and string.format("XLGB ajouter set sac (%s - %d pcs)", setName, totalInv)
                              or string.format("XLGB ajouter set (%s - %d pcs)", setName, totalInv)
    AddCustomSubMenuItem(label, buildSubmenu(invItems, "inventaire"))
  elseif totalBank > 0 then
    AddCustomSubMenuItem(string.format("XLGB ajouter set banque (%s - %d pcs)", setName, totalBank), buildSubmenu(bankItems, "banque"))
  end
end

local function AddContextMenuEntries(itemLink, itemID, inventorySlot)
  MakeContextMenuEntry_AddItemToGearSet(itemLink, itemID)
  MakeContextMenuEntry_AddSetPiecesToGearSet(itemLink)
  MakeContextMenuEntry_RemoveItemFromGearSet(itemLink, itemID)
  ShowMenu(inventorySlot)
end


local function OverWriteInventoryShowContextMenuHandler()
  LibCustomMenu:RegisterContextMenu(
      function(inventorySlot, slotActions)
        -- Inventory slot should either be the player bag, equipment slots, bank, or storage containers.
        local slotTypesAllowed = {}
        if SLOT_TYPE_ITEM then slotTypesAllowed[SLOT_TYPE_ITEM] = true end
        if SLOT_TYPE_EQUIPMENT then slotTypesAllowed[SLOT_TYPE_EQUIPMENT] = true end
        if SLOT_TYPE_BANK_ITEM then slotTypesAllowed[SLOT_TYPE_BANK_ITEM] = true end
        if SLOT_TYPE_GUILD_BANK_ITEM then slotTypesAllowed[SLOT_TYPE_GUILD_BANK_ITEM] = true end
        if SLOT_TYPE_HOUSE_BANK then slotTypesAllowed[SLOT_TYPE_HOUSE_BANK] = true end
        if SLOT_TYPE_STORAGE_ITEM then slotTypesAllowed[SLOT_TYPE_STORAGE_ITEM] = true end
        if SLOT_TYPE_COMPANION_EQUIPMENT then slotTypesAllowed[SLOT_TYPE_COMPANION_EQUIPMENT] = true end

        local slotType = ZO_InventorySlot_GetType(inventorySlot)
        if not slotTypesAllowed[slotType] then return end
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if bag == nil or index == nil then return end
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
  OverWriteInventoryShowContextMenuHandler()
end


XLGB_Page = {}
local sV

function XLGB_Page:GetNumberOfPages()
  return #sV.pages
end

local function sortPages()
  local function comparePages(pageA, pageB)
    return pageA.name < pageB.name
  end

  local preSortList = {}
  for i, page in pairs(sV.pages) do
      preSortList[i] = page.name
  end

  table.sort(sV.pages, comparePages)
  XLGB_Events:OnPageSort(preSortList)
end

function XLGB_Page:CreatePage()
  local x = "X"
  local pageName = "My " .. x .. "LGB Page"
  while XLGB_Page:GetPage(pageName) do
      x = x .. "X"
      pageName = "My " .. x .. "LGB Page"
  end
  local newPage = {
    name = pageName,
    sets = {}
  }
  table.insert(sV.pages, newPage)
  sortPages()
  return newPage.name
end

function XLGB_Page:GetPage(pageName)
  for _, page in pairs(sV.pages) do
      if page.name == pageName then
        return page
      end
  end
end

function XLGB_Page:GetIndexOfPage(pageName)
  for i, page in pairs(sV.pages) do
      if page.name == pageName then
        return i
      end
  end
end

function XLGB_Page:GetPageByIndex(index)
  return sV.pages[index]
end

function XLGB_Page:GetAllPages()
  return sV.pages
end

function XLGB_Page:RemovePage(name)
  for i, page in pairs(sV.pages) do
    if page.name == name then
      table.remove(sV.pages, i)
      return
    end
  end
end

function XLGB_Page:ClearPage(pageName)
  local page = XLGB_Page:GetPage(pageName)
  page.sets = {}
end

function XLGB_Page:SetPageName(oldName, newName)
  local page = XLGB_Page:GetPage(oldName)
  local isUnique = not XLGB_Page:GetPage(newName)
  if isUnique then
    page.name = newName
    sortPages()
    return true
  end
  return oldName == newName -- If they were the same don't change and return true
end

local function GetSetIndexInPage(setName, page)
  for i, set in pairs(page.sets) do
    if set == setName then
      return i
    end
  end
end

function XLGB_Page:AddSetToPage(setName, pageName)
  local page = XLGB_Page:GetPage(pageName)
  local isUnique = not GetSetIndexInPage(setName, page)
  if isUnique then
    table.insert(page.sets, setName)
    table.sort(page.sets)
  end
end

function XLGB_Page:RemoveSetFromPage(setName, pageName)
  local page = XLGB_Page:GetPage(pageName)
  local setIndex = GetSetIndexInPage(setName, page)
  if setIndex then
	  table.remove(page.sets, setIndex)
  end
end

function XLGB_Page:PageContainsSet(pageName, setName)
  local page = XLGB_Page:GetPage(pageName)
  for _, pageSetName in pairs(page.sets) do
    if setName == pageSetName then
      return true
    end
  end
  return false
end

function XLGB_Page:GetSetsInPage(pageName)
  local page = XLGB_Page:GetPage(pageName)
  return page.sets
end

-- function XLGB_Page:GetPageItems(pageName)
--   local page = XLGB_Page:GetPage(pageName)
--   local tempSet = {}
--   for _, set in pairs(page.sets) do
--   end
-- end

function XLGB_Page:GetAmountOfItemsInPage(pageName)
  local page = XLGB_Page:GetPage(pageName)
  local itemsInPage = 0
  for _, set in pairs(page.sets) do
      local gearSet = XLGB_GearSet:FindGearSet(set)
      itemsInPage = itemsInPage + #gearSet.items
  end
  return itemsInPage -- Returns non-unique items (i.e. can contain duplicates)
end

function XLGB_Page:GetMissingItemsInPage(fromBag, pageName, qualityFilter)
  local page = XLGB_Page:GetPage(pageName)
  local missingItemsInPage = {}
  local sets = {}
  for _, set in pairs(page.sets) do
    local setWithMissingItems = XLGB_GearSet:GetMissingItems(fromBag, XLGB_GearSet:GetGearSetIndex(set), qualityFilter)
    table.insert(sets, setWithMissingItems)
  end
  missingItemsInPage.name = pageName
  missingItemsInPage.sets = sets
  return missingItemsInPage
end

function XLGB_Page:DepositPage(pageName)
  if XLGB_Banking.isMovingItems then return end

  XLGB_Banking.isMoveCancelled = false
  XLGB_Page.isMovingPage = true
  XLGB_Events:OnPageDepositStart(pageName)
  local time = GetGameTimeMilliseconds()

  local page = XLGB_Page:GetPage(pageName)
  local nextIndex = 1

  local safeModeBefore = sV.safeMode

  local requiresSafeMode = XLGB_Page:GetAmountOfItemsInPage(pageName) > sV.threshold
  if requiresSafeMode then
    sV.safeMode = true
  end

  local function _lastSetFinish()
    if XLGB_Banking.isMovingItems then return end
    if not XLGB_Banking.isMoveCancelled then
      d("[XLGB] Page '" .. page.name .."' deposited in " .. tostring(string.format("%.2f", (GetGameTimeMilliseconds()-time)/1000)) .. " seconds.")
    else
      d("[XLGB_ERROR] Deposit of page '" .. page.name .. "' got cancelled. (" ..tostring(string.format("%.2f", (GetGameTimeMilliseconds()-time)/1000)) .. " seconds.)")
    end
    XLGB_Page.isMovingPage = false
    sV.safeMode = safeModeBefore
    XLGB_Events:OnPageDepositStop(pageName)
    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitLastSetFinish")
  end

  local function _waitDepositSet()
    if nextIndex > #page.sets or XLGB_Banking.isMoveCancelled then
      EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitDepositSet")
      EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "WaitLastSetFinish", 600, _lastSetFinish)
      return
    end
    if XLGB_Banking.isMovingItems then return end
    -- d("[XLGB] Depositing Page '" .. pageName .. "' [" .. tostring(nextIndex) .. "/" .. tostring(#page.sets) .. "] - " .. page.sets[nextIndex])
    XLGB_Banking:DepositSet(page.sets[nextIndex], sV and sV.pageDepositQualities)
    XLGB_Events:OnPageDepositNextSet(page.sets[nextIndex])
    nextIndex = nextIndex + 1
  end

  EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitDepositSet")
  EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "WaitDepositSet", 500, _waitDepositSet)
  _waitDepositSet()
end

function XLGB_Page:WithdrawPage(pageName)
  if XLGB_Banking.isMovingItems or XLGB_Page.isMovingPage then return end

  XLGB_Banking.isMoveCancelled = false
  XLGB_Page.isMovingPage = true
  XLGB_Events:OnPageWithdrawStart(pageName)
  local time = GetGameTimeMilliseconds()

  local page = XLGB_Page:GetPage(pageName)
  local nextIndex = 1

  local safeModeBefore = sV.safeMode

  local requiresSafeMode = XLGB_Page:GetAmountOfItemsInPage(pageName) > sV.threshold
  if requiresSafeMode then
    sV.safeMode = true
  end

  local function _lastSetFinish()
    if XLGB_Banking.isMovingItems then return end
    if not XLGB_Banking.isMoveCancelled then
      d("[XLGB] Page '" .. page.name .."' withdrawn in " .. tostring(string.format("%.2f", (GetGameTimeMilliseconds()-time)/1000)) .. " seconds.")
    else
      d("[XLGB_ERROR] Withdrawing of page '" .. page.name .. "' got cancelled. (" ..tostring(string.format("%.2f", (GetGameTimeMilliseconds()-time)/1000)) .. " seconds.)")
    end
    XLGB_Page.isMovingPage = false
    sV.safeMode = safeModeBefore
    XLGB_Events:OnPageWithdrawStop(pageName)
    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitLastSetFinish")
  end

  local function _waitWithdrawSet()
    if nextIndex > #page.sets or XLGB_Banking.isMoveCancelled then
      EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitWithdrawSet")
      EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitLastSetFinish")
      EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "WaitLastSetFinish", 600, _lastSetFinish)
      return
    end
    if XLGB_Banking.isMovingItems then return end
    -- d("[XLGB] Withdrawing Page '" .. pageName .. "' [" .. tostring(nextIndex) .. "/" .. tostring(#page.sets) .. "] - " .. page.sets[nextIndex])
    XLGB_Banking:WithdrawSet(page.sets[nextIndex], sV and sV.pageWithdrawQualities)
    XLGB_Events:OnPageWithdrawNextSet(page.sets[nextIndex])
    nextIndex = nextIndex + 1
  end

  EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "WaitWithdrawSet")
  EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "WaitWithdrawSet", 500, _waitWithdrawSet)
  _waitWithdrawSet()
end

function XLGB_Page:OnRemoveSet(setName)
  for _, page in pairs(XLGB_Page:GetAllPages()) do
      XLGB_Page:RemoveSetFromPage(setName, page.name)
  end
end

function XLGB_Page:OnGearSetNameChange(oldName, newName)
  for _, page in pairs(XLGB_Page:GetAllPages()) do
    for i, setName in pairs(page.sets) do
        if setName == oldName then
          page.sets[i] = newName
        end
    end
end
end

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

function XLGB_Page:CopyPageSet(pageName)
  return copy(XLGB_Page:GetPage(pageName).sets)
end

function XLGB_Page:Initialize()
  sV = XLGearBanker.savedVariables
  sV.pages = sV.pages or {}
  self.isMovingPage = false
end
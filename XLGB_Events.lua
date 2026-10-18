XLGB_Events = {}

function XLGB_Events:OnGearSetItemAdd(gearSetBefore, gearSetAfter)
  XLGB_UI:UpdateSetScrollList()
end

function XLGB_Events:OnGearSetItemRemove(gearSetBefore, gearSetAfter)
  XLGB_UI:UpdateSetScrollList()
end

function XLGB_Events:OnGearSetRemove(gearSetName)
  XLGB_Page:OnRemoveSet(gearSetName)
end

function XLGB_Events:OnGearSetSort(preSortList)
  XLGB_UI:OnGearSetSort(preSortList)
end

function XLGB_Events:OnGearSetNameChange(oldName, newName)
  XLGB_Page:OnGearSetNameChange(oldName, newName)
end

function XLGB_Events:OnPageSort(preSortList)
  XLGB_UI:OnPageSort(preSortList)
end

----
function XLGB_Events:OnPageWithdrawStart(pageName)
  XLGB_UI:OnPageWithdrawStart(pageName)
end

function XLGB_Events:OnPageWithdrawNextSet(nextSetName)
  XLGB_UI:OnPageWithdrawNextSet(nextSetName)
end

function XLGB_Events:OnPageWithdrawStop(pageName)
  XLGB_UI:OnPageWithdrawStop(pageName)
end

function XLGB_Events:OnSingleSetWithdrawStart(setName)
  XLGB_UI:OnSingleSetWithdrawStart(setName)
end

function XLGB_Events:OnSingleSetWithdrawStop(setName)
  XLGB_UI:OnSingleSetWithdrawStop(setName)
end
----

----
function XLGB_Events:OnPageDepositStart(pageName)
  XLGB_UI:OnPageDepositStart(pageName)
end

function XLGB_Events:OnPageDepositNextSet(nextSetName)
  XLGB_UI:OnPageDepositNextSet(nextSetName)
end

function XLGB_Events:OnPageDepositStop(pageName)
  XLGB_UI:OnPageDepositStop(pageName)
end

function XLGB_Events:OnSingleSetDepositStart(setName)
  XLGB_UI:OnSingleSetDepositStart(setName)
end

function XLGB_Events:OnSingleSetDepositStop(setName)
  XLGB_UI:OnSingleSetDepositStop(setName)
end
----

function XLGB_Events:OnMoveItem(targetBag, itemsLeft, bagSpaceLeft)
  XLGB_UI:OnMoveItem(targetBag, itemsLeft)
end



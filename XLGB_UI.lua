XLGB_UI = {}

local libDialog = LibDialog
local libSB = LibShifterBox
local LAM = LibAddonMenu2
local ui = {}
local sV = {}
local xl = {}
local setEditSetFalse
local setEditPageFalse

function XLGB_UI:ToggleSettings()
  LAM:OpenToPanel(XLGB_Settings.panel)
end

function XLGB_UI:XLGB_SetWindow_OnMoveStop()
  sV.setWindow_x = ui.set:GetLeft()
  sV.setWindow_y = ui.set:GetTop()
end

function XLGB_UI:XLGB_SetWindow_OnResizeStop()
  sV.setWindow_width = ui.set:GetWidth()
  sV.setWindow_height = ui.set:GetHeight()
  XLGB_UI:XLGB_SetWindow_OnMoveStop()
end

function XLGB_UI:XLGB_PageWindow_OnMoveStop()
  sV.pageWindow_x = ui.page:GetLeft()
  sV.pageWindow_y = ui.page:GetTop()
end

function XLGB_UI:OnPageSort(preSortList)
  local pageName = preSortList[sV.displayingPage]
  local newPageIndex = XLGB_Page:GetIndexOfPage(pageName)
  sV.displayingPage = newPageIndex
end

function XLGB_UI:OnGearSetSort(preSortList)
  local setName = preSortList[sV.displayingSet]
  local newSetIndex = XLGB_GearSet:GetGearSetIndex(setName)
  sV.displayingSet = newSetIndex
end

function XLGB_UI:RestorePosition()
  ui.set:ClearAnchors()
  ui.set:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, sV.setWindow_x, sV.setWindow_y)

  ui.set:SetWidth(sV.setWindow_width)
  ui.set:SetHeight(sV.setWindow_height)

  ui.page:ClearAnchors()
  ui.page:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, sV.pageWindow_x, sV.pageWindow_y)
end

local function reanchorScrollList(scrollList, top, bottom)
  scrollList:ClearAnchors()
  scrollList:SetAnchor(TOPLEFT, top, BOTTOMLEFT, 0, 10)
  scrollList:SetAnchor(BOTTOMRIGHT, bottom, TOPRIGHT, -21, -20)
end

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        PAGE WINDOW
--
--
--
--------------------------------------------------------------------------------------------

local function reanchorSetScrollList()
  local s = ui.set
  if not s then return end

  local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)
  local topControl = s.bankSetRow or s.setRow

  local bottomControl = s.totalSetItemsRow
  if xl.isSetEditable and s.addItemsRow then
    bottomControl = s.addItemsRow
  elseif isBankOpen and s.bankRow then
    bottomControl = s.bankRow
  end

  reanchorScrollList(s.scrollList, topControl, bottomControl)
  reanchorScrollList(s.empty, topControl, bottomControl)
end

local function refreshBankAndShifterRow()
  local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)
  ui.page.shifterRow:SetHidden(not xl.isPageEditable)
  ui.page.bankRow:SetHidden(xl.isPageEditable or (not isBankOpen))
  
  if ui.set then
    if ui.set.bankRow then
      ui.set.bankRow:SetHidden(xl.isSetEditable or (not isBankOpen))
    end
    if ui.set.bankSetRow then
      ui.set.bankSetRow:SetHidden(false)
      if ui.set.bankSetRow.selector then
        ui.set.bankSetRow.selector:SetHidden(false)
      end
    end
    reanchorSetScrollList()
  end
end

local function reanchorPageScrollList()
  local p = ui.page
  if xl.isPageEditable then
    reanchorScrollList(p.scrollList, p.pageRow, p.shifterRow)
    reanchorScrollList(p.empty, p.pageRow, p.shifterRow)
  elseif XLGB_Banking.bankOpen then
    reanchorScrollList(p.scrollList, p.pageRow, p.bankRow)
    reanchorScrollList(p.empty, p.pageRow, p.bankRow)
  else
    reanchorScrollList(p.scrollList, p.pageRow, p.totalPageItemsRow)
    reanchorScrollList(p.empty, p.pageRow, p.totalPageItemsRow)
  end
end

local function areThereAnySetChanges()
  if (ui.set.setRow.editName:GetText() == xl.oldSetName) and not (xl.itemChanges) then
    return false
  end
  return true
end

local function areThereAnyPageChanges()
  if (ui.page.pageRow.editName:GetText() == xl.oldPageName) and not (xl.pageSetChange) then
    return false
  end
  return true
end

function XLGB_UI:ShowOrHideEditPage()
  XLGB_UI:ShowOrHideEdit(ui.page.pageRow.edit, XLGB_Page:GetNumberOfPages())
end

function XLGB_UI:ShowOrHideEditSet()
  XLGB_UI:ShowOrHideEdit(ui.set.setRow.edit, XLGB_GearSet:GetNumberOfGearSets())
end

function XLGB_UI:ShowOrHideEdit(edit, numberOfPagesOrSets)
  local isEmpty = numberOfPagesOrSets == 0
  edit:SetHidden(isEmpty)
end

function XLGB_UI:OnBankOpen()
  if ui.set and ui.set.bankSetRow then
    ui.set.bankSetRow:SetHidden(false)
    if ui.set.bankSetRow.selector then
      ui.set.bankSetRow.selector:SetHidden(false)
    end
    XLGB_UI:UpdateBankSetDropdown()
  end
  refreshBankAndShifterRow()
  reanchorPageScrollList()
  reanchorSetScrollList()
  XLGB_UI:RefreshQualityFilters()
  if sV.showSetWindowOnOpen then
    XLGB_UI:ShowSetUI()
  end
  if sV.showPageWindowOnOpen then
    XLGB_UI:ShowPageUI()
  end
  if sV.showWardrobeWindowOnOpen and WizardsWardrobe then
    XLGB_UI:ShowWardrobeUI()
  elseif ui.wardrobe and not ui.wardrobe:IsHidden() then
    XLGB_UI:UpdateWardrobeUI()
  end
end

function XLGB_UI:OnBankClosed()
  if ui.set and ui.set.bankSetRow then
    XLGB_UI:UpdateBankSetDropdown()
  end
  refreshBankAndShifterRow()
  reanchorPageScrollList()
  reanchorSetScrollList()
  if not xl.isPageEditable then
    XLGB_UI:HidePageUI()
  end
  if not xl.isSetEditable then
    XLGB_UI:HideSetUI()
  end
  XLGB_UI:HideWardrobeUI()
  if XLGB_Wardrobe then
    XLGB_Wardrobe.selectedCharId = nil
  end
end

function XLGB_UI:DepositPage()
  if XLGB_Page:GetNumberOfPages() < 1 then
    return
  end
  XLGB_Page:DepositPage(XLGB_Page:GetPageByIndex(sV.displayingPage).name)
end

function XLGB_UI:WithdrawPage()
  if XLGB_Page:GetNumberOfPages() < 1 then
    return
  end
  XLGB_Page:WithdrawPage(XLGB_Page:GetPageByIndex(sV.displayingPage).name)
end

local function initiatePageShifterBoxEntries(pageNumber)
  local p = ui.page
  local pageName = XLGB_Page:GetPageByIndex(sV.displayingPage).name

  local left = {}
  local right = {}

  p.shifterBox:ClearLeftList()
  p.shifterBox:ClearRightList()
  p.shifterBox:UnselectAllEntries()

  for i = 1, XLGB_GearSet:GetNumberOfGearSets() do
    local setName = XLGB_GearSet:GetGearSet(i).name
    if XLGB_Page:PageContainsSet(pageName, setName) then
      table.insert(left, i, setName)
    else
      table.insert(right, i, setName)
    end
  end

  p.shifterBox:AddEntriesToLeftList(left)
  p.shifterBox:AddEntriesToRightList(right)
end

local function updatePageSetEntries()
  local sb = ui.page.shifterBox
  local chosenSets = sb:GetLeftListEntriesFull()
  local pageName = XLGB_Page:GetPageByIndex(sV.displayingPage).name
  XLGB_Page:ClearPage(pageName)
  for _, set in pairs(chosenSets) do
    XLGB_Page:AddSetToPage(set, pageName)
  end
end

function XLGB_UI:InitializePageShifterBox()
  local p = ui.page
  local customSettings = {
    showMoveAllButtons = true, -- the >> and << buttons to move all entries can be hidden if set to false
    dragDropEnabled = true, -- entries can be moved between lsit with drag-and-drop
    sortEnabled = true, -- sorting of the entries can be disabled
    sortBy = "value", -- sort the list by value or key (allowed are: "value" or "key")
    leftList = {
      -- list-specific settings that apply to the LEFT list
      title = "In", -- the title/header of the list
      rowHeight = 32, -- the height of an individual row/entry
      --rowTemplateName = "",               -- an individual XML (cirtual) control can be provided for the rows/entries
      emptyListText = GetString("No Sets"), -- the text to be displayed if there are no entries left in the list
      fontSize = 16 -- size of the font
    },
    rightList = {
      -- list-specific settings that apply to the RIGHT list
      title = "Out", -- the title/header of the list
      rowHeight = 32, -- the height of an individual row/entry
      -- rowTemplateName = "Page_ShifterBoxEntry_Template",    -- an individual XML (cirtual) control can be provided for the rows/entries
      emptyListText = GetString("All Sets"), -- the text to be displayed if there are no entries left in the list
      fontSize = 16 -- size of the font
    }
  }

  p.shifterBox = libSB.Create(XLGearBanker.name, "XLGB_Page_ShifterBox", ui.page, customSettings)
  p.shifterBox:SetAnchor(BOTTOM, ui.page.shifterRow, TOP, 0, -10)
  p.shifterBox:SetDimensions(310, 380)

  local function entryMoved(shifterBox, key, value, categoryId, isDestListLeftList)
    xl.pageSetChange = true
  end
  p.shifterBox:RegisterCallback(libSB.EVENT_ENTRY_MOVED, entryMoved)
  -- Temp fix for library
  -- local leftAllButton = XLGearBanker_XLGB_Page_ShifterBoxLeftAllButton
  -- leftAllButton:ClearAnchors()
  -- leftAllButton:SetAnchor(BOTTOM, XLGearBanker_XLGB_Page_ShifterBoxLeftButton, TOP, 0, -55)
  -----------------------

  p.shifterBox:SetHidden(true)
end

function XLGB_UI:SelectEntireTextbox(editBoxControl)
  editBoxControl:SelectAll()
end

local function refreshAddRemoveIcon(addRemoveControl, editable)
  if editable then
    addRemoveControl:SetNormalTexture("/esoui/art/buttons/pointsminus_up.dds")
    addRemoveControl:SetPressedTexture("/esoui/art/buttons/pointsminus_down.dds")
    addRemoveControl:SetMouseOverTexture("/esoui/art/buttons/pointsminus_over.dds")
  else
    addRemoveControl:SetNormalTexture("/esoui/art/buttons/pointsplus_up.dds")
    addRemoveControl:SetPressedTexture("/esoui/art/buttons/pointsplus_down.dds")
    addRemoveControl:SetMouseOverTexture("/esoui/art/buttons/pointsplus_over.dds")
  end
end

local function refreshEditIcon(editControl, editable)
  if editable then
    editControl:SetNormalTexture("/esoui/art/buttons/edit_cancel_up.dds")
    editControl:SetPressedTexture("/esoui/art/buttons/edit_cancel_down.dds")
    editControl:SetMouseOverTexture("/esoui/art/buttons/edit_cancel_over.dds")
  else
    editControl:SetNormalTexture("/esoui/art/buttons/edit_up.dds")
    editControl:SetPressedTexture("/esoui/art/buttons/edit_down.dds")
    editControl:SetMouseOverTexture("/esoui/art/buttons/edit_over.dds")
  end
end

setEditPageFalse = function()
  local p = ui.page
  xl.isPageEditable = false

  p.titleRow.title:SetText(XLGB_GetString("TITLE_PAGE"))

  p.pageRow.page:SetHidden(xl.isPageEditable) -- Hide dropdown

  p.pageRow.editName:SetHidden(not xl.isPageEditable) -- Make editName visible
  p.pageRow.editName:SetEditEnabled(xl.isPageEditable)
  p.pageRow.editName:SetMouseEnabled(xl.isPageEditable)
  p.pageRow.editName:SetCursorPosition(0)

  p.pageRow.accept:SetHidden(not xl.isPageEditable)
  p.totalPageItemsRow:SetHidden(xl.isPageEditable)

  refreshEditIcon(p.pageRow.edit, xl.isPageEditable)
  refreshAddRemoveIcon(p.pageRow.addRemovePage, xl.isPageEditable)

  p.shifterRow:SetHidden(true)
  p.shifterBox:SetHidden(true)
  p.scrollList:SetHidden(false)

  refreshBankAndShifterRow()
  reanchorPageScrollList()

  ZO_ScrollList_RefreshVisible(p.scrollList)
  ClearTooltip(InformationTooltip)
end

local function setEditPageTrue()
  local p = ui.page
  xl.isPageEditable = true
  xl.oldPageName = XLGB_Page:GetPageByIndex(sV.displayingPage).name

  p.titleRow.title:SetText(XLGB_GetString("TITLE_PAGE_EDIT"))

  p.pageRow.page:SetHidden(xl.isPageEditable) -- Hide dropdown

  p.pageRow.editName:SetHidden(not xl.isPageEditable) -- Make editName visible
  p.pageRow.editName:SetEditEnabled(xl.isPageEditable)
  p.pageRow.editName:SetText(xl.oldPageName)
  p.pageRow.editName:SelectAll()
  p.pageRow.editName:TakeFocus()
  p.pageRow.editName:SetMouseEnabled(xl.isPageEditable)

  p.pageRow.accept:SetHidden(not xl.isPageEditable)
  p.totalPageItemsRow:SetHidden(xl.isPageEditable)

  refreshEditIcon(p.pageRow.edit, xl.isPageEditable)
  refreshAddRemoveIcon(p.pageRow.addRemovePage, xl.isPageEditable)

  initiatePageShifterBoxEntries(sV.displayingPage)
  p.shifterBox:SetHidden(false)
  p.scrollList:SetHidden(true)

  p.empty:SetHidden(true)

  refreshBankAndShifterRow()
  reanchorPageScrollList()

  ZO_ScrollList_RefreshVisible(p.scrollList)
  ClearTooltip(InformationTooltip)
end

local function acceptPageChanges()
  local newPageName = ui.page.pageRow.editName:GetText()
  if XLGB_Page:SetPageName(xl.oldPageName, newPageName) then
    updatePageSetEntries()
    setEditPageFalse()
    ZO_ScrollList_RefreshVisible(ui.page.scrollList)
    XLGB_UI:UpdatePageDropdown()
    XLGB_UI:UpdatePageScrollList()
    d("[XLGB] Page succesfully changed!")
  else
    d("[XLGB] Name was not unique")
  end
end

function XLGB_UI:AcceptPageEdit()
  if areThereAnyPageChanges() then
    libDialog:ShowDialog("XLGearBanker", "AcceptPageChanges", nil)
  else
    acceptPageChanges()
  end
end

local function discardPageChanges()
  setEditPageFalse()
  XLGB_UI:UpdatePageDropdown()
  XLGB_UI:UpdatePageScrollList()
end

function XLGB_UI:TogglePageEdit()
  if xl.isPageEditable then
    if areThereAnyPageChanges() then
      libDialog:ShowDialog("XLGearBanker", "DiscardPageChangesDialog", nil)
    else
      discardPageChanges()
    end
  else
    xl.copyOfPageSet = XLGB_Page:CopyPageSet(XLGB_Page:GetPageByIndex(sV.displayingPage).name)
    xl.pageNameChange = false
    xl.pageSetChange = false
    setEditPageTrue()
  end
end

function XLGB_UI:AddRemovePage()
  if not xl.isPageEditable then
    XLGB_UI:AddPage()
  else
    XLGB_UI:RemovePage()
  end
end

function XLGB_UI:AddPage()
  local newPageName = XLGB_Page:CreatePage()
  sV.displayingPage = XLGB_Page:GetIndexOfPage(newPageName)
  XLGB_UI:SelectPage(sV.displayingPage)

  XLGB_UI:TogglePageEdit()
  XLGB_UI:ShowOrHideEditPage()
  XLGB_UI:UpdatePageDropdown()
  XLGB_UI:UpdatePageScrollList()
end

local function removePageConfirmed()
  local currentPage = XLGB_Page:GetPageByIndex(sV.displayingPage)
  if not currentPage then return end
  local pageName = currentPage.name
  local setsInPage = {}
  local pageSets = XLGB_Page:GetSetsInPage(pageName)
  if pageSets then
    for _, s in ipairs(pageSets) do
      table.insert(setsInPage, s)
    end
  end

  XLGB_Page:RemovePage(pageName)
  if setEditPageFalse then setEditPageFalse() end
  XLGB_UI:SelectPage(sV.displayingPage - 1)
  XLGB_UI:ShowOrHideEditPage()
  XLGB_UI:UpdatePageScrollList()
  XLGB_UI:UpdatePageDropdown()

  if #setsInPage > 0 then
    xl.deletedPageName = pageName
    xl.deletedPageSets = setsInPage
    local isWW = (string.sub(pageName, 1, 5) == "[WW] ")
    local dialogEntry = ESO_Dialogs["XLGearBanker_RemovePageSetsDialog"]
    if dialogEntry and dialogEntry.mainText then
      if isWW then
        dialogEntry.mainText.text = XLGB_GetString("DIALOG_DELETE_PAGE_WITH_SETS_WW_TEXT", pageName, #setsInPage)
      else
        dialogEntry.mainText.text = XLGB_GetString("DIALOG_DELETE_PAGE_WITH_SETS_TEXT", pageName, #setsInPage)
      end
    end
    zo_callLater(function()
      libDialog:ShowDialog("XLGearBanker", "RemovePageSetsDialog", nil)
    end, 150)
  end
end

function XLGB_UI:RemovePage()
  local currentPage = XLGB_Page:GetPageByIndex(sV.displayingPage)
  if not currentPage then return end
  local pageName = currentPage.name
  local pageSets = XLGB_Page:GetSetsInPage(pageName)

  if not pageSets or #pageSets == 0 then
    removePageConfirmed()
  else
    local dialogEntry = ESO_Dialogs["XLGearBanker_RemovePageDialog"]
    if dialogEntry and dialogEntry.mainText then
      dialogEntry.mainText.text = XLGB_GetString("DIALOG_DELETE_PAGE_TEXT", pageName)
    end
    libDialog:ShowDialog("XLGearBanker", "RemovePageDialog", nil)
  end
end

local function CreatePageTooltip(control, text, editText)
  control.tooltipText = text
  control.tooltipEditText = editText or text -- If no special edit text tooltip, then use default.

  local function ShowTooltip(self)
    local hl = self.GetNamedChild and self:GetNamedChild("_Highlight")
    if hl then hl:SetHidden(false) end
    InitializeTooltip(InformationTooltip, self, TOPRIGHT, 0, 5, BOTTOMRIGHT)
    local t = self.tooltipText
    if type(t) == "function" then
      t = t(self)
    end
    local e = self.tooltipEditText
    if type(e) == "function" then
      e = e(self)
    end
    if not xl.isPageEditable then
      SetTooltipText(InformationTooltip, t)
    else
      SetTooltipText(InformationTooltip, e)
    end
  end

  local function HideTooltip(self)
    local hl = self.GetNamedChild and self:GetNamedChild("_Highlight")
    if hl then hl:SetHidden(true) end
    ClearTooltip(InformationTooltip)
  end

  control:SetHandler("OnMouseEnter", ShowTooltip)
  control:SetHandler("OnMouseExit", HideTooltip)
end

local function InitPageWindowTooltips()
  CreatePageTooltip(ui.page.pageRow.edit, XLGB_GetString("PAGE_TOOLTIP_EDIT_CURRENT"), XLGB_GetString("PAGE_TOOLTIP_DISCARD"))
  CreatePageTooltip(ui.page.pageRow.accept, XLGB_GetString("PAGE_TOOLTIP_ACCEPT_CHANGES"))
  CreatePageTooltip(ui.page.pageRow.addRemovePage, XLGB_GetString("PAGE_TOOLTIP_CREATE_NEW"), XLGB_GetString("PAGE_TOOLTIP_REMOVE_CURRENT"))
  CreatePageTooltip(ui.page.shifterRow.setEditor, XLGB_GetString("PAGE_TOOLTIP_SET_EDITOR"))
  if ui.page.titleRow.settings then
    CreatePageTooltip(ui.page.titleRow.settings, XLGB_GetString("PAGE_TOOLTIP_SETTINGS"))
  end
  if ui.page.titleRow.wardrobe then
    CreatePageTooltip(ui.page.titleRow.wardrobe, XLGB_GetString("PAGE_TOOLTIP_TOGGLE_WARDROBE"))
  end
  CreatePageTooltip(ui.page.totalPageItemsRow.text, XLGB_GetString("PAGE_MAY_CONTAIN_DUPLICATES"))
  if ui.page.totalPageItemsRow.totalSets then
    CreatePageTooltip(ui.page.totalPageItemsRow.totalSets, XLGB_GetString("PAGE_TOOLTIP_TOTAL_SETS"))
  end
  if ui.page.bankRow then
    CreatePageTooltip(ui.page.bankRow.deposit, XLGB_GetString("SET_TOOLTIP_DEPOSIT_ACTIVE"))
    CreatePageTooltip(ui.page.bankRow.withdraw, XLGB_GetString("SET_TOOLTIP_WITHDRAW_ACTIVE"))
  end
end

function XLGB_UI:GetQualityFilter(moduleType, filterType)
  local isWithdraw = (filterType == "withdraw")
  if moduleType == "page" then
    return isWithdraw and sV.pageWithdrawQualities or sV.pageDepositQualities
  elseif moduleType == "set" then
    return isWithdraw and sV.setWithdrawQualities or sV.setDepositQualities
  elseif moduleType == "wardrobe" then
    return isWithdraw and sV.wardrobeWithdrawQualities or sV.wardrobeDepositQualities
  end
  return isWithdraw and sV.withdrawQualities or sV.depositQualities
end

function XLGB_UI:OnBankButtonMouseUp(control, mouseButton, filterType, moduleType)
  if mouseButton == 2 then
    XLGB_UI:ShowQualityContextMenu(control, filterType, moduleType or "page")
  end
end

function XLGB_UI:OnWardrobeBankButtonMouseUp(control, mouseButton, filterType)
  if mouseButton == 2 then
    if filterType == "prepare" then
      ClearMenu()
      AddCustomMenuItem(XLGB_GetString("WW_MENU_TITLE"), nil)
      AddCustomMenuItem(XLGB_GetString("WW_MENU_WITHDRAW"), function()
        XLGB_UI:ShowQualityContextMenu(control, "withdraw", "wardrobe")
      end)
      AddCustomMenuItem(XLGB_GetString("WW_MENU_DEPOSIT"), function()
        XLGB_UI:ShowQualityContextMenu(control, "deposit", "wardrobe")
      end)
      ShowMenu(control)
    else
      XLGB_UI:ShowQualityContextMenu(control, filterType, "wardrobe")
    end
  end
end

local function getFilterSummary(qualityTable)
  if not qualityTable then return XLGB_GetString("QUALITY_SUMMARY_ALL"), "|c00ff00" end
  local count = 0
  for q = 1, 5 do
    if qualityTable[q] then count = count + 1 end
  end
  if count == 5 then
    return XLGB_GetString("QUALITY_SUMMARY_ALL"), "|c00ff00"
  elseif count == 0 then
    return XLGB_GetString("QUALITY_SUMMARY_BLOCKED"), "|cff5555"
  elseif count == 1 and qualityTable[5] then
    return XLGB_GetString("QUALITY_SUMMARY_GOLD_ONLY"), "|cffd700"
  elseif count == 4 and not qualityTable[5] then
    return XLGB_GetString("QUALITY_SUMMARY_NO_GOLD"), "|cffffff"
  elseif count == 2 and qualityTable[4] and qualityTable[5] then
    return XLGB_GetString("QUALITY_SUMMARY_EPIC_LEGENDARY"), "|ca02ef7"
  elseif count == 4 and not qualityTable[1] then
    return XLGB_GetString("QUALITY_SUMMARY_FINE_TO_GOLD"), "|c2dc50e"
  else
    return string.format(XLGB_GetString("QUALITY_SUMMARY_ACTIVE_COUNT"), count), "|ce6cc80"
  end
end

local function onQualityDropdownMouseEnter(control, filterType, moduleType)
  local isWithdraw = (filterType == "withdraw")
  local qualityTable = XLGB_UI:GetQualityFilter(moduleType, filterType)
  local modNames = { page = XLGB_GetString("SET_MOD_PAGES"), set = XLGB_GetString("SET_MOD_SETS"), wardrobe = XLGB_GetString("SET_MOD_WARDROBE") }
  local modLabel = modNames[moduleType] or "XLGB"
  local title = isWithdraw and string.format(XLGB_GetString("QUALITY_TOOLTIP_TITLE_WITHDRAW"), modLabel) or string.format(XLGB_GetString("QUALITY_TOOLTIP_TITLE_DEPOSIT"), modLabel)

  InitializeTooltip(InformationTooltip, control, TOP, 0, -10)
  InformationTooltip:AddLine(title, "ZoFontHeader")
  InformationTooltip:AddLine(XLGB_GetString("QUALITY_TOOLTIP_DESC"), "ZoFontGameSmall")
  InformationTooltip:AddLine("----------------------------------------", "ZoFontGameSmall")

  for q = 1, 5 do
    local isActive = qualityTable and (qualityTable[q] == true)
    local qName = GetString("SI_ITEMDISPLAYQUALITY", q)
    if not qName or qName == "" then qName = GetString("SI_ITEMQUALITY", q) end
    local color = GetItemQualityColor(q)
    local colored = color and color:Colorize(qName) or qName
    local status = isActive and ("|c00ff00" .. XLGB_GetString("QUALITY_STATUS_ACTIVE") .. "|r") or ("|c666666" .. XLGB_GetString("QUALITY_STATUS_INACTIVE") .. "|r")
    InformationTooltip:AddLine(status .. " " .. colored, "ZoFontGameSmall")
  end

  InformationTooltip:AddLine("----------------------------------------", "ZoFontGameSmall")
  InformationTooltip:AddLine(XLGB_GetString("QUALITY_TOOLTIP_HINT_LEFT"), "ZoFontGameSmall")
  InformationTooltip:AddLine(XLGB_GetString("QUALITY_TOOLTIP_HINT_RIGHT"), "ZoFontGameSmall")
end

local function onQualityDropdownMouseExit(control)
  ClearTooltip(InformationTooltip)
end

function XLGB_UI:ShowQualityContextMenu(anchorControl, filterType, moduleType)
  ClearMenu()

  local isWithdraw = (filterType == "withdraw")
  local qualityTable = XLGB_UI:GetQualityFilter(moduleType, filterType)
  if not qualityTable then return end

  local modNames = { page = XLGB_GetString("SET_MOD_PAGES"), set = XLGB_GetString("SET_MOD_SETS"), wardrobe = XLGB_GetString("SET_MOD_WARDROBE") }
  local modLabel = modNames[moduleType] or "XLGB"
  local title = isWithdraw and string.format(XLGB_GetString("QUALITY_MENU_TITLE_WITHDRAW"), modLabel) or string.format(XLGB_GetString("QUALITY_MENU_TITLE_DEPOSIT"), modLabel)
  local act = isWithdraw and XLGB_GetString("QUALITY_ACTION_WITHDRAW") or XLGB_GetString("QUALITY_ACTION_DEPOSIT")
  AddCustomMenuItem("|cffffaa=== " .. title .. " ===|r", nil)

  AddCustomMenuItem("|cffd700" .. string.format(XLGB_GetString("QUALITY_PRESET_GOLD_ONLY"), act) .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q == 5) end
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
  end)

  AddCustomMenuItem("|cffffff" .. string.format(XLGB_GetString("QUALITY_PRESET_NO_GOLD"), act) .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q ~= 5) end
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
  end)

  AddCustomMenuItem("|ca02ef7" .. XLGB_GetString("QUALITY_PRESET_EPIC_LEGENDARY") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q >= 4) end
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
  end)

  AddCustomMenuItem("|c2dc50e" .. XLGB_GetString("QUALITY_PRESET_FINE_TO_GOLD") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q >= 2) end
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
  end)

  AddCustomMenuItem("|c00ff00" .. XLGB_GetString("QUALITY_PRESET_ALLOW_ALL") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = true end
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
  end)

  AddCustomMenuItem("|cff5555" .. XLGB_GetString("QUALITY_PRESET_DENY_ALL") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = false end
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
  end)

  AddCustomMenuItem("-", nil)

  for q = 1, 5 do
    local qualityIndex = q
    local isActive = (qualityTable[qualityIndex] == true)
    local checkTexture = isActive
      and "|t16:16:/esoui/art/buttons/checkbox_checked.dds|t "
      or "|t16:16:/esoui/art/buttons/checkbox_unchecked.dds|t "

    local qualityName = GetString("SI_ITEMDISPLAYQUALITY", qualityIndex)
    if not qualityName or qualityName == "" then
      qualityName = GetString("SI_ITEMQUALITY", qualityIndex)
    end
    local color = GetItemQualityColor(qualityIndex)
    local coloredName = color and color:Colorize(qualityName) or qualityName

    AddCustomMenuItem(checkTexture .. coloredName, function()
      qualityTable[qualityIndex] = not qualityTable[qualityIndex]
      XLGB_UI:RefreshQualityFilters()
      if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
    end)
  end

  ShowMenu(anchorControl)
end

local function setupQualityDropdownItems(comboBoxObj, filterType, containerCtrl, moduleType)
  local isWithdraw = (filterType == "withdraw")
  local qualityTable = XLGB_UI:GetQualityFilter(moduleType, filterType)
  if not qualityTable then return end

  comboBoxObj:ClearItems()
  comboBoxObj:SetFont("ZoFontGameSmall")

  local act = isWithdraw and XLGB_GetString("QUALITY_ACTION_WITHDRAW") or XLGB_GetString("QUALITY_ACTION_DEPOSIT")
  local onFilterChanged = function()
    XLGB_UI:RefreshQualityFilters()
    if moduleType == "wardrobe" and XLGB_UI.UpdateWardrobeUI then
      XLGB_UI:UpdateWardrobeUI()
    end
  end

  -- 1. Tout autoriser
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|c00ff00" .. XLGB_GetString("QUALITY_PRESET_ALLOW_ALL") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = true end
    onFilterChanged()
  end), ZO_COMBOBOX_SUPRESS_UPDATE)

  -- 2. Tout sauf Or
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|cffffff" .. string.format(XLGB_GetString("QUALITY_PRESET_NO_GOLD"), act) .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q ~= 5) end
    onFilterChanged()
  end), ZO_COMBOBOX_SUPRESS_UPDATE)

  -- 3. Seulement Or
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|cffd700" .. string.format(XLGB_GetString("QUALITY_PRESET_GOLD_ONLY"), act) .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q == 5) end
    onFilterChanged()
  end), ZO_COMBOBOX_SUPRESS_UPDATE)

  -- 4. Violet & Or
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|ca02ef7" .. XLGB_GetString("QUALITY_PRESET_EPIC_LEGENDARY") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q >= 4) end
    onFilterChanged()
  end), ZO_COMBOBOX_SUPRESS_UPDATE)

  -- 5. Vert à Or
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|c2dc50e" .. XLGB_GetString("QUALITY_PRESET_FINE_TO_GOLD") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = (q >= 2) end
    onFilterChanged()
  end), ZO_COMBOBOX_SUPRESS_UPDATE)

  -- 6. Tout refuser
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|cff5555" .. XLGB_GetString("QUALITY_PRESET_DENY_ALL") .. "|r", function()
    for q = 1, 5 do qualityTable[q] = false end
    onFilterChanged()
  end), ZO_COMBOBOX_SUPRESS_UPDATE)

  -- 7. Personnaliser...
  comboBoxObj:AddItem(ZO_ComboBox:CreateItemEntry("|cffecbc" .. XLGB_GetString("QUALITY_PRESET_CUSTOMIZE") .. "|r", function()
    XLGB_UI:ShowQualityContextMenu(containerCtrl, filterType, moduleType)
  end), ZO_COMBOBOX_SUPRESS_UPDATE)
end

function XLGB_UI:InitializeQualityDropdowns()
  local entries = {
    { ctrl = XLGB_PageWindow_BankRow_WithdrawQuality, fType = "withdraw", mod = "page" },
    { ctrl = XLGB_PageWindow_BankRow_DepositQuality,  fType = "deposit",  mod = "page" },
    { ctrl = XLGB_SetWindow_BankRow_WithdrawQuality,  fType = "withdraw", mod = "set" },
    { ctrl = XLGB_SetWindow_BankRow_DepositQuality,   fType = "deposit",  mod = "set" },
    { ctrl = XLGB_WardrobeWindow_FilterRow_WithdrawQuality or XLGB_WardrobeWindow_WithdrawQuality, fType = "withdraw", mod = "wardrobe" },
    { ctrl = XLGB_WardrobeWindow_FilterRow_DepositQuality or XLGB_WardrobeWindow_DepositQuality,  fType = "deposit",  mod = "wardrobe" },
  }

  for _, e in ipairs(entries) do
    local c = e.ctrl
    if c and not c.dropdown then
      c.dropdown = ZO_ComboBox_ObjectFromContainer(c)
      if c.dropdown then
        c.dropdown:SetFont("ZoFontGameSmall")
      end
      c:SetHandler("OnMouseEnter", function(self) onQualityDropdownMouseEnter(self, e.fType, e.mod) end)
      c:SetHandler("OnMouseExit", function(self) onQualityDropdownMouseExit(self) end)
      c:SetHandler("OnMouseUp", function(self, button, upInside)
        if button == 2 then
          XLGB_UI:ShowQualityContextMenu(self, e.fType, e.mod)
        end
      end)
    end
  end
end

function XLGB_UI:RefreshQualityFilters()
  XLGB_UI:InitializeQualityDropdowns()

  local dropdownEntries = {
    { container = XLGB_PageWindow_BankRow_WithdrawQuality, mod = "page",     fType = "withdraw" },
    { container = XLGB_PageWindow_BankRow_DepositQuality,  mod = "page",     fType = "deposit" },
    { container = XLGB_SetWindow_BankRow_WithdrawQuality,  mod = "set",      fType = "withdraw" },
    { container = XLGB_SetWindow_BankRow_DepositQuality,   mod = "set",      fType = "deposit" },
    { container = XLGB_WardrobeWindow_FilterRow_WithdrawQuality or XLGB_WardrobeWindow_WithdrawQuality, mod = "wardrobe", fType = "withdraw" },
    { container = XLGB_WardrobeWindow_FilterRow_DepositQuality or XLGB_WardrobeWindow_DepositQuality,  mod = "wardrobe", fType = "deposit" },
  }

  for _, entry in ipairs(dropdownEntries) do
    if entry.container and entry.container.dropdown then
      local dd = entry.container.dropdown
      local filter = XLGB_UI:GetQualityFilter(entry.mod, entry.fType)
      setupQualityDropdownItems(dd, entry.fType, entry.container, entry.mod)
      local summaryText, colorTag = getFilterSummary(filter)
      local prefix = (entry.mod == "wardrobe") and (entry.fType == "withdraw" and XLGB_GetString("QUALITY_PREFIX_WITHDRAW") or XLGB_GetString("QUALITY_PREFIX_DEPOSIT")) or ""
      dd:SetSelectedItemText(prefix .. colorTag .. summaryText .. "|r")
    end
  end
end

function XLGB_UI:SelectPage(pageNumber)
  local totalPages = XLGB_Page:GetNumberOfPages()

  if totalPages == 0 then
    sV.displayingPage = 0
  elseif pageNumber < 1 then
    sV.displayingPage = 1
  elseif pageNumber > totalPages then
    sV.displayingPage = totalPages
  else
    sV.displayingPage = pageNumber
  end

  XLGB_UI:UpdatePageScrollList()
end

function XLGB_UI:UpdatePageDropdown()
  local dd = ui.page.pageRow.page.dropdown
  dd:ClearItems()
  for i = 1, XLGB_Page:GetNumberOfPages() do
    local entry =
      ZO_ComboBox:CreateItemEntry(
      XLGB_Page:GetPageByIndex(i).name,
      function()
        XLGB_UI:SelectPage(i)
      end
    )
    dd:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
  end
  if XLGB_Page:GetNumberOfPages() > 0 and sV.displayingPage and sV.displayingPage > 0 then
    dd:SelectItemByIndex(sV.displayingPage, true)
  end
end

function XLGB_UI:InitializePageDropdown()
  local p = ui.page.pageRow.page
  p.dropdown = ZO_ComboBox_ObjectFromContainer(p)
end

function XLGB_UI:UpdatePageScrollList()
  local p = ui.page
  local scrollData = ZO_ScrollList_GetDataList(p.scrollList)
  ZO_ScrollList_Clear(p.scrollList)
  local totalItems = 0
  if XLGB_Page:GetNumberOfPages() > 0 and sV.displayingPage and sV.displayingPage > 0 then
    local page = XLGB_Page:GetPageByIndex(sV.displayingPage)
    if page then
      for _, set in pairs(XLGB_Page:GetSetsInPage(page.name)) do
        local dataEntry =
          ZO_ScrollList_CreateDataEntry(
          XLGB_Constants.PAGE_ITEM_ROW,
          {
            setName = set
          }
        )
        table.insert(scrollData, dataEntry)
      end
      totalItems = XLGB_Page:GetAmountOfItemsInPage(page.name)
      if (#scrollData < 1) and not xl.isPageEditable then
        p.empty:SetHidden(false)
      else
        p.empty:SetHidden(true)
      end
    end
  else
    p.empty:SetHidden(false)
  end
  ZO_ScrollList_Commit(p.scrollList)
  local totalSetsInPage = #scrollData
  if p.totalPageItemsRow.totalSets then
    p.totalPageItemsRow.totalSets:SetText(string.format(XLGB_GetString("PAGE_TOTAL_SETS"), totalSetsInPage))
  end
  p.totalPageItemsRow.text:SetText(string.format(XLGB_GetString("PAGE_TOTAL_ITEMS"), totalItems))
end

function XLGB_UI:WithdrawSet(withdrawControl)
  local data = withdrawControl:GetParent().data
  XLGB_Banking:WithdrawSet(data.setName, sV and sV.pageWithdrawQualities)
end

function XLGB_UI:DepositSet(depositControl)
  local data = depositControl:GetParent().data
  XLGB_Banking:DepositSet(data.setName, sV and sV.pageDepositQualities)
end

function XLGB_UI:DepositCurrentSet()
  if XLGB_GearSet:GetNumberOfGearSets() < 1 then return end
  local currentSet = XLGB_GearSet:GetGearSet(sV.displayingSet)
  if currentSet and currentSet.name then
    XLGB_Banking:DepositSet(currentSet.name, sV and sV.setDepositQualities)
  end
end

function XLGB_UI:WithdrawCurrentSet()
  if XLGB_GearSet:GetNumberOfGearSets() < 1 then return end
  local currentSet = XLGB_GearSet:GetGearSet(sV.displayingSet)
  if currentSet and currentSet.name then
    XLGB_Banking:WithdrawSet(currentSet.name, sV and sV.setWithdrawQualities)
  end
end

local function _showPageHighlight(control)
  control:GetNamedChild("_Highlight"):SetHidden(false)
end

local function _hidePageHighlight(control)
  control:GetNamedChild("_Highlight"):SetHidden(true)
end

local function fillPageItemRowWithData(control, data)
  control.data = data
  local gearSet = XLGB_GearSet:FindGearSet(data.setName)
  -- local gearSetIndex = XLGB_GearSet:GetGearSetIndex(data.setName)

  local nameCtrl = control:GetNamedChild("_Name")
  if nameCtrl then
    nameCtrl:SetText("|cffecbc" .. tostring(data.setName or "") .. "|r")
    nameCtrl:SetHidden(false)
  end
  local itemCount = (gearSet and gearSet.items and #gearSet.items) or 0
  control:GetNamedChild("_ItemsInSet"):SetText("Items: " .. tostring(itemCount))

  --
  local function toggleSetUI(self)
    local gearSetIndex = XLGB_GearSet:GetGearSetIndex(self.data.setName)
    if gearSetIndex == sV.displayingSet then
      XLGB_UI:ToggleSetUI()
    else
      XLGB_UI:SelectSet(gearSetIndex)
      XLGB_UI:ShowSetUI()
      XLGB_UI:UpdateSetDropdown()
    end
  end
  control:SetMouseEnabled(true)
  control:SetHandler("OnMouseUp", toggleSetUI)

  --

  control:SetHandler("OnMouseEnter", function(ctrl)
    _showPageHighlight(ctrl)
    if data and data.setName and data.setName ~= "" then
      InitializeTooltip(InformationTooltip, ctrl, TOPRIGHT, 0, 5, BOTTOMRIGHT)
      SetTooltipText(InformationTooltip, data.setName)
    end
  end)
  control:SetHandler("OnMouseExit", function(ctrl)
    _hidePageHighlight(ctrl)
    ClearTooltip(InformationTooltip)
  end)

  --

  local function ShowTooltip(self)
    InitializeTooltip(InformationTooltip, self, TOPRIGHT, 0, 5, BOTTOMRIGHT)
    if not xl.isPageEditable then
      SetTooltipText(InformationTooltip, self.tooltipText)
      _showPageHighlight(control)
    else
      SetTooltipText(InformationTooltip, self.tooltipEditText)
      _showPageHighlight(control)
    end
  end

  local function HideTooltip(self)
    ClearTooltip(InformationTooltip)
    _hidePageHighlight(control)
  end

  local withdrawControl = control:GetNamedChild("_Withdraw")
  withdrawControl.tooltipText = "Withdraw " .. data.setName
  withdrawControl:SetHandler("OnMouseEnter", ShowTooltip)
  withdrawControl:SetHandler("OnMouseExit", HideTooltip)

  local depositControl = control:GetNamedChild("_Deposit")
  depositControl.tooltipText = "Deposit " .. data.setName
  depositControl:SetHandler("OnMouseEnter", ShowTooltip)
  depositControl:SetHandler("OnMouseExit", HideTooltip)
end

function XLGB_UI:InitializePageScrollList()
  ZO_ScrollList_AddDataType(
    ui.page.scrollList,
    XLGB_Constants.PAGE_ITEM_ROW,
    "XLGB_Page_SetEntry_Template",
    64,
    fillPageItemRowWithData
  )
  ZO_ScrollList_EnableHighlight(ui.page.scrollList, "ZO_ThinListHighlight")
  XLGB_UI:UpdatePageScrollList()
end

function XLGB_UI:ShowPageUI()
  XLGB_UI:ShowOrHideEditPage()
  ui.page:SetHidden(false)
  XLGB_UI:UpdatePageScrollList()
end

function XLGB_UI:HidePageUI()
  if xl.isPageEditable and areThereAnyPageChanges() then
    libDialog:ShowDialog("XLGearBanker", "DiscardPageChangesDialog", nil)
  else
    setEditPageFalse()
    ui.page:SetHidden(true)
  end
end

function XLGB_UI:TogglePageUI()
  if ui.page:IsHidden() then
    XLGB_UI:ShowPageUI()
  else
    XLGB_UI:HidePageUI()
  end
end

function XLGB_UI:ToggleAllUI()
  local isPageVisible = (ui.page and not ui.page:IsHidden())
  local isSetVisible = (ui.set and not ui.set:IsHidden())
  local isWardrobeVisible = (ui.wardrobe and not ui.wardrobe:IsHidden())

  if isPageVisible or isSetVisible or isWardrobeVisible then
    XLGB_UI:HidePageUI()
    XLGB_UI:HideSetUI()
    XLGB_UI:HideWardrobeUI()
  else
    XLGB_UI:ShowSetUI()
    if WizardsWardrobe and sV.showWardrobeWindowOnOpen then
      XLGB_UI:ShowWardrobeUI()
    end
    if sV.showPageWindowOnOpen then
      XLGB_UI:ShowPageUI()
    end
  end
end

function XLGB_UI:SetupPageDialogs()
  local removePageDialog = libDialog:RegisterDialog(
    "XLGearBanker",
    "RemovePageDialog",
    XLGB_GetString("TITLE_PAGE"),
    XLGB_GetString("DIALOG_DELETE_PAGE_CONFIRM_SIMPLE"),
    removePageConfirmed,
    nil,
    nil,
    true
  )
  if removePageDialog and removePageDialog.buttons then
    if removePageDialog.buttons[1] then removePageDialog.buttons[1].text = XLGB_GetString("DIALOG_DELETE_PAGE_BTN_DELETE") end
    if removePageDialog.buttons[2] then removePageDialog.buttons[2].text = XLGB_GetString("DIALOG_CANCEL") end
  end

  local removeSetsDialog = libDialog:RegisterDialog(
    "XLGearBanker",
    "RemovePageSetsDialog",
    XLGB_GetString("TITLE_PAGE"),
    XLGB_GetString("DIALOG_DELETE_PAGE_CONFIRM_SIMPLE"),
    function()
      if xl.deletedPageSets and #xl.deletedPageSets > 0 then
        local count = 0
        local isDeletedPageWW = (string.sub(xl.deletedPageName or "", 1, 5) == "[WW] ")
        for _, setName in ipairs(xl.deletedPageSets) do
          local gsIndex = XLGB_GearSet:GetGearSetIndex(setName)
          if gsIndex and gsIndex > 0 then
            local gs = XLGB_GearSet:GetGearSet(gsIndex)
            -- Si la page supprimée est une page WW, on ne supprime STRICTEMENT que ses sets d'importation WW
            if gs and (not isDeletedPageWW or string.sub(gs.name or "", 1, 5) == "[WW] ") then
              XLGB_GearSet:RemoveGearSet(gsIndex)
              count = count + 1
            end
          end
        end
        xl.deletedPageSets = nil
        xl.deletedPageName = nil
        if setEditSetFalse then setEditSetFalse() end
        local totalSets = XLGB_GearSet:GetNumberOfGearSets()
        local newSetIndex = math.max(1, math.min(sV.displayingSet or 1, totalSets))
        XLGB_UI:SelectSet(newSetIndex)
        XLGB_UI:ShowOrHideEditSet()
        XLGB_UI:UpdateSetDropdown()
        XLGB_UI:UpdateSetScrollList()
        XLGB_UI:UpdatePageScrollList()
        d(string.format(XLGB_GetString("PAGE_SETS_DELETED"), count))
      end
    end,
    function()
      xl.deletedPageSets = nil
      xl.deletedPageName = nil
    end,
    nil,
    true
  )
  if removeSetsDialog and removeSetsDialog.buttons then
    if removeSetsDialog.buttons[1] then removeSetsDialog.buttons[1].text = XLGB_GetString("DIALOG_DELETE_PAGE_SETS_BTN_DELETE") end
    if removeSetsDialog.buttons[2] then removeSetsDialog.buttons[2].text = XLGB_GetString("DIALOG_DELETE_PAGE_SETS_BTN_KEEP") end
  end

  libDialog:RegisterDialog(
    "XLGearBanker",
    "AcceptPageChanges",
    XLGB_GetString("TITLE_PAGE"),
    XLGB_GetString("DIALOG_ACCEPT_PAGE_CHANGES"),
    acceptPageChanges,
    nil,
    nil
  )

  libDialog:RegisterDialog(
    "XLGearBanker",
    "DiscardPageChangesDialog",
    XLGB_GetString("TITLE_PAGE"),
    XLGB_GetString("DIALOG_DISCARD_PAGE_BODY"),
    discardPageChanges,
    nil,
    nil
  )
end

local function InitUIPageVariables()
  ui.page = XLGB_PageWindow

  ui.page.titleRow = XLGB_PageWindow_TitleRow
  ui.page.titleRow.title = XLGB_PageWindow_TitleRow_Title
  ui.page.titleRow.hide = XLGB_PageWindow_TitleRow_Hide
  if ui.page.titleRow.title then
    ui.page.titleRow.title:SetText(XLGB_GetString("TITLE_PAGE"))
  end

  ui.page.pageRow = XLGB_PageWindow_PageRow
  ui.page.pageRow.edit = XLGB_PageWindow_PageRow_EditPage
  ui.page.pageRow.editName = XLGB_PageWindow_PageRow_EditPageName
  ui.page.pageRow.page = XLGB_PageWindow_PageRow_Page
  ui.page.pageRow.accept = XLGB_PageWindow_PageRow_AcceptPage
  ui.page.pageRow.addRemovePage = XLGB_PageWindow_PageRow_AddRemovePage

  ui.page.scrollList = XLGB_PageWindow_ScrollList

  ui.page.empty = XLGB_PageWindow_EmptyRow

  ui.page.bankRow = XLGB_PageWindow_BankRow
  ui.page.bankRow.deposit = XLGB_PageWindow_BankRow_DepositPage
  ui.page.bankRow.withdraw = XLGB_PageWindow_BankRow_WithdrawPage
  ui.page.bankRow.withdrawQuality = XLGB_PageWindow_BankRow_WithdrawQuality
  ui.page.bankRow.depositQuality = XLGB_PageWindow_BankRow_DepositQuality

  ui.page.shifterRow = XLGB_PageWindow_ShifterRow
  ui.page.shifterRow.setEditor = XLGB_PageWindow_ShifterRow_SetEditor

  ui.page.totalPageItemsRow = XLGB_PageWindow_TotalPageItemsRow
  ui.page.totalPageItemsRow.text = XLGB_PageWindow_TotalPageItemsRow_TotalPageItems
  ui.page.totalPageItemsRow.totalSets = XLGB_PageWindow_TotalPageItemsRow_TotalPageSets

  if ui.page.bankRow.deposit and ui.page.bankRow.deposit:GetNamedChild("_Label") then
    ui.page.bankRow.deposit:GetNamedChild("_Label"):SetText(XLGB_GetString("PAGE_DEPOSIT"))
  end
  if ui.page.bankRow.withdraw and ui.page.bankRow.withdraw:GetNamedChild("_Label") then
    ui.page.bankRow.withdraw:GetNamedChild("_Label"):SetText(XLGB_GetString("PAGE_WITHDRAW"))
  end
  if ui.page.shifterRow.setEditor and ui.page.shifterRow.setEditor:GetNamedChild("_Label") then
    ui.page.shifterRow.setEditor:GetNamedChild("_Label"):SetText(XLGB_GetString("PAGE_SET_EDITOR"))
  end
  if ui.page.empty and ui.page.empty:GetNamedChild("_Label") then
    ui.page.empty:GetNamedChild("_Label"):SetText(XLGB_GetString("PAGE_EMPTY"))
  end
end

--------------------------------------------------------------------------------------------
-- PAGE WINDOW END
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        SET WINDOW
--
--
--
--
--------------------------------------------------------------------------------------------

setEditSetFalse = function()
  local s = ui.set
  xl.isSetEditable = false

  s.titleRow.title:SetText(XLGB_GetString("TITLE_SET"))

  s.setRow.set:SetHidden(false) -- Make dropdown visible

  s.setRow.editName:SetHidden(true) -- hide editName
  s.setRow.editName:SetEditEnabled(false)
  s.setRow.editName:SetMouseEnabled(false)
  s.setRow.editName:SetCursorPosition(0)

  s.setRow.accept:SetHidden(true)

  refreshEditIcon(s.setRow.edit, xl.isSetEditable)
  refreshAddRemoveIcon(s.setRow.addRemoveSet, xl.isSetEditable)

  s.addItemsRow:SetHidden(true)
  if s.bankRow then
    s.bankRow:SetHidden(not XLGB_Banking.bankOpen)
  end
  if s.bankSetRow then
    s.bankSetRow:SetHidden(false)
    if s.bankSetRow.selector then
      s.bankSetRow.selector:SetHidden(false)
    end
  end

  reanchorSetScrollList()
  ZO_ScrollList_RefreshVisible(s.scrollList)
  ClearTooltip(InformationTooltip)
end

local function setEditSetTrue()
  local s = ui.set
  xl.isSetEditable = true
  xl.oldSetName = XLGB_GearSet:GetGearSet(sV.displayingSet).name

  s.titleRow.title:SetText(XLGB_GetString("TITLE_SET_EDIT"))

  s.setRow.set:SetHidden(true) -- Hide dropdown

  s.setRow.editName:SetHidden(false) -- Make editName visible
  s.setRow.editName:SetEditEnabled(true)
  s.setRow.editName:SetText(xl.oldSetName)
  s.setRow.editName:SelectAll()
  s.setRow.editName:TakeFocus()
  s.setRow.editName:SetMouseEnabled(true)

  s.setRow.accept:SetHidden(false)

  refreshEditIcon(s.setRow.edit, xl.isSetEditable)
  refreshAddRemoveIcon(s.setRow.addRemoveSet, xl.isSetEditable)

  s.addItemsRow:SetHidden(false)
  if s.bankRow then
    s.bankRow:SetHidden(true)
  end
  if s.bankSetRow then
    s.bankSetRow:SetHidden(false)
    if s.bankSetRow.selector then
      s.bankSetRow.selector:SetHidden(false)
    end
  end

  s.empty:SetHidden(true)

  reanchorSetScrollList()
  ZO_ScrollList_RefreshVisible(s.scrollList)
  ClearTooltip(InformationTooltip)
end

local function acceptSetChanges()
  local newGearName = ui.set.setRow.editName:GetText()
  if XLGB_GearSet:EditGearSetName(newGearName, sV.displayingSet) then
    xl.copyOfSet = {}
    setEditSetFalse()
    initiatePageShifterBoxEntries()
    ZO_ScrollList_RefreshVisible(ui.set.scrollList)
    XLGB_UI:UpdateSetDropdown()
    XLGB_UI:UpdateSetScrollList()
    XLGB_UI:UpdatePageScrollList()
    d(XLGB_GetString("SET_SUCCESSFULLY_CHANGED"))
  else
    d(XLGB_GetString("SET_NAME_NOT_UNIQUE"))
  end
end

function XLGB_UI:AcceptSetEdit()
  if areThereAnySetChanges() then
    libDialog:ShowDialog("XLGearBanker", "AcceptSetChanges", nil)
  else
    acceptSetChanges()
  end
end

local function discardSetChanges()
  sV.gearSetList[sV.displayingSet] = xl.copyOfSet
  xl.copyOfSet = {}
  setEditSetFalse()

  XLGB_UI:UpdateSetScrollList()
end

function XLGB_UI:ToggleSetEdit()
  if xl.isSetEditable then
    if areThereAnySetChanges() then
      libDialog:ShowDialog("XLGearBanker", "DiscardSetChangesDialog", nil)
    else
      discardSetChanges()
    end
  else
    xl.copyOfSet = XLGB_GearSet:CopyGearSet(sV.displayingSet)
    xl.itemChanges = false
    xl.nameChanges = false
    setEditSetTrue()
  end
end

function XLGB_UI:AddRemoveSet()
  if not xl.isSetEditable then
    XLGB_UI:AddSet()
  else
    XLGB_UI:RemoveSet()
  end
  if xl.isPageEditable then
    initiatePageShifterBoxEntries()
  end
end

function XLGB_UI:AddSet()
  local newSetName = XLGB_GearSet:GenerateNewSet()
  sV.displayingSet = XLGB_GearSet:GetGearSetIndex(newSetName)
  XLGB_UI:SelectSet(sV.displayingSet)

  XLGB_UI:ToggleSetEdit()
  XLGB_UI:ShowOrHideEditSet()
  XLGB_UI:UpdateSetDropdown()
end

local function removeSetConfirmed()
  XLGB_GearSet:RemoveGearSet(sV.displayingSet)
  setEditSetFalse()
  XLGB_UI:SelectSet(sV.displayingSet - 1)
  XLGB_UI:ShowOrHideEditSet()
  XLGB_UI:UpdatePageScrollList()
  XLGB_UI:UpdateSetDropdown()
end

function XLGB_UI:RemoveSet()
  if #XLGB_GearSet:GetGearSet(sV.displayingSet).items == 0 then
    removeSetConfirmed()
  else
    libDialog:ShowDialog("XLGearBanker", "RemoveSetDialog", nil)
  end
end

function XLGB_UI:RemoveItem(removeItemControl)
  easyDebug("Removing item")
  local itemRowControl = removeItemControl:GetParent()
  local itemLink = itemRowControl.data.itemLink
  local itemID = itemRowControl.data.itemID
  xl.itemChanges = true
  XLGB_GearSet:RemoveItemFromGearSet(itemLink, itemID, sV.displayingSet)
end

function XLGB_UI:AddEquippedItemsToSet()
  -- libDialog:ShowDialog("XLGearBanker", "AddEquippedItemsToSet", nil)
  xl.itemChanges = true
  XLGB_GearSet:AddEquippedItemsToGearSet(sV.displayingSet)
  XLGB_UI:UpdateSetScrollList()
end

function XLGB_UI:OnSetWindowReceiveDrag(control)
  local bag = type(GetCursorBagId) == "function" and GetCursorBagId() or nil
  local slot = type(GetCursorSlotIndex) == "function" and GetCursorSlotIndex() or nil
  if bag == nil or slot == nil then return end

  local itemLink = GetItemLink(bag, slot)
  if not itemLink or itemLink == "" then return end

  if XLGB_GearSet:GetNumberOfGearSets() < 1 then return end
  local displayingSet = sV.displayingSet

  local itemID = Id64ToString(GetItemUniqueId(bag, slot))
  if not itemID or itemID == "" or itemID == "0" then
    itemID = itemLink
  end

  if XLGB_GearSet:GetItemIndexInGearSet(itemID, displayingSet) ~= XLGB_Constants.ITEM_NOT_IN_SET then
    local gearSetName = XLGB_GearSet:GetGearSet(displayingSet).name
    d(string.format(XLGB_GetString("SET_ALREADY_EXISTS_IN_SET"), itemLink, gearSetName))
    if type(ClearCursor) == "function" then ClearCursor() end
    return
  end

  xl.itemChanges = true
  XLGB_GearSet:AddItemToGearSet(itemLink, itemID, displayingSet)
  if type(ClearCursor) == "function" then ClearCursor() end
end

local function ShowItemTooltip(self)
  self:GetNamedChild("_BG"):SetHidden(false)
  InitializeTooltip(ItemTooltip, self)
  ItemTooltip:SetLink(self.data.itemLink)
end

local function HideItemTooltip(self)
  self:GetNamedChild("_BG"):SetHidden(true)
  ClearTooltip(ItemTooltip)
end

local function CreateSetTooltip(control, text, editText)
  control.tooltipText = text
  control.tooltipEditText = editText or text -- If no special edit text tooltip, then use default.

  local function ShowTooltip(self)
    InitializeTooltip(InformationTooltip, self, TOPRIGHT, 0, 5, BOTTOMRIGHT)
    local t = self.tooltipText
    if type(t) == "function" then
      t = t(self)
    end
    local e = self.tooltipEditText
    if type(e) == "function" then
      e = e(self)
    end
    if not xl.isSetEditable then
      SetTooltipText(InformationTooltip, t)
    else
      SetTooltipText(InformationTooltip, e)
    end
  end

  local function HideTooltip(self)
    ClearTooltip(InformationTooltip)
  end

  control:SetHandler("OnMouseEnter", ShowTooltip)
  control:SetHandler("OnMouseExit", HideTooltip)
end

local function InitSetWindowTooltips()
  CreateSetTooltip(ui.set.setRow.edit, XLGB_GetString("SET_TOOLTIP_EDIT_CURRENT"), XLGB_GetString("SET_TOOLTIP_DISCARD"))
  CreateSetTooltip(ui.set.setRow.accept, XLGB_GetString("SET_TOOLTIP_ACCEPT"))
  CreateSetTooltip(ui.set.setRow.addRemoveSet, XLGB_GetString("SET_TOOLTIP_CREATE_NEW"), XLGB_GetString("SET_TOOLTIP_REMOVE_CURRENT"))
  CreateSetTooltip(ui.set.addItemsRow.addEquipped, XLGB_GetString("SET_TOOLTIP_ADD_EQUIPPED"))
  if ui.set.bankSetRow and ui.set.bankSetRow.label then
    CreateSetTooltip(ui.set.bankSetRow.label, XLGB_GetString("SET_TOOLTIP_LIBSETS_BAG"))
  end
  if ui.set.bankRow then
    CreateSetTooltip(ui.set.bankRow.deposit, XLGB_GetString("SET_TOOLTIP_DEPOSIT_ACTIVE"))
    CreateSetTooltip(ui.set.bankRow.withdraw, XLGB_GetString("SET_TOOLTIP_WITHDRAW_ACTIVE"))
  end
  if ui.set.titleRow then
    if ui.set.titleRow.pages then
      CreateSetTooltip(ui.set.titleRow.pages, XLGB_GetString("SET_TOOLTIP_TOGGLE_PAGES"))
    end
    if ui.set.titleRow.wardrobe then
      CreateSetTooltip(ui.set.titleRow.wardrobe, XLGB_GetString("PAGE_TOOLTIP_TOGGLE_WARDROBE"))
    end
    if ui.set.titleRow.settings then
      CreateSetTooltip(ui.set.titleRow.settings, XLGB_GetString("PAGE_TOOLTIP_SETTINGS"))
    end
  end
  if ui.set.totalSetItemsRow then
    if ui.set.totalSetItemsRow.text then
      CreateSetTooltip(ui.set.totalSetItemsRow.text, function()
        local count = 0
        local setNum = sV and sV.displayingSet
        if setNum and setNum > 0 then
          local gearSet = XLGB_GearSet:GetGearSet(setNum)
          if gearSet and gearSet.items then
            count = #gearSet.items
          end
        end
        return XLGB_GetString("SET_TOTAL_ITEMS", count)
      end)
    end
    if ui.set.totalSetItemsRow.totalSets then
      CreateSetTooltip(ui.set.totalSetItemsRow.totalSets, XLGB_GetString("SET_TOOLTIP_TOTAL_SETS"))
    end
  end
end

function XLGB_UI:SelectSet(setNumber)
  local totalSets = XLGB_GearSet:GetNumberOfGearSets()

  if totalSets == 0 then
    sV.displayingSet = 0
  elseif setNumber < 1 then
    sV.displayingSet = 1
  elseif setNumber > totalSets then
    sV.displayingSet = totalSets
  else
    sV.displayingSet = setNumber
  end

  -- XLGB_GearSet:UpdateGearSetItems(sV.displayingSet)
  XLGB_UI:UpdateSetScrollList()
  if ui.set and ui.set.bankSetRow and not ui.set.bankSetRow:IsHidden() then
    XLGB_UI:UpdateBankSetDropdown()
  end
end

function XLGB_UI:UpdateSetDropdown()
  local dd = ui.set.setRow.set.dropdown
  dd:ClearItems()
  for i = 1, XLGB_GearSet:GetNumberOfGearSets() do
    local entry =
      ZO_ComboBox:CreateItemEntry(
      XLGB_GearSet:GetGearSet(i).name,
      function()
        XLGB_UI:SelectSet(i)
      end
    )
    dd:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
  end
  if XLGB_GearSet:GetNumberOfGearSets() > 0 and sV.displayingSet and sV.displayingSet > 0 then
    dd:SelectItemByIndex(sV.displayingSet, true)
  end
end

local function setupScrollableComboBoxWithAutoReset(parentControl, containerControl, options)
  if not containerControl then return end
  local comboBox = ZO_ComboBox_ObjectFromContainer(containerControl)
  local dropdownObj = nil
  if AddCustomScrollableComboBoxDropdownMenu then
    dropdownObj = AddCustomScrollableComboBoxDropdownMenu(parentControl, containerControl, options)
  end
  if not comboBox then return dropdownObj end

  local function resetFilter(cb)
    local targetCombo = cb or comboBox
    if not targetCombo then return end
    targetCombo.filterString = ""
    local ddObj = targetCombo.m_dropdownObject or dropdownObj
    local owningWindow = targetCombo.m_dropdown or (ddObj and (ddObj.control or ddObj.m_dropdown))
    if ddObj and ddObj.ResetFilters and owningWindow then
      ddObj:ResetFilters(owningWindow)
    end
    if owningWindow and owningWindow.filterBox then
      if owningWindow.filterBox.LoseFocus and owningWindow.filterBox:HasFocus() then
        owningWindow.filterBox:LoseFocus()
      end
      if owningWindow.filterBox.SetText and owningWindow.filterBox:GetText() ~= "" then
        owningWindow.filterBox:SetText("")
      end
    end
  end

  if comboBox.UpdateResults then
    local origUpdateResults = comboBox.UpdateResults
    comboBox.UpdateResults = function(selfCombo, ...)
      if selfCombo.IsDropdownVisible and not selfCombo:IsDropdownVisible() then
        return
      end
      return origUpdateResults(selfCombo, ...)
    end
  end

  -- LSM opens dropdown via ShowDropdownOnMouseUp, bypassing m_preshowDropdownFn
  if comboBox.ShowDropdownOnMouseUp then
    ZO_PreHook(comboBox, "ShowDropdownOnMouseUp", function(selfCombo)
      if selfCombo.m_preshowDropdownFn then
        selfCombo.m_preshowDropdownFn(selfCombo)
      end
      resetFilter(selfCombo)
    end)
  end

  if comboBox.HideDropdown then
    ZO_PostHook(comboBox, "HideDropdown", function(selfCombo)
      resetFilter(selfCombo)
    end)
  end

  if comboBox.ShowDropdown then
    ZO_PreHook(comboBox, "ShowDropdown", function(selfCombo)
      resetFilter(selfCombo)
    end)
  end

  local ddObj = comboBox.m_dropdownObject or dropdownObj
  local owningWindow = comboBox.m_dropdown or (ddObj and (ddObj.control or ddObj.m_dropdown))
  if owningWindow then
    ZO_PostHookHandler(owningWindow, "OnEffectivelyHidden", function()
      resetFilter(comboBox)
    end)
  end
  if containerControl then
    ZO_PostHookHandler(containerControl, "OnEffectivelyHidden", function()
      resetFilter(comboBox)
    end)
  end

  return dropdownObj, resetFilter
end

local function bankSetCustomSort(item1, item2)
  local prio1 = (item1 and item1.setEntry and item1.setEntry.priority) or 2
  local prio2 = (item2 and item2.setEntry and item2.setEntry.priority) or 2
  if prio1 ~= prio2 then
    return prio1 < prio2
  end
  local name1 = (item1 and (item1.name or (item1.setEntry and item1.setEntry.setName))) or ""
  local name2 = (item2 and (item2.name or (item2.setEntry and item2.setEntry.setName))) or ""
  return name1 < name2
end

function XLGB_UI:InitializeSetDropdown()
  local s = ui.set.setRow.set
  s.dropdown = ZO_ComboBox_ObjectFromContainer(s)
  setupScrollableComboBoxWithAutoReset(ui.set, s, {
    enableFilter = true,
    sortEntries = false,
    enableSort = false,
  })
end

function XLGB_UI:InitializeBankSetDropdown()
  if not ui.set or not ui.set.bankSetRow or not ui.set.bankSetRow.selector then return end
  local s = ui.set.bankSetRow.selector
  s.dropdown = ZO_ComboBox_ObjectFromContainer(s)
  setupScrollableComboBoxWithAutoReset(ui.set, s, {
    enableFilter = true,
    sortEntries = true,
    enableSort = false,
    customSortFunc = bankSetCustomSort,
  })
  if s.dropdown and s.dropdown.SetPreshowDropdownFunction then
    s.dropdown:SetPreshowDropdownFunction(function()
      XLGB_UI:UpdateBankSetDropdown()
    end)
  end
  s.dropdown.m_customSortFunc = bankSetCustomSort
  s.dropdown:SetSortsItems(false)
  s.dropdown:SetSelectedItemText(XLGB_GetString("SET_DROPDOWN_HINT"))
end

function XLGB_UI:UpdateBankSetDropdown()
  if not ui.set or not ui.set.bankSetRow or not ui.set.bankSetRow.selector then return end
  local s = ui.set.bankSetRow.selector
  local dd = s.dropdown
  if not dd then return end
  if AddCustomScrollableComboBoxDropdownMenu and dd.wasUsingAddCustomScrollableComboBoxDropdownMenu and not dd.XMLRowTemplates then
    return
  end

  dd:ClearItems()

  local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)

  -- Update row label and tooltip
  if ui.set.bankSetRow.label then
    if isBankOpen then
      ui.set.bankSetRow.label:SetText(XLGB_GetString("SET_LABEL") .. " |t20:20:/esoui/art/icons/icon_bank.dds|t|t20:20:/esoui/art/tooltips/icon_bag.dds|t")
      ui.set.bankSetRow.label.tooltipText = XLGB_GetString("SET_TOOLTIP_LIBSETS_BOTH")
      ui.set.bankSetRow.label.tooltipEditText = ui.set.bankSetRow.label.tooltipText
    else
      ui.set.bankSetRow.label:SetText(XLGB_GetString("SET_LABEL") .. " |t20:20:/esoui/art/tooltips/icon_bag.dds|t")
      ui.set.bankSetRow.label.tooltipText = XLGB_GetString("SET_TOOLTIP_LIBSETS_BAG")
      ui.set.bankSetRow.label.tooltipEditText = ui.set.bankSetRow.label.tooltipText
    end
  end

  local setsList = XLGB_Inventory:GetAllAvailableSets()
  if not setsList or #setsList == 0 then
    if isBankOpen then
      dd:SetSelectedItemText(XLGB_GetString("SET_NO_FOUND"))
    else
      dd:SetSelectedItemText(XLGB_GetString("SET_NO_IN_BAG"))
    end
    return
  end

  local placeholder = isBankOpen and XLGB_GetString("SET_DROPDOWN_ALL") or XLGB_GetString("SET_DROPDOWN_BAG")
  dd:SetSelectedItemText(placeholder)

  -- Refresh current set links from bags/bank and prioritize sets that constitute the currently selected set
  if sV.displayingSet and sV.displayingSet > 0 then
    XLGB_GearSet:UpdateGearSetItems(sV.displayingSet)
  end
  local currentSet = (sV.displayingSet and sV.displayingSet > 0) and XLGB_GearSet:GetGearSet(sV.displayingSet) or nil
  local constituentSetIds = {}
  local constituentSetNames = {}
  if currentSet then
    if currentSet.items then
      for _, it in ipairs(currentSet.items) do
        local link = it.link or it.itemLink
        if link and link ~= "" then
          local isSet, sName, sId = XLGB_Inventory:GetItemSetInfo(link)
          if isSet then
            if sId then constituentSetIds[sId] = true end
            if sName and sName ~= "" then constituentSetNames[zo_strlower(sName)] = true end
          end
        end
      end
    end
    if currentSet.name and currentSet.name ~= "" then
      constituentSetNames[zo_strlower(currentSet.name)] = true
    end
  end

  for _, setEntry in ipairs(setsList) do
    local isConstituent = false
    if setEntry.setId and constituentSetIds[setEntry.setId] then
      isConstituent = true
    elseif setEntry.setName and constituentSetNames[zo_strlower(setEntry.setName)] then
      isConstituent = true
    else
      local setNameLower = setEntry.setName and zo_strlower(setEntry.setName) or ""
      if setNameLower ~= "" then
        for cName in pairs(constituentSetNames) do
          if string.find(setNameLower, cName, 1, true) or string.find(cName, setNameLower, 1, true) then
            isConstituent = true
            break
          end
        end
      end
    end

    if isConstituent then
      setEntry.priority = 1
      setEntry.isConstituent = true
    else
      setEntry.priority = 2
    end
  end

  table.sort(setsList, function(a, b)
    local prioA = a.priority or 2
    local prioB = b.priority or 2
    if prioA ~= prioB then
      return prioA < prioB
    end
    if a.setName == b.setName then
      return (a.sortOrder or 1) < (b.sortOrder or 1)
    end
    return a.setName < b.setName
  end)

  -- Ensure LSM maintains our star priority order even when sorting
  dd:SetSortsItems(false)
  dd.m_sortsItems = false
  dd.m_sortOrder = nil
  dd.m_customSortFunc = bankSetCustomSort

  for _, setEntry in ipairs(setsList) do
    local baseLabel = setEntry.dropdownLabel or (setEntry.setName .. " (" .. tostring(setEntry.totalCount or #setEntry.items) .. ")")
    local starIcon = "|t20:20:/esoui/art/collections/favorite_staronly.dds|t "
    local label = setEntry.isConstituent and (starIcon .. baseLabel) or baseLabel
    local entry = ZO_ComboBox:CreateItemEntry(
      label,
      function()
        XLGB_UI:OnBankSetSelected(setEntry)
      end
    )
    entry.setEntry = setEntry
    dd:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
  end
end

function XLGB_UI:OnBankSetSelected(setEntry)
  if not setEntry then return end

  if XLGB_GearSet:GetNumberOfGearSets() == 0 then
    XLGB_GearSet:CreateNewGearSet(setEntry.setName)
    sV.displayingSet = XLGB_GearSet:GetGearSetIndex(setEntry.setName)
    XLGB_UI:SelectSet(sV.displayingSet)
    XLGB_UI:UpdateSetDropdown()
    XLGB_UI:ShowOrHideEditSet()
  end

  local displayingSet = sV.displayingSet
  if not displayingSet or displayingSet < 1 then
    displayingSet = 1
    sV.displayingSet = 1
  end

  local gearSet = XLGB_GearSet:GetGearSet(displayingSet)
  if not gearSet then return end

  local sourceLabel = nil
  if setEntry.source == "both" then
    sourceLabel = XLGB_GetString("SET_SOURCE_BOTH_LABEL")
  elseif setEntry.source == "bank" then
    sourceLabel = XLGB_GetString("SET_SOURCE_BANK_LABEL")
  elseif setEntry.source == "bag" then
    sourceLabel = XLGB_GetString("SET_SOURCE_BAG_LABEL")
  end

  local addedCount, newSetIndex = XLGB_GearSet:AddSetItemsToGearSet(setEntry.items, setEntry.setName, displayingSet, sourceLabel)
  if newSetIndex then
    displayingSet = newSetIndex
  else
    displayingSet = sV.displayingSet
  end

  gearSet = XLGB_GearSet:GetGearSet(displayingSet)

  if xl.isSetEditable then
    xl.itemChanges = true
    if gearSet and ui.set.setRow.editName then
      ui.set.setRow.editName:SetText(gearSet.name)
    end
    if gearSet then
      xl.oldSetName = gearSet.name
      if xl.copyOfSet then
        xl.copyOfSet.name = gearSet.name
      end
    end
  end

  XLGB_UI:UpdateSetDropdown()
  XLGB_UI:UpdateSetScrollList()

  zo_callLater(function()
    local selector = ui.set and ui.set.bankSetRow and ui.set.bankSetRow.selector
    if selector and selector.dropdown then
      local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)
      local placeholder = isBankOpen and XLGB_GetString("SET_DROPDOWN_ALL") or XLGB_GetString("SET_DROPDOWN_BAG")
      selector.dropdown:SetSelectedItemText(placeholder)
    end
  end, 50)
end

function XLGB_UI:UpdateSetScrollList()
  if sV.displayingSet and sV.displayingSet > 0 then
    XLGB_GearSet:UpdateGearSetItems(sV.displayingSet)
  end
  local s = ui.set
  if not s then return end

  reanchorSetScrollList()
  local totalSetItems = ui.set.totalSetItemsRow.text
  local totalSetsLabel = ui.set.totalSetItemsRow.totalSets
  local scrollData = ZO_ScrollList_GetDataList(s.scrollList)
  ZO_ScrollList_Clear(s.scrollList)
  local totalSets = XLGB_GearSet:GetNumberOfGearSets()
  if totalSetsLabel then
    totalSetsLabel:SetText(string.format(XLGB_GetString("SET_TOTAL_SETS"), totalSets))
  end
  local itemCount = 0
  if totalSets > 0 and sV.displayingSet and sV.displayingSet > 0 then
    local gearSet = XLGB_GearSet:GetGearSet(sV.displayingSet)
    if gearSet and gearSet.items then
      for _, item in pairs(gearSet.items) do
        local dataEntry =
          ZO_ScrollList_CreateDataEntry(
          XLGB_Constants.ITEM_ROW,
          {
            itemLink = item.link,
            itemID = item.ID
          }
        )
        table.insert(scrollData, dataEntry)
      end
      itemCount = #gearSet.items
      if (#scrollData < 1) and not xl.isSetEditable then
        s.empty:SetHidden(false)
      else
        s.empty:SetHidden(true)
      end
    else
      s.empty:SetHidden(false)
    end
  else
    s.empty:SetHidden(false)
  end

  totalSetItems:SetText(string.format(XLGB_GetString("SET_TOTAL_ITEMS_COUNT"), itemCount))

  if s.empty and s.empty:GetNamedChild("_Label") then
    s.empty:GetNamedChild("_Label"):SetText(XLGB_GetString("SET_EMPTY"))
  end
  ZO_ScrollList_Commit(s.scrollList)
end

local function fillSetItemRowWithData(control, data)
  control.data = data
  local textureString = GetItemLinkIcon(data.itemLink)
  control:GetNamedChild("_Name"):SetText("|t32:32:" .. textureString .. "|t " .. data.itemLink)
  control:SetMouseEnabled(true)
  control:SetHandler("OnMouseEnter", ShowItemTooltip)
  control:SetHandler("OnMouseExit", HideItemTooltip)
  control:SetHandler("OnReceiveDrag", function(ctrl) XLGB_UI:OnSetWindowReceiveDrag(ctrl) end)
  if xl.isSetEditable then
    control:GetNamedChild("_Remove"):SetHidden(false)
  else
    control:GetNamedChild("_Remove"):SetHidden(true)
  end
  CreateSetTooltip(control:GetNamedChild("_Remove"), XLGB_GetString("SET_TOOLTIP_REMOVE_ITEM"))
end

function XLGB_UI:InitializeSetScrollList()
  ZO_ScrollList_AddDataType(
    ui.set.scrollList,
    XLGB_Constants.ITEM_ROW,
    "XLGB_Item_Row_Template",
    35,
    fillSetItemRowWithData
  )
  ZO_ScrollList_EnableHighlight(ui.set.scrollList, "ZO_ThinListHighlight")
  XLGB_UI:UpdateSetScrollList()
end

local function registerSetSlotUpdate()
  EVENT_MANAGER:RegisterForEvent(XLGearBanker.name .. "SetDropdownUpdate", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(eventCode, bagId)
    if XLGB_Banking and XLGB_Banking.isMovingItems then return end
    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "RefreshSetDropdown")
    EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "RefreshSetDropdown", 250, function()
      EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "RefreshSetDropdown")
      if not (XLGB_Banking and XLGB_Banking.isMovingItems) and ui.set and not ui.set:IsHidden() then
        XLGB_UI:UpdateBankSetDropdown()
      end
    end)
  end)
end

local function unregisterSetSlotUpdate()
  EVENT_MANAGER:UnregisterForEvent(XLGearBanker.name .. "SetDropdownUpdate", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
  EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "RefreshSetDropdown")
end

function XLGB_UI:ShowSetUI()
  ui.set:SetHidden(false)
  XLGB_UI:ShowOrHideEditSet()
  local isBankOpen = (XLGB_Banking and XLGB_Banking.bankOpen == true)
  local s = ui.set
  if s then
    if s.bankRow then
      s.bankRow:SetHidden(xl.isSetEditable or (not isBankOpen))
    end
    if s.bankSetRow then
      s.bankSetRow:SetHidden(false)
      if s.bankSetRow.selector then
        s.bankSetRow.selector:SetHidden(false)
      end
      XLGB_UI:UpdateBankSetDropdown()
    end
    reanchorSetScrollList()
    XLGB_UI:UpdateSetScrollList()
  end
  registerSetSlotUpdate()
end

function XLGB_UI:HideSetUI()
  unregisterSetSlotUpdate()
  if xl.isSetEditable and areThereAnySetChanges() then
    libDialog:ShowDialog("XLGearBanker", "DiscardSetChangesDialog", nil)
  else
    setEditSetFalse()
    ui.set:SetHidden(true)
  end
end

function XLGB_UI:ToggleSetUI()
  if ui.set:IsHidden() then
    XLGB_UI:ShowSetUI()
  else
    XLGB_UI:HideSetUI()
  end
end

function XLGB_UI:SetupSetDialogs()
  libDialog:RegisterDialog(
    "XLGearBanker",
    "RemoveSetDialog",
    XLGB_GetString("TITLE_SET"),
    XLGB_GetString("DIALOG_DELETE_SET_CONFIRM_BODY"),
    removeSetConfirmed,
    nil,
    nil
  )

  libDialog:RegisterDialog(
    "XLGearBanker",
    "AcceptSetChanges",
    XLGB_GetString("TITLE_SET"),
    XLGB_GetString("DIALOG_ACCEPT_SET_CHANGES"),
    acceptSetChanges,
    nil,
    nil
  )

  libDialog:RegisterDialog(
    "XLGearBanker",
    "DiscardSetChangesDialog",
    XLGB_GetString("TITLE_SET"),
    XLGB_GetString("DIALOG_DISCARD_SET_BODY"),
    discardSetChanges,
    nil,
    nil
  )
end

local function InitUISetVariables()
  ui.set = XLGB_SetWindow

  ui.set.titleRow = XLGB_SetWindow_TitleRow
  ui.set.titleRow.title = XLGB_SetWindow_TitleRow_Title
  ui.set.titleRow.hide = XLGB_SetWindow_TitleRow_Hide
  ui.set.titleRow.settings = XLGB_SetWindow_TitleRow_Settings
  ui.set.titleRow.wardrobe = XLGB_SetWindow_TitleRow_Wardrobe
  ui.set.titleRow.pages = XLGB_SetWindow_TitleRow_Pages

  if ui.set.titleRow.title then
    ui.set.titleRow.title:SetText(XLGB_GetString("TITLE_SET"))
  end

  if ui.set.titleRow.wardrobe then
    if not WizardsWardrobe then
      ui.set.titleRow.wardrobe:SetHidden(true)
      if ui.set.titleRow.pages and ui.set.titleRow.settings then
        ui.set.titleRow.pages:ClearAnchors()
        ui.set.titleRow.pages:SetAnchor(TOPRIGHT, ui.set.titleRow.settings, TOPLEFT, -10, 1)
      end
    else
      ui.set.titleRow.wardrobe:SetHidden(false)
    end
  end

  ui.set.setRow = XLGB_SetWindow_SetRow
  ui.set.setRow.edit = XLGB_SetWindow_SetRow_EditSet
  ui.set.setRow.editName = XLGB_SetWindow_SetRow_EditSetName
  ui.set.setRow.set = XLGB_SetWindow_Selector
  ui.set.setRow.accept = XLGB_SetWindow_SetRow_AcceptSet
  ui.set.setRow.addRemoveSet = XLGB_SetWindow_SetRow_AddRemoveSet

  ui.set.bankSetRow = XLGB_SetWindow_BankSetRow
  ui.set.bankSetRow.label = XLGB_SetWindow_BankSetRow_Label
  ui.set.bankSetRow.selector = XLGB_SetWindow_BankSetSelector

  ui.set.scrollList = XLGB_SetWindow_ScrollList

  ui.set.empty = XLGB_SetWindow_EmptyRow

  ui.set.addItemsRow = XLGB_SetWindow_AddItemsRow
  ui.set.addItemsRow.addEquipped = XLGB_SetWindow_AddItemsRow_AddEquipped

  ui.set.totalSetItemsRow = XLGB_SetWindow_TotalSetItemsRow
  ui.set.totalSetItemsRow.text = XLGB_SetWindow_TotalSetItemsRow_TotalSetItems
  ui.set.totalSetItemsRow.totalSets = XLGB_SetWindow_TotalSetItemsRow_TotalSets

  ui.set.bankRow = XLGB_SetWindow_BankRow
  ui.set.bankRow.deposit = XLGB_SetWindow_BankRow_DepositSet
  ui.set.bankRow.withdraw = XLGB_SetWindow_BankRow_WithdrawSet
  ui.set.bankRow.withdrawQuality = XLGB_SetWindow_BankRow_WithdrawQuality
  ui.set.bankRow.depositQuality = XLGB_SetWindow_BankRow_DepositQuality

  if ui.set.bankRow.deposit and ui.set.bankRow.deposit:GetNamedChild("_Label") then
    ui.set.bankRow.deposit:GetNamedChild("_Label"):SetText(XLGB_GetString("SET_DEPOSIT"))
  end
  if ui.set.bankRow.withdraw and ui.set.bankRow.withdraw:GetNamedChild("_Label") then
    ui.set.bankRow.withdraw:GetNamedChild("_Label"):SetText(XLGB_GetString("SET_WITHDRAW"))
  end
  if ui.set.addItemsRow.addEquipped and ui.set.addItemsRow.addEquipped:GetNamedChild("_Label") then
    ui.set.addItemsRow.addEquipped:GetNamedChild("_Label"):SetText(XLGB_GetString("SET_ADD_EQUIPPED"))
  end
  if ui.set.empty and ui.set.empty:GetNamedChild("_Label") then
    ui.set.empty:GetNamedChild("_Label"):SetText(XLGB_GetString("SET_EMPTY"))
  end

  -- Register drag-and-drop handlers for adding equipment items to the active set
  ui.set:SetHandler("OnReceiveDrag", function(control) XLGB_UI:OnSetWindowReceiveDrag(control) end)
  ui.set.scrollList:SetHandler("OnReceiveDrag", function(control) XLGB_UI:OnSetWindowReceiveDrag(control) end)
  ui.set.empty:SetHandler("OnReceiveDrag", function(control) XLGB_UI:OnSetWindowReceiveDrag(control) end)
end

--------------------------------------------------------------------------------------------
-- SET WINDOW END
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        PROGRESS BAR
--
--
--
--
--------------------------------------------------------------------------------------------
local function getBagSize(bag)
  if bag == BAG_BANK or bag == BAG_SUBSCRIBER_BANK then
    return GetBagSize(BAG_BANK) + GetBagSize(BAG_SUBSCRIBER_BANK)
  else
    return GetBagSize(bag)
  end
end

local function getNumBagUsedSlots(bag)
  if bag == BAG_BANK or bag == BAG_SUBSCRIBER_BANK then
    return GetNumBagUsedSlots(BAG_BANK) + GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
  else
    return GetNumBagUsedSlots(bag)
  end
end

local function setProgressBar(current, total)
  local p = ui.progress
  if not p or not p.progressRow or not p.progressRow.bar then return end
  local pct = (total and total > 0) and (current / total) or 0
  if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
  local calculateOffSet = -(360 * (1 - pct))
  p.progressRow.bar:ClearAnchors()
  p.progressRow.bar:SetAnchor(TOPLEFT, p.progressRow.barBG, TOPLEFT, 0, 0)
  p.progressRow.bar:SetAnchor(BOTTOMRIGHT, p.progressRow.barBG, BOTTOMRIGHT, calculateOffSet, 0)
end

local function setInfoRowItemsInSet(itemsRemaining)
  local p = ui.progress
  if not p or not p.infoRow or not p.infoRow.setSize then return end
  p.infoRow.setSize:SetText(
    "|t52:56:/esoui/art/tradinghouse/tradinghouse_apparel_chest_up.dds|t(" ..
      tostring(itemsRemaining or 0) .. ") |t32:32:/esoui/art/chatwindow/chat_overflowarrow_up.dds|t"
  )
end

local function updateBagSpace()
  local p = ui.progress
  if not p or not p.infoRow or not p.infoRow.bagSpace then return end
  local bag = p.bag or BAG_BACKPACK
  local bagIcon = p.bagIcon or "|t32:32:/esoui/art/tooltips/icon_bag.dds|t"
  local bagSize = p.bagSize or getBagSize(bag)
  local usedSlots = getNumBagUsedSlots(bag)
  p.infoRow.bagSpace:SetText(bagIcon .. "(" .. tostring(usedSlots) .. "/" .. tostring(bagSize) .. ")")
end

local function defaultSetRowInfo()
  XLGB_UI:OnMoveItem(nil, 0)
end

local function updateProgressBar(nextSetName, pretext)
  local p = ui.progress
  p.x = p.x + 1
  p.progressRow.xOfY:SetText("[" .. tostring(p.x) .. "/" .. tostring(p.y) .. "]")
  setProgressBar(p.x, p.y)
  defaultSetRowInfo()
  p.setRow.setInfo:SetText(pretext .. " set '|cffecbc" .. nextSetName .. "|r'")
end

local function hideProgress()
  local p = ui.progress
  if not p then return end
  p.isItemList = false
  p:SetHidden(true)
  p.overlay:SetHidden(true)
end

function XLGB_UI:OnMoveItem(targetBag, itemsLeft)
  local p = ui.progress
  if not p or p:IsHidden() then return end

  if p.isItemList and targetBag and p.y and p.y > 0 and itemsLeft then
    local done = math.max(0, p.y - itemsLeft)
    setProgressBar(done, p.y)
    if p.progressRow and p.progressRow.xOfY then
      p.progressRow.xOfY:SetText("[" .. tostring(done) .. "/" .. tostring(p.y) .. "]")
    end
  end

  setInfoRowItemsInSet(itemsLeft)
  updateBagSpace()
  if p.cancelRow and p.cancelRow.safeMode then
    if sV and sV.safeMode then
      p.cancelRow.safeMode:SetText(XLGB_GetString("BANKING_SAFE_MODE_ON"))
    else
      p.cancelRow.safeMode:SetText(XLGB_GetString("BANKING_SAFE_MODE_OFF"))
    end
  end
end

------------

function XLGB_UI:OnPageWithdrawStart(pageName)
  local p = ui.progress
  p.isItemList = false
  p.x = 0
  p.y = #XLGB_Page:GetSetsInPage(pageName)
  p.titleRow.title:SetText(string.format(XLGB_GetString("BANKING_PROGRESS_WITHDRAW_PAGE"), pageName))

  p.bag = BAG_BACKPACK
  p.bagIcon = "|t32:32:/esoui/art/tooltips/icon_bag.dds|t"
  p.bagSize = getBagSize(p.bag)
  defaultSetRowInfo()

  p:SetHidden(false)
  p.overlay:SetHidden(false)
end

function XLGB_UI:OnPageWithdrawNextSet(nextSetName)
  updateProgressBar(nextSetName, XLGB_GetString("QUALITY_WITHDRAW_NAME"))
end

local function hookIIfAQuery()
  if not IIfA or type(IIfA.QueryAccountInventory) ~= "function" or IIfA._XLGB_Hooked then return end
  IIfA._XLGB_Hooked = true
  local origQuery = IIfA.QueryAccountInventory
  IIfA.QueryAccountInventory = function(self, itemLink)
    local res = origQuery(self, itemLink)
    if (not res or not res.locations or #res.locations == 0) and type(itemLink) == "string" then
      local normKey = itemLink:gsub("^|H%d+:", "|H1:"):gsub("|h.-|h$", "|h|h")
      if normKey ~= itemLink then
        res = origQuery(self, normKey)
      end
      if (not res or not res.locations or #res.locations == 0) and IIFA_DATABASE and self.currentAccount and self.currentServerType then
        local accountData = IIFA_DATABASE[self.currentAccount]
        local serverData = accountData and accountData.servers and accountData.servers[self.currentServerType]
        local db = serverData and serverData.DBv3
        if db then
          local itemId = itemLink:match(":item:(%d+):")
          if itemId then
            local pattern = ":item:" .. itemId .. ":"
            for dbKey in pairs(db) do
              if dbKey:match(pattern) then
                res = origQuery(self, dbKey)
                if res and res.locations and #res.locations > 0 then
                  break
                end
              end
            end
          end
        end
      end
    end
    return res
  end
end

local function formatIIfALocations(itemLink)
  hookIIfAQuery()
  if not IIfA or type(IIfA.QueryAccountInventory) ~= "function" then return nil end
  local query = IIfA:QueryAccountInventory(itemLink)
  if not query or not query.locations or #query.locations == 0 then return nil end

  local equippedLabel = (XLGB_GetString and XLGB_GetString("MISSING_ITEM_LOC_EQUIPPED")) or "Equipped"
  local bagLabel = (XLGB_GetString and XLGB_GetString("MISSING_ITEM_LOC_BAG")) or "Bag"
  local companionLabel = (XLGB_GetString and XLGB_GetString("MISSING_ITEM_LOC_COMPANION")) or "Companion"
  local chestLabel = (XLGB_GetString and XLGB_GetString("MISSING_ITEM_LOC_CHEST")) or "Chest"
  local bankLabel = (XLGB_GetString and XLGB_GetString("MISSING_ITEM_LOC_BANK")) or "Bank"

  local locStrings = {}
  local seen = {}
  for _, loc in ipairs(query.locations) do
    local locName = loc.name
    if locName and locName ~= "" then
      local detail = ""
      if loc.worn then
        detail = string.format(" (%s)", equippedLabel)
      elseif loc.wornCompanion then
        detail = string.format(" (%s)", companionLabel)
      elseif loc.bagLoc == BAG_BACKPACK then
        detail = string.format(" (%s)", bagLabel)
      elseif loc.bagLoc == BAG_HOUSE_BANK_ONE then
        detail = string.format(" (%s)", chestLabel)
      elseif loc.bagLoc == BAG_BANK then
        locName = bankLabel
        detail = ""
      end

      local fullLocStr = locName .. detail
      if not seen[fullLocStr] then
        seen[fullLocStr] = true
        table.insert(locStrings, fullLocStr)
      end
    end
  end

  if #locStrings > 0 then
    return table.concat(locStrings, ", ")
  end
  return nil
end

local function printMissingItemsReport(setName, missingItems)
  if not missingItems or #missingItems == 0 then return end

  local headerFmt = (XLGB_GetString and XLGB_GetString("MISSING_ITEMS_REPORT_HEADER")) or "|cFF9900[XLGB]|r Missing pieces for '%s' (%d):"
  d(string.format(headerFmt, tostring(setName), #missingItems))

  for _, itemLink in ipairs(missingItems) do
    local locText = formatIIfALocations(itemLink)
    local chatItemLink = itemLink
    if zo_strformat and SI_TOOLTIP_ITEM_NAME then
      local formatted = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemLink)
      if formatted and formatted ~= "" and formatted:find("|h") then
        chatItemLink = formatted
      end
    end
    if not chatItemLink:find("|h%[") and GetItemLinkName then
      local itemName = GetItemLinkName(itemLink)
      if itemName and itemName ~= "" then
        chatItemLink = itemLink:gsub("^|H%d+:", "|H1:"):gsub("|h.-|h$", "|h[" .. itemName .. "]|h")
      end
    end

    if locText and locText ~= "" then
      d(string.format("  |cFFD700•|r %s -> |c88BBFF%s|r", chatItemLink, locText))
    else
      d(string.format("  |cFFD700•|r %s", chatItemLink))
    end
  end
end

local function pageMissingItemsReport(bag, pageName, isWithdrawing)
  local function _onPageMissingWait()
    EVENT_MANAGER:UnregisterForUpdate("pageMissingItemsReport" .. XLGearBanker.name)
    local qualityFilter = isWithdrawing and (sV.pageWithdrawQualities or sV.withdrawQualities) or (sV.pageDepositQualities or sV.depositQualities)
    local missingItemsPage = XLGB_Page:GetMissingItemsInPage(bag, pageName, qualityFilter)
    if missingItemsPage and missingItemsPage.sets then
      for _, set in ipairs(missingItemsPage.sets) do
        if set and set.items and #set.items > 0 then
          printMissingItemsReport(set.name, set.items)
        end
      end
    end
  end

  EVENT_MANAGER:UnregisterForUpdate("pageMissingItemsReport" .. XLGearBanker.name)
  EVENT_MANAGER:RegisterForUpdate("pageMissingItemsReport" .. XLGearBanker.name, 500, _onPageMissingWait)
end

function XLGB_UI:OnPageWithdrawStop(pageName)
  hideProgress()
  local p = ui.progress
  if sV.reportMissing and not XLGB_Banking.isMoveCancelled then
    pageMissingItemsReport(p.bag, pageName, true)
  end
end

function XLGB_UI:OnSingleSetWithdrawStart(setName, startTime)
  local p = ui.progress
  p.isItemList = false
  p.x = 0
  p.y = 1
  p.titleRow.title:SetText(string.format(XLGB_GetString("BANKING_PROGRESS_WITHDRAW_SET"), setName))

  p.bag = BAG_BACKPACK
  p.bagIcon = "|t32:32:/esoui/art/tooltips/icon_bag.dds|t"
  p.bagSize = getBagSize(p.bag)
  defaultSetRowInfo()
  updateProgressBar(setName, XLGB_GetString("QUALITY_WITHDRAW_NAME"))

  p:SetHidden(false)
  p.overlay:SetHidden(false)
end

local function singleSetMissingItemsReport(bag, setName, isWithdrawing)
  local function _onSingleSetMissingWait()
    EVENT_MANAGER:UnregisterForUpdate("singleSetMissingItemsReport" .. XLGearBanker.name)
    local gearSetNumber = XLGB_GearSet:GetGearSetIndex(setName)
    if not gearSetNumber then return end
    local qualityFilter = isWithdrawing and (sV.setWithdrawQualities or sV.withdrawQualities) or (sV.setDepositQualities or sV.depositQualities)
    local targetBag = bag or (isWithdrawing and BAG_BACKPACK or (XLGB_Banking.currentBankBag or BAG_BANK))
    local missingSet = XLGB_GearSet:GetMissingItems(targetBag, gearSetNumber, qualityFilter)
    if missingSet and missingSet.items and #missingSet.items > 0 then
      printMissingItemsReport(missingSet.name, missingSet.items)
    end
  end

  EVENT_MANAGER:UnregisterForUpdate("singleSetMissingItemsReport" .. XLGearBanker.name)
  EVENT_MANAGER:RegisterForUpdate("singleSetMissingItemsReport" .. XLGearBanker.name, 500, _onSingleSetMissingWait)
end

function XLGB_UI:OnSingleSetWithdrawStop(setName)
  hideProgress()
  local p = ui.progress
  if sV.reportMissing and not XLGB_Banking.isMoveCancelled then
    singleSetMissingItemsReport(p.bag, setName, true)
  end
end

------------

function XLGB_UI:OnPageDepositStart(pageName)
  local p = ui.progress
  p.isItemList = false
  p.x = 0
  p.y = #XLGB_Page:GetSetsInPage(pageName)
  p.titleRow.title:SetText(string.format(XLGB_GetString("BANKING_PROGRESS_DEPOSIT_PAGE"), pageName))

  p.bag = XLGB_Banking.currentBankBag
  p.bagIcon = "|t32:32:/esoui/art/tooltips/icon_bank.dds|t"
  p.bagSize = getBagSize(p.bag)
  defaultSetRowInfo()

  p:SetHidden(false)
  p.overlay:SetHidden(false)
end

function XLGB_UI:OnPageDepositNextSet(nextSetName)
  updateProgressBar(nextSetName, XLGB_GetString("QUALITY_DEPOSIT_NAME"))
end

function XLGB_UI:OnPageDepositStop(pageName)
  hideProgress()
  local p = ui.progress
  if sV.reportMissing and not XLGB_Banking.isMoveCancelled then
    pageMissingItemsReport(p.bag, pageName, false)
  end
end

---

function XLGB_UI:OnSingleSetDepositStart(setName)
  local p = ui.progress
  p.isItemList = false
  p.x = 0
  p.y = 1
  p.titleRow.title:SetText(string.format(XLGB_GetString("BANKING_PROGRESS_DEPOSIT_SET"), setName))

  p.bag = XLGB_Banking.currentBankBag
  p.bagIcon = "|t32:32:/esoui/art/tooltips/icon_bank.dds|t"
  p.bagSize = getBagSize(p.bag)
  defaultSetRowInfo()
  updateProgressBar(setName, XLGB_GetString("QUALITY_DEPOSIT_NAME"))

  p:SetHidden(false)
  p.overlay:SetHidden(false)
end

function XLGB_UI:OnSingleSetDepositStop(setName)
  hideProgress()
  local p = ui.progress
  if sV.reportMissing and not XLGB_Banking.isMoveCancelled then
    singleSetMissingItemsReport(p.bag, setName, false)
  end
end

---

function XLGB_UI:OnItemListMoveStart(title, itemCount, isWithdrawing)
  local p = ui.progress
  if not p then return end
  p.isItemList = true
  p.x = 0
  p.y = itemCount or 1
  p.titleRow.title:SetText(title or XLGB_GetString("BANKING_MOVING"))

  if isWithdrawing then
    p.bag = BAG_BACKPACK
    p.bagIcon = "|t32:32:/esoui/art/tooltips/icon_bag.dds|t"
  else
    p.bag = XLGB_Banking.currentBankBag or BAG_BANK
    p.bagIcon = "|t32:32:/esoui/art/tooltips/icon_bank.dds|t"
  end
  p.bagSize = getBagSize(p.bag)
  if p.progressRow and p.progressRow.xOfY then
    p.progressRow.xOfY:SetText("[0/" .. tostring(p.y) .. "]")
  end
  setProgressBar(0, p.y)
  if p.setRow and p.setRow.setInfo then
    p.setRow.setInfo:SetText(title or "")
  end
  setInfoRowItemsInSet(p.y)
  updateBagSpace()

  p:SetHidden(false)
  p.overlay:SetHidden(false)
end

function XLGB_UI:OnItemListMoveStop()
  hideProgress()
end

--------

function XLGB_UI:CancelMoveItems()
  local p = ui.progress
  p:SetHidden(true)
  p.overlay:SetHidden(true)
  XLGB_Banking.isMoveCancelled = true
end

local function InitUIProgressVariables()
  ui.progress = XLGB_ProgressWindow

  ui.progress.titleRow = XLGB_ProgressWindow_TitleRow
  ui.progress.titleRow.title = XLGB_ProgressWindow_TitleRow_Title

  ui.progress.progressRow = XLGB_ProgressWindow_ProgressRow
  ui.progress.progressRow.xOfY = XLGB_ProgressWindow_ProgressRow_XofY
  ui.progress.progressRow.barBG = XLGB_ProgressWindow_ProgressRow_BarBG
  ui.progress.progressRow.bar = XLGB_ProgressWindow_ProgressRow_Bar

  ui.progress.infoRow = XLGB_ProgressWindow_InfoRow
  ui.progress.infoRow.setSize = XLGB_ProgressWindow_InfoRow_SetSize
  ui.progress.infoRow.bagSpace = XLGB_ProgressWindow_InfoRow_BagSpace

  ui.progress.setRow = XLGB_ProgressWindow_SetRow
  ui.progress.setRow.setInfo = XLGB_ProgressWindow_SetRow_SetInfo

  ui.progress.cancelRow = XLGB_ProgressWindow_CancelRow
  ui.progress.cancelRow.safeMode = XLGB_ProgressWindow_CancelRow_SafeMode
  ui.progress.cancelRow.cancel = XLGB_ProgressWindow_CancelRow_Cancel

  if ui.progress.cancelRow.cancel and ui.progress.cancelRow.cancel:GetNamedChild("_Label") then
    ui.progress.cancelRow.cancel:GetNamedChild("_Label"):SetText(XLGB_GetString("BANKING_CANCEL"))
  end

  ui.progress.overlay = XLGB_GreyOverlay
end
--------------------------------------------------------------------------------------------
-- PROGRESS BAR END
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        MISSING ITEMS
--
--
--
--
--------------------------------------------------------------------------------------------

function XLGB_UI:ShowMissingItemsUI()
  local m = ui.missing
  if xl.areThereAnyItemsMissing then
    m:SetHidden(false)
    m.overlay:SetHidden(false)
  end
end

function XLGB_UI:HideMissingItemsUI()
  local m = ui.missing
  m:SetHidden(true)
  m.overlay:SetHidden(true)
end

function XLGB_UI:UpdateMissingItemsScrollList(missingItemsPage)
  XLGB_UI:UpdateSetScrollList()
  local m = ui.missing
  local scrollData = ZO_ScrollList_GetDataList(m.scrollList)
  ZO_ScrollList_Clear(m.scrollList)
  xl.areThereAnyItemsMissing = false
  for _, set in pairs(missingItemsPage.sets) do
    local dataSetEntry =
      ZO_ScrollList_CreateDataEntry(
      XLGB_Constants.MISSING_SET_ROW,
      {
        name = set.name,
        amount = #set.items
      }
    )
    if #set.items ~= 0 then
      table.insert(scrollData, dataSetEntry)
    end
    for _, itemLink in pairs(set.items) do
      local dataItemEntry =
        ZO_ScrollList_CreateDataEntry(
        XLGB_Constants.MISSING_ITEM_ROW,
        {
          itemLink = itemLink
        }
      )
      xl.areThereAnyItemsMissing = true
      table.insert(scrollData, dataItemEntry)
    end
  end
  ZO_ScrollList_Commit(m.scrollList)
end

local function fillMissingSetsRowWithData(control, data)
  control.data = data
  control:GetNamedChild("_Name"):SetText("|cffecbc" .. data.name .. "|r")
  control:GetNamedChild("_Amount"):SetText("(" .. tostring(data.amount) .. ")")
end

local function fillMissingItemsRowWithData(control, data)
  control.data = data
  local textureString = GetItemLinkIcon(data.itemLink)
  control:GetNamedChild("_Name"):SetText("|t32:32:" .. textureString .. "|t " .. data.itemLink)
  control:SetMouseEnabled(true)
  control:SetHandler("OnMouseEnter", ShowItemTooltip)
  control:SetHandler("OnMouseExit", HideItemTooltip)
end

function XLGB_UI:InitializeMissingItemsScrollList()
  ZO_ScrollList_AddDataType(
    ui.missing.scrollList,
    XLGB_Constants.MISSING_SET_ROW,
    "XLGB_MissingSetRow_Template",
    35,
    fillMissingSetsRowWithData
  )
  ZO_ScrollList_AddDataType(
    ui.missing.scrollList,
    XLGB_Constants.MISSING_ITEM_ROW,
    "XLGB_MissingItemRow_Template",
    35,
    fillMissingItemsRowWithData
  )
  ZO_ScrollList_EnableHighlight(ui.missing.scrollList, "ZO_ThinListHighlight")
end

local function InitUIMissingItemsVariables()
  ui.missing = XLGB_MissingItems

  ui.missing.titleRow = XLGB_MissingItems_TitleRow
  ui.missing.titleRow.title = XLGB_MissingItems_TitleRow_Title

  ui.missing.confirmRow = XLGB_MissingItems_ConfirmRow
  ui.missing.confirmRow.confirm = XLGB_MissingItems_ConfirmRow_Confirm

  ui.missing.scrollList = XLGB_MissingItems_ScrollList

  ui.missing.overlay = XLGB_GreyOverlay

  if ui.missing.titleRow and ui.missing.titleRow.title then
    ui.missing.titleRow.title:SetText(XLGB_GetString("TITLE_MISSING"))
  end
  if ui.missing.confirmRow and ui.missing.confirmRow.confirm and ui.missing.confirmRow.confirm:GetNamedChild("_Label") then
    ui.missing.confirmRow.confirm:GetNamedChild("_Label"):SetText(XLGB_GetString("MISSING_CONFIRM_BTN"))
  end
end

--------------------------------------------------------------------------------------------
-- MISSING ITEMS END
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--                                WIZARD'S WARDROBE UI
--
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

local function fillWardrobeHeaderRowWithData(control, data)
  control.data = data
  local nameLabel = control:GetNamedChild("_Name")
  local countLabel = control:GetNamedChild("_Count")
  local quickSetBtn = control:GetNamedChild("_QuickSet")

  local sV = XLGearBanker.savedVariables
  local isCurrentTarget = (sV and sV.quickSetTargetName and sV.quickSetTargetName ~= "" and sV.quickSetTargetName == data.name)

  if nameLabel then
    nameLabel:SetText("|cffecbc" .. (data.name or "") .. "|r")
  end

  if countLabel then
    if data.total and data.total > 0 then
      local parts = {}
      if data.worn and data.worn > 0 then table.insert(parts, "|c00ff00" .. string.format(XLGB_GetString("WW_STAT_WORN"), data.worn) .. "|r") end
      if data.bag and data.bag > 0 then table.insert(parts, "|c55ff55" .. string.format(XLGB_GetString("WW_STAT_BAG"), data.bag) .. "|r") end
      if data.bank and data.bank > 0 then table.insert(parts, "|c5599ff" .. string.format(XLGB_GetString("WW_STAT_BANK"), data.bank) .. "|r") end
      if data.missing and data.missing > 0 then table.insert(parts, "|cff5555" .. string.format(XLGB_GetString("WW_STAT_MISSING"), data.missing) .. "|r") end

      local statusStr = (#parts > 0) and (" (" .. table.concat(parts, ", ") .. ")") or ""
      if statusStr ~= "" then
        countLabel:SetText(statusStr)
      else
        countLabel:SetText(string.format(XLGB_GetString("WW_PIECES_COUNT"), data.total))
      end
    else
      countLabel:SetText("")
    end
  end

  local function triggerQuickSetSelection(anchorCtrl)
    local charId = (XLGB_Wardrobe and XLGB_Wardrobe.selectedCharId) or (GetCurrentCharacterId and tostring(Id64ToString(GetCurrentCharacterId())))
    local zoneTag = (XLGB_Wardrobe and XLGB_Wardrobe.selectedZoneTag) or (WizardsWardrobe and WizardsWardrobe.selection and WizardsWardrobe.selection.zone and WizardsWardrobe.selection.zone.tag) or "GEN"
    local pageId = (XLGB_Wardrobe and XLGB_Wardrobe.selectedPageId) or (WizardsWardrobe and WizardsWardrobe.selection and WizardsWardrobe.selection.pageId) or 1
    local matches = (XLGB_Command and XLGB_Command.FindSetupsWithSet) and XLGB_Command:FindSetupsWithSet(zoneTag, pageId, data.name) or {}

    if #matches > 1 then
      ClearMenu()
      local title = "|cffecbc=== " .. data.name .. " ===|r"
      AddCustomMenuItem(title, nil)
      local purposeText = "|cffffff" .. XLGB_GetString("QUICK_SET_CONFLICT_MENU_PURPOSE") .. "|r"
      AddCustomMenuItem(purposeText, nil)
      local conflictHeader = string.format("|cffff00" .. XLGB_GetString("QUICK_SET_CONFLICT_MENU_HEADER") .. "|r", data.name, #matches)
      AddCustomMenuItem(conflictHeader, nil)
      for _, m in ipairs(matches) do
        local label = string.format("  > [%d] %s", m.index, m.name)
        AddCustomMenuItem(label, function()
          if XLGB_Command then
            XLGB_Command:SetTargetSetName(data.name, m.index, m.name, charId, zoneTag, pageId)
            if XLGB_UI and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
          end
        end)
      end
      ShowMenu(anchorCtrl or control)
    else
      local idx = (matches[1] and matches[1].index) or nil
      local name = (matches[1] and matches[1].name) or nil
      if XLGB_Command then
        XLGB_Command:SetTargetSetName(data.name, idx, name, charId, zoneTag, pageId)
        if XLGB_UI and XLGB_UI.UpdateWardrobeUI then XLGB_UI:UpdateWardrobeUI() end
      end
    end
  end

  if quickSetBtn then
    local quickSetIcon = quickSetBtn:GetNamedChild("_Icon")

    if data.isIsolated then
      quickSetBtn:SetHidden(true)
      if nameLabel then
        nameLabel:ClearAnchors()
        nameLabel:SetAnchor(LEFT, control, LEFT, 12, 0)
        nameLabel:SetAnchor(RIGHT, countLabel, LEFT, -8, 0)
      end
    else
      quickSetBtn:SetHidden(false)
      if nameLabel then
        nameLabel:ClearAnchors()
        nameLabel:SetAnchor(LEFT, quickSetBtn, RIGHT, 6, 0)
        nameLabel:SetAnchor(RIGHT, countLabel, LEFT, -8, 0)
      end

      local function applyColor(r, g, b, a)
        if quickSetIcon and quickSetIcon.SetColor then
          quickSetIcon:SetColor(r, g, b, a)
        elseif quickSetBtn.SetColor then
          quickSetBtn:SetColor(r, g, b, a)
        end
      end

      if isCurrentTarget then
        applyColor(1, 0.85, 0.2, 1)
      else
        applyColor(0.5, 0.5, 0.5, 0.5)
      end

      quickSetBtn:SetHandler("OnMouseEnter", function(btn)
        InitializeTooltip(InformationTooltip, btn, TOPLEFT, 0, -5, BOTTOMLEFT)
        if isCurrentTarget then
          SetTooltipText(InformationTooltip, string.format(XLGB_GetString("QUICK_SET_TOOLTIP_ACTIVE"), data.name))
        else
          applyColor(1, 0.9, 0.4, 0.9)
          SetTooltipText(InformationTooltip, string.format(XLGB_GetString("QUICK_SET_TOOLTIP_SET"), data.name))
        end
      end)

      quickSetBtn:SetHandler("OnMouseExit", function(btn)
        ClearTooltip(InformationTooltip)
        if isCurrentTarget then
          applyColor(1, 0.85, 0.2, 1)
        else
          applyColor(0.5, 0.5, 0.5, 0.5)
        end
      end)

      quickSetBtn:SetHandler("OnClicked", function(btn)
        triggerQuickSetSelection(btn)
      end)

      quickSetBtn:SetHandler("OnMouseUp", function(btn, button)
        if button == 2 then
          triggerQuickSetSelection(btn)
        end
      end)
    end
  end

  control:SetMouseEnabled(true)
  control:SetHandler("OnMouseEnter", function(ctrl)
    if data and data.name and data.name ~= "" then
      InitializeTooltip(InformationTooltip, ctrl, TOPRIGHT, 0, 5, BOTTOMRIGHT)
      local tooltipText = data.name .. " (" .. string.format(XLGB_GetString("WW_PIECES_COUNT"), data.total or 0) .. ")"
      if not data.isIsolated then
        if isCurrentTarget then
          tooltipText = tooltipText .. "\n|c00ff00" .. string.format(XLGB_GetString("QUICK_SET_TOOLTIP_ACTIVE"), data.name) .. "|r"
        else
          tooltipText = tooltipText .. "\n|c888888" .. XLGB_GetString("QUICK_SET_ROW_HINT") .. "|r"
        end
      end
      SetTooltipText(InformationTooltip, tooltipText)
    end
  end)
  control:SetHandler("OnMouseExit", function(ctrl)
    ClearTooltip(InformationTooltip)
  end)
  control:SetHandler("OnMouseUp", function(ctrl, button)
    if (button == 1 or button == 2) and data and data.name and data.name ~= "" and not data.isIsolated then
      triggerQuickSetSelection(ctrl)
    end
  end)
end

local function fillWardrobeItemRowWithData(control, data)
  control.data = data
  local bg = control:GetNamedChild("_BG")
  local icon = control:GetNamedChild("_Icon")
  local nameLabel = control:GetNamedChild("_Name")
  local locLabel = control:GetNamedChild("_Location")

  if icon then
    local texture = (data.itemLink and data.itemLink ~= "") and GetItemLinkIcon(data.itemLink) or "/esoui/art/icons/icon_missing.dds"
    icon:SetTexture(texture)
  end

  if nameLabel then
    nameLabel:SetText(data.itemLink or "")
  end

  if locLabel then
    if data.location == "WORN" then
      locLabel:SetText("|c00ff00" .. XLGB_GetString("WW_LOCATION_WORN") .. "|r")
    elseif data.location == "BAG" then
      locLabel:SetText("|c55ff55" .. XLGB_GetString("WW_LOCATION_BAG") .. "|r")
    elseif data.location == "BANK" then
      locLabel:SetText("|c5599ff" .. XLGB_GetString("WW_LOCATION_BANK") .. "|r")
    elseif data.location == "MISSING" then
      locLabel:SetText("|cff5555" .. XLGB_GetString("WW_LOCATION_MISSING") .. "|r")
    else
      locLabel:SetText("")
    end
  end

  control:SetMouseEnabled(true)
  control:SetHandler("OnMouseEnter", function(ctrl)
    if bg then bg:SetHidden(false) end
    if ctrl.data and ctrl.data.itemLink and ctrl.data.itemLink ~= "" then
      InitializeTooltip(ItemTooltip, ctrl, TOPRIGHT, 0, 5, BOTTOMRIGHT)
      ItemTooltip:SetLink(ctrl.data.itemLink)
      if ctrl.data.setups and #ctrl.data.setups > 0 then
        ItemTooltip:AddVerticalPadding(8)
        ItemTooltip:AddLine(XLGB_GetString("WW_SETUPS_COUNT") .. table.concat(ctrl.data.setups, ", "), "ZoFontGameSmall", 0.7, 0.9, 1)
      end
    end
  end)
  control:SetHandler("OnMouseExit", function(ctrl)
    if bg then bg:SetHidden(true) end
    ClearTooltip(ItemTooltip)
  end)
end

local function fillWardrobeSurplusRowWithData(control, data)
  control.data = data
  local bg = control:GetNamedChild("_BG")
  local icon = control:GetNamedChild("_Icon")
  local nameLabel = control:GetNamedChild("_Name")
  local setLabel = control:GetNamedChild("_Set")

  if icon then
    local texture = (data.itemLink and data.itemLink ~= "") and GetItemLinkIcon(data.itemLink) or "/esoui/art/icons/icon_missing.dds"
    icon:SetTexture(texture)
  end

  if nameLabel then
    nameLabel:SetText(data.itemLink or "")
  end

  if setLabel then
    setLabel:SetText("|cffecbc" .. (data.setName or XLGB_GetString("WW_NO_SET")) .. "|r")
  end

  control:SetMouseEnabled(true)
  control:SetHandler("OnMouseEnter", function(ctrl)
    if bg then bg:SetHidden(false) end
    if ctrl.data and ctrl.data.itemLink and ctrl.data.itemLink ~= "" then
      InitializeTooltip(ItemTooltip, ctrl, TOPRIGHT, 0, 5, BOTTOMRIGHT)
      ItemTooltip:SetLink(ctrl.data.itemLink)
    end
  end)
  control:SetHandler("OnMouseExit", function(ctrl)
    if bg then bg:SetHidden(true) end
    ClearTooltip(ItemTooltip)
  end)
end

function XLGB_UI:InitializeWardrobeScrollList()
  if not ui.wardrobe or not ui.wardrobe.scrollList then return end
  ZO_ScrollList_AddDataType(
    ui.wardrobe.scrollList,
    XLGB_Constants.WARDROBE_HEADER_ROW,
    "XLGB_Wardrobe_HeaderRow_Template",
    30,
    fillWardrobeHeaderRowWithData
  )
  ZO_ScrollList_AddDataType(
    ui.wardrobe.scrollList,
    XLGB_Constants.WARDROBE_ITEM_ROW,
    "XLGB_Wardrobe_ItemRow_Template",
    28,
    fillWardrobeItemRowWithData
  )
  ZO_ScrollList_AddDataType(
    ui.wardrobe.scrollList,
    XLGB_Constants.WARDROBE_SURPLUS_ROW,
    "XLGB_Wardrobe_SurplusRow_Template",
    28,
    fillWardrobeSurplusRowWithData
  )
  ZO_ScrollList_EnableHighlight(ui.wardrobe.scrollList, "ZO_ThinListHighlight")
end

function XLGB_UI:InitializeWardrobeSelectors()
  if not ui.wardrobe then return end

  local function initCombo(container)
    if not container then return end
    container.dropdown = ZO_ComboBox_ObjectFromContainer(container)
    setupScrollableComboBoxWithAutoReset(ui.wardrobe, container, {
      enableFilter = true,
      sortEntries = false,
      enableSort = false,
    })
    if container.dropdown then
      container.dropdown:SetSortsItems(false)
    end
  end

  initCombo(ui.wardrobe.charRow.selector)
  initCombo(ui.wardrobe.zoneRow.selector)
  initCombo(ui.wardrobe.pageRow.selector)
end

function XLGB_UI:PopulateWardrobeSelectors(preferredCharId)
  if not ui.wardrobe then return end
  if not XLGB_Wardrobe:IsWWAvailable() then
    if ui.wardrobe.summaryRow and ui.wardrobe.summaryRow.summary then
      ui.wardrobe.summaryRow.summary:SetText("|cff5555" .. XLGB_GetString("WW_NOT_DETECTED") .. "|r")
    end
    return
  end

  local charDD = ui.wardrobe.charRow.selector.dropdown
  if not charDD then return end
  charDD:ClearItems()

  local chars = XLGB_Wardrobe:GetCharacters()
  if #chars == 0 then
    charDD:SetSelectedItemText(XLGB_GetString("WW_NO_CHARS"))
    return
  end

  local selectedCharIndex = 1
  for idx, c in ipairs(chars) do
    local label = c.name
    if c.isCurrent then
      label = "|c00ff00" .. label .. " " .. XLGB_GetString("WW_CHAR_CURRENT") .. "|r"
    end
    if c.setupCount and c.setupCount > 0 then
      label = label .. " |c888888" .. string.format(XLGB_GetString("WW_SETUPS_COUNT_BADGE"), c.setupCount) .. "|r"
    end

    local entry = charDD:CreateItemEntry(
      label,
      function()
        XLGB_Wardrobe.selectedCharId = c.id
        XLGB_Wardrobe.selectedPageId = nil
        -- Conserve la zone/raid actuellement visualisée si possible, sinon celle du perso, sinon "GEN"
        local preferredZone = XLGB_Wardrobe.selectedZoneTag or c.lastZoneTag or "GEN"
        XLGB_UI:PopulateWardrobeZones(c.id, preferredZone)
      end
    )
    entry.charData = c
    charDD:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)

    if preferredCharId then
      if tostring(c.id) == tostring(preferredCharId) then
        selectedCharIndex = idx
      end
    elseif c.isCurrent then
      selectedCharIndex = idx
    end
  end

  charDD:SelectItemByIndex(selectedCharIndex)
end

function XLGB_UI:PopulateWardrobeZones(charId, preferredZoneTag)
  if not ui.wardrobe then return end
  local zoneDD = ui.wardrobe.zoneRow.selector.dropdown
  if not zoneDD then return end
  zoneDD:ClearItems()

  local zones = XLGB_Wardrobe:GetZones(charId)
  if #zones == 0 then
    zoneDD:SetSelectedItemText(XLGB_GetString("WW_NO_ZONES"))
    return
  end

  local selectedZoneIndex = 1
  local foundPreferred = false
  local firstWithSetups = nil

  for idx, z in ipairs(zones) do
    local label = z.name
    if z.setupCount and z.setupCount > 0 then
      label = label .. " |c888888(" .. z.setupCount .. ")|r"
      if not firstWithSetups and z.tag ~= "GEN" then
        firstWithSetups = idx
      end
    end
    if z.icon and z.icon ~= "" then
      label = "|t20:20:" .. z.icon .. "|t " .. label
    end

    local entry = zoneDD:CreateItemEntry(
      label,
      function()
        XLGB_Wardrobe.selectedZoneTag = z.tag
        XLGB_Wardrobe.selectedPageId = nil
        XLGB_UI:PopulateWardrobePages(charId, z.tag)
      end
    )
    entry.zoneData = z
    zoneDD:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)

    if preferredZoneTag and z.tag == preferredZoneTag then
      selectedZoneIndex = idx
      foundPreferred = true
    end
  end

  -- Si preferredZoneTag n'a pas été trouvé ou était "GEN", mais que le perso a un raid avec des setups, on privilégie ce raid
  if not foundPreferred and firstWithSetups and (not preferredZoneTag or preferredZoneTag == "GEN") then
    selectedZoneIndex = firstWithSetups
  end

  zoneDD:SelectItemByIndex(selectedZoneIndex)
end

function XLGB_UI:PopulateWardrobePages(charId, zoneTag)
  if not ui.wardrobe then return end
  local pageDD = ui.wardrobe.pageRow.selector.dropdown
  if not pageDD then return end
  pageDD:ClearItems()

  local pages, activePageId = XLGB_Wardrobe:GetPages(charId, zoneTag)
  if #pages == 0 then
    pageDD:SetSelectedItemText(XLGB_GetString("WW_NO_PAGES"))
    return
  end

  local selectedPageIndex = 1
  local preferredPageId = XLGB_Wardrobe.selectedPageId or activePageId or 1

  for idx, p in ipairs(pages) do
    local entry = pageDD:CreateItemEntry(
      p.name,
      function()
        XLGB_Wardrobe.selectedPageId = p.id
        XLGB_UI:UpdateWardrobeUI()
      end
    )
    entry.pageData = p
    pageDD:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)

    if preferredPageId and p.id == preferredPageId then
      selectedPageIndex = idx
    end
  end

  pageDD:SelectItemByIndex(selectedPageIndex)
end

function XLGB_UI:SelectWardrobeTab(tabIndex)
  XLGB_Wardrobe.activeTab = tabIndex
  if ui.wardrobe and ui.wardrobe.tabRow then
    local tabNeededLabel = ui.wardrobe.tabRow.tabNeeded:GetNamedChild("_Label")
    local tabSurplusLabel = ui.wardrobe.tabRow.tabSurplus:GetNamedChild("_Label")
    if tabIndex == 1 then
      if tabNeededLabel then tabNeededLabel:SetColor(0.2, 1, 0.2, 1) end
      if tabSurplusLabel then tabSurplusLabel:SetColor(0.7, 0.7, 0.7, 1) end
    else
      if tabNeededLabel then tabNeededLabel:SetColor(0.7, 0.7, 0.7, 1) end
      if tabSurplusLabel then tabSurplusLabel:SetColor(1, 0.8, 0.2, 1) end
    end
  end
  XLGB_UI:UpdateWardrobeUI()
end

function XLGB_UI:UpdateWardrobeUI()
  if not ui.wardrobe or ui.wardrobe:IsHidden() then return end

  local charId = XLGB_Wardrobe.selectedCharId
  local zoneTag = XLGB_Wardrobe.selectedZoneTag
  local pageId = XLGB_Wardrobe.selectedPageId

  if not charId or not zoneTag or not pageId then
    return
  end

  local neededGearMap, setsList, stats = XLGB_Wardrobe:GetPageGear(charId, zoneTag, pageId)
  local diffItems = XLGB_Wardrobe:GetDifferenceItems(charId, zoneTag, pageId)

  if ui.wardrobe.summaryRow and ui.wardrobe.summaryRow.summary then
    local parts = {}
    table.insert(parts, "|c00ff00" .. string.format(XLGB_GetString("WW_STAT_WORN"), stats.worn) .. "|r")
    table.insert(parts, "|c55ff55" .. string.format(XLGB_GetString("WW_STAT_BAG"), stats.bag) .. "|r")
    table.insert(parts, "|c5599ff" .. string.format(XLGB_GetString("WW_STAT_BANK"), stats.bank) .. "|r")
    table.insert(parts, "|cff5555" .. string.format(XLGB_GetString("WW_STAT_MISSING"), stats.missing) .. "|r")
    local statusStr = table.concat(parts, ", ")
    local summaryStr = string.format(XLGB_GetString("WW_SUMMARY_FULL"), stats.total, statusStr, #diffItems)
    ui.wardrobe.summaryRow.summary:SetText(summaryStr)
  end

  if ui.wardrobe.tabRow then
    local tabNeededLabel = ui.wardrobe.tabRow.tabNeeded:GetNamedChild("_Label")
    local tabSurplusLabel = ui.wardrobe.tabRow.tabSurplus:GetNamedChild("_Label")
    if tabNeededLabel then
      tabNeededLabel:SetText(string.format(XLGB_GetString("WW_TAB_NEEDED_COUNT"), stats.total))
    end
    if tabSurplusLabel then
      tabSurplusLabel:SetText(string.format(XLGB_GetString("WW_TAB_SURPLUS_COUNT"), #diffItems))
    end
  end

  local scrollData = ZO_ScrollList_GetDataList(ui.wardrobe.scrollList)
  ZO_ScrollList_Clear(ui.wardrobe.scrollList)

  local activeTab = XLGB_Wardrobe.activeTab or 1
  if activeTab == 1 then
    if #setsList == 0 then
      local emptyHeader = ZO_ScrollList_CreateDataEntry(
        XLGB_Constants.WARDROBE_HEADER_ROW,
        { name = XLGB_GetString("WW_NO_GEAR_IN_PAGE"), total = 0 }
      )
      table.insert(scrollData, emptyHeader)
    else
      for _, setGroup in ipairs(setsList) do
        local headerEntry = ZO_ScrollList_CreateDataEntry(
          XLGB_Constants.WARDROBE_HEADER_ROW,
          {
            name = setGroup.setName,
            total = #setGroup.items,
            worn = setGroup.worn,
            bag = setGroup.bag,
            bank = setGroup.bank,
            missing = setGroup.missing,
          }
        )
        table.insert(scrollData, headerEntry)

        for _, item in ipairs(setGroup.items) do
          local itemEntry = ZO_ScrollList_CreateDataEntry(
            XLGB_Constants.WARDROBE_ITEM_ROW,
            {
              itemLink = item.link,
              location = item.location,
              id = item.id,
              setups = item.setups,
            }
          )
          table.insert(scrollData, itemEntry)
        end
      end
    end
  else
    if #diffItems == 0 then
      local emptyHeader = ZO_ScrollList_CreateDataEntry(
        XLGB_Constants.WARDROBE_HEADER_ROW,
        { name = XLGB_GetString("WW_NO_SURPLUS"), total = 0 }
      )
      table.insert(scrollData, emptyHeader)
    else
      local countHeader = ZO_ScrollList_CreateDataEntry(
        XLGB_Constants.WARDROBE_HEADER_ROW,
        { name = XLGB_GetString("WW_DEPOSIT_HEADER"), total = #diffItems }
      )
      table.insert(scrollData, countHeader)

      for _, dItem in ipairs(diffItems) do
        local surplusEntry = ZO_ScrollList_CreateDataEntry(
          XLGB_Constants.WARDROBE_SURPLUS_ROW,
          {
            itemLink = dItem.link,
            setName = dItem.setName,
            id = dItem.ID,
          }
        )
        table.insert(scrollData, surplusEntry)
      end
    end
  end

  ZO_ScrollList_Commit(ui.wardrobe.scrollList)
end

function XLGB_UI:ToggleWardrobeUI()
  if not ui.wardrobe then return end
  if ui.wardrobe:IsHidden() then
    XLGB_UI:ShowWardrobeUI()
  else
    XLGB_UI:HideWardrobeUI()
  end
end

function XLGB_UI:ShowWardrobeUI()
  if not ui.wardrobe then return end
  if not WizardsWardrobe then return end
  ui.wardrobe:SetHidden(false)
  XLGB_UI:RestoreWardrobePosition()
  XLGB_UI:ResizeWardrobeControls()
  if not XLGB_Wardrobe.selectedCharId then
    XLGB_UI:PopulateWardrobeSelectors()
  else
    XLGB_UI:UpdateWardrobeUI()
  end
end

function XLGB_UI:HideWardrobeUI()
  if not ui.wardrobe then return end
  ui.wardrobe:SetHidden(true)
end

function XLGB_UI:XLGB_WardrobeWindow_OnMoveStop()
  if not ui.wardrobe then return end
  sV.wardrobeWindow_x = ui.wardrobe:GetLeft()
  sV.wardrobeWindow_y = ui.wardrobe:GetTop()
end

function XLGB_UI:XLGB_WardrobeWindow_OnResizeStop()
  if not ui.wardrobe then return end
  sV.wardrobeWindow_width = ui.wardrobe:GetWidth()
  sV.wardrobeWindow_height = ui.wardrobe:GetHeight()
  XLGB_UI:XLGB_WardrobeWindow_OnMoveStop()
  XLGB_UI:ResizeWardrobeControls()
end

function XLGB_UI:RestoreWardrobePosition()
  if not ui.wardrobe then return end
  if sV.wardrobeWindow_x and sV.wardrobeWindow_y then
    ui.wardrobe:ClearAnchors()
    ui.wardrobe:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, sV.wardrobeWindow_x, sV.wardrobeWindow_y)
  end
  if sV.wardrobeWindow_width and sV.wardrobeWindow_height then
    ui.wardrobe:SetWidth(sV.wardrobeWindow_width)
    ui.wardrobe:SetHeight(sV.wardrobeWindow_height)
  end
  XLGB_UI:ResizeWardrobeControls()
end

function XLGB_UI:ResizeWardrobeControls()
  if not ui.wardrobe then return end
  local totalWidth = ui.wardrobe:GetWidth() - 20
  local spacing = 4
  local btnWidth = math.floor((totalWidth - (3 * spacing)) / 4)
  if btnWidth < 70 then btnWidth = 70 end

  if ui.wardrobe.actionRow then
    if ui.wardrobe.actionRow.depositDiff then ui.wardrobe.actionRow.depositDiff:SetWidth(btnWidth) end
    if ui.wardrobe.actionRow.withdrawPage then ui.wardrobe.actionRow.withdrawPage:SetWidth(btnWidth) end
    if ui.wardrobe.actionRow.prepare then ui.wardrobe.actionRow.prepare:SetWidth(btnWidth) end
    if ui.wardrobe.actionRow.importBtn then ui.wardrobe.actionRow.importBtn:SetWidth(btnWidth) end
  end

  if ui.wardrobe.scrollList then
    ZO_ScrollList_Commit(ui.wardrobe.scrollList)
  end
end

function XLGB_UI:OnWardrobeDepositDiffClicked()
  local charId = XLGB_Wardrobe.selectedCharId
  local zoneTag = XLGB_Wardrobe.selectedZoneTag
  local pageId = XLGB_Wardrobe.selectedPageId
  if not charId or not zoneTag or not pageId then return end
  XLGB_Wardrobe:DepositDifference(charId, zoneTag, pageId)
end

function XLGB_UI:OnWardrobeWithdrawClicked()
  local charId = XLGB_Wardrobe.selectedCharId
  local zoneTag = XLGB_Wardrobe.selectedZoneTag
  local pageId = XLGB_Wardrobe.selectedPageId
  if not charId or not zoneTag or not pageId then return end
  XLGB_Wardrobe:WithdrawPageGear(charId, zoneTag, pageId)
end

function XLGB_UI:OnWardrobePrepareClicked()
  local charId = XLGB_Wardrobe.selectedCharId
  local zoneTag = XLGB_Wardrobe.selectedZoneTag
  local pageId = XLGB_Wardrobe.selectedPageId
  if not charId or not zoneTag or not pageId then return end
  XLGB_Wardrobe:PrepareInventory(charId, zoneTag, pageId)
end

function XLGB_UI:OnWardrobeImportClicked()
  local charId = XLGB_Wardrobe.selectedCharId
  local zoneTag = XLGB_Wardrobe.selectedZoneTag
  local pageId = XLGB_Wardrobe.selectedPageId
  if not charId or not zoneTag or not pageId then return end
  XLGB_Wardrobe:ImportAsXLGBPage(charId, zoneTag, pageId)
end

local function InitUIWardrobeVariables()
  ui.wardrobe = XLGB_WardrobeWindow

  ui.wardrobe.titleRow = XLGB_WardrobeWindow_TitleRow
  ui.wardrobe.titleRow.title = XLGB_WardrobeWindow_TitleRow_Title
  ui.wardrobe.titleRow.hide = XLGB_WardrobeWindow_TitleRow_Hide
  ui.wardrobe.titleRow.refresh = XLGB_WardrobeWindow_TitleRow_Refresh

  ui.wardrobe.charRow = XLGB_WardrobeWindow_CharRow
  ui.wardrobe.charRow.label = XLGB_WardrobeWindow_CharRow_Label
  ui.wardrobe.charRow.selector = XLGB_WardrobeWindow_CharRow_Selector

  ui.wardrobe.zoneRow = XLGB_WardrobeWindow_ZoneRow
  ui.wardrobe.zoneRow.label = XLGB_WardrobeWindow_ZoneRow_Label
  ui.wardrobe.zoneRow.selector = XLGB_WardrobeWindow_ZoneRow_Selector

  ui.wardrobe.pageRow = XLGB_WardrobeWindow_PageRow
  ui.wardrobe.pageRow.label = XLGB_WardrobeWindow_PageRow_Label
  ui.wardrobe.pageRow.selector = XLGB_WardrobeWindow_PageRow_Selector

  ui.wardrobe.tabRow = XLGB_WardrobeWindow_TabRow
  ui.wardrobe.tabRow.tabNeeded = XLGB_WardrobeWindow_TabRow_TabNeeded
  ui.wardrobe.tabRow.tabSurplus = XLGB_WardrobeWindow_TabRow_TabSurplus

  ui.wardrobe.summaryRow = XLGB_WardrobeWindow_SummaryRow
  ui.wardrobe.summaryRow.summary = XLGB_WardrobeWindow_SummaryRow_Summary

  ui.wardrobe.scrollList = XLGB_WardrobeWindow_ScrollList

  ui.wardrobe.filterRow = XLGB_WardrobeWindow_FilterRow
  ui.wardrobe.filterRow.withdrawQuality = XLGB_WardrobeWindow_FilterRow_WithdrawQuality or XLGB_WardrobeWindow_WithdrawQuality
  ui.wardrobe.filterRow.depositQuality = XLGB_WardrobeWindow_FilterRow_DepositQuality or XLGB_WardrobeWindow_DepositQuality

  ui.wardrobe.actionRow = XLGB_WardrobeWindow_ActionRow
  ui.wardrobe.actionRow.depositDiff = XLGB_WardrobeWindow_ActionRow_DepositDiff
  ui.wardrobe.actionRow.withdrawPage = XLGB_WardrobeWindow_ActionRow_WithdrawPage
  ui.wardrobe.actionRow.prepare = XLGB_WardrobeWindow_ActionRow_Prepare
  ui.wardrobe.actionRow.importBtn = XLGB_WardrobeWindow_ActionRow_Import

  if ui.set and ui.set.titleRow then
    ui.set.titleRow.wardrobe = XLGB_SetWindow_TitleRow_Wardrobe
  end

  if ui.wardrobe.titleRow and ui.wardrobe.titleRow.title then
    ui.wardrobe.titleRow.title:SetText(XLGB_GetString("TITLE_WARDROBE"))
  end

  if ui.wardrobe.charRow and ui.wardrobe.charRow.label then
    ui.wardrobe.charRow.label:SetText(XLGB_GetString("WW_CHAR"))
  end
  if ui.wardrobe.zoneRow and ui.wardrobe.zoneRow.label then
    ui.wardrobe.zoneRow.label:SetText(XLGB_GetString("WW_ZONE"))
  end
  if ui.wardrobe.pageRow and ui.wardrobe.pageRow.label then
    ui.wardrobe.pageRow.label:SetText(XLGB_GetString("WW_PAGE"))
  end

  if ui.wardrobe.tabRow then
    local tabNeededLabel = ui.wardrobe.tabRow.tabNeeded and ui.wardrobe.tabRow.tabNeeded:GetNamedChild("_Label")
    local tabSurplusLabel = ui.wardrobe.tabRow.tabSurplus and ui.wardrobe.tabRow.tabSurplus:GetNamedChild("_Label")
    if tabNeededLabel then tabNeededLabel:SetText(XLGB_GetString("WW_TAB_NEEDED")) end
    if tabSurplusLabel then tabSurplusLabel:SetText(XLGB_GetString("WW_TAB_SURPLUS")) end
  end

  if ui.wardrobe.summaryRow and ui.wardrobe.summaryRow.summary then
    ui.wardrobe.summaryRow.summary:SetText(XLGB_GetString("WW_LOADING"))
  end

  if ui.wardrobe.actionRow then
    local depLabel = ui.wardrobe.actionRow.depositDiff and ui.wardrobe.actionRow.depositDiff:GetNamedChild("_Label")
    local withLabel = ui.wardrobe.actionRow.withdrawPage and ui.wardrobe.actionRow.withdrawPage:GetNamedChild("_Label")
    local prepLabel = ui.wardrobe.actionRow.prepare and ui.wardrobe.actionRow.prepare:GetNamedChild("_Label")
    local impLabel = ui.wardrobe.actionRow.importBtn and ui.wardrobe.actionRow.importBtn:GetNamedChild("_Label")
    if depLabel then
      depLabel:SetFont("ZoFontWinH4")
      depLabel:SetText(XLGB_GetString("WW_BTN_DEPOSIT"))
    end
    if withLabel then
      withLabel:SetFont("ZoFontWinH4")
      withLabel:SetText(XLGB_GetString("WW_BTN_WITHDRAW"))
    end
    if prepLabel then
      prepLabel:SetFont("ZoFontWinH4")
      prepLabel:SetText(XLGB_GetString("WW_BTN_PREPARE"))
    end
    if impLabel then
      impLabel:SetFont("ZoFontWinH4")
      impLabel:SetText(XLGB_GetString("WW_BTN_IMPORT"))
    end
  end

  CreatePageTooltip(ui.wardrobe.titleRow.refresh, XLGB_GetString("WW_TOOLTIP_REFRESH"))
  CreatePageTooltip(ui.wardrobe.actionRow.depositDiff, XLGB_GetString("WW_TOOLTIP_DEPOSIT_FULL"))
  CreatePageTooltip(ui.wardrobe.actionRow.withdrawPage, XLGB_GetString("WW_TOOLTIP_WITHDRAW_FULL"))
  CreatePageTooltip(ui.wardrobe.actionRow.prepare, XLGB_GetString("WW_TOOLTIP_PREPARE_FULL"))
  CreatePageTooltip(ui.wardrobe.actionRow.importBtn, XLGB_GetString("WW_TOOLTIP_IMPORT_FULL"))
end

--------------------------------------------------------------------------------------------
-- WIZARD'S WARDROBE UI END
--------------------------------------------------------------------------------------------

function XLGB_UI:Initialize()
  xl = XLGearBanker or {}
  sV = XLGearBanker.savedVariables or {}

  xl.isSetEditable = false
  xl.isPageEditable = false
  xl.pageSetEntriesBefore = {}
  xl.copyOfSet = {}
  xl.itemChanges = false
  xl.nameChanges = false
  xl.areThereAnyItemsMissing = false

  InitUIProgressVariables()

  InitUISetVariables()
  InitSetWindowTooltips()

  InitUIPageVariables()
  InitPageWindowTooltips()

  InitUIMissingItemsVariables()
  InitUIWardrobeVariables()

  XLGB_UI:RestorePosition()
  XLGB_UI:RestoreWardrobePosition()

  XLGB_UI:InitializeSetScrollList()
  XLGB_UI:InitializeSetDropdown()
  XLGB_UI:UpdateSetDropdown()
  XLGB_UI:SelectSet(sV.displayingSet)
  XLGB_UI:SetupSetDialogs()

  XLGB_UI:InitializeBankSetDropdown()
  refreshBankAndShifterRow()
  reanchorSetScrollList()
  reanchorPageScrollList()
  XLGB_UI:RefreshQualityFilters()
  if XLGB_Banking and XLGB_Banking.bankOpen then
    XLGB_UI:UpdateBankSetDropdown()
  end

  XLGB_UI:InitializePageShifterBox()
  XLGB_UI:InitializePageScrollList()
  XLGB_UI:InitializePageDropdown()
  XLGB_UI:UpdatePageDropdown()
  XLGB_UI:SelectPage(sV.displayingPage)
  XLGB_UI:SetupPageDialogs()

  XLGB_UI:InitializeMissingItemsScrollList()
  XLGB_UI:InitializeWardrobeScrollList()
  XLGB_UI:InitializeWardrobeSelectors()

  hookIIfAQuery()

  if sV.debug then
    XLGB_UI:ShowPageUI()
  end
end

-- Namespace
XLGearBanker = XLGearBanker or {}

XLGearBanker.name = XLGearBanker.name or (XLGB_Constants and XLGB_Constants.ADDON_NAME) or "XLGearBanker"
XLGearBanker.version = XLGearBanker.version or (XLGB_Constants and XLGB_Constants.ADDON_VERSION) or "2026.10.19"
XLGearBanker.author = XLGearBanker.author or (XLGB_Constants and XLGB_Constants.AUTHOR) or "|c783f04nyc|r|c8fce00thé|r|c6a329fmère|r (original: @XL_Olsen)"

-- Default settings.
XLGearBanker.savedVariables = {
  pages = {},
  gearSetList = {},
  pageWindow_x = 995,
  pageWindow_y = 250,
  setWindow_x = 640,
  setWindow_y = 250,
  setWindow_width = 350,
  setWindow_height = 600,
  safeMode = true,
  debug = false,
  threshold = 70,
  reportMissing = true,
  showSetWindowOnOpen = true,
  showPageWindowOnOpen = false,
  showWardrobeWindowOnOpen = true,
  displayingSet = 1,
  displayingPage = 1,
  wardrobeWindow_x = 640,
  wardrobeWindow_y = 250,
  wardrobeWindow_width = 400,
  wardrobeWindow_height = 640,
  withdrawQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  depositQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  pageWithdrawQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  pageDepositQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  setWithdrawQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  setDepositQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  wardrobeWithdrawQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  wardrobeDepositQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true },
  quickSetTargetName = "",
  quickSetChoices = {},
  quickSetUndoStack = {}
}

function XLGearBanker.OnAddOnLoaded(event, addonName)
  if addonName == XLGearBanker.name then
    XLGB_Constants:Initialize()
    XLGearBanker:Initialize()
    XLGB_GearSet:Initialize()
    XLGB_Page:Initialize()
    XLGB_Banking:Initialize()
    XLGB_Wardrobe:Initialize()
    XLGB_Command:Initialize()
    XLGB_MenuOverWriter:Initialize()
    XLGB_Settings:Initialize()
    XLGB_UI:Initialize()
  end
end

function easyDebug(...)
  if XLGearBanker.logger and XLGearBanker.logger.Debug then
    XLGearBanker.logger:Debug(...)
  end
  if sV and sV.debug == true then
    d("[XLGB_DEBUG] " .. ...)
  end
end

function XLGearBanker:Initialize()
  self.savedVariables = ZO_SavedVars:NewAccountWide("XLGearBankerSavedVariables", 1, nil, XLGearBanker.savedVariables)
  sV = XLGearBanker.savedVariables
  sV.addonVersion = XLGearBanker.version
  if sV.showWardrobeWindowOnOpen == nil then
    sV.showWardrobeWindowOnOpen = true
  end
  if not sV.wardrobeWindow_width then
    sV.wardrobeWindow_width = 380
  end
  if not sV.wardrobeWindow_height then
    sV.wardrobeWindow_height = 640
  end
  if not sV.withdrawQualities then
    sV.withdrawQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
  end
  if not sV.depositQualities then
    sV.depositQualities = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
  end

  local function ensureQualityTable(target, fallback)
    if not target then
      target = {}
      for q = 1, 5 do
        target[q] = (fallback and fallback[q] ~= nil) and fallback[q] or true
      end
    else
      for q = 1, 5 do
        if target[q] == nil then
          target[q] = (fallback and fallback[q] ~= nil) and fallback[q] or true
        end
      end
    end
    return target
  end

  sV.pageWithdrawQualities = ensureQualityTable(sV.pageWithdrawQualities, sV.withdrawQualities)
  sV.pageDepositQualities = ensureQualityTable(sV.pageDepositQualities, sV.depositQualities)
  sV.setWithdrawQualities = ensureQualityTable(sV.setWithdrawQualities, sV.withdrawQualities)
  sV.setDepositQualities = ensureQualityTable(sV.setDepositQualities, sV.depositQualities)
  sV.wardrobeWithdrawQualities = ensureQualityTable(sV.wardrobeWithdrawQualities, sV.withdrawQualities)
  sV.wardrobeDepositQualities = ensureQualityTable(sV.wardrobeDepositQualities, sV.depositQualities)
  if sV.quickSetTargetName == nil then
    sV.quickSetTargetName = ""
  end
  if sV.quickSetChoices == nil then
    sV.quickSetChoices = {}
  end
  if sV.quickSetUndoStack == nil then
    sV.quickSetUndoStack = {}
  end
end

EVENT_MANAGER:RegisterForEvent(XLGearBanker.name, EVENT_ADD_ON_LOADED, XLGearBanker.OnAddOnLoaded)

-------------------------------------------------------------------------------
--Slash Commands! --
-- Note: Slash commands should not contain capital letters!
SLASH_COMMANDS["/xlgb_debug"] = function(argsv)
  if sV.debug then
    d("[XLGB] Debugging = off.")
    sV.debug = false
  else
    d("[XLGB] Debugging = on.")
    sV.debug = true
  end
end

SLASH_COMMANDS["/xlgb_overlay"] = function(argsv)
  XLGB_GreyOverlay:SetHidden(not XLGB_GreyOverlay:IsHidden())
end

SLASH_COMMANDS["/xlgb_help"] = function(argsv)
  d("[XLGB] Commands")
  d("'/xlgb_debug': Toggles debug mode. (Note: quite verbose)")
end

SLASH_COMMANDS["/xlgb"] = function()
  XLGB_UI:ToggleAllUI()
end

SLASH_COMMANDS["/xlgb_pages"] = function()
  XLGB_UI:TogglePageUI()
end
SLASH_COMMANDS["/xlgb_page"] = SLASH_COMMANDS["/xlgb_pages"]

SLASH_COMMANDS["/xlgb_ww"] = function()
  XLGB_UI:ToggleWardrobeUI()
end
-------------------------------------------------------------------------------

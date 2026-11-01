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
  fastTransferJunkTab = true,
  enableItemContextMenu = false,
  quickSetTargetName = "",
  quickSetTargetName2 = "",
  quickSetChoices = {},
  quickSetUndoStack = {},
  quickSetUndoStack2 = {},
  pageCategoryTab = 1,
  lastCustomPage = 1,
  lastWWPage = 1,
  setCategoryTab = 1,
  lastCustomSet = 1,
  lastWWSet = 1
}

function XLGearBanker.OnAddOnLoaded(event, addonName)
  if addonName == XLGearBanker.name then
    EVENT_MANAGER:UnregisterForEvent(XLGearBanker.name, EVENT_ADD_ON_LOADED)
    XLGB_Constants:Initialize()
    XLGearBanker:Initialize()
    XLGB_Inventory:Initialize()
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
  if sV.fastTransferJunkTab == nil then
    sV.fastTransferJunkTab = true
  end
  if sV.enableItemContextMenu == nil then
    sV.enableItemContextMenu = false
  end
  if sV.quickSetTargetName == nil then
    sV.quickSetTargetName = ""
  end
  if sV.quickSetTargetName2 == nil then
    sV.quickSetTargetName2 = ""
  end
  if sV.quickSetChoices == nil then
    sV.quickSetChoices = {}
  end
  if sV.quickSetUndoStack == nil then
    sV.quickSetUndoStack = {}
  end
  if sV.quickSetUndoStack2 == nil then
    sV.quickSetUndoStack2 = {}
  end
  if sV.pageCategoryTab == nil then
    sV.pageCategoryTab = 1
  end
  if sV.lastCustomPage == nil then
    sV.lastCustomPage = 1
  end
  if sV.lastWWPage == nil then
    sV.lastWWPage = 1
  end
  if sV.setCategoryTab == nil then
    sV.setCategoryTab = 1
  end
  if sV.lastCustomSet == nil then
    sV.lastCustomSet = 1
  end
  if sV.lastWWSet == nil then
    sV.lastWWSet = 1
  end

  -- Migration: Clean obsolete [WW] prefix from saved pages and sets, tagging them with isWW = true
  if sV.pages then
    for _, page in ipairs(sV.pages) do
      if page.name and string.sub(page.name, 1, 5) == "[WW] " then
        page.isWW = true
        page.name = string.sub(page.name, 6)
      end
      if page.sets then
        for i, setName in ipairs(page.sets) do
          if string.sub(setName, 1, 5) == "[WW] " then
            page.sets[i] = string.sub(setName, 6)
          end
        end
      end
    end
  end
  if sV.gearSetList then
    for _, gearSet in ipairs(sV.gearSetList) do
      if gearSet.name and string.sub(gearSet.name, 1, 5) == "[WW] " then
        gearSet.isWW = true
        gearSet.name = string.sub(gearSet.name, 6)
      end
    end
  end

  if XLGB_Wardrobe and XLGB_Wardrobe.EnrichImportedSetsWithSetups then
    XLGB_Wardrobe:EnrichImportedSetsWithSetups()
  end
end

EVENT_MANAGER:RegisterForEvent(XLGearBanker.name, EVENT_ADD_ON_LOADED, XLGearBanker.OnAddOnLoaded)

-------------------------------------------------------------------------------
-- Slash Commands Dispatcher --
-- Note: Slash commands should not contain capital letters!
-------------------------------------------------------------------------------

function XLGearBanker:PrintSlashHelp()
  local C = XLGB_Constants
  local colTag = C.COLORS.CHAT_TAG
  local colCmd = C.COLORS.GOLD
  local colDesc = C.COLORS.WHITE
  local colMuted = C.COLORS.MUTED

  d(string.format("%s %s", colTag, C.Colorize(C.COLORS.GOLD_LIGHT, XLGB_GetString("SLASH_HELP_HEADER"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_MAIN"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb set"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_SETS"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb page"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_PAGES"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb ww"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_WW"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb settings"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_SETTINGS"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb debug"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_DEBUG"))))
  d(string.format("  %s %s %s", C.Colorize(colCmd, "/xlgb help"), C.Colorize(colMuted, "-"), C.Colorize(colDesc, XLGB_GetString("SLASH_HELP_HELP"))))
end

function XLGearBanker:HandleSlashCommand(extra)
  local args = {}
  if extra and extra ~= "" then
    for word in string.gmatch(extra, "%S+") do
      table.insert(args, word:lower())
    end
  end

  local cmd = args[1]

  if not cmd or cmd == "" then
    XLGB_UI:ToggleAllUI()
    return
  end

  if cmd == "help" or cmd == "?" then
    self:PrintSlashHelp()
  elseif cmd == "set" or cmd == "sets" then
    XLGB_UI:ToggleSetUI()
  elseif cmd == "page" or cmd == "pages" then
    XLGB_UI:TogglePageUI()
  elseif cmd == "ww" or cmd == "wardrobe" then
    if not WizardsWardrobe then
      d(string.format("%s %s", XLGB_Constants.COLORS.CHAT_WARNING, XLGB_GetString("SLASH_WW_NOT_AVAILABLE")))
    else
      XLGB_UI:ToggleWardrobeUI()
    end
  elseif cmd == "settings" or cmd == "config" or cmd == "options" or cmd == "opt" then
    XLGB_UI:ToggleSettings()
  elseif cmd == "debug" then
    local sVars = XLGearBanker.savedVariables or sV
    sVars.debug = not sVars.debug
    if sV then sV.debug = sVars.debug end
    local state = sVars.debug and XLGB_Constants.COLORS.Colorize(XLGB_Constants.COLORS.GREEN, "ON") or XLGB_Constants.COLORS.Colorize(XLGB_Constants.COLORS.RED, "OFF")
    d(string.format("%s %s", XLGB_Constants.COLORS.CHAT_TAG, XLGB_GetString("SLASH_DEBUG_STATE", state)))
  else
    d(string.format("%s %s", XLGB_Constants.COLORS.CHAT_ERROR, XLGB_GetString("SLASH_UNKNOWN_SUBCOMMAND", tostring(cmd))))
  end
end

-- Primary command
SLASH_COMMANDS["/xlgb"] = function(extra)
  XLGearBanker:HandleSlashCommand(extra)
end

-- Backward compatibility aliases
SLASH_COMMANDS["/xlgb_help"] = function() XLGearBanker:HandleSlashCommand("help") end
SLASH_COMMANDS["/xlgb_debug"] = function() XLGearBanker:HandleSlashCommand("debug") end
SLASH_COMMANDS["/xlgb_pages"] = function() XLGearBanker:HandleSlashCommand("page") end
SLASH_COMMANDS["/xlgb_page"] = SLASH_COMMANDS["/xlgb_pages"]
SLASH_COMMANDS["/xlgb_sets"] = function() XLGearBanker:HandleSlashCommand("set") end
SLASH_COMMANDS["/xlgb_set"] = SLASH_COMMANDS["/xlgb_sets"]
SLASH_COMMANDS["/xlgb_ww"] = function() XLGearBanker:HandleSlashCommand("ww") end
-------------------------------------------------------------------------------

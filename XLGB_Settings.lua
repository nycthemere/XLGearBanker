-- Namespace
XLGB_Settings = {}
local sV

function XLGB_Settings:Initialize()
  sV = XLGearBanker.savedVariables

  local LAM = LibAddonMenu2
  local menuName = "XL Gear Banker"

  local panelData = {
    type = "panel",
    name = menuName,
    displayName = "|cffecbc" .. menuName .. "|r",
    author = XLGearBanker.author,
    version = XLGearBanker.version,
    slashCommand = "/xlgb_settings",
    registerForRefresh = true
    -- registerForDefaults = true,
  }
  XLGB_Settings.panel = LAM:RegisterAddonPanel(menuName, panelData)

  local optionsTable = {}

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_SET_ON_OPEN"),
      getFunc = function()
        return sV.showSetWindowOnOpen
      end,
      setFunc = function(v)
        sV.showSetWindowOnOpen = v
      end,
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_PAGE_ON_OPEN"),
      getFunc = function()
        return sV.showPageWindowOnOpen
      end,
      setFunc = function(v)
        sV.showPageWindowOnOpen = v
      end,
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_WW_ON_OPEN"),
      tooltip = XLGB_GetString("SETTINGS_WW_ON_OPEN_DESC"),
      getFunc = function()
        return sV.showWardrobeWindowOnOpen
      end,
      setFunc = function(v)
        sV.showWardrobeWindowOnOpen = v
      end,
      disabled = function()
        return not WizardsWardrobe
      end,
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "divider",
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_SAFE_MODE"),
      tooltip = XLGB_GetString("SETTINGS_SAFE_MODE_DESC"),
      getFunc = function()
        return sV.safeMode
      end,
      setFunc = function(v)
        sV.safeMode = v
      end,
      width = "full",
      warning = XLGB_GetString("SETTINGS_SAFE_MODE_DESC"),
      disabled = function()
        return XLGB_Banking.isMovingItems or XLGB_Page.isMovingPage
      end
    }
  )

  table.insert(
    optionsTable,
    {
      type = "slider",
      name = XLGB_GetString("SETTINGS_DYNAMIC_SAFE_MODE"),
      tooltip = XLGB_GetString("SETTINGS_DYNAMIC_SAFE_MODE_DESC"),
      min = 50,
      max = 200,
      step = 1,
      getFunc = function()
        return sV.threshold
      end,
      setFunc = function(v)
        sV.threshold = v
      end,
      width = "full",
      disabled = function()
        return sV.safeMode
      end
    }
  )

  table.insert(
    optionsTable,
    {
      type = "divider",
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_REPORT_MISSING"),
      tooltip = XLGB_GetString("SETTINGS_REPORT_MISSING_DESC"),
      getFunc = function()
        return sV.reportMissing
      end,
      setFunc = function(v)
        sV.reportMissing = v
      end,
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_FAST_TRANSFER_JUNK_TAB"),
      tooltip = XLGB_GetString("SETTINGS_FAST_TRANSFER_JUNK_TAB_DESC"),
      getFunc = function()
        return sV.fastTransferJunkTab
      end,
      setFunc = function(v)
        sV.fastTransferJunkTab = v
      end,
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "checkbox",
      name = XLGB_GetString("SETTINGS_ENABLE_ITEM_CONTEXT_MENU"),
      tooltip = XLGB_GetString("SETTINGS_ENABLE_ITEM_CONTEXT_MENU_DESC"),
      getFunc = function()
        return sV.enableItemContextMenu == true
      end,
      setFunc = function(v)
        sV.enableItemContextMenu = v
      end,
      width = "full"
    }
  )

  table.insert(
    optionsTable,
    {
      type = "divider",
      width = "full"
    }
  )

  local function getColoredQualityName(quality)
    local name = (GetString and GetString("SI_ITEMDISPLAYQUALITY", quality)) or ""
    if name == "" and GetString then
      name = GetString("SI_ITEMQUALITY", quality) or ""
    end
    if name == "" then
      local fallbacks = { [1] = "Normal", [2] = "Fine", [3] = "Superior", [4] = "Epic", [5] = "Legendary" }
      name = fallbacks[quality] or ("Quality " .. tostring(quality))
    end
    if GetItemQualityColor then
      local color = GetItemQualityColor(quality)
      if color and color.Colorize then
        return color:Colorize(name)
      end
    end
    return name
  end

  local function buildQualitySubmenu(title, tooltip, qualityTable, isWithdraw, moduleType)
    local controls = {
      {
        type = "description",
        text = XLGB_GetString("QUALITY_CONTEXT_TITLE", isWithdraw and XLGB_GetString("QUALITY_WITHDRAW_NAME") or XLGB_GetString("QUALITY_DEPOSIT_NAME"), moduleType),
        width = "full"
      },
      {
        type = "button",
        name = XLGB_GetString("QUALITY_SELECT_ALL"),
        width = "half",
        func = function()
          for q = 1, 5 do
            qualityTable[q] = true
          end
          if XLGB_UI and XLGB_UI.RefreshQualityFilters then
            XLGB_UI:RefreshQualityFilters()
          end
          if moduleType == "wardrobe" and XLGB_UI and XLGB_UI.UpdateWardrobeUI then
            XLGB_UI:UpdateWardrobeUI()
          end
        end
      },
      {
        type = "button",
        name = XLGB_GetString("QUALITY_CLEAR_ALL"),
        width = "half",
        func = function()
          for q = 1, 5 do
            qualityTable[q] = false
          end
          if XLGB_UI and XLGB_UI.RefreshQualityFilters then
            XLGB_UI:RefreshQualityFilters()
          end
          if moduleType == "wardrobe" and XLGB_UI and XLGB_UI.UpdateWardrobeUI then
            XLGB_UI:UpdateWardrobeUI()
          end
        end
      }
    }

    for q = 1, 5 do
      local qualityIndex = q
      table.insert(controls, {
        type = "checkbox",
        name = getColoredQualityName(qualityIndex),
        getFunc = function()
          return qualityTable[qualityIndex] == true
        end,
        setFunc = function(v)
          qualityTable[qualityIndex] = v
          if XLGB_UI and XLGB_UI.RefreshQualityFilters then
            XLGB_UI:RefreshQualityFilters()
          end
          if moduleType == "wardrobe" and XLGB_UI and XLGB_UI.UpdateWardrobeUI then
            XLGB_UI:UpdateWardrobeUI()
          end
        end,
        width = "full",
        default = true
      })
    end

    return {
      type = "submenu",
      name = title,
      tooltip = tooltip,
      controls = controls,
      disabled = function()
        if moduleType == "wardrobe" and not WizardsWardrobe then
          return true
        end
        return false
      end
    }
  end

  -- Pages
  table.insert(optionsTable, {
    type = "header",
    name = XLGB_GetString("SETTINGS_QUALITY_FILTERS_PAGE"),
    width = "full"
  })
  table.insert(optionsTable, buildQualitySubmenu(XLGB_GetString("SETTINGS_QUALITY_FILTERS_PAGE_WITHDRAW"), XLGB_GetString("SETTINGS_QUALITY_FILTERS_PAGE_WITHDRAW_DESC"), sV.pageWithdrawQualities, true, "page"))
  table.insert(optionsTable, buildQualitySubmenu(XLGB_GetString("SETTINGS_QUALITY_FILTERS_PAGE_DEPOSIT"), XLGB_GetString("SETTINGS_QUALITY_FILTERS_PAGE_DEPOSIT_DESC"), sV.pageDepositQualities, false, "page"))

  -- Sets
  table.insert(optionsTable, {
    type = "header",
    name = XLGB_GetString("SETTINGS_QUALITY_FILTERS_SET"),
    width = "full"
  })
  table.insert(optionsTable, buildQualitySubmenu(XLGB_GetString("SETTINGS_QUALITY_FILTERS_SET_WITHDRAW"), XLGB_GetString("SETTINGS_QUALITY_FILTERS_SET_WITHDRAW_DESC"), sV.setWithdrawQualities, true, "set"))
  table.insert(optionsTable, buildQualitySubmenu(XLGB_GetString("SETTINGS_QUALITY_FILTERS_SET_DEPOSIT"), XLGB_GetString("SETTINGS_QUALITY_FILTERS_SET_DEPOSIT_DESC"), sV.setDepositQualities, false, "set"))

  -- Wizard's Wardrobe
  table.insert(optionsTable, {
    type = "header",
    name = XLGB_GetString("SETTINGS_QUALITY_FILTERS_WW"),
    width = "full"
  })
  table.insert(optionsTable, buildQualitySubmenu(XLGB_GetString("QUALITY_CONTEXT_TITLE", XLGB_GetString("QUALITY_WITHDRAW_NAME"), "Wardrobe"), XLGB_GetString("QUALITY_WITHDRAW_TOOLTIP"), sV.wardrobeWithdrawQualities, true, "wardrobe"))
  table.insert(optionsTable, buildQualitySubmenu(XLGB_GetString("SETTINGS_QUALITY_FILTERS_WW_DEPOSIT"), XLGB_GetString("SETTINGS_QUALITY_FILTERS_WW_DEPOSIT_DESC"), sV.wardrobeDepositQualities, false, "wardrobe"))

  -- Quick Set Keybind (Wizard's Wardrobe)
  table.insert(optionsTable, {
    type = "header",
    name = XLGB_GetString("SETTINGS_QUICK_SET_HEADER"),
    width = "full"
  })
  table.insert(optionsTable, {
    type = "editbox",
    name = XLGB_GetString("SETTINGS_QUICK_SET_TARGET"),
    tooltip = XLGB_GetString("SETTINGS_QUICK_SET_TARGET_DESC"),
    getFunc = function() return sV.quickSetTargetName or "" end,
    setFunc = function(v) sV.quickSetTargetName = v end,
    width = "full"
  })
  table.insert(optionsTable, {
    type = "dropdown",
    name = XLGB_GetString("SETTINGS_QUICK_SET_DETECTED_DROPDOWN"),
    tooltip = XLGB_GetString("SETTINGS_QUICK_SET_DETECTED_DROPDOWN_DESC"),
    choices = function()
      local list = { "-" }
      if WizardsWardrobe and WizardsWardrobe.selection and XLGB_Wardrobe then
        local zoneTag = WizardsWardrobe.selection.zone and WizardsWardrobe.selection.zone.tag or "GEN"
        local pageId = WizardsWardrobe.selection.pageId or 1
        local charId = WizardsWardrobe.currentCharacterId
        if charId then
          local _, setsList = XLGB_Wardrobe:GetPageGear(charId, zoneTag, pageId)
          if setsList then
            for _, s in ipairs(setsList) do
              if s.setName and s.setName ~= "" and not s.isIsolated then
                table.insert(list, s.setName)
              end
            end
          end
        end
      end
      return list
    end,
    getFunc = function()
      return (sV.quickSetTargetName and sV.quickSetTargetName ~= "") and sV.quickSetTargetName or "-"
    end,
    setFunc = function(v)
      if v ~= "-" then
        sV.quickSetTargetName = v
      end
    end,
    width = "full",
    disabled = function() return not WizardsWardrobe end
  })
  table.insert(optionsTable, {
    type = "dropdown",
    name = XLGB_GetString("SETTINGS_QUICK_SET_CONFLICT_CHOICE"),
    tooltip = XLGB_GetString("SETTINGS_QUICK_SET_CONFLICT_CHOICE_DESC"),
    choices = function()
      local list = { "Demander en jeu (Menu contextuel)" }
      if WizardsWardrobe and WizardsWardrobe.selection and XLGB_Command then
        local zoneTag = WizardsWardrobe.selection.zone and WizardsWardrobe.selection.zone.tag or "GEN"
        local pageId = WizardsWardrobe.selection.pageId or 1
        local matches = XLGB_Command:FindSetupsWithSet(zoneTag, pageId, sV.quickSetTargetName)
        for _, m in ipairs(matches) do
          table.insert(list, string.format("[%d] %s", m.index, m.name))
        end
      end
      return list
    end,
    getFunc = function()
      if WizardsWardrobe and WizardsWardrobe.selection and XLGB_Command then
        local charId = WizardsWardrobe.currentCharacterId
        local zoneTag = WizardsWardrobe.selection.zone and WizardsWardrobe.selection.zone.tag or "GEN"
        local pageId = WizardsWardrobe.selection.pageId or 1
        local saved = XLGB_Command:GetSavedSetupChoice(charId, zoneTag, pageId, sV.quickSetTargetName)
        if saved and saved.index and saved.name then
          return string.format("[%d] %s", saved.index, saved.name)
        end
      end
      return "Demander en jeu (Menu contextuel)"
    end,
    setFunc = function(v)
      if WizardsWardrobe and WizardsWardrobe.selection and XLGB_Command then
        local charId = WizardsWardrobe.currentCharacterId
        local zoneTag = WizardsWardrobe.selection.zone and WizardsWardrobe.selection.zone.tag or "GEN"
        local pageId = WizardsWardrobe.selection.pageId or 1
        local idx = string.match(v, "%[(%d+)%]")
        if idx then
          idx = tonumber(idx)
          local name = string.gsub(v, "%[%d+%]%s*", "")
          XLGB_Command:SaveSetupChoice(charId, zoneTag, pageId, sV.quickSetTargetName, idx, name)
        end
      end
    end,
    width = "full",
    disabled = function()
      if not WizardsWardrobe or not WizardsWardrobe.selection or not XLGB_Command then return true end
      local zoneTag = WizardsWardrobe.selection.zone and WizardsWardrobe.selection.zone.tag or "GEN"
      local pageId = WizardsWardrobe.selection.pageId or 1
      local matches = XLGB_Command:FindSetupsWithSet(zoneTag, pageId, sV.quickSetTargetName)
      return #matches <= 1
    end
  })

  table.insert(
    optionsTable,
    {
      type = "divider",
      width = "full"
    }
  )

  LAM:RegisterOptionControls(menuName, optionsTable)
end

-- function xlHoF.UnlockEnableUIUpdate(alert)
--     if alert.unlock and alert.enable then
--         alert.control:SetHidden(false)
--     else
--         alert.control:SetHidden(true)
--     end
-- end

-- function xlHoF.GenerateSettingsForAlert(alert)
--     return
--     {
--         type        = "header",
--         name        = xlHoF.Colorize(alert.settingsHeader, alert.color),
--         width       = "full",	--or "half" (optional)
--     },
--     {
--         type        = "description",
--         text        = alert.description,
--         width       = "full",
--     },
--     {
--         type        = "checkbox",
--         name        = SI_XLHOF_SETTINGS_ENABLE,
--         tooltip     = SI_XLHOF_SETTINGS_ENABLE_TOOLTIP,
--         getFunc     = function() return alert.enable end,
--         setFunc     = function(v)
--                         alert.enable = v
--                         xlHoF.UnlockEnableUIUpdate(alert)
--                     end,
--         width       = "full",
--     },
--     {
--         type        = "checkbox",
--         name        = SI_XLHOF_SETTINGS_UNLOCK,
--         tooltip     = SI_XLHOF_SETTINGS_UNLOCK_TOOLTIP,
--         getFunc     = function() return alert.unlock end,
--         setFunc     = function(v)
--                         alert.unlock = v
--                         if not v then sV.unlockAll = false end
--                         xlHoF.UnlockEnableUIUpdate(alert)
--                     end,
--         width       = "full",
--         warning     = SI_XLHOF_SETTINGS_UNLOCK_WARNING,
--         disabled    = function() return not alert.enable end,
--     },
--     {
--         type        = "slider",
--         name        = SI_XLHOF_SETTINGS_SIZE,
--         tooltip     = SI_XLHOF_SETTINGS_SIZE_TOOLTIP,
--         min         = 16,
--         max         = 64,
--         step        = 2,
--         getFunc     = function() return alert.fontSize end,
--         setFunc     = function(v)
--                         alert.fontSize = v
--                         xlHoF.SetLabelFontSize(alert.control, alert.fontSize)
--                     end,
--         width       = "full",
--         warning     = SI_XLHOF_SETTINGS_SIZE_WARNING,
--         disabled    = function()
--                         return not (alert.unlock and alert.enable)
--                     end,
--     }
-- end

-- table.insert(
--     optionsTable,
--     {
--         type = "checkbox",
--         name = "Account Wide",
--         tooltip = "Use the same settings throughout the entire account - instead of per character.",
--         getFunc = function()
--             return xlHoF.savedVariables.accountWide
--         end,
--         setFunc = function(v)
--             xlHoF.characterSavedVars.accountWide = v
--             xlHoF.accountSavedVars.accountWide = v
--         end,
--         width = "full", --or "half",
--         requiresReload = true,
--     }
-- )

-- -- Category. --
-- table.insert(optionsTable, {
--     type = "header",
--     name = ZO_HIGHLIGHT_TEXT:Colorize("My Header"),
--     width = "full",	--or "half" (optional)
-- })

-- table.insert(optionsTable, {
--     type = "description",
--     --title = "My Title",	--(optional)
--     title = nil,	--(optional)
--     text = "My description text to display.",
--     width = "full",	--or "half" (optional)
-- })

-- table.insert(optionsTable, {
--     type = "dropdown",
--     name = "My Dropdown",
--     tooltip = "Dropdown's tooltip text.",
--     choices = {"table", "of", "choices"},
--     getFunc = function() return "of" end,
--     setFunc = function(var) print(var) end,
--     width = "half",	--or "half" (optional)
--     warning = "Will need to reload the UI.",	--(optional)
-- })

-- table.insert(optionsTable, {
--     type = "dropdown",
--     name = "My Dropdown",
--     tooltip = "Dropdown's tooltip text.",
--     choices = {"table", "of", "choices"},
--     getFunc = function() return "of" end,
--     setFunc = function(var) print(var) end,
--     width = "half",	--or "half" (optional)
--     warning = "Will need to reload the UI.",	--(optional)
-- })

-- table.insert(optionsTable, {
--     type = "slider",
--     name = "My Slider",
--     tooltip = "Slider's tooltip text.",
--     min = 0,
--     max = 20,
--     step = 1,	--(optional)
--     getFunc = function() return 3 end,
--     setFunc = function(value) d(value) end,
--     width = "half",	--or "half" (optional)
--     default = 5,	--(optional)
-- })

-- table.insert(optionsTable, {
--     type = "button",
--     name = "My Button",
--     tooltip = "Button's tooltip text.",
--     func = function() d("button pressed!") end,
--     width = "half",	--or "half" (optional)
--     warning = "Will need to reload the UI.",	--(optional)
-- })

-- table.insert(optionsTable, {
--     type = "submenu",
--     name = "Submenu Title",
--     tooltip = "My submenu tooltip",	--(optional)
--     controls = {
--         [1] = {
--             type = "checkbox",
--             name = "My Checkbox",
--             tooltip = "Checkbox's tooltip text.",
--             getFunc = function() return true end,
--             setFunc = function(value) d(value) end,
--             width = "half",	--or "half" (optional)
--             warning = "Will need to reload the UI.",	--(optional)
--         },
--         [2] = {
--             type = "colorpicker",
--             name = "My Color Picker",
--             tooltip = "Color Picker's tooltip text.",
--             getFunc = function() return 1, 0, 0, 1 end,	--(alpha is optional)
--             setFunc = function(r,g,b,a) print(r, g, b, a) end,	--(alpha is optional)
--             width = "half",	--or "half" (optional)
--             warning = "warning text",
--         },
--         [3] = {
--             type = "editbox",
--             name = "My Editbox",
--             tooltip = "Editbox's tooltip text.",
--             getFunc = function() return "this is some text" end,
--             setFunc = function(text) print(text) end,
--             isMultiline = false,	--boolean
--             width = "half",	--or "half" (optional)
--             warning = "Will need to reload the UI.",	--(optional)
--             default = "",	--(optional)
--         },
--     },
-- })

-- table.insert(optionsTable, {
--     type = "custom",
--     reference = "MyAddonCustomControl",	--unique name for your control to use as reference
--     refreshFunc = function(customControl) end,	--(optional) function to call when panel/controls refresh
--     width = "half",	--or "half" (optional)
-- })

-- table.insert(optionsTable, {
--     type = "texture",
--     image = "EsoUI\\Art\\ActionBar\\abilityframe64_up.dds",
--     imageWidth = 64,	--max of 250 for half width, 510 for full
--     imageHeight = 64,	--max of 100
--     tooltip = "Image's tooltip text.",	--(optional)
--     width = "half",	--or "half" (optional)
-- })

--[[
  XLGB_Command.lua

  Command Pattern & Combat Buffer for Wizard's Wardrobe Quick Set Keybind.
  - Intercepts setup load requests to prevent spamming / queuing multiple swaps in WW during combat.
  - If triggered in combat, buffers the command until combat drops.
  - If re-pressed in combat (Undo), cancels the pending command cleanly without ever notifying WW.
  - When pressed out of combat, performs the swap and maintains a persistent LIFO Undo stack
    in savedVariables (sV.quickSetUndoStack) so that pressing the keybind returns to the previous setup.
  - Solves the corner case of /reloadui or disconnect/reconnect:
    Before switching, the previous setup is pushed onto the persistent stack.
    On reload/reconnect, the stack and current worn gear are evaluated so that pressing the keybind
    pops the stack and returns to the previous setup instead of reapplying the switch.
  - Detects conflicts when multiple setups in the filtered scope (Character, Trial/Zone, WW Page) contain the targeted set,
    and displays the conflicting setup names for user selection.
]]--

XLGB_Command = {}
local CMD = XLGB_Command

CMD.pendingCommand = nil
CMD.isToggled = false
CMD.lastKeyPressTime = 0

function CMD:Initialize()
  self.pendingCommand = nil
  self.isToggled = false
  self.lastKeyPressTime = 0

  EVENT_MANAGER:RegisterForEvent("XLGB_Command_CombatState", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
    CMD:OnCombatStateChanged(inCombat)
  end)

  EVENT_MANAGER:RegisterForEvent("XLGB_Command_Alive", EVENT_PLAYER_ALIVE, function()
    CMD:OnCombatStateChanged(IsUnitInCombat("player"))
  end)

  EVENT_MANAGER:RegisterForEvent("XLGB_Command_Reincarnated", EVENT_PLAYER_REINCARNATED, function()
    CMD:OnCombatStateChanged(IsUnitInCombat("player"))
  end)
end

function CMD:OnCombatStateChanged(inCombat)
  if not inCombat and self.pendingCommand then
    local cmd = self.pendingCommand
    self.pendingCommand = nil

    if XLGearBanker.logger then
      XLGearBanker.logger:Info("Combat ended: executing buffered setup swap to: " .. tostring(cmd.targetName))
    end

    cmd:Execute()
    PlaySound(SOUNDS.ABILITY_WEAPON_SWAP)
    d(string.format(XLGB_GetString("QUICK_SET_COMBAT_ENDED_APPLIED"), cmd.targetName or "Setup"))
  end
end

-- Retrieves character id as string
function CMD:GetCurrentCharId()
  local charId = nil
  if GetCurrentCharacterId then
    charId = tostring(Id64ToString(GetCurrentCharacterId()))
  end
  if (not charId or charId == "" or charId == "0") and WizardsWardrobe and WizardsWardrobe.currentCharacterId then
    charId = tostring(WizardsWardrobe.currentCharacterId)
  end
  return charId or "default"
end

-- ── PERSISTENT UNDO STACK (savedVariables: quickSetUndoStack[charId]) ──

function CMD:GetUndoStack(charId)
  local sV = XLGearBanker.savedVariables
  if not sV then return {} end
  sV.quickSetUndoStack = sV.quickSetUndoStack or {}
  charId = tostring(charId or self:GetCurrentCharId())
  sV.quickSetUndoStack[charId] = sV.quickSetUndoStack[charId] or {}
  return sV.quickSetUndoStack[charId]
end

function CMD:PushUndo(charId, entry)
  local stack = self:GetUndoStack(charId)
  table.insert(stack, entry)
  while #stack > 10 do
    table.remove(stack, 1)
  end
end

function CMD:PopUndo(charId)
  local stack = self:GetUndoStack(charId)
  if #stack == 0 then return nil end
  return table.remove(stack)
end

function CMD:PeekUndo(charId)
  local stack = self:GetUndoStack(charId)
  if #stack == 0 then return nil end
  return stack[#stack]
end

function CMD:ClearUndoStack(charId)
  local sV = XLGearBanker.savedVariables
  if not sV or not sV.quickSetUndoStack then return end
  charId = tostring(charId or self:GetCurrentCharId())
  sV.quickSetUndoStack[charId] = {}
end

-- ── CHECKS IF CURRENTLY WEARING TARGET SET ──
function CMD:IsWearingSet(targetSetName, targetSetId)
  if (not targetSetName or targetSetName == "") and (not targetSetId or targetSetId == 0) then
    return false
  end
  local targetLower = (targetSetName and targetSetName ~= "") and zo_strlower(targetSetName) or nil

  local bag = BAG_WORN
  local slot = ZO_GetNextBagSlotIndex(bag)
  while slot do
    local link = GetItemLink(bag, slot)
    if link and link ~= "" then
      local isSet, setName, setId = XLGB_Inventory:GetItemSetInfo(link)
      if isSet then
        if targetSetId and targetSetId > 0 and setId == targetSetId then
          return true
        end
        if targetLower and setName then
          local setLower = zo_strlower(setName)
          if setLower == targetLower or zo_strfind(setLower, targetLower, 1, true) or zo_strfind(targetLower, setLower, 1, true) then
            return true
          end
        end
      end
    end
    slot = ZO_GetNextBagSlotIndex(bag, slot)
  end
  return false
end

-- ── DETECTS CURRENT SETUP (Even when WW.currentIndex is 0 after reloadui/relog) ──
function CMD:DetectCurrentSetup(zoneTag, pageId)
  local WW = WizardsWardrobe
  if WW and WW.currentIndex and WW.currentIndex > 0 then
    local setup = Setup and Setup.FromStorage and Setup:FromStorage(zoneTag, pageId, WW.currentIndex)
    local name = (setup and not setup:IsEmpty()) and setup:GetName() or ("Setup " .. WW.currentIndex)
    return WW.currentIndex, name
  end

  if not WW or not WW.setups or not Setup or not Setup.FromStorage then
    return 0, "Unknown"
  end

  local zoneSetups = WW.setups[zoneTag]
  local pageSetups = zoneSetups and zoneSetups[pageId]
  if not pageSetups then return 0, "Unknown" end

  local bestIndex = 0
  local bestScore = 0
  local bestName = "Unknown"

  local gearSlots = WW.GEARSLOTS or {}

  for index = 1, #pageSetups do
    local setup = Setup:FromStorage(zoneTag, pageId, index)
    if setup and not setup:IsEmpty() and not setup:IsDisabled() then
      local gear = setup:GetGear() or setup.gear
      if gear then
        local matchScore = 0
        for _, gearSlot in ipairs(gearSlots) do
          local item = gear[gearSlot]
          if item and item.link and item.link ~= "" then
            local wornLink = GetItemLink(BAG_WORN, gearSlot)
            if wornLink and wornLink ~= "" then
              local wornId = Id64ToString(GetItemUniqueId(BAG_WORN, gearSlot))
              if item.id and item.id ~= "" and item.id == wornId then
                matchScore = matchScore + 2
              elseif item.link == wornLink then
                matchScore = matchScore + 1
              end
            end
          end
        end
        if matchScore > bestScore then
          bestScore = matchScore
          bestIndex = index
          bestName = setup:GetName() or ("Setup " .. index)
        end
      end
    end
  end

  if bestScore >= 4 then
    return bestIndex, bestName
  end

  return 0, "Unknown"
end

-- ── EXECUTES SETUP SWAP IN WIZARD'S WARDROBE ──
function CMD:ExecuteSetupSwap(zoneTag, pageId, index, name)
  local WW = WizardsWardrobe
  if not WW or not WW.LoadSetup or not index or index <= 0 then return false end
  local zoneObj = (WW.zones and WW.zones[zoneTag]) or { tag = zoneTag }
  if WW.Log and WW.LOGTYPES then
    WW.Log(string.format(XLGB_GetString("QUICK_SET_LOG_LOADING"), name or ("Setup " .. index)), WW.LOGTYPES.NORMAL)
  end
  WW.LoadSetup(zoneObj, pageId, index, false, false)
  return true
end

-- Searches setups within the filtered scope (zoneTag and pageId) containing targetSetName or targetSetId
function CMD:FindSetupsWithSet(zoneTag, pageId, targetSetName, targetSetId)
  if not WizardsWardrobe or not WizardsWardrobe.setups then return {} end
  local zoneSetups = WizardsWardrobe.setups[zoneTag]
  local pageSetups = zoneSetups and zoneSetups[pageId]
  if not pageSetups then return {} end

  local matches = {}
  local targetLower = (targetSetName and targetSetName ~= "") and zo_strlower(targetSetName) or ""

  for index = 1, #pageSetups do
    local setup = Setup and Setup.FromStorage and Setup:FromStorage(zoneTag, pageId, index)
    if setup and not setup:IsEmpty() and not setup:IsDisabled() then
      local gear = setup:GetGear() or setup.gear
      local found = false

      if gear then
        local gearSlots = WizardsWardrobe.GEARSLOTS or {}
        for _, gearSlot in ipairs(gearSlots) do
          local item = gear[gearSlot]
          if item and item.link and item.link ~= "" then
            local isSet, setName, setId = XLGB_Inventory:GetItemSetInfo(item.link)
            if isSet then
              if (targetSetId and targetSetId > 0 and setId == targetSetId) or
                 (targetLower ~= "" and setName and zo_strlower(setName) == targetLower) or
                 (targetLower ~= "" and setName and zo_strfind(zo_strlower(setName), targetLower, 1, true)) then
                found = true
                break
              end
            end
          end
        end
      end

      if found then
        table.insert(matches, {
          index = index,
          name = setup:GetName() or ("Setup " .. index),
          setup = setup,
        })
      end
    end
  end

  return matches
end

-- Retrieves user's previously chosen setup when a conflict exists on this character/zone/page
function CMD:GetSavedSetupChoice(charId, zoneTag, pageId, targetSetName)
  local sV = XLGearBanker.savedVariables
  if not sV or not sV.quickSetChoices then return nil end
  local c = sV.quickSetChoices
  if c[charId] and c[charId][zoneTag] and c[charId][zoneTag][pageId] then
    return c[charId][zoneTag][pageId][targetSetName]
  end
  return nil
end

-- Persists user's choice for this character/zone/page
function CMD:SaveSetupChoice(charId, zoneTag, pageId, targetSetName, index, name)
  local sV = XLGearBanker.savedVariables
  if not sV then return end
  sV.quickSetChoices = sV.quickSetChoices or {}
  sV.quickSetChoices[charId] = sV.quickSetChoices[charId] or {}
  sV.quickSetChoices[charId][zoneTag] = sV.quickSetChoices[charId][zoneTag] or {}
  sV.quickSetChoices[charId][zoneTag][pageId] = sV.quickSetChoices[charId][zoneTag][pageId] or {}
  sV.quickSetChoices[charId][zoneTag][pageId][targetSetName] = { index = index, name = name }

  if XLGearBanker.logger then
    XLGearBanker.logger:Info(string.format("Saved Quick Set choice: [%d] %s for %s/%s/%s", index, name, tostring(charId), tostring(zoneTag), tostring(pageId)))
  end
end

-- Displays interactive context menu listing conflicting setup names so the user can choose
function CMD:ShowConflictSelectionMenu(matches, charId, zone, pageId, inCombat, targetSetName)
  ClearMenu()
  local title = "|cffecbc=== " .. (targetSetName or "") .. " ===|r"
  AddCustomMenuItem(title, nil)
  local purposeText = "|cffffff" .. XLGB_GetString("QUICK_SET_CONFLICT_MENU_PURPOSE") .. "|r"
  AddCustomMenuItem(purposeText, nil)
  local headerText = string.format("|cffff00" .. XLGB_GetString("QUICK_SET_CONFLICT_MENU_HEADER") .. "|r", targetSetName or "", #matches)
  AddCustomMenuItem(headerText, nil)

  for _, match in ipairs(matches) do
    local label = string.format("  > [%d] %s", match.index, match.name)
    AddCustomMenuItem(label, function()
      CMD:SaveSetupChoice(charId, zone.tag, pageId, targetSetName, match.index, match.name)
      d(string.format(XLGB_GetString("QUICK_SET_SAVED_CHOICE_MSG"), match.name, targetSetName))
      CMD:DispatchCommand(zone, pageId, match.index, match.name, inCombat, targetSetName)
    end)
  end

  ShowMenu()
end

-- Displays conflict resolution menu at establishment time
function CMD:PromptConflictResolution(targetSetName, matches, charId, zoneTag, pageId)
  ClearMenu()
  local title = "|cffecbc=== " .. (targetSetName or "") .. " ===|r"
  AddCustomMenuItem(title, nil)
  local purposeText = "|cffffff" .. XLGB_GetString("QUICK_SET_CONFLICT_MENU_PURPOSE") .. "|r"
  AddCustomMenuItem(purposeText, nil)
  local headerText = string.format("|cffff00" .. XLGB_GetString("QUICK_SET_CONFLICT_MENU_HEADER") .. "|r", targetSetName or "", #matches)
  AddCustomMenuItem(headerText, nil)

  for _, match in ipairs(matches) do
    local label = string.format("  > [%d] %s", match.index, match.name)
    AddCustomMenuItem(label, function()
      self:SaveSetupChoice(charId, zoneTag, pageId, targetSetName, match.index, match.name)
      PlaySound(SOUNDS.BOOK_PAGE_TURN)
      self:CheckAndWarnKeybind(targetSetName, match.name)
    end)
  end

  ShowMenu()
end

-- Dispatches the swap command directly or buffers it if in combat
function CMD:DispatchCommand(zone, pageId, targetIndex, targetName, inCombat, targetSetName)
  local charId = self:GetCurrentCharId()
  local prevIndex, prevName = self:DetectCurrentSetup(zone.tag, pageId)
  local prevSetup = {
    zoneTag = zone.tag,
    pageId = pageId,
    index = prevIndex,
    name = prevName,
  }
  local targetSetup = {
    zoneTag = zone.tag,
    pageId = pageId,
    index = targetIndex,
    name = targetName,
    setName = targetSetName,
  }

  local cmd = {
    targetName = targetName,
    charId = charId,
    Execute = function()
      -- Empile le setup 'avant' (prevSetup) avant d'exécuter le switch vers la cible
      CMD:PushUndo(charId, { prev = prevSetup, target = targetSetup, timestamp = GetTimeStamp() })
      CMD:ExecuteSetupSwap(zone.tag, pageId, targetIndex, targetName)
      CMD.isToggled = true
    end,
  }

  if inCombat then
    CMD.pendingCommand = cmd
    PlaySound(SOUNDS.ABILITY_WEAPON_SWAP)
    d(string.format(XLGB_GetString("QUICK_SET_IN_COMBAT_BUFFERED"), targetName))
  else
    cmd:Execute()
  end
end

-- Dispatches the undo command (pop from stack) directly or buffers it if in combat
function CMD:DispatchUndo(entry, inCombat)
  local charId = self:GetCurrentCharId()
  local prevSetup = entry.prev
  local targetName = (prevSetup and prevSetup.name) or ("Setup " .. tostring(prevSetup and prevSetup.index or 0))

  local cmd = {
    targetName = targetName,
    charId = charId,
    isUndo = true,
    Execute = function()
      -- Dépile le setup précédent enregistré pour revenir sur lui
      local popped = CMD:PopUndo(charId)
      if popped and popped.prev and popped.prev.index and popped.prev.index > 0 then
        CMD:ExecuteSetupSwap(popped.prev.zoneTag, popped.prev.pageId, popped.prev.index, popped.prev.name)
        CMD.isToggled = false
        PlaySound(SOUNDS.INVENTORY_ITEM_EQUIP)
        d(string.format(XLGB_GetString("QUICK_SET_LOG_UNDOING"), popped.prev.name or ("Setup " .. popped.prev.index)))
      else
        CMD.isToggled = false
        d(XLGB_GetString("QUICK_SET_UNDO_CANNOT_RESTORE"))
      end
    end,
  }

  if inCombat then
    CMD.pendingCommand = cmd
    PlaySound(SOUNDS.ABILITY_WEAPON_SWAP)
    d(string.format(XLGB_GetString("QUICK_SET_IN_COMBAT_BUFFERED_UNDO"), targetName))
  else
    cmd:Execute()
  end
end

-- Entry point called by keybind
function CMD:OnQuickSetKeybindPressed()
  local WW = WizardsWardrobe
  if not WW then
    d("|cFF5555[XLGB]|r " .. XLGB_GetString("WW_NOT_DETECTED"))
    return
  end

  -- Débouncing rapide pour éviter les doubles clics accidentels
  local now = GetGameTimeMilliseconds()
  if self.lastKeyPressTime and (now - self.lastKeyPressTime) < 500 then
    return
  end
  self.lastKeyPressTime = now

  local inCombat = IsUnitInCombat("player")
  local charId = self:GetCurrentCharId()

  -- ── 1. CAS COMBAT : ANNULATION / UNDO DU BUFFER ──
  -- Si une commande est en attente dans notre tampon, la réactivation en combat est un UNDO pur :
  -- On annule la commande avant même que WW n'ait commencé à la traiter !
  if inCombat and self.pendingCommand then
    local cancelledName = self.pendingCommand.targetName or "Setup"
    self.pendingCommand = nil
    PlaySound(SOUNDS.NEGATIVE_TOOLTIP_CLICK)
    d(string.format(XLGB_GetString("QUICK_SET_IN_COMBAT_CANCELLED"), cancelledName))
    return
  end

  local zone = WW.selection and WW.selection.zone
  if not zone and WW.currentZone then zone = WW.currentZone end
  local zoneTag = zone and zone.tag or "GEN"
  local pageId = (WW.selection and WW.selection.pageId) or 1

  local sV = XLGearBanker.savedVariables
  local targetSetName = sV and sV.quickSetTargetName or ""

  if not targetSetName or targetSetName == "" then
    d(XLGB_GetString("QUICK_SET_NO_TARGET_CONFIGURED"))
    return
  end

  -- ── 2. VÉRIFICATION DE LA PILE UNDO (Persistante dans savedVariables) ──
  local top = self:PeekUndo(charId)
  local isCurrentlyOnTarget = false

  if top and top.prev and top.prev.index and top.prev.index > 0 then
    if self.isToggled then
      isCurrentlyOnTarget = true
    elseif self:IsWearingSet(top.target and top.target.setName or targetSetName) then
      -- Couvre le cas de reloadui ou reconnexion : le joueur porte le set du target !
      isCurrentlyOnTarget = true
    elseif WW.currentIndex and top.target and WW.currentIndex > 0 and WW.currentIndex == top.target.index and zoneTag == top.target.zoneTag then
      isCurrentlyOnTarget = true
    end
  end

  -- ── 3. RESAISIE = POP DE LA PILE POUR REVENIR SUR LE SETUP PRÉCÉDENT ──
  if isCurrentlyOnTarget and top then
    self:DispatchUndo(top, inCombat)
    return
  end

  -- Si la pile contenait une entrée périmée (ex: joueur n'est plus sur le target et ne porte plus le set)
  if top and not isCurrentlyOnTarget then
    self:ClearUndoStack(charId)
  end

  -- ── 4. RÉSOLUTION DU SETUP DANS LE SCOPE COURANT (Perso, Trial, Page) ──
  local matches = self:FindSetupsWithSet(zoneTag, pageId, targetSetName)

  if #matches == 0 then
    local zoneName = zone and zone.name or zoneTag
    d(string.format(XLGB_GetString("QUICK_SET_NO_SETUPS_FOUND"), targetSetName, zoneName, pageId))
    return
  end

  -- ── 5. GESTION DES CONFLITS (Plusieurs setups avec ce set) ──
  if #matches > 1 then
    local savedChoice = self:GetSavedSetupChoice(charId, zoneTag, pageId, targetSetName)
    local chosenMatch = nil

    if savedChoice and savedChoice.index then
      for _, m in ipairs(matches) do
        if m.index == savedChoice.index then
          chosenMatch = m
          break
        end
      end
    end

    if chosenMatch then
      self:DispatchCommand(zone, pageId, chosenMatch.index, chosenMatch.name, inCombat, targetSetName)
    elseif inCombat then
      -- En combat sans choix préalable : on utilise le premier setup sans ouvrir de menu bloquant
      self:DispatchCommand(zone, pageId, matches[1].index, matches[1].name, inCombat, targetSetName)
    else
      -- Hors combat sans choix préalable : affiche la liste des noms des setups en conflit
      self:ShowConflictSelectionMenu(matches, charId, zone, pageId, inCombat, targetSetName)
    end
  else
    -- Un seul setup trouvé : sélection automatique directe
    self:DispatchCommand(zone, pageId, matches[1].index, matches[1].name, inCombat, targetSetName)
  end
end

-- Returns the formatted key name bound to XLGB_QUICK_SET_TOGGLE, or nil if unbound
function CMD:GetQuickSetKeybindString()
  if not (GetActionIndicesFromName and GetActionBindingInfo and GetKeyName) then return nil end
  local layer, category, action = GetActionIndicesFromName("XLGB_QUICK_SET_TOGGLE")
  if not layer then return nil end
  local maxBindings = GetMaxBindingsPerAction and GetMaxBindingsPerAction() or 4
  for bindingIndex = 1, maxBindings do
    local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layer, category, action, bindingIndex)
    if key and key ~= 0 and key ~= KEY_INVALID then
      local parts = {}
      for _, mod in ipairs({ mod1, mod2, mod3, mod4 }) do
        if mod and mod ~= 0 and mod ~= KEY_INVALID then
          parts[#parts + 1] = GetKeyName(mod)
        end
      end
      parts[#parts + 1] = GetKeyName(key)
      return table.concat(parts, "+")
    end
  end
  return nil
end

-- Checks if keybind is established and alerts/informs the user
function CMD:CheckAndWarnKeybind(setName, setupName)
  local keyString = self:GetQuickSetKeybindString()
  if keyString and keyString ~= "" then
    local setupInfo = (setupName and setupName ~= "") and (" -> [" .. setupName .. "]") or ""
    d(string.format(XLGB_GetString("QUICK_SET_BOUND_INFO"), setName, setupInfo, keyString))
  else
    PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
    d(string.format(XLGB_GetString("QUICK_SET_UNBOUND_WARNING"), setName))
  end
end

-- Sets the target set name for quick swapping (e.g. from Wardrobe UI or Settings)
-- If setupIndex and setupName are supplied, resolves conflict immediately at establishment.
-- Otherwise, checks current page and prompts user immediately if multiple setups exist.
function CMD:SetTargetSetName(setName, setupIndex, setupName, charId, zoneTag, pageId)
  if not setName or setName == "" then return end
  local sV = XLGearBanker.savedVariables
  if not sV then return end

  sV.quickSetTargetName = setName

  local WW = WizardsWardrobe
  if not charId then
    charId = self:GetCurrentCharId()
  end
  if not zoneTag then
    zoneTag = (WW and WW.selection and WW.selection.zone and WW.selection.zone.tag) or "GEN"
  end
  if not pageId then
    pageId = (WW and WW.selection and WW.selection.pageId) or 1
  end

  -- Réinitialise la pile d'undo car le set cible a changé
  self:ClearUndoStack(charId)

  -- Choix de setup explicitement fourni (ex: depuis le clic-droit sur la garde-robe)
  if setupIndex and setupName then
    self:SaveSetupChoice(charId, zoneTag, pageId, setName, setupIndex, setupName)
    PlaySound(SOUNDS.BOOK_PAGE_TURN)
    self:CheckAndWarnKeybind(setName, setupName)
    return
  end

  -- Recherche immédiate de conflits sur la page courante lors de l'établissement
  local matches = self:FindSetupsWithSet(zoneTag, pageId, setName)
  if #matches == 1 then
    self:SaveSetupChoice(charId, zoneTag, pageId, setName, matches[1].index, matches[1].name)
    PlaySound(SOUNDS.BOOK_PAGE_TURN)
    self:CheckAndWarnKeybind(setName, matches[1].name)
  elseif #matches > 1 then
    -- Résolution immédiate du conflit à l'établissement !
    self:PromptConflictResolution(setName, matches, charId, zoneTag, pageId)
  else
    self:CheckAndWarnKeybind(setName, nil)
  end
end

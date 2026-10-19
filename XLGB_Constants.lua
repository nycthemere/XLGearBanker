-- =========================================================
-- XLGearBanker - Constants
-- =========================================================

XLGearBanker = XLGearBanker or {}
XLGB_Constants = XLGB_Constants or {}

-- ── Logger (disponible immédiatement pour tous les modules) ──
if LibDebugLogger then
    XLGearBanker.logger = LibDebugLogger("XLGearBanker")
else
    local noop = function() end
    local stub = {
        Info    = noop,
        Debug   = noop,
        Warn    = noop,
        Error   = noop,
        Verbose = noop,
        Create  = function(self, _tag) return self end,
    }
    XLGearBanker.logger = stub
end

-- ── Constants ─────────────────────────────────────────────
local C = {
    ADDON_NAME    = "XLGearBanker",
    ADDON_TITLE   = "XL Gear Banker",
    ADDON_VERSION = "2026.10.19",
    AUTHOR        = "|c783f04nyc|r|c8fce00thé|r|c6a329fmère|r (original: @XL_Olsen)",

    COLORS = {
        GOLD  = "|cffecbc",
        WHITE = "|cffffff",
        RED   = "|cff0000",
        GREEN = "|c00ff00",
    },
}

-- Rendre les métadonnées et constantes accessibles immédiatement
XLGearBanker.name      = C.ADDON_NAME
XLGearBanker.version   = C.ADDON_VERSION
XLGearBanker.author    = C.AUTHOR
XLGearBanker.Constants = C

for k, v in pairs(C) do
    XLGB_Constants[k] = v
end

function XLGB_Constants:Initialize()
    --Bags
    self.NO_BAG = -1
    self.storageBagIDs = {
        bag_eight = BAG_HOUSE_BANK_EIGHT,
        bag_five = BAG_HOUSE_BANK_FIVE,
        bag_four = BAG_HOUSE_BANK_FOUR,
        bag_nine = BAG_HOUSE_BANK_NINE,
        bag_one = BAG_HOUSE_BANK_ONE,
        bag_seven = BAG_HOUSE_BANK_SEVEN,
        bag_size = BAG_HOUSE_BANK_SIX,
        bag_ten = BAG_HOUSE_BANK_TEN,
        bag_three = BAG_HOUSE_BANK_THREE,
        bag_two = BAG_HOUSE_BANK_TWO
      }

    --Items
    self.ITEM_NOT_IN_BAG = -1
    self.ITEM_NOT_IN_SET = -1

    --GearSets
    self.GEARSET_NOT_ASSIGNED_TO_STORAGE = -1

    --Strings
    self.ADD_ITEM_TO_GEARSET = "XLGB addItem"
    self.ADD_BANK_SET_TO_GEARSET = "XLGB add bank set"
    self.REMOVE_ITEM_FROM_GEARSET = "XLGB removeItem"

    --UI Stuff
    self.ITEM_ROW = 69
    self.PAGE_ITEM_ROW = 420

    self.MISSING_SET_ROW = 111
    self.MISSING_ITEM_ROW = 222

    self.WARDROBE_HEADER_ROW = 333
    self.WARDROBE_ITEM_ROW = 444
    self.WARDROBE_SURPLUS_ROW = 555
end
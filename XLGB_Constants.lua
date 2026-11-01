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
    ADDON_VERSION = "2026.10.31-101047",
    AUTHOR        = "|c783f04nyc|r|c8fce00thé|r|c6a329fmère|r (original: @XL_Olsen)",

    COLORS = {
        RESET               = "|r",

        -- Primary text colors
        GOLD                = "|cffecbc",  -- Signature gold/beige for headers and set names
        GOLD_LIGHT          = "|cffd700",  -- Bright gold for presets and chat bullets
        WHITE               = "|cffffff",  -- Standard neutral white text
        YELLOW              = "|cffff00",  -- Warnings and conflict headers
        AMBER               = "|cffcc00",  -- Slot 1 badge
        ORANGE              = "|cff9900",  -- Tag / Chat prefix
        ORANGE_SURPLUS      = "|cffaa00",  -- Surplus count indicator
        RED                 = "|cff5555",  -- Error / Missing items / Unbind [X]
        RED_ALERT           = "|cff0000",  -- Critical alerts / Safe mode OFF
        GREEN               = "|c00ff00",  -- Success / Active items / Worn gear
        GREEN_BAG           = "|c55ff55",  -- Bag inventory gear
        GREEN_FINE          = "|c2dc50e",  -- Fine-to-Gold quality preset
        BLUE_BANK           = "|c5599ff",  -- Bank equipment
        BLUE_SOFT           = "|c88bbff",  -- Secondary location details
        PURPLE_EPIC         = "|ca02ef7",  -- Epic & Legendary quality preset
        CYAN                = "|c00e5ff",  -- Quick Set #2 / Slot 2
        AQUA                = "|c66ccff",  -- WW Boss / Setups accent
        MUTED               = "|c888888",  -- Muted hints and piece counters
        GREY                = "|c888888",  -- Muted hints and setup counters
        GREY_DARK           = "|c666666",  -- Inactive status text
        COUNT_CUSTOM        = "|ce6cc80",  -- Custom active count badge
        TITLE_ACCENT        = "|cffffaa",  -- Context menu title accent

        -- Semantic aliases
        TITLE               = "|cffecbc",
        SET_NAME            = "|cffecbc",
        SLOT_1              = "|cffff00",
        SLOT_1_TAG          = "|cffcc00",
        SLOT_2              = "|c00e5ff",
        ACTIVE              = "|c00ff00",
        WORN                = "|c00ff00",
        BAG                 = "|c55ff55",
        BANK                = "|c5599ff",
        MISSING             = "|cff5555",
        CHAT_TAG            = "|cff9900[XLGB]|r",
        CHAT_ERROR          = "|cff5555[XLGB]|r",
        CHAT_SUCCESS        = "|c00ff00[XLGB]|r",
        CHAT_WARNING        = "|cffff00[XLGB]|r",

        -- Quality preset text tags
        QUALITY_GOLD        = "|cffd700",
        QUALITY_EPIC        = "|ca02ef7",
        QUALITY_FINE        = "|c2dc50e",
        QUALITY_BLOCKED     = "|cff5555",
        QUALITY_ALLOW_ALL   = "|c00ff00",
        QUALITY_NO_GOLD     = "|cffffff",
        QUALITY_CUSTOMIZE   = "|cffecbc",
        QUALITY_ACTIVE_COUNT= "|ce6cc80",
        QUALITY_MENU_TITLE  = "|cffffaa",
        QUALITY_INACTIVE    = "|c666666",

        -- RGBA vectors for controls and texture colorization
        RGBA = {
            STAR_SLOT_1     = { 1.0, 0.85, 0.2, 1.0 },
            STAR_SLOT_2     = { 0.2, 0.85, 1.0, 1.0 },
            STAR_HOVER      = { 1.0, 0.9, 0.4, 0.9 },
            STAR_MUTED      = { 0.5, 0.5, 0.5, 0.5 },
            TAB_ACTIVE      = { 0.2, 1.0, 0.2, 1.0 },
            TAB_SURPLUS     = { 1.0, 0.8, 0.2, 1.0 },
            TAB_MUTED       = { 0.7, 0.7, 0.7, 1.0 },
        },

        -- Raw HEX strings (without |c or |r)
        HEX = {
            AQUA            = "66ccff",
            CYAN            = "00e5ff",
            GOLD            = "ffecbc",
            MUTED           = "888888",
            GREY            = "888888",
        },
    },
}

function C.Colorize(color, text)
    return (color or "") .. tostring(text or "") .. "|r"
end
C.COLORS.Colorize = C.Colorize

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
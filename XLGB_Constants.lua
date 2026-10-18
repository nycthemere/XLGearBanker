XLGB_Constants = {}

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
# XLGearBanker

XL Gear Banker (XLGB) is an ESO addon that strives to combat the tedious task of moving all your gear to another character. Automatic gear banking and withdrawal, quality filters and Wizard's Wardrobe synchronization.

<!-- commits:start -->
## History

### 2026.10.30-101046 — Streamline banking performance, context menu options, and missing item reporting

- Replace blocking missing-items modal window with discrete chat reports and Inventory Insight (IIfA) cross-character location lookups;
- Normalize IIfA item link keys and implement itemId fallback to resolve locations in both chat and popup tooltips;
- Implement temporary Junk tab switching during deposits and withdrawals to optimize bulk transfer performance;
- Add total moved item counts alongside elapsed time in banking and wardrobe transaction result messages;
- Make right-click item context menu entries optional via settings and eliminate invalid slot type references;
- Dynamically register slot updates only while set UI is open and unregister EVENT_ADD_ON_LOADED upon initialization;
- Add complete English, French, and German localizations for all new settings, context actions, and report strings.

### 2026-10-24 — Enhance UI layout and controls, Wizard's Wardrobe integration, and localization.
### 2026-10-20 — Implement a Wizard's Wardrobe Quick Set toggle keybind with combat buffering, target conflict resolution, and persistent undo across reloads and disconnects.
### 2026-10-19 — Fix gear set auto-rename index desync and centralize addon version in constants.
### 2026-10-18 — First commit to github.
### 2026-10-18 — Initial commit.

<!-- commits:end -->
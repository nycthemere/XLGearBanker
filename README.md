# XLGearBanker

XL Gear Banker (XLGB) is an ESO addon that strives to combat the tedious task of moving all your gear to another character. Automatic gear banking and withdrawal, quality filters and Wizard's Wardrobe synchronization.

<!-- commits:start -->
## History

### 2026.10.31-101047 — Add dual quick set support, categorize sets and pages with tabs, and optimize inventory caching.

#### Fixed

- Fix bag iteration boundary overflow and empty slot lookups in findItemIndexInBag and findItemsToMove by iterating from 0 to bagSize - 1 and verifying valid item links prior to UID resolution;
- Prevent set row text and item counts from clipping into action buttons in XLGearBanker.xml by anchoring labels to relative control bounds with single-line ellipsis wrapping;
- Prevent Wizard's Wardrobe setup cross-contamination across characters and zones by scoping setup scans strictly to matching character IDs and zone tags.

#### Added

- Add secondary Quick Set keybinding (XLGB_QUICK_SET_2_TOGGLE) with an independent undo stack, target set configuration, and cyan UI indicators;
- Add tabbed navigation (XLGB Pages / Wizard's Wardrobe and XLGB Sets / Wizard's Wardrobe) to both Page and Set windows with live item counters and persistent active tab states;
- Add a unified /xlgb [set|page|ww|settings|debug|help] slash command dispatcher with colored help output while preserving legacy command aliases;
- Add boss and setup name tooltips to Wizard's Wardrobe gear set headers and surplus inventory rows;
- Add interactive star icon context menus to bind or unbind sets directly to Quick Set #1 or Quick Set #2;
- Add localized strings across English, French, and German for all new tab filters, slash command help, boss tooltips, and Quick Set #2 controls;
- Centralize semantic UI text colors, quality preset tags, and RGBA control color vectors in XLGB_Constants.COLORS.

#### Improved

- Cache inventory slot unique IDs and item set metadata with event-driven invalidation on EVENT_INVENTORY_SINGLE_SLOT_UPDATE to eliminate redundant Id64ToString(GetItemUniqueId()) calls;
- Memoize Inventory Insight (IIfA) location queries and database key lookups, clearing caches automatically on bank open and close events;
- Pass pre-calculated gear maps directly into WWB:GetDifferenceItems to bypass redundant bag and bank scans during surplus item checks;
- Cache active keybind display strings with automatic invalidation on EVENT_KEYBINDINGS_LOADED;
- Automatically migrate legacy saved variables by stripping obsolete [WW] name prefixes and assigning native isWW = true boolean flags.

#### Removed

- Remove obsolete .gitignore containing unrelated file rules;
- Remove hardcoded [WW] prefixes from imported Wizard's Wardrobe page and set titles;
- Remove duplicate full inventory scans when evaluating surplus wardrobe equipment.

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
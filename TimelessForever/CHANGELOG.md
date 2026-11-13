# Changelog — TimelessForever Suite

## [v1.4.0] — 2026-11-13 (Utility Button Bar, ScrollsPicker & MacroAssist Update)

### ⚡ Unified Timeless Button Bar (TimelessForever_Bar)
- **Consolidated Action Bar**: Grouped Nightlight, Disenchant, and Fishing into a single sleek, floating action bar.
- **Clean Button Renaming**: Simplified and standardized labels to "Nightlight", "Disenchant", and "Fishing".
- **Customizable Layout**: Shift+Drag anywhere on screen, auto-saving position across sessions, toggle Horizontal/Vertical orientation, and frame locking.
- **Dedicated Settings Tab**: Direct configuration inside the TimelessForever suite hub (`/tfbar` or `/timelessforever bar`).

---

### 📜 Stat Scrolls Bag Scanner (ScrollsPicker & Radial Buff Wheel)
- **New Module**: Added `ScrollsPicker` scanning bags for Classic Stat Scrolls (Agility, Strength, Stamina, Intellect, Spirit, and Protection Ranks I–IV).
- **Interactive UI**: Live bag count badges, missing rank detection, and 1-click scroll application directly from the window without searching bags.
- **Smart Auto-Popup**: Automatically shows when stat scroll buffs expire or are missing; automatically hides once all active buffs are applied.
- **Radial Buff Wheel Integration**: Full configuration controls integrated right into the Buffs tab (`/timelessforever buffs`) with scale slider and missing-rank filters.

---

### 📦 TimelessForever_Move (MacroAssistForever Integration)
- **MacroAssist Support**: Added full movement, scale adjustment, and position persistence for `MacroAssistForeverFrame`.
- **Flexible Drag Targets**: Added recognition for capitalized and lowercase headers and titlebars (`frame.header`, `frame.title`, `frame.Header`, `frame.Title`).
- **Slash Shortcuts**: Added `/timelessmove macro` (toggle visibility) and `/timelessmove macro reset` (center position).
- **Safe Event Hooking**: Protected hooking for `ShowMacroFrame` and `SlashCmdList["MACROASSISTFOREVER"]` preventing nil/function indexing Lua errors.

---

### 💎 Polish & Bug Fixes
- **TimelessForever_Disenchant**: Instant 1-click bag disenchanting without equipping gear, auto-loot on disenchant, and mailbox mode support.
- **TimelessForever_nightlight**: Fixed Lua syntax error at line 1163 (`'=' expected near ')'`) during trainer tier progression.
- **About Tab Redesign**: Completely revamped the About & Updates tab into clean, structured inline cards, live module status directory, and 1-click navigation buttons.

---

## [v1.0.0] — 2026-10-22 (Initial Release)

Welcome to the initial launch of **TimelessForever** for **World of Warcraft: Forever**!  
This release bundles all 9 core and modular quality-of-life additions under one unified suite.

---

### 🌟 Core Suite & In-Game Dashboard
- **Unified Master Settings Hub**: Access all modules from a single, clean in-game options menu (`/tf` or `/timelessforever`).
- **Minimap Launcher**: Left-click to open settings, right-click for quick actions context menu, draggable positioning.
- **In-Game Macro Generator**: Automatically create a custom `/timelessforever` macro in your Macro panel with customizable icons.
- **Zero-Taint Architecture**: Built for pure performance with zero action-bar lockups during combat.

---

### 🔦 TimelessForever_nightlight (Cursor Lantern & Atmospheric Light)
- **Mouse-Tracking Spotlight**: Realistic lantern illumination that smoothly follows your cursor.
- **Optical Darkness Falloff**: Darkens surrounding environment with soft radial falloff for immersive cave and night questing.
- **Organic Torch Flicker**: Procedural lighting simulation mimicking real campfire and torchlight.
- **8 Ambient Presets**: Warm Torchlight, Elune Moonlight, Cozy Candlelight, Campfire Ember, Holy Radiance, Arcane Violet, Fel Torch, and Pure Daylight (+ custom color picker).
- **Interactive Control**: Draggable floating lantern toggle with mousewheel beam resizing.

---

### 🎣 TimelessForever_Fishing (Automated Fishing QoL)
- **Smart Rod Auto-Swap**: Equips your fishing rod when casting begins and automatically swaps back to your battle weapons upon entering combat or moving.
- **Click-Anywhere Reel**: Right-click anywhere on the screen to reel in your catch as soon as the bobber splashes.
- **Double-Click Cast**: Quick double right-click anywhere in the water to cast your line.
- **Lure Reminders & Audio Alerts**: Never fish without your bait or lures active.
- **Floating Quick-Toggle**: 1-click on-screen enable/disable button.

---

### 🗺️ TimelessForever_Minimap (Modern Square Minimap)
- **Clean Square Design**: Sleek borderless or custom-bordered square minimap.
- **Live Coordinates**: High-precision real-time player and cursor coordinate readouts.
- **Zone Header Banner**: Prominent, clean zone and subzone display.
- **Addon Tray Integration**: Seamlessly docks with the Addon Button Tray.

---

### 🎒 TimelessForever_MinimapBag (Addon Button Collector)
- **Automatic Button Gathering**: Consolidates third-party addon icons into a clean slide-out drawer.
- **Smart Docking**: Supports both circular and square minimap docking paths.
- **Customizable**: Adjust button sizes, drawer spacing, and expansion directions.

---

### 💬 TimelessForever_AITranslate (In-Game Chat Translation)
- **Multi-Channel Translation**: Automatically translates Party, Raid, Guild, Whispers, Say, Yell, and World channels.
- **Modular Offline Dictionaries**: Built-in translation dictionaries for multiple languages.
- **Optional Companion App**: High-speed OCR and neural translation overlay for foreign character sets.

---

### ⚡ TimelessForever_Tweaks (Graphics & CVars Optimizer)
- **Extended Camera Zoom**: Camera zoom multiplier slider up to 2.6x for maximum raid and world awareness.
- **Nameplate Customization**: Extended draw distance and collision stacking controls.
- **Combat Text & Performance**: Streamlined scrolling combat text and 1-click performance presets.

---

### 📦 TimelessForever_Move (Blizzard UI Frame Unlocker)
- **Movable Default Frames**: Drag, move, scale, and save positions for Character Sheet, Spellbook, Quest Log, Merchant, Bags, Gossip, and more.
- **Zero-Taint Architecture**: Safe for combat; will never lock up your action bars.

---

### 💚 TimelessForever_Heal (Mouseover Healing Frames)
- **Low-Latency Updates**: Instant health updates and incoming heal predictions.
- **Aura & Debuff Filtering**: Prioritizes dispellable debuffs and active HoTs.
- **Mouseover Ready**: Native support for `@mouseover` macros and click-casting.

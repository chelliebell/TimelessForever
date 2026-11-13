# TimelessHeal

**A clean, modern click-casting addon built specifically for World of Warcraft: Timeless.**

TimelessHeal enhances Blizzard’s existing party and raid frames without forcing you into a completely different unit-frame setup. Assign your heals, click a frame, and heal.

Simple to configure. Fast to use. Built around the restrictions of the Timeless client.

---

## Features

* **Click Casting**
  Assign spells to Left Click, Right Click, Middle Click, Mouse 4, Mouse 5, and additional mouse buttons.
* **Modifier Bindings**
  Create separate bindings using Shift, Ctrl, and Alt for a much larger healing toolkit.
* **Drag & Drop Setup**
  Drag spells directly from your spellbook into TimelessHeal or type the spell name manually.
* **Smart Resurrection**
  When enabled, your configured resurrection spell can automatically replace your normal heal when clicking a dead player outside combat. Includes optional whisper alerts when casting.
* **Smart Buffs (v1.1.38-beta)**
  Configure class-specific buffs and let TimelessHeal handle missing buffs through your normal clicks while outside combat.
  * Added a new **Heal Below %** priority (if an ally is critically hurt, healing takes priority over buffing).
  * Automatically checks your exact class-assigned buff, tracking your copy separately from others.
  * Friendly pets safely fall through to normal heals.
  * Avoids out-of-range or line-of-sight miscasts.
* **Trinket + Heal Bindings**
  Assign Trinket 1 (Slot 13) or Trinket 2 (Slot 14) to individual healing binds. TimelessHeal attempts the selected on-use trinket before casting the assigned heal.
* **Out-of-Range Detection**
  Optionally dim unavailable players almost completely and display a compact **OoR** warning directly on their frame.
* **Range Alerts & Built-In Sound Browser**
  Choose and preview compatible Blizzard sounds directly inside TimelessHeal with optional on-screen error messages.
* **Dispellable Debuff Outlines**
  Display colored outlines around healing frames when players are affected by supported dispellable debuffs (Magic, Curse, Poison, Disease).
* **Binding Tooltips**
  Hover over a healing frame to quickly see the abilities currently assigned to your mouse buttons.
* **Mouseover Highlighting**
  Optionally darken/highlight frames as you mouse over them, making your intended healing target easier to identify.

---

## Custom Self & Target Bars

TimelessHeal includes optional custom bars for **your character** and **your current target**.

* Self and Target are configured independently and can have their own size, text placement, font sizes, health percentages, and positioning.
* Every adjustment updates immediately. No Apply button required.
* You can also type exact numerical values for precise sizing instead of relying entirely on sliders.

---

## Quick Access Launcher (FH Icon)

TimelessHeal includes a small movable **FH** icon:
* **Left Click:** Open TimelessHeal settings
* **Right Click:** Enable or disable healing-frame functionality
* **Shift + Left Drag:** Move the **FH** icon anywhere on your screen (position saved per character)

---

## Settings Window Lock

* Added a **Lock / Unlock** button beside the settings window close button.
* Locking the window prevents TimelessHeal settings from being accidentally dragged while configuring the addon.
* All settings controls remain fully usable while the window is locked.

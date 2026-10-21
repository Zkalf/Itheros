# Spec 0008 amendment 3: hands in the middle, tap a slot to fill it

Status: accepted
Amends: [spec 0008](0008-character-and-world-layout.md) §3.5 (Gear) and adds a criterion
Product owner: Zkalf (asked for it after playtesting the doll, 2026-10-21)
Date: 2026-10-21

## Change
1. **The hands stand out.** The bottom row holds only **Main hand** and **Off hand**, centred under the figure
   (under a two-hander the Off hand stays greyed with a link icon, as today). The trinkets move to the columns: left column Head, Neck, Shoulder, Cloak, Chest, Bracer,
   **Trinket 1**; right column Gloves, Belt, Legs, Boots, Ring 1, Ring 2, **Trinket 2**.
2. **Every slot can be tapped, empty or not.** It opens a **slot sheet**:
   - its name and kind ("Head", "Ring 1 · rings fit here");
   - what's worn there, if anything, with its stats and **Unequip**;
   - **From your bag**: every bag item that fits this slot, best first, each with its stat change against what's
     worn there and **Equip** (empty slot) or **Swap**. Tapping an item's name opens its item card;
   - with nothing in the bag that fits: "Nothing in your bag fits here yet."
3. Equipping from the slot sheet puts the item in **that** slot (so a ring tapped from Ring 2 goes to Ring 2), with
   the two-hand rules of §2.1.

## Acceptance criteria
15. The bottom row of the doll holds only Main hand and Off hand; the trinkets sit at the foot of the two columns.
16. Tapping an empty or filled slot opens its sheet: the worn item (if any) with Unequip, and every bag item that fits
    that slot with its stat change and Equip or Swap, which equips into that slot; "Nothing in your bag fits here
    yet." when none does.

# Plan 0006: Build "Item qualities"

Status: accepted
Spec: `specs/0005-item-qualities.md` · Intent: `intent/0005-item-qualities.md` (accepted, f86dd0a)
Product owner: Zkalf · Date: 2026-10-19

## What changes in the code
- **Item keys:** a piece of gear of quality Q is stored as `<item>@<quality>` in the inventory and equipment maps
  (`bone_sword@rare`); common keeps the plain id, so existing saves need no migration and the save format is
  unchanged. Helpers split a key into item and quality; every lookup of item data goes through them.
- **`data.dart` / `economy.json`:** `qualities` (id, colour, bonus, chance), `qualityPerLevel`, `qualityMaxLevels`.
  `enemies.json`: `firstKillDrops` entries gain `repeatChance`. Validation: chances sum to 1, order is fixed.
- **`game.dart`:** a quality roll on crafted and dropped gear; stats with quality (`stats`, gear score); stacks,
  equip and unequip by key; `owned` counts all qualities; boss repeat drops; "Next goal" by stats with quality.
- **`simulation.dart`:** the sensible player ranks gear by stats with quality.
- **App:** `Labels.item` adds the quality: "Bone sword (Rare)"; the Character tab colours names; report lines use the full key.

## Order of work
### M1: Rules, tests first
Failing tests committed first for criteria 1–8, then implement. **Proof:** `.\scripts\check.ps1` green, including
the pacing tests (criterion 10). The simulator report of qualities seen by day 14 / 50 / 90 is pasted into the
commit message.

### M2: Screens
Quality in brackets after every gear name, colour on the Character tab, separate rows per quality (criterion 9). Widget tests
with `MemorySaveStore`. **Proof:** check green.

### M3: On the phone
`.\scripts\check.ps1 -Release`, `.\scripts\device-smoke.ps1 -Install`, the save carries over with its gear common.
The verifier checks against spec 0005. The owner playtests (test walk helps here).

## Risks
| Risk | Mitigation |
|---|---|
| Item ids are used in many places; a missed lookup crashes on a `@` key | One helper for item data by key; a test equips, reports and saves every quality of every gear item |
| Lucky gear speeds up levelling | Pacing tests with qualities on; the owner accepted easier bosses with lucky gear |
| The inventory fills with spare copies | Accepted for now; salvaging is the likely next intent |

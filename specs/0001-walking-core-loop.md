# Spec 0001: Walking-powered combat RPG — core loop

Status: accepted
Intent: [intent/0001-walking-core-loop.md](../intent/0001-walking-core-loop.md) (accepted, commit 28fac3e)
Product owner: Zkalf
Date: 2026-10-18

The first build is an Android-only vertical slice ("the Goblin slice"): real steps drive travel, combat, mining
and crafting for levels 1–5, with the step bank and offline catch-up working exactly as the intent describes.
All numbers below are starting values. They live in data files and are tuned during Build and Test.

## 1. Decisions on the intent's open questions

The product owner approves, changes or rejects each row.

| # | Question | Proposal | Why |
|---|---|---|---|
| 1 | Stopping an activity | **Deferred, as requested.** The slice lets the player *switch* to another activity while the app is open, which ends the current one. There is no "stop and go idle" button yet. | Without switching, the slice can't be played. Explicit stopping stays open for a later intent. |
| 2 | Bank cap values | `cap = 1,000 + 500 × level` → L1 1,500 · L5 3,500 · L10 6,000. Talents and achievements add flat bonuses. | Roughly a third of an average day's walking at L1, so the bank matters without replacing walking. |
| 3 | What "almost all" excludes | Everything that produces progress (XP, materials, items, travel) costs steps. Equipping gear, managing inventory, picking activities and viewing stats are free. Achievement rewards are the only progress not paid for with steps. | Keeps the rule simple and true. |
| 4 | Platforms | **Android first** (confirmed by product owner). iOS later, built on a cloud macOS service so no Mac is needed. | Development happens on Windows. iOS builds need macOS and Xcode. |
| 5 | Engine/tech | **Flutter (Dart)**. Game rules live in a pure-Dart package with no Flutter dependency. | An auto-resolved RPG is mostly UI. One codebase covers both platforms. The `health` plugin covers Health Connect and HealthKit (to be confirmed in `plan.md`). Pure-Dart rules give fast unit tests, which is the feedback loop the playbook asks for. Unity and Godot need native plugins for step data. |
| 6 | Step history | Steps count from the moment the player grants step permission on first launch. Nothing from before install counts. Between sessions, every step since the last sync counts. | Long absences limit themselves: the activity uses steps up and any overflow beyond the bank cap is lost. |
| 7 | Cheating | Low priority while the game is single-player. Exclude step records the platform marks as manually entered. Ignore phone-shaking. | No leaderboards means cheating only affects the cheater. Revisit with any social intent. |
| 8 | Daily caps | **None.** Pacing comes from the bank cap and the level curve. | The intent says more walking means faster progress. |
| 9 | Social | Solo only. | Keeps the slice small and needs no server. |
| 10 | Monetisation | None in the slice. A separate intent decides this before any public release. | The intent's rule (money must not replace walking) still applies. |
| 11 | Scope | The **Goblin slice** first: levels 1–5, one region, one enemy type plus one tougher variant, one gathering skill, one crafting skill, two gear slots, the step bank, and 6 achievements. Talents are designed (§7) but not built. | Proves the core loop on a real phone before content is added. |
| 12 | *New:* one level or per-skill levels | **One character level**, with XP from combat, gathering and crafting. | The intent ties the bank cap to "character level". Per-skill levels could come with a later intent. |

## 2. Step economy

### 2.1 Step source and sync
- **Android source:** Health Connect, aggregated `Steps` over a time window, which deduplicates phone and watch data.
  Records whose recording method is *manual entry* are excluded.
- **iOS source (later):** HealthKit cumulative step count, excluding records marked "was user entered". HealthKit
  is used instead of Core Motion because Core Motion keeps only a short history.
- **Sync window:** `[lastSyncEnd, now]`. `lastSyncEnd` is saved in the same write as the new game state, so the
  same steps are never applied twice. If `now` is earlier than `lastSyncEnd` (clock changed), the sync does nothing.
- **When sync runs:** on app open, then every few seconds while the app is in the foreground.
- **No background work in the slice.** "The character keeps working while the app is closed" is achieved by
  catch-up: on open, the closed-app steps are simulated in order. This avoids needing the background-read permission.

### 2.2 Allocation rule
Steps are applied one at a time, in order. The implementation may batch them as long as the result is identical.

```
for each walked step:
    if an activity is running:
        boost = 1 if bank > 0 else 0
        bank -= boost
        activity.progress += 1 + boost
        complete every action unit whose step cost is now covered
        if the activity cannot start its next unit:
            the activity ends; later steps in this sync take the else branch
    else:
        bank = min(bank + 1, cap)        # steps beyond the cap are lost
```

- A unit is one fight, one ore, one crafted item, or one leg of travel.
- Before a unit starts, the game checks it can run (materials present, destination not yet reached).
  If not, the activity ends. A unit is never left half-paid.
- Leftover progress smaller than one unit's cost is kept while the activity continues. It is discarded when the activity ends.
- The cap is read at the moment each step is banked, so a level-up during catch-up raises it immediately.

### 2.3 Worked examples (these become tests)
| Start | Steps walked | Result |
|---|---|---|
| Fighting, bank 0 | 100 | 100 activity steps, bank 0 |
| Fighting, bank 50 | 100 | 150 activity steps (100 walked + 50 boost), bank 0 |
| Idle, bank 1,400, cap 1,500 | 300 | Bank 1,500, 200 steps lost |
| Crafting, enough ore for 1 more sword (150 steps), bank 0 | 400 | Sword crafted after 150 steps, activity ends, bank +250 |
| Same sync window applied twice | — | Second application changes nothing |

## 3. Activities

| Activity | Unit | Step cost per unit | Reward |
|---|---|---|---|
| Travel | One leg between locations | Per route (§6) | Arrive. No XP. The activity ends on arrival. |
| Combat | One fight | 10 steps per combat round (≈ 50 steps per goblin) | XP plus a chance of drops. Repeats until the player loses or switches. |
| Mining | One ore | 100 steps | 1 copper ore, 20 XP. Repeats until switched. |
| Crafting | One item | Per recipe (§6) | Item plus XP. Repeats until materials run out. |

Activities run only at the location they belong to: combat and mining in their regions, crafting at Camp.

## 4. Character, gear and combat

- **Base stats at L1:** HP 30, Attack 5, Defense 2. **Per level:** +5 HP, +1 Attack, +1 Defense.
- **Gear slots (slice):** weapon and body. Gear adds flat stats.
- **Combat:** fully auto-resolved in rounds, with the player striking first. Damage per hit = `max(1, attack − defense ÷ 2)`,
  varied by ±20% using a seeded random number generator, so the same state and seed always give the same outcome.
- **HP:** restored to full at the start of each fight (simplification for the slice).
- **Defeat:** the character retreats. Nothing is lost, the combat activity ends, and later steps go to the bank.
  A message explains the loss and points to better gear. This is part of the natural tutorial.

## 5. Progression and onboarding

**Assumption:** an average player walks about 5,000 steps a day.

| Level | Cumulative activity steps (target) | What unlocks |
|---|---|---|
| 1 | 0 | Travel, combat (goblin), step bank |
| 2 | ~100 | Mining |
| 3 | ~500 | Crafting |
| 4 | ~1,500 | Goblin brute (tougher fight) |
| 5 | ~3,500 | End of the slice: reached on day 1 by an average walker |
| 10 | ~45,000 | Talents (§7): about day 9 for an average walker |

XP thresholds are derived from these targets at roughly 5 steps per XP. Systems appear only when unlocked. Until
then they are hidden, not greyed out.

**First session:** permission prompt → the character stands at Camp → the game suggests "Walk to Goblin Woods
(200 steps)" → arrival → "Fight goblins". A new player's first goblin falls within the first 250 steps or so.

## 6. Slice content

- **Locations:** Camp (crafting) ↔ Goblin Woods 200 steps ↔ Copper Hills 300 steps. Camp ↔ Copper Hills 400 steps.
- **Goblin (L1):** HP 20, Atk 4, Def 1, 10 XP. Drops: goblin hide 50%, rusty dagger 5%.
- **Goblin brute (L4):** HP 45, Atk 8, Def 3, 30 XP. Drops: 2 goblin hides. It is meant to be risky without crafted gear.
- **Items:** rusty dagger (+1 Atk), copper sword (+3 Atk), hide vest (+2 Def, +10 HP).
- **Recipes:** copper sword = 5 copper ore + 150 steps, 30 XP. Hide vest = 4 goblin hides + 150 steps, 30 XP.
- **Achievements:**

| Achievement | Condition | Reward |
|---|---|---|
| First Steps | Walk 100 steps | Badge |
| Goblin Slayer I | Defeat 10 goblins | Badge |
| Prospector | Mine 10 copper ore | Badge |
| Smith | Craft your first item | Badge |
| Brute Force | Defeat a goblin brute | Badge |
| Marathon | Walk 42,195 steps in total | +500 bank cap |

Marathon proves that achievement rewards can raise the bank cap, as the intent asks.

## 7. Talents (designed only, built after the slice)
Talents unlock at level 10. A talent point is gained per level from 10 onward. Talents give passive bonuses only,
such as bank cap, step cost reductions, or combat stats. A future spec details the tree.

## 8. Out of scope for the slice
iOS · background sync and notifications · an explicit "stop activity" · talents · daily rewards · spending
banked steps directly · social, cloud save, accounts · monetisation · sound and music beyond placeholders.

## 9. Concerns flagged for the product owner

1. **Device coverage (high).** Health Connect counts phone steps itself only on Android 14+ with a recent system
   update. Older phones get steps only from a manufacturer app such as Samsung Health, and some phones have none.
   Counting also starts only once an app is granted step permission, so there is no backfill.
   **Test device: Fairphone 5, Android 15.** It meets the Android 14+ requirement. The system-update requirement
   (SDK extension 20+, delivered through Google Play system updates) is not yet confirmed. The product owner reports
   that other walking games work on this phone, so the phone's step sensor works, though those games may not read
   steps through Health Connect. The first Build milestone
   is therefore a step probe on this phone: request step permission, then read steps back. A fallback (Google's
   Recording API or the raw step-counter sensor) is planned only if the probe fails.
2. **Store compliance (medium).** Google Play requires a health-data declaration and a privacy policy for Health
   Connect access. Both are needed before any store release, even closed testing.
3. **Data origin change (low, unverified).** One source reports that Health Connect changed how it labels on-device
   step data in June 2026. If this is confirmed, queries must not filter on the old label. Check this in `plan.md`.
4. **iOS later needs a Mac or a cloud macOS build service**, plus the HealthKit entitlement.
5. **Design risk: zero-step days give zero progress.** This is intentional under option B. The deferred daily or
   achievement rewards (intent "later additions") are the mitigation. Watch this in playtests.
6. **Design risk: travel overhead.** Walking 400 steps to Camp just to craft may feel like a tax. Tune route
   costs in playtests.
7. **No organisational skills exist yet** for security, privacy or UX, so this spec was not checked against any.
   Recommendation for Build: add a hook that fails the build if the release Android manifest requests the INTERNET
   permission. That enforces "health data stays on device" mechanically, not just as a rule.

## 10. Acceptance criteria (input to the Test stage)
1. Every worked example in §2.3 passes as an automated test of the pure-Dart rules package.
2. Combat with the same character, enemy and seed always produces the same result.
3. Re-applying an already processed sync window changes nothing, including after the app is killed mid-write.
4. On a real Android phone: steps walked with the app closed are applied, in order, on next open.
5. A simulated new player reaches level 2 within 350 walked steps, starting at Camp (200 travel + about 100 combat, plus margin).
6. Simulated runs at 5,000 steps/day reach level 5 on day 1 and level 10 within 7–11 days (with talents locked).
7. The release build declares no INTERNET permission.
8. Mining, crafting and the goblin brute stay hidden until their unlock level.

## Sources
- [The AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
- [Health Connect: read raw data (30-day history window)](https://developer.android.com/health-and-fitness/health-connect/read-data)
- [Health Connect: feature availability](https://developer.android.com/health-and-fitness/health-connect/features/availability)
- [Health Connect: track steps (Android 14 + SDK extension 20 for on-device counting)](https://developer.android.com/health-and-fitness/health-connect/features/steps)
- [Google help: track your steps with Health Connect](https://support.google.com/android/answer/16786157)
- [Health Connect without a wearable (native phone step counting, June 2026 data-origin change)](https://sahha.ai/blog/health-connect-without-a-wearable/)
- [Apple CMPedometer](https://developer.apple.com/documentation/coremotion/cmpedometer)

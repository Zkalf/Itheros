# Spec 0001: Walking-powered combat RPG — core loop

Status: accepted
Intent: [intent/0001-walking-core-loop.md](../intent/0001-walking-core-loop.md) (accepted, commit 28fac3e)
Product owner: Zkalf
Date: 2026-10-18

The first build is an Android-only vertical slice ("the Goblin slice"): real steps drive travel, combat, mining
and crafting for levels 1–5, with the step bank and offline catch-up working exactly as the intent describes.
All numbers below are starting values. They live in data files and are tuned during Build and Test.

Spec 0001 bounded the first build. Later specs built on it and changed parts of it; each part says where.

## 1. Decisions on the intent's open questions

The product owner approves, changes or rejects each row.

| # | Question | Proposal | Why |
|---|---|---|---|
| 1 | Stopping an activity | **A Stop button** (owner, 2026-10-19). The player can *switch* to another activity, which ends the current one, or **stop** it and rest. Stopping and switching never lose steps (§2.2). Since spec 0003 the player runs a queue of actions, and Stop starts the next one. | Switching lost the steps paid toward an unfinished unit (found on the Fairphone). |
| 2 | Bank cap values | `cap = 9,500 + 500 × level` → L1 10,000 · L5 12,000 · L10 14,500 (spec 0003 §6; spec 0001 started at `1,000 + 500 × level`, L1 1,500). Talents and achievements add flat bonuses. | Roughly a third of an average day's walking at L1, so the bank matters without replacing walking. Spec 0003 made it bigger. |
| 3 | What "almost all" excludes | Everything that produces progress (XP, materials, items, travel) costs steps. Equipping gear, managing inventory, picking activities and viewing stats are free. Achievement rewards are the only progress not paid for with steps. | Keeps the rule simple and true. |
| 4 | Platforms | **Android first** (confirmed by product owner). iOS later, built on a cloud macOS service so no Mac is needed. | Development happens on Windows. iOS builds need macOS and Xcode. |
| 5 | Engine/tech | **Flutter (Dart)**. Game rules live in a pure-Dart package with no Flutter dependency. | An auto-resolved RPG is mostly UI. One codebase covers both platforms. The `health` plugin covers Health Connect and HealthKit (to be confirmed in `plan.md`). Pure-Dart rules give fast unit tests, which is the feedback loop the playbook asks for. Unity and Godot need native plugins for step data. |
| 6 | Step history | The whole day on which a new game starts counts, including the steps walked before the start (owner, 2026-11-06: "Give them the steps"). Days before it do not count. Between sessions, every step since the last sync counts. | Long absences limit themselves: the activity uses steps up and any overflow beyond the bank cap is lost. "Walked today" on Now shows the day's whole total, so day one counts in full, or the screen would say that the player walked more than the game gave them (#225). |
| 7 | Cheating | Low priority while the game is single-player. Steps are read only from the de-duplicated aggregate, which includes manually entered records. Ignore phone-shaking. | No leaderboards means cheating only affects the cheater. The plugin's manual-entry filter sums raw records without de-duplication and double-counts (49,883 against 26,371 on the test phone). Revisit with any social or leaderboard intent. |
| 8 | Daily caps | **None.** Pacing comes from the bank cap and the level curve. | The intent says more walking means faster progress. |
| 9 | Social | Solo only. | Keeps the slice small and needs no server. |
| 10 | Monetisation | None in the slice. A separate intent decides this before any public release. | The intent's rule (money must not replace walking) still applies. |
| 11 | Scope | The **Goblin slice** first: levels 1–5, one region, one enemy type plus one tougher variant, one gathering skill, one crafting skill, two gear slots, the step bank, and 6 achievements. Talents are designed (§7) but not built. | Proves the core loop on a real phone before content is added. The list bounded the first build, not later content. |
| 12 | *New:* one level or per-skill levels | **One character level**, with XP from combat, gathering and crafting. Since spec 0010 each profession also has a level of its own; the character level stays. | The intent ties the bank cap to "character level". |

## 2. Step economy

### 2.1 Step source and sync
- **Android source:** Health Connect, aggregated `Steps` for each day, which de-duplicates phone and watch data. The
  aggregate includes manually entered records (decision 7).
- **iOS source (later):** HealthKit cumulative step count, excluding records marked "was user entered". HealthKit
  is used instead of Core Motion because Core Motion keeps only a short history.
- **Steps per day:** the save keeps the **credited steps per calendar day** (local time) for the last 7 days.
  - On each sync, for each of those days: `total = aggregate(dayStart, min(dayEnd, now))`, then
    `delta = total − credited[day]`. If `delta > 0`, apply `delta` walked steps (§2.2) and set
    `credited[day] = total`. If `delta ≤ 0`, do nothing. Steps already credited are never taken back.
  - Days are processed oldest first. Days older than 7 days are dropped from the save and never revisited.
  - **The first day:** a new game starts with nothing credited for the day of its start, so the first sync gives it
    the steps walked earlier that day (decision 6). The days before the first day are not in the window.
  - The bank cap and the other rules of a sync stay as they are: a player who walked more than the cap before the
    start keeps what the cap allows.
  - The day map is saved in the same atomic write as the game state, so a sync applied twice changes nothing.
  - A clock change can't double-count, because credit is tracked per day total rather than per time window.
  - Why per day: the Fairphone 5 showed two Health Connect sources for the same walking, the phone (24,203 steps) and
    Garmin Connect (25,680); the aggregate de-duplicated them to 26,371. Garmin uploads in batches and backdates its
    records, so a time-window sync (`[lastSyncEnd, now]`) would never see watch-only steps that arrive after their
    window was processed.
- **Walked today** on Now shows the steps that the game got today, on day one too.
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
            the activity ends (its unspent progress goes to the bank);
            later steps in this sync take the else branch
    else:
        bank = min(bank + 1, cap)        # steps beyond the cap are lost
```

- A unit is one fight, one ore, one crafted item, or one leg of travel.
- Before a unit starts, the game checks it can run (materials present, destination not yet reached).
  If not, the activity ends. A unit is never left half-paid.
- Leftover progress smaller than one unit's cost is kept while the activity continues.
- **Whenever an activity ends, is stopped or is replaced by another**, its unspent progress (steps paid toward the
  unfinished unit, including bank boost steps) goes to the step bank.
  - The bank cap still applies: a refund fills the bank up to the cap, like any banked step.
  - In practice this matters when stopping or switching. When an activity ends by itself (arrival, defeat, out of
    materials) the leftover is at most 1 boost step.
  - A fight in progress is abandoned: the next fight starts at full HP for both sides.
  - Materials are untouched; they are only consumed when a craft completes.
  - It can't be exploited. The refund is the walked steps plus the boost steps they used. The boost steps came from
    the bank, so the result is the same as having walked those steps while resting. Example: bank 100, travel, walk
    9 steps (progress 18, bank 91), stop or switch: bank 109. Walking 9 steps while resting also gives 109.
- **Stop:** the current-activity card has a Stop button while an activity runs. Stopping ends the activity, refunds
  its unspent steps to the bank, and the character rests: further steps go to the bank until a new activity starts.
  Stopping and switching are free (no step cost) and, like every action, sync steps first.
- The cap is read at the moment each step is banked, so a level-up during catch-up raises it immediately.
- Since spec 0003 the activity is the first action of a queue. When it ends, the next action starts; with an empty
  queue the character rests.

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
| Combat | One fight | 10 steps per combat round (≈ 50 steps per goblin at first; fights are longer since spec 0002 amendment 3) | XP plus a chance of drops. Repeats until the player loses or switches. Since spec 0003 a loss gives part of the XP, and the action ends after 3 losses in a row or at its stop condition. |
| Mining | One ore | 100 steps | 1 copper ore, 20 XP. Repeats until switched. |
| Crafting | One item | Per recipe (§6) | Item plus XP. Repeats until materials run out. |

Activities run only at the location they belong to: combat and mining in their regions, crafting at Camp (and at
the outposts of spec 0002 §6). Since spec 0003 the queue travels to an action by itself.

## 4. Character, gear and combat

- **Base stats at L1:** HP 30, Attack 5, Defense 2. **Per level:** +10 HP, +1 Attack, +1 Defense (spec 0002 §4; spec
  0001 started at +5 HP).
- **Gear slots (slice):** weapon and body. Gear adds flat stats. Spec 0002 §4 and spec 0008 added the other slots.
- **Combat:** fully auto-resolved in rounds, with the player striking first. Damage per hit = `max(1, attack − defense ÷ 2)`,
  varied by ±20% using a seeded random number generator, so the same state and seed always give the same outcome.
  Since spec 0009 §2 a swing can miss, crit or be blocked, and damage types count.
- **HP:** restored to full at the start of each fight (simplification for the slice).
- **Defeat:** the character retreats. Nothing is lost, the combat activity ends, and later steps go to the bank.
  A message explains the loss and points to better gear. This is part of the natural tutorial. Spec 0003 §5 changed
  the loss rules.

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

Later specs changed this table. Spec 0002 §2 set the levels up to 30 (level 10 on day 12-16), and spec 0009
criterion 16 holds the pace now. Since spec 0008 decision 1 nothing opens by level but talents.

**First session:** permission prompt → the character stands at Camp → the game suggests "Walk to Goblin Woods
(200 steps)" → arrival → "Fight goblins". A new player's first goblin falls within the first 250 steps or so.

## 6. Slice content

- **Locations:** Camp (crafting) ↔ Goblin Woods 200 steps ↔ Copper Hills 300 steps. Camp ↔ Copper Hills 400 steps.
- **Goblin (L1):** HP 29 (20), Atk 4, Def 1, 20 XP (10). Drops: goblin hide 90% (50%), rusty dagger 13.5% (5%).
- **Goblin brute (L4):** HP 80 (45), Atk 8, Def 3, 23 XP (30). Drops: 4 goblin hides (2). It is meant to be risky
  without crafted gear.
- The monsters' numbers are those of `enemies.json`, with the first ones in brackets. Spec 0002 §6 added the other
  areas and monsters.
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

Marathon proves that achievement rewards can raise the bank cap, as the intent asks. Spec 0017 replaced this table:
its §2 lists the achievements and their rewards.

## 7. Talents (designed only, built after the slice)
Talents unlock at level 10. A talent point is gained per level from 10 onward. Talents give passive bonuses only,
such as bank cap, step cost reductions, or combat stats. Spec 0015 details the trees.

## 8. Out of scope for the slice
iOS · background sync and notifications · spending banked steps directly · social, cloud save, accounts ·
monetisation · sound and music beyond placeholders.

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
6. Removed on 2026-10-19: spec 0002 criterion 3 replaced it, and spec 0009 criterion 16 holds the pace now.
7. The release build declares no INTERNET permission.
8. Removed on 2026-10-21: spec 0008 decision 1 shows every system from level 1.

**Steps per day**
9. A late upload of 500 steps into an already-synced earlier hour today is credited on the next sync.
10. A late upload into yesterday is credited, up to 7 days back.
11. An aggregate that drops (de-duplication priority changed) credits nothing and takes nothing back.

**Refunds and Stop**
12. Fighting with 7 steps toward the next round, bank 0, switching to travel: bank 7, travel progress 0.
13. Bank 100, travel, walk 9 steps, switch: bank 109, the same as walking 9 steps while resting.
14. Stopping refunds the same way and leaves the character resting; the next walked steps go to the bank.
15. The refund respects the cap: bank 5 below the cap with 18 unspent steps gives a full bank.
16. Switching away from crafting or stopping it keeps all materials and refunds the paid steps.
17. The Stop button is shown only while an activity is running.

**Day one counts**
18. With 2,000 steps walked before the start of a new game, the first sync gives the game 2,000 steps.
19. Steps of the day before the start do not count.
20. On day one, "Walked today" equals the steps that the game got that day.
21. A save from before day one counted in full keeps its credit: the steps it did not count on its first day stay
    uncounted.

## Sources
- [The AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
- [Health Connect: read raw data (30-day history window)](https://developer.android.com/health-and-fitness/health-connect/read-data)
- [Health Connect: feature availability](https://developer.android.com/health-and-fitness/health-connect/features/availability)
- [Health Connect: track steps (Android 14 + SDK extension 20 for on-device counting)](https://developer.android.com/health-and-fitness/health-connect/features/steps)
- [Google help: track your steps with Health Connect](https://support.google.com/android/answer/16786157)
- [Health Connect without a wearable (native phone step counting, June 2026 data-origin change)](https://sahha.ai/blog/health-connect-without-a-wearable/)
- [Apple CMPedometer](https://developer.apple.com/documentation/coremotion/cmpedometer)

## History
- 2026-10-18: first version (intent 0001, plan 0001). Criteria 1-8.
- 2026-10-18, amendment 1 (plan 0001 M1): steps are credited per local day for the last 7 days; the aggregate
  includes manual entries. Decision 7; §2.1; criteria 9-11. Its fourth criterion (no steps from before the permission
  grant) ended with amendment 3.
- 2026-10-19, amendment 2 (plan 0001 M6): unspent steps go back to the bank; a Stop button. Decision 1; §2.2;
  criteria 12-17.
- 2026-10-19, amendment 2 erratum 1 (plan 0001 M6): the example of the refund is a travel, not a fight. §2.2;
  criterion 13.
- 2026-10-19, spec 0002: levels up to 30, +10 HP per level, more areas and monsters. §4; §5; §6; criterion 6 removed.
- 2026-10-19, spec 0003: the queue, the loss rules, a bank cap of 10,000 at level 1. Decisions 1 and 2; §2.2; §3;
  §4.
- 2026-10-21, spec 0008: nothing opens by level but talents; more gear slots. §4; §5; criterion 8 removed.
- 2026-10-21, spec 0009: a swing can miss, crit or be blocked. §4.
- 2026-10-21, spec 0010: each profession has a level of its own. Decision 12.
- 2026-10-24, spec 0017: the achievements of today. §6.
- 2026-10-31, spec 0015: the talent trees. §7.
- 2026-11-01, spec 0013: the supply chest, a daily reward. §8.
- 2026-11-06, amendment 3 (#225, plan 0050): day one counts in full. Decision 6; §2.1; criteria 18-21.
- 2026-11-09, spec 0002 amendment 3 and its erratum 1 (#234): tougher, longer fights; the Goblin gives 20 XP. §3; §6.
- 2026-11-15 (plan 0068): the amendments and the erratum folded into this file. §6 gives the Goblin's and the
  Goblin brute's numbers of `enemies.json` (HP 29 and 80; XP 20 and 23; hide 90%, dagger 13.5%; 4 hides), with the
  first numbers beside them. Decision 2 gives the bank cap of spec 0003. No rule or criterion changed.

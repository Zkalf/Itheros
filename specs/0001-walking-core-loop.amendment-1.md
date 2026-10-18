# Spec 0001 amendment 1: per-day step reconciliation

Status: accepted
Amends: [specs/0001-walking-core-loop.md](0001-walking-core-loop.md) §2.1 and decision 7
Product owner: Zkalf
Date: 2026-10-18

The M1 step probe on the Fairphone 5 showed two Health Connect sources for the same walking: the phone itself
(24,203 steps today) and Garmin Connect (25,680). Health Connect's aggregate de-duplicates them to 26,371.
Garmin uploads in batches and backdates its records, so a time-window sync (`[lastSyncEnd, now]`) would never
see watch-only steps that arrive after their window was processed.

## Replaces §2.1 "Sync window"
- The save keeps **credited steps per calendar day** (local time) for the last 7 days.
- On each sync, for each of those days: `total = aggregate(dayStart, min(dayEnd, now))`, then
  `delta = total − credited[day]`. If `delta > 0`, apply `delta` walked steps (spec §2.2) and set
  `credited[day] = total`. If `delta ≤ 0`, do nothing. Steps already credited are never taken back.
- Days are processed oldest first. Days older than 7 days are dropped from the save and never revisited.
- **Install day:** `credited[today]` starts at the aggregate when permission is granted, so steps from before
  install don't count (spec decision 6 is unchanged).
- The day map is saved in the same atomic write as the game state, so a sync applied twice changes nothing.
- A clock change can't double-count, because credit is tracked per day total rather than per time window.

## Changes decision 7 "Cheating"
- Steps are read only from the de-duplicated **aggregate**, which includes manually entered records.
  The plugin's manual-entry filter sums raw records without de-duplication and double-counts (49,883 vs 26,371
  on the test phone), so it is not used.
- Manual entries are accepted for the single-player slice. Revisit with any social or leaderboard intent.

## Acceptance criteria added
1. A late upload of 500 steps into an already-synced earlier hour today is credited on the next sync.
2. A late upload into yesterday is credited, up to 7 days back.
3. An aggregate that drops (de-duplication priority changed) credits nothing and takes nothing back.
4. Steps before the permission grant on install day are not credited.

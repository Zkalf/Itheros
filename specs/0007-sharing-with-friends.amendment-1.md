# Spec 0007 amendment 1: what each part of the version number means

Status: accepted
Amends: [spec 0007](0007-sharing-with-friends.md) decision 9 (version numbers)
Product owner: Zkalf (decided the three parts and that no release follows a schedule, 2026-10-26)
Date: 2026-10-26

## Why
- Decision 9 says each release raises the middle number, and a quick fix raises the last.
- It does not say what counts as a quick fix, and it gives no rule for the first number.
- So the number tells a friend only "newer or older", not what kind of update it is.

## Change
A version is **x.y.z**. Each release raises one part. The parts after it go back to 0 (0.5.1 → 0.6.0, 0.9.2 → 1.0.0).

| Part | Goes up when | Example |
|---|---|---|
| **z** (fixes) | The release has **only fixes**: bugs, nits, wording and looks. It has no new rule, system or content. | 0.5.0 → 0.5.1 |
| **y** (new things) | The release has **something new to play**: a new rule or system, new content (areas, items, monsters, recipes), or a change to the pace. Fixes can come with it. | 0.5.1 → 0.6.0 |
| **x** (a big milestone) | The owner decides that the game is ready for a full release to friends, not only to the closest friends who are invested or help. That release is **1.0.0**. Until then x is **0**: an early test version. A big system alone, such as talents, does not make 1.0. | 0.9.0 → 1.0.0 |

**When to release**
1. No release follows a schedule. The owner decides each release, with Claude's advice.
2. Claude may suggest a release, with the number that this rule gives and the reason.

**What stays**
3. The first friend release was 0.2.0. Each release adds its sample save (spec 0007 §8).
4. The hidden build number goes up by one every release.
5. `.\scripts\release.ps1` raises y. `.\scripts\release.ps1 -Fix` raises z. A way to raise x comes as a small script
   change when the owner calls 1.0.

## Acceptance criteria
**Rule**
1. `RELEASING.md` states the rule of this amendment: z for only fixes, y for something new to play, x for 1.0.
2. `RELEASING.md` says that the owner decides each release and that no release follows a schedule.

**Check**
3. Rules, numbers and the save do not change. No code or script changes.

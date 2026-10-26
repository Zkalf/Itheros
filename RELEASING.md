# Releasing Itheros

The owner's runbook (plan 0009 D3). Claude prepares; only the owner releases. Spec 0007 has the rules behind it.

## How we number releases
A version is **x.y.z** (spec 0007 amendment 1). Each release raises one part; the parts after it go back to 0.

| Part | Goes up when | Script |
|---|---|---|
| **z** (fixes) | Only fixes: bugs, nits, wording, looks. No new rule, system or content. | `.\scripts\release.ps1 -Fix` |
| **y** (new things) | Something new to play: a new rule or system, new content, or a change to the pace. Fixes can come with it. | `.\scripts\release.ps1` |
| **x** (1.0) | The owner calls the game ready for a full release to friends, not only the closest ones. Until then x is 0. | comes with 1.0 |

No release follows a schedule. The owner decides each release; Claude may suggest one, with its number and why.

## The notes grow with each change
`releases/next.md` holds the notes of the next release, in plain words for players (#119).
- Each pull request with a change that players notice adds a line to it, or changes a line.
- A change that players do not notice (tests, scripts, specs, plans) adds no line.
- So you can read what changed since the last release at any time, and the notes are ready when you release.

## A normal release
1. Read `releases/next.md`. Claude tidies it in a pull request if you ask: a first line that sums it up, the
   biggest changes first. Merge that (`.\scripts\merge.ps1 <number>`, or `! scripts/merge.sh <number>` from the
   Claude Code prompt).
2. In a PowerShell window in the project folder:
   ```
   git pull
   .\scripts\release.ps1
   ```
   Use `.\scripts\release.ps1 -Fix` for a release of only fixes (0.3.0 → 0.3.1) instead of one with something new
   (0.3.0 → 0.4.0). See [How we number releases](#how-we-number-releases).
   From this terminal: `! powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release.ps1`
3. It stops at the first problem. Before the upload, a failure undoes everything; just fix it and run it again.
4. When it says `RELEASED`, tell Claude: it downloads the game through the friend link and checks it.

## Taking back a bad release
Android can't install an older version over a newer one, so "going back" is always a new, fixed version.
1. **Stop new installs right away.** Mark the bad release as a pre-release:
   ```
   gh release edit v0.3.0 --repo Zkalf/Itheros --prerelease
   ```
   The plain link (`releases/latest`) and Obtainium skip pre-releases, so new installs get the version before it
   (after a few seconds; `gh release list --repo Zkalf/Itheros` shows which one is "Latest").
   Friends who already have the bad version keep it for now.
2. Tell friends who updated: "don't uninstall; a fix is coming" (uninstalling deletes their game).
3. Claude fixes the bug (the `bugfix` skill, an incident record) in a pull request; you merge it.
4. `git pull`, then `.\scripts\release.ps1 -Fix`. The fix (0.3.1) goes over the bad version and keeps everyone's
   game. Friends with Obtainium are told; others open the plain link again.
5. Optionally delete the bad release afterwards: `gh release delete v0.3.0 --repo Zkalf/Itheros` (keep the tag).

## Restoring the release key
Needed on a new PC, or if `%USERPROFILE%\.itheros\` or `app\android\key.properties` is lost. Friends' phones only
accept updates signed with this exact key.
1. Open your Bitwarden secure note with the Itheros key (or the USB stick copy). It holds the key file in base64,
   the `key.properties` text and the restore steps; follow them.
2. Prove it's the right key: `.\scripts\release.ps1 -DryRun` must end with `signed with the release key` and
   `DRY RUN PASSED`.

If both the Bitwarden note and the USB copy are ever lost, the key can't be recreated: every friend would have to
uninstall (losing their game) and install a new-key version. Keep both backups.

## Good to know
- Your own builds (`.\scripts\check.ps1 -Release`, with test walk) use the same version as the last release.
- `.\scripts\release.ps1 -DryRun` builds and checks everything and publishes nothing. Claude may run it; the
  production gate (`.claude/hooks/production-gate.ps1`) blocks Claude from anything more.

# Plan 0009: Deploy and Maintain stages

Status: accepted (2026-10-20)
Builds on: plan 0002 (Test stage), plan 0008 (GitHub repo, release command) · Playbook stages 5 and 6
Product owner: Zkalf · Date: 2026-10-20

## Why
The Deploy stage was put off while the game lived only on the owner's PC ("one-man project"). With a public repo
and friends installing releases, its core ideas now apply, scaled to one person:
- Changes are reviewed as **pull requests** against a written **REVIEW.md**, and a **CI check** runs on every one.
- The agent acts **up to the production gate and can't pass it**: only the owner publishes releases, and Claude
  can't touch the signing key.
- There is a **rollback** answer for a bad release.
- **Maintain:** the game sends nothing home (by design), so friends' reports are the monitoring. Each one becomes
  an **incident record**, a regression eval, and a fix or a new intent.

What the playbook has that this plan leaves out (enterprise-sized): managed settings, environment tiers, OpenTelemetry
audit, metric bands and σ-tier alerting, an on-call Slack agent.

## Steps
### D1: Pull requests with CI (scaled trunk-based development)
- `main` is the trunk and always releasable. Claude works on a short-lived branch (one per plan milestone, bug
  fix or document; merged within a day) and opens a PR (`gh pr create`) with the proof in the description. The
  PR links its intent/spec/plan. PRs are squash-merged, so each change is one commit on `main`.
- `scripts\merge.ps1 <PR number>`: the owner's merge from the terminal. It shows the PR's title, description and
  changed files and the check result, and merges only when the check is green. The GitHub app works too.
- A PreToolUse hook blocks Claude from running `gh pr merge` or `merge.ps1` and from pushing to `main`: Claude
  opens PRs, only the owner merges. (gh is signed in as the owner, so PRs appear under the owner's name; GitHub
  doesn't allow approving your own PR, which is why the merge is the approval.)
- `.github/workflows/check.yml`: on every PR and push to `main`, a Windows runner sets up Flutter and the Android
  SDK and runs `scripts\check.ps1 -Release`. It builds with the debug key (no key in CI, ever) and so still proves
  no INTERNET and no cloud backup.
- Branch protection on `main`: a PR and a green check are required. Admins may bypass it, so `release.ps1`
  (the owner's) can still push its "Release x.y.z" commit and tag; the hook above keeps Claude from doing the
  same. **The owner's approval is the merge.**
- Accepting an intent, spec or plan becomes merging its PR, as the playbook describes.

### D2: REVIEW.md
At the repo root: the review passes (spec acceptance criteria, correctness, health data stays on the phone, saves
load across versions, tests prove the change), what counts as **Important** (must fix before merge) versus a
**Nit** (at most 3 per review), and exclusions (save fixtures, `docs/commit-map.md`, generated files). Claude runs
the review (`/code-review` with the verifier's findings) and posts it on the PR. A finding that repeats goes into
`CLAUDE.md`.

### D3: The production gate
- A PreToolUse hook blocks Claude from running `release.ps1` except with `-DryRun`.
- `.claude/settings.json` deny rules: no reading `app/android/key.properties` or `~/.itheros/**`.
- `RELEASING.md` (runbook): how to release; how to take back a bad release (mark it a pre-release on GitHub so
  Obtainium and the plain link skip it, then `release.ps1 -Fix` with the fix; Android can't go back to an older
  version, so "rollback" is always a new, higher version); how to restore the key from the backup.
- One rehearsal: a dry run plus a pretend bad release on a throwaway test repo.

### M1: Incident records
- `incidents/NNNN-<name>.md` (template): who reported it and how, the version, what happened, the cause, the fix
  PR, the regression eval, and the lesson (and whether it went into `CLAUDE.md`). The `bugfix` skill writes one for
  every bug from real use.
- Small fixes go straight to a PR; bigger findings become a new `intent/` file (the playbook's loop back to Plan).

### M2: A security pass
`/security-review` of the whole repo once, now that it's public, and on any PR that touches `app/android/`,
`scripts/` or `.claude/`.

## Owner decisions
1. Use pull requests (D1) at all, or keep committing straight to `main`? **Decided 2026-10-20: yes, scaled
   trunk-based development; the owner merges from the terminal (`merge.ps1`) or the GitHub app.**
2. Scheduled eval runs in CI (the playbook's `agent-evals.yml`)? They need an Anthropic API key as a GitHub secret
   and cost about $10 a run. **Decided 2026-10-20: no for now; evals keep running locally when the setup changes.**

## Proof
D1: a PR from Claude, CI green, merged by the owner with `merge.ps1`; a PR with a failing check can't be merged;
the hook blocks Claude's `gh pr merge` and push to `main`. D2: the first
review posted per REVIEW.md. D3: the hook blocks `release.ps1` without `-DryRun`; a read of `key.properties` is
denied; the rehearsal works. M1: the first incident record (from the next real report). M2: review findings fixed or
dismissed with a reason.

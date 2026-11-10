# Spec 0022 amendment 1: the tour's last card names the Bank button

Status: accepted
Amends: [spec 0022](0022-camp-tour.md) §3.1, the words of step 6
Issue: #255 (found with [spec 0020 amendment 5](0020-item-bank.amendment-5.md), the Bank button in the top bar)
Product owner: Zkalf (asked on 2026-11-10 to do it soon)
Date: 2026-11-10

## Why
- The top bar has a Bank button since spec 0020 amendment 5. The tour's last card lists the buttons "up top" and
  leaves it out.

## Change
1. The words of step 6 become: "Up top: the bank, your supply chest, your achievements, the Journal and Settings.
   Settings can show you this tour again. Off you go, {name}. Walk."
2. Nothing else of the tour changes.

## Acceptance criteria
1. The card of step 6 shows the words of change 1, with the player's name.

**Check and release**
2. Rules, numbers and the save do not change. The pacing test passes.
3. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

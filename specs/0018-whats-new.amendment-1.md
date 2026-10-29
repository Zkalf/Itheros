# Spec 0018 amendment 1: a list inside a list item

Status: accepted
Amends: [spec 0018](0018-whats-new.md) §3.3 (the format of the notes)
Issue: #118
Product owner: Zkalf (accepted on 2026-10-29, instead of a change to the published 0.4.0 notes)
Date: 2026-10-29

## Why
- `releases/0.4.0.md` has a list inside a list item: "  - **Milestones** …" and "  - **Feats** …" under
  "**30 achievements:**".
- Spec 0018 §3.3 rule 3 reads a line that starts with two spaces as more text of the item. The card would show
  "Early, Mid and Late. Each one shows its reward. - Milestones come …" as one item.
- The test of criterion 3 would fail on `releases/0.4.0.md`, because "  - " is outside §3.3.
- GitHub shows the two lines as a list inside the item. Players saw them that way on the release page.

## Change
1. **A list inside a list item:** a line that starts with two spaces and "- " is an item of a second list. It
   belongs to the item above it.
2. The card shows such an item with its own bullet, indented one step more than the item above it.
3. A line that starts with four spaces and follows an item of the second list is more text of that item.
4. A second list inside an item of the second list is outside the format. It stays plain text (§3.3 rule 5).
5. The other rules of §3.3 stay as they are. A line that starts with two spaces and no "- " is still more text of
   the item above it.
6. The words of `releases/0.4.0.md` do not change.

## Acceptance criteria
**The format**
1. "  - " under an item shows as an item with a bullet, indented more than the item above it.
2. The test of spec 0018 criterion 3 passes on `releases/0.4.0.md`.
3. A line with two spaces and no "- " under an item still joins the text of that item.

**Check and release**
4. Rules, numbers and the save do not change. The pacing test passes.
5. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

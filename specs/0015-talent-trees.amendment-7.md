# Spec 0015 amendment 7: Ysolde says "Reset"

Status: accepted
Amends: [spec 0015](0015-talent-trees.md) §2.7 (the reset button and the confirmation)
Issue: #157
Product owner: Zkalf (2026-11-01: "Ysolde should state reset instead of forget". Then: "Do the nit we talked about
before")
Date: 2026-11-01

## Why
The game calls it a reset (§2.6), but Ysolde's sheet says "Forget". One name for one thing.

## Change
1. **The button:** **Reset my talents** (free) or **Reset my talents · 4,000 steps**.
2. **The confirmation:** "Reset every talent? Your points come back to spend again." with **Reset** and **Keep**.
3. **What stays:** Ysolde's other lines, the price, and the rules of the reset.

## Acceptance criteria
**Trainer**
131. Ysolde's sheet says "Reset my talents", and "Reset my talents · 2,000 steps" for a paid reset.
132. The confirmation asks "Reset every talent? Your points come back to spend again." with Reset and Keep.
133. No screen of the trainer says "Forget".

**Check and release**
134. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

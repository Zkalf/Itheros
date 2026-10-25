# Spec NNNN amendment N: <what changes, in a few words>

<!--
A guide, not a form. Keep the header, Why, Change and the acceptance criteria; add sections when they help.
Follow WRITING.md. Name the file specs/NNNN-<name>.amendment-N.md with the next free N for that spec.
An amendment changes an accepted spec without editing it. A wording error of the author is an erratum instead.
-->

Status: draft
Amends: [spec NNNN](NNNN-<name>.md) §<section> (<what it is about>)
Issue: #N
Product owner: Zkalf (<what the owner chose, and when>)
Date: <YYYY-MM-DD>

## Why
<!-- What goes wrong or is missing today, as the player sees it. -->
-

## Change
<!-- Numbered. Say what stays, too, when a reader could doubt it. -->
1. **<Short name>:** <the new rule or look>.
2. <What stays as it is.>

## Acceptance criteria
<!-- One check per criterion, grouped under short headings, numbered in one series (WRITING.md rules 13-14). -->
**<Group>**
1. <one thing that a test or the owner can check>

**Check and release**
2. Rules, numbers and the save do not change. The pacing test passes.
3. `.\scripts\check.ps1 -Release` is green, and the release build declares no INTERNET permission.

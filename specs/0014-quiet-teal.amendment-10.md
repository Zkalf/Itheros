# Spec 0014 amendment 10: the emblem fills the launcher icon

Status: accepted
Amends: [spec 0014](0014-quiet-teal.md) §3.3 (the launcher icon) and criterion 24 ("The launcher shows the emblem on
`#060708`")
Issue: #222
Product owner: Zkalf (playtest of 2026-11-06: "The icon is fine, just remove the black border.")
Date: 2026-11-06

## Why
- The emblem is round, and it sits inside Android's safe zone: a circle of 66 dp in the icon's 108 dp.
- The launcher shows a circle of 72 dp. So a ring of the background `#060708` shows around the emblem: a black border.

## Change
1. The emblem and the one-colour emblem grow until the emblem's circle is about 74 dp across, a little more than the
   72 dp that a round launcher shows. On a round icon no background shows.
2. The picture of the emblem does not change, only its size in the icon files. The launcher crops its outer edge a
   little.
3. The background layer stays `#060708`. A launcher with square or rounded-square icons still shows it in the
   corners.
4. The splash screen uses the same file, so its emblem grows by the same share.

## Acceptance criteria
1. In each density, the emblem covers the whole circle of 72 dp in the centre of the 108 dp icon: no pixel inside it
   is transparent.
2. The one-colour emblem has the same size as the emblem, and still one colour.
3. The adaptive icon keeps its three layers: the background `#060708`, the emblem and the one-colour emblem.

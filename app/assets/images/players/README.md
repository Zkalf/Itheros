# Portraits

This folder holds the portraits of the player (spec 0014 §3.1). No portrait exists yet.

- The file name is `<origin>_<gender>.webp`, for example `coast_fisher_female.webp`.
- The origin is an `id` in `packages/game_core/data/origins.json`.
- The gender is `male`, `female` or `neither`.
- A portrait without a file shows `placeholders/player.webp`.
- The app reads the file names at start, so a new portrait needs no code change.

`app/pubspec.yaml` lists this folder. Flutter stops with an error when a listed folder does not exist, and Git
keeps no empty folder. So this file stays here.

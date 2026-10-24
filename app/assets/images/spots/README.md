# Gathering spots

This folder holds the pictures of the gathering spots (spec 0014 amendment 1). No picture exists yet.

- The file name is `<spot id>.webp`, for example `copper_vein.webp`.
- The spot id is an `id` under `nodes` in `packages/game_core/data/world.json`.
- A spot without a file shows the tool placeholder of its profession, for example `placeholders/tool_mining.webp`.
- The app reads the file names at start, so a new picture needs no code change.

`app/pubspec.yaml` lists this folder. Flutter stops with an error when a listed folder does not exist, and Git
keeps no empty folder. So this file stays here.

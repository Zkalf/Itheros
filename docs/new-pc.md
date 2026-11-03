# Working on another PC

The code, specs, plans and issues are on GitHub. Claude's memory of the project lives on each PC and syncs only
by hand, with `scripts\sync-memory.ps1`. The release key stays on the PC that releases and installs on the phone.

## Change PC
1. On the PC that you leave: `.\scripts\sync-memory.ps1 -Push`. It copies Claude's memory to
   `OneDrive\Itheros\claude-memory\`.
2. On the PC that you start: `git pull`, then `.\scripts\sync-memory.ps1 -Pull`.

Each run names the files that it adds, changes and removes. It first backs up the memory that it replaces, to
`%USERPROFILE%\.claude\memory-backups\`. If you forget step 1, Claude misses only its newest notes. The rules are in
the repo (`CLAUDE.md`, the skills).

From the Claude Code prompt (Git Bash):
`! powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sync-memory.ps1 -Pull`

## Set up a new PC (once)
1. Install Git, the GitHub CLI, Claude Code, JDK 17, Android Studio (for the Android SDK) and Flutter 3.47.7 stable.
   Put Flutter on PATH.
2. Set Git's name and no-reply email, for all repos:
   ```
   git config --global user.name Zkalf
   git config --global user.email 15740075+Zkalf@users.noreply.github.com
   ```
3. Clone the repo and sign in to GitHub:
   ```
   git clone https://github.com/Zkalf/Itheros.git
   gh auth login
   ```
4. Start Claude Code once in the repo folder, so that it makes its project folder. Then run
   `.\scripts\sync-memory.ps1 -Pull`.
5. Optional: copy `%USERPROFILE%\.claude\settings.json` and `statusline.ps1` from the old PC.
6. Only on a PC that releases or installs on the phone: copy the release key yourself (RELEASING.md). Claude never
   touches it.
7. Check: `.\scripts\check.ps1`. On a PC with the key: `.\scripts\check.ps1 -Release`.

# Working on another PC

The code, specs, plans and issues are on GitHub. Claude's memory of the project lives on each PC and syncs only
by hand, with `scripts\sync-memory.ps1`. The release key stays on the PC that releases and installs on the phone.
A copy of this guide is in `OneDrive\Itheros\move.md`, for a PC that has no clone yet.

## Change PC
1. On the PC that you leave: `.\scripts\sync-memory.ps1 -Push`. It copies Claude's memory to
   `OneDrive\Itheros\claude-memory\`.
2. On the PC that you start: `git pull`, then `.\scripts\sync-memory.ps1 -Pull`.

Each run names the files that it adds, changes and removes. It first backs up the memory that it replaces, to
`%USERPROFILE%\.claude\memory-backups\`. If you forget step 1, Claude misses only its newest notes. The rules are in
the repo (`CLAUDE.md`, the skills).

From the Claude Code prompt (Git Bash):
`! powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sync-memory.ps1 -Pull`

Claude can run either direction for you: say "push my memory" or "pull my memory".

Claude's own settings (`%USERPROFILE%\.claude\settings.json` and `statusline.ps1`) change rarely. After a change,
copy them to `OneDrive\Itheros\claude-settings\` by hand, or ask Claude to.

## Set up a new PC (once)
Claude does most of the work. You do only what needs you: two installs, the sign-ins, the Windows prompts and the key.

### What you do
1. Install Git: `winget install Git.Git`. Install Claude Code as on the other PC.
2. Open PowerShell in your user folder, start `claude`, and sign in.
3. Say: **"Set up Itheros on this PC: follow OneDrive\Itheros\move.md, the part for Claude."**
4. While Claude works:
   - Click **Yes** on each Windows prompt for an installer.
   - When Claude asks, sign in to GitHub: type `! gh auth login`, pick GitHub.com, HTTPS and the browser.
5. When Claude says so, quit Claude and start it again in `Desktop\Itheros`. Say: **"Finish the PC setup."**
6. Only on a PC that releases or installs on the phone: copy the release key yourself (`RELEASING.md`, "Needed on a
   new PC"). Claude never touches it. Then plug in the Fairphone, allow USB debugging, and turn off USB selective
   suspend (Power options).

### What Claude does
Claude runs each step, checks it, and says what it did. Versions are the ones of the main PC (2026-11-03).
1. **JDK 17 and the GitHub CLI:** `winget install Microsoft.OpenJDK.17 GitHub.cli`. Set the user variable
   `JAVA_HOME` to the JDK folder if the installer did not. Optional, only to change the art (`art/README.md`):
   Python 3 (`winget install Python.Python.3.14`).
2. **Git's name and no-reply email,** for all repos:
   ```
   git config --global user.name Zkalf
   git config --global user.email 15740075+Zkalf@users.noreply.github.com
   ```
3. **GitHub sign-in:** ask the owner for `! gh auth login`, then check `gh auth status`.
4. **The repo:** `git clone https://github.com/Zkalf/Itheros.git "$HOME\Desktop\Itheros"`.
5. **Flutter 3.47.7 stable:** `git clone --depth 1 -b 3.47.7 https://github.com/flutter/flutter.git
   "$HOME\dev\flutter"`. Add `$HOME\dev\flutter\bin` to the user PATH. Run `flutter --version`.
6. **The Android SDK, without Android Studio:**
   - Download the newest "Command line tools only" zip for Windows (developer.android.com/studio). Unzip it so that
     `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat` exists.
   - Set the user variable `ANDROID_HOME` to `%LOCALAPPDATA%\Android\Sdk`.
   - Install: `"platform-tools" "platforms;android-36" "platforms;android-35" "build-tools;36.0.0"
     "ndk;28.2.13676358" "cmake;3.22.1"`.
   - Accept the licences through `cmd /c "sdkmanager.bat --licenses < yes.txt"`, with a file of "y" lines.
     PowerShell pipes do not reach `.bat` tools (`CLAUDE.md`, Known mistakes).
   - Run `flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk"` and `flutter doctor`.
7. **The memory:** `.\scripts\sync-memory.ps1 -Pull` from the repo.
8. **Claude's settings:** copy `settings.json` and `statusline.ps1` from `OneDrive\Itheros\claude-settings\` into
   `%USERPROFILE%\.claude\`. Back up the PC's own `settings.json` first if it has one. The copies in
   `claude-move.zip` are older: do not use them.
9. Tell the owner to start Claude again in `Desktop\Itheros` (owner step 5). Then:
   - Say what the memory holds ("I know the project: ...").
   - Run `.\scripts\check.ps1`. On a PC with the key: `.\scripts\check.ps1 -Release`.
   - Report the result and anything that failed.

#!/bin/sh
# The owner's merge from the Claude Code prompt, whose ! runs Git Bash: ! scripts/merge.sh <number>
# Runs scripts/merge.ps1 (the production gate blocks Claude from both).
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/merge.ps1" "$@"

#!/bin/bash

# Sync dot-files repos with GitHub (run manually via `dot-sync`).
# The repo is the directory this script lives in.
baseDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gitDirs=("$baseDir")

for dir in "${gitDirs[@]}"; do
    echo -e "\n--> $dir"
    [ -d "$dir/.git" ] || { echo "not a git repo, skipping"; continue; }
    cd "$dir" || continue
    # commit local edits first so the tree is clean for rebase
    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "dot-sync $(date '+%Y-%m-%d %H:%M')"
    else
        echo "nothing to commit"
    fi
    if ! git pull --rebase; then
        git rebase --abort 2>/dev/null
        echo "pull failed (conflict?), skipping push for $dir"
        continue
    fi
    if git remote get-url origin >/dev/null 2>&1; then
        git push
    else
        echo "no origin remote, skipping push"
    fi
done

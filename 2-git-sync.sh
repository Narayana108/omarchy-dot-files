#!/bin/bash

# Sync dot-files repos with GitHub (run manually via `dot-sync`).
gitDirs=("${HOME}/Dev/git/dot-files")

for dir in "${gitDirs[@]}"; do
    echo -e "\n--> $dir"
    [ -d "$dir/.git" ] || { echo "not a git repo, skipping"; continue; }
    cd "$dir" || continue
    if ! git pull --rebase; then
        echo "pull failed (conflict?), skipping commit/push for $dir"
        continue
    fi
    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "dot-sync $(date '+%Y-%m-%d %H:%M')"
    else
        echo "nothing to commit"
    fi
    if git remote get-url origin >/dev/null 2>&1; then
        git push
    else
        echo "no origin remote, skipping push"
    fi
done

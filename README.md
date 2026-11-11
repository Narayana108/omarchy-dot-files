# omarchy-dot-files

Personal dot-file config synced between two laptops (Arch/Omarchy) via this private GitHub repo.

## Layout

| Path | Purpose |
|---|---|
| `config/` | Every non-hidden file here is symlinked into `~/.config` by `1-create-symlinks.sh`, mirroring subdirectories |
| `bin/dev-container` | Symlinked to `~/.local/bin/dev-container`; only files listed in the script's `binFiles` array are linked — add a name there to link another bin |
| `global-bashrc` / `naga-bashrc` | Bash config, sourced from `~/.bashrc` via `DOT_FILES` |
| `1-create-symlinks.sh` | Creates/refreshes the symlinks (repo files win; existing targets replaced silently) |
| `2-git-sync.sh` | Pull --rebase, commit everything, push; run manually as `dot-sync` |

## Setup on a new laptop

1. Clone this repo to `~/Dev/git/dot-files`.
2. Add near the top of `~/.bashrc`:
   ```bash
   DOT_FILES="$HOME/Dev/git/dot-files"
   source "$DOT_FILES/naga-bashrc"
   source "$DOT_FILES/global-bashrc"
   ```
3. Make scripts executable: `chmod +x *.sh`
4. Run `./1-create-symlinks.sh`.

## Day-to-day

Edit the files in this repo — they are live through the symlinks — then run `dot-sync` on each laptop to pull/push changes.

## Machine-specific configs

Untracked per-laptop configs stay local and never sync, e.g. `~/.config/hypr/monitors.lua`, `hyprland.lua`, `looknfeel.lua`, `autostart.lua`, `.luarc.json`. Only files under this repo's `config/` are synced. If the repo is cloned somewhere other than `~/Dev/git/dot-files`, the symlink script still works (it resolves its own location), but `DOT_FILES` in `~/.bashrc` must point at the actual clone path.

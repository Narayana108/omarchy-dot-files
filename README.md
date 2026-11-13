# omarchy-dot-files

Personal dot-file config for Arch/Omarchy, synced between machines through this repo.

## Layout

| Path | Purpose |
|---|---|
| `config/` | Every non-hidden file here is symlinked into `~/.config` by `1-create-symlinks.sh`, mirroring subdirectories |
| `bin/dev-container` | Symlinked to `~/.local/bin/dev-container`; only files listed in the script's `binFiles` array are linked — add a name there to link another bin |
| `agent_workspace_container/` | `Dockerfile` for `localhost/thoth:debian13`, the sandbox image `bin/dev-container` launches — see [its README](agent_workspace_container/README.md) |
| `global-bashrc` / `naga-bashrc` | Bash config, sourced from `~/.bashrc` via `DOT_FILES` |
| `1-create-symlinks.sh` | Creates/refreshes the symlinks (repo files win; existing targets replaced silently) |
| `2-git-sync.sh` | Commit everything, pull --rebase (aborts on conflict, never pushes a conflicted tree), push; run manually as `dot-sync`. Syncs the repo the script lives in |
| `.gitignore` | Keeps secrets, logs, and machine-local overrides out of the tree — `2-git-sync.sh` runs `git add -A`, so this is what stops stray files being committed |

## Setup on a new laptop

1. Clone this repo to `~/Dev/git/omarchy-dot-files`.
2. Add near the top of `~/.bashrc`:
   ```bash
   DOT_FILES="$HOME/Dev/git/omarchy-dot-files"
   source "$DOT_FILES/naga-bashrc"
   source "$DOT_FILES/global-bashrc"
   ```
3. Make scripts executable: `chmod +x *.sh`
4. Run `./1-create-symlinks.sh`.

## Day-to-day

Edit the files in this repo — they are live through the symlinks — then run `dot-sync` on each laptop to pull/push changes.

## Agent workspace container

`dev-container` opens a Podman sandbox for an agent harness to work in. It
lists the immediate subdirectories of `/data/llms/agent_workspaces` plus the
directory you invoked it from (labelled `(current directory)`), asks which
harness to run, allocates three free ports, and starts the container with the
chosen directory bind-mounted at `/workspace`.

```bash
dev-container            # pick workspace, then harness
```

The image it needs is built from `agent_workspace_container/`:

```bash
cd agent_workspace_container && podman build -t localhost/thoth:debian13 .
```

See [agent_workspace_container/README.md](agent_workspace_container/README.md)
for what goes into the image and how the mounts are laid out.

## Machine-specific configs

Untracked per-laptop configs stay local and never sync, e.g. `~/.config/hypr/monitors.lua`, `hyprland.lua`, `looknfeel.lua`, `autostart.lua`, `.luarc.json`. Only files under this repo's `config/` are synced. If the repo is cloned somewhere other than `~/Dev/git/omarchy-dot-files`, the symlink script still works (it resolves its own location), but `DOT_FILES` in `~/.bashrc` must point at the actual clone path.

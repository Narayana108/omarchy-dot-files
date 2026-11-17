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
lists the immediate subdirectories of `/data/llms/agent_workspaces` (override
with `DEV_CONTAINER_WORKSPACES_DIR`) plus the directory you invoked it from
(labelled `(current directory)`), asks which harness to run, allocates three
free ports, and starts the container with the chosen directory bind-mounted at
its host path, which is also the container's working directory.

```bash
dev-container            # pick workspace, then harness
dev-container --new      # skip the session menu, start fresh
dev-container --resume ID
dev-container --list     # print resumable sessions and exit
dev-container --clean    # remove stopped dev-container containers
dev-container --build    # rebuild the image
```

It refuses to mount `/`, `$HOME`, or an ancestor of `$HOME`, and forwards the
host's git identity so `git commit` works inside the container.

It then lists the sessions that harness can resume in that workspace — title,
size, date, message count, id, and model — and resumes the one you pick (or
starts a new one). A fine-grained GitHub PAT exported as `LLM_GH_TOKEN` is
passed into the container as `GH_TOKEN`, so `gh` and HTTPS `git push` work
without credentials baked into the image.

The image it needs is built from `agent_workspace_container/`:

```bash
cd agent_workspace_container && podman build -t localhost/thoth:debian13 .
```

See [agent_workspace_container/README.md](agent_workspace_container/README.md)
for what goes into the image and how the mounts are laid out. The image carries
the usual CLI tooling — `rg`, `fd`, `bat`, `fzf`, `jq`, `yq`, `sqlite3`,
`shellcheck`, `shfmt`, `uv`, `ruff`, `delta`, `eza`, `zoxide`, `just`, `cloc`,
`tokei`, `hyperfine`, `htop`, `tmux`, `vim`, `dig`, `nc`, `lsof`, `strace`,
`rsync`, `wget`, `gpg`, `git-lfs`, `git-filter-repo`, `moreutils`, `parallel`,
`entr`, `pv`, `bc`, `xxd`, `file`, `less`, and kitty/foot/alacritty/ghostty
terminfo. It also installs the language servers OMP auto-detects for shell,
Python, TypeScript/JS, Svelte, Vue, Astro, YAML/Ansible, PHP, Docker, GraphQL,
Prisma, Vim, Emmet, Go, Rust, and C/C++.

## Machine-specific configs

Untracked per-laptop configs stay local and never sync, e.g. `~/.config/hypr/monitors.lua`, `hyprland.lua`, `looknfeel.lua`, `autostart.lua`, `.luarc.json`. Only files under this repo's `config/` are synced. If the repo is cloned somewhere other than `~/Dev/git/omarchy-dot-files`, the symlink script still works (it resolves its own location), but `DOT_FILES` in `~/.bashrc` must point at the actual clone path.

# agent_workspace_container

Isolated container environments for agent harnesses to work in.

`bin/dev-container` launches this image so an agent harness (OMP, OpenCode, or
Qoder) gets its own sandbox with the workspace bind-mounted at its host path,
its own home directory, and its own copy of the harness configuration — instead
of running against your real dot-files.

## Build

```bash
podman build -t localhost/thoth:debian13 .
```

The tag must stay `localhost/thoth:debian13`: it is hardcoded as `IMAGE` in
`bin/dev-container`.

## What is in the image

Base: `docker.io/library/debian:13-slim`.

Toolchain, installed from upstream binaries with checksum verification where
upstream publishes one:

| Component | Version | Source |
|---|---|---|
| Node.js + npm | `26.13.0` (ARG) | `nodejs.org/dist`, verified against `SHASUMS256.txt` |
| Go | `1.27.4` (ARG) | `go.dev/dl`, verified against `GO_SHA256` |
| GitHub CLI (`gh`) | `2.104.0` (ARG) | `github.com/cli/cli` release tarball, verified against `GH_SHA256` |
| Bun | `1.4.4` (ARG) | `bun.com/install` |
| OMP (`@oh-my-pi/pi-coding-agent`) | latest at build time | `bun install -g` |
| OpenCode | latest at build time | `opencode.ai/install` |
| Qoder CLI | latest at build time | `npm install -g @qoder-ai/qodercli@latest` |

System packages: `bash`, `ca-certificates`, `curl`, `git`, `openssh-client`,
`build-essential`, `pkg-config`, `python3` (+ `dev`, `venv`, `pip`), `jq`,
`procps`, `ripgrep`, `unzip`, `xz-utils`, `libatomic1`, `passwd`.

Node, Go, and Bun are pinned through `ARG`s so a rebuild is reproducible. The
three harnesses float to latest — bump the pinned versions deliberately, but
expect harness behaviour to change under you without a Dockerfile edit.

## The `dev` user

Everything runs as an unprivileged user, `dev`, uid/gid `1000`, home
`/home/dev`, shell `bash`. The uid/gid pair is not arbitrary: `dev-container`
starts the container with `--userns="keep-id:uid=1000,gid=1000"`, so files the
agent creates in `/workspace/<workspace-name>` are owned by your host uid.

Pre-created as `dev`-owned `0700` directories, so bind mounts land on real
directories rather than being created as root:

```
/home/dev/.omp/agent          /home/dev/.config/opencode
/home/dev/.omp/run            /home/dev/.local/share/opencode
/home/dev/.npm-global/bin     /home/dev/.qoder
```

`PATH` puts `~/.bun/bin`, `~/.npm-global/bin`, `~/.opencode/bin`, `~/go/bin`,
and `/usr/local/go/bin` ahead of the system directories.

Qoder is installed and smoke-tested against a throwaway `HOME`
(`/tmp/qoder-check`) and then deleted. Its npm dispatcher self-bootstraps into
`$HOME/.qoder` and rewrites the shell rc on first run; running it against a
throwaway home keeps `/home/dev/.qoder` a pure mount target and leaves
`/home/dev/.profile` untouched.

`WORKDIR` is `/workspace` (the default for a plain `podman run`); `CMD` is
`bash`. `dev-container` always overrides the working directory with
`--workdir=/workspace/<workspace-name>`.

## How `dev-container` uses it

`bin/dev-container` mounts:

| Host | Container | Mode |
|---|---|---|
| selected workspace directory | same absolute path as on the host (also the working directory) | rw |
| `<workspace>/.git/hooks` | `<workspace>/.git/hooks` | ro |
| `<workspace>/.git/config` | `<workspace>/.git/config` | ro |
| `$(omp config path)` | `/home/dev/.omp/agent` | rw |
| `$(omp config path)/extensions` | `/home/dev/.omp/agent/extensions` | ro |
| `$(omp config path)/managed-skills` | `/home/dev/.omp/agent/managed-skills` | ro |
| `$(omp config path)/agents` | `/home/dev/.omp/agent/agents` | ro |
| `$(omp config path)/memories` | `/home/dev/.omp/agent/memories` | ro |
| `$(omp config path)/config.yml` | `/home/dev/.omp/agent/config.yml` | ro |
| `$(omp config path)/models.yml` | `/home/dev/.omp/agent/models.yml` | ro |
| `~/.omp/plugins` | `/home/dev/.omp/plugins` | ro |
| `~/.config/opencode` | `/home/dev/.config/opencode` | ro |
| `~/.local/share/opencode` | `/home/dev/.local/share/opencode` | rw |
| `~/.local/state/opencode` | `/home/dev/.local/state/opencode` | rw |
| `~/.claude/skills` | `/home/dev/.claude/skills` | ro |
| `~/.agents/skills` | `/home/dev/.agents/skills` | ro |
| `/usr/share/omarchy/default/agents/skills` | same path | ro |
| `~/.qoder` | `/home/dev/.qoder` | rw |
| `~/.qoder/entry`, `.bin`, `security-resources`, `external-commands`, `plugins`, `shell-snapshots` | same paths under `/home/dev/.qoder` | ro |
| `~/.qoder/settings.json` | `/home/dev/.qoder/settings.json` | ro |

The read-only entries shadow the writable config mounts: the harness can read
its extensions, skills, agents, OpenCode config, Qoder dispatcher/runtime/plugin
hooks, and git hooks/config, but cannot replace them with code the host would
execute.

`dev-container` also writes two host-side views so OMP and OpenCode see the same
material:

- `~/.config/opencode/agents/omp-<name>.md` — OMP agent bodies converted to
  OpenCode subagents. OMP's `model`/`tools`/`spawns` frontmatter is not
  OpenCode-compatible, so only `description`, `mode: subagent`, and the body are
  kept.
- `~/.config/opencode/skills/<name>` — relative symlinks to
  `~/.omp/agent/managed-skills/<name>`. OpenCode does not follow a symlinked
  source root, so each skill is linked individually.

Both are inside the read-only `~/.config/opencode` mount, so the container sees
them but cannot change them.

`GH_TOKEN` is passed through from the host environment (see
[GitHub authentication](#github-authentication)) so `gh` and HTTPS `git push`
authenticate without any credential in the image.

The container runs with `--cap-drop=ALL`, `--security-opt=no-new-privileges`,
`--pids-limit=512`, and publishes three ports on `127.0.0.1` only:

| Container port | Purpose |
|---|---|
| `3000` | OMP |
| `5173` | Vite |
| `8000` | API |

`dev-container` allocates the host side of each from `3000`/`5173`/`8000`
upwards in steps of `1000`, picking the first free triple.

## GitHub authentication

`dev-container` forwards a token only when you export one explicitly, as
`LLM_GH_TOKEN` (preferred) or `GH_TOKEN`. It never calls `gh auth token`: that
returns the host's broad OAuth credential, and handing it to a sandboxed agent
widens the blast radius for no reason. Use a fine-grained PAT scoped to the
repositories the agent needs (`Contents: Read and write`, plus `Metadata: Read`
and any of `Pull requests` / `Issues` / `Workflows` you want it to touch), with
an expiration.

The value is copied from the host environment with `--env GH_TOKEN`; it is
never written to the image or to `~/.gitconfig`, and it does not appear in the
container's argv.

The image installs `gh` and sets a global credential helper:

```bash
git config --global credential.https://github.com.helper '!gh auth git-credential'
```

so HTTPS `git push` authenticates through `GH_TOKEN`. SSH remotes
(`git@github.com:…`) ignore the token — switch them to HTTPS or clone with `gh`
to push from inside the container.

## Session resume

After you pick a harness, `dev-container` lists the sessions that harness can
resume in the selected workspace and lets you pick one:

```
Sessions in this workspace:

   #  Modified              Size   Msgs  Title
   1  2026-11-17 08:58  650.2 KB     64  Add cwd workspace option to dev-container
      01a1d3ac-bd7a-70c0-892a-96363ab508ee  openrouter/baidu/ernie-5.5-flash-preview:free
   2  2026-11-17 08:58  512.0 KB    167  Dev container cwd workspace
      01a1d3b3-adeb-71f3-92da-4aa314908054  baidu/ernie-5.5-flash-preview:free

   3) new session

Select session number (or q to quit):
```

Each entry shows the title, size, modification time, message count, session id,
and model. Enter a number to resume that session, the last number (or an empty
line) to start a new one, or `q` to quit.

| Harness | Resume flag |
|---|---|
| OMP | `--resume <id>` |
| OpenCode | `--session <id>` |
| Qoder | `--resume <id>` |

Sessions are keyed by the canonical workspace path, which is the same inside
and outside the container, so a session started on the host is offered in the
container and vice versa. `PI_CODING_AGENT_SESSION_DIR` points OMP at the
host bucket explicitly; OpenCode and Qoder resolve it from the cwd.

Because the session store is shared read-write, the container can read and
rewrite the host's conversation history. That is the tradeoff for resuming host
sessions; the read-only overlays above still stop it from planting new code.

## Security

The container is an isolation boundary, not a second host.

- Runs as unprivileged `dev` (uid/gid `1000`) with `--userns=keep-id`, so files
  it writes in the workspace are owned by your host uid and it cannot act as
  root on the host.
- `--cap-drop=ALL`, `--security-opt=no-new-privileges`, `--pids-limit=512`.
- Ports are published on `127.0.0.1` only.
- No SSH agent, no `~/.ssh`, no host keyring, no Docker/Podman socket.
- `GH_TOKEN` is the only credential passed through the environment, and only
  when you export it explicitly. It is a fine-grained PAT, not the host's broad
  OAuth token. Provider credentials still live in the mounted harness data
  directories (see the residual risks).

Paths the host harness loads as code are mounted **read-only** over the
writable config mounts, so a compromised agent cannot plant something that runs
on the host at its next start:

| Path | Why |
|---|---|
| `~/.omp/agent/extensions` | OMP loads and executes these |
| `~/.omp/agent/managed-skills` | skills become agent instructions |
| `~/.omp/agent/agents` | agent definitions shape host behaviour |
| `~/.omp/agent/memories` | memories are injected into host sessions |
| `~/.omp/agent/config.yml`, `models.yml` | hooks and provider endpoints |
| `~/.omp/plugins` | OMP loads and executes npm plugins |
| `~/.config/opencode` | OpenCode loads `plugins/`, `tui.jsonc`, `opencode.json`, and the generated `agents/`/`skills/` views |
| `~/.claude/skills`, `~/.agents/skills` | shared skill trees |
| `/usr/share/omarchy/default/agents/skills` | targets of the `~/.agents/skills` symlinks |
| `~/.qoder/entry`, `.bin`, `security-resources`, `external-commands`, `plugins`, `shell-snapshots`, `settings.json` | Qoder dispatcher, runtime, plugin hooks, command registry, marketplace list, shell snapshots, policy |
| `<workspace>/.git/hooks`, `<workspace>/.git/config` | git hooks and `core.hooksPath`/`sshCommand` |

Creating a host-level extension, skill, agent, OpenCode plugin, Qoder plugin,
or git hook from inside the container therefore fails; do that on the host.
Project-local `.opencode/skills` and `.opencode/agents` still work because they
live in the writable workspace.

Residual risks to keep in mind:

- The harness data directories are shared read-write so sessions and auth work.
  They contain provider credentials (`agent.db`, `auth.json`, `~/.qoder/.auth`);
  treat the container as the same trust domain as your host user for those.
- `~/.omp/agent/agent.db`, `history.db`, `usage.db`, `sessions`, `blobs`, and
  `terminal-sessions` remain writable. A compromised agent can read the stored
  provider credentials and rewrite conversation history. The read-only
  overlays above stop it from planting *new* code, not from reading or
  corrupting existing state.
- The workspace is read-write. `.git/hooks` and `.git/config` are read-only,
  but `.git/index`, objects, refs, and logs are not, so a compromised agent can
  still rewrite history or the index. Review `git log`/`git diff` before
  running host-side git commands.
- `.gitattributes`, `.gitmodules`, `.envrc`, `Makefile`, `package.json` scripts,
  and editor task files live in the workspace and are writable. They only run
  when you invoke them on the host; review changes before you do.
- Network egress is unrestricted by design: the harness needs to browse the
  web. A compromised agent can therefore exfiltrate anything it can read. The
  read-only mounts reduce what it can *plant*, not what it can *send*.

## Rebuilding

The image is not rebuilt automatically. After editing the Dockerfile:

```bash
podman build -t localhost/thoth:debian13 .
```

`dev-container` refuses to start if the image is missing, and refuses to start
if a container of the same name already exists — remove a stale one with
`podman rm -f thoth-<workspace>`.
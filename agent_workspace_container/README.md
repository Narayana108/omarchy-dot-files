# agent_workspace_container

Isolated container environments for agent harnesses to work in.

`bin/dev-container` launches this image so an agent harness (OMP, OpenCode, or
Qoder) gets its own sandbox with a workspace bind-mounted at `/workspace`, its
own home directory, and its own copy of the harness configuration — instead of
running against your real dot-files.

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
agent creates in `/workspace` are owned by your host uid.

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

`WORKDIR` is `/workspace`; `CMD` is `bash`.

## How `dev-container` uses it

`bin/dev-container` mounts, read-write:

| Host | Container |
|---|---|
| selected workspace directory | `/workspace` (also the working directory) |
| `$(omp config path)` | `/home/dev/.omp/agent` |
| `~/.config/opencode` | `/home/dev/.config/opencode` |
| `~/.local/share/opencode` | `/home/dev/.local/share/opencode` |
| `~/.qoder` | `/home/dev/.qoder` |

The container runs with `--cap-drop=ALL`, `--security-opt=no-new-privileges`,
`--pids-limit=512`, and publishes three ports on `127.0.0.1` only:

| Container port | Purpose |
|---|---|
| `3000` | OMP |
| `5173` | Vite |
| `8000` | API |

`dev-container` allocates the host side of each from `3000`/`5173`/`8000`
upwards in steps of `1000`, picking the first free triple.

## Rebuilding

The image is not rebuilt automatically. After editing the Dockerfile:

```bash
podman build -t localhost/thoth:debian13 .
```

`dev-container` refuses to start if the image is missing, and refuses to start
if a container of the same name already exists — remove a stale one with
`podman rm -f thoth-<workspace>`.
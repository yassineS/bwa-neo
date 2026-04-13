# Contributing to bwa-neo

Read **`docs/requirements.md`**, **`docs/design.md`**, and **`docs/tasks.md`** before large changes. To **run the `bwa` binary** (subcommands, pipelines), see **`docs/USAGE.md`**. For **AI agents** or workspace setup, read **[`AGENTS.md`](AGENTS.md)** first.

**Repository location:** clone and work only under **`~/Code/bwa-neo`**—open that path as the workspace root; do not use the home directory as the project root for bwa-neo.

**Git workflow:** see **[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)** for branches (`main`, `feat/*`, `fix/*`), commits, PR flow, and **GitHub CLI (`gh`)** commands (`gh repo create`, `gh pr create`, etc.).

## Build

- **Make**: `make` (same as upstream BWA).
- **CMake**: `cmake -S . -B build && cmake --build build && ctest --test-dir build`.

## Git

If this tree was imported without `.git`, run `./scripts/init-git.sh` locally, then add your remote and push.

## Pull requests

1. Describe behaviour change vs BWA / bwa-mem2 compatibility.
2. Add or update tests (`tests/`, CI smoke).
3. Update `CHANGELOG.md` and **`docs/tasks.md`** checkboxes when completing a tracked item.

## Code style

Match surrounding C style in touched files. Avoid unrelated refactors in the same PR.

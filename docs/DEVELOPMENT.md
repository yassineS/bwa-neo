# Development workflow (Git)

**Canonical repository path:** `~/Code/bwa-neo` only. Do not maintain a parallel clone elsewhere.

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Always releasable; protected; merges via PR or reviewed merge. |
| `feat/<topic>` | Short-lived feature work (e.g. `feat/sampe-threads`, `feat/mem2-cmake`). |
| `fix/<topic>` | Bugfixes. |
| `chore/<topic>` | Tooling, CI, docs-only when no behaviour change. |

Optional later: `develop` integration branch if you add release trains; not required for a small team.

## Commits

- Write imperative subject lines: `Add samse -t for pac_pos`, not `Added`.
- One logical change per commit when practical.
- Reference issues/PRs in the body: `See #12`.

Conventional Commits (optional but recommended):

- `feat:` new behaviour
- `fix:` bugfix
- `test:` tests only
- `docs:` documentation
- `chore:` CI, build scripts, formatting
- `perf:` performance-only change

## Day-to-day

```bash
cd ~/Code/bwa-neo
git fetch origin
git checkout main
git pull origin main
git checkout -b feat/my-change
# edit, build, test
cmake --build build && ctest --test-dir build
git add -p
git commit -m "feat: describe change"
git push -u origin feat/my-change
# open PR into main
```

## First-time setup (contributors)

```bash
git clone <your-fork-url> ~/Code/bwa-neo
cd ~/Code/bwa-neo
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build
```

### If the tree has no `.git` yet (initial import)

From **`~/Code/bwa-neo`** in your system terminal:

```bash
./scripts/bootstrap-git.sh
# then commit when satisfied with `git status`
```

If `git init` fails with **Operation not permitted** on `.git/hooks`, your environment is blocking hook installation; the repo metadata may still work—try `git -c core.hooksPath=/dev/null init -b main` or upgrade your Git client.

## What not to do

- Do not commit `build/`, `*.o`, the `bwa` binary, or `third_party/bwa-mem2/` (see `.gitignore`).
- Do not keep a second working copy under `~/bwa-neo`; it was removed to avoid drift.

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
gh pr create --fill   # optional: open a PR from the CLI
```

## GitHub CLI (`gh`)

This project assumes **[GitHub CLI](https://cli.github.com/)** is installed and authenticated (`gh auth status`). Prefer `gh` over hand-pasted URLs so you avoid shell mistakes with angle brackets or wrong remotes.

**Once per machine**, wire Git’s HTTPS access to the same account as `gh` (avoids `remote: Repository not found` when `gh` works but `git push` does not):

```bash
gh auth setup-git
```

### First push to GitHub (after local commit on `main`)

From `~/Code/bwa-neo`, create the remote repo and push in one step:

```bash
gh auth setup-git   # if you have not already
gh repo create bwa-neo --public --source=. --remote=origin --push
```

Use `--private` instead of `--public` if you want a private repo. Omit the name `bwa-neo` to default to the current directory name.

### Push failed but the repo was created (`Repository not found`)

If `gh repo create … --push` created the repo on GitHub but **`git push` failed**, the remote is usually correct; fix credentials and push again:

```bash
gh auth setup-git
git remote -v
git push -u origin main
```

Do **not** run `gh repo create` again if the repository already exists—GitHub will error or require a new name. Use `gh repo view` to confirm the repo is there.

If `origin` already exists but is wrong:

```bash
git remote remove origin
gh repo create bwa-neo --public --source=. --remote=origin --push
```

If the repo **already exists** on GitHub and you only need to attach the remote:

```bash
gh repo set-default YOUR_LOGIN/bwa-neo   # optional
git remote add origin https://github.com/YOUR_LOGIN/bwa-neo.git
git push -u origin main
```

(or use `gh repo sync` / clone patterns from `gh repo --help` for your case.)

### Useful commands

| Command | Purpose |
|---------|---------|
| `gh pr create` | Open a pull request |
| `gh pr checks` | Watch CI |
| `gh workflow run` | Trigger a workflow |

## First-time setup (contributors)

```bash
gh repo clone YOUR_LOGIN/bwa-neo ~/Code/bwa-neo
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

## GitHub Wiki

Contributor-facing wiki pages are published separately from `main`. Staging copies live under [`docs/wiki-wip/`](../wiki-wip/README.md). After enabling Wikis in repository settings:

1. Install the [GitHub CLI](https://cli.github.com/) and run `gh auth login` and **`gh auth setup-git`** once per machine.

2. If the wiki git remote does not exist yet, open the wiki from **`gh`** and create a short **Home** page in the browser, then clone:

   ```bash
   gh browse --wiki yassineS/bwa-neo
   gh repo clone https://github.com/yassineS/bwa-neo.wiki.git
   cd bwa-neo.wiki
   ```

3. From the **bwa-neo** repo root, you can sync staging in one step (clone via **`gh`**, then **Git** only inside the wiki directory for commit and push):

   ```bash
   ./scripts/publish-wiki-from-staging.sh
   ```

The public index is `https://github.com/yassineS/bwa-neo/wiki`. Status and first-time notes: [`docs/wiki-wip/WIKI_PUBLISH_STATUS.md`](../wiki-wip/WIKI_PUBLISH_STATUS.md).

## What not to do

- Do not commit `build/`, `*.o`, the `bwa` binary, or `third_party/bwa-mem2/` (see `.gitignore`).
- Do not keep a second working copy under `~/bwa-neo`; it was removed to avoid drift.

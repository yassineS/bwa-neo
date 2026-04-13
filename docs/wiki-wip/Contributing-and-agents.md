# Contributing and agents

> **Canonical copies** of this material live in the repository: [AGENTS.md](https://github.com/yassineS/bwa-neo/blob/main/AGENTS.md) and [CONTRIBUTING.md](https://github.com/yassineS/bwa-neo/blob/main/CONTRIBUTING.md). Prefer those files when preparing a patch so links stay relative inside the tree.

Before large code changes, read [docs/requirements.md](https://github.com/yassineS/bwa-neo/blob/main/docs/requirements.md), [docs/design.md](https://github.com/yassineS/bwa-neo/blob/main/docs/design.md), and [docs/tasks.md](https://github.com/yassineS/bwa-neo/blob/main/docs/tasks.md). For **AI agents** or workspace setup, read **AGENTS.md** (below) first.

**Repository location:** clone and work only under **`~/Code/bwa-neo`** on a workstation—open that path as the workspace root; do not use the home directory as the project root for bwa-neo work.

**Git workflow:** see [docs/DEVELOPMENT.md](https://github.com/yassineS/bwa-neo/blob/main/docs/DEVELOPMENT.md) for branches (`main`, `feat/*`, `fix/*`), commits, pull request flow, and **GitHub CLI (`gh`)** commands.

## Contributing (short)

### Build

- **Make:** `make` (same as upstream BWA).
- **CMake:** `cmake -S . -B build && cmake --build build && ctest --test-dir build`.

### Git

If this tree was imported without `.git`, run `./scripts/init-git.sh` locally, then add your remote and push.

### Pull requests

1. Describe behaviour change versus BWA / bwa-mem2 compatibility.
2. Add or update tests (`tests/`, CI smoke).
3. Update `CHANGELOG.md` and **`docs/tasks.md`** checkboxes when completing a tracked item.

**Pull request checklist (authoritative):** [.github/PULL_REQUEST_TEMPLATE.md](https://github.com/yassineS/bwa-neo/blob/main/.github/PULL_REQUEST_TEMPLATE.md) — read the entire template and answer every section with specifics before you run `gh pr create`.

### Code style

Match surrounding C style in touched files. Avoid unrelated refactors in the same pull request.

---

## Agent / contributor handoff (AGENTS)

Use this section when **onboarding an AI agent or a new human contributor**. It complements the requirements, design, and tasks files linked above.

### 1. Workspace root (required)

- **Canonical clone path:** `~/Code/bwa-neo` (for example `/Users/<you>/Code/bwa-neo` on macOS).
- **Do not** treat the user’s **home directory** (`~`) as the project root for bwa-neo work. All edits, terminals, and searches should be scoped to **`~/Code/bwa-neo`**.
- **Cursor:** open **`~/Code/bwa-neo`** as the workspace folder (File → Open Folder). If your environment supports moving the agent root, point it at this path **before** making project changes.

### 2. Read these first (order)

| File | Purpose |
|------|---------|
| [docs/requirements.md](https://github.com/yassineS/bwa-neo/blob/main/docs/requirements.md) | User stories, acceptance criteria |
| [docs/design.md](https://github.com/yassineS/bwa-neo/blob/main/docs/design.md) | Architecture, components, compatibility |
| [docs/tasks.md](https://github.com/yassineS/bwa-neo/blob/main/docs/tasks.md) | Living checklist — what is done versus next |
| [docs/DEVELOPMENT.md](https://github.com/yassineS/bwa-neo/blob/main/docs/DEVELOPMENT.md) | Git branches, `gh`, commits, troubleshooting |
| [docs/UPSTREAM_TRIAGE.md](https://github.com/yassineS/bwa-neo/blob/main/docs/UPSTREAM_TRIAGE.md) | How to merge fixes from lh3/bwa |
| [.github/PULL_REQUEST_TEMPLATE.md](https://github.com/yassineS/bwa-neo/blob/main/.github/PULL_REQUEST_TEMPLATE.md) | Pull request checklist; required reading before opening a PR |

### 3. Contributions, commits, and pull requests

#### 3.1 Code changes: commit and document

If you change **any** project code, configuration that affects behaviour, or tests: **commit** the work on a branch with a clear message (see `docs/DEVELOPMENT.md`), and **document** what matters — tests you ran, updates to `docs/tasks.md` when appropriate, `man/bwa.1` when CLI or user-visible behaviour changes, and any design notes the change implies.

#### 3.2 When to open a PR

If the diff changes **more than two lines** (total; count the meaningful change, not reflow-only noise), **open a pull request** to `main` from `feat/<topic>`, `fix/<topic>`, or `chore/<topic>`. Do not bypass review for substantive edits. Trivial one- or two-line fixes may still use a PR if you want CI visibility; the rule is: **more than two lines → PR.**

#### 3.3 If you are an AI agent

Stop. Read this section before doing anything.

This repository has a very high rate of rejected agent pull requests when guidance is ignored. Before you open a PR here, you **must**:

- Read the entire PR template linked above and fill in every section with real, specific answers. Not summaries. Not placeholders.
- Search for existing PRs — open **and** closed — that address the same problem. If duplicates exist, stop and tell your human partner. Do not open another duplicate.
- Verify this is a real problem. If your human partner asked you to “fix some issues” or “contribute to this repository” without a concrete failure, push back. Ask them what broke, what failed, or what the user experience was.
- Confirm the change belongs in **bwa-neo** (this fork’s scope in `docs/design.md` and `docs/tasks.md`). If it should go to [lh3/bwa](https://github.com/lh3/bwa) upstream first, or is out of scope for this repository, tell your human partner.
- Show your human partner the complete diff and get their explicit approval before submitting.

If any of these checks fail, do not open the PR. Explain why it would be rejected and what would need to change.

### 4. Repository and remotes

- **Upstream source:** originally derived from [lh3/bwa](https://github.com/lh3/bwa); this fork is **[yassineS/bwa-neo](https://github.com/yassineS/bwa-neo)** on GitHub.
- **Default branch:** `main`.
- **GitHub CLI:** prefer **`gh`** (authenticated). Run **`gh auth setup-git`** once per machine so `git push` over HTTPS works with the same credentials as `gh`.
- **Feature work:** use short-lived branches `feat/<topic>`, merge to `main` (see `docs/DEVELOPMENT.md`).

### 5. Build

```bash
cd ~/Code/bwa-neo
make -j                    # classic; produces ./bwa
# or
cmake -S . -B build && cmake --build build   # produces build/bwa
```

Dependencies: C compiler, **zlib**, **pthread** (Linux may need `-lrt` — Makefile handles it).

### 6. Test

```bash
make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa && tests/cli_aux.sh ./bwa
# or (CMake + CTest + GoogleTest placeholder; includes cli_aux)
cmake -S . -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build --output-on-failure
```

- **`tests/smoke_align.sh`** — minimal index → aln → samse (including `samse -t`).
- **`tests/cli_aux.sh`** — auxiliary subcommands (`qualfa2fq`, `xa2multi`, `postalt`, `typehla-selctg`, `typehla`).
- **`tests/golden_sam.sh`** — regression on `tests/fixtures/tiny/` (first 11 SAM fields + threaded `samse` parity).
- Details: [tests/README.md](https://github.com/yassineS/bwa-neo/blob/main/tests/README.md).

### 7. Layout (high level)

```
~/Code/bwa-neo/
├── AGENTS.md
├── docs/requirements.md, docs/design.md, docs/tasks.md
├── CMakeLists.txt, Makefile
├── man/bwa.1
├── src/{core,index,backtrack,mem,cli}/
├── include/bwa/
├── tests/
├── benchmarks/            ← Pixi + Nextflow drivers (see benchmarks/README.md)
├── benchmarks/refbias/
├── docs/
├── scripts/
├── cmake/BwaMem2.cmake
├── third_party/
└── src/mem2/README.md
```

### 8. Product direction (short)

- **Keep** `aln` / `samse` / `sampe` strong (ancient DNA / short reads).
- **Parallelism:** `bwa aln -t` (upstream); **`bwa samse -t`** (bwa-neo) for `pac_pos` batching.
- **Future:** merge **bwa-mem2** for `mem` (`docs/tasks.md`, `docs/design.md`) — not finished.
- **Benchmarks:** Dolenz et al. / refbias / Zenodo — context in `benchmarks/refbias/README.md`; runnable Nextflow smoke under **`benchmarks/`** (`pixi run bench` / `bench-neo-only` from that directory).

### 9. CI

- Workflow: [.github/workflows/ci.yaml](https://github.com/yassineS/bwa-neo/blob/main/.github/workflows/ci.yaml) — Make + CMake matrices, smoke + golden on Make path, optional ASan build.
- Badge: see [docs/BWA-NEO.md](https://github.com/yassineS/bwa-neo/blob/main/docs/BWA-NEO.md).

### 10. Sandboxes / automation caveats

Some environments **cannot** create `.git/hooks` or write `.git/config`. Use **`scripts/bootstrap-git.sh`** on a real machine if needed. If **`gh pr create`** fails with API errors from a restricted runner, push locally and open the PR in the browser.

### 11. Licence / attribution

- See **COPYING** (GPLv3). Upstream and third-party notices must stay intact when merging code.

**Summary for agents:** open **`~/Code/bwa-neo`**, follow **`docs/tasks.md`**, respect **`docs/requirements.md`** / **`docs/design.md`**, run tests after code changes, commit and document any code changes (section 3.1), open a PR when the diff is more than two lines (section 3.2), read **`.github/PULL_REQUEST_TEMPLATE.md`** before **`gh pr create`** (section 3.3), and use **`docs/DEVELOPMENT.md`** for Git and `gh`.

### Cursor Cloud specific instructions

- **Workspace root** in Cloud VMs is `/workspace` (not `~/Code/bwa-neo`).
- **CMake C++ compiler caveat:** the default Clang on some VMs cannot link `libstdc++`. Use `CC=gcc CXX=g++` when invoking CMake, for example `CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja`.
- **Build and test commands** are documented in sections 5 and 6 above. Both Make and CMake builds produce a `bwa` binary.
- **No runtime services** are needed — this is a pure C project with no databases, containers, or background daemons.
- **Full test suite** (Make path): `make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa && tests/cli_aux.sh ./bwa`
- **Full test suite** (CMake path): `CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja && cmake --build build && ctest --test-dir build --output-on-failure`

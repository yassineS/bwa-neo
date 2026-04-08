# Agent / contributor handoff — bwa-neo

Use this file when **onboarding an AI agent or a new human contributor**. It complements `**requirements.md`**, `**design.md**`, and `**tasks.md**`.

## 1. Workspace root (required)

- **Canonical clone path:** `~/Code/bwa-neo` (i.e. `/Users/<you>/Code/bwa-neo` on macOS).
- **Do not** treat the user’s **home directory** (`~`) as the project root for bwa-neo work. All edits, terminals, and searches should be scoped to `**~/Code/bwa-neo`**.
- **Cursor:** open `**~/Code/bwa-neo`** as the workspace folder (File → Open Folder). If your environment supports moving the agent root, point it at this path **before** making project changes.

## 2. Read these first (order)


| File                                                 | Purpose                                          |
| ---------------------------------------------------- | ------------------------------------------------ |
| `[requirements.md](requirements.md)`                 | User stories, acceptance criteria                |
| `[design.md](design.md)`                             | Architecture, components, compatibility          |
| `[tasks.md](tasks.md)`                               | Living checklist — what is done vs next          |
| `[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)`         | Git branches, `**gh`**, commits, troubleshooting |
| `[docs/UPSTREAM_TRIAGE.md](docs/UPSTREAM_TRIAGE.md)` | How to merge fixes from lh3/bwa                  |


## 3. Repository and remotes

- **Upstream source:** originally derived from [lh3/bwa](https://github.com/lh3/bwa); this fork is **[yassineS/bwa-neo](https://github.com/yassineS/bwa-neo)** on GitHub.
- **Default branch:** `main`.
- **GitHub CLI:** prefer `**gh`** (authenticated). Run `**gh auth setup-git**` once per machine so `git push` over HTTPS works with the same credentials as `gh`.
- **Feature work:** use short-lived branches `feat/<topic>`, merge to `main` (see `docs/DEVELOPMENT.md`).

## 4. Build

```bash
cd ~/Code/bwa-neo
make -j                    # classic; produces ./bwa
# or
cmake -S . -B build && cmake --build build   # produces build/bwa
```

Dependencies: C compiler, **zlib**, **pthread** (Linux may need `-lrt` — Makefile handles it).

## 5. Test

```bash
make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa
# or (CMake + CTest + GoogleTest placeholder)
cmake -S . -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build --output-on-failure
```

- `**tests/smoke_align.sh**` — minimal index → aln → samse (incl. `samse -t`).
- `**tests/golden_sam.sh**` — regression on `**tests/fixtures/tiny/**` (first 11 SAM fields + threaded samse parity).
- Details: `[tests/README.md](tests/README.md)`.

## 6. Layout (high level)

```
~/Code/bwa-neo/
├── AGENTS.md              ← this file
├── requirements.md, design.md, tasks.md
├── CMakeLists.txt, Makefile
├── src/{core,index,backtrack,mem,cli}/ ← BWA C sources by subsystem
├── include/bwa/           ← shared/public headers
├── tests/                 ← smoke, golden, CTest, fixtures
├── benchmarks/refbias/    ← refbias / Zenodo workflow skeleton
├── docs/                  ← DEVELOPMENT, UPSTREAM_TRIAGE
├── scripts/               ← bootstrap-git, fetch-bwa-mem2
├── cmake/BwaMem2.cmake    ← optional ExternalProject for mem2
├── third_party/         ← bwa-mem2 after fetch (often gitignored; see third_party/README.md)
└── src/mem2/README.md     ← placeholder for future in-tree mem2 merge
```

## 7. Product direction (short)

- **Keep** `aln` / `samse` / `sampe` strong (ancient DNA / short reads).
- **Parallelism:** `bwa aln -t` (upstream); `**bwa samse -t`** (bwa-neo) for pac_pos batching.
- **Future:** merge **bwa-mem2** for `mem` (`tasks.md`, `design.md`) — not finished.
- **Benchmarks:** Dolenz et al. / refbias / Zenodo — context in `benchmarks/refbias/README.md`; runnable Nextflow smoke in `benchmarks/at_scale/` (`pixi run bench` / `bench-neo-only`).

## 8. CI

- Workflow: `[.github/workflows/ci.yaml](.github/workflows/ci.yaml)` — Make + CMake matrices, smoke + golden on Make path, ASan build optional.
- Badge: see `[README-BWA-NEO.md](README-BWA-NEO.md)`.

## 9. Sandboxes / automation caveats

Some environments **cannot** create `.git/hooks` or write `.git/config`. Use `**scripts/bootstrap-git.sh`** on a real machine if needed. If `**gh pr create**` fails with API errors from a restricted runner, push locally and open the PR in the browser.

## 10. License / attribution

- See `**COPYING**` (GPLv3). Upstream and third-party notices must stay intact when merging code.

---

**Summary for agents:** Open `**~/Code/bwa-neo`**, follow `**tasks.md**`, respect `**requirements.md**` / `**design.md**`, run tests after code changes, and use `**docs/DEVELOPMENT.md**` for Git and `gh`.

## Cursor Cloud specific instructions

- **Workspace root** in Cloud VMs is `/workspace` (not `~/Code/bwa-neo`).
- **CMake C++ compiler caveat:** the default Clang on this VM cannot link `libstdc++`. Use `CC=gcc CXX=g++` when invoking CMake, e.g. `CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja`.
- **Build & test commands** are documented in sections 4 and 5 above. Both Make and CMake builds produce a `bwa` binary.
- **No runtime services** are needed — this is a pure C project with no databases, containers, or background daemons.
- **Full test suite** (Make path): `make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa`
- **Full test suite** (CMake path): `CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja && cmake --build build && ctest --test-dir build --output-on-failure`
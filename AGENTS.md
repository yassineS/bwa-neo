# Agent / contributor handoff — bwa-neo

Use this file when **onboarding an AI agent or a new human contributor**. It complements `**docs/requirements.md`**, `**docs/design.md**`, and `**docs/tasks.md**`.

## 1. Workspace root (required)

- **Canonical clone path:** `~/Code/bwa-neo` (i.e. `/Users/<you>/Code/bwa-neo` on macOS).
- **Do not** treat the user’s **home directory** (`~`) as the project root for bwa-neo work. All edits, terminals, and searches should be scoped to `**~/Code/bwa-neo`**.
- **Cursor:** open `**~/Code/bwa-neo`** as the workspace folder (File → Open Folder). If your environment supports moving the agent root, point it at this path **before** making project changes.

## 2. Read these first (order)


| File                                                 | Purpose                                          |
| ---------------------------------------------------- | ------------------------------------------------ |
| `[docs/requirements.md](docs/requirements.md)`       | User stories, acceptance criteria                |
| `[docs/design.md](docs/design.md)`                   | Architecture, components, compatibility        |
| `[docs/tasks.md](docs/tasks.md)`                     | Living checklist — what is done vs next            |
| `[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)`         | Git branches, `**gh`**, commits, troubleshooting |
| `[docs/UPSTREAM_TRIAGE.md](docs/UPSTREAM_TRIAGE.md)` | How to merge fixes from lh3/bwa                  |
| `[.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)` | PR checklist; required reading before opening a PR |


## 3. Contributions, commits, and pull requests

### 3.1 Code changes: commit and document

If you change **any** project code, configuration that affects behaviour, or tests: **commit** the work on a branch with a clear message (see `docs/DEVELOPMENT.md`), and **document** what matters — tests you ran, updates to `docs/tasks.md` when appropriate, `man/bwa.1` when CLI or user-visible behaviour changes, and any design notes the change implies.

### 3.2 When to open a PR

If the diff changes **more than two lines** (total; count the meaningful change, not reflow-only noise), **open a pull request** to `main` from `feat/<topic>`, `fix/<topic>`, or `chore/<topic>`. Do not bypass review for substantive edits. Trivial one- or two-line fixes may still use a PR if you want CI visibility; the rule is: **>2 lines → PR.**

### 3.3 If you are an AI agent

Stop. Read this section before doing anything.

This repo has a 94% PR rejection rate. Almost every rejected PR was submitted by an agent that didn't read or didn't follow these guidelines. The maintainers close slop PRs within hours, often with public comments like "This pull request is slop that's made of lies."

Your job is to protect your human partner from that outcome. Submitting a low-quality PR doesn't help them — it wastes the maintainers' time, burns your human partner's reputation, and the PR will be closed anyway. That is not being helpful. That is being a tool of embarrassment.

Before you open a PR against this repo, you MUST:

- Read the entire PR template at `.github/PULL_REQUEST_TEMPLATE.md` and fill in every section with real, specific answers. Not summaries. Not placeholders.
- Search for existing PRs — open AND closed — that address the same problem. If duplicates exist, STOP and tell your human partner. Do not open another duplicate.
- Verify this is a real problem. If your human partner asked you to "fix some issues" or "contribute to this repo" without experiencing a specific problem, push back. Ask them what broke, what failed, what the user experience was.
- Confirm the change belongs in **bwa-neo** (this fork’s scope in `docs/design.md` and `docs/tasks.md`). If it should go to [lh3/bwa](https://github.com/lh3/bwa) upstream first, or is out of scope for this repository, tell your human partner.
- Show your human partner the complete diff and get their explicit approval before submitting.

If any of these checks fail, do not open the PR. Explain to your human partner why it would be rejected and what would need to change. They will thank you for saving them the embarrassment.

## 4. Repository and remotes

- **Upstream source:** originally derived from [lh3/bwa](https://github.com/lh3/bwa); this fork is **[yassineS/bwa-neo](https://github.com/yassineS/bwa-neo)** on GitHub.
- **Default branch:** `main`.
- **GitHub CLI:** prefer `**gh`** (authenticated). Run `**gh auth setup-git**` once per machine so `git push` over HTTPS works with the same credentials as `gh`.
- **Feature work:** use short-lived branches `feat/<topic>`, merge to `main` (see `docs/DEVELOPMENT.md`).

## 5. Build

```bash
cd ~/Code/bwa-neo
make -j                    # classic; produces ./bwa
# or
cmake -S . -B build && cmake --build build   # produces build/bwa
```

Dependencies: C compiler, **zlib**, **pthread** (Linux may need `-lrt` — Makefile handles it).

## 6. Test

```bash
make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa && tests/cli_aux.sh ./bwa
# or (CMake + CTest + GoogleTest placeholder; includes cli_aux)
cmake -S . -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build --output-on-failure
```

- `**tests/smoke_align.sh**` — minimal index → aln → samse (incl. `samse -t`).
- `**tests/cli_aux.sh**` — aux subcommands (`qualfa2fq`, `xa2multi`, `postalt`, `typehla-selctg`, `typehla`).
- `**tests/golden_sam.sh**` — regression on `**tests/fixtures/tiny/**` (first 11 SAM fields + threaded samse parity).
- Details: `[tests/README.md](tests/README.md)`.

## 7. Layout (high level)

```
~/Code/bwa-neo/
├── AGENTS.md              ← this file
├── docs/requirements.md, docs/design.md, docs/tasks.md
├── CMakeLists.txt, Makefile
├── man/bwa.1              ← troff man page (also installed by CMake)
├── src/{core,index,backtrack,mem,cli}/ ← BWA C sources by subsystem
├── include/bwa/           ← shared/public headers
├── tests/                 ← smoke, golden, CTest, fixtures
├── benchmarks/refbias/    ← refbias / Zenodo workflow skeleton
├── docs/                  ← requirements, design, tasks, DEVELOPMENT, UPSTREAM_TRIAGE, …
├── scripts/               ← bootstrap-git, fetch-bwa-mem2
├── cmake/BwaMem2.cmake    ← optional ExternalProject for mem2
├── third_party/         ← bwa-mem2 after fetch (often gitignored; see third_party/README.md)
└── src/mem2/README.md     ← placeholder for future in-tree mem2 merge
```

## 8. Product direction (short)

- **Keep** `aln` / `samse` / `sampe` strong (ancient DNA / short reads).
- **Parallelism:** `bwa aln -t` (upstream); `**bwa samse -t`** (bwa-neo) for pac_pos batching.
- **Future:** merge **bwa-mem2** for `mem` (`docs/tasks.md`, `docs/design.md`) — not finished.
- **Benchmarks:** Dolenz et al. / refbias / Zenodo — context in `benchmarks/refbias/README.md`; runnable Nextflow smoke in `benchmarks/at_scale/` (`pixi run bench` / `bench-neo-only`).

## 9. CI

- Workflow: `[.github/workflows/ci.yaml](.github/workflows/ci.yaml)` — Make + CMake matrices, smoke + golden on Make path, ASan build optional.
- Badge: see `[docs/BWA-NEO.md](docs/BWA-NEO.md)`.

## 10. Sandboxes / automation caveats

Some environments **cannot** create `.git/hooks` or write `.git/config`. Use `**scripts/bootstrap-git.sh`** on a real machine if needed. If `**gh pr create**` fails with API errors from a restricted runner, push locally and open the PR in the browser.

## 11. License / attribution

- See `**COPYING**` (GPLv3). Upstream and third-party notices must stay intact when merging code.

---

**Summary for agents:** Open `**~/Code/bwa-neo`**, follow `**docs/tasks.md**`, respect `**docs/requirements.md**` / `**docs/design.md**`, run tests after code changes, commit and document any code changes (section 3.1), open a PR when the diff is more than two lines (section 3.2), read `**/.github/PULL_REQUEST_TEMPLATE.md**` before `**gh pr create**` (section 3.3), and use `**docs/DEVELOPMENT.md**` for Git and `gh`.

## Cursor Cloud specific instructions

- **Workspace root** in Cloud VMs is `/workspace` (not `~/Code/bwa-neo`).
- **CMake C++ compiler caveat:** the default Clang on this VM cannot link `libstdc++`. Use `CC=gcc CXX=g++` when invoking CMake, e.g. `CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja`.
- **Build & test commands** are documented in sections 5 and 6 above. Both Make and CMake builds produce a `bwa` binary.
- **No runtime services** are needed — this is a pure C project with no databases, containers, or background daemons.
- **Full test suite** (Make path): `make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa && tests/cli_aux.sh ./bwa`
- **Full test suite** (CMake path): `CC=gcc CXX=g++ cmake -S . -B build -DBUILD_TESTING=ON -G Ninja && cmake --build build && ctest --test-dir build --output-on-failure`
# bwa-neo — Cloud agent runbook (build & test)

Use this skill when you need to **compile, run, and validate** this repository in a fresh environment (CI-like sandboxes, cloud agents, containers). It is **minimal by design**: extend it when you discover new workflows (see [Maintaining this skill](#maintaining-this-skill)).

## What this project is

- **C codebase** (BWA fork: **bwa-neo**). The shipped binary is **`bwa`** (short-read `aln` / `samse` / `sampe`, etc.).
- There is **no web app to start**, **no feature-flag service**, and **no runtime env vars** that toggle product behavior. Configuration is **CLI flags** to `bwa` subcommands (see `./bwa` help output). Do not invent env-based feature flags—document real CLI options only.

## First-time setup (any machine)

**Dependencies (Linux, matches CI):**

```bash
sudo apt-get update -q && sudo apt-get install -q -y zlib1g-dev
# CMake path also:
sudo apt-get install -q -y cmake ninja-build
```

**Optional — GitHub push/PR from a real workstation:** authenticate GitHub CLI once (`gh auth login` or your org’s method), then `gh auth setup-git` so `git push` uses the same credentials as `gh`. Cloud agents often receive credentials via the platform; use whatever `git remote -v` and `gh auth status` show in that environment.

**Workspace path:** human docs often say `~/Code/bwa-neo`; in sandboxes the repo may be mounted elsewhere (e.g. `/workspace`). Always `cd` to the **repository root** (where `Makefile` and `CMakeLists.txt` live) before building.

## Build (two supported paths)

Pick one; CI runs **both**.

### A. Make (classic — produces `./bwa` at repo root)

```bash
cd /path/to/bwa-neo
make -j
# binary: ./bwa
```

- **Compiler override:** `make CC=clang` (CI tests gcc and clang).
- **AddressSanitizer (optional):** `make asan=1` — see Makefile `asan` hook.

### B. CMake + Ninja (produces `build/bwa`)

```bash
cd /path/to/bwa-neo
cmake -S . -B build -G Ninja -DBUILD_TESTING=ON
cmake --build build
# binary: build/bwa
ctest --test-dir build --output-on-failure
```

- **ASan build (CMake):** `cmake -S . -B build-asan -G Ninja -DBWA_NEO_ENABLE_ASAN=ON -DBUILD_TESTING=OFF && cmake --build build-asan` (mirrors CI `build-asan` job).

---

## By codebase area — what to touch and how to test

### 1. `src/core/`, `src/index/`, `src/backtrack/`, `src/mem/`, `src/cli/`, `include/bwa/`

These directories hold the **library and `bwa` executable** sources.

**Validate after edits:**

1. Rebuild (Make or CMake path above).
2. Run **shell regression tests** against the binary path you built:
   - `./bwa` → use `./bwa` in commands below
   - `build/bwa` → substitute `build/bwa`

```bash
chmod +x tests/smoke_align.sh tests/golden_sam.sh tests/golden_sampe.sh
tests/smoke_align.sh ./bwa
tests/golden_sam.sh ./bwa
tests/golden_sampe.sh ./bwa
```

**What each does (quick):**

| Script | Role |
|--------|------|
| `tests/smoke_align.sh` | Tiny ref index + `aln` + `samse` (+ `samse -t` header check). |
| `tests/golden_sam.sh` | First 11 SAM fields vs `tests/fixtures/tiny/`; threaded `samse` parity. |
| `tests/golden_sampe.sh` | Paired-end `sampe` vs `tests/fixtures/tiny_pe/`. |

**CMake parity:** With `-DBUILD_TESTING=ON`, `ctest` registers `unit`, `smoke_align`, `golden_sam`, and `golden_sampe` (see `tests/CMakeLists.txt`).

**Unit test stub:** CTest target `unit` runs GoogleTest scaffold (`tests/test_unit.cpp`)—useful for small C++-side checks; most mapping behavior is covered by the golden scripts.

### 2. `tests/` — fixtures and golden expectations

- **Changing output format or alignment details** may require updating files under `tests/fixtures/` and the `expected*.tsv` files referenced in `tests/README.md`.
- **Workflow:** run `golden_sam.sh` / `golden_sampe.sh` locally after intentional SAM changes; only commit expectation updates when the new behavior is correct.

### 3. `.github/workflows/` — CI

- **CI entrypoint:** `.github/workflows/ci.yaml`.
- **Local parity:** `make -j` + the three golden/smoke scripts; and/or CMake configure with `BUILD_TESTING=ON` + `ctest`.
- **No secrets required** for the default build/test jobs (standard Ubuntu packages only).

### 4. `benchmarks/refbias/` — benchmark workflow skeleton

- **Not** part of the default `ctest` suite.
- **Quick smoke:** `cd benchmarks && pixi install && pixi run bench-neo-only` (builds bwa-neo with CMake, runs Nextflow on tiny fixtures). Full parity vs conda `bwa`: `pixi run bench`.
- Full Zenodo-scale reproduction is **manual / HPC**; see `benchmarks/refbias/README.md`.

### 5. `scripts/`, `docs/`, `third_party/`

- **scripts:** e.g. `scripts/bootstrap-git.sh` for git setup on a real machine; unrelated to compile/test loop unless you are fixing scripting.
- **docs:** orientation only unless your task is documentation.
- **third_party:** optional bwa-mem2 fetch (see `cmake/BwaMem2.cmake`, `third_party/README.md`)—not required for core `make`/`ctest` flows above.

---

## “Running the app”

There is **no long-running server**. **Smoke-run** the CLI:

```bash
./bwa 2>&1 | head -5
./bwa index   # see usage via ./bwa without args or subcommand help
```

Use the **smoke and golden scripts** as the primary end-to-end checks.

---

## Maintaining this skill

When you discover a **new reliable command**, **CI difference**, or **trap for agents**, update this file in the same PR as the change (or immediately after), and keep it **short**:

1. Add a bullet under the right **codebase area** or **Build** section.
2. Prefer **copy-pasteable commands** over prose.
3. If something applies only to cloud sandboxes (e.g. cannot run `sudo`), note the fallback (e.g. “zlib already present in image; skip apt”).
4. Remove or fix **wrong** instructions—stale runbook lines are worse than none.

**Owners:** treat this file as a living **agent runbook**, not product documentation for end users (`README`, `docs/DEVELOPMENT.md`, and `tests/README.md` remain canonical for humans).

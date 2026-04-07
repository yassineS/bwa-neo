# bwa-neo — requirements

Work directory: **`/Users/yassinesouilmi/Code/bwa-neo` only**—no second working copy (e.g. under `$HOME/bwa-neo`). Git workflow: **`docs/DEVELOPMENT.md`**. Changes follow **requirements → design → tasks** (see `design.md`, `tasks.md`).

## Product vision

A maintained fork of BWA that keeps the **`aln` / `samse` / `sampe`** pipeline relevant (ancient DNA, short reads), adds **tests and CI**, **targets useful upstream fixes**, **parallel execution** where safe, **integrates bwa-mem2** for `mem`, and ships **reproducible refbias-style benchmarks**.

## User stories and acceptance criteria

### R1 — Build and release

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R1.1 | As a user, I can build with CMake or Make. | `cmake -S . -B build && cmake --build build` produces `bwa`; `make` still works. |
| R1.2 | As a packager, I get a defined version string. | `bwa 2>&1` or `-v` reflects bwa-neo versioning (see `main.c` / CMake). |

### R2 — Correctness and compatibility

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R2.1 | As a user, single-threaded `aln`/`samse`/`sampe` matches prior BWA behaviour on fixed inputs. | Golden / smoke tests pass in CI. |
| R2.2 | As a user, `bwa mem` matches **bwa-mem2** SAM output for the same inputs (normalized), once mem2 is integrated. | Regression tests vs reference `bwa-mem2` binary. |

### R3 — Parallelism

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R3.1 | As a user, I can speed up `bwa aln` with `-t` (existing upstream). | Documented; threads ≥ 1. |
| R3.2 | As a user, I can speed up `bwa samse` coordinate conversion with `-t`. | `-t N` uses multiple threads for the SA-to-PAC position phase; default `-t 1` preserves legacy behaviour. |
| R3.3 | As a user, I get deterministic SAM order when using parallelism where documented. | Output order unchanged vs single-threaded for `samse` pac_pos phase (per-read processing independent). |

### R4 — Testing

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R4.1 | As a developer, I run unit/integration tests locally and in CI. | CTest / smoke script runs on push; optional ASan build. |

### R5 — Upstream triage

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R5.1 | As a maintainer, I track lh3/bwa issues/PRs with a written process. | `docs/UPSTREAM_TRIAGE.md` describes labels, repro, merge policy. |

### R6 — bwa-mem2 integration

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R6.1 | As a user, I can build **bwa-mem2** alongside bwa-neo from one configure step (or documented script). | CMake option or `scripts/fetch-bwa-mem2.sh` + build; `third_party/bwa-mem2` documented. |
| R6.2 | Long term: single tree routes `mem` to mem2 implementation. | Tracked in `tasks.md` (phased). |

### R7 — Refbias / performance benchmarks

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| R7.1 | As a researcher, I can reproduce a **smoke** pipeline aligned with Dolenz et al. (Bioinformatics 2024, btae436), refbias_scripts, Zenodo 14234666. | `benchmarks/refbias/README.md` + smoke script; full Zenodo runs optional/nightly. |

## Out of scope (for now)

- MPI cluster parallelism (see historical pBWA).
- Changing default alignment algorithms without tests and version bump.

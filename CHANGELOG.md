# Changelog

Single project log for **bwa-neo**. The legacy Subversion-era **`ChangeLog`** file from upstream lh3/bwa was removed to avoid maintaining two histories; for pre-fork revisions see [upstream commits](https://github.com/lh3/bwa/commits).

## Unreleased

### Changed

- **Repository layout:** planning docs moved to `docs/` (`requirements.md` → `docs/requirements.md`, etc.); fork overview → `docs/BWA-NEO.md`; upstream `NEWS.md` and `README-alt.md` → `docs/`; man page → `man/bwa.1`; `code_of_conduct.md` → `docs/CODE_OF_CONDUCT.md`. Removed duplicate upstream **`ChangeLog`** (SVN-era); use **`CHANGELOG.md`** only.

### Added

- **`AGENTS.md`**: handoff for AI agents and contributors (workspace `~/Code/bwa-neo`, read order, build/test, layout, CI, caveats). Linked from `docs/BWA-NEO.md` and `CONTRIBUTING.md`.
- **Golden SAM regression**: `tests/golden_sam.sh`, `tests/fixtures/tiny/` (mapped 32bp read; first 11 fields; `samse -t` parity). CI runs it on the Make path too.
- **`docs/BWA-NEO.md`**: CI status badge for `yassineS/bwa-neo`.
- **`docs/DEVELOPMENT.md`**: Git workflow (`main`, `feat/*`, `fix/*`), commits, first-time `git` setup, and **GitHub CLI (`gh`)** (`gh repo create … --push`, `gh auth setup-git`, troubleshooting).
- **`scripts/bootstrap-git.sh`**: initialize `main` and stage files (run locally if the agent cannot create `.git`).
- Canonical path and single-clone policy documented in `docs/requirements.md`, `CONTRIBUTING.md`, `docs/BWA-NEO.md`.
- Repository spine: `docs/requirements.md`, `docs/design.md`, `docs/tasks.md`.
- CMake build (`CMakeLists.txt`) alongside existing Makefile.
- `bwa samse -t INT`: multithreaded SA-to-PAC coordinate phase (`bwa_cal_pac_pos`) using pthreads; default remains single-threaded.
- `tests/smoke_align.sh` and CTest wiring; `tests/README.md`.
- `scripts/init-git.sh` (wrapper), `scripts/fetch-bwa-mem2.sh`, `third_party/README.md`.
- Optional CMake integration for building bwa-mem2 (`-DBWA_NEO_BUILD_BWA_MEM2=ON`).
- `benchmarks/refbias/` skeleton aligned with Dolenz et al. (Bioinformatics 2024) / refbias_scripts / Zenodo 14234666.
- Documentation: `CONTRIBUTING.md`, `SECURITY.md`, `MAINTAINERS.md`, `docs/UPSTREAM_TRIAGE.md`.

### Removed

- Stale duplicate tree previously under `~/bwa-neo` (renamed to `~/bwa-neo.duplicate-removed-20260407` for recovery); use **`~/Code/bwa-neo` only**.

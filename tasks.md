# bwa-neo — implementation checklist

## Bootstrap

- [x] **`AGENTS.md`** — pointers for agents (workspace path, build, test, Git, layout)
- [x] Import lh3/bwa sources under `~/Code/bwa-neo`
- [x] Add `requirements.md`, `design.md`, `tasks.md`
- [x] Add CMake build; keep Makefile
- [x] Add `CONTRIBUTING.md`, `SECURITY.md`, `MAINTAINERS.md`
- [x] `scripts/bootstrap-git.sh` (+ `init-git.sh` wrapper) and **`docs/DEVELOPMENT.md`** (branching, commits)
- [x] Push to GitHub (`main`); see `docs/DEVELOPMENT.md` (`gh`, `gh auth setup-git`)

## Testing and CI

- [x] Smoke test script (`tests/smoke_align.sh`)
- [x] CMake + CTest wiring for smoke / unit placeholder
- [x] GitHub Actions: extend with CMake + smoke + optional ASan
- [x] Golden SAM regression (`tests/golden_sam.sh`, `tests/fixtures/tiny/`) — first 11 fields + `samse -t` parity

## Upstream triage

- [x] Process doc `docs/UPSTREAM_TRIAGE.md`
- [ ] Curated list of merged fixes from lh3/bwa issues/PRs (ongoing)

## Parallelism

- [x] Document `bwa aln -t` (upstream)
- [x] `bwa samse -t` for `bwa_cal_pac_pos` batching
- [ ] Optional: parallel hot paths in `sampe` (larger refactor; `infer_isize` ordering constraints)

## bwa-mem2

- [x] `scripts/fetch-bwa-mem2.sh` + `third_party/README.md` (full `git clone --recursive` recommended for a working mem2 build; tarball may miss submodules)
- [x] CMake `ExternalProject` / optional target for bwa-mem2 (`-DBWA_NEO_BUILD_BWA_MEM2=ON`)
- [x] `src/mem2/README.md` placeholder for future in-tree sources
- [ ] Full merge: route `mem` to in-tree mem2 and remove duplicate `bwamem.c` (post-1.0)

## Refbias benchmarks

- [x] `benchmarks/refbias/README.md` — pointers to Dolenz et al. / Zenodo; smoke runs via **`benchmarks/at_scale`** (Pixi + Nextflow, no Makefile under `benchmarks/`)
- [x] `benchmarks/at_scale/` — Nextflow tiny-fixture pipeline: threaded `aln` + neo `samse -t`, `sampe`, optional conda-`bwa` first-11 parity, samse thread self-test, `publication_manifest.json`
- [ ] Extend Nextflow (Zenodo fetch, hyperfine, plots, simulation tracks)
- [ ] Download Zenodo 14234666 assets via scripted checksum
- [ ] Nightly full benchmark job (optional)

## Milestones (from plan)

- [x] **0.1**: Docs + CMake + smoke + CI updates + samse `-t`
- [ ] **0.2**: Upstream triage batch + more tests (golden coverage expanded)
- [ ] **1.0**: Stable parallel paths + full test suite
- [ ] **2.0**: `mem` powered by merged bwa-mem2 only

# bwa-neo — implementation checklist

## Bootstrap

- `**AGENTS.md**` — pointers for agents (workspace path, build, test, Git, layout)
- Import lh3/bwa sources under `~/Code/bwa-neo`
- Add `requirements.md`, `design.md`, `tasks.md`
- Add CMake build; keep Makefile
- Add `CONTRIBUTING.md`, `SECURITY.md`, `MAINTAINERS.md`
- `scripts/bootstrap-git.sh` (+ `init-git.sh` wrapper) and `**docs/DEVELOPMENT.md**` (branching, commits)
- Push to GitHub (`main`); see `docs/DEVELOPMENT.md` (`gh`, `gh auth setup-git`)

## Testing and CI

- Smoke test script (`tests/smoke_align.sh`)
- CMake + CTest wiring for smoke / unit placeholder
- GitHub Actions: extend with CMake + smoke + optional ASan
- Golden SAM regression (`tests/golden_sam.sh`, `tests/fixtures/tiny/`) — first 11 fields + `samse -t` parity

## Upstream triage

- Process doc `docs/UPSTREAM_TRIAGE.md`
- Curated list of merged fixes from lh3/bwa issues/PRs (ongoing)

## Parallelism

- Document `bwa aln -t` (upstream)
- `bwa samse -t` for `bwa_cal_pac_pos` batching
- `bwa sampe -t` for threaded gapped refinement + parity regression checks
- Optional: parallel `sampe` coordinate conversion / pairing hot paths (larger refactor; `infer_isize` ordering constraints)

## bwa-mem2

- `scripts/fetch-bwa-mem2.sh` + `third_party/README.md` (full `git clone --recursive` recommended for a working mem2 build; tarball may miss submodules)
- CMake `ExternalProject` / optional target for bwa-mem2 (`-DBWA_NEO_BUILD_BWA_MEM2=ON`)
- `src/mem2/README.md` placeholder for future in-tree sources
- Full merge: route `mem` to in-tree mem2 and remove duplicate `bwamem.c` (post-1.0)

## Refbias benchmarks

- `benchmarks/refbias/README.md` + `Makefile` smoke target
- Download Zenodo 14234666 assets via scripted checksum
- Nightly full benchmark job (optional)

## Milestones (from plan)

- **0.1**: Docs + CMake + smoke + CI updates + samse `-t`
- **0.2**: Upstream triage batch + more tests (golden coverage expanded)
- **1.0**: Stable parallel paths + full test suite
- **2.0**: `mem` powered by merged bwa-mem2 only
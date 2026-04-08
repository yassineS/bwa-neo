---
name: bwa-neo
description: bwa-neo workspace — BWA fork, benchmarks via Pixi+Nextflow under benchmarks/at_scale; Nextflow/Seqera guidance from official docs (no Seqera CLI required in Cursor)
---

# bwa-neo (agent skill context)

Portable skill under [Agent Skills / Seqera discovery](https://docs.seqera.io/platform-cloud/seqera-ai/skills) (`.agents/skills/`). **Do not rely on the Seqera AI CLI** in Cursor or Cursor Cloud; use this file and `.cursor/rules/seqera-ai.mdc` as instructions.

## Repository

- **Product:** lh3/bwa fork with CI, parallel `samse -t`, phased bwa-mem2 (`design.md`, `tasks.md`).
- **Library build (general):** `cmake -S . -B build && cmake --build build` → `build/bwa`, or root `Makefile`.
- **Benchmarks (self-contained):** `benchmarks/at_scale/` — **Pixi** (`pixi.toml`) provides Nextflow, JDK, baseline **bwa** (conda), and CMake toolchains; tasks build neo into `build-benchmark/bwa` and run Nextflow. **No Makefile in that folder.**
- **Tests:** `tests/smoke_align.sh`, `tests/golden_sam.sh`, `tests/golden_sampe.sh` (need a `bwa` binary path).
- **Onboarding:** `AGENTS.md`, `docs/DEVELOPMENT.md`.

## Nextflow / publication outputs

- Pipeline: `benchmarks/at_scale/nextflow/main.nf` — `index` / `aln` / `samse`, optional first-11 SAM parity vs `params.bwa_baseline`, **`publication_manifest.json`** (git SHA, inputs, parity status, tool paths).
- Cite pinned tool versions from **`pixi.lock`** and manifest JSON in methods/supplements.

## Further reading

- [Seqera AI / Skills](https://docs.seqera.io/platform-cloud/seqera-ai/skills) (discovery paths, payload limits)
- [Nextflow docs](https://www.nextflow.io/docs/latest/)

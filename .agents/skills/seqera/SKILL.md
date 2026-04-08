---
name: bwa-neo
description: bwa-neo workspace — BWA fork, aln/samse/sampe, tests, CMake/Make; aligns with Seqera AI skill discovery (see docs.seqera.io platform-cloud seqera-ai skills)
---

# bwa-neo in Seqera AI sessions

Use this when the user runs **Seqera AI** from this repository. Discovery paths are documented in [Skills — discovery directories](https://docs.seqera.io/platform-cloud/seqera-ai/skills) (project: `.agents/skills/`, `.seqera/skills/`). Keep added context under ~5 KB per skill.

## Repository facts

- **Product:** Fork of lh3/bwa with CI, tests, optional parallel `samse -t`, phased bwa-mem2 integration (`design.md`, `tasks.md`).
- **Build:** `make -j` → `./bwa`; or `cmake -S . -B build && cmake --build build` → `build/bwa`.
- **Tests:** `tests/smoke_align.sh ./bwa`, `tests/golden_sam.sh ./bwa`, `tests/golden_sampe.sh ./bwa`.
- **Entrypoints:** `src/cli/main.c`; classic pipeline in `src/backtrack/`; `mem` in `src/mem/`.
- **Contributor onboarding:** `AGENTS.md`, `docs/DEVELOPMENT.md`.

## Nextflow / Seqera Platform

For pipeline and platform help, follow current **Nextflow** and **Seqera** best practices and built-in CLI skills (e.g. `/nextflow-config`, `/nf-pipeline-structure`) from [Seqera AI skills](https://docs.seqera.io/platform-cloud/seqera-ai/skills). Any Nextflow under `benchmarks/` is experimental until wired in `tasks.md`.

## Cursor (no local CLI)

Contributors using **Cursor** or **Cursor Cloud** may not have `seqera` installed. Workspace guidance for the IDE lives in `.cursor/rules/seqera-ai.mdc` and does not require shell access to the Seqera CLI.

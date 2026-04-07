# Upstream triage (lh3/bwa)

Process for incorporating fixes and ideas from [lh3/bwa](https://github.com/lh3/bwa) issues and pull requests.

## Labels (recommended)

| Label | Meaning |
|-------|---------|
| `repro-needed` | Awaiting minimal FASTA/FASTQ + CLI to reproduce |
| `portability` | macOS, ARM, compiler flags |
| `correctness` | Wrong alignment, crashes, buffer issues |
| `performance` | Speed / memory (often needs profiling) |
| `wont-merge` | Out of scope for bwa-neo |

## Workflow

1. **Reproduce** on bwa-neo `master` with the same inputs.
2. **Add a test** (smoke, golden SAM, or unit) that fails before the fix.
3. **Cherry-pick or reimplement** the patch; keep commits focused.
4. **CHANGELOG** entry crediting the original author and linking the upstream issue/PR.

## Candidates to watch

- Open PRs touching **Makefile**, **buffer sizes**, **ARM NEON**, or **warnings-as-errors**.
- Issues about **incorrect CIGAR**, **index edge cases**, or **threading**.

Re-run this audit periodically; track merged items in **`tasks.md`**.

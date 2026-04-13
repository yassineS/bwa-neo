# Reference-bias and `bwa aln` performance benchmarks

This directory holds **design notes** and pointers to workflows that reproduce analyses aligned with:

- [refbias_scripts](https://github.com/sdolenz/refbias_scripts)
- Dolenz et al., *Bioinformatics* (2024), [btae436](https://doi.org/10.1093/bioinformatics/btae436)
- Zenodo record [14234666](https://zenodo.org/records/14234666)

Executable smoke / publication-style checks live under **`benchmarks/`** (Nextflow + Pixi; no Makefile under `benchmarks/`).

## Goals

- Measure **reference bias** and **read-length** effects when mapping with **`bwa aln`** (and pairing steps), not only wall-clock time.
- Record **runtime** (user/system/elapsed), **peak RSS**, and throughput where relevant.

## Smoke / parity (CI-friendly)

From **`benchmarks/`** (builds bwa-neo via CMake, runs Nextflow on tiny fixtures):

```bash
cd benchmarks
pixi install
pixi run bench-neo-only    # neo only, fast
# or full parity vs conda bwa + manifest:
pixi run bench
```

See [`benchmarks/README.md`](../README.md) for outputs and profiles.

## Full reproduction

1. Download Zenodo **14234666** artifacts (or follow `refbias_scripts` to regenerate).
2. Pin **reference genome** versions and **bwa-neo** git SHA in your lab notes.
3. Extend the **Nextflow** workflow in `benchmarks/nextflow/` for Zenodo-scale data; cite Dolenz et al. (2024) and note any parameter deviations.

## Metrics (suggested)

- Per-read-length mismatch or bias statistics (as defined in the paper / AMBER if used).
- `bwa aln` and `sampe`/`samse` timings separately.
- Index build time (one-off) vs alignment time.

## CI tiers

| Tier | When | Purpose |
|------|------|---------|
| Smoke | Every push / optional CI | Minutes; tiny FASTQ via Nextflow (`pixi run bench` or `bench-neo-only`) |
| Nightly / manual | HPC workstation | Full Zenodo-scale |

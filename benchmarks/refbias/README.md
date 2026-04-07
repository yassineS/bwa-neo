# Reference-bias and `bwa aln` performance benchmarks

This directory holds workflows to reproduce analyses aligned with:

- [refbias_scripts](https://github.com/sdolenz/refbias_scripts)
- Dolenz et al., *Bioinformatics* (2024), [btae436](https://doi.org/10.1093/bioinformatics/btae436)
- Zenodo record [14234666](https://zenodo.org/records/14234666)

## Goals

- Measure **reference bias** and **read-length** effects when mapping with **`bwa aln`** (and pairing steps), not only wall-clock time.
- Record **runtime** (user/system/elapsed), **peak RSS**, and throughput where relevant.

## Smoke test (CI-friendly)

From the repo root:

```bash
make -j
make -C benchmarks/refbias smoke
```

This runs a minimal pipeline (see `Makefile`) that only checks tooling and can be extended to download Zenodo assets with checksums.

## Full reproduction

1. Download Zenodo **14234666** artifacts (or follow `refbias_scripts` to regenerate).
2. Pin **reference genome** versions and **bwa-neo** git SHA in your lab notes.
3. Run the Snakemake / Makefile pipeline you maintain here; cite Dolenz et al. (2024) and note any parameter deviations.

## Metrics (suggested)

- Per-read-length mismatch or bias statistics (as defined in the paper / AMBER if used).
- `bwa aln` and `sampe`/`samse` timings separately.
- Index build time (one-off) vs alignment time.

## CI tiers

| Tier | When | Purpose |
|------|------|---------|
| Smoke | Every push | Seconds; validates scripts run |
| Nightly / manual | HPC workstation | Full Zenodo-scale |

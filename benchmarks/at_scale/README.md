# At-scale correctness and performance validation (bwa-neo)

This directory specifies **self-contained**, **reproducible** benchmarks comparing **bwa-neo** to reference builds (upstream **lh3/bwa**, **bwa-mem2**) using a **Nextflow** driver, fixed seeds where randomness exists, and **publication-quality** tables and figures.

## Scope

| Layer | Correctness goal | Performance goal |
|-------|------------------|-------------------|
| **aln → samse** | SAM parity vs baseline BWA (same index, same reads, same CLI flags) | Wall time, CPU user time, peak RSS, reads/sec |
| **aln → sampe** | Same | Same |
| **mem** (legacy in-tree) | SAM parity vs lh3/bwa `mem` | Same |
| **mem** (bwa-mem2 binary) | SAM parity vs vendored **bwa-mem2** (separate index type) | Same |

CI keeps **tiny** fixtures (`tests/fixtures/tiny/`). This workflow targets **scale** (full chromosomes or Zenodo refbias assets).

## Reproducibility: seeds and determinism

bwa-neo inherits upstream behavior:

- **Reference index**: `bns->seed` is set to **11** and `srand48` is called when loading the index (`src/index/bntseq.c`, `src/backtrack/bwase.c`, `src/backtrack/bwape.c`). Parity tests must use the **same reference FASTA** and **same index build** for both binaries.
- **Tie-breaking**: `drand48()` is used in `samse` / `sampe` paths for random hit selection. Fixed `srand48` from the index seed makes single-threaded runs repeatable.
- **Threads**: For **bit-identical** SAM, use **`-t 1`** on `aln`, `samse`, and `sampe` unless you explicitly test threaded `samse` (already covered in-repo by `tests/golden_sam.sh` for tiny data). For performance, report thread counts explicitly.

If a code path ever introduces new RNG use without a fixed seed, the benchmark should fail a **determinism check** (two consecutive runs must match).

## Data sources (download in-pipeline)

| Dataset | Role | Acquisition |
|---------|------|----------------|
| **Zenodo 14234666** | Refbias / `aln` stress, publication alignment | HTTP download + SHA256 pin (see `benchmarks/refbias/README.md`) |
| **Reference FASTA** | Shared index for parity | Explicit URL + version (e.g. GRCh38 primary assembly) + `.fai` from same build |
| **Reads** | WGS or exome subset | ENA/SRA or Zenodo; record accession and checksum |

Nextflow `params` should expose: `ref_url`, `reads_url` (or local paths), `zenodo_record`, and `checksums_file` for audit.

## Correctness pipeline (Nextflow processes)

1. **FETCH** — Download artifacts; verify checksums; emit provenance JSON (URLs, SHA256, git SHAs of `bwa-neo`, baseline BWA, bwa-mem2).
2. **BUILD_INDEX** — Run `bwa index` (classic) for **aln/samse/sampe**; run **bwa-mem2** index for mem2 comparisons (never mix index types).
3. **RUN_BASELINE** / **RUN_NEO** — Same command lines except binary path; capture stdout SAM, stderr, `/usr/bin/time -v` or equivalent for max RSS.
4. **NORMALIZE_SAM** — Sort by QNAME (or coordinate, depending on test contract); optionally strip volatile fields (e.g. some PG/MM lines) if comparing across versions; **default**: compare primary alignment fields + SEQ + QUAL + MAPQ + CIGAR + RNEXT/PNEXT for PE.
5. **DIFF** — `diff` or `cmp` on normalized streams; optional **allow-list** for known header differences (PG, `@SQ` order if ref identical).
6. **REPORT** — Pass/fail per algorithm; diff size; first mismatch line.

## Performance pipeline

- Use **hyperfine** (multiple runs, warmup) or **GNU time** with repeated trials; record mean, stdev, min, max.
- Normalize by **read count** and **total bases** for throughput.
- Compare: **neo vs lh3/bwa** for aln+samse and aln+sampe; **neo mem vs lh3 mem**; **neo routed to mem2 vs third_party bwa-mem2** (when enabled).
- Store raw TSV: `tool`, `command`, `threads`, `elapsed_s`, `max_rss_kb`, `reads`, `bases`.

## Plotting (publication quality)

- **Language**: R (`ggplot2`) or Python (`matplotlib` + `scienceplots` / journal stylesheet).
- **Figures**: (1) runtime bar chart with error bars by pipeline; (2) speedup ratio vs baseline; (3) optional accuracy/refbias metrics if Zenodo pipeline extended.
- **Style**: Vector output (PDF/SVG), named colorblind-safe palette, font sizes for two-column print (~8–9 pt).

Scripts should live under `benchmarks/at_scale/plot/` and read only generated TSV/CSV.

## Running (once Nextflow workflow is implemented)

```bash
cd benchmarks/at_scale/nextflow
nextflow run main.nf \
  -profile docker \
  --outdir results \
  --bwa_neo /path/to/bwa-neo/bwa \
  --bwa_baseline /path/to/lh3-bwa/bwa \
  --bwa_mem2 /path/to/bwa-mem2/bwa-mem2
```

Profiles: `standard` (local), `slurm` or `awsbatch` for HPC/cloud.

## Tiers

| Tier | When | Duration |
|------|------|----------|
| Smoke | CI optional | Minutes; tiny FASTQ |
| Full | Manual / release | Hours; Zenodo-scale |

## Related

- `benchmarks/refbias/` — Makefile smoke and Zenodo pointer
- `tests/golden_sam.sh` — small deterministic SAM check

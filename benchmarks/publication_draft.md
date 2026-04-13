# bwa-neo publication draft (benchmark smoke, tiny fixtures)

## Run summary

- Date (UTC manifest): 2026-04-08T06:57:01.350271Z
- Driver: Nextflow (`nextflow/main.nf`) with `standard,publication` profile
- Command: `cd benchmarks && pixi run bench`
- Binaries:
  - bwa-neo: `build-benchmark/bwa`
  - baseline bwa (conda): `.pixi/envs/default/bin/bwa`
- Threads:
  - `aln`: 4
  - `samse`: 4 for bwa-neo (`samse -t`), omitted for baseline bwa
  - `sampe`: no thread flag (threading comes from `aln -t`)

## Data

- Single-end fixture:
  - Reference: `tests/fixtures/tiny/ref.fa`
  - Reads: `tests/fixtures/tiny/reads.fq`
- Paired-end fixture:
  - Reference: `tests/fixtures/tiny_pe/ref.fa`
  - Reads: `tests/fixtures/tiny_pe/r1.fq`, `tests/fixtures/tiny_pe/r2.fq`

## Correctness results

All checks passed.


| Check                                     | Result | Evidence                                                     |
| ----------------------------------------- | ------ | ------------------------------------------------------------ |
| SE parity (first 11 SAM fields)           | PASS   | `nextflow/results_publication/parity/parity_se.ok`           |
| PE parity (first 11 SAM fields)           | PASS   | `nextflow/results_publication/parity/parity_pe.ok`           |
| `samse -t` self-parity (`-t 1` vs `-t 4`) | PASS   | `nextflow/results_publication/parity/samse_thread_parity.ok` |


Observed record counts from generated SAMs:


| Output                     | Alignments |
| -------------------------- | ---------- |
| `se/neo/neo.sam`           | 1          |
| `se/baseline/baseline.sam` | 1          |
| `pe/neo/neo.sam`           | 2          |
| `pe/baseline/baseline.sam` | 2          |


## Publication-ready wording (results)

On deterministic tiny-fixture smoke benchmarks, bwa-neo matched baseline bwa on first-11 SAM-field parity for both single-end and paired-end paths. In addition, bwa-neo preserved first-11 parity for `samse` between `-t 1` and `-t 4` under the same test fixture and reference, supporting thread-safe behavior for the tested output contract.

## Limitations of this run

- This run validates correctness-oriented parity only; it does **not** emit timing/RSS TSV artifacts.
- The current `nextflow/main.nf` benchmark processes generate SAM outputs and parity checks, but no `hyperfine` or `/usr/bin/time` summary table is published in `results_publication`.
- Dataset is smoke-scale (tiny fixtures), suitable for CI-style correctness checks but not publication-grade performance claims.

## Required before final manuscript submission

1. Extend `nextflow/main.nf` to emit per-run performance TSV (`elapsed_s`, `max_rss_kb`, read/bases throughput) for neo and baseline.
2. Run benchmark tiers on larger datasets (e.g., Zenodo/refbias or representative chromosome-scale subsets) with repeated trials.
3. Generate publication plots (runtime, speedup, memory) from raw TSVs; figures land under each run `--outdir` (e.g. `nextflow/results_publication_local/plot/`).
4. Record binary provenance robustly (version strings, git SHA, compiler flags) because current `*_versions.txt` files are empty in this run.
5. Re-run with clean output directory and archive manifest + raw results as supplemental material.
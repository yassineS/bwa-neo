# Using bwa-neo (the `bwa` program)

This document describes **how to run the `bwa` executable** produced by this tree. For build instructions, see [`AGENTS.md`](../AGENTS.md) or [`docs/DEVELOPMENT.md`](DEVELOPMENT.md). For the full option reference, read the manual page [`man/bwa.1`](../man/bwa.1) in the repository or run `man ./man/bwa.1` from your checkout.

**Burrows–Wheeler aligner (BWA)** maps DNA sequencing reads to a reference genome. The same binary exposes several **subcommands**; you choose a pipeline based on read length and algorithm.

## Choosing an algorithm (short guide)

| Situation | Typical command | Notes |
|-----------|-----------------|--------|
| Illumina reads ~70–250 bp, general purpose | `bwa mem` | Usually the default choice today for short reads. |
| Very short reads (e.g. ≤100 bp), legacy or ancient DNA style pipelines | `bwa aln` → `bwa samse` or `bwa sampe` | Backtracking; two-step (SAI then SAM). |
| Long reads (older BWA-SW path) | `bwa bwasw` | For many long-read workflows, upstream recommends **minimap2** instead. |
| PacBio / Oxford Nanopore | Prefer **minimap2** | See upstream README in this repo. |

For citations and background, see the **Citing BWA** section in [`README.md`](../README.md).

## Build the binary

```bash
make -j          # produces ./bwa
# or: cmake -S . -B build && cmake --build build   # produces build/bwa
```

Use `./bwa` or `build/bwa` below according to how you built.

## Reference index (`bwa index`)

Every algorithm needs an FM index built from your reference FASTA:

```bash
./bwa index ref.fa
```

This creates `ref.fa.bwt`, `ref.fa.pac`, `ref.fa.sa`, and related files. Use the same path **prefix** you passed to `index` as the “database” argument for alignment commands (often `ref.fa`).

## BWA-MEM (`bwa mem`) — single- and paired-end

**Single-end:**

```bash
./bwa mem ref.fa reads.fq > aln-se.sam
```

**Paired-end:**

```bash
./bwa mem ref.fa read1.fq read2.fq > aln-pe.sam
```

Common options (see the manual page for the full list):

- **`-t INT`** — thread count for alignment.
- **`-R`** — read group line for the SAM header.

Compressed FASTQ (`.gz`) is supported.

## Backtracking pipeline (`aln` → `samse` / `sampe`)

Used for short reads where you want the original BWA-backtrack behaviour.

1. **Align to produce SAI (binary alignment index):**

   ```bash
   ./bwa aln ref.fa reads.fq > reads.sai
   ```

   Use **`bwa aln -t N`** for multithreaded alignment (upstream).

2. **Convert SAI + reads to SAM:**

   **Single-end:**

   ```bash
   ./bwa samse ref.fa reads.sai reads.fq > aln-se.sam
   ```

   **Paired-end** (two SAI files):

   ```bash
   ./bwa aln ref.fa read1.fq > r1.sai
   ./bwa aln ref.fa read2.fq > r2.sai
   ./bwa sampe ref.fa r1.sai r2.sai read1.fq read2.fq > aln-pe.sam
   ```

### bwa-neo: parallel `samse` (`-t`)

This fork adds **`-t N`** to **`bwa samse`** so coordinate conversion can use multiple POSIX threads (default is effectively single-threaded behaviour when `N` is 1). Example:

```bash
./bwa samse -t 4 ref.fa reads.sai reads.fq > aln-se.sam
```

**`-f FILE`** may be used to write SAM to a file instead of stdout (see `bwa samse --` usage in the source or [`man/bwa.1`](../man/bwa.1)).

Compatibility: for a fixed index and input order, **`samse` output should match the logical alignments of single-threaded `samse`**; see [`docs/design.md`](design.md).

## Other subcommands

The binary also implements helpers and older entry points, for example:

- **`bwa bwasw`** — BWA-SW alignment.
- **`bwa fastmap`** — index / query for the `fastmap` workflow.
- Auxiliary tools such as **`qualfa2fq`**, **`xa2multi`**, **`postalt`**, and type-HLA helpers — see [`tests/cli_aux.sh`](../tests/cli_aux.sh) and the manual page.

Run `./bwa` with no arguments or check the manual page for a full list.

## Manual page

After building, from the repository root:

```bash
man ./man/bwa.1
```

Install paths may also place `bwa.1` in your manual path if you install via CMake with the usual `CMAKE_INSTALL_PREFIX`.

## See also

- [`README.md`](../README.md) — upstream introduction, FAQs, and links.
- [`docs/BWA-NEO.md`](BWA-NEO.md) — what is specific to this fork.
- [`docs/design.md`](design.md) — architecture and compatibility notes.

# Usage and features

This page summarises how to run **bwa-neo**’s `bwa` binary. Authoritative detail lives in the repository: [docs/USAGE.md](https://github.com/yassineS/bwa-neo/blob/main/docs/USAGE.md) and the manual page [man/bwa.1](https://github.com/yassineS/bwa-neo/blob/main/man/bwa.1).

## What you get

One executable, **`bwa`**, with subcommands for indexing, **BWA-MEM** (`mem`), **backtracking** (`aln`, `samse`, `sampe`), **BWA-SW** (`bwasw`), and other helpers. Choose the pipeline based on read type and lab practice; for short Illumina reads, **`bwa mem`** is usually the right starting point.

## Minimal examples

**Index a reference:**

```bash
bwa index ref.fa
```

**Align with BWA-MEM (paired-end):**

```bash
bwa mem ref.fa read1.fq read2.fq > aln-pe.sam
```

**Backtracking (single-end):**

```bash
bwa aln ref.fa reads.fq > reads.sai
bwa samse ref.fa reads.sai reads.fq > aln-se.sam
```

## bwa-neo feature: parallel `samse`

This fork adds **`-t N`** to **`bwa samse`** so the SAM conversion step can use multiple threads (POSIX threads). Example:

```bash
bwa samse -t 4 ref.fa reads.sai reads.fq > aln-se.sam
```

Optional **`-f FILE`** writes SAM to a file instead of stdout. Compatibility expectations for threaded `samse` are described in [docs/design.md](https://github.com/yassineS/bwa-neo/blob/main/docs/design.md).

## Read more

- Full user guide: [docs/USAGE.md](https://github.com/yassineS/bwa-neo/blob/main/docs/USAGE.md)
- Upstream introduction and FAQs: [README.md](https://github.com/yassineS/bwa-neo/blob/main/README.md)

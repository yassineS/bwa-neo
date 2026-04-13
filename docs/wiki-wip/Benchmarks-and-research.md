# Benchmarks and research

bwa-neo carries **design-first** benchmark material alongside runnable **Pixi + Nextflow** drivers under the top-level [`benchmarks/`](https://github.com/yassineS/bwa-neo/tree/main/benchmarks) directory (there is **no** Makefile there; use Pixi tasks).

## At-scale correctness and performance

Start with [benchmarks/README.md](https://github.com/yassineS/bwa-neo/blob/main/benchmarks/README.md). Typical entry points from `benchmarks/`:

```bash
cd benchmarks
pixi install
pixi run bench-neo-only   # fast neo-only smoke
pixi run bench            # adds baseline parity paths where configured
```

The repository root is one level above `benchmarks/`; Pixi tasks resolve `REPO_ROOT` accordingly.

## Reference bias and Zenodo context

Background, citations, and Zenodo record pointers: [benchmarks/refbias/README.md](https://github.com/yassineS/bwa-neo/blob/main/benchmarks/refbias/README.md) — note some older prose in that file still mentions a separate `benchmarks/at_scale/` tree; the **live** workflow files live under [`benchmarks/nextflow/`](https://github.com/yassineS/bwa-neo/tree/main/benchmarks/nextflow) and [`benchmarks/pixi.toml`](https://github.com/yassineS/bwa-neo/blob/main/benchmarks/pixi.toml).

## Publication draft

Working publication notes: [benchmarks/publication_draft.md](https://github.com/yassineS/bwa-neo/blob/main/benchmarks/publication_draft.md).

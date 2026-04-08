# bwa-neo

[![CI](https://github.com/yassineS/bwa-neo/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/yassineS/bwa-neo/actions/workflows/ci.yaml)

**Use a single clone:** `~/Code/bwa-neo` is the canonical working tree for this fork. Open that folder as the **Cursor / IDE workspace root** (not `~`). **Agent handoff:** see **[`AGENTS.md`](../AGENTS.md)** for pointers, layout, build/test, and GitHub. See [`DEVELOPMENT.md`](DEVELOPMENT.md) for Git branching and commits.

This tree is the **bwa-neo** fork layout (see `requirements.md`, `design.md`, `tasks.md` in this `docs/` folder).

It is primarily an **agentic-programming experiment** to refactor BWA, speed up and
parallelize `bwa aln` and `samse`/`sampe`, and progressively uniformize the code
organization between BWA-MEM and bwa-mem2.

For production workflows, prefer the original upstream tools (`lh3/bwa` and
`bwa-mem2`) and treat this fork as experimental unless you are intentionally
evaluating these changes.

**Quick start**

```bash
make -j
# or
cmake -S . -B build && cmake --build build && ctest --test-dir build
```

**Documentation spine**

- [`requirements.md`](requirements.md) — user stories and acceptance criteria
- [`design.md`](design.md) — architecture and components
- [`tasks.md`](tasks.md) — checklist

**Changes in this fork (summary)**

- CMake + GoogleTest scaffold; smoke alignment test.
- `bwa samse -t N` — parallel coordinate conversion (pthread).
- Optional bwa-mem2: `scripts/fetch-bwa-mem2.sh` (prefer full `git clone --recursive` of bwa-mem2 for a complete build).
- `benchmarks/refbias/` — reference-bias / Zenodo context; **`benchmarks/at_scale/`** — Pixi + Nextflow smoke and parity (no Makefile under `benchmarks/`).

The original upstream README content remains in `README.md`.

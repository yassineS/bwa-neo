# bwa-neo

[![CI](https://github.com/yassineS/bwa-neo/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/yassineS/bwa-neo/actions/workflows/ci.yaml)

**Use a single clone:** `~/Code/bwa-neo` is the canonical working tree for this fork. See `docs/DEVELOPMENT.md` for Git branching and commits.

This tree is the **bwa-neo** fork layout (see `requirements.md`, `design.md`, `tasks.md`).

**Quick start**

```bash
make -j
# or
cmake -S . -B build && cmake --build build && ctest --test-dir build
```

**Documentation spine**

- `requirements.md` — user stories and acceptance criteria  
- `design.md` — architecture and components  
- `tasks.md` — checklist  

**Changes in this fork (summary)**

- CMake + GoogleTest scaffold; smoke alignment test.
- `bwa samse -t N` — parallel coordinate conversion (pthread).
- Optional bwa-mem2: `scripts/fetch-bwa-mem2.sh` (prefer full `git clone --recursive` of bwa-mem2 for a complete build).
- `benchmarks/refbias/` — reference-bias / performance workflow skeleton.

The original upstream README content remains in `README.md`.

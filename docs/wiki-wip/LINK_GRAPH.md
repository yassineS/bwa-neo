# Internal documentation link graph (T2)

Sources: [README.md](../../README.md) (first fork-relevant lines and doc links), [docs/BWA-NEO.md](../BWA-NEO.md).

## Links from README.md (fork-relevant)

| Link target | Exists in tree | Notes |
|-------------|----------------|-------|
| `docs/BWA-NEO.md` | Yes | Valid relative from repo root. |
| `man/bwa.1` | Yes | Valid. |

Upstream README also references `lh3/bwa` clone URLs and external sites; those are out of scope for in-repo path checks.

## Links from docs/BWA-NEO.md

| Link target | Exists in tree | Notes |
|-------------|----------------|-------|
| `../AGENTS.md` | Yes | Resolves to `AGENTS.md` from `docs/`. |
| `DEVELOPMENT.md` | Yes | Same directory. |
| `requirements.md` | Yes | |
| `design.md` | Yes | |
| `tasks.md` | Yes | |

## Text references (not markdown links) flagged

| Reference | Status | Notes |
|-----------|--------|-------|
| `benchmarks/at_scale/` in BWA-NEO.md § “Changes in this fork” | **Mismatch** | There is no `benchmarks/at_scale/` directory on `main` in this tree. Benchmark drivers live under [`benchmarks/`](../benchmarks/README.md) (`pixi.toml`, `nextflow/`, etc.). |
| `benchmarks/at_scale/` in AGENTS.md §7 layout and §8 | **Mismatch** | Same; layout diagram omits top-level `benchmarks/nextflow` and points at a non-existent `at_scale` folder. |
| [`benchmarks/refbias/README.md`](../benchmarks/refbias/README.md) → `../at_scale/README.md` | **Broken** | Relative link from `refbias/` to `benchmarks/at_scale/README.md` — target file missing. Instructions say `cd benchmarks/at_scale`; should be `cd benchmarks` per [`benchmarks/README.md`](../benchmarks/README.md). |
| [`docs/tasks.md`](../tasks.md) checklist “benchmarks/at_scale/” | **Mismatch** | Tasks still describe `at_scale` as a directory; implementation is consolidated under `benchmarks/`. |

## Consistency note (for gap review)

- [README.md](../../README.md) badges point at **lh3/bwa** CI; [docs/BWA-NEO.md](../BWA-NEO.md) badges point at **yassineS/bwa-neo** CI. That is intentional (upstream body vs fork header) but can confuse newcomers — the wiki Home page calls this out.

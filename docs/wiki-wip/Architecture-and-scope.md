# Architecture and scope

This page is a **short orientation**. The full specifications live in the repository on the `main` branch.

## Product shape

- **Backtracking pipeline** (`index`, `aln`, `samse`, `sampe`) remains a first-class focus, including ancient DNA style short reads.
- **Parallelism:** upstream-style `bwa aln -t`, plus **bwa-neo** `bwa samse -t` for batched `pac_pos` work.
- **`mem` path:** legacy in-tree code today; **bwa-mem2** integration is staged via optional fetch under `third_party/` (see design and tasks).

## Read next (full text on GitHub)

| Document | Contents |
|----------|----------|
| [docs/requirements.md](https://github.com/yassineS/bwa-neo/blob/main/docs/requirements.md) | User stories and acceptance criteria |
| [docs/design.md](https://github.com/yassineS/bwa-neo/blob/main/docs/design.md) | Component map, data models, compatibility and thread-safety notes |
| [docs/tasks.md](https://github.com/yassineS/bwa-neo/blob/main/docs/tasks.md) | Checklist of delivered and planned work |

## Upstream merges

For how to bring selective fixes from lh3/bwa into this fork, see [docs/UPSTREAM_TRIAGE.md](https://github.com/yassineS/bwa-neo/blob/main/docs/UPSTREAM_TRIAGE.md).

# Documentation gap report (T12)

Inputs: [inventory.json](inventory.json), staged wiki pages under this directory, [docs/tasks.md](../tasks.md), and a fresh read of benchmark and design docs.

---

## 1. Missing or inconsistent

| Issue | Detail |
|--------|--------|
| **`benchmarks/at_scale/`** | **Resolved in-tree:** [benchmarks/refbias/README.md](../../benchmarks/refbias/README.md) and [docs/tasks.md](../tasks.md) now point at **`benchmarks/`** and `benchmarks/nextflow/`. Remaining mentions elsewhere (if any) should be cleaned up with `rg at_scale`. |
| **Licence wording** | **Resolved in-tree:** [docs/design.md](../design.md) § Licence now states GPLv3 via **`COPYING`** and preserves bwa-mem2 note. |
| **README badges vs fork** | [README.md](../../README.md) shows **lh3/bwa** CI badges in the banner; [docs/BWA-NEO.md](../BWA-NEO.md) shows **yassineS/bwa-neo** CI. Intentional split (upstream body vs fork pointer) but easy to misread—Home wiki page already explains; could add one line to README fork note. |
| **GitHub `main` vs wiki links** | Wiki pages use **`/blob/main/`** URLs. Until merged, some links **404** on the live site (see [LINK_CHECK_RESULTS.md](LINK_CHECK_RESULTS.md)). |

---

## 2. Not surfaced in the wiki (Part A inventory)

These are **repo-only by choice** unless you expand the hybrid wiki:

| Path | Suggested disposition |
|------|-------------------------|
| [docs/README-alt.md](../README-alt.md) | Repo-only is fine; link from [docs/BWA-NEO.md](../BWA-NEO.md) if it becomes canonical. |
| [docs/NEWS.md](../NEWS.md) | Linked from **Security, licence, and conduct** wiki page. |
| [docs/CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) | Linked from same wiki page. |
| [docs/UPSTREAM_TRIAGE.md](../UPSTREAM_TRIAGE.md) | Linked from **Architecture and scope** and **Contributing and agents**. |
| [bwakit/README.md](../../bwakit/README.md) | Repo-only unless you add a short “Packaging / bwakit” wiki bullet. |
| [src/mem2/README.md](../../src/mem2/README.md) | Repo-only; specialist. |
| [third_party/README.md](../../third_party/README.md) | Repo-only; contributor-facing. |
| [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md) | Linked from **Contributing and agents**; not duplicated in wiki (by design). |
| [.cursor/skills/bwa-neo-cloud-runbook.md](../../.cursor/skills/bwa-neo-cloud-runbook.md) | **Intentionally repo-only** (IDE-scoped). |
| [CHANGELOG.md](../../CHANGELOG.md), [MAINTAINERS.md](../../MAINTAINERS.md) | Linked from **Security, licence, and conduct**. |
| [scripts/publish-wiki-from-staging.sh](../../scripts/publish-wiki-from-staging.sh) | New helper; mention in [docs/DEVELOPMENT.md](../DEVELOPMENT.md) / [README](README.md) here only—no separate wiki page required. |

---

## 3. User-facing holes

| Topic | Gap |
|--------|-----|
| **Install packages** | No first-party conda/Docker/Homebrew recipe in-repo; README points at upstream/BioConda generically. |
| **“Which binary do I run?”** | Partially addressed by [docs/USAGE.md](../USAGE.md) and wiki **Usage and features**; still no single “5-minute install from release tarball” if you add releases later. |
| **Fork vs upstream table** | Wiki **Home** gives narrative; a small comparison table (maintained in `docs/USAGE.md` or BWA-NEO) would help new visitors. |
| **sampe threading** | [docs/tasks.md](../tasks.md) notes optional future `sampe` parallelism; user docs do not need to promise it. |

---

## 4. Recommended next actions (prioritised)

| Priority | Task |
|----------|------|
| **P1** | Merge pending **`main`** updates so wiki **`/blob/main/`** links for USAGE, benchmarks README, PR template, and `benchmarks/nextflow` return **200**; re-run [LINK_CHECK_RESULTS.md](LINK_CHECK_RESULTS.md). |
| **P1** | Complete **T10**: seed wiki (`gh browse --wiki yassineS/bwa-neo`), then `./scripts/publish-wiki-from-staging.sh`. |
| **P2** | Optional wiki page or Home bullet for **bwakit** subtree. |
| **P2** | Add **`docs/tasks.md`** checkbox “sync wiki after AGENTS / USAGE / build changes” if you want explicit tracking. |

---

## Success criteria (plan Part E)

| Criterion | Status |
|-----------|--------|
| Every Part A item linked from wiki **or** listed in §2 as repo-only | **Met** (with §2 table). |
| Contributor/agent hybrid core readable in wiki | **Met** (Contributing + Build pages). |
| No broken `main` links on **published** wiki | **Pending merge + T10**; staging links checked in [LINK_CHECK_RESULTS.md](LINK_CHECK_RESULTS.md). |
| Gap report with follow-ups | **This file** |

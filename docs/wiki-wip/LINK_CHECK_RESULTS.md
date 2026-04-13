# Link check results (T11)

**Date:** 2026-04-13  
**Scope:** Outbound `https://github.com/yassineS/bwa-neo/blob/main/...` and `.../tree/main/...` links in staged wiki page Markdown (`Home.md`, `Usage-and-features.md`, `Contributing-and-agents.md`, `Build-and-test.md`, `Architecture-and-scope.md`, `Benchmarks-and-research.md`, `Security-licence-and-conduct.md`, `_Sidebar.md`, `_Footer.md`).  
**Method:** `curl -sL -o /dev/null -w '%{http_code}'` (follows redirects; same status a browser would see for the HTML document page).

## Results

| HTTP | URL |
|------|-----|
| 404 | `https://github.com/yassineS/bwa-neo/blob/main/.github/PULL_REQUEST_TEMPLATE.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/.github/workflows/ci.yaml` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/AGENTS.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/CHANGELOG.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/CONTRIBUTING.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/COPYING` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/MAINTAINERS.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/README.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/SECURITY.md` |
| 404 | `https://github.com/yassineS/bwa-neo/blob/main/benchmarks/README.md` |
| 404 | `https://github.com/yassineS/bwa-neo/blob/main/benchmarks/pixi.toml` |
| 404 | `https://github.com/yassineS/bwa-neo/blob/main/benchmarks/publication_draft.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/benchmarks/refbias/README.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/BWA-NEO.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/CODE_OF_CONDUCT.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/DEVELOPMENT.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/NEWS.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/UPSTREAM_TRIAGE.md` |
| 404 | `https://github.com/yassineS/bwa-neo/blob/main/docs/USAGE.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/design.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/requirements.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/docs/tasks.md` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/man/bwa.1` |
| 200 | `https://github.com/yassineS/bwa-neo/blob/main/tests/README.md` |
| 200 | `https://github.com/yassineS/bwa-neo/tree/main/benchmarks` |
| 404 | `https://github.com/yassineS/bwa-neo/tree/main/benchmarks/nextflow` |

## Interpretation

Several **404** responses reflect paths that exist in the **local** working tree but are **not yet on the default branch** on GitHub at the time of the check (for example new docs and benchmark layout on a feature branch). After those changes merge to **`main`**, re-run this check (same `curl` loop or open each link after **`gh browse`** to the file).

**Optional `gh` check:** `gh api repos/yassineS/bwa-neo/contents/<path>` returns JSON for paths that exist on `main` (handy for agents without `curl`).

## Browser pass

For accessibility and rendering, spot-check the published wiki at https://github.com/yassineS/bwa-neo/wiki after T10 push, or open each blob link with:

```bash
gh browse --repo yassineS/bwa-neo
```

…and navigate from there, or paste URLs into the browser.

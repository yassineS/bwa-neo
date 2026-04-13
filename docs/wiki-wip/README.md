# GitHub Wiki export (staging)

This folder holds **staging copies** of the GitHub Wiki pages for **bwa-neo**. The live wiki is a **separate git repository** from the main code tree.

## Public wiki URL

After publishing: `https://github.com/yassineS/bwa-neo/wiki`

## Publish steps (maintainers)

1. Enable the wiki under **Repository settings → General → Features → Wikis**.
2. Install and sign in to the [GitHub CLI](https://cli.github.com/) (`gh auth login`). Clone the wiki repository (empty on first use):

   ```bash
   gh repo clone https://github.com/yassineS/bwa-neo.wiki.git
   cd bwa-neo.wiki
   ```

3. Copy Markdown from this directory into the wiki clone root (same filenames):

   - `Home.md`
   - `Usage-and-features.md`
   - `Contributing-and-agents.md`
   - `Build-and-test.md`
   - `Architecture-and-scope.md`
   - `Benchmarks-and-research.md`
   - `Security-licence-and-conduct.md`
   - `_Sidebar.md`
   - `_Footer.md`

4. Commit and push to the wiki remote. The GitHub CLI does not replace Git for staging commits; use normal Git commands, with **`gh auth setup-git`** applied once so `git push` authenticates like `gh`:

   ```bash
   git add .
   git commit -m "docs: sync wiki pages from docs/wiki-wip"
   git push
   ```

When you change [AGENTS.md](../AGENTS.md), [CONTRIBUTING.md](../CONTRIBUTING.md), [USAGE.md](../USAGE.md), or build and test instructions in the main repository, update the matching files here and push the wiki again.

## Artefacts from the documentation aggregation plan

| File | Purpose |
|------|---------|
| [inventory.json](inventory.json) | Machine-readable documentation inventory with audience tags |
| [LINK_GRAPH.md](LINK_GRAPH.md) | Link audit for README and fork landing doc |
| [LINK_CHECK_RESULTS.md](LINK_CHECK_RESULTS.md) | HTTP status check for outbound `blob/main` links (generated) |
| [GAP_REPORT.md](GAP_REPORT.md) | Final documentation gap catalogue (generated) |

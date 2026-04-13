# GitHub Wiki export (staging)

This folder holds **staging copies** of the GitHub Wiki pages for **bwa-neo**. The live wiki is a **separate git repository** from the main code tree.

## Public wiki URL

After publishing: `https://github.com/yassineS/bwa-neo/wiki`

## Publish steps (maintainers)

1. Enable the wiki under **Repository settings → General → Features → Wikis**.
2. Install and sign in to the [GitHub CLI](https://cli.github.com/) (`gh auth login`). Run **`gh auth setup-git`** once so `git push` uses the same credentials as `gh`.

3. **First-time only:** if `gh repo clone https://github.com/yassineS/bwa-neo.wiki.git` returns **Repository not found**, GitHub has not created the wiki git repository yet. Open the wiki from the CLI, then create and save a short **Home** page in the browser:

   ```bash
   gh browse --wiki yassineS/bwa-neo
   ```

   After that, `gh repo clone …` should succeed.

4. **Automated option** (from repo root, after the wiki git exists):

   ```bash
   ./scripts/publish-wiki-from-staging.sh
   ```

   Override clone location with `WIKI_CLONE_DIR=/path/to/bwa-neo.wiki` if needed.

### Manual clone and copy

Clone the wiki repository:

```bash
gh repo clone https://github.com/yassineS/bwa-neo.wiki.git
cd bwa-neo.wiki
```

Copy Markdown from this directory into the wiki clone root (same filenames):

- `Home.md`
- `Usage-and-features.md`
- `Contributing-and-agents.md`
- `Build-and-test.md`
- `Architecture-and-scope.md`
- `Benchmarks-and-research.md`
- `Security-licence-and-conduct.md`
- `_Sidebar.md`
- `_Footer.md`

5. Commit and push to the wiki remote. **Git** is still required for `git add` / `git commit` / `git push` inside the `.wiki` clone (GitHub does not offer `gh` commands for wiki commits). Ensure **`gh auth setup-git`** has been run so those pushes authenticate like **`gh`**:

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
| [WIKI_PUBLISH_STATUS.md](WIKI_PUBLISH_STATUS.md) | T10 outcome and first-time `gh browse --wiki` steps |

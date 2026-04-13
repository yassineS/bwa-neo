# Wiki publish status (T10)

**Public wiki URL:** https://github.com/yassineS/bwa-neo/wiki

**Outcome (automated push):** A `gh repo clone https://github.com/yassineS/bwa-neo.wiki.git` attempt from this environment returned **Repository not found**. On GitHub, the wiki **git** remote often does not exist until at least one wiki page has been created in the web UI (or the wiki feature was toggled without seeding content).

**What to do next (prefer `gh`):**

1. Open the wiki in the browser from the CLI (creates no files locally; use this to reach “Create the first page” quickly):

   ```bash
   gh browse --wiki yassineS/bwa-neo
   ```

2. Save any short **Home** page once.

3. Clone and publish using **`gh`** for the clone step, then run the helper (still uses **Git** only inside the wiki clone for `add` / `commit` / `push`, because GitHub does not expose wiki commits through `gh`):

   ```bash
   gh auth setup-git   # once per machine
   ./scripts/publish-wiki-from-staging.sh
   ```

**Note:** GitHub’s wiki remains a **separate** repository from `main`; syncing after in-repo doc edits is a deliberate second step.

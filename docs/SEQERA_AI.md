# Seqera AI (CLI) in this repository

[Seqera AI](https://docs.seqera.io/platform-cloud/seqera-ai/) is the Seqera command-line assistant for Nextflow, Seqera Platform, and bioinformatics workflows. It complements local development of pipelines under `benchmarks/at_scale/nextflow/` and any nf-core–style work.

## Requirements

- Node.js **18+** and **npm**
- A [Seqera Platform](https://cloud.seqera.io/) account (free tier includes starter credits for Seqera AI)

## Install (local machine or VM)

From the repo root:

```bash
chmod +x scripts/install-seqera-ai.sh scripts/check-seqera-ai.sh
./scripts/install-seqera-ai.sh
```

Or manually:

```bash
npm install -g seqera
seqera --version
```

## Authenticate

Interactive (opens browser):

```bash
seqera login
```

Automation / CI / headless environments:

```bash
export SEQERA_ACCESS_TOKEN=<your_platform_access_token>
seqera ai --headless "your question"
```

See [Authentication](https://docs.seqera.io/platform-cloud/seqera-ai/authentication) for `TOWER_ACCESS_TOKEN`, enterprise URLs, and `SEQERA_AI_BACKEND_URL` when pointing at hosted backends.

## Verify

```bash
./scripts/check-seqera-ai.sh
```

With a token set, this also runs a minimal headless query.

## Use

- Interactive TUI: `seqera ai`
- One-shot: `seqera ai --headless "How do I structure Nextflow modules?"`
- Continue session: `seqera ai -c`

## Coding agents (Cursor, Claude Code, etc.)

Install the bundled skill into this repo (committed under `.claude/skills/seqera/`):

```bash
seqera skill install --local
```

After upgrading the global CLI:

```bash
seqera skill check --update
```

## Dev Container

Opening the workspace in the devcontainer installs Node.js and runs `./scripts/install-seqera-ai.sh` on container create. You still need `seqera login` (or a token) inside the container.

## Further reading

- [Seqera AI overview](https://docs.seqera.io/platform-cloud/seqera-ai/)
- [Installation](https://docs.seqera.io/platform-cloud/seqera-ai/installation)
- [Authentication](https://docs.seqera.io/platform-cloud/seqera-ai/authentication)
- [Skills](https://docs.seqera.io/platform-cloud/seqera-ai/skills)

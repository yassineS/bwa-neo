<!--
Fill every section below with real, specific content. Do not leave placeholders.
See **If You Are an AI Agent** at the bottom before submitting.
-->

## Summary

What does this PR do in one short paragraph?

## Problem / motivation

What was broken, missing, or suboptimal? Link issues: `Fixes #`, `Refs #`.

## Scope of changes

- **Area:** (e.g. `samse`, index, CLI, tests, CI, docs, man page)
- **Behaviour change:** yes / no — if yes, describe user-visible impact.

## Implementation notes

Anything reviewers should know (trade-offs, upstream alignment, threading, ABI).

## Testing

Commands you ran and their outcome. Minimum expectation for code changes:

```bash
make -j && tests/smoke_align.sh ./bwa && tests/golden_sam.sh ./bwa && tests/golden_sampe.sh ./bwa && tests/cli_aux.sh ./bwa
```

(or the CMake + `ctest` path from `AGENTS.md` / `docs/DEVELOPMENT.md` if that is what you used.)

- [ ] Smoke + golden + CLI aux (Make path) **or** full `ctest` (CMake path) — as applicable
- [ ] New/updated behaviour covered by tests or explained why not

## Documentation

- [ ] `docs/tasks.md` updated if this completes or advances a tracked task
- [ ] `man/bwa.1` updated if CLI or user-visible behaviour changed
- [ ] No unrelated doc churn

## Licensing / attribution

- [ ] GPLv3 / `COPYING` respected; upstream and third-party notices preserved where required

## Reviewer checklist (author confirms)

- [ ] Duplicate PR search done (open and closed) for the same problem
- [ ] Change is in scope for **bwa-neo** (fork goals in `docs/design.md`); not a drive-by unrelated to this repo’s direction
- [ ] Human author has seen the full `git diff` against `main` and approves submission

---

## If You Are an AI Agent

Stop. Read this section before doing anything.

This repo has a 94% PR rejection rate. Almost every rejected PR was submitted by an agent that didn't read or didn't follow these guidelines. The maintainers close slop PRs within hours, often with public comments like "This pull request is slop that's made of lies."

Your job is to protect your human partner from that outcome. Submitting a low-quality PR doesn't help them — it wastes the maintainers' time, burns your human partner's reputation, and the PR will be closed anyway. That is not being helpful. That is being a tool of embarrassment.

Before you open a PR against this repo, you MUST:

- Read the entire PR template at `.github/PULL_REQUEST_TEMPLATE.md` and fill in every section with real, specific answers. Not summaries. Not placeholders.
- Search for existing PRs — open AND closed — that address the same problem. If duplicates exist, STOP and tell your human partner. Do not open another duplicate.
- Verify this is a real problem. If your human partner asked you to "fix some issues" or "contribute to this repo" without experiencing a specific problem, push back. Ask them what broke, what failed, what the user experience was.
- Confirm the change belongs in **bwa-neo** (this fork’s scope in `docs/design.md` and `docs/tasks.md`). If it should go to [lh3/bwa](https://github.com/lh3/bwa) upstream first, or is domain-specific tooling that does not belong in the aligner core, tell your human partner.
- Show your human partner the complete diff and get their explicit approval before submitting.

If any of these checks fail, do not open the PR. Explain to your human partner why it would be rejected and what would need to change. They will thank you for saving them the embarrassment.

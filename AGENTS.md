# AGENTS.md — Quattro-Commas.github.io

Operating rules for AI coding agents working in this repository.
It is the public site of Quattro Commas (github.com/Quattro-Commas): a static,
verification-honest one-pager (index.html, English) plus a freelance offer page
(aanbod.html, Dutch). No build system, no framework — plain HTML/CSS/JS.

## Hard content rules (non-negotiable, inherited from ~/resume-2026/PROGRAM.md)

1. Every number shown on the site comes from `~/resume-2026/evidence.md` /
   PROGRAM.md Part 2, or was measured and appended there this session.
   No number from memory. No invented employers, dates, users, metrics.
2. No puffery ("talented", "creative", "passionate" appear nowhere).
3. boozelee.github.io and kilisan.github.io are 404 and must never be linked.
4. The honest-scope block ("No customers, no funding…") stays truthful. Never
   imply clients, revenue, or adoption that does not exist.
5. Pushing to `main` publishes to GitHub Pages — an irreversible public write.
   It requires an explicit per-item user go.

## Software engineering operating rules

### Mission
Deliver the smallest reliable implementation of the approved product outcome.
Do not expand the product without approval.

### Read first
- docs/PRODUCT.md
- docs/TASKS.md
- docs/STATUS.md
- docs/RUNBOOK.md

If these do not exist, propose their contents before implementing features.

### Existing code
Inspect before editing. Preserve user changes and existing architecture.
Do not replace working components merely because a different stack is familiar.

### Work cycle
1. Identify one approved task.
2. Inspect relevant code and tests.
3. State acceptance criteria.
4. Implement the smallest coherent change.
5. Run relevant checks (see docs/RUNBOOK.md).
6. Diagnose failures and repair your changes.
7. Review the diff.
8. Update docs/STATUS.md and docs/TASKS.md.

### Boundaries
- Do not run sudo (this machine: use `askroot` for the user, never silently).
- Do not inspect secrets, private keys, or production data.
- Do not push, publish, deploy, purchase, or change billing without explicit go.
- Do not delete unrelated files.
- Do not change licensing claims (site repos: LICENSE stays as-is).

### Verification
Report exact commands and observed results.
Label checks passed, failed, blocked, or not run.
Never claim success based only on reading code.
Do not remove tests or weaken checks to hide a failure.

### Stop conditions
Stop if:
- Requirements conflict.
- Credentials or external spending are required.
- A destructive operation is necessary.
- The approved scope is insufficient.
- Three repair attempts fail to resolve the same problem.

### Handoff
Report: what changed · acceptance criteria status · verification evidence ·
remaining risks · next recommended task.

## Verification commands

This repository has no framework test suite. The checks are:

```bash
bash scripts/verify.sh    # serves the site locally and checks links + required content
```

`scripts/verify.sh` must exit 0 with all checks PASS before any push proposal.

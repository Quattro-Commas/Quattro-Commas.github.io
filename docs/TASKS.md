# TASKS

One task in progress at a time. Acceptance criteria are demonstrable, not vibes.

## TASK-001 — Publish aanbod.html (BLOCKED on user go)
- Change: new aanbod.html + one-line link in index.html contact block.
- Status: implemented on branch `agent/first-usable-release`, verified locally
  (0 console errors, mobile 375px OK, keyboard order OK, no dead targets).
- Acceptance:
  - [x] aanbod.html complete per docs/PRODUCT.md
  - [x] index.html links to /aanbod.html
  - [x] scripts/verify.sh passes
  - [ ] explicit user go → commit + push to main (publishes live)

## TASK-002 — Add scripts/verify.sh (DONE)
- A local check script: serve the repo root, verify every internal link
  resolves, verify required content markers on both pages, exit non-zero on
  any failure. No external network calls.
- Acceptance:
  - [x] fails when a page or asset is missing (negative mode: live server +
        deliberately missing page reported broken, exit 1; documented)
  - [x] passes on the current tree (3 consecutive runs: PASS/exit 0,
        incl. run immediately after negative — SO_REUSEADDR fix verified)
  - [x] documented in docs/RUNBOOK.md and AGENTS.md

## TASK-003 — CI verify gate (in progress — landing via PR)
- `.github/workflows/verify.yml`: on PR to main, push to main, and manual
  dispatch; runs `scripts/verify.sh` plus the `--negative` detector proof
  (exit 1 required; exit 2 = red). Zero dependencies, zero secrets,
  `contents: read`, 5-minute timeout.
- Acceptance:
  - [ ] workflow runs green on its own PR (pull_request trigger uses the
        merge ref, so the new workflow runs on the PR that adds it)
  - [ ] merged to main after green

## TASK-004 — Offer-page casus section (proposed, blocked on first client)
- Placeholder stays empty until a real, client-approved casus exists.
  No invented case studies, ever.

# STATUS — 2026-10-17 (session 2: engineering workflow applied)

## Session context
Crush engineering-workflow setup applied to this repo: AGENTS.md operating
rules, docs/ (PRODUCT/TASKS/STATUS/RUNBOOK), .agents/skills/software-engineer,
work branch `agent/first-usable-release`, offline verify gate.
Model/provider route verified: large=glm-5.3-flash (zai), small=deepseek-v4.1-flash
(hyper). Global crushrc grants read-only auto-approvals (view/ls/grep) and
disables metrics. No Mistral provider configured; Vibe stays separate.

## State
- Branch: `agent/first-usable-release`.
- Working tree (all uncommitted, reviewable):
  - aanbod.html (new) — Dutch freelance offer page
  - index.html (+1 line) — contact-block link to /aanbod.html
  - AGENTS.md (new) — operating rules + hard content rules
  - docs/ (new) — PRODUCT, TASKS, STATUS, RUNBOOK
  - scripts/verify.sh (new) — offline verification gate
  - .agents/skills/software-engineer/SKILL.md (new)
- TASK-002 DONE with evidence:
  - `bash scripts/verify.sh` → ALL CHECKS PASS, exit 0 (3 consecutive runs)
  - `bash scripts/verify.sh --negative` → live server, all real checks PASS,
    deliberately missing page reported broken, exit 1 (documented contract)
  - Repairs this session (per work cycle): foreground-server bug (missing `&`),
    invalid handler subclassing, missing SO_REUSEADDR on back-to-back runs.
- TASK-001 (publish aanbod page) BLOCKED on explicit user go — push to main
  publishes to GitHub Pages immediately.

## Risks / open decisions
- No CI yet (TASK-003 proposed, after TASK-001 ships).
- fonts.googleapis.com is a runtime external dependency; verify.sh is
  offline by design and does not check it.
- Honest-scope text must be re-checked for truthfulness at publish time.

## Next recommended task
User go for TASK-001 (commit + push). Then TASK-003 CI workflow.

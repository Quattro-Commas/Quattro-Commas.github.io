---
name: software-engineer
description: Build or repair this site through scoped implementation, testing, and evidence-based review.
user-invocable: true
---

# Software engineering workflow

Use this workflow for approved site-building and repository-repair tasks in
this repository. Operating rules and boundaries live in AGENTS.md; they bind.

## Phase 1: Understand
Read AGENTS.md and docs/ (PRODUCT, TASKS, STATUS, RUNBOOK).
Inspect entry points, existing pages, scripts, and relevant code.
Separate observed facts from assumptions.

## Phase 2: Scope
Define one useful end-to-end outcome.
List acceptance criteria and exclusions.
Identify external dependencies and risks.
Do not silently add a service, dependency, or page.

## Phase 3: Baseline
Inspect current Git changes (`git status --short`, `git diff`).
Run `bash scripts/verify.sh` and record the result.
Record pre-existing failures separately — never silently adopt them.

## Phase 4: Implement
Make small, coherent changes.
Follow the existing design system in index.html (tokens: --teal --amber
--magenta --cream --ink; Permanent Marker headings, JetBrains Mono details,
Sora body; 1px-border cards; honest-scope voice).
Content rules from AGENTS.md are acceptance criteria, not suggestions.
Add no framework, no build step, no analytics.

## Phase 5: Verify and repair
Run `bash scripts/verify.sh`.
Read actual failures. Fix the implementation, not the success criteria.
Stop after three unsuccessful repairs of the same problem.

## Phase 6: Review
Inspect the final diff.
Check: internal links resolve, honest-scope text still true, no new numbers
outside ~/resume-2026/evidence.md, no secrets, mobile + keyboard behaviour.
Identify checks that were not run and say so.

## Phase 7: Handoff
Update docs/STATUS.md and docs/TASKS.md.
Report evidence for each acceptance criterion (command + observed result).
Do not push. Proposing the push is allowed; executing it requires the
explicit per-item user go (AGENTS.md hard rule 5).

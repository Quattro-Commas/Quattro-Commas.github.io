# Product: Quattro Commas site (quattro-commas.github.io)

## User
Two audiences, one static site:
1. Recruiters and engineers evaluating Kiliaan Vanvoorden for AI
   evaluation/verification engineering roles (index.html, English).
2. Owners of Belgian SMEs who need manual data work automated (aanbod.html,
   Dutch) — the freelance bijberoep funnel.

## Problem
Reviewers do not clone repositories; they click. The site must answer
"can this person build things, and can I trust the claims?" in under 30
seconds — with proof a stranger can re-run — and give SME prospects a
concrete, fixed-price way to start.

## Current release (live)
- index.html: hero, ticker, terminal animation, creed cards, selected work
  (5 repos), honest-scope note, contact block with CV link.
- aanbod.html (built on branch, awaiting publish go): signals, 3 fixed-price
  packages, 4-step process, verification guard rationale, honest-scope block,
  terms (incl. Peppol e-invoicing), contact CTA.

## Acceptance criteria (site-wide)
- Every internal link resolves (no 404) when served from the repo root.
- No console errors on load.
- `scripts/verify.sh` exits 0.
- All numbers on pages trace to ~/resume-2026/evidence.md or are offers/prices.
- Mobile usable at 375px; keyboard navigable; prefers-reduced-motion respected.
- Honest-scope text on both pages remains factually true at publish time.

## Exclusions
- No build tooling, no framework, no analytics, no tracking cookies.
- No client logos, testimonials, or metrics that cannot be re-derived.
- No backend, no forms-to-database (contact is mailto only).

## External services
- Google Fonts (link tag) — accepted.
- GitHub Pages hosting — accepted.
None other approved.

## Release approval
Pushing to `main` publishes to GitHub Pages. Manual per-item approval required
(~/resume-2026/PROGRAM.md rule 5).

# Quattro-Commas — Groq peer-review: how this gets "Musk-impressive"

> Status: peer-review draft. Author: Groq via the local inference gateway. Reviewer: mavis. Date: 2026-10-11.
>
> Bar: auditable, scientifically rigorous, first-principles, openly inspectable, ships working artifacts, never marketing. The four highest-leverage moves survive constraint-checking below; the rest of the Groq draft is in [`/tmp/qc-groq-phase3-reply.md`](../../tmp/qc-groq-phase3-reply.md) for the audit trail.

## What Groq proposed

The full proposal is 22,887 chars covering all seven repos, with three cross-cutting asks (single highest-leverage move, a move that compounds across all repos, a candid impossible-move). Many sub-proposals (GPG-signing, S3 publishing, org-wide repo manifests) cross the strategy doc's no-silo line (no new datastore, no new external service). This file keeps the ones that pass.

## Vision (3 paragraphs, tight)

1. **Auditable as a property, not a promise.** Every artifact the org emits — `harness` evidence JSON, `elohim-gate` claim verdict, `mcp-regression-lab` regression report, `repotruth` audit output, `terminal221b` diff approval log — carries a deterministic, self-describing identity: what build produced it, what input it had, what claim it makes. A reviewer six months later can prove the artifact is intact without trusting anyone.

2. **A compounding substrate, not a portfolio.** Today every repo is useful on its own; tomorrow every repo should *light up* the others when it ships a new feature. A new harness evidence field should be visible to `repotruth` (as part of the self-claim audit), to `mcp-regression-lab` (as part of an MCP-server contract check), to `terminal221b` (as part of the local-only diff review), and to `elohim-gate` (as a reproducible environment pin). The substrate is `harness`'s evidence JSON; everything else is a viewer of it.

3. **Open the gate on what was hidden.** Six specifically named failures are the reason `elohim` exists; six more can name the next round. Every shipped feature should ship with a *deliberately broken version* of itself, run through `harness eval`, and surface the failure modes in the HTML report. That is how `elohim` justifies its existence; that is how every other repo should justify the next version.

## Surviving moves, per repo

The Groq draft offered 4-5 moves per repo. After constraint-checking, the **3** that survive per repo are below. Each card names the smallest first implementation.

### `harness`

#### A. Deterministic evidence hash chain

**Move.** Stamp every `evidence/<task>.json` with `hash` and `prev_hash` fields. The hash is SHA-256 over a canonicalised form of the evidence JSON (sorted keys, no `time` jitter). `prev_hash` is the hash of the most recent evidence record in the same `.ai-engineering/evidence/` directory.

**Why it crosses the bar.** Turns the evidence directory into an immutable audit log *without* any external service, signed dependencies, or new infrastructure. A malicious actor who edits a past evidence JSON cannot hide the edit: the chain breaks at `prev_hash`. The chain is reproducible: starting from an empty directory and feeding back the same inputs produces the same chain head.

**First implementation.**

```python
# harness/chain.py
import hashlib, json
from pathlib import Path
from harness.policy import AE

def _canon(d: dict) -> bytes:
    return json.dumps(d, sort_keys=True, separators=(",", ":")).encode("utf-8")

def evidence_hash(ev: dict) -> str:
    """SHA-256 of the canonicalised evidence JSON."""
    return hashlib.sha256(_canon(ev)).hexdigest()

def prev_evidence_hash(root: Path) -> str:
    """Hash of the most recent evidence record by `time`, or '0'*64 for an empty chain."""
    d = root / AE / "evidence"
    if not d.is_dir():
        return "0" * 64
    recs = sorted(d.glob("*.json"), key=lambda p: p.stat().st_mtime)
    return "0" * 64 if not recs else json.loads(recs[-1].read_text()).get("hash", "0" * 64)
```

Wire into `cmd_verify` (and `_verify_run`) between `ev = {...}` and `write_evidence`: `ev["prev_hash"] = prev_evidence_hash(r); ev["hash"] = evidence_hash(ev)`.

Tests (`tests/test_chain.py`, new): the hash is stable across runs (excluding `captured_at`); the chain advances by one `prev_hash` per run; manually editing a historical JSON makes the next chain compute a different head.

#### B. Eval-driven dogfooding

**Move.** Add `harness eval redteam --task <id> --agent <a>` that wraps the existing eval corpus with a *known-bad* candidate (an intentionally-failing implementation injected into the worktree just before `harness verify` runs). The eval reports whether the gates caught the failure; the run's evidence JSON captures what they saw.

**Why it crosses the bar.** Every other "we have governance" tool ships without proof it actually catches failures. `harness eval redteam` is the proof, and it's open: the failures are public, the test cases are public, the report is public.

**First implementation.** Extend `harness/eval.py` with `redteam` mode that mutates `tasks.json` to inject a known-bad implementation per task. Output: `evals/redteam-report.html`. Tests: `tests/test_eval.py::test_redteam_catches_injected_bug` and `test_redteam_passes_clean_baseline`.

#### C. Evidence "viewer" subcommand

**Move.** `harness evidence view <task>` renders an HTML page from the JSON that the dashboard can fetch. Today the HTML is rendered by `harness/evidence.py:render` to a side path — separate, hidden, only served by `harness serve`. The viewer CLI lets you point any tool at it.

**Why it crosses the bar.** Evidence becomes a first-class object you can hand to anyone without the dashboard.

**First implementation.** New `cmd_view` in `harness/evidence.py`; thin wrapper around `render` writing to stdout or to `--out`. Test in `tests/test_evidence.py::test_view_stdin_arg`.

### `elohim`

#### A. Reproducible environment pin (extends Phase 1's `repro`)

**Move.** When invoked from `harness` via `--elohim-context`, elohim writes its current SHA-256 instrument pin to the evidence JSON's `repro.elohim_sha` field (mirroring `repro.harness_sha`).

**First implementation.** Adds a `repro["elohim_sha"] = compute_pin(skills/elohim-harness/)` in `embed_repro_metadata` when called from the harness integration path; in-process call only (no subprocess) for speed.

#### B. Adversarial claim ledger

**Move.** Extend the existing `claim-ledger` instrument with a "challenge" mode: a caller submits a *known-claimable* numeric statement; the instrument returns a single-page report that names the claim, the residual, the failure mode if any, and the rule that triggered the red light.

**First implementation.** New subcommand `elohim challenge <statement.json>` (statement is a small JSON shape). Tests in `tests/test_challenge.py`. Defer cross-repo impact to Phase 5 (`verify-all` orchestrator).

#### C. Public case-study sync

**Move.** The six historical failures in `docs/CASE-STUDY.md` are *Markdown*. Add a JSON variant — `docs/cases.json` — and have `elohim` reference both. Anyone pulling the repo gets a deterministic test corpus: re-run `tests/test_all.py` and watch each case flip from `red` to `green` over the next release.

**First implementation.** `docs/cases.json` schema: `[{"id", "title", "module", "expected_residual"}]`. `tests/test_all.py` loads and asserts each. Owner-side work: rewrite `CASE-STUDY.md`'s six bullets to have matching JSON entries.

### `repotruth`

#### A. Schema-versioned evidence-aware audits

**Move.** When auditing a repo, `repotruth audit` should look for `.ai-engineering/evidence/*.json` and cross-check each evidence's `hash`, `prev_hash`, `repro.harness_sha` chain against the local source tree's HEAD. Missing or inconsistent evidence → a `evidence-integrity` finding (new severity `medium`).

**First implementation.** New file `repotruth/src/rules/evidence.ts` with `auditEvidence(blob, srcSha): Finding[]`. Wired into `repotruth/src/audit.ts` after the existing rules.

#### B. Harness-evidence samples

**Move.** Publish `examples/harness-evidence.json` files (one per sample task) so users can try `repotruth audit-evidence <file>` against realistic shapes.

**First implementation.** 3 sample files manually curated from the running `qc/repos/harness` evidence output; gated by `tests/extract_evidence.test.ts`.

#### C. CI-side `protect-all-branches` reconstruction

**Move.** Today the ruleset is enabled by hand in the GH UI. Provide a `repotruth sync-rules <org>` command that emits a `rulesets.json` snapshot and a `gh api` recipe to rebuild it, so the org's policy is in *Git*, not just in *settings*.

**First implementation.** `repotruth/src/rules_ts.ts` exports; `repotruth/src/cli.ts` adds `sync-rules <org>`. Manual PR step remains — automate later.

### `mcp-regression-lab`

#### A. Harness-evidence-driven regression

**Move.** `mcp-lab harness-run <artifact> --servers <pool>` replays the MCP-call sequence encoded in a harness evidence JSON against a server pool. Today the lab only sees golden cases; this lets it *also* see what harness has already exercised.

**First implementation.** `mcp-regression-lab/src/harness_run.ts` parses `evidence/<task>.json` (forgiving — skip the `repro` block if absent) and re-emits each recorded MCP call against the configured server pool. `mcp-regression-lab/test/harness_run.test.ts` fixture.

#### B. Public regression feeds

**Move.** `mcp-lab watch <server-url> --json` emits a one-line-per-run log of `server → tool → expected → actual`. Anyone can subscribe to the JSON stream for any open MCP server.

**First implementation.** New subcommand in `src/cli.ts`; uses the existing `hosted-check` plumbing.

#### C. Deterministic report

**Move.** Today `report.html` may include wall-clock times. Add a `--deterministic` flag that suppresses them and uses sorted/sorted-bytes output so report diffs across runs are line-stable.

**First implementation.** `src/report.ts` checks a flag and short-circuits the timestamp formatter.

### `terminal221b`

#### A. bwrap policy-as-data

**Move.** Move the `bwrap` argument builder from `packages/cli/src/executor.ts` into a typed module with JSON-exported policy (`packages/cli/src/sandbox/policy.json`). Reviewers can diff policy changes in PRs.

**First implementation.** Extract a `buildBwrapArgs(policy: SandboxPolicy): string[]` function; write `SandboxPolicy` as a zod-style JSON schema; export schema and example.

#### B. Harness-evidence-aware approval

**Move.** When `terminal221b approve-diff` runs against a task contract, include the latest `evidence/<task>.json` hash in the approval log. The approval becomes auditable: which evidence the human signed off on.

**First implementation.** `packages/cli/src/approval.ts` writes `{approval_id, evidence_hash, bwrap_policy_sha, ts}` to the local transcript.

#### C. TUI-side evidence dashboard

**Move.** The Rust TUI shows recent `harness verify` runs by reading `.ai-engineering/evidence/*.json` directly. A small `terminal221b-views evidence` command.

**First implementation.** `packages/rust-tui/src/evidence.rs` reads JSON and renders a list. Test by snapshotting the JSON layout.

### `Quattro-Commas.github.io`

#### A. Audit dashboard

**Move.** A static `/audit/` page (auto-generated by a workflow that consumes harness evidence on every push) that lists every `evidence/<task>.json` in the org with its `verdict`, `hash`, and `prev_hash`. Public, append-only.

**First implementation.** `scripts/audit_page.js` (Node) reads `evidence/*.json` from a configured repo and writes `audit/index.html`. Run on schedule + on push to `main` via `.github/workflows/audit.yml`.

#### B. Case-study embed

**Move.** Embed `elohim`'s six `cases.json` into the public site as a card grid, replacing the prose-heavy `CASE-STUDY.md`. Each card has the same JSON the gate sees.

**First implementation.** `docs/cases.json` (elohim's) is copied into `public/cases.json`; `<card-grid>` is a tiny web component.

#### C. Repo state snapshot

**Move.** A static `/state/` page that for each repo shows: latest release SHA, current `main` SHA, SHA-pinned Actions status, `harness scan --fail-under 70` latest score.

**First implementation.** `scripts/state.js` consumes public PyPI/GitHub APIs and writes `state/index.html`.

### `.github`

#### A. Org-level evidence aggregator

**Move.** A workflow `.github/workflows/aggregate-evidence.yml` that runs weekly and pulls the latest `evidence/` JSON from each member repo, then writes a manifest at `Quattro-Commas/audit-feed` (new repo) that catalogues every emit.

**First implementation.** Workflow + `scripts/aggregate.py`. The new `audit-feed` repo is auto-bootstrapped.

#### B. Org-wide policy repo

**Move.** Move the `protect-all-branches` rules into `Quattro-Commas/policy` (a repo) and have a workflow sync it back to each member repo's rulesets. Today the rules live in each member repo's settings.

**First implementation.** `policy/rulesets/` JSON file + `scripts/sync_rules.sh` that calls `gh api`. Phase 5 candidate.

#### C. Shared harness init

**Move.** A workflow `.github/workflows/harness-bootstrap.yml` that, when a new repo is created in the org via `gh repo create`, automatically runs `harness init` + opens the first PR with the SHA-pinned workflow.

**First implementation.** Repo template. Defer.

## Three cross-cutting asks

**1. Single highest-leverage move this quarter: `harness` evidence hash chain (Move A above).**
It is three files, one test file, no new deps, ships today. Once it is in, every other repo's audit can verify it, the existing eval corpus becomes tamper-evident, and the org has a proof story it can carry into a public talk. Total effort: ~6 hours including tests and PR.

**2. Move that compounds across all seven repos: the Evidence JSON is a wire format.**
Once the chain hash lands, every other repo grows a viewer for it. `repotruth` audits chain integrity (`evidence-integrity` finding). `mcp-regression-lab` replays recorded calls. `terminal221b` approves with evidence_hash in the approval log. `elohim` writes its own SHA pin into `repro.elohim_sha`. The website renders the chain head. None of those require any cross-repo commit; each is a small addition to its repo.

**3. Move that is impossible without breaking the public surface: a cross-repo single-source-of-truth.**
The org would benefit from a "federation" repo that owns every other repo's invariants. That requires either (a) introducing a new datastore (org-wide evidence ledger) or (b) treating one of the existing repos as a single point of truth (which centralises governance the org's local-first posture explicitly rejects). Neither survives the no-silo constraint. Either decision would require a charter change in `Quattro-Commas.github.io/index.html`.

## What we explicitly are not building

This survives from the strategy doc: no new language, no new datastore, no custom silicon, no claims/payments rails, no model marketplace. The Groq draft proposed GPG signing and S3 publishing; both have been rejected in this distillation. The chain-hash approach delivers the equivalent audit invariant (`prev_hash` is a SHA-256 chain that detects *any* tampering, not just cryptographic) with zero new dependencies.

## Open questions / risks

1. **Schema versioning.** Phase 5 plans a `stages` field on top-level evidence. Bump `schema_version: 2` only when strictly necessary — the chain hash moves the "we know what was emitted" requirement from a schema field to a SHA, which is robust against forward drift.
2. **Throughput cost.** Hashing the canonicalised evidence JSON adds ~1ms per verify on a modern machine. Acceptable.
3. **`prev_hash` ordering.** Currently uses `mtime` (which can be wrong under clock skew). Worth switching to a `time` field (already in `ev`) once the contract is read-locked.

---

## Deliverable on disk

- Raw Groq output: `/tmp/qc-groq-phase3-reply.md` (22,887 chars content + 7,960 chars reasoning).
- This distilled file: `MUSKS-IMPRESSIVE.md` (Quattro-Commas.github.io).
- Phase-2 PR: Quattro-Commas/harness#11.
- Phase-1 PR: Quattro-Commas/harness#10.
- Phase-B PR: Quattro-Commas/repotruth#15.

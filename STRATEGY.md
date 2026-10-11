# Quattro-Commas — 2026 Q4 AI-Infrastructure Roadmap

> Status: proposed. Owner: Kiliaan Vanvoorden. Inputs: prior Phase-B closure + a Groq peer-review pass (Oct 11, 2026).
>
> Three of these items are scoped for **this quarter**. Two are scoped for **the year**. All sit on existing surface area — no new language, no new datastore, no new silicon.

## Where we are today

Seven repos, all with public READMEs, badges, CI, releases, and AGENTS.md:

| Repo | Tagline | License | Role |
|---|---|---|---|
| `harness` | "Local-first control plane that turns a normal Git repo into a governed agentic dev environment." | AGPL-3.0 | Governs every agent write; gates every claim. Already runs `harness ci` with a SHA-pinned generator. |
| `elohim` | "A number is a finding only after its residual was measured." | MIT | Numerical-evidence gate. Eight instruments. Reproducibility is the spine. |
| `terminal221b` | "Expo/React Native chat client + local-first coding CLI + Rust shell TUI." | AGPL-3.0 | Local-only diff approval, bubblewrap sandbox for the write path. |
| `repotruth` | Repo-truth / reference-verification. | AGPL-3.0 | Cross-cuts any repo that mentions other repos. |
| `mcp-regression-lab` | MCP regression rig. | AGPL-3.0 | Locks in MCP-server behavior across versions. |
| `.github` | Org meta | n/a | Org-level settings. |
| `Quattro-Commas.github.io` | Org website | n/a | Public face. |

Phase B has just shipped: triage + showcase polish across the four big repos, CI fixes, READMEs, badges, Makefiles, LICENSE fix, PRs created, releases published, adversarial review, final verification. The Quattro-Commas GitHub org enforces a strict policy on Actions (`github-owned` only, full commit SHA required) which Phase B closed.

## Where we're going

Quattro-Commas becomes **the local-first, reproducible, evidence-driven engineering platform** — the substrate on which every AI-coding agent writes, every claim is verified, and nothing ships without independent review. Not a cloud service. Not a new runtime. Built on open stacks (Python, TypeScript, Rust), enforced by deterministic evidence, pinned by org policy.

We are not: a generic cloud service; a new language runtime; a marketplace; a model provider.

## Six concrete additions — ordered by quarter

### Q4-2026 — small, shippable

These three are each a single PR. Each lands on an existing module. None requires a new dependency.

#### 1. Reproducibility metadata in every `harness verify`

**Repo / files**

- `harness/repro.py` (new) — `def embed_repro_metadata(root: Path, *, harness_sha: str | None = None, gha_sha: str | None = None) -> dict`
- `harness/verify.py` — in `cmd_verify`, compute `meta = embed_repro_metadata(...)` just before `ev = {...}` and assign `ev["repro"] = meta` (and likewise in `runner.py:_verify_run` for parity).
- `harness/cli.py` — extend the `verify` subparser with `--embed-repro` (default off).
- `tests/test_repro.py` (new) — assert keys `harness_sha`, `host`, `time`, `python_version`, `python_packages_hash` are present and stable across two consecutive invocations against a fixture repo. Use the existing `helpers.py` `harness()` driver.

**Why it matters.** Evidence becomes self-describing; a reviewer who reads `evidence/<task>.json` months later can prove the artifact was produced by an exact harness build on an exact runtime. `harness serve` already streams the same evidence via SSE, so the dashboard inherits the metadata for free.

**Acceptance.** Running `harness task start demo --goal "x" --accept "x" --allow "src/**" --risk low && harness verify demo --embed-repro` writes `evidence/demo.json` whose `repro` block passes `tests/test_repro.py`.

#### 2. Numeric-claim verification hook in `harness verify`

**Repo / files**

- `harness/repro.py` (or `harness/verify.py`) — `def find_numeric_claims(evidence_blob: dict) -> list[dict]` looks for any numeric results the agent committed under `.ai-engineering/evidence/numeric/**/*.json` (already supported by `harness/evidence`).
- `harness/verify.py` — after building `ev`, scan for numeric claims; for each one, call `elohim` as a subprocess (`elohim-gate estimate <claim-json>`); on residual > configured tolerance, append a result `{"name": "elohim-numeric/<claim-id>", "required": True, "ok": False, ...}`.
- `tests/test_verify_numeric.py` (new) — mock `elohim` as a fake returning a fixed residual; assert `cmd_verify` records a FAIL with the claim id; assert the inverse case.
- Optional opt-in flag `--numeric-verify` on the `verify` subparser (mirrors `--embed-repro`).

**Why it matters.** Pairs the two flagship repos: every numeric claim that an agent emits is checked against the regression suite elohim has codified. This is the first cross-repo integration in the org and the natural first billable of the elohim skills bundle.

**Acceptance.** A harness task that produces a fabricated numeric claim fails verification with a residual pointing at the originating claim id; a correct claim passes.

#### 3. Cross-repo evidence extraction in `repotruth`

**Repo / files**

- `repotruth/src/cli.ts` — add subcommand `extract-evidence <path>` (note: real layout is TS under `repotruth/src/`, not the Python `cli.py` an earlier draft assumed).
- `repotruth/src/extract_evidence.ts` (new) — `extractEvidence(blob: object): EvidenceBundle` walks `evidence/<task>.json` files for repo refs of the form `org/repo@sha` and emits a signed bundle.
- `repotruth/test/extract_evidence.test.ts` (new) — fixture with two cross-repo refs asserts the bundle.
- `repotruth/automation/` already contains `LICENSE.PROPRIETARY` material — leave strictly untouched.

**Why it matters.** Closes the audit gap where harness evidence cites a commit that doesn't exist on the cited branch. Repo-truth becomes the single source of cross-repo provenance the rest of the platform can route through.

**Acceptance.** `npx repotruth extract-evidence .ai-engineering/evidence/<task>.json` writes a JSON bundle listing every repo reference and the SHAs that resolve.

### 2027 H1 — larger, still self-hosted

#### 4. Unified `harness verify --all`

**Repo / files**

- `harness/verify.py` — new `cmd_verify_all(a)` orchestrates: existing gates → scope → review → repro meta → numeric verify → extract-evidence → emit one combined `evidence/<task>.json` with a single verdict and per-stage rows.

**Why it matters.** Reviewers run one command. The audit story collapses to a single artifact.

**Acceptance.** Five staged rows present in the evidence JSON; verdict is AND-of-stages.

#### 5. `mcp-regression-lab` artifact-driven harness integration

**Repo / files**

- `mcp-regression-lab/src/cli.ts` — add subcommand `harness-run <artifact>` (real layout is `src/cli.ts`, not the Python `cli.py` the earlier draft guessed).
- `mcp-regression-lab/src/harness_run.ts` (new) — re-executes `harness verify` against an evidence artifact, replays the recorded numeric claims through a configured MCP server pool, emits a regression report.

**Why it matters.** MCP server upgrades become gated: a new release cannot regress the contract that harness evidence relied on.

**Acceptance.** Breaking-change scoring visible in `report.html`; CI gates on regression delta.

#### 6. `terminal221b` sandbox-integrated harness scan diff approval

**Repo / files**

- `terminal221b/packages/cli/src/sandbox.ts` (new) — `runSandbox(taskPath: string): Promise<void>` mirrors `harness scan` output inside the existing bubblewrap sandbox (the same one used by `executor.ts`'s `bwrap` write path).

**Why it matters.** Local-first diff approval stops being a separate CLI; it inherits the bubblewrap guarantees that the write path already enforces.

**Acceptance.** `terminal221b sandbox run tasks/<name>` exits 0 inside bwrap; writes outside the declared `--allow` set fail.

## Process

- Every PR touches exactly one repo (one branch, one review, one merge).
- Every PR carries `evidence/<task>.json`-shaped output (real or stub) so that the empirical claim is in the diff.
- Every PR runs the repo's own CI gate — never a separate "team gate".
- Org policy: `github-owned` Actions, full commit SHA only. The `harness ci` generator emits these by default; updates to the SHA set land via `harness/ci.py` constants and re-running `harness ci --force`.

## What we explicitly are not building

- A new language runtime.
- A custom inference chip.
- A claims / payments rail.
- A model marketplace.
- Multi-tenant cloud infrastructure.

The platform wins by being **the auditor the rest of the AI-engineering stack passes through**, not by being the stack itself.

---

Provenance: synthesized Oct 11, 2026 from the Phase-B closure log + a Groq peer-review pass against the current `main`/`fix/*` state of every repo. Every file-path in this document was verified against `git ls-tree` before drafting.

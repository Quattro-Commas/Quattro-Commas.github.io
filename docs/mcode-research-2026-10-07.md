# MiniMax Code (`mcode`) 0.6.3 — measured engineering assessment

**Status: partially evaluated.** Small Python correctness family measured end-to-end; Flutter,
TypeScript, Lua, Tauri packaging and Supabase migrations **not executed** (no toolchains, RAM below
the enforced floor). Sections that were not executed say so instead of guessing.

- Research date: **2026-10-07**
- Revised **2026-10-07**: `testgen-mathx` and `trap-discount` added to §5. The original `trap-discount`
  result was invalidated — its fixture, not the agent, was at fault. Three task families are now
  measured, **9 of 9 attempts accepted**.
- Agent: `mcode` **0.6.3** at `/root/.minimax-code/bin/mcode`
- Model: `MiniMax-M3.1-Flash-Preview`, variant `thinking`
- Credential: managed OAuth, **token plan** (no per-token USD figure available)
- Studio `origin/main` at measurement: `60a80be`
- Full evidence: [`docs/evidence/README.md`](evidence/README.md)

---

## 1. Identity and verdict

**MiniMax Code**, invoked as `mcode`, is an open-source terminal coding agent. This measurement
confirms the identity and corrects its version: it is installed here at **0.6.3**, not the `0.4.12`
baseline that circulated in earlier write-ups, which now predates the measured surface by two minor
releases.

**Verdict.** `mcode` is a competent terminal agent with an unusually good automation contract, and
one real blocker on its own onboarding path. Its `--output-format json` result object exposes
`status`, `usage`, and an explicit **`usageIncomplete`** flag — so a caller can distinguish a
complete run from a truncated one *without trusting the model's prose*. That single field is worth
more to an evaluation pipeline than most published benchmark numbers.

It solved every bug-fix attempt it was given, on every repeat — **but only after the harness that
graded them was fixed.** The one task that first read 3/3 FAIL was failing on three separate bugs in
its own fixture, and read 3/3 PASS once those were corrected (§5). The sample is small, the domain is
narrow, and its `mcode init` path failed outright on this device. Treat it as **verified good at
small, test-backed Python fixes under a bounded budget** and **unproven** everywhere else.

> **The most transferable finding in this report is not about the agent.** A benchmark harness with
> three defects in it produced a confident, repeated, entirely false result, and the failure was
> *stable* — 3/3 identical failures read as a strong signal rather than a bug. The independent
> acceptance step caught it only because acceptance was re-run from scratch and compared against a
> spec written before the code. Had the grader trusted the agent's own summary, the false result
> would have shipped.

**Correction that matters most:** the tool that was described as needing installation is already
installed here, at a version with a materially larger flag surface than documented. Read
`--help`; do not trust a write-up.

## 2. Architecture — as far as it can be observed from outside

`mcode` is a closed binary distributed via npm as `@minimax-ai/code`; the architecture is not
inspectable from this device, so this section reports **observed interfaces**, not internals.

Three entry points, verified:

| Entry point | TTY required | Use |
|---|---|---|
| `mcode [prompt]` | **yes** | Interactive TUI |
| `mcode exec [prompt]` | **no** | One-shot headless run |
| `mcode acp` | no | Agent Client Protocol server over stdio |

The headless path is the important one for engineering work, and it is the well-built one. It
accepts `--cwd`, `--timeout`, `--max-steps`, `--permission`, `--output-format`, `--output-schema`,
`--diagnostics-dir`, `-o`, `--effort`, and per-run `--model`. Its result object is versioned
(`schemaVersion: 1`, `type: exec.result`) and carries run/session/turn IDs — enough to build a
reproducible evaluation harness on top, which is what §5 does.

## 3. Strengths, weaknesses, and a measured flaw matrix

### Measured strengths

| Strength | Evidence | Consequence |
|---|---|---|
| Honest automation contract | `usageIncomplete: false`, `usageSource: completed_responses` on a real run | A truncated run is detectable, not silent |
| Bounded execution | `--timeout`, `--max-steps`, process exit codes | A runaway task is stoppable |
| First-class diff review | `mcode exec review` covers staged, unstaged **and untracked** changes | Review is a CLI citizen, not a manual habit |
| Schema-constrained answers | `--output-schema` | Machine-checkable output without regex scraping |
| Precise minimal edits | 3/3 attempts changed exactly one file each | Low blast radius on the measured task |
| Secret hygiene by default | No third-party key configured; managed OAuth only | No key material in play to leak |

### Flaw matrix

Severity is the consequence, not a measured incidence rate. Frequency reflects what was observed
here, and the sample is small — do not read it as a prevalence estimate.

| Issue | Affected | Severity | Frequency evidence | Workaround | Status |
|---|---|---|---|---|---|
| **`mcode init .` fails unattended** — `Session Project could not be resolved`, then hangs to timeout; no `AGENTS.md` | 0.6.3 | **High** (blocks onboarding) | 1/1 attempt, reproduced | Author `AGENTS.md` by hand; treat `init` as interactive-only until re-tested | Not fixed here |
| **`--diagnostics-dir` must be empty** — rejects a dir containing the output file, `exit 2` | 0.6.3 | Medium (friction) | 1/1 attempt, twice | Write stdout to a sibling path | Working as designed |
| **`exec` output not written on failure** — `exit 2` produced a 0-byte stdout | 0.6.3 | Medium | 1/1 | Check exit code before parsing JSON | Not fixed here |
| Input-token cost does not scale with task size (~29k for a 2-file repo) | 0.6.3 | Medium (cost) | 3/3 attempts, consistent | Keep sessions short; budget on input, not output | By design |
| TUI commands undocumented in `--help` (`/goal`, `/steer`, `/context`, `/changelog`, …) | 0.6.3 | Low | Observed in-session | Discover in the TUI | Documentation gap |

### On the reported-but-unreproduced failure modes

Earlier write-ups cite upstream issues about agents writing files during read-only review,
reconstructing truncated test output as complete, and signing with a stale key. **None of those were
reproduced in this pass** — the measured sample is too small and the tasks too narrow. They are
carried as unconfirmed third-party reports, not as findings. The `usageIncomplete` field is
noteworthy here precisely because it is the mechanism that would make "truncated output reported as
complete" detectable at the protocol level.

## 4. Dataset and benchmark assessment

**No published benchmark number is adopted.** SWE-bench-style scores measure a model in a harness
someone else built; they say nothing about `mcode` plus *your* provider, *your* permissions, and
*your* prompt. This assessment measures the configured system, locally.

Method, and why it is shaped this way:

1. Each attempt gets **its own git worktree** from an identical commit. A failed attempt is destroyed
   by removing the worktree, never by reverting shared state.
2. One bounded `mcode exec` per attempt (`--timeout 4m --max-steps 12`, `--permission smart`).
3. Acceptance is decided by **re-running the acceptance command from scratch**. The agent's summary is
   recorded, never believed.
4. Incomplete evidence scores `UNKNOWN` and stays in the published set.
5. Agent telemetry (tokens, duration, status) comes from the JSON contract, so cost is measured, not
   estimated.

Raw rows: [`docs/evidence/results.jsonl`](evidence/results.jsonl).

## 5. What was actually run

### `bugfix-vowels` — case-sensitivity defect, one-line fix

Acceptance `python3 test_strutil.py` fails beforehand with `vowels uppercase: got 0, want 5`.

| Attempt | Exit | Agent status | Independent verdict | Tokens (in/out) | Wall |
|---|---|---|---|---|---|
| 1 | 0 | succeeded | **PASS** | 30660 / ~150 | 27 s |
| 2 | 0 | succeeded | **PASS** | 31672 / ~170 | 60 s |
| 3 | 0 | succeeded | **PASS** | 28987 / ~140 | 36 s |

**3/3 accepted.** Every attempt touched exactly one file. The fixture repo was still at `aa5e226`
with no stray branches after all worktrees were removed — isolation held.

### `testgen-mathx` — generate a test suite for an existing module

Acceptance `python3 test_mathx.py`. Fixture commit `72be246`.

| Attempt | Exit | Agent status | Independent verdict | Tokens (in/out) | Wall |
|---|---|---|---|---|---|
| 1 | 0 | succeeded | **PASS** | 36087 / 3168 | 51 s |
| 2 | 0 | succeeded | **PASS** | 33843 / 2663 | 38 s |
| 3 | 0 | succeeded | **PASS** | 35859 / 3580 | 44 s |

**3/3 accepted**, with **zero** unnecessary changes in every attempt — the only task where the agent
touched nothing beyond the file it was asked to produce. Output tokens run ~3x higher than the
bug-fix task, which is what test generation actually costs: the agent emits the artifact.

### `trap-discount` — a measurement that was wrong before it was run

The first version of this task recorded **3/3 FAIL** with the agent reporting `succeeded`. It was
never an agent defect. Three separate faults sat in the *fixture*, and the number was wrong in the
same direction each time.

1. **The harness scored correct behaviour as failure.** The original `check()` treated *any* raised
   exception as a failure, so the `ValueError` that SPEC.md *requires* counted against the agent.
2. **The first fix was incomplete.** Commit `b3309af` corrected the scoring but left two assertions
   a conforming implementation still fails: it demanded a `ValueError` for `percent=0.5`, which is
   inside the spec's own valid `0..1` range, and expected `66.66` for `percent=0.333`, a value that
   belongs to `percent=1/3`.
3. **One assertion could not fail at all.** Even the corrected rounding case could not distinguish
   `round()` from `floor()` — both yield `66.69`, so a truncating implementation passed it.

Commit `78eb4ee` finishes the correction. `SPEC.md` and `src/discount.py` were **not** touched: the
spec is the contract, and the test was corrected to match it, never the reverse. The corrected
harness was then mutation-tested — every mutant caught, conforming implementation passes:

| Mutant | Verdict |
|---|---|
| Original broken impl (`percent/100`, no validation) | caught |
| Missing negative-price rule | caught |
| Truncates instead of rounding | caught |
| Treats `percent` as `0..100` | caught |
| Spec-conforming implementation | passes |

The three invalid rows were **deleted** from `results.jsonl` rather than kept as FAILs. A reader
must not be able to find an agent failure that was really a fixture failure.

### `trap-discount-v2` — re-measured against the corrected harness

Fixture commit `78eb4ee`.

| Attempt | Exit | Agent status | Independent verdict | Tokens | Wall |
|---|---|---|---|---|---|
| 1 | 0 | succeeded | **PASS** | 33148 | 36 s |
| 2 | 0 | succeeded | **PASS** | 32011 | 37 s |
| 3 | 0 | succeeded | **PASS** | 31749 | 36 s |

**3/3 accepted.** This is the headline correction: the same task that read 3/3 FAIL against the
broken harness reads **3/3 PASS** against the corrected one. The earlier verdict measured the test.

Getting attempt 1 took **three tries at the harness, not the agent**, and the failures are worth
recording because none of them were test results:

1. `--diagnostics-dir must be empty` — `exit 2`, 4 s, zero bytes of output. The run directory
   inherited by the attempt still held the previous run's `progress.jsonl`. The agent never started.
   A documented 0.6.3 behaviour, and a runner bug: run directories are now cleared before reuse.
2. Twice, `mobile-safe.py` stopped the run for *available RAM below reserve* — the 512 MiB reserve.
   Attempts 2 and 3 cleared the same guard without incident, so the shortfall is environmental and
   nondeterministic. **No threshold was lowered to get attempt 1 to run**; it was waited out.

None of these was ever written to the ledger as a failure. An attempt that never executed is
UNKNOWN, and UNKNOWN is the honest word.

### What the cost actually looks like

- **~28k–33k input tokens for a two-file repository**, across every task measured. Output tokens vary
  by what is being produced: ~150–1000 for a one-line fix, ~2700–3600 for a generated test suite.
  The agent reads far more scaffolding than it writes. **Budget input, not output.**
- 27–60 s wall for a single-line fix; 36–51 s for a generated test suite.
- On a token plan, no honest per-task USD figure exists. The circulated price table was not
  re-verified here and is not restated.

### Executed vs. not

| Wave | Planned | Executed |
|---|---|---|
| A — local verification | 6 steps | **6** |
| B1 pilot | 9 | **9 of 9 — every attempt accepted** |
| B2 local wave | 42 | **not run** |
| B3 Flutter/TS/Lua/DB | 78 | **NOT RUN — blocked** |

`flutter`, `dart`, `tsc`, `lua`, `docker`, `psql`, `supabase` are absent, and available RAM
(519–729 MiB observed) sits at or below the 768 MiB threshold `mobile-safe.py` enforces. **That
threshold was not lowered.** Executing those families here would have measured the environment, not
the agent. The same guard twice refused `trap-discount-v2` attempt 1 for breaching its 512 MiB
reserve, and was likewise not lowered — the attempt was re-run once memory recovered.

### A gap in this harness: PASS verdicts are not independently re-inspectable

Each attempt is destroyed by removing its worktree, which is correct for isolation but means **the
agent's actual patch is archived nowhere**. `results.jsonl` records that attempt 2 produced a PASS;
it does not record *what* attempt 2 produced. Run directories keep only agent telemetry
(`progress.jsonl`, `result.json`). A later reader cannot audit a verdict without re-running the
task. The fix is one line — write `git diff` into the run directory before dropping the worktree —
and it is the highest-value change to this harness.

## 6. Recommended infrastructure

Ordered by what the evidence supports.

**Required.** `mcode` 0.6.3 pinned; one authenticated provider; a git repository per attempt; an
independent acceptance command that exists *before* the agent runs. That last one is what converts
a plausible patch into a verified one.

**Recommended.** Isolated worktrees (proven here — they held under three attempts and left no
residue). Bound every run with `--timeout` and `--max-steps`. Capture JSON output to a sibling path
so `--diagnostics-dir` can stay empty. Review `dataContribution.enabled` before pointing this at
proprietary code.

**Optional.** `mcode exec review` for diffs. `--output-schema` when output feeds another tool.
`--effort` when a task genuinely needs more deliberation.

**Experimental / unjustified here.** Parallel workers, local LLM inference, model routing. Nothing in
this measurement demonstrates a need for any of them.

## 7. Reproducible setup

Everything below was run on this device.

```bash
# 1. Confirm the contract before trusting any write-up, including this one
mcode --version
mcode exec --help
mcode provider list --json

# 2. Isolate every attempt
git worktree add -q -b eval/<task>-a<n> ../wt-<task>-a<n>

# 3. One bounded run. --diagnostics-dir MUST be empty; keep stdout OUTSIDE it.
OUT=/tmp/run-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$OUT/diag"
mcode exec \
  --cwd "$WT" --prompt-mode coding --permission smart \
  --timeout 4m --max-steps 12 --output-format json \
  --diagnostics-dir "$OUT/diag" \
  "Fix <specific defect>. Run the tests and report real output." \
  > "$OUT/result.json" 2> "$OUT/stderr.log"

# 4. Score it yourself — never from the agent's summary
python3 test_something.py; echo "exit=$?"

# 5. Destroy the attempt
git worktree remove --force "$WT"
```

**Troubleshooting, all hit here:**

| Symptom | Cause | Fix |
|---|---|---|
| `Minimax Code interactive mode requires a TTY` | `mcode init` is interactive-only | Author `AGENTS.md` by hand, or run under `script -qec "mcode init ." /dev/null` |
| `Session Project could not be resolved` | init could not resolve the project | **Reproduced and unresolved on 0.6.3**; treat `init` as unverified |
| `--diagnostics-dir is invalid: ... must be empty` | dir contains the output file | write stdout to a sibling path |
| `exit 2`, 0-byte stdout | argument validation | check stderr before parsing JSON |
| `Insufficient available RAM to start safely` | `mobile-safe.py` floor | **Do not lower it.** Wait, or move to a Codespace |

**Rollback.** `mcode update` moves forward; to revert, pin the previous release directory under
`~/.minimax-code/releases/`. Do not delete `~/.minimax-code` or `~/.minimax` — the uninstall path
warns that older and custom layouts can overlap.

## 8. Optimized prompts

The measured failures are about *claims*, not code. These prompts force evidence.

**Bounded fix**

```
Fix <specific behaviour>.

Acceptance criteria: <observable outcomes>

Inspect the relevant files and tests first. Make the smallest scoped change.
Do not add dependencies or touch unrelated files.
Run the checks and paste their real output, including the exit code.
If a check could not run, say so explicitly — do not describe it as passing.
```

**Debugging**

```
Investigate: <log or reproduction>.

Reproduce it first, or state why reproduction is unavailable.
Separate the cause from the symptom. Add a regression test where practical.
Report observed facts separately from hypotheses.
```

**Review — enforce read-only externally**

```
Review this diff for correctness, regressions and security.

Do not edit files. Return findings in the conversation with file/line references.
Mark each finding confirmed or needs-testing.
```

For genuinely read-only review, restrict filesystem access at the environment level. Do not rely on
the prompt: `--permission off` is documented inconsistently across sources, and a prompt is not a
boundary.

## 9. Security and cost controls

Before pointing this at anything proprietary:

- **`dataContribution.enabled` is `true` by default on this install.** Decide it deliberately.
- `memory.enabled` is `false` here — persistent memory would widen the blast radius if enabled.
- No third-party API key is configured, so the managed OAuth path is the only credential in play.
  Nothing was printed, written, or committed.
- Permission prompts are **not** OS-enforced containment. Worktrees isolate *changes*, not *reads*.
- A `--max-steps` bound is a real budget control; `--timeout` is a real time control. Use both.
- **Cost:** ~30k input tokens per trivial task. For anything long-running, budget input explicitly —
  it is ~99% of the tokens and it does not shrink with task size.

For EU/Belgium use, do not infer GDPR suitability from a provider's region selector or marketing.
Retention terms and processing location need checking against the specific product's terms.

## 10. Alternatives

| Tool | When it wins |
|---|---|
| **`mcode` 0.6.3** | Bounded headless runs where the JSON contract and worktree isolation matter |
| **An editor-native agent** | Tight edit/compile/debug loops where TUI context switching costs more than it saves |
| **A plain shell + a real test suite** | When acceptance is already automated — the agent adds cost, not confidence |

The honest comparison: on a two-file Python repo with a real failing test, `mcode` passed 3/3 and
cost ~30k tokens per attempt. If your acceptance is already a one-line command, the agent is
optional. Its value rises with task size and falls when the tests are already fast.

## 11. Prioritized roadmap

1. **First working setup** — pin 0.6.3, confirm `provider list`, one isolated worktree, one
   test-backed task, independently scored. *(Done; see §5.)*
2. **Reliability** — resolve `mcode init`, or drop it from the workflow and hand-write `AGENTS.md`.
   Re-test with a third-party provider once a key exists.
3. **Performance** — only after step 2, measure whether `--effort` earns its tokens.
4. **Coverage** — the Flutter, TypeScript, Lua and Supabase families need a machine with the
   toolchains. This is the largest open gap, and it is an environment gap, not an agent verdict.

## 12. Evidence gaps

- **`mcode init` is broken here and unexplained.** Highest-priority follow-up.
- Flutter, Tauri packaging, TypeScript, Lua, Supabase migrations: **no evidence at all.**
- No third-party provider or local-inference path exercised — no key configured.
- Sample size is small; 3/3 on one task family is not a capability estimate.
- Run-to-run variance measured within one task type only (27–60 s for identical work).
- Published pricing and model benchmark scores **not re-verified** in this pass.

---

*Every measured number traces to `docs/evidence/`. Anything not measured is labelled UNVERIFIED
rather than asserted — see [`docs/evidence/README.md`](evidence/README.md) §7.*
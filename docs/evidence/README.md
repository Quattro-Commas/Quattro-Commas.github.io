# Evidence appendix — MiniMax Code (`mcode`) 0.6.3

Captured **2026-10-07** on an ARM64 Linux device (Termux proot). Every number below was measured
here. Anything not measured is labelled **UNVERIFIED** rather than asserted.

This file exists because the studio's rule is that a published number must come from a query, or it
does not get published. Where a measurement contradicts a widely-copied claim, both are recorded and
the correction is stated.

## 1. Environment provenance

Captured by `docs/evidence/environment.txt`:

| Field | Measured value |
|---|---|
| `mcode --version` | **0.6.3** |
| `mcode` path | `/root/.minimax-code/bin/mcode` |
| Bundled Node runtime | **v24.19.0** (`~/.minimax-code/runtime/node-v24.19.0-linux-arm64`) |
| System Node | v22.22.1 |
| npm (system) | 10.9.4 |
| `pnpm` | **absent** |
| `~/.minimax-code/current` | `0.6.3` |
| Studio `origin/main` at clone time | `60a80be7d914030f279b38e17fd10fafa63142b9` |
| RAM total | 3653 MiB |
| RAM available at capture | 647 MiB |
| Captured (UTC) | 2026-10-07T12:23:13Z |

### Correction to a widely-copied premise

A prior write-up of this tool reasoned around a **`0.4.12`** source baseline and hedged against a
`0.6.2` issue report. The installed binary here is **0.6.3**. Any guidance written against 0.4.12
predates the surface documented below by two minor releases. Re-verify before trusting it.

## 2. Provider and auth state

From `mcode provider list --json` (no key values exist to leak — see below):

```json
{
  "minimaxModelSource": "token_plan",
  "providers": [
    {"providerId": "minimax_oauth", "active": true, "readOnly": true,  "hasApiKey": false},
    {"providerId": "minimax_api",   "active": false, "readOnly": false, "hasApiKey": false}
  ]
}
```

- Active credential: managed OAuth on a **token plan**, not a per-token billed key.
- **No third-party API key is configured.** The custom-endpoint path (`mcode provider add`) is
  therefore documented but could not be exercised end-to-end here. That is a gap, not a success.
- Models present in `~/.minimax/config.yaml`: `MiniMax-M2.7`, `MiniMax-M2.7-highspeed`,
  `MiniMax-M3`, `MiniMax-M3.1-Flash-Preview`.

### Two switches worth knowing before you trust a private repo

| Switch | Value here | Meaning |
|---|---|---|
| `dataContribution.enabled` | **`true`** | The shipped default is to contribute data |
| `memory.enabled` | `false` | Persistent memory is off in this profile |

`dataContribution.enabled: true` is the default this device ships with. Anyone using this tool on
proprietary code should decide that setting deliberately rather than inherit it.

## 3. Verified CLI surface (0.6.3)

Full `--help` transcripts for twelve command paths are in `docs/evidence/cli-help/`. Every flag
mentioned in this report was read from that capture.

Beyond the commonly documented surface, **0.6.3 adds or exposes**:

| Flag / command | Verified effect |
|---|---|
| `mcode exec review` | Reviews staged, unstaged **and untracked** changes — a first-class diff reviewer |
| `--effort <level>` | Per-run reasoning effort override (also on `exec review`) |
| `--output-schema <schema>` | JSON Schema file or inline object constraining the final answer |
| `--diagnostics-dir <path>` | Save bounded execution diagnostics; **the directory must be empty** |
| `-o, --output-last-message <path>` | Write only the final message to a file |
| `--input` / `--input-format` | `text` or `json`; only `-` is supported as the source |
| `--file <path>` | Attach a file (repeatable) |
| `--lane <lane>` | Managed backend lane for test/staging builds |
| `--tui-mode <mode>` | `regular` (default) or `fullscreen` |
| `--config <path>` | Explicit runtime config for this process |
| `--system-prompt-file` / `--append-system-prompt-file` | Replace or extend the agent identity prompt |
| `mcode init [directory]` | Generate `AGENTS.md` via the Runtime init skill |
| `mcode provider test <id>` | Test a provider or one configured model (`--json`) |
| `mcode provider use <source>` | `token-plan` or `api-key` |

`provider add` defaults `--api-format` to `anthropic-messages`; the alternatives are
`openai-completions` and `openai-responses`. `mcode login` takes `--region cn|global` and
`--no-browser`.

## 4. Reproduction: what worked and what did not

### 4.1 `mcode exec` — works, and returns a machine-readable contract

A single bounded read-only run:

```bash
mcode exec \
  --cwd "$WT" --prompt-mode coding --permission smart \
  --timeout 4m --max-steps 6 --output-format json \
  --diagnostics-dir "$EMPTY_DIR" \
  "List the functions defined in src/calc.py. Do not modify any file."
```

**Exit 0.** The JSON contract (`schemaVersion: 1`, `type: exec.result`) carries:

| Field | Observed value |
|---|---|
| `status` | `succeeded` |
| `model.modelId` | `MiniMax-M3.1-Flash-Preview` |
| `model.variant` | `thinking` |
| `usage` | input 28688 · output 132 · cacheRead 559 · total 28820 |
| `usageIncomplete` | `false` |
| `durationMs` | 6631 |

`usageIncomplete` is a first-class honesty signal: a caller can tell a truncated run from a whole
one without reading prose.

**Two real constraints found the hard way:**

1. `--diagnostics-dir` **must point at an empty directory**. Pointing it at a directory you also
   redirect stdout into fails with `exit 2` and
   `--diagnostics-dir is invalid: Diagnostics directory must be empty.` Write results to a sibling
   path.
2. `mcode exec` requires no TTY; `mcode init` **does**.

### 4.2 `mcode init` — failed here, and this is a reportable defect

Run under an allocated pty (`script -qec "mcode init ." /dev/null`) against a clean 2-file git
worktree, it:

- launched the full interactive TUI rather than a non-interactive init flow,
- hung at `Loading` while spinning up a session,
- emitted `× Error — The response failed. Reason: Session Project could not be resolved`,
- then **sat idle until the 420 s timeout killed it (exit 124)**,
- and **produced no `AGENTS.md`**.

Verified afterwards: no `AGENTS.md` in the worktree; worktree still clean; fixture commit unchanged.

So on 0.6.3, **`mcode init .` did not work unattended.** It needs a TTY, and under a pty it did not
complete. Treat "run `mcode init .` to bootstrap project instructions" as unproven on this device
until a human repeats it interactively. The TUI did surface these in-session commands, which do not
appear in `--help`: `/feedback` (preview a redacted report before upload), `/permission`,
`/sessions`, `/plugins`, `/goal`, `/context`, `/steer`, `/fork`, `/rewind`, `/compact`, `/skills`,
`/changelog`.

## 5. Benchmark results

Method: each attempt builds its own git worktree from an identical commit, runs one bounded
`mcode exec`, then scores the result by **re-running the acceptance command from scratch**. The
agent's own summary is recorded but never decides the verdict. Incomplete evidence scores
`UNKNOWN`. Raw rows: `docs/evidence/results.jsonl`.

### Task `bugfix-vowels` — case-sensitivity bug in `count_vowels`

Fix a one-line case-handling defect in `src/strutil.py`. Acceptance: `python3 test_strutil.py`,
which fails beforehand (`vowels uppercase: got 0, want 5`).

| Attempt | Exit | Agent status | **Independent verdict** | Total tokens | Wall |
|---|---|---|---|---|---|
| 1 | 0 | succeeded | **PASS** | 30660 | 27 s |
| 2 | 0 | succeeded | **PASS** | 31672 | 60 s |
| 3 | 0 | succeeded | **PASS** | 28987 | 36 s |

**3/3 accepted.** Every attempt made exactly one file change. The fix was minimal and matched the
docstring. Isolation held: the fixture repo remained at `aa5e226` with no stray branches after all
three worktrees were removed.

### Cost shape actually observed

- ~29k–32k **input** tokens for a trivial 2-file repository, against ~100–200 output tokens.
- The input cost is dominated by system prompt, tool definitions, and session scaffolding — it does
  **not** shrink with task difficulty.
- Wall time 27–60 s for a single-line fix.
- Because the active credential is a **token plan**, no per-task USD figure can be honestly quoted
  from this evidence. The widely-repeated MiniMax price table was **not re-verified in this pass**
  and is not restated here as fact.

## 6. Benchmark scope actually executed

| Wave | Planned | Executed | Location |
|---|---|---|---|
| A — local verification | 6 steps | **6** | local |
| B1 pilot | 9 | see `results.jsonl` | local |
| B2 local wave | 42 | **not run** | local |
| B3 remaining | 78 | **NOT RUN — blocked** | Codespace |

**Why 78 runs did not happen.** `flutter`, `dart`, `tsc`, `lua`, `docker`, `psql` and `supabase` are
all absent on this device, and available RAM (~519–690 MiB observed) sits below the 768 MiB start
threshold `codrax/scripts/mobile-safe.py` enforces. That threshold was not lowered. Running the
Flutter, TypeScript, Lua and Supabase families here would have required installing multi-GB
toolchains into a memory-constrained proot — the environment, not the agent, would have produced the
result. Those tasks require a Codespace, and starting one needs separate owner approval because it
burns core-hours.

Reported honestly: **this is a partial evaluation.** It covers a small Python correctness family
well and says nothing yet about Flutter, Tauri packaging, TypeScript, Lua, or database migrations.

## 7. Not verified in this pass

Carried forward unverified rather than restated as fact:

- Published MiniMax pricing for the cited models.
- SWE-bench Verified / Pro scores attributed to the model family.
- Upstream issue reports (#400–#441 in the prior write-up) — titles only, not reproduced.
- Any custom-endpoint or local-inference profile — no third-party key is configured here.
- `mcode init` in interactive human hands.
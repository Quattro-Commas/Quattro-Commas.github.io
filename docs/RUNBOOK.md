# RUNBOOK

## Serve locally
```bash
cd ~/quattro-commas.github.io
python3 -m http.server 8177 --bind 127.0.0.1
# open http://127.0.0.1:8177/            (studio one-pager, EN)
# open http://127.0.0.1:8177/aanbod.html (freelance offer, NL)
```

## Verify (run before any push proposal)
```bash
bash scripts/verify.sh
```
Checks, all offline: serves the repo root on a scratch port, resolves every
internal href/src found in index.html and aanbod.html, asserts required
content markers (nav link, packages, honest block, contact), prints
PASS/FAIL per check, exits non-zero on any failure.

Negative test (prove the checker can fail):
```bash
bash scripts/verify.sh --negative   # expects: one deliberately broken check FAILs, exit 1
```

## Publish (needs explicit user go — publishes live immediately)
```bash
git add <files> && git commit   # attribution per repo convention
git push origin agent/first-usable-release   # optional review step
git switch main && git merge --ff-only agent/first-usable-release && git push origin main
```
GitHub Pages serves `main` at https://quattro-commas.github.io within ~1 min.

## Post-publish smoke
- Load / and /aanbod.html in a browser; check console for errors.
- Confirm the new link appears in the contact block.

## Model/provider notes (Crush)
- Verified route: large=glm-5.3-flash (zai), small=deepseek-v4.1-flash (hyper).
- No Mistral provider configured in Crush; the Vibe subscription stays a
  separate surface. Do not assume a Mistral key would bill against Vibe.
- Global config: ~/.config/crush/crush.json (MCP + LSP) merged with
  ~/.config/crush/crushrc (permissions: view/ls/grep auto-approved; metrics
  off). Backups: crush.json.backup-20261017-030500 in the same directory.
- Trust rule: both config formats are executable at load. Inspect any
  project-local .crushrc / crushrc / .crush.json / crush.json before opening
  an unfamiliar repo in Crush. This repo had none at setup time.

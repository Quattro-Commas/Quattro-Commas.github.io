#!/usr/bin/env bash
# Local offline verification for this site. See docs/RUNBOOK.md.
# Usage:
#   bash scripts/verify.sh             # full check suite; exit 0 = all PASS
#   bash scripts/verify.sh --negative  # prove the checker detects breakage; exit 1 expected
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${VERIFY_PORT:-8177}"
NEGATIVE=0
[ "${1:-}" = "--negative" ] && NEGATIVE=1

FAILED=0

say_pass() { printf 'PASS  %s\n' "$1"; }
say_fail() { printf 'FAIL  %s\n' "$1"; FAILED=1; }

python3 - "$ROOT" "$PORT" <<'PY' &
import http.server, socketserver, threading, functools, sys, os, time
root, port = sys.argv[1], int(sys.argv[2])
socketserver.TCPServer.allow_reuse_address = True
class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass
httpd = socketserver.TCPServer(("127.0.0.1", port), functools.partial(QuietHandler, directory=root))
threading.Thread(target=httpd.serve_forever, daemon=True).start()
time.sleep(0.4)
open(os.path.join(root, ".verify-port"), "w").write(str(port))
try:
    while True: time.sleep(3600)
except KeyboardInterrupt:
    pass
PY
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null; rm -f "$ROOT/.verify-port"' EXIT

# Wait until the server answers.
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if python3 -c "import urllib.request,sys; urllib.request.urlopen('http://127.0.0.1:${PORT}/', timeout=1)" 2>/dev/null; then
    break
  fi
  sleep 0.3
done

check_url() { # 0 = reachable 200, 1 = not
  python3 - "$1" <<'PY'
import sys, urllib.request, urllib.error
url = sys.argv[1]
try:
    with urllib.request.urlopen(url, timeout=5) as r:
        sys.exit(0 if r.status == 200 else 1)
except Exception:
    sys.exit(1)
PY
}

extract_internal_links() { # print deduplicated internal href/src targets from a served page
  python3 - "$1" <<'PY'
import sys, urllib.request
from html.parser import HTMLParser
class P(HTMLParser):
    def __init__(self):
        super().__init__(); self.out = set()
    def handle_starttag(self, tag, attrs):
        for k, v in attrs:
            if k in ("href", "src") and v:
                if v.startswith(("mailto:", "http://", "https://", "data:", "#")):
                    continue
                self.out.add("/" + v.lstrip("/"))
p = P()
p.feed(urllib.request.urlopen(sys.argv[1], timeout=5).read().decode("utf-8", "replace"))
print("\n".join(sorted(p.out)))
PY
}

page_body() { python3 -c "import urllib.request,sys; print(urllib.request.urlopen('http://127.0.0.1:${PORT}$1', timeout=5).read().decode('utf-8','replace'))"; }

expect_body_contains() { # $1 page path, $2 needle, $3 label
  if page_body "$1" 2>/dev/null | grep -qF -- "$2"; then say_pass "$3"; else say_fail "$3"; fi
}

echo "== verify.sh on port ${PORT} (root: ${ROOT}) =="

# 1. Pages reachable
check_url "http://127.0.0.1:${PORT}/"             && say_pass "index.html served (200)"             || say_fail "index.html served (200)"
check_url "http://127.0.0.1:${PORT}/aanbod.html"  && say_pass "aanbod.html served (200)"            || say_fail "aanbod.html served (200)"

# 2. Required content markers
expect_body_contains "/"      'href="/aanbod.html"'                       "index links to /aanbod.html"
expect_body_contains "/"      "Open to AI engineering roles"              "index contact block intact"
expect_body_contains "/"      "No customers, no funding"                  "index honest-scope block intact"
expect_body_contains "/aanbod.html" "Bewijsbaar werkend"                  "aanbod hero intact"
expect_body_contains "/aanbod.html" "bakerstreetbandit@zohomail.eu"       "aanbod contact intact"
expect_body_contains "/aanbod.html" "Peppol-conforme e-facturatie"        "aanbod Peppol term intact"

# 3. Every internal link/asset resolves
LINKS="$( { extract_internal_links "http://127.0.0.1:${PORT}/" 2>/dev/null; extract_internal_links "http://127.0.0.1:${PORT}/aanbod.html" 2>/dev/null; } | sort -u )"
BAD=0
while IFS= read -r path; do
  [ -z "$path" ] && continue
  if check_url "http://127.0.0.1:${PORT}${path}"; then
    say_pass "internal ${path}"
  else
    say_fail "internal ${path} (not 200)"
    BAD=1
  fi
done <<< "$LINKS"
[ "$BAD" -eq 0 ] || true  # per-link failures already flagged

# 4. Negative mode: prove the detector detects. Always exits 1 when the
#    detector works (RUNBOOK contract); exits 2 if the detector itself broke.
if [ "$NEGATIVE" -eq 1 ]; then
  if check_url "http://127.0.0.1:${PORT}/definitief-niet-bestaan-verify-negative.html"; then
    say_fail "detector broken: a missing page reported reachable"
    exit 2
  fi
  say_pass "detector correctly reports a missing page as broken"
  echo "== NEGATIVE MODE: expected failure confirmed =="
  exit 1
fi

echo "== summary =="
if [ "$FAILED" -eq 0 ]; then echo "ALL CHECKS PASS"; exit 0; else echo "CHECKS FAILED"; exit 1; fi

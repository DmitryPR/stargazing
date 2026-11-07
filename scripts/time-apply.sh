#!/usr/bin/env bash
# Send the accepted sky time to Stellarium.
# Writes output/set-sky-time/03-apply.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir set-sky-time)"
proposal="${out_dir}/02-proposed.md"
out="${out_dir}/03-apply.md"

if [[ ! -f "$proposal" ]]; then
  printf 'no proposal. Run bash scripts/time-propose.sh first.\n' >&2
  exit 1
fi

if [[ -f "$out" ]] && grep -q '^status: ok$' "$out"; then
  printf 'this run already applied a sky time. Start a new run to change it again.\n' >&2
  exit 1
fi

url="$(stellarium_url)"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

eval "$(python3 - "$proposal" <<'PY'
import shlex
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
if not text.startswith("---\n"):
    raise SystemExit("proposal has no front matter")
end = text.find("\n---", 4)
front = {}
for line in text[4:end].splitlines():
    if not line.strip() or ":" not in line:
        continue
    key, value = line.split(":", 1)
    front[key.strip()] = value.strip().strip('"')

if front.get("status") != "review":
    raise SystemExit("proposal is not an accepted instant")
if not front.get("jday"):
    raise SystemExit("proposal has no Julian day")

for key in ("jday", "timerate", "utc", "local", "label"):
    print(f"{key}={shlex.quote(front.get(key, ''))}")
PY
)"

if ! stellarium_curl -X POST \
  --data-urlencode "time=${jday}" \
  --data-urlencode "timerate=${timerate}" \
  "${url}/api/main/time" >"$body_file"; then
  reply="$(cat "$body_file" 2>/dev/null || true)"
  cat >"$out" <<EOF
---
stage: apply
status: failed
jday: ${jday}
timerate: ${timerate}
utc: "${utc}"
local: "${local}"
label: "${label}"
---

The connector did not accept the sky time.

${reply}
EOF
  exit 1
fi

JDAY_VALUE="$jday" \
TIMERATE_VALUE="$timerate" \
UTC_VALUE="$utc" \
LOCAL_VALUE="$local" \
LABEL_VALUE="$label" \
python3 - "$body_file" "$out" <<'PY'
import os
import sys
from pathlib import Path

reply = Path(sys.argv[1]).read_text().strip() or "(empty)"
failed = reply.startswith("error:")

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

text = f"""---
stage: apply
status: {"failed" if failed else "ok"}
jday: {os.environ["JDAY_VALUE"]}
timerate: {os.environ["TIMERATE_VALUE"]}
utc: {q(os.environ["UTC_VALUE"])}
local: {q(os.environ["LOCAL_VALUE"])}
label: {q(os.environ["LABEL_VALUE"])}
---

Sky time sent:

- Label: {os.environ["LABEL_VALUE"]}
- Local: {os.environ["LOCAL_VALUE"]}
- UTC: {os.environ["UTC_VALUE"]}
- Julian day: {os.environ["JDAY_VALUE"]}
- Timerate: {os.environ["TIMERATE_VALUE"]}

Connector reply: {reply}
"""
Path(sys.argv[2]).write_text(text)
print("ok" if not failed else reply)
raise SystemExit(1 if failed else 0)
PY

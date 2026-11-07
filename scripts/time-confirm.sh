#!/usr/bin/env bash
# Read the simulation time back and compare it with the proposal.
# Writes output/set-sky-time/04-confirm.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir set-sky-time)"
proposal="${out_dir}/02-proposed.md"
applied="${out_dir}/03-apply.md"
out="${out_dir}/04-confirm.md"

if [[ ! -f "$applied" ]]; then
  printf 'no apply result. Run bash scripts/time-apply.sh first.\n' >&2
  exit 1
fi

url="$(stellarium_url)"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl "${url}/api/main/status" >"$body_file"; then
  printf 'failed: %s\n' "$url" >&2
  exit 1
fi

python3 - "$proposal" "$applied" "$body_file" "$out" <<'PY'
import json
import sys
from pathlib import Path

def front_matter(path):
    text = Path(path).read_text()
    if not text.startswith("---\n"):
        raise SystemExit(f"{path} has no front matter")
    end = text.find("\n---", 4)
    front = {}
    for line in text[4:end].splitlines():
        if not line.strip() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        front[key.strip()] = value.strip().strip('"')
    return front

proposal, applied, body_path, out_path = sys.argv[1:]
proposed = front_matter(proposal)
apply_result = front_matter(applied)
if apply_result.get("status") != "ok":
    raise SystemExit("apply did not succeed")

status = json.loads(Path(body_path).read_text())
time_info = status.get("time") or {}
jday = time_info.get("jday")
timerate = time_info.get("timerate")
try:
    jday_ok = abs(float(jday) - float(proposed.get("jday"))) <= (1 / 86400)
except (TypeError, ValueError):
    jday_ok = False
try:
    rate_ok = abs(float(timerate)) <= 1e-8
except (TypeError, ValueError):
    rate_ok = False
matched = jday_ok and rate_ok

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def shown(value):
    if value is None or value == "":
        return "(none)"
    return str(value)

differences = []
if not jday_ok:
    differences.append("jday")
if not rate_ok:
    differences.append("timerate")
difference_line = ", ".join(differences) if differences else "(none)"
text = f"""---
stage: confirm
status: {"match" if matched else "mismatch"}
local: {q(time_info.get("local") or "")}
utc: {q(time_info.get("utc") or "")}
jday: {jday if isinstance(jday, (int, float)) else '""'}
timerate: {timerate if isinstance(timerate, (int, float)) else '""'}
---

Stellarium now reports:

- Local: {shown(time_info.get("local"))}
- UTC: {shown(time_info.get("utc"))}
- Julian day: {shown(jday)}
- Timerate: {shown(timerate)}

Matches the accepted sky time: {"yes" if matched else "no"}
Fields that differ: {difference_line}

The person checks this against the Stellarium window.
"""
Path(out_path).write_text(text)
print("match" if matched else "mismatch")
raise SystemExit(0 if matched else 2)
PY

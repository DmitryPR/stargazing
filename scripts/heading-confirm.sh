#!/usr/bin/env bash
# Read the view heading back and compare it with the proposal.
# Writes output/set-heading/04-confirm.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir set-heading)"
proposal="${out_dir}/02-proposed.md"
applied="${out_dir}/03-apply.md"
out="${out_dir}/04-confirm.md"

if [[ ! -f "$applied" ]]; then
  printf 'no apply result. Run bash scripts/heading-apply.sh first.\n' >&2
  exit 1
fi

url="$(stellarium_url)"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl "${url}/api/main/view?coord=altAz" >"$body_file"; then
  printf 'failed: %s\n' "$url" >&2
  exit 1
fi

python3 - "$proposal" "$applied" "$body_file" "$out" <<'PY'
import json
import math
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

def plain(value):
    return f"{value:.10f}".rstrip("0").rstrip(".")

def wrap_delta(left, right):
    return abs((float(left) - float(right) + 180.0) % 360.0 - 180.0)

proposal, applied, body_path, out_path = sys.argv[1:]
proposed = front_matter(proposal)
apply_result = front_matter(applied)
if apply_result.get("status") != "ok":
    raise SystemExit("apply did not succeed")

payload = json.loads(Path(body_path).read_text())
raw = payload.get("altAz")
if isinstance(raw, str):
    vector = json.loads(raw)
elif isinstance(raw, list):
    vector = raw
else:
    raise SystemExit("view response has no altAz vector")
x, y, z = (float(part) for part in vector)
length = math.hypot(x, y, z)
if length == 0:
    raise SystemExit("altAz vector has length 0")
heading = (180.0 - math.degrees(math.atan2(y, x))) % 360.0
look_altitude = math.degrees(math.asin(max(-1.0, min(1.0, z / length))))

heading_ok = wrap_delta(heading, proposed.get("heading")) <= 0.01
look_ok = abs(look_altitude - float(proposed.get("look_altitude"))) <= 0.01
matched = heading_ok and look_ok
mismatches = []
if not heading_ok:
    mismatches.append("heading")
if not look_ok:
    mismatches.append("look_altitude")
mismatch_line = ", ".join(mismatches) if mismatches else "(none)"
names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
cardinal = names[int((heading + 22.5) // 45) % 8]
text = f"""---
stage: confirm
status: {"match" if matched else "mismatch"}
heading: {plain(heading)}
cardinal: "{cardinal}"
look_altitude: {plain(look_altitude)}
---

Stellarium now reports:

- Heading: {plain(heading)}°
- Cardinal: {cardinal}
- Look altitude: {plain(look_altitude)}°

Matches the accepted heading: {"yes" if matched else "no"}
Fields that differ: {mismatch_line}
Tolerance: 0.01°

The person checks this against the Stellarium window.
"""
Path(out_path).write_text(text)
print("match" if matched else "mismatch")
raise SystemExit(0 if matched else 2)
PY

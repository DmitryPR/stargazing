#!/usr/bin/env bash
# Read the observer location back and compare it with the proposal.
# Writes output/set-location/04-confirm.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir set-location)"
proposal="${out_dir}/02-proposed.md"
applied="${out_dir}/03-apply.md"
out="${out_dir}/04-confirm.md"

if [[ ! -f "$applied" ]]; then
  printf 'no apply result. Run bash scripts/location-apply.sh first.\n' >&2
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
location = status.get("location") or {}

def close(left, right, tolerance):
    try:
        return abs(float(left) - float(right)) <= tolerance
    except (TypeError, ValueError):
        return False

checks = {
    "latitude": close(location.get("latitude"), proposed.get("latitude"), 0.0001),
    "longitude": close(location.get("longitude"), proposed.get("longitude"), 0.0001),
    "altitude": close(location.get("altitude"), proposed.get("altitude"), 1),
    "name": (location.get("name") or "") == proposed.get("name", ""),
    "planet": (location.get("planet") or "").casefold() == proposed.get("planet", "").casefold(),
    "region": (location.get("region") or "") == proposed.get("region", ""),
}
matched = all(checks.values())

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def shown(value, suffix=""):
    if value is None or value == "":
        return "(none)"
    return f"{value}{suffix}"

mismatches = [key for key, ok in checks.items() if not ok]
mismatch_line = ", ".join(mismatches) if mismatches else "(none)"
text = f"""---
stage: confirm
status: {"match" if matched else "mismatch"}
name: {q(location.get("name") or "")}
latitude: {location.get("latitude") if isinstance(location.get("latitude"), (int, float)) else '""'}
longitude: {location.get("longitude") if isinstance(location.get("longitude"), (int, float)) else '""'}
altitude: {location.get("altitude") if isinstance(location.get("altitude"), (int, float)) else '""'}
planet: {q(location.get("planet") or "")}
region: {q(location.get("region") or "")}
---

Stellarium now reports:

- Name: {shown(location.get("name"))}
- Latitude: {shown(location.get("latitude"), "°")}
- Longitude: {shown(location.get("longitude"), "°")}
- Altitude: {shown(location.get("altitude"), " m")}
- Planet: {shown(location.get("planet"))}
- Region: {shown(location.get("region"))}

Matches the accepted custom location: {"yes" if matched else "no"}
Fields that differ: {mismatch_line}

The person checks this against the Stellarium window.
"""
Path(out_path).write_text(text)
print("match" if matched else "mismatch")
raise SystemExit(0 if matched else 2)
PY

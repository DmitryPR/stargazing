#!/usr/bin/env bash
# Record a compass heading beside the current one. Does not call Stellarium.
# Writes output/set-heading/02-proposed.md
# Exit 2 so the person can review before apply.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

heading=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --heading)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for %s\n' "$1" >&2
        exit 1
      fi
      heading="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      printf 'usage: bash scripts/heading-propose.sh --heading <degrees>\n' >&2
      exit 1
      ;;
  esac
done

if [[ -z "$heading" ]]; then
  printf 'usage: bash scripts/heading-propose.sh --heading <degrees>\n' >&2
  exit 1
fi

out_dir="$(ensure_output_dir set-heading)"
current="${out_dir}/01-current.md"
out="${out_dir}/02-proposed.md"

if [[ ! -f "$current" ]]; then
  printf 'current heading has not been read. Run bash scripts/heading-current.sh first.\n' >&2
  exit 1
fi

HEADING_VALUE="$heading" python3 - "$current" "$out" <<'PY'
import math
import os
import sys
from pathlib import Path

current_path, out_path = sys.argv[1:]
text = Path(current_path).read_text()
if not text.startswith("---\n"):
    raise SystemExit("current heading file has no front matter")
end = text.find("\n---", 4)
if end < 0:
    raise SystemExit("current heading file has no front matter")
front = {}
for line in text[4:end].splitlines():
    if not line.strip() or ":" not in line:
        continue
    key, value = line.split(":", 1)
    front[key.strip()] = value.strip().strip('"')

if front.get("status") != "connected":
    raise SystemExit("current heading was not read. Run bash scripts/heading-current.sh again.")

try:
    supplied = float(os.environ["HEADING_VALUE"])
except ValueError:
    raise SystemExit("heading must be a number of degrees")
if not math.isfinite(supplied) or supplied < 0 or supplied > 360:
    raise SystemExit("heading must be between 0 and 360")

heading = 0.0 if supplied == 360 else supplied
az_radians = math.radians(180.0 - heading)

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def plain(value):
    return f"{value:.10f}".rstrip("0").rstrip(".")

def shown(value, suffix=""):
    if value is None or value == "":
        return "(none)"
    return f"{value}{suffix}"

names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
cardinal = names[int((heading + 22.5) // 45) % 8]
body = f"""---
stage: propose
status: review
current_heading: {front.get("heading", '""')}
current_cardinal: {q(front.get("cardinal", ""))}
current_look_altitude: {front.get("look_altitude", '""')}
supplied: {plain(supplied)}
heading: {plain(heading)}
cardinal: {q(cardinal)}
look_altitude: {front.get("look_altitude", '""')}
az_radians: {f"{az_radians:.16f}".rstrip("0").rstrip(".")}
---

Current view heading:

- Heading: {shown(front.get("heading", ""), "°")}
- Cardinal: {shown(front.get("cardinal", ""))}
- Look altitude: {shown(front.get("look_altitude", ""), "°")}

Target view heading:

- Heading: {plain(heading)}°
- Cardinal: {cardinal}
- Look altitude: {shown(front.get("look_altitude", ""), "°")} (unchanged)
- Connector az: {f"{az_radians:.16f}".rstrip("0").rstrip(".")} radians

The person accepts or rejects this heading before it is sent.
"""
Path(out_path).write_text(body)
print("review")
raise SystemExit(2)
PY

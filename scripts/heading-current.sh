#!/usr/bin/env bash
# Read the current view heading. Does not change Stellarium.
# Writes output/set-heading/01-current.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

url="$(stellarium_url)"
out="$(ensure_output_dir set-heading)/01-current.md"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl "${url}/api/main/view?coord=altAz" >"$body_file"; then
  cat >"$out" <<EOF
---
stage: current
status: failed
url: ${url}
---

The Remote Control connector did not answer at ${url}.

In Stellarium, enable the Remote Control plugin and start its server. The default port is 8090.
EOF
  printf 'failed: %s\n' "$url" >&2
  exit 1
fi

STELLARIUM_URL_VALUE="$url" python3 - "$body_file" "$out" <<'PY'
import json
import math
import os
import sys
from pathlib import Path

body_path, out_path = sys.argv[1:]
payload = json.loads(Path(body_path).read_text())
raw = payload.get("altAz")
if isinstance(raw, str):
    vector = json.loads(raw)
elif isinstance(raw, list):
    vector = raw
else:
    raise SystemExit("view response has no altAz vector")
if len(vector) != 3:
    raise SystemExit("altAz vector must have 3 numbers")
x, y, z = (float(part) for part in vector)
length = math.hypot(x, y, z)
if length == 0:
    raise SystemExit("altAz vector has length 0")
heading = (180.0 - math.degrees(math.atan2(y, x))) % 360.0
look_altitude = math.degrees(math.asin(max(-1.0, min(1.0, z / length))))

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def plain(value):
    return f"{value:.10f}".rstrip("0").rstrip(".")

names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
cardinal = names[int((heading + 22.5) // 45) % 8]
vector_text = "[" + ", ".join(plain(part) for part in (x, y, z)) + "]"
text = f"""---
stage: current
status: connected
url: {q(os.environ["STELLARIUM_URL_VALUE"])}
heading: {plain(heading)}
cardinal: {q(cardinal)}
look_altitude: {plain(look_altitude)}
vector: {q(vector_text)}
---

Current view heading:

- Heading: {plain(heading)}°
- Cardinal: {cardinal}
- Look altitude: {plain(look_altitude)}°
- altAz: {vector_text}
"""
Path(out_path).write_text(text)
print("connected")
PY

#!/usr/bin/env bash
# Read the current observer location. Does not change Stellarium.
# Writes output/set-location/01-current.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

url="$(stellarium_url)"
out="$(ensure_output_dir set-location)/01-current.md"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl "${url}/api/main/status" >"$body_file"; then
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
import os
import sys
from pathlib import Path

body_path, out_path = sys.argv[1:]
status = json.loads(Path(body_path).read_text())
location = status.get("location") or {}

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def line(value, suffix=""):
    if value is None or value == "":
        return "(none)"
    return f"{value}{suffix}"

name = location.get("name") or ""
latitude = location.get("latitude")
longitude = location.get("longitude")
altitude = location.get("altitude")
planet = location.get("planet") or ""
region = location.get("region") or ""

text = f"""---
stage: current
status: connected
url: {q(os.environ["STELLARIUM_URL_VALUE"])}
name: {q(name)}
latitude: {latitude if isinstance(latitude, (int, float)) else '""'}
longitude: {longitude if isinstance(longitude, (int, float)) else '""'}
altitude: {altitude if isinstance(altitude, (int, float)) else '""'}
planet: {q(planet)}
region: {q(region)}
---

Current observer location:

- Name: {line(name)}
- Latitude: {line(latitude, "°")}
- Longitude: {line(longitude, "°")}
- Altitude: {line(altitude, " m")}
- Planet: {line(planet)}
- Region: {line(region)}
"""
Path(out_path).write_text(text)
print("connected")
PY

#!/usr/bin/env bash
# Read the observer place for a local calendar. Does not change Stellarium.
# Writes output/local-calendar/01-place.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

url="$(stellarium_url)"
out="$(ensure_output_dir local-calendar)/01-place.md"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl "${url}/api/main/status" >"$body_file"; then
  cat >"$out" <<EOF
---
stage: place
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
time_info = status.get("time") or {}

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def shown(value, suffix=""):
    if value is None or value == "":
        return "(none)"
    return f"{value}{suffix}"

name = location.get("name") or ""
latitude = location.get("latitude")
longitude = location.get("longitude")
gmt_shift = time_info.get("gmtShift")
text = f"""---
stage: place
status: connected
url: {q(os.environ["STELLARIUM_URL_VALUE"])}
name: {q(name)}
latitude: {latitude if isinstance(latitude, (int, float)) else '""'}
longitude: {longitude if isinstance(longitude, (int, float)) else '""'}
timezone: {q(time_info.get("timeZone") or "")}
gmt_shift: {gmt_shift if isinstance(gmt_shift, (int, float)) else '""'}
---

Observer place:

- Name: {shown(name)}
- Latitude: {shown(latitude, "°")}
- Longitude: {shown(longitude, "°")}
- Timezone: {shown(time_info.get("timeZone"))}
"""
Path(out_path).write_text(text)
print("connected")
PY

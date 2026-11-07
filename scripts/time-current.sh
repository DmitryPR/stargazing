#!/usr/bin/env bash
# Read the current simulation time. Does not change Stellarium.
# Writes output/set-sky-time/01-current.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

url="$(stellarium_url)"
out="$(ensure_output_dir set-sky-time)/01-current.md"
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
time_info = status.get("time") or {}
location = status.get("location") or {}

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def shown(value):
    if value is None or value == "":
        return "(none)"
    return str(value)

local = time_info.get("local") or ""
utc = time_info.get("utc") or ""
jday = time_info.get("jday")
gmt_shift = time_info.get("gmtShift")
timerate = time_info.get("timerate")
text = f"""---
stage: current
status: connected
url: {q(os.environ["STELLARIUM_URL_VALUE"])}
local: {q(local)}
utc: {q(utc)}
jday: {jday if isinstance(jday, (int, float)) else '""'}
timezone: {q(time_info.get("timeZone") or "")}
gmt_shift: {gmt_shift if isinstance(gmt_shift, (int, float)) else '""'}
timerate: {timerate if isinstance(timerate, (int, float)) else '""'}
is_time_now: {str(bool(time_info.get("isTimeNow"))).lower()}
location_name: {q(location.get("name") or "")}
---

Current simulation time:

- Place: {shown(location.get("name"))}
- Local: {shown(local)}
- UTC: {shown(utc)}
- Timezone: {shown(time_info.get("timeZone"))}
- Julian day: {shown(jday)}
- Timerate: {shown(timerate)}
- Running at real now: {"yes" if time_info.get("isTimeNow") else "no"}
"""
Path(out_path).write_text(text)
print("connected")
PY

#!/usr/bin/env bash
# Send the accepted custom location to Stellarium.
# Writes output/set-location/03-apply.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir set-location)"
proposal="${out_dir}/02-proposed.md"
out="${out_dir}/03-apply.md"

if [[ ! -f "$proposal" ]]; then
  printf 'no proposal. Run bash scripts/location-propose.sh first.\n' >&2
  exit 1
fi

if [[ -f "$out" ]] && grep -q '^status: ok$' "$out"; then
  printf 'this run already applied a location. Start a new run to change it again.\n' >&2
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
    raise SystemExit("proposal is not waiting for review")

required = ("latitude", "longitude", "altitude", "name", "planet", "region")
missing = [key for key in required if key not in front]
if missing:
    raise SystemExit("proposal is missing " + ", ".join(missing))

for key in required:
    print(f"{key}={shlex.quote(front[key])}")
PY
)"

if ! stellarium_curl -X POST \
  --data-urlencode "latitude=${latitude}" \
  --data-urlencode "longitude=${longitude}" \
  --data-urlencode "altitude=${altitude}" \
  --data-urlencode "name=${name}" \
  --data-urlencode "region=${region}" \
  --data-urlencode "planet=${planet}" \
  "${url}/api/location/setlocationfields" >"$body_file"; then
  reply="$(cat "$body_file" 2>/dev/null || true)"
  cat >"$out" <<EOF
---
stage: apply
status: failed
name: "${name}"
latitude: ${latitude}
longitude: ${longitude}
altitude: ${altitude}
planet: "${planet}"
region: "${region}"
---

The connector did not accept the custom location.

${reply}
EOF
  exit 1
fi

NAME_VALUE="$name" \
LATITUDE_VALUE="$latitude" \
LONGITUDE_VALUE="$longitude" \
ALTITUDE_VALUE="$altitude" \
PLANET_VALUE="$planet" \
REGION_VALUE="$region" \
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
name: {q(os.environ["NAME_VALUE"])}
latitude: {os.environ["LATITUDE_VALUE"]}
longitude: {os.environ["LONGITUDE_VALUE"]}
altitude: {os.environ["ALTITUDE_VALUE"]}
planet: {q(os.environ["PLANET_VALUE"])}
region: {q(os.environ["REGION_VALUE"])}
---

Custom location sent:

- Name: {os.environ["NAME_VALUE"]}
- Latitude: {os.environ["LATITUDE_VALUE"]}°
- Longitude: {os.environ["LONGITUDE_VALUE"]}°
- Altitude: {os.environ["ALTITUDE_VALUE"]} m
- Planet: {os.environ["PLANET_VALUE"]}
- Region: {os.environ["REGION_VALUE"] or "(none)"}

Connector reply: {reply}
"""
Path(sys.argv[2]).write_text(text)
print(reply)
raise SystemExit(1 if failed else 0)
PY

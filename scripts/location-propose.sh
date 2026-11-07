#!/usr/bin/env bash
# Record a custom location beside the current one. Does not call Stellarium.
# Writes output/set-location/02-proposed.md
# Exit 2 so the person can review before apply.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

latitude=""
longitude=""
altitude=""
name=""
region=""
planet=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latitude|--longitude|--altitude|--name|--region|--planet)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for %s\n' "$1" >&2
        exit 1
      fi
      case "$1" in
        --latitude) latitude="$2" ;;
        --longitude) longitude="$2" ;;
        --altitude) altitude="$2" ;;
        --name) name="$2" ;;
        --region) region="$2" ;;
        --planet) planet="$2" ;;
      esac
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      printf 'usage: bash scripts/location-propose.sh --latitude <degrees> --longitude <degrees> [--altitude <metres>] [--name <name>] [--region <region>] [--planet <planet>]\n' >&2
      exit 1
      ;;
  esac
done

if [[ -z "$latitude" || -z "$longitude" ]]; then
  printf 'usage: bash scripts/location-propose.sh --latitude <degrees> --longitude <degrees> [--altitude <metres>] [--name <name>] [--region <region>] [--planet <planet>]\n' >&2
  exit 1
fi

out_dir="$(ensure_output_dir set-location)"
current="${out_dir}/01-current.md"
out="${out_dir}/02-proposed.md"

if [[ ! -f "$current" ]]; then
  printf 'current location has not been read. Run bash scripts/location-current.sh first.\n' >&2
  exit 1
fi

LATITUDE_VALUE="$latitude" \
LONGITUDE_VALUE="$longitude" \
ALTITUDE_VALUE="$altitude" \
NAME_VALUE="$name" \
REGION_VALUE="$region" \
PLANET_VALUE="$planet" \
python3 - "$current" "$out" <<'PY'
import os
import sys
from pathlib import Path

current_path, out_path = sys.argv[1:]
text = Path(current_path).read_text()
if not text.startswith("---\n"):
    raise SystemExit("current location file has no front matter")
end = text.find("\n---", 4)
if end < 0:
    raise SystemExit("current location file has no front matter")
front = {}
for line in text[4:end].splitlines():
    if not line.strip() or ":" not in line:
        continue
    key, value = line.split(":", 1)
    front[key.strip()] = value.strip().strip('"')

if front.get("status") != "connected":
    raise SystemExit("current location was not read. Run bash scripts/location-current.sh again.")

def number(raw, label, low, high):
    try:
        value = float(raw)
    except ValueError:
        raise SystemExit(f"{label} must be a number")
    if value < low or value > high:
        raise SystemExit(f"{label} must be between {low} and {high}")
    return value

latitude = number(os.environ["LATITUDE_VALUE"], "latitude", -90, 90)
longitude = number(os.environ["LONGITUDE_VALUE"], "longitude", -180, 180)
altitude_raw = os.environ["ALTITUDE_VALUE"]
altitude = number(altitude_raw, "altitude", -2000, 20000) if altitude_raw else 0.0
planet = os.environ["PLANET_VALUE"] or front.get("planet") or "Earth"
name = os.environ["NAME_VALUE"] or f"{latitude:.2f}, {longitude:.2f}"
region = os.environ["REGION_VALUE"]

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def shown(value, suffix=""):
    if value is None or value == "":
        return "(none)"
    return f"{value}{suffix}"

body = f"""---
stage: propose
status: review
current_name: {q(front.get("name", ""))}
current_latitude: {front.get("latitude", '""')}
current_longitude: {front.get("longitude", '""')}
current_altitude: {front.get("altitude", '""')}
current_planet: {q(front.get("planet", ""))}
current_region: {q(front.get("region", ""))}
name: {q(name)}
latitude: {latitude}
longitude: {longitude}
altitude: {altitude}
planet: {q(planet)}
region: {q(region)}
---

Current observer location:

- Name: {shown(front.get("name", ""))}
- Latitude: {shown(front.get("latitude", ""), "°")}
- Longitude: {shown(front.get("longitude", ""), "°")}
- Altitude: {shown(front.get("altitude", ""), " m")}
- Planet: {shown(front.get("planet", ""))}
- Region: {shown(front.get("region", ""))}

Custom location:

- Name: {name}
- Latitude: {latitude}°
- Longitude: {longitude}°
- Altitude: {altitude} m
- Planet: {planet}
- Region: {shown(region)}

The person accepts or rejects this custom location before it is sent.
"""
Path(out_path).write_text(body)
print("review")
raise SystemExit(2)
PY

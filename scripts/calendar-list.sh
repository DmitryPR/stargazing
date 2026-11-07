#!/usr/bin/env bash
# List upcoming sky events visible at the current observer place.
# Writes output/local-calendar/02-calendar.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

days="366"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for --days\n' >&2
        exit 1
      fi
      days="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      printf 'usage: bash scripts/calendar-list.sh [--days <count>]\n' >&2
      exit 1
      ;;
  esac
done

out_dir="$(ensure_output_dir local-calendar)"
place="${out_dir}/01-place.md"
out="${out_dir}/02-calendar.md"
root="$(repo_root)"

if [[ ! -f "$place" ]]; then
  printf 'observer place has not been read. Run bash scripts/calendar-place.sh first.\n' >&2
  exit 1
fi

DAYS_VALUE="$days" REPO_ROOT="$root" python3 - "$place" "$out" <<'PY'
import math
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

place_path, out_path = sys.argv[1:]

def front_matter(path):
    body = Path(path).read_text()
    if not body.startswith("---\n"):
        return {}
    finish = body.find("\n---", 4)
    if finish < 0:
        return {}
    fields = {}
    for line in body[4:finish].splitlines():
        if not line.strip() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip().strip('"')
    return fields

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def parse_instant(raw):
    text_value = raw.strip()
    if text_value.count("-") < 2 or ":" not in text_value:
        raise ValueError("needs a date and a clock time")
    normalized = text_value.replace(" ", "T", 1)
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        raise ValueError("needs a timezone, for example Z")
    return parsed.astimezone(timezone.utc)

def distance_km(lat1, lon1, lat2, lon2):
    radius = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    chord = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlmb / 2) ** 2
    return 2 * radius * math.asin(math.sqrt(chord))

place = front_matter(place_path)
if place.get("status") != "connected":
    raise SystemExit("observer place was not read. Run bash scripts/calendar-place.sh again.")

try:
    days = int(os.environ["DAYS_VALUE"])
except ValueError:
    raise SystemExit("--days must be a whole number")
if days < 1 or days > 3660:
    raise SystemExit("--days must be from 1 to 3660")

try:
    place_lat = float(place.get("latitude", ""))
    place_lon = float(place.get("longitude", ""))
except ValueError:
    raise SystemExit("observer place has no coordinates")

now = datetime.now(timezone.utc).replace(microsecond=0)
until = now + timedelta(days=days)
gmt_shift = place.get("gmt_shift", "")
try:
    offset = timedelta(days=float(gmt_shift))
except ValueError:
    offset = timedelta(0)

def local_text(instant):
    return (instant + offset).strftime("%Y-%m-%dT%H:%M:%SZ").replace("Z", "")

included = []
skipped = []
events_dir = Path(os.environ["REPO_ROOT"]) / "knowledge" / "events"
paths = sorted(events_dir.glob("*.md")) if events_dir.is_dir() else []
for path in paths:
    fields = front_matter(path)
    title = fields.get("title") or path.stem
    try:
        instant = parse_instant(fields.get("utc", ""))
    except (ValueError, TypeError):
        skipped.append(f"- {title}: unreadable utc")
        continue
    if instant < now:
        skipped.append(f"- {title}: past")
        continue
    if instant >= until:
        skipped.append(f"- {title}: outside the window")
        continue
    visibility = (fields.get("visibility") or "").casefold()
    if visibility == "global":
        included.append((instant, title, "global", ""))
        continue
    if visibility != "local":
        skipped.append(f"- {title}: no visibility")
        continue
    try:
        event_lat = float(fields.get("latitude", ""))
        event_lon = float(fields.get("longitude", ""))
        radius = float(fields.get("radius_km", ""))
    except ValueError:
        skipped.append(f"- {title}: incomplete local visibility")
        continue
    if radius <= 0:
        skipped.append(f"- {title}: incomplete local visibility")
        continue
    distance = distance_km(place_lat, place_lon, event_lat, event_lon)
    if distance <= radius:
        included.append((instant, title, "local", f"{distance:.1f} km"))
    else:
        skipped.append(f"- {title}: {distance:.1f} km outside its radius")

included.sort(key=lambda item: item[0])
event_lines = []
for instant, title, kind, distance in included:
    where = "everywhere" if kind == "global" else distance
    event_lines.append(
        f"- {instant.strftime('%Y-%m-%dT%H:%M:%SZ')} UTC"
        f" ({local_text(instant)} local) — {title} ({where})"
    )
if not event_lines:
    event_lines.append("- (none)")
if not skipped:
    skipped.append("- (none)")

text = f"""---
stage: calendar
status: ready
name: {q(place.get("name", ""))}
latitude: {place.get("latitude", '""')}
longitude: {place.get("longitude", '""')}
from: {q(now.strftime("%Y-%m-%dT%H:%M:%SZ"))}
until: {q(until.strftime("%Y-%m-%dT%H:%M:%SZ"))}
days: {days}
count: {len(included)}
---

Upcoming sky events at {place.get("name") or "the observer place"}:

{chr(10).join(event_lines)}

Left out:

{chr(10).join(skipped)}

Local times use the connector's current timezone offset. The person checks this calendar. It does not change the sky.
"""
Path(out_path).write_text(text)
print(f"ready {len(included)}")
PY

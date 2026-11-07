#!/usr/bin/env bash
# Record a target sky time beside the current one. Does not call Stellarium.
# Writes output/set-sky-time/02-proposed.md
# Exit 2 so the person can review before apply.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

utc=""
local_time=""
event=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --utc|--local|--event)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for %s\n' "$1" >&2
        exit 1
      fi
      case "$1" in
        --utc) utc="$2" ;;
        --local) local_time="$2" ;;
        --event) event="$2" ;;
      esac
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

chosen=0
if [[ -n "$utc" ]]; then
  chosen=$((chosen + 1))
fi
if [[ -n "$local_time" ]]; then
  chosen=$((chosen + 1))
fi
if [[ -n "$event" ]]; then
  chosen=$((chosen + 1))
fi
if [[ "$chosen" -ne 1 ]]; then
  printf 'usage: bash scripts/time-propose.sh --utc "<ISO-8601>" | --local "<ISO-8601>" | --event "<name>"\n' >&2
  exit 1
fi

out_dir="$(ensure_output_dir set-sky-time)"
current="${out_dir}/01-current.md"
out="${out_dir}/02-proposed.md"
root="$(repo_root)"

if [[ ! -f "$current" ]]; then
  printf 'current time has not been read. Run bash scripts/time-current.sh first.\n' >&2
  exit 1
fi

UTC_VALUE="$utc" \
LOCAL_VALUE="$local_time" \
EVENT_VALUE="$event" \
REPO_ROOT="$root" \
python3 - "$current" "$out" <<'PY'
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

current_path, out_path = sys.argv[1:]
text = Path(current_path).read_text()
if not text.startswith("---\n"):
    raise SystemExit("current time file has no front matter")
end = text.find("\n---", 4)
if end < 0:
    raise SystemExit("current time file has no front matter")
front = {}
for line in text[4:end].splitlines():
    if not line.strip() or ":" not in line:
        continue
    key, value = line.split(":", 1)
    front[key.strip()] = value.strip().strip('"')

if front.get("status") != "connected":
    raise SystemExit("current time was not read. Run bash scripts/time-current.sh again.")

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

def julian_day(dt):
    dt = dt.astimezone(timezone.utc)
    year, month = dt.year, dt.month
    day = dt.day
    if month <= 2:
        year -= 1
        month += 12
    century = year // 100
    gregorian = 2 - century + century // 4
    fraction = (
        dt.hour + dt.minute / 60 + (dt.second + dt.microsecond / 1e6) / 3600
    ) / 24
    return (
        int(365.25 * (year + 4716))
        + int(30.6001 * (month + 1))
        + day
        + gregorian
        - 1524.5
        + fraction
    )

def parse_instant(raw, naive_tz):
    text_value = raw.strip()
    if text_value.count("-") < 2 or ":" not in text_value:
        raise SystemExit(
            "a sky time needs a date and a clock time, for example 2026-08-12T22:00:00"
        )
    normalized = text_value.replace(" ", "T", 1)
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError as error:
        raise SystemExit(f"could not read the clock time: {error}")
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=naive_tz)
    return parsed.astimezone(timezone.utc)

def event_front_matter(path):
    body = path.read_text()
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

gmt_shift = float(front.get("gmt_shift") or 0)
observer_tz = timezone(timedelta(days=gmt_shift))
source = "utc" if os.environ["UTC_VALUE"] else "local" if os.environ["LOCAL_VALUE"] else "event"
status = "review"
label = ""
note = ""
target_utc = None

if source == "event":
    query = os.environ["EVENT_VALUE"].casefold()
    events_dir = Path(os.environ["REPO_ROOT"]) / "knowledge" / "events"
    matches = []
    if events_dir.is_dir():
        for path in sorted(events_dir.glob("*.md")):
            fields = event_front_matter(path)
            title = fields.get("title") or path.stem
            stem = path.stem.casefold()
            title_key = title.casefold()
            if query == stem or query == title_key or query in stem or query in title_key:
                matches.append((path, title, fields.get("utc", "")))
    exact = [item for item in matches if query == item[0].stem.casefold() or query == item[1].casefold()]
    chosen = exact if exact else matches
    if len(chosen) == 1:
        path, title, utc_raw = chosen[0]
        if not utc_raw:
            raise SystemExit(f"{path.name} has no utc instant")
        target_utc = parse_instant(utc_raw, timezone.utc)
        label = title
    elif len(chosen) == 0:
        status = "missing"
        label = os.environ["EVENT_VALUE"]
        note = "No event file matches that name. Add one under knowledge/events/ or give a clock time."
    else:
        status = "choose"
        label = os.environ["EVENT_VALUE"]
        lines = "\n".join(f"- {title} ({path.name})" for path, title, _utc in chosen)
        note = "More than one event matches:\n\n" + lines
else:
    raw = os.environ["UTC_VALUE"] if source == "utc" else os.environ["LOCAL_VALUE"]
    naive_tz = timezone.utc if source == "utc" else observer_tz
    target_utc = parse_instant(raw, naive_tz)
    label = raw

if target_utc is None:
    jday_line = '""'
    utc_line = '""'
    local_line = '""'
    target_block = note or "No instant was selected."
else:
    target_local = target_utc.astimezone(observer_tz)
    jday = julian_day(target_utc)
    jday_line = f"{jday:.10f}"
    utc_line = q(target_utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
    local_line = q(target_local.strftime("%Y-%m-%dT%H:%M:%S"))
    target_block = f"""Target sky time:

- Source: {source}
- Label: {label}
- Local: {target_local.strftime("%Y-%m-%dT%H:%M:%S")}
- UTC: {target_utc.strftime("%Y-%m-%dT%H:%M:%SZ")}
- Julian day: {jday:.10f}
- Clock: paused
"""

body = f"""---
stage: propose
status: {status}
source: {source}
label: {q(label)}
utc: {utc_line}
local: {local_line}
jday: {jday_line}
timerate: 0
current_local: {q(front.get("local", ""))}
current_utc: {q(front.get("utc", ""))}
current_jday: {front.get("jday", '""')}
current_timerate: {front.get("timerate", '""')}
timezone: {q(front.get("timezone", ""))}
---

Current simulation time:

- Local: {front.get("local") or "(none)"}
- UTC: {front.get("utc") or "(none)"}
- Julian day: {front.get("jday") or "(none)"}
- Timezone: {front.get("timezone") or "(none)"}

{target_block}
"""
if status == "review":
    body += "\nThe person accepts or rejects this instant before it is sent.\n"
Path(out_path).write_text(body)
print(status)
raise SystemExit(2)
PY

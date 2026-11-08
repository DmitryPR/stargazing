#!/usr/bin/env bash
# Scrape the IMO shower calendar into one record.
set -euo pipefail

source "$(dirname "$0")/../lib.sh"

out=""
window=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out|--window)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for %s\n' "$1" >&2
        exit 1
      fi
      case "$1" in
        --out) out="$2" ;;
        --window) window="$2" ;;
      esac
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

body="$(mktemp)"
trap 'rm -f "$body"' EXIT
status="fetched"
if ! curl -fsS -m 20 -A "star-hackathon" -o "$body" "https://www.imo.net/calendar/"; then
  status="failed"
fi

WINDOW_PATH="$window" STATUS_VALUE="$status" python3 - "$body" "$out" <<'PY'
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

body_path, out_path = sys.argv[1:]
status = os.environ["STATUS_VALUE"]
window = os.environ["WINDOW_PATH"]
url = "https://www.imo.net/calendar/"
notes = []
if status == "fetched":
    html = Path(body_path).read_text(errors="replace")
    limit = None
    if window:
        text = Path(window).read_text()
        end = text.find("\n---", 4)
        front = {}
        for line in text[4:end].splitlines():
            if ":" not in line:
                continue
            key, value = line.split(":", 1)
            front[key.strip()] = value.strip().strip('"')
        start = datetime.strptime(front["now"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        until = datetime.strptime(front["until"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        limit = (start, until)
    months = {
        "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
        "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
    }
    full = {
        "Jan": "January", "Feb": "February", "Mar": "March", "Apr": "April",
        "May": "May", "Jun": "June", "Jul": "July", "Aug": "August",
        "Sep": "September", "Oct": "October", "Nov": "November", "Dec": "December",
    }
    for card in re.split(r'<article id="', html)[1:]:
        name_match = re.search(r'class="shower-card__name">([^<]+)', card)
        peak_match = re.search(r"PEAK NIGHT</div>([^<]+)", card)
        active_match = re.search(r'class="hide-mobile">([^<]+)</span>', card)
        if not name_match or not peak_match:
            continue
        name = name_match.group(1).strip()
        peak = peak_match.group(1).strip()
        active = active_match.group(1).strip() if active_match else ""
        night = re.fullmatch(r"(\d{1,2})[–-](\d{1,2}) ([A-Za-z]{3})", peak)
        if not night:
            notes.append(f"{name}: peak night `{peak}` has no clock time")
            continue
        start_day, end_day, month_name = night.groups()
        month = months.get(month_name)
        year = None
        for token in (month_name, full.get(month_name, month_name)):
            found = re.search(rf"{token} (\d{{4}})", active)
            if found:
                year = int(found.group(1))
                break
        years = list(dict.fromkeys(int(item) for item in re.findall(r"\b(20\d{2})\b", active)))
        if year is None and len(years) == 1:
            year = years[0]
        if month is None or year is None:
            notes.append(f"{name}: peak night `{peak}` has no clock time; the year was not on the card")
            continue
        try:
            night_start = datetime(year, month, int(start_day), tzinfo=timezone.utc)
            night_end = datetime(year, month, int(end_day), tzinfo=timezone.utc) + timedelta(days=1)
        except ValueError:
            notes.append(f"{name}: peak night `{peak}` has no clock time")
            continue
        if limit and (night_end <= limit[0] or night_start >= limit[1]):
            continue
        notes.append(f"{name}: peak night {peak} ({active}). The page gives no UTC clock time.")
else:
    notes.append("download failed")

note_lines = [f"- {line}" for line in notes] or ["- (none)"]
Path(out_path).write_text(
    "---\n"
    'source: "International Meteor Organization"\n'
    "id: imo\n"
    f"status: {status}\n"
    f'url: "{url}"\n'
    "kind: nights\n"
    "---\n\n"
    "Instants:\n\n"
    "- (none)\n\n"
    "Notes:\n\n"
    + "\n".join(note_lines)
    + "\n"
)
print(status)
PY

#!/usr/bin/env bash
# Download the named event sources and write a proposal.
# Writes output/fetch-events/02-proposed.md
# Exit 2 so the person can review before any event file is saved.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir fetch-events)"
window="${out_dir}/01-window.md"
out="${out_dir}/02-proposed.md"
raw="${out_dir}/raw"

if [[ ! -f "$window" ]]; then
  printf 'no window. Run bash scripts/events-window.sh first.\n' >&2
  exit 1
fi

rm -rf "$raw"
mkdir -p "$raw"

years="$(python3 - "$window" <<'PY'
import sys
from datetime import datetime
from pathlib import Path

text = Path(sys.argv[1]).read_text()
if not text.startswith("---\n"):
    raise SystemExit("window file has no front matter")
end = text.find("\n---", 4)
front = {}
for line in text[4:end].splitlines():
    if not line.strip() or ":" not in line:
        continue
    key, value = line.split(":", 1)
    front[key.strip()] = value.strip().strip('"')
if front.get("status") != "ready":
    raise SystemExit("window is not ready")
start = datetime.strptime(front["now"], "%Y-%m-%dT%H:%M:%SZ")
until = datetime.strptime(front["until"], "%Y-%m-%dT%H:%M:%SZ")
print(start.year)
if until.year != start.year:
    print(until.year)
PY
)"

for year in $years; do
  if ! curl -fsS -m 20 -A "star-hackathon" \
    -o "${raw}/usno-${year}.html" \
    "https://aa.usno.navy.mil/calculated/moon/phases?year=${year}"; then
    printf 'failed\n' >"${raw}/usno-${year}.error"
  fi
done

if ! curl -fsS -m 20 -A "star-hackathon" \
  -o "${raw}/imo.html" \
  "https://www.imo.net/calendar/"; then
  printf 'failed\n' >"${raw}/imo.error"
fi

python3 - "$window" "$raw" "$out" <<'PY'
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

window_path, raw_path, out_path = sys.argv[1:]
raw_dir = Path(raw_path)

def front_matter(path):
    text = Path(path).read_text()
    if not text.startswith("---\n"):
        raise SystemExit(f"{path} has no front matter")
    end = text.find("\n---", 4)
    front = {}
    for line in text[4:end].splitlines():
        if not line.strip() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        front[key.strip()] = value.strip().strip('"')
    return front

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

window = front_matter(window_path)
start = datetime.strptime(window["now"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
until = datetime.strptime(window["until"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)

MONTHS = {
    "Jan": 1, "January": 1, "Feb": 2, "February": 2, "Mar": 3, "March": 3,
    "Apr": 4, "April": 4, "May": 5, "Jun": 6, "June": 6, "Jul": 7, "July": 7,
    "Aug": 8, "August": 8, "Sep": 9, "September": 9, "Oct": 10, "October": 10,
    "Nov": 11, "November": 11, "Dec": 12, "December": 12,
}
FULL = {
    "Jan": "January", "Feb": "February", "Mar": "March", "Apr": "April",
    "May": "May", "Jun": "June", "Jul": "July", "Aug": "August",
    "Sep": "September", "Oct": "October", "Nov": "November", "Dec": "December",
}
PHASES = ["New Moon", "First Quarter", "Full Moon", "Last Quarter"]

proposed = []
incomplete = []
sources = []

def in_window(instant):
    return start <= instant < until

for path in sorted(raw_dir.glob("usno-*.html")):
    year = path.name.removeprefix("usno-").removesuffix(".html")
    url = f"https://aa.usno.navy.mil/calculated/moon/phases?year={year}"
    html = path.read_text(errors="replace")
    table = re.search(r"<table[\s\S]*?</table>", html, re.I)
    cells = re.findall(r"<td[^>]*>([\s\S]*?)</td>", table.group(0) if table else "", re.I)
    kept = 0
    for index, cell in enumerate(cells):
        text = re.sub(r"<[^>]+>", "", cell).replace("\xa0", " ").strip()
        if text in ("", "--"):
            continue
        match = re.fullmatch(r"(\d{4}) ([A-Za-z]{3}) (\d{1,2}) (\d{2}):(\d{2})", text)
        if not match:
            incomplete.append(f"- USNO {year}: unreadable cell `{text}`")
            continue
        year_n, month_name, day, hour, minute = match.groups()
        month = MONTHS.get(month_name)
        if month is None:
            incomplete.append(f"- USNO {year}: unreadable cell `{text}`")
            continue
        instant = datetime(int(year_n), month, int(day), int(hour), int(minute), tzinfo=timezone.utc)
        if not in_window(instant):
            continue
        phase = PHASES[index % 4]
        proposed.append({
            "utc": instant,
            "title": phase,
            "source": "US Naval Observatory",
            "url": url,
            "detail": text,
        })
        kept += 1
    sources.append(f"- US Naval Observatory {year}: fetched, {kept} instants in the window ({url})")

for path in sorted(raw_dir.glob("usno-*.error")):
    year = path.name.removeprefix("usno-").removesuffix(".error")
    sources.append(f"- US Naval Observatory {year}: failed")

imo_path = raw_dir / "imo.html"
imo_url = "https://www.imo.net/calendar/"
if imo_path.is_file():
    html = imo_path.read_text(errors="replace")
    cards = re.split(r'<article id="', html)[1:]
    seen = 0
    for card in cards:
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
            incomplete.append(f"- {name}: peak night `{peak}` has no clock time")
            continue
        start_day, end_day, month_name = night.groups()
        month = MONTHS.get(month_name)
        year = None
        for token in (month_name, FULL.get(month_name, month_name)):
            found = re.search(rf"{token} (\d{{4}})", active)
            if found:
                year = int(found.group(1))
                break
        years = list(dict.fromkeys(int(item) for item in re.findall(r"\b(20\d{2})\b", active)))
        if year is None and len(years) == 1:
            year = years[0]
        if month is None or year is None:
            incomplete.append(f"- {name}: peak night `{peak}` has no clock time; the year was not on the card")
            continue
        try:
            night_start = datetime(year, month, int(start_day), tzinfo=timezone.utc)
            night_end = datetime(year, month, int(end_day), tzinfo=timezone.utc) + timedelta(days=1)
        except ValueError:
            incomplete.append(f"- {name}: peak night `{peak}` has no clock time")
            continue
        if night_end <= start or night_start >= until:
            continue
        seen += 1
        incomplete.append(
            f"- {name}: peak night {peak} ({active}). The page gives no UTC clock time."
        )
    night_word = "peak night" if seen == 1 else "peak nights"
    sources.append(
        f"- International Meteor Organization: fetched, {seen} {night_word} in the window without a clock time ({imo_url})"
    )
if (raw_dir / "imo.error").is_file():
    sources.append("- International Meteor Organization: failed")

if not sources:
    raise SystemExit("no sources were fetched")
if all(line.endswith("failed") for line in sources):
    raise SystemExit("every source failed")

proposed.sort(key=lambda item: item["utc"])
event_lines = []
for item in proposed:
    stamp = item["utc"].strftime("%Y-%m-%dT%H:%M:%SZ")
    event_lines.append(
        f"- {stamp} — {item['title']} ({item['source']}; {item['detail']})"
    )
if not event_lines:
    event_lines.append("- (none)")
if not incomplete:
    incomplete.append("- (none)")

text = f"""---
stage: fetch
status: review
now: {q(window["now"])}
until: {q(window["until"])}
days: {window["days"]}
count: {len(proposed)}
---

Sources:

{chr(10).join(sources)}

Proposed instants:

{chr(10).join(event_lines)}

No clock time:

{chr(10).join(incomplete)}

A proposed instant has a UTC clock time from the page. A peak night is not given a midnight time. The person accepts an instant before it is saved as an event file. This file stays in output/.
"""
Path(out_path).write_text(text)
print(f"review {len(proposed)}")
raise SystemExit(2)
PY

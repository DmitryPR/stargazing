#!/usr/bin/env bash
# Scrape US Naval Observatory moon phases into one record.
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

raw="$(mktemp -d)"
trap 'rm -rf "$raw"' EXIT

years="$(WINDOW_PATH="$window" python3 - <<'PY'
import os
from datetime import datetime, timezone
from pathlib import Path

window = os.environ["WINDOW_PATH"]
if not window:
    print(datetime.now(timezone.utc).year)
    raise SystemExit(0)
text = Path(window).read_text()
end = text.find("\n---", 4)
front = {}
for line in text[4:end].splitlines():
    if ":" not in line:
        continue
    key, value = line.split(":", 1)
    front[key.strip()] = value.strip().strip('"')
start = datetime.strptime(front["now"], "%Y-%m-%dT%H:%M:%SZ")
until = datetime.strptime(front["until"], "%Y-%m-%dT%H:%M:%SZ")
print(start.year)
if until.year != start.year:
    print(until.year)
PY
)"

failed=""
for year in $years; do
  if ! curl -fsS -m 20 -A "star-hackathon" \
    -o "${raw}/usno-${year}.html" \
    "https://aa.usno.navy.mil/calculated/moon/phases?year=${year}"; then
    failed="${failed} ${year}"
  fi
done

WINDOW_PATH="$window" FAILED_YEARS="$failed" python3 - "$raw" "$out" <<'PY'
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

raw_dir, out_path = sys.argv[1:]
window = os.environ["WINDOW_PATH"]
failed_years = os.environ["FAILED_YEARS"].split()

def bounds():
    if not window:
        return None
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
    return start, until

limit = bounds()
months = {
    "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
    "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
}
phases = ["New Moon", "First Quarter", "Full Moon", "Last Quarter"]
instants = []
notes = []
urls = []
for path in sorted(Path(raw_dir).glob("usno-*.html")):
    year = path.name.removeprefix("usno-").removesuffix(".html")
    url = f"https://aa.usno.navy.mil/calculated/moon/phases?year={year}"
    urls.append(url)
    html = path.read_text(errors="replace")
    table = re.search(r"<table[\s\S]*?</table>", html, re.I)
    cells = re.findall(r"<td[^>]*>([\s\S]*?)</td>", table.group(0) if table else "", re.I)
    for index, cell in enumerate(cells):
        text = re.sub(r"<[^>]+>", "", cell).replace("\xa0", " ").strip()
        if text in ("", "--"):
            continue
        match = re.fullmatch(r"(\d{4}) ([A-Za-z]{3}) (\d{1,2}) (\d{2}):(\d{2})", text)
        if not match:
            notes.append(f"unreadable cell `{text}`")
            continue
        year_n, month_name, day, hour, minute = match.groups()
        month = months.get(month_name)
        if month is None:
            notes.append(f"unreadable cell `{text}`")
            continue
        instant = datetime(int(year_n), month, int(day), int(hour), int(minute), tzinfo=timezone.utc)
        if limit and not (limit[0] <= instant < limit[1]):
            continue
        phase = phases[index % 4]
        instants.append(f"{instant.strftime('%Y-%m-%dT%H:%M:%SZ')} | {phase} | {text}")
for year in failed_years:
    notes.append(f"{year} download failed")

status = "failed" if not urls and failed_years else "fetched"
url_line = urls[0] if len(urls) == 1 else " ".join(urls)
instant_lines = [f"- {line}" for line in instants] or ["- (none)"]
note_lines = [f"- {line}" for line in notes] or ["- (none)"]
Path(out_path).write_text(
    "---\n"
    'source: "US Naval Observatory"\n'
    "id: usno\n"
    f"status: {status}\n"
    f'url: "{url_line}"\n'
    "kind: instants\n"
    "---\n\n"
    "Instants:\n\n"
    + "\n".join(instant_lines)
    + "\n\nNotes:\n\n"
    + "\n".join(note_lines)
    + "\n"
)
print(status)
PY

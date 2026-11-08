#!/usr/bin/env bash
# Ask each source scraper for a record, then write one proposal.
# Writes output/fetch-events/02-proposed.md
# Exit 2 so the person can review before any event file is saved.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir fetch-events)"
window="${out_dir}/01-window.md"
out="${out_dir}/02-proposed.md"
scraped="${out_dir}/scraped"

if [[ ! -f "$window" ]]; then
  printf 'no window. Run bash scripts/events-window.sh first.\n' >&2
  exit 1
fi

rm -rf "$scraped"
mkdir -p "$scraped"

root="$(repo_root)"
for source in usno imo; do
  bash "${root}/scripts/scrapers/${source}.sh" --window "$window" --out "${scraped}/${source}.md" || true
done

python3 - "$window" "$scraped" "$out" <<'PY'
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

window_path, scraped_path, out_path = sys.argv[1:]

def front_matter(text):
    if not text.startswith("---\n"):
        raise SystemExit("scraped record has no front matter")
    end = text.find("\n---", 4)
    front = {}
    for line in text[4:end].splitlines():
        if not line.strip() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        front[key.strip()] = value.strip().strip('"')
    return front, text[end + 4:]

def section(body, title):
    match = re.search(rf"{title}:\n\n(.*?)(?:\n\n|\Z)", body, re.S)
    if not match:
        return []
    lines = []
    for line in match.group(1).splitlines():
        if line.startswith("- ") and line != "- (none)":
            lines.append(line[2:])
    return lines

def q(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'

window_text = Path(window_path).read_text()
window, _ = front_matter(window_text)
start = datetime.strptime(window["now"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
until = datetime.strptime(window["until"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)

expected = [
    "usno", "imo",
]
records = []
for source_id in expected:
    path = Path(scraped_path) / f"{source_id}.md"
    if not path.is_file():
        records.append({
            "source": source_id,
            "status": "failed",
            "url": "",
            "kind": "check",
            "instants": [],
            "notes": ["did not write a record"],
        })
        continue
    front, body = front_matter(path.read_text())
    records.append({
        "source": front.get("source", source_id),
        "status": front.get("status", "failed"),
        "url": front.get("url", ""),
        "kind": front.get("kind", "check"),
        "instants": section(body, "Instants"),
        "notes": section(body, "Notes"),
    })

if records and all(item["status"] != "fetched" for item in records):
    raise SystemExit("every source failed")

proposed = []
nights = []
checks = []
sources = []
for item in records:
    url = f" ({item['url']})" if item["url"] else ""
    sources.append(f"- {item['source']}: {item['status']}{url}")
    for line in item["instants"]:
        match = re.match(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z) \| (.+) \| (.+)", line)
        if not match:
            checks.append(f"{item['source']}: unreadable instant `{line}`")
            continue
        stamp, title, detail = match.groups()
        instant = datetime.strptime(stamp, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        if not (start <= instant < until):
            continue
        proposed.append((instant, f"- {stamp} — {title} ({item['source']}; {detail})"))
    for note in item["notes"]:
        if item["kind"] == "nights":
            nights.append(f"- {note}")
        else:
            checks.append(f"- {item['source']}: {note}")

proposed.sort(key=lambda item: item[0])
event_lines = [line for _, line in proposed] or ["- (none)"]
night_lines = nights or ["- (none)"]
check_lines = checks or ["- (none)"]
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

{chr(10).join(night_lines)}

Other checks:

{chr(10).join(check_lines)}

A proposed instant has a UTC clock time from its scraped record. Notes stay notes. The person accepts an instant before it is saved as an event file. This file stays in output/.
"""
Path(out_path).write_text(text)
print(f"review {len(proposed)}")
raise SystemExit(2)
PY

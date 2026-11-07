#!/usr/bin/env bash
# Read back what Stellarium selected after focus.
# Writes output/point-sky/04-confirm.md
set -euo pipefail

if [[ $# -lt 1 || -z "${1// }" ]]; then
  printf 'usage: bash scripts/confirm.sh "<catalog name>"\n' >&2
  exit 1
fi

source "$(dirname "$0")/lib.sh"

target="$1"
url="$(stellarium_url)"
out="$(ensure_output_dir)/04-confirm.md"
status_file="$(mktemp)"
info_file="$(mktemp)"
trap 'rm -f "$status_file" "$info_file"' EXIT

stellarium_curl "${url}/api/main/status" >"$status_file"
stellarium_curl -G "${url}/api/objects/info" \
  --data-urlencode "name=${target}" \
  --data-urlencode "format=json" >"$info_file"

TARGET_VALUE="$target" python3 - "$status_file" "$info_file" "$out" <<'PY'
import json
import os
import re
import sys
from html import unescape
from pathlib import Path

status_path, info_path, out_path = sys.argv[1:]
target = os.environ["TARGET_VALUE"]
status = json.loads(Path(status_path).read_text())
info = json.loads(Path(info_path).read_text())
html = status.get("selectioninfo") or ""
match = re.search(r"<h2[^>]*>(.*?)</h2>", html, flags=re.I | re.S)
selected = unescape(re.sub(r"<[^>]+>", "", match.group(1))).strip() if match else ""
matched = selected.casefold() == target.casefold()
view = status.get("view") or {}
fov = view.get("fov")

def angle(value):
    return f"{value:.2f}°" if isinstance(value, (int, float)) else "unknown"

result = "match" if matched else "mismatch"
text = f"""---
stage: confirm
status: {result}
target: "{target}"
selected: "{selected}"
---

Accepted catalog name: {target}
Stellarium selected: {selected or "(none)"}
Match: {"yes" if matched else "no"}

- Altitude: {angle(info.get("altitude"))}
- Azimuth: {angle(info.get("azimuth"))}
- Field of view: {angle(fov)}

The person checks this against the Stellarium window.
"""
Path(out_path).write_text(text)
print(result)
raise SystemExit(0 if matched else 2)
PY

#!/usr/bin/env bash
# Ask the Remote Control connector for current status.
# Writes output/point-sky/01-connect.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

url="$(stellarium_url)"
out="$(ensure_output_dir)/01-connect.md"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl "${url}/api/main/status" >"$body_file"; then
  cat >"$out" <<EOF
---
stage: connect
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
import re
import sys
from html import unescape
from pathlib import Path

body_path, out_path = sys.argv[1:]
status = json.loads(Path(body_path).read_text())
location = status.get("location") or {}
time_info = status.get("time") or {}
view = status.get("view") or {}
html = status.get("selectioninfo") or ""
match = re.search(r"<h2[^>]*>(.*?)</h2>", html, flags=re.I | re.S)
selected = unescape(re.sub(r"<[^>]+>", "", match.group(1))).strip() if match else "none"
fov = view.get("fov")
fov_line = f"{fov:.2f}°" if isinstance(fov, (int, float)) else "unknown"

text = f"""---
stage: connect
status: connected
url: {os.environ["STELLARIUM_URL_VALUE"]}
---

The Remote Control connector answered.

- Place: {location.get("name") or "unknown"} ({location.get("latitude")}, {location.get("longitude")})
- Local time: {time_info.get("local") or "unknown"}
- Field of view: {fov_line}
- Selected: {selected}
"""
Path(out_path).write_text(text)
print("connected")
PY

#!/usr/bin/env bash
# Send the accepted compass heading to Stellarium.
# Writes output/set-heading/03-apply.md
set -euo pipefail

source "$(dirname "$0")/lib.sh"

out_dir="$(ensure_output_dir set-heading)"
proposal="${out_dir}/02-proposed.md"
out="${out_dir}/03-apply.md"

if [[ ! -f "$proposal" ]]; then
  printf 'no proposal. Run bash scripts/heading-propose.sh first.\n' >&2
  exit 1
fi

if [[ -f "$out" ]] && grep -q '^status: ok$' "$out"; then
  printf 'this run already applied a heading. Start a new run to change it again.\n' >&2
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

required = ("heading", "az_radians", "look_altitude")
missing = [key for key in required if key not in front or front[key] == ""]
if missing:
    raise SystemExit("proposal is missing " + ", ".join(missing))

for key in required:
    print(f"{key}={shlex.quote(front[key])}")
PY
)"

if ! stellarium_curl -X POST \
  --data-urlencode "az=${az_radians}" \
  "${url}/api/main/view" >"$body_file"; then
  reply="$(cat "$body_file" 2>/dev/null || true)"
  cat >"$out" <<EOF
---
stage: apply
status: failed
heading: ${heading}
az_radians: ${az_radians}
look_altitude: ${look_altitude}
---

The connector did not accept the heading.

${reply}
EOF
  exit 1
fi

HEADING_VALUE="$heading" \
AZ_VALUE="$az_radians" \
LOOK_VALUE="$look_altitude" \
python3 - "$body_file" "$out" <<'PY'
import os
import sys
from pathlib import Path

reply = Path(sys.argv[1]).read_text().strip() or "(empty)"
failed = reply.startswith("error:")
text = f"""---
stage: apply
status: {"failed" if failed else "ok"}
heading: {os.environ["HEADING_VALUE"]}
az_radians: {os.environ["AZ_VALUE"]}
look_altitude: {os.environ["LOOK_VALUE"]}
---

Heading sent:

- Heading: {os.environ["HEADING_VALUE"]}°
- Connector az: {os.environ["AZ_VALUE"]} radians
- Look altitude left unchanged: {os.environ["LOOK_VALUE"]}°

Connector reply: {reply}
"""
Path(sys.argv[2]).write_text(text)
print(reply)
raise SystemExit(1 if failed else 0)
PY

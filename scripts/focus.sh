#!/usr/bin/env bash
# Focus an accepted catalog name in Stellarium.
# Writes output/point-sky/03-focus.md
set -euo pipefail

if [[ $# -lt 1 || -z "${1// }" ]]; then
  printf 'usage: bash scripts/focus.sh "<catalog name>" [center|zoom|mark]\n' >&2
  exit 1
fi

mode="${2:-center}"
case "$mode" in
  center|zoom|mark) ;;
  *)
    printf 'mode must be center, zoom, or mark\n' >&2
    exit 1
    ;;
esac

source "$(dirname "$0")/lib.sh"

target="$1"
url="$(stellarium_url)"
out="$(ensure_output_dir)/03-focus.md"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl -X POST \
  --data-urlencode "target=${target}" \
  --data-urlencode "mode=${mode}" \
  "${url}/api/main/focus" >"$body_file"; then
  reply="$(cat "$body_file" 2>/dev/null || true)"
  cat >"$out" <<EOF
---
stage: focus
status: failed
target: "${target}"
mode: ${mode}
---

The connector did not accept the focus.

${reply}
EOF
  exit 1
fi

TARGET_VALUE="$target" MODE_VALUE="$mode" python3 - "$body_file" "$out" <<'PY'
import os
import sys
from pathlib import Path

body_path, out_path = sys.argv[1:]
reply = Path(body_path).read_text().strip() or "(empty)"
failed = reply.startswith("error:")
status = "failed" if failed else "ok"
text = f"""---
stage: focus
status: {status}
target: "{os.environ["TARGET_VALUE"]}"
mode: {os.environ["MODE_VALUE"]}
---

Catalog name: {os.environ["TARGET_VALUE"]}
Mode: {os.environ["MODE_VALUE"]}
Connector reply: {reply}
"""
Path(out_path).write_text(text)
print(reply)
raise SystemExit(1 if failed else 0)
PY

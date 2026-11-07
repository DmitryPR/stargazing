#!/usr/bin/env bash
# Resolve a search string to one catalog name.
# Writes output/point-sky/02-resolve.md
# Exit 0 when one exact catalog name exists. Exit 2 when a person must choose.
set -euo pipefail

if [[ $# -lt 1 || -z "${1// }" ]]; then
  printf 'usage: bash scripts/resolve.sh "<search>"\n' >&2
  exit 1
fi

source "$(dirname "$0")/lib.sh"

search="$1"
url="$(stellarium_url)"
out="$(ensure_output_dir)/02-resolve.md"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

if ! stellarium_curl -G "${url}/api/objects/find" --data-urlencode "str=${search}" >"$body_file"; then
  printf 'find failed against %s\n' "$url" >&2
  exit 1
fi

SEARCH_VALUE="$search" python3 - "$body_file" "$out" <<'PY'
import json
import os
import sys
from pathlib import Path

body_path, out_path = sys.argv[1:]
search = os.environ["SEARCH_VALUE"]
names = json.loads(Path(body_path).read_text())
if not isinstance(names, list):
    raise SystemExit("connector find did not return a list")

exact = [name for name in names if str(name).casefold() == search.casefold()]
target = exact[0] if len(exact) == 1 else ""
status = "exact" if target else "review"
listed = "\n".join(f"- {name}" for name in names) or "- (none)"
target_line = target if target else "(none)"

text = f"""---
stage: resolve
status: {status}
query: {search}
target: "{target}"
---

Search: {search}

Catalog names returned:

{listed}

Exact catalog name: {target_line}
"""
Path(out_path).write_text(text)
print(status)
raise SystemExit(0 if target else 2)
PY

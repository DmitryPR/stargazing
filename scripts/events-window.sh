#!/usr/bin/env bash
# Record the UTC window for a fetch. Does not download a page.
# Writes output/fetch-events/01-window.md
# A new run replaces the previous fetch-events output.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

days=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for --days\n' >&2
        exit 1
      fi
      days="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      printf 'usage: bash scripts/events-window.sh [--days <count>]\n' >&2
      exit 1
      ;;
  esac
done

out_dir="$(ensure_output_dir fetch-events)"
rm -rf "$out_dir"
mkdir -p "$out_dir"
out="${out_dir}/01-window.md"

DAYS_VALUE="$days" python3 - "$out" <<'PY'
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

raw = os.environ["DAYS_VALUE"]
try:
    days = int(raw) if raw else 366
except ValueError:
    raise SystemExit("--days must be a whole number")
if days < 1 or days > 3660:
    raise SystemExit("--days must be from 1 to 3660")

now = datetime.now(timezone.utc).replace(microsecond=0)
until = now + timedelta(days=days)
text = f"""---
stage: window
status: ready
now: "{now.strftime("%Y-%m-%dT%H:%M:%SZ")}"
until: "{until.strftime("%Y-%m-%dT%H:%M:%SZ")}"
days: {days}
---

Fetch window:

- From: {now.strftime("%Y-%m-%dT%H:%M:%SZ")}
- Until: {until.strftime("%Y-%m-%dT%H:%M:%SZ")}
- Days: {days}
"""
Path(sys.argv[1]).write_text(text)
print("ready")
PY

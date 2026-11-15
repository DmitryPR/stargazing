#!/usr/bin/env bash
# Decide the read-photo criteria for one photo record.
# Reads the record and does not change it.
# Exit 0 when the record is ready for a person. Exit 1 when a criterion fails.
set -euo pipefail

record=""
utc=""
latitude=""
longitude=""
heading=""

usage() {
  printf 'usage: bash scripts/check-read-photo.sh --record <path> [--utc <utc> --latitude <deg> --longitude <deg> --heading <deg>]\n' >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --record|--utc|--latitude|--longitude|--heading)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for %s\n' "$1" >&2
        usage
        exit 1
      fi
      case "$1" in
        --record) record="$2" ;;
        --utc) utc="$2" ;;
        --latitude) latitude="$2" ;;
        --longitude) longitude="$2" ;;
        --heading) heading="$2" ;;
      esac
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$record" ]]; then
  usage
  exit 1
fi

supplied=0
[[ -n "$utc" ]] && supplied=$((supplied + 1))
[[ -n "$latitude" ]] && supplied=$((supplied + 1))
[[ -n "$longitude" ]] && supplied=$((supplied + 1))
[[ -n "$heading" ]] && supplied=$((supplied + 1))
if [[ "$supplied" -ne 0 && "$supplied" -ne 4 ]]; then
  printf 'an expected true reading needs --utc, --latitude, --longitude, and --heading together\n' >&2
  exit 1
fi

RECORD_PATH="$record" EXPECT_UTC="$utc" EXPECT_LATITUDE="$latitude" \
  EXPECT_LONGITUDE="$longitude" EXPECT_HEADING="$heading" \
  python3 - <<'PY'
import os
import sys
from pathlib import Path

path = Path(os.environ["RECORD_PATH"])
if not path.is_file():
    print("- photo record is missing", file=sys.stderr)
    raise SystemExit(1)

text = path.read_text()
if not text.startswith("---\n"):
    print("- photo record has no front matter", file=sys.stderr)
    raise SystemExit(1)
end = text.find("\n---", 4)
if end < 0:
    print("- photo record front matter does not close", file=sys.stderr)
    raise SystemExit(1)

fields = {}
for line in text[4:end].splitlines():
    if ":" not in line:
        continue
    key, value = line.split(":", 1)
    value = value.strip()
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        value = value[1:-1]
    fields[key.strip()] = value

failures = []
if fields.get("status", "") != "review":
    failures.append("status is not review")

heading_ref = fields.get("heading_ref", "")
if heading_ref == "M":
    failures.append("heading is magnetic and is not a true heading")
elif os.environ["EXPECT_UTC"]:
    if heading_ref != "T":
        failures.append("heading reference is not true")
    expected = {
        "utc": os.environ["EXPECT_UTC"],
        "latitude": os.environ["EXPECT_LATITUDE"],
        "longitude": os.environ["EXPECT_LONGITUDE"],
        "heading": os.environ["EXPECT_HEADING"],
    }
    actual_utc = fields.get("utc", "")
    if actual_utc != expected["utc"]:
        failures.append("utc does not match the expected true reading")
    for key in ("latitude", "longitude", "heading"):
        raw = fields.get(key, "")
        try:
            actual = float(raw)
            target = float(expected[key])
        except ValueError:
            failures.append(f"{key} does not match the expected true reading")
            continue
        if abs(actual - target) > 1e-6:
            failures.append(f"{key} does not match the expected true reading")

if failures:
    for item in failures:
        print(f"- {item}", file=sys.stderr)
    raise SystemExit(1)
raise SystemExit(0)
PY

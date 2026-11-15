#!/usr/bin/env bash
# Score the read-photo fixtures. The expected true reading lives in this script.
# Exit 0 when all three cases match the criteria. A pass does not accept a sky change.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

root="$(repo_root)"
cd "$root"

expect_utc="2026-11-14T05:17:31Z"
expect_latitude="59.35694166666666"
expect_longitude="24.5237"
expect_heading="125.4344100197759"

swift "${root}/scripts/photo-fixture.swift" true "${root}/tests/read-photo/fixtures/tagapere-true.jpg"
swift "${root}/scripts/photo-fixture.swift" magnetic "${root}/tests/read-photo/fixtures/tagapere-magnetic.jpg"

failed=0

set +e
bash "${root}/scripts/photo-run.sh" \
  --photo "${root}/tests/read-photo/fixtures/tagapere-true.jpg" \
  --run-id tagapere-001 \
  --utc "$expect_utc" \
  --latitude "$expect_latitude" \
  --longitude "$expect_longitude" \
  --heading "$expect_heading"
true_exit=$?
bash "${root}/scripts/photo-run.sh" \
  --photo "${root}/tests/read-photo/fixtures/tagapere-magnetic.jpg" \
  --run-id magnetic-001
magnetic_exit=$?
bash "${root}/scripts/photo-run.sh" \
  --photo "${root}/tests/read-photo/fixtures/missing.jpg" \
  --run-id missing-001
missing_exit=$?
bash "${root}/scripts/photo-read.sh" \
  --photo "${root}/tests/read-photo/fixtures/tagapere-true.jpg" >/dev/null
later_exit=$?
set -e

if [[ "$true_exit" -ne 0 ]]; then
  printf 'fail tagapere-001 exit %s\n' "$true_exit" >&2
  failed=1
fi
if [[ "$magnetic_exit" -eq 0 ]]; then
  printf 'fail magnetic-001 passed\n' >&2
  failed=1
fi
if [[ "$missing_exit" -eq 0 ]]; then
  printf 'fail missing-001 passed\n' >&2
  failed=1
fi
if [[ "$later_exit" -ne 2 ]]; then
  printf 'fail later read exit %s\n' "$later_exit" >&2
  failed=1
fi

EXPECT_UTC="$expect_utc" python3 - "$root" "$failed" <<'PY'
import os
import sys
from pathlib import Path

root = Path(sys.argv[1])
failed = int(sys.argv[2])

def front_matter(path):
    text = path.read_text()
    end = text.find("\n---", 4)
    fields = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        value = value.strip().strip('"')
        fields[key.strip()] = value
    return fields

def fail(message):
    global failed
    print(f"fail {message}", file=sys.stderr)
    failed = 1

true_state = front_matter(root / "runs/read-photo/tagapere-001/state.md")
if true_state.get("state") != "awaiting-review":
    fail("tagapere-001 state is not awaiting-review")

magnetic_dir = root / "runs/read-photo/magnetic-001"
magnetic_state = front_matter(magnetic_dir / "state.md")
magnetic_record = front_matter(magnetic_dir / "01-photo.md")
if magnetic_state.get("state") != "failed":
    fail("magnetic-001 state is not failed")
if magnetic_record.get("heading_ref") != "M":
    fail("magnetic-001 heading_ref is not M")
try:
    if abs(float(magnetic_record.get("heading", "")) - 40.0) > 1e-6:
        fail("magnetic-001 heading changed")
except ValueError:
    fail("magnetic-001 heading changed")

missing_dir = root / "runs/read-photo/missing-001"
missing_state = front_matter(missing_dir / "state.md")
if missing_state.get("state") != "failed":
    fail("missing-001 state is not failed")
if (missing_dir / "01-photo.md").exists():
    fail("missing-001 wrote a photo record")

if failed:
    raise SystemExit(1)

print("ok tagapere-001 awaiting-review")
print("ok magnetic-001 failed")
print("ok missing-001 failed")
print("ok magnetic record kept")
PY

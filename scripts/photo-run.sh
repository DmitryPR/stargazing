#!/usr/bin/env bash
# Read one photograph, keep the record under runs/read-photo/, and run the check.
# Exit 0 when the check passes. That state is awaiting-review, not an acceptance.
# Exit 1 when the file cannot be read or the check fails. The run folder stays.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

photo=""
run_id=""
utc=""
latitude=""
longitude=""
heading=""

usage() {
  printf 'usage: bash scripts/photo-run.sh --photo <path> --run-id <id> [--utc <utc> --latitude <deg> --longitude <deg> --heading <deg>]\n' >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --photo|--run-id|--utc|--latitude|--longitude|--heading)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for %s\n' "$1" >&2
        usage
        exit 1
      fi
      case "$1" in
        --photo) photo="$2" ;;
        --run-id) run_id="$2" ;;
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

if [[ -z "$photo" || -z "$run_id" ]]; then
  usage
  exit 1
fi
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
  printf 'run id must be letters, numbers, hyphens, or underscores\n' >&2
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

root="$(repo_root)"
run_dir="${root}/runs/read-photo/${run_id}"
rm -rf "$run_dir"
mkdir -p "$run_dir"

write_state() {
  local state="$1"
  local note="$2"
  cat > "${run_dir}/state.md" <<EOF
---
run_id: ${run_id}
workflow: read-photo
state: ${state}
stage: 01-read
---

${note}
EOF
}

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
trap 'rm -f "$stdout_file" "$stderr_file"' EXIT

set +e
bash "${root}/scripts/photo-read.sh" --photo "$photo" >"$stdout_file" 2>"$stderr_file"
read_exit=$?
set -e

if [[ "$read_exit" -ne 2 ]]; then
  message="$(tr '\n' ' ' < "$stderr_file" | sed 's/[[:space:]]*$//')"
  if [[ -z "$message" ]]; then
    message="The photograph could not be read."
  fi
  write_state "failed" "${message} Ask once for a path. Do not invent metadata."
  printf '%s\n' "$message" >&2
  exit 1
fi

record="${root}/output/read-photo/01-photo.md"
if [[ ! -f "$record" ]]; then
  write_state "failed" "The read stopped without a photo record. Do not invent metadata."
  printf 'the read stopped without a photo record\n' >&2
  exit 1
fi

cp "$record" "${run_dir}/01-photo.md"

check_args=(--record "${run_dir}/01-photo.md")
if [[ "$supplied" -eq 4 ]]; then
  check_args+=(--utc "$utc" --latitude "$latitude" --longitude "$longitude" --heading "$heading")
fi

set +e
bash "${root}/scripts/check-read-photo.sh" "${check_args[@]}"
check_exit=$?
set -e

if [[ "$check_exit" -ne 0 ]]; then
  write_state "failed" "The mechanical check failed. The record stays. Do not convert a magnetic heading. Do not pass it to set-heading."
  exit 1
fi

write_state "awaiting-review" "The mechanical check passed. This is not an acceptance."
printf 'awaiting-review\n'
exit 0

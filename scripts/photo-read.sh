#!/usr/bin/env bash
# Read one photograph's clock, GPS place, and compass bearing.
# Writes output/read-photo/01-photo.md
# Exit 2 so the person can review before any Stellarium change.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

photo=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --photo)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for --photo\n' >&2
        exit 1
      fi
      photo="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      printf 'usage: bash scripts/photo-read.sh --photo <path>\n' >&2
      exit 1
      ;;
  esac
done

if [[ -z "$photo" ]]; then
  printf 'usage: bash scripts/photo-read.sh --photo <path>\n' >&2
  exit 1
fi
if [[ ! -f "$photo" ]]; then
  printf 'no photograph at %s\n' "$photo" >&2
  exit 1
fi

out_dir="$(ensure_output_dir read-photo)"
rm -rf "$out_dir"
mkdir -p "$out_dir"
out="${out_dir}/01-photo.md"
root="$(repo_root)"

swift "${root}/scripts/photo-exif.swift" "$photo" "$out"
printf 'review\n'
exit 2

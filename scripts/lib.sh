#!/usr/bin/env bash
# Shared helpers for the Stellarium Remote Control scripts.

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

stellarium_url() {
  local base="${STELLARIUM_URL:-http://127.0.0.1:8090}"
  printf '%s' "${base%/}"
}

# stellarium_curl [curl args...]
# Bash 3.2 (macOS) treats an empty array as unbound when set -u is on.
stellarium_curl() {
  if [[ -n "${STELLARIUM_PASSWORD:-}" ]]; then
    curl -fsS -m 8 -u ":${STELLARIUM_PASSWORD}" "$@"
  else
    curl -fsS -m 8 "$@"
  fi
}

ensure_output_dir() {
  local root
  root="$(repo_root)"
  mkdir -p "${root}/output/point-sky"
  printf '%s\n' "${root}/output/point-sky"
}

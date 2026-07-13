#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-headless}"
case "$MODE" in headless|headed) ;; *) echo 'Usage: start-native.sh [headless|headed]' >&2; exit 2;; esac
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CAMOFOX_DISPLAY_MODE="$MODE"
export CAMOFOX_PROFILE_DIR="${CAMOFOX_PROFILE_DIR:-$ROOT/data/profiles}"
export CAMOFOX_WINDOW_WIDTH="${CAMOFOX_WINDOW_WIDTH:-1280}"
export CAMOFOX_WINDOW_HEIGHT="${CAMOFOX_WINDOW_HEIGHT:-720}"
if [[ -z "${CAMOFOX_HUMAN_AUTH_ADMIN_KEY:-}" ]]; then
  ENV_PATH="$(hermes config env-path | tr -d '\r\n')"
  if [[ -f "$ENV_PATH" ]]; then
    CAMOFOX_HUMAN_AUTH_ADMIN_KEY="$(grep '^CAMOFOX_HUMAN_AUTH_ADMIN_KEY=' "$ENV_PATH" | tail -n 1 | cut -d= -f2-)"
  fi
fi
export CAMOFOX_ADMIN_KEY="${CAMOFOX_HUMAN_AUTH_ADMIN_KEY:-}"
export PORT="9377"
cd "$ROOT/vendor/camofox-browser"
echo "Starting native Camofox in ${MODE} mode on http://127.0.0.1:9377"
exec npm start

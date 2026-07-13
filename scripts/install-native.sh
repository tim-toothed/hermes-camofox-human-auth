#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v git >/dev/null || { echo 'git is required.' >&2; exit 1; }
command -v node >/dev/null || { echo 'Node.js is required.' >&2; exit 1; }
command -v npm >/dev/null || { echo 'npm is required.' >&2; exit 1; }
command -v hermes >/dev/null || { echo 'Hermes is required.' >&2; exit 1; }

VENDOR="$ROOT/vendor/camofox-browser"
if [[ ! -d "$VENDOR/.git" ]]; then
  mkdir -p "$(dirname "$VENDOR")"
  git clone --depth 1 --branch master https://github.com/jo-inc/camofox-browser.git "$VENDOR"
fi
(
  cd "$VENDOR"
  git fetch --depth 1 origin master
  git checkout --detach origin/master
  git reset --hard HEAD
  git apply --check --ignore-space-change --ignore-whitespace "$ROOT/patches/server-native-headed.patch"
  git apply --ignore-space-change --ignore-whitespace "$ROOT/patches/server-native-headed.patch"
  npm install
)

ENV_PATH="$(hermes config env-path | tr -d '\r\n')"
mkdir -p "$(dirname "$ENV_PATH")" "$ROOT/data/profiles"
touch "$ENV_PATH"
ADMIN_KEY="${CAMOFOX_HUMAN_AUTH_ADMIN_KEY:-$(openssl rand -hex 24 2>/dev/null || python -c 'import secrets; print(secrets.token_hex(24))')}"
for key in CAMOFOX_HUMAN_AUTH_BACKEND CAMOFOX_HUMAN_AUTH_URL CAMOFOX_HUMAN_AUTH_USER_ID CAMOFOX_HUMAN_AUTH_SESSION_KEY CAMOFOX_HUMAN_AUTH_DISPLAY_MODE CAMOFOX_HUMAN_AUTH_PROFILE_DIR CAMOFOX_HUMAN_AUTH_ADMIN_KEY; do
  sed -i.bak "/^${key}=/d" "$ENV_PATH"
done
cat >> "$ENV_PATH" <<EOF
CAMOFOX_HUMAN_AUTH_BACKEND=native
CAMOFOX_HUMAN_AUTH_URL=http://127.0.0.1:9377
CAMOFOX_HUMAN_AUTH_USER_ID=hermes
CAMOFOX_HUMAN_AUTH_SESSION_KEY=native-auth
CAMOFOX_HUMAN_AUTH_DISPLAY_MODE=headless
CAMOFOX_HUMAN_AUTH_PROFILE_DIR=$ROOT/data/profiles
CAMOFOX_HUMAN_AUTH_ADMIN_KEY=$ADMIN_KEY
EOF
rm -f "$ENV_PATH.bak"
echo "Native Camofox installed in $VENDOR"
echo "Hermes env configured at $ENV_PATH"
echo 'Run scripts/start-native.sh headless or headed.'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v docker >/dev/null || { echo 'Docker is required.' >&2; exit 1; }
command -v git >/dev/null || { echo 'Git is required.' >&2; exit 1; }
if [[ ! -f .env ]]; then cp .env.example .env; echo 'Created .env. Set VNC_PASSWORD, then rerun install.sh.'; exit 1; fi
VENDOR="$ROOT/vendor/camofox-browser"
if [[ ! -d "$VENDOR/.git" ]]; then mkdir -p "$(dirname "$VENDOR")"; git clone --depth 1 --branch master https://github.com/jo-inc/camofox-browser.git "$VENDOR"; fi
(
  cd "$VENDOR"
  git fetch --depth 1 origin master
  git checkout --detach origin/master
  test "$(git rev-parse HEAD)" = "ce3a3b085aacba73eb8de6c51733c19fb13bfae4"
  git reset --hard HEAD
)
for patch in "$ROOT"/patches/*.patch; do (cd "$VENDOR" && git apply --check --ignore-space-change --ignore-whitespace "$patch" && git apply --ignore-space-change --ignore-whitespace "$patch"); done
WATCHER="$VENDOR/plugins/vnc/vnc-watcher.sh"
tr -d "$(printf '\\015')" < "$WATCHER" > "$WATCHER.tmp" && mv "$WATCHER.tmp" "$WATCHER"
DIST="$VENDOR/dist"
mkdir -p "$DIST"
ARCH="${CAMOFOX_ARCH:-x86_64}"
if [[ "$ARCH" == "aarch64" ]]; then YTDLP_SUFFIX="_aarch64"; else YTDLP_SUFFIX=""; fi
curl -fL "https://github.com/daijiro/camoufox/releases/download/v135.0.1-beta.24/camoufox-135.0.1-beta.24-lin.${ARCH}.zip" -o "$DIST/camoufox-${ARCH}.zip"
curl -fL "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux${YTDLP_SUFFIX}" -o "$DIST/yt-dlp-${ARCH}"
docker compose up -d --build
if command -v hermes >/dev/null; then
  ENV_PATH="$(hermes config env-path)"
  mkdir -p "$(dirname "$ENV_PATH")"
  touch "$ENV_PATH"
  for pair in CAMOFOX_URL=http://127.0.0.1:9378 CAMOFOX_USER_ID=hermes CAMOFOX_SESSION_KEY=visible-auth CAMOFOX_ADOPT_EXISTING_TAB=true; do key="${pair%%=*}"; grep -v "^${key}=" "$ENV_PATH" > "$ENV_PATH.tmp" || true; mv "$ENV_PATH.tmp" "$ENV_PATH"; echo "$pair" >> "$ENV_PATH"; done
  echo "Hermes env configured. Restart Hermes to load it."
fi
curl -fsS http://127.0.0.1:9378/health

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OS="$(uname -s)"
echo "Detected OS: ${OS}"
echo
echo "Choose Camofox backend:"
echo "1. Local: Native headed/headless"
echo "2. VPS/Server: Docker + noVNC"
read -r -p "Select [1/2]: " CHOICE
case "$CHOICE" in
  1) BACKEND=native; BACKEND_URL=http://127.0.0.1:9377 ;;
  2) BACKEND=docker; BACKEND_URL=http://127.0.0.1:9378 ;;
  *) echo "Choose 1 or 2." >&2; exit 2 ;;
esac

ENV_PATH="$(hermes config env-path | tr -d '\r\n')"
CONFIG_PATH="$(hermes config path | tr -d '\r\n')"
mkdir -p "$(dirname "$ENV_PATH")"
touch "$ENV_PATH"
if grep -q '^CAMOFOX_HUMAN_AUTH_BACKEND=' "$ENV_PATH"; then
  sed -i.bak "s/^CAMOFOX_HUMAN_AUTH_BACKEND=.*/CAMOFOX_HUMAN_AUTH_BACKEND=${BACKEND}/" "$ENV_PATH"
else
  printf '\nCAMOFOX_HUMAN_AUTH_BACKEND=%s\n' "$BACKEND" >> "$ENV_PATH"
fi
rm -f "$ENV_PATH.bak"

if [[ "$BACKEND" == native ]]; then
  "$ROOT/scripts/install-native.sh"
else
  "$ROOT/scripts/install.sh"
fi

provider=""
if [[ -f "$CONFIG_PATH" ]]; then
  provider="$(awk '/^[[:space:]]*cloud_provider:[[:space:]]*/ {print $2; exit}' "$CONFIG_PATH" | tr '[:upper:]' '[:lower:]')"
fi
existing_url=""
if grep -q '^CAMOFOX_URL=' "$ENV_PATH"; then
  existing_url="$(grep '^CAMOFOX_URL=' "$ENV_PATH" | tail -n 1 | cut -d= -f2-)"
fi

set_env_value() {
  local key="$1" value="$2" tmp
  tmp="${ENV_PATH}.tmp"
  grep -v "^${key}=" "$ENV_PATH" > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$ENV_PATH"
}

if [[ -z "$provider" && -z "$existing_url" ]]; then
  echo
echo 'No Hermes browser provider is configured.'
  read -r -p 'Configure Hermes browser provider to Camofox now? [y/N] ' answer
  if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    hermes config set browser.cloud_provider camofox
    set_env_value CAMOFOX_URL "$BACKEND_URL"
    echo 'Hermes browser provider configured: Camofox'
  else
    echo 'Camofox backend installed, but Hermes browser provider was left unchanged.'
  fi
elif [[ -n "$provider" && "$provider" != camofox && -z "$existing_url" ]]; then
  echo
echo "Hermes currently uses browser provider '$provider'."
  read -r -p 'Switch Hermes browser provider to Camofox now? [y/N] ' answer
  if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    hermes config set browser.cloud_provider camofox
    set_env_value CAMOFOX_URL "$BACKEND_URL"
    echo 'Hermes browser provider switched to Camofox.'
  else
    echo 'Existing browser provider preserved; Camofox Human Auth remains separately installed.'
  fi
elif [[ "$provider" == camofox && -z "$existing_url" ]]; then
  echo 'Hermes is configured for Camofox but CAMOFOX_URL is missing.'
  read -r -p "Set CAMOFOX_URL to $BACKEND_URL now? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    set_env_value CAMOFOX_URL "$BACKEND_URL"
  fi
fi

echo "Camofox backend selected: ${BACKEND}"
echo 'Restart Hermes after setup so it loads the selected backend.'

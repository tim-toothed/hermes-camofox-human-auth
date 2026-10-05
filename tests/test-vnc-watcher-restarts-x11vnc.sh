#!/usr/bin/env bash
# Regression test: if x11vnc exits while Xvfb remains on the same display,
# the VNC watcher must start it again.
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
  printf 'Usage: %s /path/to/vnc-watcher.sh\n' "$0" >&2
  exit 2
fi

SOURCE=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
TMP=$(mktemp -d "${TMPDIR:-/tmp}/vnc-watcher-test.XXXXXX")
BIN="$TMP/bin"
mkdir -p "$BIN" "$TMP/logs" "$TMP/novnc"
PID_FILE="$TMP/x11vnc.pid"
STARTS="$TMP/x11vnc-starts"
WATCHER_LOG="$TMP/watcher.log"
WATCHER_PID=""

cleanup() {
  if [[ -n "$WATCHER_PID" ]]; then
    kill "$WATCHER_PID" 2>/dev/null || true
    wait "$WATCHER_PID" 2>/dev/null || true
  fi
  if [[ -f "$PID_FILE" ]]; then
    local child_pid
    IFS= read -r child_pid < "$PID_FILE" || true
    if [[ -n "${child_pid:-}" ]]; then
      kill "$child_pid" 2>/dev/null || true
    fi
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

# Redirect the watcher's fixed production log paths into this isolated test dir.
python3 - "$SOURCE" "$TMP/watcher.sh" "$TMP/logs" "$TMP/novnc" <<'PY'
from pathlib import Path
import sys
source, destination, log_dir, novnc_dir = map(Path, sys.argv[1:])
text = source.read_text()
text = text.replace('/var/log/novnc.log', str(log_dir / 'novnc.log'))
text = text.replace('/var/log/x11vnc.log', str(log_dir / 'x11vnc.log'))
text = text.replace('/usr/share/novnc', str(novnc_dir))
destination.write_text(text)
destination.chmod(0o755)
PY

# Stub only the external services/process discovery. The display stays :99.
python3 - "$BIN" <<'PY'
from pathlib import Path
import sys
bin_dir = Path(sys.argv[1])
stubs = {
    'ps': "#!/bin/sh\nprintf '%s\\n' '/usr/bin/Xvfb :99 -screen 0 1920x1080x24'\n",
    'websockify': "#!/bin/sh\nexit 0\n",
    'x11vnc': "#!/bin/sh\nnohup sleep 120 </dev/null >/dev/null 2>&1 &\nprintf '%s\\n' \"$!\" > \"$PID_FILE\"\nprintf 'start\\n' >> \"$STARTS\"\n",
    'pgrep': "#!/bin/sh\n[ \"$*\" = \"-f x11vnc.*-display :99\" ] || exit 1\n[ -f \"$PID_FILE\" ] || exit 1\nIFS= read -r pid < \"$PID_FILE\" || exit 1\nkill -0 \"$pid\" 2>/dev/null || exit 1\nprintf '%s\\n' \"$pid\"\n",
}
for name, content in stubs.items():
    path = bin_dir / name
    path.write_text(content)
    path.chmod(0o755)
PY

export PATH="$BIN:$PATH"
export PID_FILE STARTS
export VNC_RESOLUTION=1920x1080x24
export VNC_PORT=5911 NOVNC_PORT=6089 VNC_BIND=127.0.0.1

timeout --kill-after=2s 15s "$TMP/watcher.sh" >"$WATCHER_LOG" 2>&1 &
WATCHER_PID=$!

# Wait until the first x11vnc instance is confirmed running on the display.
for ((i=0; i<100; i++)); do
  if [[ -s "$STARTS" ]] && grep -q 'x11vnc running (pid=' "$WATCHER_LOG"; then
    break
  fi
  sleep 0.1
done
if [[ ! -s "$STARTS" ]] || ! grep -q 'x11vnc running (pid=' "$WATCHER_LOG"; then
  printf 'FAIL: watcher did not start x11vnc initially\n' >&2
  cat "$WATCHER_LOG" >&2
  exit 1
fi

IFS= read -r first_pid < "$PID_FILE"
kill "$first_pid"

# The same Xvfb display is still reported; the watcher must notice and retry.
for ((i=0; i<80; i++)); do
  if [[ $(wc -l < "$STARTS") -ge 2 ]]; then
    printf 'PASS: x11vnc restarted on the unchanged Xvfb display\n'
    exit 0
  fi
  sleep 0.1
done

printf 'FAIL: x11vnc was not restarted after its process died\n' >&2
cat "$WATCHER_LOG" >&2
exit 1

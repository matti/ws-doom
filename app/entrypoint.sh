#!/usr/bin/env sh
set -euo pipefail

_term() {
  echo "TERM"
  exit 0
}
_forever () {
  while true; do
    set +e
      $@
    set -e
  done
}
_wait_for_x() {
  while true; do
    >/dev/null 2>&1 xdpyinfo && break
    sleep 0.1
  done
}
trap '_term' TERM

(
  >/dev/null 2>&1 rm /tmp/.X0-lock || true

  exec Xvfb "$DISPLAY" -screen 0 "640x480x24"
) >/tmp/xvfb.log 2>&1 &
xvfb_pid=$!

(
  _wait_for_x
  x11vnc \
    -display "$DISPLAY" \
    -shared \
    -clear_all \
    -loop0 \
    -nolookup \
    -nocursor \
    -nopw
) >/tmp/x11vnc.log 2>&1 &
x11vnc_pid=$!

(
  _forever
) >/tmp/chocolate-doom.log 2>&1 &

if [ "${WSDOOM_RESET_ON_DISCONNECT:-}" = "yes" ]; then
  cp /app/websockify-exit-on-disconnect.js /opt/websockify-js/websockify/websockify.js
fi

(
  while true; do
    (
      exec chocolate-doom -nogui -iwad /doom1.wad -window -nograbmouse -nosound -nomouse -config /app/chocolate-doom.cfg
    ) >/tmp/chocolate-doom.log 2>&1 &
    chocolate_doom_pid=$!

    (
      node /opt/websockify-js/websockify/websockify.js  --web /app/public :8080 127.0.0.1:5900
    ) >/tmp/websockify.js 2>&1 &
    websockify_pid=$!

    while true; do
      >/dev/null 2>&1 kill -0 $chocolate_doom_pid || break
      >/dev/null 2>&1 kill -0 $websockify_pid || break
      sleep 0.5
    done

    (
      set +e
        kill -9 $chocolate_doom_pid
        kill -9 $websockify_pid
      set -e
    ) >/dev/null 2>&1 &
  done
) &


wait $xvfb_pid

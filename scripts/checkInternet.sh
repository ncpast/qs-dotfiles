#!/usr/bin/env bash
set -u

json_out() {
  printf '{"type":%s,"score":%s}\n' "$1" "$2"
}

IFACE=$(
  ip route get 1.1.1.1 2>/dev/null |
    awk '{for (i=1; i<=NF; i++) if ($i=="dev") {print $(i+1); exit}}'
)

if [[ -z "${IFACE:-}" ]]; then
  json_out null null
  exit 1
fi

if [[ -d "/sys/class/net/$IFACE/wireless" ]]; then
  TYPE='"wifi"'

  SIGNAL=""
  if command -v iw >/dev/null 2>&1; then
    SIGNAL=$(
      iw dev "$IFACE" link 2>/dev/null |
        awk -F': ' '/signal:/{print $2; exit}' |
        awk '{print int($1)}'
    )
  fi

  if [[ -n "${SIGNAL:-}" ]]; then
    if   (( SIGNAL >= -50 )); then SCORE=5
    elif (( SIGNAL >= -60 )); then SCORE=4
    elif (( SIGNAL >= -67 )); then SCORE=3
    elif (( SIGNAL >= -75 )); then SCORE=2
    else SCORE=1
    fi

    json_out "$TYPE" "$SCORE"
    exit 0
  fi

  QUALITY=$(
    awk -v i="${IFACE}:" '$1==i {gsub(/\./,"",$3); print int($3); exit}' \
      /proc/net/wireless 2>/dev/null
  )

  if [[ -n "${QUALITY:-}" ]]; then
    if   (( QUALITY >= 56 )); then SCORE=5
    elif (( QUALITY >= 42 )); then SCORE=4
    elif (( QUALITY >= 28 )); then SCORE=3
    elif (( QUALITY >= 14 )); then SCORE=2
    else SCORE=1
    fi

    json_out "$TYPE" "$SCORE"
    exit 0
  fi

  json_out "$TYPE" null
else
  json_out '"ethernet"' null
fi
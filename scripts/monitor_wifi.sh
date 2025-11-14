#!/usr/bin/env bash
# monitor_wifi.sh - Termux: scan wifi and log key fields
set -euo pipefail

LOG_DIR="${HOME}/wifi_monitor"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/wifi_$(date +%F).log"

# default interval (seconds)
INTERVAL_SEC="${INTERVAL_SEC:-30}"

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

scan_once() {
  # requires termux-wifi-scaninfo and jq
  if ! command -v termux-wifi-scaninfo >/dev/null 2>&1; then
    echo "ERROR: termux-wifi-scaninfo not found" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq not found" >&2
    exit 1
  fi

  local raw
  raw=$(termux-wifi-scaninfo 2>/dev/null || echo "[]")
  # pretty list: SSID | BSSID | RSSI | FREQ | CAPABILITIES
  echo "$(timestamp) - scan result:" >> "$LOG_FILE"
  echo "$raw" \
    | jq -r '.[] | "\(.ssid) \t \(.bssid) \t rssi=\(.rssi) \t freq=\(.frequency_mhz) \t caps=\(.capabilities)"' \
    | tee -a "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

# single-run mode if argument provided
if [[ "${1:-}" == "--once" || "${1:-}" == "-1" ]]; then
  scan_once
  exit 0
fi

# continuous loop
echo "Starting wifi monitor. Logging to: $LOG_FILE"
echo "Press Ctrl+C to stop."
while true; do
  scan_once
  sleep "$INTERVAL_SEC"
done

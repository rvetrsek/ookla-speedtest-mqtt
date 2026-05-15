#!/bin/bash
set -euo pipefail
trap 'rc=$?; log "ERROR: speedtest.sh failed on line $LINENO (exit code $rc)"' ERR

RESULTS_FORMAT="json"
RESULTS_PATH="/tmp/speedtest-results"
SPEEDTEST_STDERR="/tmp/speedtest-results.err"
FIRST_START_PATH="/first_start"

log() {
  echo "$(date +%D_%T) - $*" >>/proc/1/fd/1
}

dump_file_to_log() {
  local label="$1" path="$2"
  if [ -s "$path" ]; then
    log "$label:"
    cat "$path" >>/proc/1/fd/1
  fi
}

convertmbps() {
  jq '.download.bandwidth = (.download.bandwidth / 125000.0) | .upload.bandwidth = (.upload.bandwidth / 125000.0)' \
    "$RESULTS_PATH" >"${RESULTS_PATH}.tmp" && mv "${RESULTS_PATH}.tmp" "$RESULTS_PATH"
}

publish_mqtt() {
  if [ -n "${MQTT_PASS:-}" ]; then
    log "Sending JSON data to $MQTT_SERVER..."
    mosquitto_pub -u "$MQTT_USER" -P "$MQTT_PASS" -h "$MQTT_SERVER" -t "$MQTT_TOPIC" -f "$RESULTS_PATH"
  else
    log "Sending JSON data to $MQTT_SERVER with no authentication..."
    mosquitto_pub -h "$MQTT_SERVER" -t "$MQTT_TOPIC" -f "$RESULTS_PATH"
  fi
}

# Build speedtest args; accept license/GDPR on first run only
SPEEDTEST_ARGS="--format=$RESULTS_FORMAT"

# if [ ! -f "$FIRST_START_PATH" ]; then
#    touch "$FIRST_START_PATH"
SPEEDTEST_ARGS="$SPEEDTEST_ARGS --accept-license --accept-gdpr"
# fi

if [ -n "${SERVER_ID:-}" ]; then
  log "Running Ookla speed test using specified server..."
  SPEEDTEST_ARGS="$SPEEDTEST_ARGS --server-id=$SERVER_ID"
else
  log "Running Ookla speed test..."
fi

touch "$RESULTS_PATH"
: >"$SPEEDTEST_STDERR"
log "speedtest args: $SPEEDTEST_ARGS"

# Run speedtest, capturing stderr so we can see why it failed (cron has no MTA).
# Disable -e around the call so we can format diagnostics before exiting.
set +e
# shellcheck disable=SC2086
speedtest $SPEEDTEST_ARGS >"$RESULTS_PATH" 2>"$SPEEDTEST_STDERR"
rc=$?
set -e

if [ "$rc" -ne 0 ]; then
  log "ERROR: speedtest exited with code $rc"
  dump_file_to_log "speedtest stderr" "$SPEEDTEST_STDERR"
  dump_file_to_log "speedtest stdout" "$RESULTS_PATH"
  rm -f "$SPEEDTEST_STDERR" "$RESULTS_PATH"
  exit "$rc"
fi

# Surface any stderr noise even on success (warnings, deprecations, etc.)
dump_file_to_log "speedtest stderr (non-fatal)" "$SPEEDTEST_STDERR"
rm -f "$SPEEDTEST_STDERR"

# Strip any license/GDPR preamble that appears before the JSON on first run
if ! head -1 "$RESULTS_PATH" | grep -q '^{'; then
  sed -n '/^{/,$p' "$RESULTS_PATH" >"${RESULTS_PATH}.tmp" && mv "${RESULTS_PATH}.tmp" "$RESULTS_PATH"
fi

convertmbps
publish_mqtt

log "Sending JSON results to log for troubleshooting..."
cat "$RESULTS_PATH" >>/proc/1/fd/1
log "Cleaning up for the next run..."
rm "$RESULTS_PATH"
log "Finished..."

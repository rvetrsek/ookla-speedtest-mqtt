#!/bin/bash
set -euo pipefail
trap 'log "ERROR: speedtest.sh failed on line $LINENO"' ERR

RESULTS_FORMAT="json"
RESULTS_PATH="/tmp/speedtest-results"
FIRST_START_PATH="/first_start"

log() {
    echo "$(date +%D_%T) - $*" >> /proc/1/fd/1
}

convertmbps() {
    jq '.download.bandwidth = (.download.bandwidth / 125000.0) | .upload.bandwidth = (.upload.bandwidth / 125000.0)' \
        "$RESULTS_PATH" > "${RESULTS_PATH}.tmp" && mv "${RESULTS_PATH}.tmp" "$RESULTS_PATH"
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

if [ ! -f "$FIRST_START_PATH" ]; then
    touch "$FIRST_START_PATH"
    SPEEDTEST_ARGS="$SPEEDTEST_ARGS --accept-license --accept-gdpr"
fi

if [ -n "${SERVER_ID:-}" ]; then
    log "Running Ookla speed test using specified server..."
    SPEEDTEST_ARGS="$SPEEDTEST_ARGS --server-id=$SERVER_ID"
else
    log "Running Ookla speed test..."
fi

touch "$RESULTS_PATH"
# shellcheck disable=SC2086
speedtest $SPEEDTEST_ARGS > "$RESULTS_PATH"

# Strip any license/GDPR preamble that appears before the JSON on first run
if ! head -1 "$RESULTS_PATH" | grep -q '^{'; then
    sed -n '/^{/,$p' "$RESULTS_PATH" > "${RESULTS_PATH}.tmp" && mv "${RESULTS_PATH}.tmp" "$RESULTS_PATH"
fi

convertmbps
publish_mqtt

log "Sending JSON results to log for troubleshooting..."
cat "$RESULTS_PATH" >> /proc/1/fd/1
log "Cleaning up for the next run..."
rm "$RESULTS_PATH"
log "Finished..."

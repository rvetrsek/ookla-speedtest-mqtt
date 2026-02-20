#!/bin/bash
set -euo pipefail

log() {
    echo "$(date +%D_%T) - $*" >> /proc/1/fd/1
}

# Validate required environment variables
: "${MQTT_SERVER:?MQTT_SERVER is required}"
: "${MQTT_TOPIC:?MQTT_TOPIC is required}"
: "${CRON:?CRON is required}"

# Test cron expression
cron_regex_test() {
    local CRONEXP="$1"
    local REGEX='^((((\d+,)+\d+|(\d+(\/|-|#)\d+)|\d+L?|\*(\/\d+)?|L(-\d+)?|\?|[A-Z]{3}(-[A-Z]{3})?) ?){5,7})|(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(@every (\d+(s|m|h))+)$'
    echo "$CRONEXP" | grep -Pq "$REGEX"
}

log "Cron expression was specified, testing..."
if cron_regex_test "$CRON"; then
    log "Cron expression is valid: $CRON"
else
    log "ERROR: Cron expression is invalid: $CRON. Exiting."
    exit 1
fi

log "Setting up cron job..."
echo "$CRON /usr/bin/speedtest.sh" | crontab - || { log "ERROR: Failed to install crontab. Exiting."; exit 1; }

# Export only the variables speedtest.sh needs so cron can see them
{
    echo "MQTT_SERVER=\"$MQTT_SERVER\""
    echo "MQTT_TOPIC=\"$MQTT_TOPIC\""
    [ -n "${MQTT_USER:-}" ] && echo "MQTT_USER=\"$MQTT_USER\""
    [ -n "${MQTT_PASS:-}" ] && echo "MQTT_PASS=\"$MQTT_PASS\""
    [ -n "${SERVER_ID:-}" ] && echo "SERVER_ID=\"$SERVER_ID\""
    [ -n "${TZ:-}" ] && echo "TZ=\"$TZ\""
} > /etc/environment

log "Running cron in foreground..."
exec cron -f

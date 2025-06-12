#!/bin/bash

#variables
LOG_DATE_FORMAT="$(date +%D_%T)"

#test cron expression
cron_regex_test() { 
    local CRONEXP="$1"
    local REGEX='^((((\d+,)+\d+|(\d+(\/|-|#)\d+)|\d+L?|\*(\/\d+)?|L(-\d+)?|\?|[A-Z]{3}(-[A-Z]{3})?) ?){5,7})|(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(@every (\d+(s|m|h))+)$'
    if echo "$CRONEXP" | grep -Pq "$REGEX"; then
        return 0  #cron expression is valid
    else
        return 1  #cron expression is invalid
    fi
}

#setup cron job
if [[ -n $CRON ]]; then
        echo "$LOG_DATE_FORMAT - Cron expression was specified, testing..." &> /proc/1/fd/1
        if cron_regex_test "$CRON"; then
                echo "$LOG_DATE_FORMAT - Cron expression is valid: $CRON" &> /proc/1/fd/1
                echo "$LOG_DATE_FORMAT - Setting up cron job..." &> /proc/1/fd/1
                echo "$CRON /usr/bin/speedtest.sh" | crontab -  &> /proc/1/fd/1
        else
                echo "$LOG_DATE_FORMAT - Cron expression was invalid: $CRON, defaulting to hourly so the container can start up..." &> /proc/1/fd/1
                echo "$LOG_DATE_FORMAT - Setting up cron job..." &> /proc/1/fd/1
                echo "0 * * * * /usr/bin/speedtest.sh" | crontab -  &> /proc/1/fd/1
        fi
else
        echo "$LOG_DATE_FORMAT - Cron expression was not specified, defaulting to hourly..." &> /proc/1/fd/1
        echo "$LOG_DATE_FORMAT - Setting up cron job..." &> /proc/1/fd/1
        echo "0 * * * * /usr/bin/speedtest.sh" | crontab -  &> /proc/1/fd/1
fi

#export env vars so cron can see them
printenv > /etc/environment

#run cron in forground to keep container alive
echo "$LOG_DATE_FORMAT - Running cron in foreground..." &> /proc/1/fd/1
cron -f  &> /proc/1/fd/
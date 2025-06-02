#!/bin/bash

#variables
LOG_DATE_FORMAT="$(date +%D_%T)"

#setup cron job
echo "$LOG_DATE_FORMAT - Setting up cron job..." &> /proc/1/fd/1
echo "0 * * * * /usr/bin/speedtest.sh" | crontab -  &> /proc/1/fd/1

#export env vars so cron can see them
printenv > /etc/environment

#run cron in forground to keep container alive
echo "$LOG_DATE_FORMAT - Running cron in foreground..." &> /proc/1/fd/1
cron -f  &> /proc/1/fd/1
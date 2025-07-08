#!/bin/bash

#functions and variables
mqttwithpass() {
	mosquitto_pub -u $MQTT_USER -P $MQTT_PASS -h $MQTT_SERVER -t $MQTT_TOPIC -f $RESULTS_PATH
}

mqttnopass() {
	mosquitto_pub -h $MQTT_SERVER -t $MQTT_TOPIC -f $RESULTS_PATH
}

convertmbps() {
	jq ".download.bandwidth = "$(echo "scale=2; $(jq -r '.download.bandwidth' $RESULTS_PATH)/125000" | bc)"" $RESULTS_PATH | sponge $RESULTS_PATH
	jq ".upload.bandwidth = "$(echo "scale=2; $(jq -r '.upload.bandwidth' $RESULTS_PATH)/125000" | bc)"" $RESULTS_PATH | sponge $RESULTS_PATH
}

RESULTS_FORMAT="json-pretty"
RESULTS_PATH="/tmp/speedtest-results"
FIRST_START_PATH="/first_start"
LOG_DATE_FORMAT="$(date +%D_%T)"

#check if container has been started before
if [ ! -f $FIRST_START_PATH ]; then
	touch $FIRST_START_PATH
	touch $RESULTS_PATH

    if [[ "${SERVER_ID}" ]]; then
		echo "$LOG_DATE_FORMAT - Running Ookla speed test using specified server..." &> /proc/1/fd/1
        speedtest --accept-license --accept-gdpr --server-id=$SERVER_ID --format=$RESULTS_FORMAT &> $RESULTS_PATH
    else
		echo "$LOG_DATE_FORMAT - Running Ookla speed test..." &> /proc/1/fd/1
        speedtest --accept-license --accept-gdpr --format=$RESULTS_FORMAT &> $RESULTS_PATH
    fi

	#since this is the first run, the license acceptance info shows up at the beginning of our output
	sed -i '1,16d' $RESULTS_PATH

	#the default value from the speedtest is in bytes, here we convert that to Mbps
	convertmbps

	if [[ "${MQTT_PASS}" ]]; then
		echo "$LOG_DATE_FORMAT - Sending JSON data to $MQTT_SERVER..." &> /proc/1/fd/1
		mqttwithpass

	else
		echo "$LOG_DATE_FORMAT - Sending JSON data to $MQTT_SERVER with no authentication..." &> /proc/1/fd/1
		mqttnopass
	fi

	echo "$LOG_DATE_FORMAT - Sending JSON results to log for troubleshooting..." &> /proc/1/fd/1
	echo $(<$RESULTS_PATH) &> /proc/1/fd/1
	echo "$LOG_DATE_FORMAT - Cleaning up for the next run..." &> /proc/1/fd/1
	rm $RESULTS_PATH
	echo "$LOG_DATE_FORMAT - First run is complete. License and GDPR have been accepted." &> /proc/1/fd/1
	echo "$LOG_DATE_FORMAT - Finished..." &> /proc/1/fd/1
else
	#if container has been started before, stdout is fine, no license acceptance
	touch $RESULTS_PATH

	if [[ "${SERVER_ID}" ]]; then
		echo "$LOG_DATE_FORMAT - Running Ookla speed test using specified server..." &> /proc/1/fd/1
		speedtest --server-id=$SERVER_ID --format=$RESULTS_FORMAT &> $RESULTS_PATH
	else
		echo "$LOG_DATE_FORMAT - Running Ookla speed test..." &> /proc/1/fd/1
		speedtest --format=$RESULTS_FORMAT &> $RESULTS_PATH
	fi

	#the default value from the speedtest is in bytes, here we convert that to Mbps
	convertmbps

	if [[ "${MQTT_PASS}" ]]; then
		echo "$LOG_DATE_FORMAT - Sending JSON data to $MQTT_SERVER..." &> /proc/1/fd/1
		mqttwithpass
	else
		echo "$LOG_DATE_FORMAT - Sending JSON data to $MQTT_SERVER with no authentication..." &> /proc/1/fd/1
		mqttnopass
	fi
	
	echo "$LOG_DATE_FORMAT - Sending JSON results to log for troubleshooting..." &> /proc/1/fd/1
	echo $(<$RESULTS_PATH) &> /proc/1/fd/1
	echo "$LOG_DATE_FORMAT - Cleaning up for the next run..." &> /proc/1/fd/1
	rm $RESULTS_PATH
	echo "$LOG_DATE_FORMAT - Finished..." &> /proc/1/fd/1
fi
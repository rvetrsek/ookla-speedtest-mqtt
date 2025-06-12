# ookla-speedtest-mqtt
![Image Build Status](https://img.shields.io/github/actions/workflow/status/ccmpbll/ookla-speedtest-mqtt/docker-image.yml?branch=main) ![Docker Image Size](https://img.shields.io/docker/image-size/ccmpbll/ookla-speedtest-mqtt/latest) ![Docker Pulls](https://img.shields.io/docker/pulls/ccmpbll/ookla-speedtest-mqtt.svg) ![License](https://img.shields.io/badge/License-GPLv3-blue.svg)

A simple container designed to send JSON formatted Ookla speed test results over MQTT. Uses [Ookla's Speedtest CLI tool](https://www.speedtest.net/apps/cli).

### Required environment variables:

**MQTT_SERVER:** IP address of MQTT server

**MQTT_TOPIC:** Topic for speed test results

**CRON:** Cron schedule expression - "0 * * * *" - define how often tests are run

**TZ:** Set timezone - Uses standard tz database format - America/New_York

### Optional environment variables:

**SERVER_ID:** Specify a server using its numeric ID

**MQTT_USER:** MQTT username

**MQTT_PASS:** MQTT password

### Example:
```
docker run -d -e MQTT_TOPIC='ookla-speedtest/results' -e MQTT_SERVER_='192.168.1.10' -e CRON='0 * * * *' -e TZ='America/New_York' ccmpbll/ookla-speedtest-mqtt:latest
```

### Telegraf Config Example:

I use Telegraf to get this data into an InfluxDB instance. Below is an excerpt from my Telegraf config that demonstrates how I accomplish this.
If there is a better way to do this, I am *very* open to suggestions.

```TOML
[[inputs.mqtt_consumer]]
        name_override = "<WHAT YOU WANT THE INFLUXDB TABLE TO BE CALLED>"
        servers = ["tcp://<YOUR MQTT SERVER IP>:1883"]
        topics = ["<YOUR MQTT TOPIC>"]
        data_format = "json_v2"
[[inputs.mqtt_consumer.json_v2]]
[[inputs.mqtt_consumer.json_v2.field]]
        path = "ping.jitter"
        rename = "ping_jitter"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "ping.latency"
        rename = "ping_latency"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "ping.low"
        rename = "ping_low"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "ping.high"
        rename = "ping_high"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "download.bandwidth"
        rename = "download_bandwidth"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "download.latency.iqm"
        rename = "download_latency_iqm"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "download.latency.low"
        rename = "download_latency_low"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "download.latency.high"
        rename = "download_latency_high"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "download.latency.jitter"
        rename = "download_latency_jitter"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "upload.bandwidth"
        rename = "upload_bandwidth"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "upload.latency.iqm"
        rename = "upload_latency_iqm"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "upload.latency.low"
        rename = "upload_latency_low"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "upload.latency.high"
        rename = "upload_latency_high"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "upload.latency.jitter"
        rename = "upload_latency_jitter"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "packetLoss"
        rename = "packet_loss"
        type = "float"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "isp"
        rename = "isp"
        type = "string"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "interface.externalIp"
        rename = "external_ip"
        type = "string"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "server.id"
        rename = "server_id"
        type = "string"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "server.name"
        rename = "server_name"
        type = "string"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "server.location"
        rename = "server_location"
        type = "string"
[[inputs.mqtt_consumer.json_v2.field]]
        path = "server.country"
        rename = "server_country"
        type = "string"
```
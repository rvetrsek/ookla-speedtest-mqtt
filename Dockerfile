FROM debian:trixie-slim
LABEL Name=ookla-speedtest-mqtt
LABEL maintainer="Chris Campbell"

ARG SPEEDTEST_CLI_VERSION="1.2.0"
ENV TZ=

RUN apt-get update && apt-get full-upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates tzdata bash cron wget jq mosquitto-clients \
    && wget -q https://install.speedtest.net/app/cli/ookla-speedtest-${SPEEDTEST_CLI_VERSION}-linux-x86_64.tgz \
        -O /tmp/ookla-speedtest.tgz \
    && tar zxf /tmp/ookla-speedtest.tgz -C /tmp speedtest \
    && mv /tmp/speedtest /bin/speedtest \
    && chmod +x /bin/speedtest \
    && rm /tmp/ookla-speedtest.tgz \
    && apt-get remove -y wget \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 speedtest.sh /usr/bin/
COPY --chmod=755 entrypoint.sh /usr/bin/

ENTRYPOINT ["entrypoint.sh"]

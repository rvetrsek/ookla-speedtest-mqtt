FROM debian:bookworm-slim
LABEL Name=ookla-speedtest-mqtt
LABEL maintainer="Chris Campbell"

ARG SPEEDTEST_CLI_VERSION="1.2.0"

RUN apt update && apt full-upgrade -y
RUN apt install tzdata bash cron curl wget nano jq bc moreutils mosquitto-clients -y
RUN apt clean && apt autoremove -y

RUN wget https://install.speedtest.net/app/cli/ookla-speedtest-${SPEEDTEST_CLI_VERSION}-linux-x86_64.tgz -O /tmp/ookla-speedtest.tgz

RUN tar zxvf /tmp/ookla-speedtest.tgz -C /tmp speedtest
RUN mv /tmp/speedtest /bin/speedtest
RUN ["chmod", "+x", "/bin/speedtest"]
RUN rm /tmp/ookla-speedtest.tgz

ENV TZ=

COPY speedtest.sh /usr/bin
RUN ["chmod", "+x", "/usr/bin/speedtest.sh"]

RUN echo "0 * * * * /usr/bin/speedtest.sh" | crontab -

CMD ["cron", "-f"]

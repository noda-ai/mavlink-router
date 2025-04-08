FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        meson \
        ninja-build \
        gcc \
        g++ \
        net-tools \
        gettext \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY . /mavlink-router

RUN cd /mavlink-router \
    && rm -rf build \
    && meson setup -Dsystemdsystemunitdir=/usr/lib/systemd/system --buildtype=release build .  \
    && ninja -C build

# Create directory for config
RUN mkdir -p /etc/mavlink-router

# Copy the template file
COPY main.conf.tpl /etc/mavlink-router/main.conf.tpl

# # Set default values for environment variables
# ENV GCS_IP=192.168.1.100
# ENV GCS_PORT=14550

# Create a simple entrypoint script
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'sed -e "s/{GCS_IP}/$GCS_IP/g" -e "s/{GCS_PORT}/$GCS_PORT/g" /etc/mavlink-router/main.conf.tpl > /etc/mavlink-router/main.conf' >> /entrypoint.sh && \
    echo 'exec /mavlink-router/build/src/mavlink-routerd -c /etc/mavlink-router/main.conf "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Use entrypoint script to substitute variables and start mavlink-routerd
ENTRYPOINT ["/entrypoint.sh"]

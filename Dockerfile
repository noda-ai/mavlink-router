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

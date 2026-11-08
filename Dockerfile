# syntax=docker/dockerfile:1
# DCS World dedicated server under Wine Staging (ntsync-enabled build).
FROM archlinux:base-20261101.0.620205

# Pin all packages to one Arch Linux Archive snapshot for reproducible builds.
ARG ARCH_ARCHIVE_DATE=2026/11/07
ARG NOVNC_VERSION=1.7.0
ARG NOVNC_SHA256=b1003a11b6e6e8d8f7f5e5586daae7f8ca651d8aee0aa155ff9ac841c48f52c6
ARG WEBSOCKIFY_VERSION=0.13.0
ARG WEBSOCKIFY_SHA256=b6413e364efd04f3c92ec8c17747e3c4adc20157c2ef1c5d019a26d944a46df8

RUN echo "Server = https://archive.archlinux.org/repos/${ARCH_ARCHIVE_DATE}/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist \
 && pacman -Syyuu --noconfirm \
 && pacman -S --noconfirm --needed \
      wine-staging \
      xorg-server-xvfb openbox x11vnc xdotool \
      python unzip patch curl procps-ng \
 && pacman -Scc --noconfirm \
 && rm -rf /var/cache/pacman/pkg/*

# noVNC + websockify are not packaged by Arch; install pinned upstream releases.
RUN curl -fsSL -o /tmp/novnc.tgz "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz" \
 && echo "${NOVNC_SHA256}  /tmp/novnc.tgz" | sha256sum -c - \
 && curl -fsSL -o /tmp/websockify.tgz "https://github.com/novnc/websockify/archive/refs/tags/v${WEBSOCKIFY_VERSION}.tar.gz" \
 && echo "${WEBSOCKIFY_SHA256}  /tmp/websockify.tgz" | sha256sum -c - \
 && mkdir -p /opt/novnc /opt/websockify \
 && tar -xzf /tmp/novnc.tgz -C /opt/novnc --strip-components=1 \
 && tar -xzf /tmp/websockify.tgz -C /opt/websockify --strip-components=1 \
 && ln -s vnc.html /opt/novnc/index.html \
 && rm /tmp/novnc.tgz /tmp/websockify.tgz

RUN useradd --uid 1000 --user-group --create-home --home-dir /home/dcs dcs \
 && mkdir -p /data && chown dcs:dcs /data

COPY --chmod=0755 rootfs/usr/local/bin/ /usr/local/bin/
COPY rootfs/opt/dcs/ /opt/dcs/

ENV LANG=C.UTF-8 \
    USER=dcs \
    HOME=/home/dcs \
    WINEPREFIX=/data/wine \
    WINEARCH=win64 \
    WINEDEBUG=-all \
    DISPLAY=:0

USER dcs
WORKDIR /data
# 6080: noVNC, 10308: DCS (tcp+udp), 8088: DCS WebGUI API (keep internal)
EXPOSE 6080 10308/tcp 10308/udp 8088
ENTRYPOINT ["/usr/local/bin/dcs-entrypoint"]

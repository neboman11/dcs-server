# syntax=docker/dockerfile:1
# DCS World dedicated server under Wine Staging (ntsync-enabled build).
FROM archlinux:base-20261101.0.620205

# Pin all packages to one Arch Linux Archive snapshot for reproducible builds.
ARG ARCH_ARCHIVE_DATE=2026/11/07
ARG NOVNC_VERSION=1.7.0
ARG NOVNC_SHA256=b1003a11b6e6e8d8f7f5e5586daae7f8ca651d8aee0aa155ff9ac841c48f52c6
ARG WEBSOCKIFY_VERSION=0.13.0
ARG WEBSOCKIFY_SHA256=b6413e364efd04f3c92ec8c17747e3c4adc20157c2ef1c5d019a26d944a46df8
# SimpleRadio Standalone server (native Linux build)
ARG SRS_VERSION=2.4.1.0
ARG SRS_SHA256=46268dd35204d04426974f66d25eaddaebbaa6b133a7bd227675fae30ed88127
# Tacview DCS exporter, redistributed by ActiumDev/dcs-server-wine with Raia Software's permission
# for dedicated servers; fetched (not vendored) at a pinned commit.
ARG ACTIUM_COMMIT=7ab1812bb2896dae1559cab08d638ec275782e92
ARG TACVIEW_DLL_SHA256=a8710018d5e07983cadc0aee84093b7f76e4d35b632db76504e95e7aed2c9544
ARG TACVIEW_EXPORT_SHA256=a41a35afb91530581865243bb976caee465fb92009baaa2a3554c09a1cafaa27
ARG TACVIEW_GUI_SHA256=b155f8c78bb22dff3b98de10d80a218ccb703ee9e56d556c4c4274ff9eb8d8f1
ARG TACVIEW_README_SHA256=9e730448bc213807bc7588e5f0c6f6e70e0d16d258f2ab79e06681afe0150a5d
# DCSServerBot runs under Wine on Windows Python (all compiled deps ship win_amd64 wheels).
ARG PYTHON_WIN_VERSION=3.14.10
ARG PYTHON_WIN_SHA256=92480239264744fe0386a1bd8275786fefa126e3129e56a68e22b52c73329965
# MFC (mfc140u.dll) for pywin32's win32ui, which DCSServerBot imports via pywinauto.
ARG VC_REDIST_URL=https://download.visualstudio.microsoft.com/download/pr/e9604e21-4b79-4096-a4b3-1b63d4b55b4d/CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B/VC_redist.x64.exe
ARG VC_REDIST_SHA256=cc0ff0eb1dc3f5188ae6300faef32bf5beeba4bdd6e8e445a9184072096b713b

RUN echo "Server = https://archive.archlinux.org/repos/${ARCH_ARCHIVE_DATE}/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist \
 && pacman -Syyuu --noconfirm \
 && pacman -S --noconfirm --needed \
      wine-staging \
      xorg-server-xvfb openbox x11vnc xdotool \
      python unzip patch curl procps-ng samba \
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

RUN mkdir -p /opt/srs \
 && curl -fsSL -o /opt/srs/SRS-Server-Commandline "https://github.com/ciribob/DCS-SimpleRadioStandalone/releases/download/${SRS_VERSION}/SRS-Server-Commandline-Linux" \
 && echo "${SRS_SHA256}  /opt/srs/SRS-Server-Commandline" | sha256sum -c - \
 && chmod 0755 /opt/srs/SRS-Server-Commandline \
 && echo "${SRS_VERSION}" > /opt/srs/version.txt

RUN set -e; a="https://raw.githubusercontent.com/ActiumDev/dcs-server-wine/${ACTIUM_COMMIT}/.wine/drive_c/Tacview"; \
    t=/opt/dcs/Tacview; mkdir -p "$t/Mods/Tech/Tacview/bin" "$t/Scripts/Hooks"; \
    curl -fsSL -o "$t/Mods/Tech/Tacview/bin/tacview.dll" "https://media.githubusercontent.com/media/ActiumDev/dcs-server-wine/${ACTIUM_COMMIT}/.wine/drive_c/Tacview/Mods/Tech/Tacview/bin/tacview.dll"; \
    curl -fsSL -o "$t/Scripts/TacviewGameExport.lua" "$a/Scripts/TacviewGameExport.lua"; \
    curl -fsSL -o "$t/Scripts/Hooks/TacviewGameGUI.lua" "$a/Scripts/Hooks/TacviewGameGUI.lua"; \
    curl -fsSL -o "$t/README.md" "$a/README.md"; \
    printf '%s  %s\n' "${TACVIEW_DLL_SHA256}" "$t/Mods/Tech/Tacview/bin/tacview.dll" \
      "${TACVIEW_EXPORT_SHA256}" "$t/Scripts/TacviewGameExport.lua" \
      "${TACVIEW_GUI_SHA256}" "$t/Scripts/Hooks/TacviewGameGUI.lua" \
      "${TACVIEW_README_SHA256}" "$t/README.md" | sha256sum -c -

RUN mkdir -p /opt/python-win \
 && curl -fsSL -o /opt/python-win/python-installer.exe "https://www.python.org/ftp/python/${PYTHON_WIN_VERSION}/python-${PYTHON_WIN_VERSION}-amd64.exe" \
 && echo "${PYTHON_WIN_SHA256}  /opt/python-win/python-installer.exe" | sha256sum -c - \
 && echo "${PYTHON_WIN_VERSION}" > /opt/python-win/version.txt \
 && curl -fsSL -o /opt/python-win/vc_redist.x64.exe "${VC_REDIST_URL}" \
 && echo "${VC_REDIST_SHA256}  /opt/python-win/vc_redist.x64.exe" | sha256sum -c -

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
# 6080: noVNC, 10308: DCS, 5002: SRS, 42674: Tacview realtime, 445: SMB (sidecars), 8088: DCS WebGUI API (internal)
EXPOSE 6080 10308/tcp 10308/udp 5002/tcp 5002/udp 42674/tcp 445/tcp 8088
ENTRYPOINT ["/usr/local/bin/dcs-entrypoint"]

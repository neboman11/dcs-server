# dcs-server

Container image for the DCS World dedicated server on Linux, using Arch Linux's
`wine-staging` build (compiled with ntsync support) and a headless X display with
noVNC for the one-time login and installer UI.

Deployed by [argocd-definitions](https://github.com/neboman11/argocd-definitions) (`dcs/dcs-server`).

## Runtime layout

| Path | Contents |
|---|---|
| `/data/wine` | Wine prefix (persist this volume) |
| `/data/wine/drive_c/DCS_server` | DCS install, managed by `DCS_updater.exe` |
| `/data/wine/drive_c/DCS_configs/DCS.server` | Server writedir (`Saved Games\DCS.server`): `Config/`, `Missions/`, `Logs/`, `Scripts/Hooks/` |

## Environment

| Variable | Default | Purpose |
|---|---|---|
| `VNC_PASSWORD` | required | noVNC/VNC password (port 6080) |
| `DCS_MODE` | `server` | `server`, `benchmark` (ActiumDev benchmark missions in the server writedir), or `desktop` (display only) |
| `DCS_TERRAINS` | `CAUCASUS_terrain` | Space-separated module IDs; missing ones are installed on start |
| `DCS_AUTO_UPDATE` | `false` | Run `DCS_updater.exe update` on every start |
| `DCS_DESANITIZE` | empty | Lua modules to un-sanitize in `MissionScripting.lua` (e.g. `io lfs` for Liberation/DCC). Only run trusted missions. |
| `DCS_SERVER_NAME` / `DCS_SERVER_PASSWORD` / `DCS_MAX_PLAYERS` | empty | Enforced into `serverSettings.lua` on start when set |
| `TACVIEW_ENABLE` / `TACVIEW_REALTIME` / `TACVIEW_REALTIME_PORT` / `TACVIEW_REALTIME_PASSWORD` | `false` / `false` / `42674` / empty | Server-side Tacview recording to `DCS.server/Tacview` and optional live telemetry; settings are written into `Config/options.lua` on start |
| `SRS_ENABLE` | `false` | Install the SRS autoconnect hook (SRS itself runs as the `srs-server` sidecar) |
| `DCSSB_ENABLE` | `false` | Run DCSServerBot (Windows Python under Wine) instead of the watchdog; it starts and supervises DCS. Needs `DISCORD_TOKEN`, `DISCORD_GUILD_ID`, `DISCORD_OWNER_ID`, `DCSSB_DATABASE_URL`; optional `DCSSB_CHANNEL_STATUS/CHAT/ADMIN`, `DCSSB_NODE` |
| `DCS_WATCHDOG_MAX_FAILURES` | `8` | Consecutive missed or error WebGUI responses (15 s apart) before the server is restarted |
| `BENCHMARK_MISSIONS` / `BENCHMARK_ROUNDS` / `BENCHMARK_RUNTIME` | all three ActiumDev missions / `3` / `180` | Benchmark mode: missions (space-separated) run back to back inside the logged-in writedir, then the benchmark files are removed and the container idles |

Wine uses `/dev/ntsync` automatically when the device is present and writable in the
container; the entrypoint logs whether it is available.

## Sidecars (same image)

| Command | Purpose | Notes |
|---|---|---|
| `srs-server` | SimpleRadio Standalone server (native Linux build) | Config in `DCS.server/SRS/server.cfg`; `SRS_PORT` (5002), optional `SRS_EAM_BLUE_PASSWORD` / `SRS_EAM_RED_PASSWORD` |
| `samba-server` | SMB share `\\<host>\dcs` of the `DCS.server` writedir | Runs as root to authenticate, forces file access to uid 1000; needs `SMB_PASSWORD` (user `dcs`) |

## DCSServerBot under Wine

The bot's Windows dependencies install into the Wine prefix on first start: the VC++ 2015-2022
runtime (MFC for `pywin32`'s `win32ui`), Windows Python, and a virtualenv with the bot's
requirements. Two Wine-specific adjustments: `pywinauto` is kept on its win32 backend (Wine's
UIAutomation type library is not usable), and the bot runs under `script(1)` because it needs a
Windows console. Bot config (`main.yaml`, `nodes.yaml`, `servers.yaml`, `services/bot.yaml`,
`plugins/scheduler.yaml`) is regenerated from the environment on every start.

## First start

1. Start the container; it downloads the updater and installs DCS plus the configured terrains.
2. Open noVNC on port 6080 and, when `DCS_server.exe` shows the login window, log in
   with the server's ED account and enable auto-login (creates `Config/network.vault`).

## Credits

Server watchdog, MissionScripting exploit mitigation, Lua hooks (FPSmon, NoErrPopup,
SRSautoConnect), SRS default config, Wine registry tweaks, and benchmark assets are vendored from
[ActiumDev/dcs-server-wine](https://github.com/ActiumDev/dcs-server-wine) under the MIT
license (`rootfs/opt/dcs/LICENSE.ActiumDev`). The Tacview DCS exporter is downloaded at build
time from the same project, which redistributes it with Raia Software's authorization for
dedicated servers (see `/opt/dcs/Tacview/README.md` in the image).

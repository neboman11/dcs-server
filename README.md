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
| `DCS_MODE` | `server` | `server`, `benchmark` (ActiumDev benchmark missions), or `desktop` (display only) |
| `DCS_TERRAINS` | `CAUCASUS_terrain` | Space-separated module IDs; missing ones are installed on start |
| `DCS_AUTO_UPDATE` | `false` | Run `DCS_updater.exe update` on every start |
| `DCS_DESANITIZE` | empty | Lua modules to un-sanitize in `MissionScripting.lua` (e.g. `io lfs` for Liberation/DCC). Only run trusted missions. |
| `DCS_SERVER_NAME` / `DCS_SERVER_PASSWORD` / `DCS_MAX_PLAYERS` | empty | Enforced into `serverSettings.lua` on start when set |
| `BENCHMARK_MISSION` / `BENCHMARK_ROUNDS` / `BENCHMARK_RUNTIME` | `Benchmark_100_v2025.04.27.miz` / `3` / `180` | Benchmark mode parameters |

Wine uses `/dev/ntsync` automatically when the device is present and writable in the
container; the entrypoint logs whether it is available.

## First start

1. Start the container; it downloads the updater and installs DCS plus the configured terrains.
2. Open noVNC on port 6080 and, when `DCS_server.exe` shows the login window, log in
   with the server's ED account and enable auto-login (creates `Config/network.vault`).

## Credits

Server watchdog, MissionScripting exploit mitigation, Lua hooks, Wine registry tweaks,
and benchmark assets are vendored from
[ActiumDev/dcs-server-wine](https://github.com/ActiumDev/dcs-server-wine) under the MIT
license (`rootfs/opt/dcs/LICENSE.ActiumDev`).

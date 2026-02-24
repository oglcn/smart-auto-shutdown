# Smart Auto-Shutdown

A lightweight, systemd-based auto-shutdown system for Linux servers.  
Automatically powers off idle machines to save costs on cloud instances (AWS, GCP, etc.).

## How it works

```
Boot ──── wait BOOT_DELAY ──── check every CHECK_INTERVAL ────┐
                                                               │
                                    ┌──────────────────────────┤
                                    │                          │
                              ┌─────▼─────┐            ┌──────▼──────┐
                              │  SSH = 0   │── no ─────▶│ Reset timer │
                              │  CPU < 20% │            └─────────────┘
                              └─────┬──────┘
                                    │ yes
                              ┌─────▼──────────────┐
                              │ Idle ≥ THRESHOLD ?  │── no ──▶ keep counting
                              └─────┬──────────────┘
                                    │ yes
                              ┌─────▼─────┐
                              │  Shutdown  │
                              └───────────┘
```

**Default behaviour:** After **8 hours** of uptime, the system checks every **10 minutes**.  
If there are **no SSH sessions** and **CPU is below 20%** for **1 continuous hour**, the machine shuts down with a 1-minute warning.  
Any SSH connection or CPU spike resets the countdown.

## Quick install

**One-liner** (curl from GitHub and install directly):

```bash
curl -fsSL https://raw.githubusercontent.com/USER/smart-auto-shutdown/main/install.sh | sudo bash
```

Non-interactive with all defaults:

```bash
curl -fsSL https://raw.githubusercontent.com/USER/smart-auto-shutdown/main/install.sh | sudo bash -s -- --defaults
```

Or clone and run locally:

```bash
git clone https://github.com/USER/smart-auto-shutdown.git
cd smart-auto-shutdown
sudo ./install.sh
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/USER/smart-auto-shutdown/main/install.sh | sudo bash -s -- --uninstall
```

Or locally:

```bash
sudo ./install.sh --uninstall
```

## Configuration

All settings live in `/etc/smart-auto-shutdown.conf`:

| Setting | Default | Description |
|---|---|---|
| `IDLE_THRESHOLD` | `3600` (1 hr) | Seconds of continuous idle before shutdown |
| `CPU_THRESHOLD` | `20` | CPU % below which the system is "idle" |
| `SHUTDOWN_DELAY` | `1` | Minutes of warning before actual halt |

The boot delay and check interval are in the systemd timer (`/etc/systemd/system/autoshutdown.timer`).  
After editing, reload with:

```bash
sudo systemctl daemon-reload
sudo systemctl restart autoshutdown.timer
```

## Usage

```bash
shutdown-control status    # Show current monitoring status
shutdown-control pause     # Temporarily disable auto-shutdown
shutdown-control resume    # Re-enable monitoring
shutdown-control reset     # Reset idle countdown
shutdown-control logs      # View recent log entries
```

## How it detects activity

| Signal | Method |
|---|---|
| SSH sessions | `ss -tn state established sport = :22` — counts active TCP connections on port 22 |
| CPU usage | `top -bn2` — two-sample measurement to get an accurate average |

Both conditions must be "idle" simultaneously for the countdown to progress.  
If **either** becomes active, the countdown resets to zero.

## Files installed

| Path | Purpose |
|---|---|
| `/usr/local/bin/smart-shutdown-check.sh` | Core check script (runs periodically) |
| `/usr/local/bin/shutdown-status` | Status display utility |
| `/usr/local/bin/shutdown-control` | Pause / resume / reset / logs |
| `/etc/systemd/system/autoshutdown.timer` | Systemd timer unit |
| `/etc/systemd/system/autoshutdown.service` | Systemd service unit |
| `/etc/smart-auto-shutdown.conf` | Configuration file |
| `/var/run/smart-shutdown-state` | Runtime state (auto-managed) |

## Development

The distributable `install.sh` is auto-generated. Source files live in `scripts/` and `systemd/`, and `install.sh.in` is the template with `@EMBED` markers.

After editing any source file, rebuild:

```bash
./build.sh    # produces install.sh with all scripts inlined
```

```
smart-auto-shutdown/
├── build.sh              # Assembles install.sh from template + sources
├── install.sh.in         # Installer template (edit this, not install.sh)
├── install.sh            # ← Generated output (commit this)
├── uninstall.sh
├── scripts/
│   ├── smart-shutdown-check.sh
│   ├── shutdown-status
│   └── shutdown-control
└── systemd/
    ├── autoshutdown.timer
    └── autoshutdown.service
```

## Requirements

- Linux with **systemd**
- **bash** ≥ 4
- **iproute2** (`ss`)
- **procps** (`top`)

## License

MIT

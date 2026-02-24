# Smart Auto-Shutdown

Automatically shut down idle Linux servers to save costs on cloud instances (AWS, GCP, Azure, etc.).

A lightweight systemd-based daemon that monitors SSH sessions and CPU usage, and powers off the machine after a sustained period of inactivity.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/oglcn/smart-auto-shutdown/main/install.sh | sudo bash
```

Non-interactive with all defaults:

```bash
curl -fsSL https://raw.githubusercontent.com/oglcn/smart-auto-shutdown/main/install.sh | sudo bash -s -- --defaults
```

<details>
<summary>Or clone and run locally</summary>

```bash
git clone https://github.com/oglcn/smart-auto-shutdown.git
cd smart-auto-shutdown
sudo ./install.sh
```

</details>

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/oglcn/smart-auto-shutdown/main/install.sh | sudo bash -s -- --uninstall
```

## Usage

```bash
shutdown-control status    # Show current monitoring status
shutdown-control pause     # Temporarily disable auto-shutdown
shutdown-control resume    # Re-enable monitoring
shutdown-control reset     # Reset idle countdown
shutdown-control logs      # View recent log entries
```

## Default behaviour

After **8 hours** of uptime, the system begins checking every **10 minutes**. If there are **no SSH sessions** and **CPU stays below 20%** for **1 continuous hour**, the machine shuts down with a 1-minute warning. Any SSH connection or CPU spike immediately resets the countdown to zero. All thresholds are configurable.

## Configuration

All runtime settings live in `/etc/smart-auto-shutdown.conf`:

| Setting | Default | Description |
|---|---|---|
| `IDLE_THRESHOLD` | `3600` (1 hour) | Seconds of continuous idle before shutdown |
| `CPU_THRESHOLD` | `20` | CPU % below which the system is considered idle |
| `SHUTDOWN_DELAY` | `1` | Minutes of warning before actual halt |

The boot delay and check interval are set in the systemd timer at `/etc/systemd/system/autoshutdown.timer`. After editing any config, reload:

```bash
sudo systemctl daemon-reload && sudo systemctl restart autoshutdown.timer
```

### Activity detection

| Signal | Method | Idle when |
|---|---|---|
| SSH | Established TCP connections on port 22 via `ss` | 0 connections |
| CPU | Two-sample average via `top` | Below `CPU_THRESHOLD` |

Both must be idle simultaneously for the countdown to progress. Either one becoming active resets the countdown to zero.

## Requirements

- Linux with **systemd**
- **bash** ≥ 4
- **iproute2** (`ss`)
- **procps** (`top`)

---

<details>
<summary><strong>Development</strong></summary>

### Overview

The distributable `install.sh` is **auto-generated** — do not edit it directly.

Source files live in `scripts/` and `systemd/`. The template `install.sh.in` contains `# @EMBED <path>` markers that get replaced with file contents during the build.

```
smart-auto-shutdown/
├── build.sh              # Assembles install.sh from template + source files
├── install.sh.in         # Installer template (edit this)
├── install.sh            # ← Generated output (commit this)
├── uninstall.sh          # Convenience wrapper
├── scripts/
│   ├── smart-shutdown-check.sh   # Core idle-detection logic
│   ├── shutdown-status           # Status display utility
│   └── shutdown-control          # CLI control (pause/resume/reset/logs)
└── systemd/
    ├── autoshutdown.timer        # Timer unit template
    └── autoshutdown.service      # Service unit
```

### Build

After editing any source file:

```bash
./build.sh
```

This reads `install.sh.in`, inlines every `@EMBED` reference, and writes the self-contained `install.sh`. Commit both the source files and the generated `install.sh`.

### Files installed on target

| Path | Purpose |
|---|---|
| `/usr/local/bin/smart-shutdown-check.sh` | Core check script (runs on timer) |
| `/usr/local/bin/shutdown-status` | Status display |
| `/usr/local/bin/shutdown-control` | CLI control utility |
| `/etc/systemd/system/autoshutdown.timer` | Systemd timer unit |
| `/etc/systemd/system/autoshutdown.service` | Systemd service unit |
| `/etc/smart-auto-shutdown.conf` | Runtime configuration |
| `/var/run/smart-shutdown-state` | Idle state tracking (auto-managed) |

</details>

## License

MIT

---

Made with ❤ by [@oglcn](https://github.com/oglcn)

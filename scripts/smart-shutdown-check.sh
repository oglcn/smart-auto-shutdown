#!/bin/bash
# Smart Auto-Shutdown Check Script
# Checks for SSH sessions and system idle status.
# Only shuts down after sustained idle period with no SSH connections.

set -euo pipefail

CONFIG_FILE="/etc/smart-auto-shutdown.conf"
STATE_FILE="/var/run/smart-shutdown-state"

# Defaults (overridden by config file)
IDLE_THRESHOLD=3600   # seconds of continuous idle before shutdown
CPU_THRESHOLD=20      # percent CPU; below this is "idle"
SHUTDOWN_DELAY=1      # minutes of warning before actual halt

# Load config
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

check_ssh_sessions() {
    local count
    count=$(ss -tn state established sport = :22 | tail -n +2 | wc -l)
    [ "$count" -eq 0 ]
}

check_system_idle() {
    local cpu_usage cpu_int
    cpu_usage=$(top -bn2 -d 0.5 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | cut -d'%' -f1)
    cpu_int=${cpu_usage%.*}
    [ "$cpu_int" -lt "$CPU_THRESHOLD" ]
}

logger -t smart-shutdown "Running smart shutdown check (idle_threshold=${IDLE_THRESHOLD}s, cpu_threshold=${CPU_THRESHOLD}%)"

if check_ssh_sessions && check_system_idle; then
    if [ -f "$STATE_FILE" ]; then
        IDLE_START=$(cat "$STATE_FILE")
        CURRENT_TIME=$(date +%s)
        IDLE_DURATION=$((CURRENT_TIME - IDLE_START))

        logger -t smart-shutdown "System idle for ${IDLE_DURATION}s (need ${IDLE_THRESHOLD}s)"

        if [ "$IDLE_DURATION" -ge "$IDLE_THRESHOLD" ]; then
            logger -t smart-shutdown "Idle threshold reached. Shutting down system."
            rm -f "$STATE_FILE"
            /sbin/shutdown -h +"$SHUTDOWN_DELAY" \
                "System idle for $((IDLE_THRESHOLD / 60)) min with no SSH. Shutting down in ${SHUTDOWN_DELAY} min."
        fi
    else
        date +%s > "$STATE_FILE"
        logger -t smart-shutdown "Started tracking idle state"
    fi
else
    if [ -f "$STATE_FILE" ]; then
        logger -t smart-shutdown "Activity detected or SSH session active. Resetting idle counter."
        rm -f "$STATE_FILE"
    fi
fi

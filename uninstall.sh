#!/bin/bash
# Convenience wrapper — calls the installer in uninstall mode.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/install.sh" --uninstall

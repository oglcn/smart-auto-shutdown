#!/bin/bash
# Assembles install.sh from install.sh.in by replacing @EMBED markers
# with the contents of the referenced source files.
#
# Usage:  ./build.sh
# Output: install.sh (self-contained, ready to distribute)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/install.sh.in"
OUTPUT="${SCRIPT_DIR}/install.sh"

if [ ! -f "$TEMPLATE" ]; then
    echo "Error: ${TEMPLATE} not found" >&2
    exit 1
fi

errors=0

while IFS= read -r line; do
    if [[ "$line" =~ ^#\ @EMBED\ (.+)$ ]]; then
        src="${SCRIPT_DIR}/${BASH_REMATCH[1]}"
        if [ ! -f "$src" ]; then
            echo "Error: embedded file not found: ${src}" >&2
            errors=$((errors + 1))
            continue
        fi
        cat "$src"
    else
        printf '%s\n' "$line"
    fi
done < "$TEMPLATE" > "$OUTPUT"

chmod +x "$OUTPUT"

if [ "$errors" -gt 0 ]; then
    echo "Build completed with ${errors} error(s)." >&2
    exit 1
fi

echo "Built: ${OUTPUT}"

#!/bin/bash
# setup-orbit.sh — thin wrapper around the bundled plugin script.
#
# Usage (from any project directory):
#   bash /path/to/orbit/setup-orbit.sh
#
# For the canonical usage pattern, install orbit-base as a Claude Code plugin
# and run the bundled script via:
#   ${CLAUDE_PLUGIN_ROOT}/scripts/setup-orbit.sh
#
# This wrapper resolves the bundled script relative to its own location.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLED="$SCRIPT_DIR/plugins/orbit-base/scripts/setup-orbit.sh"

if [ ! -f "$BUNDLED" ]; then
    echo "Error: bundled script not found at $BUNDLED" >&2
    exit 1
fi

exec bash "$BUNDLED" "$@"

#!/bin/bash
# orbit-context.sh — shared guard for orbit's distributed hooks.
#
# Sourced by every bash hook. Exports is_orbit_context(): exit 0 iff the
# current project has been orbit-initialized, else exit 1.
#
# "Orbit-initialized" = the durable marker file ${CLAUDE_PROJECT_DIR}/.orbit/config
# exists. This file is written by /orbit-init (Step 4) BEFORE any hook runs and is
# NEVER created by a hook — so it cannot be self-satisfied (chicken-egg safe).
# Bare .orbit/ directory does NOT count: a hook could create it; config it cannot.
#
# No stdout, no side effects. Safe to source repeatedly.

is_orbit_context() {
    local _dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    [ -f "$_dir/.orbit/config" ]
}

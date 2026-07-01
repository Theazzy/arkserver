#!/usr/bin/env bash
#
# Liveness probe for the ARK server. Exit 0 = healthy, non-zero = unhealthy.
# Prepared here; wired into the container via a Compose HEALTHCHECK in Phase 6.
#
# Lightweight on purpose (runs on an interval): it checks the server *process* is
# alive. Phase 6 may upgrade this to an RCON readiness probe (e.g. `arkmanager rconcmd
# listplayers`) once port/RCON wiring is finalized.

set -uo pipefail

if pgrep -f 'ShooterGameServer' >/dev/null 2>&1; then
  exit 0
fi

echo "healthcheck: ShooterGameServer process not found" >&2
exit 1

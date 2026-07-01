#!/usr/bin/env bash

set -e

[[ -z "${DEBUG}" ]] || [[ "${DEBUG,,}" = "false" ]] || [[ "${DEBUG,,}" = "0" ]] || set -x

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
UMASK="${UMASK:-0002}"

# Align the steam user/group with the requested PUID/PGID so files written to the
# bind-mounted volume are owned correctly on the host (#69). Runs as root.
CURRENT_UID="$(id -u "${STEAM_USER}")"
CURRENT_GID="$(id -g "${STEAM_USER}")"
if [[ "${CURRENT_GID}" != "${PGID}" ]]; then
  echo "Setting ${STEAM_USER} group id ${CURRENT_GID} -> ${PGID}"
  groupmod -o -g "${PGID}" "${STEAM_USER}"
fi
if [[ "${CURRENT_UID}" != "${PUID}" ]]; then
  echo "Setting ${STEAM_USER} user id ${CURRENT_UID} -> ${PUID}"
  usermod -o -u "${PUID}" "${STEAM_USER}"
fi

if [[ ! -d "${ARK_SERVER_VOLUME}" ]]; then
  mkdir -p "${ARK_SERVER_VOLUME}"
fi

chown "${STEAM_USER}": "${ARK_SERVER_VOLUME}" || echo "Failed setting rights on ${ARK_SERVER_VOLUME}, continuing startup..."

# Cluster is opt-in: only provision /cluster when CLUSTER_ID is set, so a plain
# vanilla server never gets a stray shared-transfer directory (Phase 5, gated).
if [[ -n "${CLUSTER_ID}" ]]; then
  mkdir -p "/cluster"
  chown "${STEAM_USER}": "/cluster" || echo "Failed setting rights on /cluster, continuing startup..."
fi

# Fix ownership of the whole volume only when it doesn't already match the target
# uid (first boot or after a PUID change) — avoids a costly recursive chown on every start.
if [[ "$(stat -c %u "${ARK_SERVER_VOLUME}")" != "${PUID}" ]]; then
  echo "Fixing ownership of ${ARK_SERVER_VOLUME} for ${PUID}:${PGID} (first run or PUID change)..."
  chown -R "${PUID}:${PGID}" "${ARK_SERVER_VOLUME}" || echo "Partial chown on ${ARK_SERVER_VOLUME}, continuing startup..."
fi

# Persist arkmanager state on the volume; expose it at /etc/arkmanager (idempotent, #95).
if [[ ! -d "${ARK_TOOLS_DIR}" ]]; then
  if [[ -e "/etc/arkmanager" && ! -L "/etc/arkmanager" ]]; then
    # First run: move the image's default config onto the volume.
    mv "/etc/arkmanager" "${ARK_TOOLS_DIR}"
  else
    mkdir -p "${ARK_TOOLS_DIR}"
  fi
  rm -f "${ARK_TOOLS_DIR}/arkmanager.cfg" "${ARK_TOOLS_DIR}/instances/main.cfg"
fi

chown -R "${STEAM_USER}": "${ARK_TOOLS_DIR}" || echo "Failed setting rights on ${ARK_TOOLS_DIR}, continuing startup..."

# Replace whatever currently sits at /etc/arkmanager with a symlink to the persisted dir.
# Handle the symlink and real-directory cases separately so a stale dir can't trip up
# `ln` with "File exists" / "Directory not empty" (#95).
if [[ -L "/etc/arkmanager" ]]; then
  rm -f "/etc/arkmanager"
elif [[ -e "/etc/arkmanager" ]]; then
  rm -rf "/etc/arkmanager"
fi
ln -sfn "${ARK_TOOLS_DIR}" "/etc/arkmanager"

service cron start

# Inherit umask into the server process; gosu preserves it across exec.
umask "${UMASK}"

exec gosu "${STEAM_USER}" /steam-entrypoint.sh "$@"

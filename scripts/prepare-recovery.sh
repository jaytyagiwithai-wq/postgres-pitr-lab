#!/bin/sh

set -eu
umask 077

: "${PGDATA:?PGDATA is required}"
: "${WALG_BACKUP_NAME:?WALG_BACKUP_NAME is required}"
: "${RECOVERY_TARGET_TIME:?RECOVERY_TARGET_TIME is required}"

if ! printf '%s\n' "$WALG_BACKUP_NAME" \
    | grep -Eq '^base_[A-F0-9]+$'; then
    echo "ERROR: Invalid WAL-G backup name: $WALG_BACKUP_NAME" >&2
    exit 1
fi

if ! printf '%s\n' "$RECOVERY_TARGET_TIME" \
    | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,6})?Z$'; then
    echo "ERROR: RECOVERY_TARGET_TIME must be an RFC 3339 UTC timestamp." >&2
    exit 1
fi

# PostgreSQL's recovery configuration expects its conventional timestamptz
# representation rather than the RFC 3339 T/Z representation accepted at
# this script's boundary.
POSTGRES_RECOVERY_TARGET_TIME=$(printf '%s\n' "$RECOVERY_TARGET_TIME" \
    | sed 's/T/ /; s/Z$/+00/')

mkdir -p "$PGDATA"

if [ -n "$(find "$PGDATA" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    echo "ERROR: Recovery data directory is not empty: $PGDATA" >&2
    exit 1
fi

echo "Fetching base backup: $WALG_BACKUP_NAME"
wal-g backup-fetch "$PGDATA" "$WALG_BACKUP_NAME"

if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "ERROR: Restored backup has no PG_VERSION file." >&2
    exit 1
fi

if [ "$(cat "$PGDATA/PG_VERSION")" != "16" ]; then
    echo "ERROR: Restored backup is not PostgreSQL major version 16." >&2
    exit 1
fi

cat >> "$PGDATA/postgresql.auto.conf" <<EOF

# Added by scripts/prepare-recovery.sh for this PITR drill.
restore_command = 'wal-g wal-fetch %f %p'
recovery_target_time = '$POSTGRES_RECOVERY_TARGET_TIME'
recovery_target_inclusive = true
recovery_target_action = 'promote'
EOF

touch "$PGDATA/recovery.signal"
chmod 0600 "$PGDATA/postgresql.auto.conf" "$PGDATA/recovery.signal"
chown -R postgres:postgres "$PGDATA"

echo "Recovery volume prepared successfully."

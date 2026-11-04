#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
archive="${1:?Usage: restore.sh /absolute/path.dump week3_restore_unique_name}"
destination="${2:?Provide a NEW verification database name}"
safe_db "$destination"
[[ "$archive" == /* && -f "$archive" && -f "$archive.sha256" ]] || { echo 'Need absolute archive path and checksum sidecar' >&2; exit 1; }
sha256sum -c "$archive.sha256"
db_container
# createdb fails if destination exists: never overwrite a database.
docker exec "$DB_CONTAINER" createdb -U postgres --template=template0 "$destination"
docker exec -i "$DB_CONTAINER" pg_restore -U postgres -d "$destination" --no-owner --no-acl --exit-on-error --single-transaction <"$archive"
mkdir -p "$BACKUP_DIR"
log "RESTORE OK database=$destination archive=$archive" | tee -a "$BACKUP_DIR/operations.log"

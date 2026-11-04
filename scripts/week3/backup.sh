#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
db_container
database="${1:-todo}"
[[ "$database" == todo ]] || safe_db "$database"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
archive="$BACKUP_DIR/${database}_$(date -u +%Y%m%dT%H%M%SZ)_$$.dump"
trap 'rm -f "${archive}.partial"' EXIT
docker exec "$DB_CONTAINER" pg_dump -U postgres -d "$database" -Fc --no-owner --no-acl >"$archive.partial"
test -s "$archive.partial"
docker exec -i "$DB_CONTAINER" pg_restore --list <"$archive.partial" >/dev/null
mv "$archive.partial" "$archive"
(cd "$BACKUP_DIR" && sha256sum -- "$(basename "$archive")") >"$archive.sha256"
log "BACKUP OK database=$database archive=$archive" | tee -a "$BACKUP_DIR/operations.log" >&2
# Keep at least the newest archive. Old complete archives expire after 14 days.
find "$BACKUP_DIR" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.dump.sha256' \) -mtime +14 ! -name "$(basename "$archive")" ! -name "$(basename "$archive").sha256" -delete
printf '%s\n' "$archive"

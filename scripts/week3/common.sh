#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/todo-backups}"
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*"; }
db_container() {
  DB_CONTAINER="$(docker ps -q --filter "label=com.docker.compose.project=${TODO_PROJECT:-todo-task-manager}" --filter label=com.docker.compose.service=db)"
  [[ -n "$DB_CONTAINER" && "$DB_CONTAINER" != *$'\n'* ]] || { echo 'Expected exactly one running production DB container' >&2; exit 1; }
}
sql() { docker exec -i "$DB_CONTAINER" psql -X -v ON_ERROR_STOP=1 -U postgres -d "$1" "${@:2}"; }
safe_db() { [[ "$1" =~ ^week3_restore_[a-z0-9_]+$ ]] || { echo 'Destination must start week3_restore_ and contain only lowercase letters/digits/underscores' >&2; exit 1; }; }

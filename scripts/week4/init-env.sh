#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="${APP_ENV_FILE:-$HOME/.config/todo/production.env}"
[[ "$ENV_FILE" == /* && "$ENV_FILE" != "$ROOT"/* ]] || { echo 'Use an absolute environment file OUTSIDE the repository'; exit 1; }
if [[ ! -f "$ENV_FILE" ]]; then
  if docker volume inspect "${TODO_PROJECT:-todo-task-manager}_postgres_data" >/dev/null 2>&1; then
    echo 'Existing DB volume found, but no environment file. Restore original secrets; do not generate replacement credentials.' >&2; exit 1
  fi
  mkdir -p "$(dirname "$ENV_FILE")"
  chmod 700 "$(dirname "$ENV_FILE")"
  printf 'DB_ADMIN_PASSWORD=%s\nDB_APP_PASSWORD=%s\n' "$(openssl rand -hex 24)" "$(openssl rand -hex 24)" > "$ENV_FILE"
fi
chmod 600 "$ENV_FILE"
echo 'Environment file is ready; its contents were not printed.'

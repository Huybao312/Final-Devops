#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 || -z "${SUDO_USER:-}" || "$SUDO_USER" == root ]]; then
  echo "Run from a normal Ubuntu account: sudo bash scripts/cutover-week2-vm.sh" >&2
  exit 1
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"
if [[ ! -f .env ]] || [[ "$(stat -c %a .env)" != 600 ]]; then
  echo "Missing .env or mode is not 0600" >&2
  exit 1
fi
if ! docker compose version >/dev/null; then
  echo "Docker Compose is not available" >&2
  exit 1
fi
if docker volume inspect todo-task-manager_postgres_data >/dev/null 2>&1; then
  echo "The target volume already exists. Inspect it before attempting another import." >&2
  exit 1
fi
if ! systemctl is-active --quiet flaskapp || ! systemctl is-active --quiet postgresql; then
  echo "The Week 1 app and database must be running before cutover." >&2
  exit 1
fi

APP_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
FINAL_DUMP="$APP_HOME/todo-week1-final-$(date +%Y%m%d-%H%M%S).sql"
OLD_STOPPED=0
CUTOVER_DONE=0
rollback() {
  if [[ "$OLD_STOPPED" == 1 && "$CUTOVER_DONE" != 1 ]]; then
    echo "Cutover failed. Stopping the container app and restoring the Week 1 service." >&2
    docker compose stop app >/dev/null 2>&1 || true
    systemctl start flaskapp || true
  fi
}
trap rollback EXIT

echo "==> Stopping Week 1 app to freeze writes"
systemctl stop flaskapp
OLD_STOPPED=1

echo "==> Taking final data-only dump outside the repository"
install -m 0600 -o "$SUDO_USER" -g "$SUDO_USER" /dev/null "$FINAL_DUMP"
runuser -u postgres -- pg_dump --data-only --no-owner --no-privileges -d todo > "$FINAL_DUMP"
echo "Final dump: $FINAL_DUMP"
echo "SHA256: $(sha256sum "$FINAL_DUMP" | cut -d' ' -f1)"

QUERY="SELECT count(*), md5(coalesce(json_agg(t ORDER BY t.id)::text, '[]')) FROM (SELECT id, title, description, completed, created_at AT TIME ZONE 'UTC' AS created_at_utc FROM public.tasks) AS t;"
OLD_SIGNATURE="$(runuser -u postgres -- psql -d todo -tA -c "$QUERY")"
echo "Week 1 count and checksum: $OLD_SIGNATURE"

echo "==> Initializing PostgreSQL 18 container and importing data"
docker compose up -d --wait db
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d todo < "$FINAL_DUMP"
NEW_SIGNATURE="$(docker compose exec -T db psql -U postgres -d todo -tA -c "$QUERY" | tr -d '\r')"
echo "Container count and checksum: $NEW_SIGNATURE"
if [[ "$OLD_SIGNATURE" != "$NEW_SIGNATURE" ]]; then
  echo "Data comparison failed; Week 1 service will be restored." >&2
  exit 1
fi

echo "==> Starting container app behind existing Nginx"
docker compose up -d --build --wait app
curl -fsS --retry 10 --retry-connrefused --retry-delay 1 http://127.0.0.1/health
echo
systemctl disable flaskapp
CUTOVER_DONE=1
echo "PASS: data matched and container app is serving through Nginx."
echo "The Week 1 PostgreSQL service and its data remain available for rollback."

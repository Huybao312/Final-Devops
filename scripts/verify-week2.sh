#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."
command -v docker >/dev/null
command -v curl >/dev/null

TITLE="week2-persistence-$(date +%s)-$RANDOM"
BASE_URL="http://127.0.0.1:${APP_BIND_PORT:-5000}"
echo "Creating $TITLE through the application"
curl -fsS -o /dev/null -X POST "$BASE_URL/tasks" \
  --data-urlencode "title=$TITLE" --data-urlencode "description=Persistence verification"
docker compose exec -T db psql -U postgres -d todo -v title="$TITLE" -tA <<'SQL' | grep -qx 1
SELECT count(*) FROM public.tasks WHERE title = :'title';
SQL

echo "Recreating both containers without removing the named volume"
docker compose down
docker compose up -d --wait

curl -fsS "$BASE_URL/health"
echo
docker compose exec -T db psql -U postgres -d todo -v title="$TITLE" -tA <<'SQL' | grep -qx 1
SELECT count(*) FROM public.tasks WHERE title = :'title';
SQL
curl -fsS "$BASE_URL/" | grep -Fq "$TITLE"
echo "PASS: task survived container recreation and is visible in database and UI"

#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$APP_DIR/docs/evidence/verify-app.txt}"
BASE_URL="${BASE_URL:-http://127.0.0.1}"
ENV_FILE="${ENV_FILE:-/etc/todo-task-manager.env}"
TITLE="DevOps Week 1 verification $(date +%Y%m%d-%H%M%S)"

mkdir -p "$(dirname "$OUT")"

if [[ ! -r "$ENV_FILE" ]]; then
  echo "ERROR: cannot read $ENV_FILE. Run with sudo: sudo bash scripts/verify-app.sh" >&2
  exit 1
fi

{
  echo "# Application verification"
  echo "Generated: $(date -Is)"
  echo "Base URL: $BASE_URL"
  echo

  echo "## 1. Health endpoint"
  curl -fsS "$BASE_URL/health"
  echo

  echo "## 2. Create a task through Nginx"
  curl -fsS -o /dev/null -w "POST /tasks -> HTTP %{http_code}\n" \
    -X POST "$BASE_URL/tasks" \
    --data-urlencode "title=$TITLE" \
    --data-urlencode "description=Created by scripts/verify-app.sh"
  echo

  echo "## 3. Read the task back from the web UI"
  if curl -fsS "$BASE_URL/" | grep -Fq "$TITLE"; then
    echo "OK: '$TITLE' is visible in GET /"
  else
    echo "FAIL: task not found in GET /" >&2
    exit 1
  fi
  echo

  echo "## 4. Read the same row directly from PostgreSQL"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  psql "$DATABASE_URL" -v title="$TITLE" <<'SQL'
SELECT id, title, description, completed, created_at
FROM tasks
WHERE title = :'title';
SQL
  echo

  echo "## 5. Toggle the task and verify the boolean changed"
  TASK_ID="$(psql "$DATABASE_URL" -tA -v title="$TITLE" <<'SQL'
SELECT id FROM tasks WHERE title = :'title' ORDER BY id DESC LIMIT 1;
SQL
)"
  curl -fsS -o /dev/null -w "POST /tasks/$TASK_ID/toggle -> HTTP %{http_code}\n" \
    -X POST "$BASE_URL/tasks/$TASK_ID/toggle"
  psql "$DATABASE_URL" -c "SELECT id, title, completed FROM tasks WHERE id = $TASK_ID;"
  echo

  echo "## 6. Verify least-privilege grants for the application role"
  psql "$DATABASE_URL" -c "
SELECT current_user AS role,
       has_table_privilege(current_user, 'public.tasks', 'SELECT') AS can_select,
       has_table_privilege(current_user, 'public.tasks', 'INSERT') AS can_insert,
       has_table_privilege(current_user, 'public.tasks', 'UPDATE') AS can_update,
       has_table_privilege(current_user, 'public.tasks', 'DELETE') AS can_delete,
       has_schema_privilege(current_user, 'public', 'CREATE') AS can_create_objects;"
  echo

  echo "Verification completed successfully."
} | tee "$OUT"

if [[ -n "${SUDO_USER:-}" ]]; then
  chown "$SUDO_USER": "$OUT"
fi

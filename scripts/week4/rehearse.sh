#!/usr/bin/env bash
# Fresh isolated Compose deployment + actual troubleshooting; no production access.
set -Eeuo pipefail
umask 077
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
read -r free_app free_proxy < <(python3 - <<'PY'
import socket
a,b=socket.socket(),socket.socket()
a.bind(('127.0.0.1',0)); b.bind(('127.0.0.1',0))
print(a.getsockname()[1],b.getsockname()[1])
PY
)
export TODO_PROJECT="todo-week4-rehearsal-$(date -u +%Y%m%d%H%M%S)-$$"
[[ "$TODO_PROJECT" == todo-week4-rehearsal-* ]] || exit 1
config_dir="$HOME/.config/todo/rehearsals/$TODO_PROJECT"
mkdir -p "$config_dir"
export APP_ENV_FILE="$config_dir/compose.env"
export REHEARSAL_PROXY_CONFIG="$config_dir/proxy.conf"
export APP_BIND_PORT="${APP_BIND_PORT:-$free_app}"
export REHEARSAL_PROXY_PORT="${REHEARSAL_PROXY_PORT:-$free_proxy}"
export APP_VERSION="$(git -C "$ROOT" rev-parse HEAD)"
export BACKUP_DIR="$config_dir/backups"
cp "$ROOT/deploy/rehearsal-nginx.conf" "$REHEARSAL_PROXY_CONFIG"
for name in TODO_PROJECT APP_ENV_FILE REHEARSAL_PROXY_CONFIG APP_BIND_PORT REHEARSAL_PROXY_PORT APP_VERSION; do
  printf 'export %s=%q\n' "$name" "${!name}"
done > "$config_dir/runtime.env"
report="${EVIDENCE_FILE:-$config_dir/rehearsal.txt}"
mkdir -p "$(dirname "$report")"
exec > >(tee "$report") 2>&1
echo "START $(date -u +%FT%TZ) project=$TODO_PROJECT fresh volumes, separate credentials"
echo "Rehearsal only: app=127.0.0.1:$APP_BIND_PORT proxy=127.0.0.1:$REHEARSAL_PROXY_PORT"
bash "$ROOT/scripts/week4/init-env.sh"
dc=(docker compose --project-directory "$ROOT" --env-file "$APP_ENV_FILE" -p "$TODO_PROJECT" -f "$ROOT/compose.yaml" -f "$ROOT/deploy/rehearsal.compose.yaml")
"${dc[@]}" build app
"${dc[@]}" up -d --wait
db="$("${dc[@]}" ps -q db)"
base="http://127.0.0.1:$REHEARSAL_PROXY_PORT"
wait_status() {
  local expected="$1" code
  for attempt in {1..30}; do
    code="$(curl -s --max-time 8 -o /dev/null -w '%{http_code}' "$base/health" || true)"
    [[ "$code" == "$expected" ]] && { echo "PASS /health status=$code"; return; }
    sleep 1
  done
  echo "FAIL expected HTTP $expected, got $code"; return 1
}
cleanup_fault() {
  cp "$ROOT/deploy/rehearsal-nginx.conf" "$REHEARSAL_PROXY_CONFIG"
  "${dc[@]}" start db app proxy >/dev/null 2>&1 || true
  "${dc[@]}" exec -T proxy nginx -s reload >/dev/null 2>&1 || true
}
trap cleanup_fault EXIT
wait_status 200
curl -fsS "$base/version"
curl -fsS -o /dev/null -X POST "$base/tasks" --data-urlencode 'title=week4-persistence-marker'
echo 'INCIDENT 1: stopped app -> proxy 502; root cause app process unavailable'
"${dc[@]}" stop app
wait_status 502
"${dc[@]}" logs --no-color --timestamps --tail 10 proxy
"${dc[@]}" start app
wait_status 200
echo 'RECOVERED 1: restarted existing app container'
echo 'INCIDENT 2: stopped DB -> health 503; root cause database connection unavailable'
"${dc[@]}" stop db
wait_status 503
"${dc[@]}" logs --no-color --timestamps --tail 10 app
"${dc[@]}" start db
wait_status 200
echo 'RECOVERED 2: restarted existing DB with same volume'
echo 'INCIDENT 3: valid proxy syntax, wrong upstream port -> 502'
python3 - "$REHEARSAL_PROXY_CONFIG" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); p.write_text(p.read_text().replace('app:5000','app:5999'))
PY
"${dc[@]}" exec -T proxy nginx -t
"${dc[@]}" exec -T proxy nginx -s reload
wait_status 502
"${dc[@]}" logs --no-color --timestamps --tail 10 proxy
cp "$ROOT/deploy/rehearsal-nginx.conf" "$REHEARSAL_PROXY_CONFIG"
"${dc[@]}" exec -T proxy nginx -t
"${dc[@]}" exec -T proxy nginx -s reload
wait_status 200
echo 'RECOVERED 3: corrected upstream port; syntax check alone had not detected runtime fault'
echo 'VERIFY DB least privilege'
if docker exec "$db" psql -X -v ON_ERROR_STOP=1 -U postgres -d todo -c 'SET ROLE todo_app; CREATE TABLE public.forbidden(id int);'; then
  echo 'FAIL application role can create tables'; exit 1
fi
echo 'VERIFY persistence after container recreation'
"${dc[@]}" down
"${dc[@]}" up -d --wait --no-build
wait_status 200
curl -fsS "$base/" | grep -q 'week4-persistence-marker'
echo 'PASS original task survived container recreation'
bash "$ROOT/scripts/week3/verify-restore.sh"
wait_status 200
echo "PASS ALL $(date -u +%FT%TZ) independent deployment, 3 incidents, persistence, privileges, restore"
echo "Retained project=$TODO_PROJECT config=$config_dir for defense. Use: bash scripts/week4/control-rehearsal.sh $config_dir status|logs|cleanup"
trap - EXIT

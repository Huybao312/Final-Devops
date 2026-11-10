#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export APP_ENV_FILE="${APP_ENV_FILE:-$HOME/.config/todo/production.env}"
bash "$ROOT/scripts/week4/init-env.sh"
export APP_VERSION="${APP_VERSION:-$(git -C "$ROOT" rev-parse HEAD)}"
dc=(docker compose --project-directory "$ROOT" --env-file "$APP_ENV_FILE" -p "${TODO_PROJECT:-todo-task-manager}" -f "$ROOT/compose.yaml")
"${dc[@]}" config -q
"${dc[@]}" build app
"${dc[@]}" up -d --wait
curl -fsS "http://127.0.0.1:${APP_BIND_PORT:-5000}/health"
actual="$(curl -fsS "http://127.0.0.1:${APP_BIND_PORT:-5000}/version" | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')"
[[ "$actual" == "$APP_VERSION" ]]
echo "PASS deployment health and version=$actual"

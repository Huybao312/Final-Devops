#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
config="${1:?Provide the config directory printed by rehearse.sh}"
[[ "$config" == "$HOME/.config/todo/rehearsals/todo-week4-rehearsal-"* && -f "$config/runtime.env" ]] || { echo 'Not a rehearsal config directory'; exit 1; }
source "$config/runtime.env"
[[ "$TODO_PROJECT" == todo-week4-rehearsal-* ]] || exit 1
dc=(docker compose --project-directory "$ROOT" --env-file "$APP_ENV_FILE" -p "$TODO_PROJECT" -f "$ROOT/compose.yaml" -f "$ROOT/deploy/rehearsal.compose.yaml")
case "${2:-status}" in
  status) "${dc[@]}" ps ;;
  logs) "${dc[@]}" logs --no-color --timestamps --since 10m --tail 80 app db proxy ;;
  stop-app) "${dc[@]}" stop app ;;
  start-app) "${dc[@]}" start app ;;
  stop-db) "${dc[@]}" stop db ;;
  start-db) "${dc[@]}" start db ;;
  break-proxy|fix-proxy)
    cp "$ROOT/deploy/rehearsal-nginx.conf" "$REHEARSAL_PROXY_CONFIG"
    if [[ "$2" == break-proxy ]]; then
      python3 - "$REHEARSAL_PROXY_CONFIG" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); p.write_text(p.read_text().replace('app:5000','app:5999'))
PY
    fi
    "${dc[@]}" exec -T proxy nginx -t
    "${dc[@]}" exec -T proxy nginx -s reload ;;
  cleanup) "${dc[@]}" down ;;
  *) echo 'Use status|logs|stop-app|start-app|stop-db|start-db|break-proxy|fix-proxy|cleanup'; exit 1 ;;
esac

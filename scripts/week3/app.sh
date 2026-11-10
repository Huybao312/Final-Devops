#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
APP_ENV_FILE="${APP_ENV_FILE:-$HOME/.config/todo/production.env}"
if [[ ! -f "$APP_ENV_FILE" && -f "$HOME/Final-Devops-week2/.env" ]]; then
  APP_ENV_FILE="$HOME/Final-Devops-week2/.env"
fi
[[ -f "$APP_ENV_FILE" ]] || { echo 'Set APP_ENV_FILE to your production Compose env file' >&2; exit 1; }
case "${1:-status}" in
  stop|start|status|logs) ;;
  *) echo 'Usage: app.sh stop|start|status|logs'; exit 1 ;;
esac
dc=(docker compose --project-directory "$ROOT" --env-file "$APP_ENV_FILE" -f "$ROOT/compose.yaml")
case "${1:-status}" in
  stop) "${dc[@]}" stop app ;;
  start) "${dc[@]}" start app ;;
  status) "${dc[@]}" ps ;;
  logs) "${dc[@]}" logs --no-color --timestamps --since "${SINCE:-15m}" --tail 150 app db ;;
esac

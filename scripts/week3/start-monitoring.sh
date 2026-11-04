#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
config_dir="$HOME/.config/todo-week3"
mkdir -p "$config_dir"
chmod 700 "$config_dir"
if [[ ! -f "$config_dir/monitoring.env" ]]; then
  printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(openssl rand -hex 24)" >"$config_dir/monitoring.env"
fi
chmod 600 "$config_dir/monitoring.env"
docker compose --env-file "$config_dir/monitoring.env" -f "$ROOT/monitoring/compose.yaml" up -d
log 'Monitoring started. Grafana credential is in ~/.config/todo-week3/monitoring.env; read privately, never screen-share it.'

#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
log 'Listening TCP ports (no secrets)'
ss -lnt
log 'Docker published ports: DB must not publish host 5432; app must bind loopback'
docker ps --format '{{.Names}} {{.Ports}}'
log 'Firewall status (sudo required)'
sudo ufw status verbose
log 'Application role must not be superuser/create database/create role'
db_container
sql todo -c "SELECT rolname,rolsuper,rolcreatedb,rolcreaterole FROM pg_roles WHERE rolname IN ('todo_app','todo_owner');"
sql todo -c "SELECT grantee,privilege_type FROM information_schema.role_table_grants WHERE table_name='tasks' AND grantee='todo_app';"
log 'Secret file permissions only; do not display their content'
env_file="${APP_ENV_FILE:-$HOME/.config/todo/production.env}"
[[ -f "$env_file" ]] || env_file="$HOME/Final-Devops-week2/.env"
stat -c '%a %U %n' "$env_file" "$HOME/.config/todo-week3/monitoring.env"

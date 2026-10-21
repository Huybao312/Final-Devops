#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$APP_DIR/docs/evidence/server-info.txt}"
mkdir -p "$(dirname "$OUT")"

{
  echo "# Server information"
  echo "Generated: $(date -Is)"
  echo
  echo "## OS"
  cat /etc/os-release
  echo
  echo "## Kernel"
  uname -a
  echo
  echo "## CPU"
  lscpu
  echo
  echo "## Memory"
  free -h
  echo
  echo "## Disk"
  df -hT
  echo
  echo "## Network interfaces"
  ip -brief address
  echo
  echo "## Default route"
  ip route show default
  echo
  echo "## Current user"
  id
  echo
  echo "## SSH daemon configuration"
  sshd -T 2>/dev/null | grep -E '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers|allowgroups)' || true
  echo
  echo "## Listening TCP ports"
  ss -lntp
  echo
  echo "## UFW status"
  ufw status verbose || true
  echo
  echo "## Secret file permissions"
  stat -c '%A %U:%G %n' /etc/todo-task-manager.env 2>/dev/null || true
  echo
  echo "## Service status"
  systemctl --no-pager --full status flaskapp nginx postgresql ssh || true
  echo
  echo "## Versions"
  nginx -v 2>&1 || true
  psql --version || true
  "$APP_DIR/venv/bin/python" --version || true
  echo
  echo "## Health endpoint"
  curl -fsS http://127.0.0.1/health || true
  echo
} | tee "$OUT"

if [[ -n "${SUDO_USER:-}" ]]; then
  chown "$SUDO_USER": "$OUT"
fi

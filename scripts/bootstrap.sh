#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="flaskapp"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run with sudo: sudo bash scripts/bootstrap.sh" >&2
  exit 1
fi

if [[ -z "${SUDO_USER:-}" || "${SUDO_USER}" == "root" ]]; then
  echo "ERROR: run from a normal user account with sudo, not from a root shell." >&2
  exit 1
fi

if [[ "$APP_DIR" != "/opt/todo-task-manager" ]]; then
  echo "ERROR: repository must be at /opt/todo-task-manager (found $APP_DIR)." >&2
  echo "Move or clone it there, then re-run this script." >&2
  exit 1
fi

DEPLOY_USER="$SUDO_USER"

echo "==> Installing packages"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3-venv python3-pip postgresql nginx curl git ufw openssl

echo "==> Setting ownership and permissions"
chown -R "$DEPLOY_USER":www-data "$APP_DIR"
find "$APP_DIR" -path "$APP_DIR/.git" -prune -o -path "$APP_DIR/venv" -prune -o -type d -exec chmod 750 {} +
find "$APP_DIR" -path "$APP_DIR/.git" -prune -o -path "$APP_DIR/venv" -prune -o -type f -exec chmod 640 {} +
chmod 750 "$APP_DIR"/scripts/*.sh

echo "==> Creating virtual environment"
if [[ ! -x "$APP_DIR/venv/bin/python" ]]; then
  sudo -H -u "$DEPLOY_USER" python3 -m venv "$APP_DIR/venv"
fi
sudo -H -u "$DEPLOY_USER" "$APP_DIR/venv/bin/pip" install --disable-pip-version-check -r "$APP_DIR/requirements.txt"
chmod -R g+rX "$APP_DIR/venv"

echo "==> Configuring PostgreSQL"
systemctl enable --now postgresql
bash "$APP_DIR/scripts/setup-db.sh"

echo "==> Installing systemd unit"
install -m 0644 "$APP_DIR/systemd/flaskapp.service" "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo "==> Installing Nginx site"
install -m 0644 "$APP_DIR/nginx/flaskapp" /etc/nginx/sites-available/flaskapp
ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/flaskapp
rm -f /etc/nginx/sites-enabled/default
systemctl enable --now nginx
nginx -t
systemctl reload nginx

echo "==> Configuring firewall"
bash "$APP_DIR/scripts/setup-firewall.sh"

echo "==> Starting application"
systemctl restart "$SERVICE_NAME"

echo "==> Checking health endpoint"
if ! curl -fsS --retry 15 --retry-connrefused --retry-delay 1 http://127.0.0.1/health; then
  echo >&2
  echo "ERROR: health check failed. Recent application logs:" >&2
  journalctl -u "$SERVICE_NAME" -n 50 --no-pager >&2
  exit 1
fi

echo
echo "Deployment complete."
VM_IP="$(ip -4 -brief address show scope global | awk '{print $3}' | cut -d/ -f1 | head -n1)"
echo "Open:   http://${VM_IP}/"
echo "Health: http://${VM_IP}/health"

#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="${SERVICE_NAME:-flaskapp}"
ENV_FILE="${ENV_FILE:-/etc/todo-task-manager.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE is missing. Run scripts/setup-db.sh first." >&2
  exit 1
fi

cd "$APP_DIR"

if git remote get-url origin >/dev/null 2>&1; then
  echo "==> Updating code from origin"
  git pull --ff-only origin "$(git branch --show-current)"
else
  echo "==> No origin remote; deploying current working tree"
fi

echo "==> Installing Python dependencies"
"$APP_DIR/venv/bin/pip" install --disable-pip-version-check -r requirements.txt
chmod -R g+rX "$APP_DIR/venv"

echo "==> Restarting $SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

echo "==> Checking health endpoint"
curl --fail --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 \
  http://127.0.0.1/health
echo
echo "Deployment successful."

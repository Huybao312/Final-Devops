#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="${SERVICE_NAME:-flaskapp}"

cd "$APP_DIR"

if git remote get-url origin >/dev/null 2>&1; then
  echo "Updating code from origin..."
  git pull --ff-only origin "$(git branch --show-current)"
else
  echo "No origin remote configured; deploying the current working tree."
fi

echo "Installing Python dependencies..."
./venv/bin/pip install --disable-pip-version-check -r requirements.txt

echo "Restarting ${SERVICE_NAME}.service..."
sudo systemctl restart "$SERVICE_NAME"

echo "Checking health endpoint..."
curl --fail --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 http://localhost/health >/dev/null
echo "Deployment successful!"

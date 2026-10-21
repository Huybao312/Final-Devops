#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run with sudo: sudo bash scripts/setup-firewall.sh" >&2
  exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
  echo "ERROR: ufw is not installed. Run: sudo apt install -y ufw" >&2
  exit 1
fi

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH || ufw allow 22/tcp
ufw allow 80/tcp comment 'HTTP via Nginx'
ufw --force enable
ufw status verbose

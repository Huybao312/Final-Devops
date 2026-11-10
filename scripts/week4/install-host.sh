#!/usr/bin/env bash
# Dedicated Ubuntu host only. Does not migrate the legacy Week 1 database.
set -Eeuo pipefail
[[ $EUID == 0 && -n ${SUDO_USER:-} && $SUDO_USER != root ]] || { echo 'Run via sudo from a normal user'; exit 1; }
. /etc/os-release
[[ $ID == ubuntu && ( $VERSION_ID == 24.04 || $VERSION_ID == 26.04 ) ]] || { echo 'Supported: Ubuntu 24.04/26.04'; exit 1; }
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if systemctl is-active --quiet flaskapp; then
  echo 'Legacy flaskapp is active. Use the Week 2 migration procedure, not clean installation.' >&2; exit 1
fi
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git nginx ufw openssl python3
if ! docker compose version >/dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker nginx
usermod -aG docker "$SUDO_USER"
install -m 0644 "$ROOT/nginx/flaskapp" /etc/nginx/sites-available/flaskapp
ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/flaskapp
if [[ -L /etc/nginx/sites-enabled/default ]]; then unlink /etc/nginx/sites-enabled/default; fi
nginx -t
systemctl reload nginx
bash "$ROOT/scripts/setup-firewall.sh"
echo 'Host ready. Log out/in for docker group, then run scripts/week4/deploy-clean.sh as the normal user.'

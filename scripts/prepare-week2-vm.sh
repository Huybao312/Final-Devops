#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 || -z "${SUDO_USER:-}" || "$SUDO_USER" == root ]]; then
  echo "Run from a normal Ubuntu account: sudo bash scripts/prepare-week2-vm.sh" >&2
  exit 1
fi

if [[ ! -f /etc/os-release ]]; then
  echo "Ubuntu OS information is missing" >&2
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != ubuntu ]]; then
  echo "This setup script supports Ubuntu only" >&2
  exit 1
fi

APP_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
BACKUP="$APP_HOME/todo-week1-preflight-$(date +%Y%m%d-%H%M%S).dump"

echo "==> Backing up the existing PostgreSQL database before changing packages"
install -m 0600 -o "$SUDO_USER" -g "$SUDO_USER" /dev/null "$BACKUP"
runuser -u postgres -- pg_dump -Fc -d todo > "$BACKUP"
echo "Backup: $BACKUP"
echo "SHA256: $(sha256sum "$BACKUP" | cut -d' ' -f1)"
printf 'Existing tasks: '
runuser -u postgres -- psql -d todo -tAc 'SELECT count(*) FROM public.tasks;'

if ! command -v docker >/dev/null || ! docker compose version >/dev/null 2>&1; then
  echo "==> Installing Docker Engine and Compose plugin from Docker's Ubuntu repository"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl
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
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker
usermod -aG docker "$SUDO_USER"
echo "Docker: $(docker --version)"
echo "Compose: $(docker compose version --short)"
echo "Next: log out of SSH and back in so the docker group is active."
echo "The Week 1 app and PostgreSQL services have not been stopped."

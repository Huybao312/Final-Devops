#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_NAME="${DB_NAME:-todo}"
DB_APP_USER="${DB_APP_USER:-todo_app}"
DB_OWNER_ROLE="${DB_OWNER_ROLE:-todo_owner}"
ENV_FILE="${ENV_FILE:-/etc/todo-task-manager.env}"
SCHEMA_FILE="$APP_DIR/db/schema.sql"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run with sudo: sudo bash scripts/setup-db.sh" >&2
  exit 1
fi

for value in "$DB_NAME" "$DB_APP_USER" "$DB_OWNER_ROLE"; do
  if [[ ! "$value" =~ ^[a-z_][a-z0-9_]*$ ]]; then
    echo "ERROR: invalid PostgreSQL identifier: $value" >&2
    exit 1
  fi
done

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found. Install PostgreSQL first: sudo apt install -y postgresql" >&2
  exit 1
fi
if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "ERROR: schema not found: $SCHEMA_FILE" >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  echo "ERROR: openssl not found. Install it: sudo apt install -y openssl" >&2
  exit 1
fi

systemctl enable --now postgresql

DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -hex 24)}"
if [[ ! "$DB_PASSWORD" =~ ^[A-Za-z0-9._~-]+$ ]]; then
  echo "ERROR: DB_PASSWORD must contain only URL-safe characters (A-Z a-z 0-9 . _ ~ -)." >&2
  exit 1
fi

role_exists() {
  runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$1'" | grep -q 1
}

db_exists() {
  runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$1'" | grep -q 1
}

# postgres cannot read the 0640 repository files; run from a neutral directory.
cd /tmp

if role_exists "$DB_OWNER_ROLE"; then
  echo "==> Role $DB_OWNER_ROLE already exists"
else
  echo "==> Creating role $DB_OWNER_ROLE (NOLOGIN, owns objects)"
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "CREATE ROLE ${DB_OWNER_ROLE} NOLOGIN;"
fi

if role_exists "$DB_APP_USER"; then
  echo "==> Updating password for role $DB_APP_USER"
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "ALTER ROLE ${DB_APP_USER} WITH LOGIN PASSWORD '${DB_PASSWORD}';"
else
  echo "==> Creating role $DB_APP_USER (LOGIN, DML only)"
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "CREATE ROLE ${DB_APP_USER} LOGIN PASSWORD '${DB_PASSWORD}';"
fi

if db_exists "$DB_NAME"; then
  echo "==> Database $DB_NAME already exists"
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_OWNER_ROLE};"
else
  echo "==> Creating database $DB_NAME"
  runuser -u postgres -- createdb --owner="${DB_OWNER_ROLE}" "${DB_NAME}"
fi

echo "==> Applying schema"
# Root opens the file; psql reads it from stdin as postgres.
runuser -u postgres -- psql -v ON_ERROR_STOP=1 -d "$DB_NAME" < "$SCHEMA_FILE"

echo "==> Applying ownership and least-privilege grants"
runuser -u postgres -- psql -v ON_ERROR_STOP=1 -d "$DB_NAME" <<SQL
ALTER TABLE public.tasks OWNER TO ${DB_OWNER_ROLE};
ALTER SEQUENCE public.tasks_id_seq OWNER TO ${DB_OWNER_ROLE};
REVOKE ALL ON DATABASE ${DB_NAME} FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_APP_USER};
GRANT USAGE ON SCHEMA public TO ${DB_APP_USER};
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.tasks TO ${DB_APP_USER};
GRANT USAGE, SELECT ON SEQUENCE public.tasks_id_seq TO ${DB_APP_USER};
SQL

echo "==> Writing $ENV_FILE (root:root, 0600)"
umask 077
install -m 0600 -o root -g root /dev/null "$ENV_FILE"
cat > "$ENV_FILE" <<EOF
# Managed by scripts/setup-db.sh. Do not commit this file.
DATABASE_URL=postgresql://${DB_APP_USER}:${DB_PASSWORD}@127.0.0.1:5432/${DB_NAME}
EOF

echo "==> Testing application role over TCP"
if ! PGPASSWORD="$DB_PASSWORD" psql -w -h 127.0.0.1 -U "$DB_APP_USER" -d "$DB_NAME" -tAc "SELECT 1" >/dev/null; then
  echo "ERROR: cannot connect as $DB_APP_USER. Check pg_hba.conf and the password." >&2
  exit 1
fi

if systemctl list-unit-files --type=service 2>/dev/null | grep -q '^flaskapp\.service'; then
  echo "==> Restarting flaskapp"
  systemctl restart flaskapp
fi

echo
echo "PostgreSQL is ready."
echo "  Database:   $DB_NAME"
echo "  App role:   $DB_APP_USER (SELECT/INSERT/UPDATE/DELETE only)"
echo "  Owner role: $DB_OWNER_ROLE (NOLOGIN)"
echo "  Env file:   $ENV_FILE (0600, root:root)"

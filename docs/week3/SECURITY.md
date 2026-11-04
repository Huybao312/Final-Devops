# Week 3 security and ports

Record PASS/FAIL and UTC date on the actual VM; config review alone is not proof.

| Check | Expected | Runtime result |
|---|---|---|
| SSH 22 | Needed for administration; key access | Pending |
| Nginx 80 | Public app entry on VM LAN | Pending |
| app 5000 | 127.0.0.1 only | Pending |
| PostgreSQL 5432 | No host publish; internal backend network | Pending |
| Grafana 3000 | 127.0.0.1; SSH tunnel + login | Pending |
| Prometheus 9090, exporters 9100/9115 | 127.0.0.1 only | Pending |
| UFW | deny incoming; allow SSH/HTTP only | Pending |
| DB role todo_app | DML only; no superuser/DDL/role creation | Pending |
| Secrets | outside Git; files 600; owner only | Pending |
| Docker logs | rotated; no passwords printed | Pending |

Run `bash scripts/week3/security-audit.sh`. Existing `sudo bash scripts/setup-firewall.sh` enables deny-incoming plus SSH/HTTP. Inspect existing UFW rules first: the script does not remove earlier allow rules. Remove unnecessary allow rules explicitly after review. Keep an SSH connection and UTM console open while changing firewall. Docker port publishing can bypass UFW; loopback bindings and no DB publish are necessary independent controls.

Production passwords stay in GitHub Actions secrets and the VM env file; Grafana generates its own credential outside repo. App uses todo_app, PostgreSQL administrative access is reserved for backup/restore and administration. Docker group grants effective root access; it is not a restricted user role. Only the trusted deployment user should belong. GitHub runner executes repository workflows: restrict repo write rights and production environment access; do not run untrusted fork code on that runner.

The existing PostgreSQL Week 1 host service may still be present for rollback. Audit `ss -lnt` for its port too; verify it binds loopback or stop it only after a tested backup and explicit rollback decision. Do not confuse it with the container database.

`.env`/dumps are ignored, but ignore rules do not remove historic secrets. Review history before public submission; if a credential has leaked, rotate it. Do not show `.env`, `docker inspect` environment output or `docker compose config` (without `-q`) while screen sharing.

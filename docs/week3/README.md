# Week 3 — Monitoring, Security & Reliability

## Architecture and install

Keep the Week 2 app/DB Compose project. `monitoring/compose.yaml` is an independent Linux VM stack: Node Exporter reads VM CPU/RAM, Blackbox probes Nginx `/health` (including DB connectivity), Prometheus stores metrics/alert state, Grafana provisions the dashboard. All monitoring ports bind loopback. Host networking here is intended for Ubuntu VM, not Docker Desktop host metrics.

On the VM, use a stable checkout separate from the runner workspace:

```bash
cd ~
git clone --branch main https://github.com/Huybao312/Final-Devops.git Final-Devops-week3
cd ~/Final-Devops-week3
bash scripts/week3/start-monitoring.sh
bash scripts/week3/backup.sh
bash scripts/week3/verify-restore.sh
bash scripts/week3/security-audit.sh
```

If installing from local files, copy this checkout to `~/Final-Devops-week3` instead. No script changes the production DB schema or clears its volume. Monitoring may need approximately 1–2 minutes of samples before CPU rate graphs appear. Four monitoring containers require additional VM memory; inspect `free -h`/`docker stats --no-stream`.

Canonical access ports on Mac: **13000 Grafana / 19090 Prometheus / 18080 app**. VM listeners remain loopback 3000/9090/80; SSH maps each Mac port to the corresponding VM port. Exporters stay VM-only 9100/9115; DB is not published.

From Mac, open one tunnel, replacing `VM_IP` with the VM address. If a tunnel is already running, reuse it; `ExitOnForwardFailure` prevents silently running a second conflicting tunnel:

```bash
ssh -i ~/.ssh/devops_week2_utm -o ExitOnForwardFailure=yes -N -L 13000:127.0.0.1:3000 -L 19090:127.0.0.1:9090 -L 18080:127.0.0.1:80 ubuntusever@VM_IP
```

Grafana: http://localhost:13000 (admin); dashboard UID `todo-week3`. Prometheus alerts: http://localhost:19090/alerts. App: http://localhost:18080. Read Grafana's configured password privately from `~/.config/todo-week3/monitoring.env` before screen sharing. It is stored outside Git with mode 600. Grafana initial password is only applied when its volume is first initialized.

## Logs and alert acceptance

App, DB and all four monitoring services use Docker JSON logs, rotated at 10 MB × 3 files per container. Gunicorn emits access/error logs to stdout/stderr with captured application output. Rotation is not long-term archival; save the incident time window before containers are replaced.

```bash
SINCE=10m bash scripts/week3/app.sh logs
# For a specific UTC incident time:
SINCE=2026-11-04T00:00:00Z bash scripts/week3/app.sh logs
```

`TodoAppUnavailable` fires after the probe fails continuously for 30 seconds (plus scrape/evaluation delay). Open Prometheus Alerts and show Pending → Firing → Inactive. This checkpoint accepts alert STATE; no email/Telegram delivery is claimed. `MonitoringTargetDown` catches failed exporters. No probe data must be investigated rather than treated as healthy.

## Backup policy and restore

`backup.sh [todo|week3_restore_name]` creates a custom-format PostgreSQL 18 archive and SHA-256 sidecar under `~/todo-backups` (directory 700, files 600). New sidecars contain a basename rather than an absolute path. Restore always hashes the exact selected archive and compares only the expected digest, including for legacy absolute-path sidecars. Copy or rename the archive together with its sidecar; altered archives are rejected before any database is created. Partial failures do not produce a complete archive. Local archives expire after 14 days; `operations.log` records outcomes. Run daily manually, or schedule with the VM user's crontab using the stable checkout path. Copy encrypted archives to a separate disk/device for host-loss protection: VM-local backup alone does not cover losing the VM disk.

```cron
0 2 * * * /bin/bash /home/ubuntusever/Final-Devops-week3/scripts/week3/backup.sh >> /home/ubuntusever/todo-backups/scheduler.log 2>&1
```

Create the backup directory before scheduling. Approximate recovery point is the most recent successful backup; no unmeasured RTO promise. Check scheduler logs and run restore drills.

`restore.sh ABSOLUTE_ARCHIVE NEW_DATABASE` validates the checksum and only accepts new `week3_restore_*` databases. It refuses overwriting existing DBs or restoring directly into production `todo`. Archive restored without ownership/ACL so verification objects are owned by postgres; this is a recovery verification, not production cutover. Real production recovery additionally needs a maintenance window and the application role grants restored/verified.

`verify-restore.sh` takes a production snapshot, restores it into an isolated DB, adds a synthetic marker, backs that DB up, deletes only that marker in the isolated DB, and restores into another NEW DB. Row count plus checksum of all task columns must match pre-deletion; the marker is printed. Logs remain outside Git in `restore-verification.log`. Verification DBs remain for evidence; after review remove only the printed `week3_restore_*` names with `docker exec DB_CONTAINER dropdb -U postgres NAME`.

## Deliverables and honest status

- Dashboard JSON and provisioning: `monitoring/`.
- Security/ports checklist: `SECURITY.md`.
- Backup/restore scripts and policy: `scripts/week3/`, this file.
- Incident playbook (3 scenarios): `PLAYBOOK.md`.
- Online demo script: `DEMO_ONLINE.md`.
- Save screenshots, alert state transitions, restore logs and logs around the actual incident in `docs/evidence/week3/` after redacting secrets/private addresses. Never substitute fabricated output for a runtime check.

Source references: [Node Exporter](https://prometheus.io/docs/guides/node-exporter/), [Prometheus alert rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/), [PostgreSQL 18 pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html).

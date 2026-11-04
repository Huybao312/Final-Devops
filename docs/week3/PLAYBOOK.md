# Incident playbook

## 1. App down / Nginx 502

Detect: Grafana health 0; `TodoAppUnavailable` Firing. Record UTC start with `date -u`.
Diagnose: `bash scripts/week3/app.sh status`, `SINCE=10m bash scripts/week3/app.sh logs`, `curl -i http://127.0.0.1/health`, `sudo journalctl -u nginx --since '10 min ago' --no-pager`. Inspect whether app is stopped, unhealthy, or failing to connect to DB. A stopped process may have only lifecycle logs; use Nginx upstream error log (`sudo tail -n 40 /var/log/nginx/error.log`) for the failed request.
Recover: `bash scripts/week3/app.sh start` for a stopped app. Do not rebuild/tag random source during recovery. For a configuration/code fault, correct the cause and use the tested deployment pipeline.
Verify: `/health` 200, `/version` expected SHA, Grafana health 1 and alert inactive. Record recovery time and cause.

## 2. App cannot reach database

Detect: `/health` 503, app requests fail while process remains running.
Diagnose: DB status/logs, `docker exec DB_CONTAINER pg_isready -U postgres -d todo`, disk usage `df -h`, internal network and credentials (privately). Distinguish network/auth errors from database crash or full disk. Never print passwords in incident evidence.
Recover: start the existing DB container if stopped; correct the actual disk/network/auth fault. Never delete the named volume or initialize an empty replacement as a shortcut.
Verify: SQL read succeeds, `/health` 200 and an existing task can be read. Do not simulate this incident against production just for extra screenshots.

## 3. Deleted task / restore needed

Detect: missing record; record time, scope, last successful backup.
Diagnose: distinguish accidental deletion from wrong DB/filters. Verify archive checksum and restore it into a NEW isolated DB using `restore.sh`. Query for the missing record.
Recover: run `verify-restore.sh` for the checkpoint drill; it modifies only synthetic data in an isolated DB. For a real incident, inspect restored rows and plan reviewed selective recovery or maintenance cutover; don't blindly overwrite current production data.
Verify: compare count/checksum and required records, preserve archive and restore log. Restore does not recover changes newer than the backup. Record data loss window, cause and prevention.

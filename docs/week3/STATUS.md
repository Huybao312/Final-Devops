# Verification status — 2026-11-04

## Passed on Ubuntu VM

- Four monitoring containers started; Grafana dashboard provisioned and visually checked with CPU/RAM/health data.
- Actual app outage: TodoAppUnavailable FIRING at 04:09:50 UTC; app recovered and alert cleared at 04:10:21 UTC. Earlier independent drill also passed.
- Production snapshot restored into an isolated database; synthetic marker added, backed up, deleted and restored into a second isolated database. Before deletion: 6 rows; after deletion: 5; after restore: 6. Full task checksum before/after restore: 8cc09cee92455447381358e714d084ac.
- Production remains 5 task records. Only isolated databases were modified in the deletion drill.
- Secret files mode 600; backup directory mode 700. Application role has DML grants and no superuser/create-role/create-database rights.
- Monitoring/app bind loopback. Container DB has no host publish; legacy Week 1 PostgreSQL listens loopback on 5432.
- Daily backup installed at 02:00 UTC in VM user's crontab; existing entries preserved. Scheduled execution has not yet occurred; manual backup and restore passed.
- GitHub configuration/alert-rule tests and real PostgreSQL app integration tests passed.

## Final security and deployment verification

- Owner ran the sudo firewall setup on VM console: UFW active, incoming deny, only 22/80 allowed for IPv4/IPv6. Output recorded in firewall-console.txt with its source identified.
- External port check from Mac: 22/80 reachable; 5000/5432/3000/9090/9100/9115 unreachable.
- Week 3 merged in PR #4; main pipeline deployed 1262dd141a4aeea7ff2ae5bf1226963e37948b07. Health healthy and production count still 5.
- Both app/DB inspect confirm json-file logging with max-size=10m and max-file=3.
- Initial deployment pipeline: https://github.com/Huybao312/Final-Devops/actions/runs/41771790899

All checkpoint functionality has runtime evidence. Scheduled backup's first automatic execution remains a future operational check; manual backup/restore already passed. Video is not fabricated: actual screenshots and logs are provided as the allowed alternative.

Evidence: docs/evidence/week3/. Screenshots and text/JSON are actual results, not illustrative output. No database dumps or secrets are committed.

## Follow-up audit fixes — 2026-11-04

- Portable basename sidecars; restore verifies the selected archive's bytes, including for legacy absolute-path sidecars. Live relocated/renamed restore passed; corrupted copy was rejected before DB creation, while its original still existed. Regression is part of CI.
- All four monitoring containers now have verified json-file rotation (10m × 3), matching app/DB.
- Canonical Mac ports: 13000 Grafana / 19090 Prometheus / 18080 app. Repo guide and Downloads demo use the same mapping. VM-only service ports remain unchanged.
- Backup cron first scheduled run and copying encrypted archives to a separate device remain operational follow-up items, not claimed as tested.
- Evidence: hardening-verification.txt.

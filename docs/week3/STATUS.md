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

## Pending

- UFW status/enable requires interactive sudo on VM console; user was given the command. No firewall PASS is claimed before its output is reviewed.
- Log rotation settings are in the deployment configuration; verify after main deployment recreates containers.

Evidence: docs/evidence/week3/. Screenshots and text/JSON are actual results, not illustrative output. No database dumps or secrets are committed.

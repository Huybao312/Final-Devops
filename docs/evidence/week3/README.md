# Week 3 runtime evidence

Recorded on Ubuntu VM on 2026-11-04 UTC.

- dashboard.jpg: provisioned Grafana with real CPU/RAM, health/latency.
- alert-firing.jpg / alert-firing.json: actual outage generated TodoAppUnavailable FIRING.
- alert-verification.txt: stop/recover lifecycle, timestamped app logs and successful alert resolution.
- alert-recovered.json / health-recovered.json: alert cleared and probe success 1.
- restore-verification.txt: full backup/delete/restore proof in isolated databases; production unchanged.
- runtime-audit.txt: ports, running services, production row count, secret file modes and installed backup schedule.
- cpu-metrics.json / memory-metrics.json: raw Prometheus measurements.

Firewall owner-console output, external port checks and final deployment/log-rotation verification are included. Archives remain outside repo on VM.

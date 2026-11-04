# Verification status — 2026-11-04

## Passed

- Local shell syntax and both Compose configurations.
- GitHub Week 3 configuration checks: https://github.com/Huybao312/Final-Devops/actions/runs/41770271678
- The CI run validates Prometheus config and synthetic alert firing/resolution; it does not prove VM runtime behavior.

## Pending VM access

- Actual dashboard samples and screenshots.
- App stop → alert FIRING → recovery → clear alert, with recorded time/log.
- Actual firewall/ports/DB permissions audit.
- Successful production backup and isolated delete/restore drill with matching row count/checksum.
- Online demo rehearsal, screenshots/video and redacted evidence.

SSH to the last known VM address timed out and the self-hosted runner reported offline. The checkpoint is not yet complete. No runtime evidence has been fabricated, and no production restore/firewall change has been executed in this work session.

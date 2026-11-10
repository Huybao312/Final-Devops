# Week 4 evidence

- `rehearsal-vm.txt`: fresh Compose project on Ubuntu 26.04.1 ARM64, 10/11/2026 04:01:38–04:02:42 UTC. Three induced faults, root cause/recovery, privilege denial, persistence and isolated restore all PASS. Independent of production.
- `rehearsal-local.txt`: same scenario on Docker Desktop with new project/secrets/volume. This initial local build was an uncommitted rehearsal; the source SHA label is a base reference, not a released image. Final verification is the committed source in CI and the release manifest.
- `local-tests.txt`: seven tests against a disposable PostgreSQL 18 container; no production DB used.
- `ci-checks.txt`: actual CLI output from PR #5 checks. Deploy skipped on PR is expected; main deployment is linked from release metadata.

Private network addresses in raw rehearsal logs are redacted as `[internal-address]`. No secret values or database archives are included. Week 3 dashboard/alert screenshots used in the report/video retain their original date and are identified as historical evidence. Browser access was unavailable during final document preparation, so no fresh UI screenshots were fabricated; current VM checks use API/logs.

The video walkthrough is a clearly labeled TTS rehearsal, not a recording of the named team members. Final member narration and contribution confirmation are human submission tasks.

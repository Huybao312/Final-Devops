# Week 4 evidence

- `rehearsal-vm.txt`: fresh Compose project on Ubuntu 26.04.1 ARM64, 10/11/2026 04:01:38–04:02:42 UTC. Three induced faults, root cause/recovery, privilege denial, persistence and isolated restore all PASS. Independent of production.
- `rehearsal-local.txt`: same scenario on Docker Desktop with new project/secrets/volume. This initial local build was an uncommitted rehearsal; the source SHA label is a base reference, not a released image. Final verification is the committed source in CI and the release manifest.
- `local-tests.txt`: seven tests against a disposable PostgreSQL 18 container; no production DB used.
- `ci-checks.txt`: actual CLI output from PR #5 checks. Deploy skipped on PR is expected; main deployment is linked from release metadata.

Private network addresses in raw rehearsal logs are redacted as `[internal-address]`. No secret values or database archives are included. Week 3 dashboard/alert screenshots used in the report/video retain their original date and are identified as historical evidence. Browser access was unavailable during final document preparation, so no fresh UI screenshots were fabricated; current VM checks use API/logs.

The video walkthrough is a clearly labeled TTS rehearsal, not a recording of the named team members. Final member narration and contribution confirmation are human submission tasks.

Final-candidate repeat on source f69d2059605b57571554772d884e0de6a3709777: rehearsal-final-vm.txt, 04:20:11–04:20:46 UTC, PASS all checks. Older runs remain identified by their own SHA/date.

## Kiểm chứng bổ sung 11/11/2026

- `final-tests-2026-11-11.txt`: 7 test tích hợp trên PostgreSQL riêng; SHA source thử ghi trong file.
- `rehearsal-2026-11-11.txt`: triển khai độc lập, ba sự cố/phục hồi, persistence, least privilege, restore 2→1→2 và checksum khớp.
- `configuration-checks-2026-11-11.txt`: cú pháp shell, Compose, checksum và alert rules.

Các mốc thời gian trước khi sửa lệch giờ VM phản ánh đồng hồ VM lúc ghi log, không phải phép đo thời gian thực. Không dùng chênh lệch timestamp qua lần chỉnh giờ để suy luận downtime. Báo cáo và video cuối do nhóm bổ sung riêng.

# Ma trận nghiệm thu cuối

| Yêu cầu Week 4 | Hồ sơ / minh chứng | Trạng thái |
|---|---|---|
| Tích hợp Week 1–3 ổn định | compose.yaml, monitoring/, CI/CD và evidence tuần 2–4 | Kiểm chứng runtime; bản final cần đối chiếu main/release SHA |
| Guide từ server sạch | DEPLOYMENT.md + install-host.sh + deploy-clean.sh | Có guide; fresh Compose trên Ubuntu và Docker Desktop PASS; không reset OS production |
| Commit → CI/CD → app mới | Workflow tuần 2, PR final, /version | Merge/deploy cuối được ghi trong release manifest |
| Monitoring/logs/health/security | Dashboard/rules/log rotation, security checklist, ảnh/log tuần 3 và kiểm tra tuần 4 | Có minh chứng thật; không tuyên bố có notification email |
| Backup/restore đúng dữ liệu | verify-restore.sh + rehearsal-vm.txt | PASS 2→1→2, checksum khớp; production không bị xóa |
| ≥3 sự cố thực nghiệm | PLAYBOOK.md và rehearsal-vm.txt | App stopped, DB stopped, wrong proxy upstream PASS |
| Final repo + release/tag | RELEASE.md + GitHub release | Tag/manifest được tạo sau CI cuối |
| Sơ đồ final + operations README | architecture.svg, ARCHITECTURE.md, README, docs/week3 | Hoàn thiện |
| Technical paper 6–10 trang đề xuất | REPORT.md / REPORT.pdf | PDF 8 trang, đã render kiểm tra |
| Video thuyết minh 5–10 phút | VIDEO_SCRIPT.md, bản walkthrough giọng tổng hợp 5 phút 30 giây | Có bản tập 5:30; nhóm cần thu thuyết minh thật trước khi nộp, không giả giọng thành viên |
| Q&A/đóng góp cá nhân | DEMO_ONLINE.md + contribution-log.md | Danh sách/phân công đã xác nhận; mỗi người phải tự bảo vệ và xác nhận phần thực hiện |

## Giới hạn nghiệm thu

- Test PASS là bằng chứng cho lần chạy và các trường hợp đã nêu, không chứng minh không thể còn lỗi.
- Diễn tập trên project/volume mới chứng minh khởi tạo stack độc lập; không được nói đã factory-reset OS nếu chưa làm.
- TTS walkthrough là bản tập, không thay bản ghi thành viên giải thích theo yêu cầu lớp.
- Bản backup Mac chưa là backup trên thiết bị vật lý độc lập; cron có lịch cài đặt và kiểm thử môi trường tối giản, không gán lịch sử chạy tự động chưa quan sát.
- Không ghi khống commit/đóng góp hoặc copy mật khẩu vào report/video.

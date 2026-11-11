# Hồ sơ nộp DevOps Final Project 2026

Repo: https://github.com/Huybao312/Final-Devops

Bản cập nhật hoàn thiện kỹ thuật: `v1.0.1-final`. Tag cũ `v1.0.0-final` được giữ nguyên để đối chiếu lịch sử. Báo cáo kỹ thuật và video thuyết minh cuối do nhóm bổ sung riêng; các bản report/video tham khảo trước đây không phải xác nhận đã nộp hai yêu cầu này.

## Đọc theo thứ tự

1. [README và kiến trúc](README.md), [ảnh tổng thể](docs/architecture.png).
2. [Triển khai từ Ubuntu sạch](docs/week4/DEPLOYMENT.md).
3. [Vận hành, backup và cổng dịch vụ](docs/week3/README.md).
4. [Playbook 7 sự cố, cách xác minh và phục hồi](docs/week4/PLAYBOOK.md).
5. [Minh chứng kỹ thuật](docs/evidence/week4/README.md).

## Môi trường và thao tác

- Sửa code/Git trên Mac trong repo này. Không chạy UFW hoặc script Linux trên Mac.
- Vận hành VM: SSH vào Ubuntu rồi `cd /home/ubuntusever/Final-Devops-week4`. Đây là đường dẫn của VM hiện hữu; guide cài mới dùng `~/Final-Devops`.
- Job deploy chạy trong workspace riêng của GitHub runner. Workspace này được GitHub Actions quản lý, không phải một ứng dụng khác.
- Bản diễn tập dùng cùng code, nhưng container/database/volume/config riêng để thử lỗi. Nó không thay thế app chính và không được theo dõi bởi dashboard production.
- Grafana 13000, Prometheus 19090, app qua Nginx 18080 trên Mac qua SSH tunnel. VM phải bật; kiểm tra đồng bộ giờ trước buổi demo.
- Secrets, private keys, database dumps và thư mục venv không thuộc bản nộp. Không tự tạo mật khẩu DB mới nếu volume đang có dữ liệu.

## Trạng thái kiểm chứng ngày 11/11/2026

- PostgreSQL 18 tích hợp: 7 test PASS trên database riêng.
- Shell syntax, Compose app/monitoring, checksum và Prometheus alert rules được kiểm tra.
- Rehearsal VM: ba sự cố, phục hồi, persistence, quyền DB và restore count/checksum PASS; log lưu trong evidence.
- Sửa lệch giờ VM; dashboard trả dữ liệu và Active alerts hiển thị 0 khi không firing.
- Đăng ký lại runner, khôi phục service; deploy demo commit 71124e2 thành công. Bản source cuối được kiểm chứng tiếp qua workflow và /version sau push; xem tag và lịch sử Actions cho SHA cuối.

## Nhóm bổ sung trước khi gửi bài

- Báo cáo theo template giảng viên và thông tin còn thiếu của thành viên.
- Video 5–10 phút do thành viên thuyết minh; không dùng bản giọng tổng hợp như video thành viên.
- Mỗi thành viên luyện phần phụ trách và Q&A, mở thử link repo/release bằng quyền người xem phù hợp.

Test PASS phản ánh những lần chạy được ghi lại. Bản triển khai phục vụ một VM local/LAN, chưa có HA, public TLS hoặc đăng nhập ứng dụng.

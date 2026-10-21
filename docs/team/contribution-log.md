# Nhật ký đóng góp

Chỉ ghi **việc thật đã làm**. Mỗi dòng phải có commit hash hoặc minh chứng (log/ảnh) tương ứng. Không điền khống, không backdate commit.

| Ngày | Thành viên | Việc đã làm | Commit | Minh chứng |
|---|---|---|---|---|
|  | Lê Hoàng Tùng |  |  |  |
|  | Phùng Ngô Huy Bảo |  |  |  |
|  | Đào Tuấn Bảo |  |  |  |

## Gợi ý việc thật cho từng thành viên

### Lê Hoàng Tùng — nhóm trưởng

- Dựng UTM VM, cài Ubuntu Server 26.04 ARM64.
- Cấu hình SSH, UFW, PostgreSQL role/database.
- Viết `systemd/flaskapp.service`, `nginx/flaskapp`, `scripts/bootstrap.sh`, `scripts/setup-db.sh`.
- Chuyển `app.py` từ SQLite sang psycopg/PostgreSQL.
- Viết `README.md`, `docs/architecture.md`, `docs/architecture.drawio`.
- Demo và trả lời Q&A.

### Phùng Ngô Huy Bảo

- Review diff chuyển PostgreSQL: kiểm tra CRUD, kiểu `boolean`, `created_at`.
- Chạy test chức năng trên VM: tạo/sửa/toggle/xóa task.
- Ghi lại ít nhất một lỗi hoặc đề xuất cải tiến vào `docs/reviews/app-review.md`.
- Commit review + kết quả test.

### Đào Tuấn Bảo

- Chạy `sudo bash scripts/verify-app.sh`, kiểm tra output.
- Chụp ảnh giao diện app, `systemctl status`, `ufw status`, `ss -lntp`.
- Thu `server-info.txt`, `verify-app.txt`.
- Viết 2 mục troubleshooting thực tế gặp phải trong `docs/evidence/`.
- Commit evidence + ảnh.

> Nếu một thành viên không có commit thật, không ghi tên vào cột "việc đã làm". Điểm cá nhân dựa trên commit log và câu trả lời bảo vệ; ghi khống dễ bị phát hiện khi giảng viên hỏi.

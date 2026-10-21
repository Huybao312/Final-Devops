# Kịch bản demo Week 1 (5 phút)

## 0. Trước khi vào demo (10 phút)

Chạy trên Mac:

```bash
ssh <user>@<VM_IP>
```

Trên VM:

```bash
cd /opt/todo-task-manager
sudo systemctl status flaskapp nginx postgresql --no-pager
curl -fsS http://127.0.0.1/health
hostname -I
```

Mở sẵn trên Mac:

- `http://<VM_IP>/`
- Terminal SSH vào VM
- `docs/architecture.png`
- `docs/evidence/verify-app.txt`

Nếu IP đổi:

```bash
hostname -I
```

## 1. Kiến trúc (30 giây)

Nói:

> Đây là ứng dụng Todo Task Manager chạy trên Ubuntu Server 26.04 ARM64 trong UTM. Trình duyệt trên Mac vào Nginx cổng 80; Nginx chuyển tiếp tới Gunicorn ở loopback 5000; Flask kết nối PostgreSQL ở loopback 5432. Chỉ cổng 22 và 80 được mở qua UFW; database không lộ ra mạng.

Chỉ vào sơ đồ:

- Client → Nginx :80
- Nginx → Gunicorn 127.0.0.1:5000
- Gunicorn → PostgreSQL 127.0.0.1:5432
- PostgreSQL → `/var/lib/postgresql`

## 2. Server, port, firewall (1 phút)

Chạy:

```bash
hostname -I
sudo ss -lntp
sudo ufw status verbose
systemctl status flaskapp --no-pager
```

Nói:

- VM nhận IP `192.168.64.x` qua UTM Shared Network.
- `ss` cho thấy 80 do Nginx, 5000 do Gunicorn, 5432 do PostgreSQL; 5000/5432 chỉ loopback.
- UFW chỉ allow 22 và 80.
- systemd quản lý app, tự restart khi lỗi.

## 3. Demo chức năng (1.5 phút)

Trên trình duyệt:

1. Mở `http://<VM_IP>/`.
2. Tạo task: title `Demo Week 1`, description `Kiểm tra ghi dữ liệu`.
3. Sửa task thành `Demo Week 1 - edited`.
4. Bấm toggle để chuyển sang hoàn thành.
5. Refresh trang — dữ liệu vẫn còn.
6. Xóa một task thử nghiệm.

Nói:

> Mỗi thao tác là một POST request đi qua Nginx → Gunicorn → Flask → PostgreSQL. Dữ liệu không nằm trong bộ nhớ app.

## 4. Chứng minh database (1 phút)

Trên terminal:

```bash
sudo -u postgres psql -d todo -c \
  "SELECT id, title, completed, created_at FROM tasks ORDER BY id DESC LIMIT 5;"
```

Nói:

- Bản ghi vừa tạo xuất hiện trong PostgreSQL.
- `completed` là boolean, `created_at` là timestamptz.
- Role `todo_app` chỉ có DML; kiểm tra:

```bash
sudo -u postgres psql -d todo -c "\dp public.tasks"
```

## 5. Log và health (30 giây)

```bash
curl -fsS http://127.0.0.1/health
journalctl -u flaskapp -n 20 --no-pager
```

Nói:

- `/health` kiểm tra cả app và kết nối DB.
- Log tập trung trong journald; Nginx có access/error log riêng.

## 6. Bằng chứng tự động (30 giây)

```bash
sudo bash scripts/verify-app.sh
```

Nói:

> Script tạo task qua Nginx, đọc lại từ HTML, query trực tiếp PostgreSQL, toggle và kiểm tra quyền của role app. Đây là bằng chứng lặp lại được, không phải thao tác thủ công.

## 7. Câu hỏi dự kiến

**Vì sao dùng Nginx?**  
Nginx làm reverse proxy, nhận cổng 80, ẩn Gunicorn khỏi mạng, thêm header và log; Gunicorn không cần bind public.

**Vì sao Gunicorn thay vì Flask dev server?**  
Flask dev server chỉ để phát triển; Gunicorn là WSGI server production, có worker, restart, log.

**Vì sao PostgreSQL thay vì SQLite?**  
SQLite là file, không có database service/role/network boundary; Week 2 cần DB service trong Compose, Week 3 cần phân quyền và backup/restore.

**Password nằm ở đâu?**  
Trong `/etc/todo-task-manager.env`, quyền 0600 root:root, không commit. systemd đọc file và truyền `DATABASE_URL` cho app.

**Nếu DB chết thì sao?**  
`/health` trả 503; Nginx vẫn chạy; sửa DB rồi restart app. systemd unit có `Requires=postgresql.service`.

**Vì sao app chạy user `www-data`?**  
Không chạy root; giảm thiệt hại nếu app bị khai thác. App dir chỉ cho group đọc.

**Vì sao 5000/5432 không mở?**  
Không cần thiết; chỉ Nginx và app local cần. Mở ra ngoài là tăng bề mặt tấn công.

## 8. Phương án dự phòng

Nếu UTM network hoặc SSH lỗi:

1. Mở UTM console, đăng nhập trực tiếp.
2. Chạy `hostname -I`, `systemctl status flaskapp`, `curl 127.0.0.1/health`.
3. Dùng ảnh/video đã chuẩn bị trong `docs/evidence/`.
4. Nếu IP đổi, mở `http://<IP mới>/`.

Không bao giờ tắt UFW hoặc mở 5432 để "cứu" demo.

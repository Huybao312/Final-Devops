# Bằng chứng Week 1

Thư mục này chứa bằng chứng kỹ thuật cho checkpoint **Infrastructure & Initial Deployment**. Mọi file phải là output thật từ VM, không chỉnh sửa thủ công.

## 1. Danh sách bắt buộc

| # | Bằng chứng | Cách tạo | File gợi ý |
|---|---|---|---|
| 1 | Cấu hình server | `sudo bash scripts/server-info.sh` | `server-info.txt` |
| 2 | Ghi/đọc dữ liệu | `sudo bash scripts/verify-app.sh` | `verify-app.txt` |
| 3 | Firewall | `sudo ufw status verbose` | `ufw-status.txt` |
| 4 | Port đang listen | `sudo ss -lntp` | `listening-ports.txt` |
| 5 | Trạng thái service | `systemctl status flaskapp nginx postgresql --no-pager` | `services.txt` |
| 6 | Giao diện app | Chụp màn hình trình duyệt | `01-app-list.png`, `02-app-create.png` |
| 7 | Dữ liệu trong DB | `sudo -u postgres psql -d todo -c "SELECT ..."` | `03-db-rows.png` hoặc `.txt` |
| 8 | Kiến trúc | Đã có sẵn trong repo | `docs/architecture.png` |
| 9 | Video dự phòng | Quay màn hình demo 3–5 phút | `demo-fallback.mp4` (không commit nếu nặng) |

## 2. Lệnh thu thập

Chạy trên Ubuntu VM, trong repo:

```bash
sudo bash scripts/server-info.sh
sudo bash scripts/verify-app.sh

sudo ufw status verbose | tee docs/evidence/ufw-status.txt
sudo ss -lntp | tee docs/evidence/listening-ports.txt
systemctl status flaskapp nginx postgresql --no-pager | tee docs/evidence/services.txt
```

Kiểm tra file:

```bash
ls -lah docs/evidence/
```

## 3. Ảnh chụp cần có

1. **Trang chủ app** với ít nhất 3 task, trong đó có task đã hoàn thành.
2. **Form tạo task** đang nhập title/description.
3. **Sau khi tạo** — task mới xuất hiện trong danh sách.
4. **Sau khi sửa/toggle** — nội dung hoặc trạng thái thay đổi.
5. **Query PostgreSQL** — cùng bản ghi hiển thị trong terminal.
6. **`systemctl status flaskapp`** — `active (running)`.
7. **`ufw status verbose`** — chỉ 22/tcp và 80/tcp.
8. **`ss -lntp`** — 5000 và 5432 chỉ bind `127.0.0.1`.
9. **UTM console** — `hostname -I` hoặc `ip -brief address` để chứng minh IP.
10. **Sơ đồ kiến trúc** — export PNG.

## 4. Quy tắc bảo mật

- Không chụp hoặc commit `/etc/todo-task-manager.env`.
- Không để lộ password trong terminal, ảnh, video, log.
- Không chụp SSH private key.
- IP `192.168.64.x` là IP private, được phép dùng trong báo cáo.
- Nếu ảnh có password, che trước khi commit.

## 5. Checklist trước demo

- [ ] `curl -fsS http://127.0.0.1/health` trả `{"status":"healthy"}`.
- [ ] Mở được `http://<VM_IP>/` từ Safari/Chrome trên Mac.
- [ ] Tạo/sửa/xóa task thành công.
- [ ] Query PostgreSQL thấy đúng bản ghi.
- [ ] `systemctl status flaskapp` là `active (running)`.
- [ ] `ufw status verbose` chỉ có 22, 80.
- [ ] `ss -lntp` không có 5000/5432 bind `0.0.0.0`.
- [ ] Có video/screenshot dự phòng nếu mạng UTM lỗi.
- [ ] Repo đã push commit mới nhất.

## 6. Bằng chứng Week 2

- [`week2-cutover.txt`](week2-cutover.txt): 4 bản ghi và checksum trùng giữa PostgreSQL tuần 1 và container.
- [`week2-persistence.txt`](week2-persistence.txt): task còn sau `docker compose down` và `up` trên VM.
- [`week2-runtime.txt`](week2-runtime.txt): container, health, role và port trước deploy tự động.
- [`week2-deploy.txt`](week2-deploy.txt): workflow `build-test → deploy` xanh, `/version` đổi từ `local` sang SHA commit mới, DB vẫn còn dữ liệu.
- [`week2-app-after.png`](week2-app-after.png): giao diện từ Mac sau deploy.

Log và ảnh tuần 2 là kết quả chạy thật trên VM hoặc máy Mac, không chứa password/token. Video demo có lời giải thích của nhóm vẫn cần nhóm tự ghi.

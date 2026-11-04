# Kịch bản demo online Week 3 — 8–10 phút

## Chuẩn bị trước giờ chia sẻ màn hình

- VM phải đang bật; Docker, Nginx, monitoring đã chạy. Không để Mac/VM ngủ khi demo.
- Terminal VM ở `~/Final-Devops-week3`, một terminal Mac giữ SSH tunnel theo README.
- Mở http://localhost:3000/d/todo-week3, http://localhost:9090/alerts và http://localhost:8080.
- Đăng nhập Grafana trước; đóng cửa sổ chứa mật khẩu. Chỉ chia sẻ cửa sổ trình duyệt/terminal demo.
- Đã chạy thử `verify-restore.sh`; lưu ảnh/log kết quả thật làm dự phòng. Không nói PASS nếu chưa chạy.

## 1. Dashboard — 1 phút

**Nói:** “Tuần 3 em bổ sung giám sát trên VM. Dashboard thể hiện CPU, RAM, health và độ trễ. Health được kiểm tra qua Nginx tới app; endpoint còn kiểm tra kết nối PostgreSQL.”

Mở dashboard, chọn Last 15 minutes. Chỉ vào CPU, RAM và health = 1. Nếu CPU chưa có dữ liệu, chờ khoảng 2 phút từ lúc monitoring khởi động.

## 2. Cảnh báo, logs và phục hồi — 2–3 phút

**Nói trước lệnh:** “Em sẽ dừng riêng app để tạo lỗi thật. Database vẫn chạy. Script chờ alert FIRING rồi khởi động lại app; có cơ chế phục hồi khi script kết thúc.”

Trên terminal VM:

```bash
cd ~/Final-Devops-week3
bash scripts/week3/demo-alert.sh
```

Trong lúc đợi, chuyển trình duyệt sang Alerts. **Nói:** “Probe phát hiện lỗi, rule chờ 30 giây để tránh báo động do lỗi thoáng qua. Trạng thái đi từ Pending sang Firing; đây là cảnh báo đã được kiểm thử.”

Chụp ảnh khi Firing; quay lại terminal xem log. **Nói:** “Em tra log theo khoảng thời gian xảy ra sự cố. App đã được start lại; health trở về 1 và cảnh báo được xóa sau lần đánh giá tiếp theo.”

Nếu cần xem lại log trong cửa sổ thời gian:

```bash
SINCE=5m bash scripts/week3/app.sh logs
```

**Nói:** “Lệnh lọc log app/database trong 5 phút gần nhất, kèm timestamp. Em không cần đọc toàn bộ log từ lúc hệ thống được cài.”

## 3. Bảo mật — 1 phút

**Nói trước lệnh:** “Em kiểm tra port, firewall, quyền DB và quyền file secrets. Nội dung mật khẩu không được đưa lên màn hình.”

```bash
bash scripts/week3/security-audit.sh
```

**Nói sau kết quả:** “Nginx là cổng vào app. App và monitoring chỉ bind loopback; PostgreSQL không publish port ra host. Dashboard được mở qua SSH tunnel. User app có quyền thao tác dữ liệu, không có quyền superuser hay tạo role. Docker group là quyền quản trị mạnh nên chỉ cấp cho user triển khai tin cậy.”

Chỉ nói các kết luận trên nếu output thật khớp checklist; giải thích và sửa nếu phát hiện port thừa.

## 4. Backup → xóa dữ liệu thử → restore — 2–3 phút

**Nói trước lệnh:** “Em backup production rồi restore vào DB kiểm chứng riêng. Tại DB kiểm chứng em tạo một bản ghi thử, backup, xóa bản ghi và restore lại. Cách này chứng minh khả năng khôi phục mà vẫn bảo vệ dữ liệu hiện tại.”

```bash
bash scripts/week3/verify-restore.sh
```

Chỉ vào ba dòng `Before deletion`, `After deletion`, `After restore` và bản ghi marker.

**Nói:** “Sau khi xóa, số dòng/checksum thay đổi. Sau restore, cả số dòng và checksum của toàn bộ bảng khớp bản trước khi xóa; bản ghi thử đã trở lại. Backup được lưu ngoài repo, file chỉ chủ sở hữu đọc được, có checksum và giữ 14 ngày.”

Không chỉ nhìn dòng PASS: chỉ ra marker và giá trị count/checksum thật. DB kiểm chứng còn lại để kiểm tra sau buổi demo.

## 5. Kết thúc — 30 giây

**Nói:** “Em có ba playbook: app không phản hồi, mất kết nối database và khôi phục dữ liệu. Mỗi playbook có phát hiện, chẩn đoán, phục hồi và bước xác nhận. Backup trên cùng VM chưa bảo vệ khi mất ổ VM; cần thêm bản sao ở thiết bị khác cho tình huống đó.”

Mở `docs/week3/PLAYBOOK.md`, cho xem ba mục. Kết thúc bằng dashboard health = 1 và app hoạt động.

## Dự phòng khi mạng/VM lỗi

Chiếu ảnh/video/log của lần chạy thật gần nhất; nói rõ đó là bản ghi trước, không mô tả là live. Nếu app chưa phục hồi: `bash scripts/week3/app.sh start`, sau đó kiểm tra `curl -fsS http://127.0.0.1/health`. Không xóa volume, không restore đè production trong lúc trình bày.

# Tuần 3 — Giám sát, bảo mật và độ tin cậy

## Kiến trúc và cài đặt

Giữ nguyên dự án Compose ứng dụng/cơ sở dữ liệu của tuần 2. `monitoring/compose.yaml` là bộ dịch vụ độc lập trên máy ảo Linux: Node Exporter đọc CPU/RAM của máy ảo, Blackbox thăm dò `/health` qua Nginx (gồm kiểm tra kết nối DB), Prometheus lưu số liệu/trạng thái cảnh báo, Grafana cấp cấu hình bảng điều khiển. Tất cả cổng giám sát chỉ nghe loopback. Chế độ mạng host ở đây dành cho máy ảo Ubuntu, không phải lấy số liệu máy chủ Docker Desktop.

Trên máy ảo, dùng bản mã nguồn ổn định, tách khỏi thư mục làm việc của runner:

```bash
cd ~
git clone --branch main https://github.com/Huybao312/Final-Devops.git Final-Devops-week3
cd ~/Final-Devops-week3
bash scripts/week3/start-monitoring.sh
bash scripts/week3/backup.sh
bash scripts/week3/verify-restore.sh
bash scripts/week3/security-audit.sh
```

Nếu cài từ tệp cục bộ, sao chép bản mã nguồn này vào `~/Final-Devops-week3`. Các script không thay đổi cấu trúc DB production hoặc xóa volume của nó. Cần khoảng 1–2 phút lấy mẫu để đồ thị CPU xuất hiện. Bốn container giám sát cần thêm RAM máy ảo; kiểm tra bằng `free -h`/`docker stats --no-stream`.

Cổng truy cập thống nhất trên Mac: **13000 Grafana / 19090 Prometheus / 18080 ứng dụng**. Dịch vụ bên trong máy ảo vẫn dùng 3000/9090/80; SSH ánh xạ từng cổng Mac tới cổng tương ứng. Grafana/Prometheus nghe loopback; địa chỉ nghe của Nginx không bị đường hầm thay đổi. Các bộ xuất số liệu chỉ dùng nội bộ máy ảo tại 9100/9115; container DB không công bố cổng.

Từ Mac, mở một đường hầm, thay `VM_IP` bằng địa chỉ máy ảo. Nếu đã có đường hầm hoạt động đúng, dùng lại; `ExitOnForwardFailure` ngăn kết nối thứ hai âm thầm chạy khi cổng chuyển tiếp bị xung đột:

```bash
ssh -i ~/.ssh/devops_week2_utm -o ExitOnForwardFailure=yes -N -L 13000:127.0.0.1:3000 -L 19090:127.0.0.1:9090 -L 18080:127.0.0.1:80 ubuntusever@VM_IP
```

Grafana: http://localhost:13000 (tài khoản admin); mã bảng điều khiển `todo-week3`. Cảnh báo Prometheus: http://localhost:19090/alerts. Ứng dụng: http://localhost:18080. Đọc riêng mật khẩu Grafana đã cấu hình tại `~/.config/todo-week3/monitoring.env` trước khi chia sẻ màn hình. Tệp nằm ngoài Git với quyền 600. Mật khẩu khởi tạo Grafana chỉ được áp dụng khi volume được khởi tạo lần đầu.

## Nhật ký và kiểm chứng cảnh báo

Ứng dụng, DB và bốn dịch vụ giám sát dùng nhật ký JSON của Docker, luân chuyển tối đa 3 tệp, mỗi tệp 10 MB cho từng container. Gunicorn đưa nhật ký truy cập/lỗi ra stdout/stderr và thu đầu ra ứng dụng. Luân chuyển không phải lưu trữ dài hạn; lưu nhật ký trong khoảng thời gian sự cố trước khi thay container.

```bash
SINCE=10m bash scripts/week3/app.sh logs
# Tra cứu từ một thời điểm sự cố cụ thể theo UTC:
SINCE=2026-11-04T00:00:00Z bash scripts/week3/app.sh logs
```

`TodoAppUnavailable` kích hoạt khi thăm dò thất bại liên tục 30 giây (cộng độ trễ lấy mẫu/đánh giá). Mở Prometheus Alerts và trình bày Pending → Firing → Inactive (chờ xác nhận → đang cảnh báo → không hoạt động). Checkpoint chấp nhận trạng thái cảnh báo; không tuyên bố đã gửi email/Telegram. `MonitoringTargetDown` phát hiện đích giám sát không truy cập được. Nếu không có số liệu thăm dò, phải điều tra, không coi là khỏe.

## Chính sách sao lưu và khôi phục

`backup.sh [todo|week3_restore_name]` tạo tệp sao lưu PostgreSQL 18 định dạng custom và tệp SHA-256 đi kèm tại `~/todo-backups` (thư mục quyền 700, tệp quyền 600). Tệp SHA-256 mới dùng tên tệp thay vì đường dẫn tuyệt đối. Khôi phục luôn tính mã kiểm tra của đúng tệp được chọn và so sánh với giá trị mong đợi, kể cả tệp đi kèm cũ dùng đường dẫn tuyệt đối. Sao chép/đổi tên cả tệp sao lưu và tệp đi kèm; tệp bị thay đổi sẽ bị từ chối trước khi tạo DB. Lỗi giữa chừng không tạo ra tệp sao lưu hoàn chỉnh. Script dọn bản sao lưu cũ hơn 14 ngày khi chạy; `operations.log` ghi kết quả. Chạy thủ công hằng ngày hoặc đặt lịch trong crontab của người dùng máy ảo với đường dẫn mã nguồn ổn định. Sao chép bản sao lưu đã mã hóa sang đĩa/thiết bị khác để phòng mất máy chủ: bản sao lưu cùng máy ảo không bảo vệ khi mất ổ đĩa máy ảo.

```cron
0 2 * * * /bin/bash /home/ubuntusever/Final-Devops-week3/scripts/week3/backup.sh >> /home/ubuntusever/todo-backups/scheduler.log 2>&1
```

Tạo thư mục sao lưu trước khi đặt lịch. Điểm khôi phục tương ứng bản sao lưu thành công gần nhất; không hứa thời gian khôi phục (RTO) khi chưa đo. Kiểm tra nhật ký chạy theo lịch và diễn tập khôi phục.

`restore.sh ABSOLUTE_ARCHIVE NEW_DATABASE` kiểm tra mã toàn vẹn và chỉ chấp nhận cơ sở dữ liệu mới tên `week3_restore_*`. Script từ chối ghi đè DB hiện có hoặc khôi phục trực tiếp vào production `todo`. Khôi phục bỏ qua chủ sở hữu/quyền ACL nên các đối tượng kiểm chứng thuộc postgres; đây là kiểm chứng khôi phục, chưa phải chuyển đổi production. Khôi phục production thật cần thời gian bảo trì và khôi phục/kiểm tra quyền của vai trò ứng dụng.

`verify-restore.sh` chụp dữ liệu production, khôi phục vào DB cô lập, thêm bản ghi đánh dấu thử nghiệm, sao lưu DB đó, chỉ xóa bản ghi thử và khôi phục vào DB MỚI khác. Số dòng và mã kiểm tra của toàn bộ cột trong bảng công việc phải khớp trước xóa; bản ghi đánh dấu được in ra. Nhật ký ở ngoài Git trong `restore-verification.log`. Giữ DB kiểm chứng làm minh chứng; sau khi rà soát, chỉ xóa đúng tên `week3_restore_*` đã in bằng `docker exec DB_CONTAINER dropdb -U postgres NAME`.

## Hồ sơ nộp và trạng thái thực tế

- Cấu hình JSON và cấp cấu hình bảng điều khiển: `monitoring/`.
- Danh sách kiểm tra bảo mật/cổng: `SECURITY.md`.
- Script và chính sách sao lưu/khôi phục: `scripts/week3/` và tài liệu này.
- Sổ tay xử lý sự cố (3 tình huống): `PLAYBOOK.md`.
- Kịch bản trình diễn trực tuyến: `DEMO_ONLINE.md`.
- Lưu ảnh chụp, chuyển trạng thái cảnh báo, nhật ký khôi phục và nhật ký sự cố thật tại `docs/evidence/week3/` sau khi che thông tin bí mật/địa chỉ riêng tư. Không thay kiểm chứng thực tế bằng đầu ra giả.

Tài liệu tham khảo: [Node Exporter](https://prometheus.io/docs/guides/node-exporter/), [quy tắc cảnh báo Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/), [pg_restore của PostgreSQL 18](https://www.postgresql.org/docs/18/app-pgrestore.html).

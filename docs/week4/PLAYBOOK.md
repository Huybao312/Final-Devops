# Playbook bảo vệ cuối — sự cố có thật hoặc đã thực nghiệm

Quy tắc chung: ghi UTC và phạm vi ảnh hưởng; thu log trước khi sửa; nêu giả thuyết rồi xác minh; sửa nguyên nhân; xác nhận health, dữ liệu và version. Không xóa volume để chữa lỗi kết nối. Các bài phá lỗi chủ động dùng project `todo-week4-rehearsal-*`, không dùng production.

Nginx host production ghi lỗi upstream tại `/var/log/nginx/todo-error.log` (đã đối chiếu file site đang chạy); xem bằng `sudo tail -n 40 /var/log/nginx/todo-error.log`. Proxy container rehearsal có log stdout/stderr qua helper, là hai vị trí khác nhau.

## 1. App stopped → Nginx 502 (đã thực nghiệm)

- **Triệu chứng:** HTTP 502; trong production dashboard health 0 và alert Pending/Firing.
- **Xác minh:** `bash scripts/week4/control-rehearsal.sh "$REHEARSAL" status`, rồi `logs`; proxy log connection refused, app container Exited. Kiểm tra app trực tiếp phân biệt lỗi proxy với app.
- **Nguyên nhân gốc đã tạo:** dừng app container; Nginx còn hoạt động nhưng không có upstream app.
- **Khắc phục:** `bash scripts/week4/control-rehearsal.sh "$REHEARSAL" start-app`.
- **Xác nhận:** `/health` qua proxy 200, `/version` đúng SHA; task vẫn tồn tại; production alert inactive sau phục hồi.
- **Phòng tránh:** healthcheck, restart unless-stopped cho crash/reboot, kiểm tra sau deploy. `docker stop` chủ động không được restart policy tự sửa ngay; không đánh đồng restart policy với self-healing mọi tình huống.
- **Minh chứng:** log rehearsal tuần 4, log/ảnh alert tuần 3.

## 2. DB stopped → app health 503 (đã thực nghiệm)

- **Triệu chứng:** app process vẫn chạy, `/health` 503, log `health database check failed (OperationalError)`.
- **Xác minh:** status/log DB và app; `pg_isready` trong DB nếu container còn chạy. Xem `df -h`, network và quyền truy cập; không in DSN/password. Lỗi auth và DB stopped cần cách sửa khác nhau dù đều có thể là OperationalError.
- **Nguyên nhân gốc đã tạo:** DB container bị dừng, kết nối PostgreSQL không thiết lập được.
- **Khắc phục:** `bash scripts/week4/control-rehearsal.sh "$REHEARSAL" start-db`; giữ nguyên volume và credentials.
- **Xác nhận:** health 200, đọc lại marker task; quyền todo_app không có CREATE TABLE.
- **Phòng tránh:** depends_on healthy cho lần khởi động, connect/query timeout, monitoring DB/app, theo dõi dung lượng. depends_on không tự khắc phục DB hỏng sau startup.

## 3. Proxy sai upstream port → 502 dù nginx -t PASS (đã thực nghiệm)

- **Triệu chứng:** proxy còn chạy; app trực tiếp healthy nhưng qua proxy 502.
- **Xác minh:** so sánh hai đường health, proxy logs và upstream. `nginx -t` chỉ kiểm cú pháp, không xác minh port đó có service.
- **Nguyên nhân gốc đã tạo:** `app:5999` thay cho `app:5000` trong cấu hình proxy thử.
- **Khắc phục:** `bash scripts/week4/control-rehearsal.sh "$REHEARSAL" fix-proxy`; helper phục hồi config, chạy nginx -t và reload.
- **Xác nhận:** đường qua proxy trở lại 200, version khớp, task còn nguyên.
- **Phòng tránh:** smoke test end-to-end qua reverse proxy sau thay đổi; quản lý config trong Git và so sánh với file chạy thật. Không dừng DB để chữa lỗi ở proxy.

## 4. Mất bản ghi / archive chuyển chỗ bị kiểm tra sai (đã thực nghiệm)

- **Triệu chứng:** thiếu task; hoặc checksum cũ báo OK nhưng file copy thực tế đã thay đổi.
- **Xác minh:** phân biệt nhầm DB/filter với xóa thật; băm chính archive được chọn. Test hồi quy dùng bản sao và bản gốc đồng thời tồn tại.
- **Nguyên nhân:** thao tác xóa bản ghi thử; lỗi cũ dùng đường dẫn tuyệt đối từ sidecar để kiểm file gốc thay vì archive sắp restore.
- **Khắc phục:** helper hiện tại băm archive được chọn, đối chiếu digest và từ chối trước createdb nếu sai. `restore.sh` chỉ nhận DB mới có prefix week3_restore_; xác minh dữ liệu trước khi lập kế hoạch cutover thật.
- **Xác nhận:** count + checksum toàn bảng trước xóa bằng sau restore; marker trở lại. Archive bị sửa phải FAIL và không tạo DB.
- **Phòng tránh:** backup ngoài repo, mode 600, lịch backup và restore drills; bản sao ở thiết bị khác cho mất host. Checksum không thay thế chữ ký/xác thực người tạo backup.

## 5. Tunnel báo Address already in use (đã gặp trong quá trình chuẩn bị)

- **Triệu chứng:** bind 13000/19090/18080 thất bại.
- **Xác minh trên Mac:** `lsof -nP -iTCP:13000 -iTCP:19090 -iTCP:18080 -sTCP:LISTEN`; mở URL và curl health. Nếu đúng tiến trình SSH cũ và dịch vụ healthy thì dùng lại.
- **Nguyên nhân:** mở tunnel thứ hai khi tunnel kiểm chứng vẫn giữ ports.
- **Khắc phục:** tái sử dụng tunnel; chỉ đóng tiến trình đã xác minh thuộc phiên của mình khi muốn tạo lại. Không kill tùy tiện tiến trình khác.
- **Xác nhận:** ba URL mở được; app health 200.
- **Phòng tránh:** một bộ ports thống nhất và ExitOnForwardFailure; mở tunnel trước buổi demo, giữ đúng một terminal.

## 6. Dashboard No data, runner token expired — đồng hồ VM sai (11/11/2026)

- **Triệu chứng:** dashboard Last 15 minutes trống dù Prometheus targets đều UP; workflow deploy chờ runner. VM đã chậm khoảng 5 giờ 43 phút so với Mac; chrony báo system time hơn 20.000 giây slow.
- **Xác minh:** so sánh `date -u` trên Mac và Ubuntu; trên Ubuntu chạy `chronyc tracking`, `timedatectl`; kiểm tra `/api/v1/targets` và query `up` ở Prometheus. Đổi timezone không sửa được sai lệch đồng hồ thực tế.
- **Khắc phục trên Ubuntu:** `sudo chronyc makestep`. Đợi vài lần scrape, refresh dashboard Last 15 minutes. CPU dùng rate 2 phút nên cần đủ mẫu mới sau bước chỉnh giờ. Không sửa timestamp dữ liệu cũ để giả lập lịch sử.
- **Runner:** `systemctl status actions.runner.Huybao312-Final-Devops.utm-todo-arm64.service`. Nếu service dừng, restart bằng sudo; nếu log báo registration đã bị xóa, đăng ký lại qua Settings → Actions → Runners bằng token mới, giữ label `todo-vm`, rồi start service. Không ghi token vào repo hoặc evidence.
- **Xác nhận:** đồng hồ khớp; CPU/RAM/health/latency có dữ liệu mới; Active alerts bằng 0 khi không firing; workflow build-test/deploy đều xanh và `/version` khớp commit.
- **Phòng tránh:** đồng bộ giờ trước demo và sau khi VM resume; Ubuntu dùng chrony, lệnh của systemd-timesyncd có thể không áp dụng. VM tạm dừng có thể lệch giờ, NTP đang active chưa chứng minh giờ đã đúng.

## 7. No such file, REHEARSAL rỗng — chạy sai terminal/thư mục

- **Triệu chứng:** `bash: scripts/...: No such file or directory`, hoặc helper báo không phải rehearsal directory.
- **Xác minh:** `hostname`, `pwd`, `printf '%s\n' "$REHEARSAL"`. Terminal Mac không có Docker/socket/firewall của Ubuntu; SSH mới không giữ biến từ phiên trước.
- **Khắc phục:** SSH vào VM, `cd /home/ubuntusever/Final-Devops-week4`, gán REHEARSAL bằng config directory từ dòng cuối của rehearse.sh, rồi `source "$REHEARSAL/runtime.env"` để nạp cổng và cấu hình. Nếu chưa có bản PASS thì chạy rehearse.sh trước.
- **Xác nhận:** status liệt kê container prefix rehearsal; health qua đúng cổng proxy riêng trả 200. Production dùng project todo-task-manager và cổng Nginx 80.
- **Phòng tránh:** ghi nơi chạy trước mỗi nhóm lệnh, giữ cùng phiên SSH trong phần sự cố; không sao chép các từ viết tắt trong bảng như lệnh hoàn chỉnh.

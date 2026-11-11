# Triển khai bản cuối từ Ubuntu sạch

## Phạm vi và điều kiện

Máy Ubuntu 24.04/26.04 64-bit (ARM64 hoặc AMD64), user thường có sudo/SSH, Internet tới apt/GitHub/Docker Hub. Khuyến nghị 2–4 CPU, 4 GB RAM trở lên, 25 GB đĩa trở lên. Đây là server dành riêng cho đồ án; không chạy script cài host trên server đang phục vụ ứng dụng khác. Bản cũ systemd không được cài song song vào cổng 5000.

Fresh Compose deployment được kiểm chứng bằng project/volume/network/secrets mới và ba bài sự cố; host installer có kiểm tra Ubuntu và cấu hình theo tài liệu Docker chính thức. Không coi diễn tập container là bằng chứng đã xóa/cài lại toàn bộ OS production.

## 1. Cài host

Trên Ubuntu mới:

```bash
sudo apt update
sudo apt install -y git
cd ~
git clone https://github.com/Huybao312/Final-Devops.git Final-Devops
cd ~/Final-Devops
# Khi dùng release: git checkout v1.0.0-final
sudo bash scripts/week4/install-host.sh
```

Đăng xuất SSH rồi đăng nhập lại để nhóm docker có hiệu lực. Giữ console VM khi cấu hình firewall. Script cài Docker Engine/Compose từ apt repo chính thức, Nginx và UFW, mở SSH/HTTP, không tạo host PostgreSQL. Nếu Docker packages xung đột, xử lý packages theo lỗi apt; script không tự gỡ dịch vụ hiện có.

## 2. Tạo secrets và deploy

```bash
cd ~/Final-Devops
bash scripts/week4/deploy-clean.sh
bash scripts/week3/start-monitoring.sh
curl -fsS http://127.0.0.1/health
curl -fsS http://127.0.0.1/version
```

Secrets được sinh ngoài repo tại `~/.config/todo/production.env` (600). Không in file này khi screen sharing. Script bảo toàn file đã có; nếu thấy DB volume cũ nhưng thiếu credentials, script từ chối tạo mật khẩu mới để tránh phá kết nối DB. `APP_VERSION` là SHA source được build. Docker Compose tự áp schema/role khi tạo volume rỗng lần đầu.

Trên VM hiện hữu của nhóm, tiếp tục dùng secrets tuần 2. Muốn chuyển vị trí file mà không đổi password: `install -m 600 ~/Final-Devops-week2/.env ~/.config/todo/production.env` sau khi tạo thư mục mode 700. Không chạy init lại DB hay đổi mật khẩu DB khi di chuyển file.

## 3. Runner và GitHub Actions

Repository Settings → Actions → Runners → New self-hosted runner, chọn Linux ARM64 cho UTM (AMD64 cho máy x86). Dùng hướng dẫn và registration token ngắn hạn do GitHub cung cấp; không commit token. Đặt label `todo-vm`, cài runner bằng user thuộc docker group, cài service bằng `sudo ./svc.sh install USER` rồi start. Token này khác SSH key.

Environment `production` và repository secrets cần `DB_ADMIN_PASSWORD`, `DB_APP_PASSWORD` khớp file production trên VM, cùng `CI_DB_PASSWORD` riêng cho DB test. Nhập riêng trong GitHub UI; không paste vào README/video. PR chạy build/test trên GitHub-hosted runner; chỉ main chạy deploy trên self-hosted runner. Người có quyền sửa workflow có thể điều khiển runner, nên repo write permission phải được giới hạn.

## 4. Truy cập online

Từ Mac (thay VM_IP):

```bash
ssh -i ~/.ssh/devops_week2_utm -o ExitOnForwardFailure=yes -N -L 13000:127.0.0.1:3000 -L 19090:127.0.0.1:9090 -L 18080:127.0.0.1:80 ubuntusever@VM_IP
```

Grafana http://localhost:13000/d/todo-week3; Prometheus http://localhost:19090/alerts; app http://localhost:18080. Nếu ports đã dùng, kiểm tra tunnel cũ bằng `lsof -nP -iTCP:13000 -sTCP:LISTEN` và URL; không đổi ports tùy tiện hay tắt tiến trình không rõ nguồn. User Grafana `admin`, mật khẩu nằm trong file riêng `~/.config/todo-week3/monitoring.env`. Không ghi mật khẩu vào hồ sơ public.

## 5. Backup và vận hành

```bash
bash scripts/week3/backup.sh
bash scripts/week3/verify-restore.sh
SINCE=10m bash scripts/week3/app.sh logs
bash scripts/week3/security-audit.sh
```

Cron chỉ chạy khi VM đang bật tại thời điểm lịch; không tự bù lần chạy đã bỏ lỡ khi VM tắt. Backup thủ công trước buổi demo và trước thay đổi dữ liệu quan trọng. Cấu hình cron theo hướng dẫn tuần 3, dùng đường dẫn repo thực tế; tạo `~/todo-backups` trước khi redirect log. Restore được thử trên DB mới, không ghi đè production. Chứng minh khôi phục không đồng nghĩa đã có kế hoạch cutover production tự động: phải xác nhận quyền todo_app, dừng ghi và rà dữ liệu khi sự cố thật.

## 6. Diễn tập độc lập và dọn dẹp

```bash
EVIDENCE_FILE=/tmp/week4-rehearsal.txt bash scripts/week4/rehearse.sh
```

Script chọn hai cổng loopback rảnh, in project `todo-week4-rehearsal-*`, tạo credentials và DB riêng. Chỉ container thử nghiệm bị dừng/sửa proxy. Script giữ project để hỏi đáp, lưu thông số tại CONFIG/runtime.env. Dùng `bash scripts/week4/control-rehearsal.sh CONFIG status` để xem lại, `logs` để tra log, `cleanup` để down đúng project thử. Helper chặn project không có prefix rehearsal và giữ volume. Không dùng helper này cho production. Thư mục config/credentials nằm ngoài repo.


## Giới hạn

Không có public TLS/domain, app authentication/CSRF token, HA hoặc rollback tự động. App giới hạn payload/input, dùng parameterized SQL, proxy loopback, DB least privilege; chưa đủ để coi là dịch vụ Internet multi-user. Backup trên VM và bản sao Mac cùng thiết bị không chịu được mất cả máy Mac. Ảnh cũ phải ghi đúng ngày/SHA; không dùng chúng để tuyên bố trạng thái hiện tại.

Tham khảo: https://docs.docker.com/engine/install/ubuntu/ ; https://docs.github.com/en/actions/hosting-your-own-runners ; https://www.postgresql.org/docs/18/app-pgrestore.html

## Kiểm tra giờ trước demo và khi VM vừa resume

Trên Mac và Ubuntu chạy `date -u` để đối chiếu. Trên Ubuntu chạy `chronyc tracking`; nếu lệch đáng kể, `sudo chronyc makestep`, đợi vài lần scrape rồi refresh Grafana. Đồng hồ sai có thể làm dashboard trống và GitHub runner lỗi token. Host installer bản cuối cài chrony và đồng bộ giờ; máy hiện hữu kiểm tra trước khi tự thay đổi dịch vụ NTP.

## Đường dẫn trên VM đang dùng

Repo chỉnh sửa nằm trên Mac tại `/Users/macos/Final Devops/Final-Devops`. Các lệnh vận hành Linux chạy sau khi SSH vào Ubuntu và `cd /home/ubuntusever/Final-Devops-week4`. Cài mới theo guide dùng `~/Final-Devops`; thay đường dẫn vận hành nếu cài trên máy khác. GitHub Actions checkout trong `_work` là workspace runner tự quản lý; không xóa nó khi job đang chạy. Thư mục config và backup ở ngoài repo để tránh commit secrets/dữ liệu.

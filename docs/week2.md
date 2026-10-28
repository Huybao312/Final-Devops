# Tuần 2 — Docker, dữ liệu bền vững và CI/CD

Tài liệu này mô tả đường đi từ commit trên `main` đến ứng dụng trên Ubuntu VM UTM. Không xem việc có workflow trong repo là bằng chứng đã deploy: cần một workflow run xanh, health check, phiên bản commit và ảnh/video thật.

## Kiến trúc tuần 2

Mac browser → UTM VM `:80` → Nginx của tuần 1 → `127.0.0.1:5000` → Gunicorn/Flask container → network `backend` → PostgreSQL 18 container → named volume `todo-task-manager_postgres_data`.

PostgreSQL không publish port lên host và chỉ nối network nội bộ `backend`. App nối `backend` và `frontend`, chỉ publish `127.0.0.1:5000` (có thể đổi cổng host bằng `APP_BIND_PORT` khi thử cục bộ). Nginx và UFW tuần 1 tiếp tục phục vụ cổng 80. Với image PostgreSQL 18, named volume gắn tại `/var/lib/postgresql`; `db/schema.sql` và `db/init-roles.sh` chỉ khởi tạo khi volume còn trống. `todo_app` chỉ có quyền đọc/ghi bảng; `todo_owner` không đăng nhập.

## 1. Chuẩn bị VM và runner

1. Trên Ubuntu VM, sau khi clone nhánh tuần 2 vào một thư mục riêng, chạy `sudo bash scripts/prepare-week2-vm.sh`. Script lưu bản dump đầy đủ ngoài repo, rồi cài [Docker Engine và Compose plugin](https://docs.docker.com/engine/install/ubuntu/) từ repository chính thức, thêm user vào nhóm `docker`. Đăng xuất/đăng nhập lại để nhận nhóm mới; kiểm tra `docker version` và `docker compose version`. Quyền nhóm `docker` gần tương đương root; chỉ đăng ký runner cho repo tin cậy, giới hạn người có quyền push `main` và review workflow trước khi merge.
2. Trong GitHub repo, mở **Settings → Actions → Runners → New self-hosted runner**. Chọn Linux ARM64, chạy các lệnh GitHub đưa ra trên chính VM. [Đăng ký thêm label `todo-vm`](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/apply-labels) và cài runner làm service. Không commit token đăng ký. Kiểm tra runner hiển thị **Idle**. Máy Mac và VM cần Internet outbound tới GitHub; VM không cần public IP hoặc inbound SSH từ GitHub.
3. Tạo ba chuỗi hex độc lập bằng `openssl rand -hex 24`. Đặt chúng trong GitHub **Settings → Secrets and variables → Actions** với tên `DB_ADMIN_PASSWORD`, `DB_APP_PASSWORD`, `CI_DB_PASSWORD`. Hai secret đầu dùng cho VM và phải khớp `.env` lúc khởi tạo volume; `CI_DB_PASSWORD` chỉ dùng cho PostgreSQL tạm trên GitHub-hosted runner. Không đổi hai secret VM sau lần khởi tạo DB nếu chưa đổi password tương ứng trong PostgreSQL. Các giá trị phải là chuỗi URL-safe.
4. Tạo GitHub environment tên `production`. Nếu muốn duyệt trước mỗi deploy, cấu hình required reviewers; để demo tự động từ push, không đặt approval gate. Workflow deploy chỉ chạy sau job `build-test` thành công.

## 2. Chuyển dữ liệu từ PostgreSQL tuần 1

Chạy trên VM với source mới tại `/opt/todo-task-manager`. **Không xóa database/volume cũ và không dùng `docker compose down -v`.** Kiểm tra `sudo systemctl status flaskapp postgresql nginx` và giữ một bản backup nằm ngoài repo. Dừng app cũ trước bản dump cuối để không có ghi mới trong lúc chuyển dữ liệu; Nginx sẽ tạm trả 502 trong khoảng cắt dịch vụ.

```bash
cd /opt/todo-task-manager
sudo systemctl stop flaskapp
sudo -u postgres pg_dump --data-only --no-owner --no-privileges -d todo > "$HOME/todo-week1-data.sql"
chmod 600 "$HOME/todo-week1-data.sql"
sudo -u postgres psql -d todo -tAc 'SELECT count(*) FROM public.tasks;'

cp deploy/compose.env.example .env
chmod 600 .env
# Sửa .env: dùng CHÍNH HAI giá trị đã đặt trong GitHub Secrets.
# Không lưu mật khẩu vào history hoặc screenshot.
docker compose up -d --wait db
docker compose exec -T db psql -U postgres -d todo < "$HOME/todo-week1-data.sql"
docker compose exec -T db psql -U postgres -d todo -tAc 'SELECT count(*) FROM public.tasks;'
```

Hai số hàng phải khớp. Nếu DB tuần 1 không có bản ghi, vẫn giữ backup và kiểm tra schema/role. Nếu import báo lỗi, dừng ở đây và xử lý; `sudo systemctl start flaskapp` để khôi phục dịch vụ cũ. Việc import chỉ chạy **một lần** vào volume mới.

Sau khi xác nhận dữ liệu, chuyển cổng 5000 từ systemd sang container:

```bash
sudo systemctl disable flaskapp
docker compose up -d --build --wait
curl -fsS http://127.0.0.1/health
curl -fsS http://127.0.0.1/version
docker compose ps
```

Nginx vẫn proxy tới loopback `:5000`. Nếu health fail, xem `docker compose logs --tail=100 app db`, sửa nguyên nhân rồi `docker compose up -d --wait`. Có thể bật lại `flaskapp` sau khi `docker compose stop app` để quay về bản tuần 1, nhưng dữ liệu mới trong container sẽ không tự đồng bộ về DB cũ.

## 3. Pipeline và deploy tự động

`.github/workflows/week2.yml` chạy khi mở pull request vào `main`, push `main` hoặc bấm `workflow_dispatch`. Pull request chỉ chạy kiểm tra; deploy dành cho `main`:

1. GitHub-hosted runner checkout source, build image, dựng PostgreSQL test, chạy `pytest` CRUD và `/health`. Test fail thì job deploy không chạy.
2. Self-hosted runner trên VM checkout **đúng commit**, build image ARM64, `docker compose up -d --wait`, rồi xác nhận `/version` khớp SHA và `/health` healthy. `APP_VERSION` nằm trong image.

Đưa code lên một branch để review và chạy kiểm tra trước. Khi đã hoàn tất chuyển dữ liệu và runner/secrets sẵn sàng, merge/push vào `main` sẽ tự chạy deploy. Có thể dùng `workflow_dispatch` để chạy lại. Branch protection nên yêu cầu job `build-test` xanh trước khi merge. Workflow không dùng `scripts/deploy.sh` của tuần 1.

## 4. Minh chứng bắt buộc

Trên VM, export hai biến bằng cách đọc `.env` trong shell hiện tại (`set -a; . ./.env; set +a`) rồi chạy:

```bash
bash scripts/verify-week2.sh | tee docs/evidence/week2-persistence.txt
docker compose ps
curl -fsS http://127.0.0.1/version
curl -fsS http://127.0.0.1/health
```

Script tạo một task thật, `docker compose down` rồi `up` (không `-v`), kiểm tra cùng task trong DB và UI. Không chạy trong lúc có người đang dùng app vì có downtime ngắn. Sau đó push một thay đổi nhỏ trên `main`, lưu link workflow run và ảnh/video `before → run xanh → after`, cùng SHA từ `/version`. Không ghi log giả hoặc dùng ảnh cũ. Minh chứng test fail: tạo một branch thử nghiệm với assertion sai, cho thấy job đỏ và deploy bị skip; không merge branch đó.

## 5. Lỗi thường gặp

- `port is already allocated`: `flaskapp` tuần 1 vẫn chiếm `127.0.0.1:5000`; kiểm tra `ss -lntp`, thực hiện cutover đúng thứ tự.
- `password authentication failed`: secret GitHub khác `.env` dùng khi khởi tạo volume; sửa secret về giá trị gốc hoặc đổi password trong DB một cách có kiểm soát.
- Runner offline/job queued: kiểm tra service runner trên VM, nhãn `todo-vm`, mạng outbound và `docker compose version`.
- Nginx 502: kiểm tra `docker compose ps`, `docker compose logs app db`, rồi gọi trực tiếp `http://127.0.0.1:5000/health`.

# Tuần 3 — Bảo mật và các cổng mạng

Ghi kết quả đạt/không đạt và ngày theo UTC trên máy ảo thực tế; chỉ đọc cấu hình chưa phải minh chứng vận hành.

| Hạng mục | Kết quả mong đợi | Kết quả kiểm tra thực tế |
|---|---|---|
| SSH 22 | Phục vụ quản trị; đăng nhập bằng khóa | ĐẠT 2026-11-04 |
| Nginx 80 | Cổng vào ứng dụng trên mạng LAN của máy ảo | ĐẠT 2026-11-04 |
| Ứng dụng 5000 | Chỉ nghe tại 127.0.0.1 | ĐẠT 2026-11-04 |
| PostgreSQL 5432 | Container không công bố cổng ra máy chủ; dùng mạng backend nội bộ | ĐẠT 2026-11-04 |
| Grafana 3000 | 127.0.0.1; truy cập qua đường hầm SSH và đăng nhập | ĐẠT 2026-11-04 |
| Prometheus 9090, bộ xuất số liệu 9100/9115 | Chỉ nghe tại 127.0.0.1 | ĐẠT 2026-11-04 |
| UFW | Chặn kết nối vào; chỉ cho phép SSH/HTTP | ĐẠT — kiểm tra tại console bởi chủ máy, chỉ 22/80 |
| Vai trò DB todo_app | Chỉ thao tác dữ liệu; không có quyền siêu quản trị/tạo cấu trúc/tạo vai trò | ĐẠT 2026-11-04 |
| Thông tin bí mật | Ngoài Git; tệp quyền 600; chỉ chủ sở hữu truy cập | ĐẠT 2026-11-04 |
| Nhật ký Docker | Luân chuyển tệp; không in mật khẩu | ĐẠT — kiểm tra cấu hình 10m × 3 và rà soát nhật ký sự cố |

Chạy `bash scripts/week3/security-audit.sh`. Script `sudo bash scripts/setup-firewall.sh` hiện có bật chính sách chặn kết nối vào và cho phép SSH/HTTP. Kiểm tra quy tắc UFW hiện tại trước: script không xóa các quy tắc cho phép cũ. Sau khi rà soát, xóa riêng các quy tắc không cần thiết. Giữ kết nối SSH và console UTM mở khi thay đổi tường lửa. Việc công bố cổng Docker có thể đi vòng qua UFW; chỉ nghe tại địa chỉ nội bộ (loopback) và không công bố cổng DB là các lớp kiểm soát độc lập cần thiết.

Mật khẩu hệ thống đang phục vụ nằm trong GitHub Actions secrets và tệp biến môi trường của máy ảo; Grafana tạo thông tin đăng nhập riêng ngoài kho mã. Ứng dụng dùng `todo_app`; quyền quản trị PostgreSQL dành cho sao lưu/khôi phục và quản trị. Nhóm Docker có quyền thực tế tương đương root, không phải vai trò người dùng bị giới hạn. Chỉ tài khoản triển khai tin cậy được tham gia nhóm này. Runner GitHub chạy quy trình của kho mã: giới hạn quyền ghi kho mã và quyền truy cập môi trường production; không chạy mã từ bản fork không tin cậy trên runner đó.

Dịch vụ PostgreSQL cài trực tiếp từ tuần 1 có thể còn để quay lại phiên bản cũ. Kiểm tra cả cổng của dịch vụ này bằng `ss -lnt`; xác nhận chỉ nghe loopback, hoặc chỉ dừng sau khi có bản sao lưu đã kiểm thử và quyết định rõ về phương án quay lại. Không nhầm dịch vụ này với cơ sở dữ liệu trong container.

`.env` và tệp sao lưu được bỏ qua, nhưng quy tắc bỏ qua không xóa thông tin bí mật trong lịch sử Git. Rà soát lịch sử trước khi nộp công khai; thay thông tin đăng nhập nếu đã bị lộ. Không hiển thị `.env`, phần biến môi trường của `docker inspect` hoặc `docker compose config` (không có `-q`) khi chia sẻ màn hình.

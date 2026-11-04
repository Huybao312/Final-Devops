# Sổ tay xử lý sự cố

## 1. Ứng dụng ngừng hoạt động / Nginx trả lỗi 502

**Phát hiện:** Grafana hiển thị health = 0; cảnh báo `TodoAppUnavailable` ở trạng thái Firing (đang cảnh báo). Ghi thời điểm bắt đầu theo UTC bằng `date -u`.

**Chẩn đoán:** dùng `bash scripts/week3/app.sh status`, `SINCE=10m bash scripts/week3/app.sh logs`, `curl -i http://127.0.0.1/health`, `sudo journalctl -u nginx --since '10 min ago' --no-pager`. Xác định ứng dụng đã dừng, không khỏe hay không kết nối được cơ sở dữ liệu. Tiến trình đã dừng có thể chỉ còn nhật ký vòng đời; xem nhật ký lỗi kết nối dịch vụ phía sau của Nginx (`sudo tail -n 40 /var/log/nginx/error.log`) để tìm yêu cầu thất bại.

**Khôi phục:** chạy `bash scripts/week3/app.sh start` nếu ứng dụng đã dừng. Không tùy tiện xây dựng lại hoặc gắn nhãn mã nguồn trong lúc khôi phục. Nếu lỗi cấu hình/mã nguồn, sửa nguyên nhân và dùng quy trình triển khai đã kiểm thử.

**Xác nhận:** `/health` trả 200, `/version` trả mã SHA mong đợi, Grafana health = 1 và cảnh báo không còn hoạt động. Ghi thời gian khôi phục và nguyên nhân.

## 2. Ứng dụng không kết nối được cơ sở dữ liệu

**Phát hiện:** `/health` trả 503, yêu cầu tới ứng dụng thất bại dù tiến trình vẫn chạy.

**Chẩn đoán:** kiểm tra trạng thái/nhật ký cơ sở dữ liệu, `docker exec DB_CONTAINER pg_isready -U postgres -d todo`, dung lượng đĩa bằng `df -h`, mạng nội bộ và thông tin đăng nhập (kiểm tra riêng tư). Phân biệt lỗi mạng/xác thực với cơ sở dữ liệu bị dừng hoặc đầy đĩa. Không in mật khẩu trong minh chứng sự cố.

**Khôi phục:** khởi động container cơ sở dữ liệu hiện có nếu bị dừng; sửa đúng lỗi đĩa/mạng/xác thực. Không xóa volume có tên hoặc khởi tạo cơ sở dữ liệu rỗng thay thế để xử lý tắt.

**Xác nhận:** truy vấn SQL đọc được dữ liệu, `/health` trả 200 và đọc được một công việc đã tồn tại. Không mô phỏng lỗi này trên hệ thống đang phục vụ chỉ để bổ sung ảnh chụp.

## 3. Công việc bị xóa / cần khôi phục dữ liệu

**Phát hiện:** thiếu bản ghi; ghi thời điểm, phạm vi và bản sao lưu thành công gần nhất.

**Chẩn đoán:** phân biệt xóa nhầm với chọn sai cơ sở dữ liệu/bộ lọc. Kiểm tra mã kiểm tra toàn vẹn của tệp sao lưu và dùng `restore.sh` khôi phục vào cơ sở dữ liệu cô lập MỚI. Truy vấn bản ghi bị thiếu.

**Khôi phục:** chạy `verify-restore.sh` cho bài thử checkpoint; script chỉ sửa dữ liệu thử nghiệm trong cơ sở dữ liệu cô lập. Với sự cố thật, kiểm tra các dòng đã khôi phục và lập phương án khôi phục chọn lọc được rà soát hoặc chuyển đổi trong thời gian bảo trì; không ghi đè dữ liệu hiện tại một cách mù quáng.

**Xác nhận:** so sánh số dòng, mã kiểm tra dữ liệu và các bản ghi cần thiết; giữ tệp sao lưu và nhật ký khôi phục. Không thể lấy lại thay đổi mới hơn bản sao lưu bằng quy trình này. Ghi khoảng thời gian có thể mất dữ liệu, nguyên nhân và cách phòng tránh.

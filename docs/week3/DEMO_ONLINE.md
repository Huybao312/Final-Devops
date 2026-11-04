# Kịch bản trình diễn trực tuyến tuần 3 — 8–10 phút

## Chuẩn bị trước giờ chia sẻ màn hình

Cửa sổ dòng lệnh Mac 1 — giữ đường hầm SSH mở (thay `VM_IP` bằng IP hiện tại của VM):

```bash
ssh -i ~/.ssh/devops_week2_utm -o ExitOnForwardFailure=yes -N -L 13000:127.0.0.1:3000 -L 19090:127.0.0.1:9090 -L 18080:127.0.0.1:80 ubuntusever@VM_IP
```

Cửa sổ dòng lệnh Mac 2 — đăng nhập VM rồi chuẩn bị trước khi chia sẻ màn hình:

```bash
ssh -i ~/.ssh/devops_week2_utm ubuntusever@VM_IP
cd ~/Final-Devops-week3
sudo -v
```

Grafana dùng tài khoản `admin`, mật khẩu đã cấu hình trong tệp riêng trên VM. Đọc mật khẩu và đăng nhập trước khi chia sẻ màn hình. Nếu đường hầm báo cổng đã được dùng, thử các URL bên dưới và dùng lại đường hầm cũ nếu đã truy cập được.

- VM phải đang bật; Docker, Nginx, hệ thống giám sát đã chạy. Không để Mac/VM ngủ khi demo.
- Cửa sổ dòng lệnh máy ảo ở `~/Final-Devops-week3`, một cửa sổ dòng lệnh Mac giữ đường hầm SSH theo README.
- Mở http://localhost:13000/d/todo-week3, http://localhost:19090/alerts và http://localhost:18080.
- Đăng nhập Grafana trước; đóng cửa sổ chứa mật khẩu. Chỉ chia sẻ cửa sổ trình duyệt/dòng lệnh trình diễn.
- Đã chạy thử `verify-restore.sh`; lưu ảnh/nhật ký kết quả thật làm dự phòng. Không nói PASS nếu chưa chạy.

## 1. Bảng điều khiển — 1 phút

**Nói:** “Tuần 3 em bổ sung giám sát trên VM. Bảng điều khiển thể hiện CPU, RAM, health và độ trễ. Trạng thái sức khỏe được kiểm tra qua Nginx tới ứng dụng; điểm truy cập còn kiểm tra kết nối PostgreSQL.”

Mở bảng điều khiển, chọn Last 15 minutes (15 phút gần nhất). Chỉ vào CPU, RAM và health = 1. Nếu CPU chưa có dữ liệu, chờ khoảng 2 phút từ lúc hệ thống giám sát khởi động.

## 2. Cảnh báo, nhật ký và phục hồi — 2–3 phút

**Nói trước lệnh:** “Em sẽ dừng riêng ứng dụng để tạo lỗi thật. Cơ sở dữ liệu vẫn chạy. Script chờ cảnh báo ở trạng thái FIRING rồi khởi động lại ứng dụng; có cơ chế phục hồi khi script kết thúc.”

Trên cửa sổ dòng lệnh máy ảo:

```bash
cd ~/Final-Devops-week3
bash scripts/week3/demo-alert.sh
```

Trong lúc đợi, chuyển trình duyệt sang Alerts (cảnh báo). **Nói:** “Bộ thăm dò phát hiện lỗi, quy tắc chờ 30 giây để tránh báo động do lỗi thoáng qua. Trạng thái đi từ Pending (chờ xác nhận) sang Firing (đang cảnh báo); đây là cảnh báo đã được kiểm thử.”

Chụp ảnh khi Firing; quay lại cửa sổ dòng lệnh xem nhật ký. **Nói:** “Em tra nhật ký theo khoảng thời gian xảy ra sự cố. Ứng dụng đã được khởi động lại; health trở về 1 và cảnh báo được xóa sau lần đánh giá tiếp theo.”

Nếu cần xem lại nhật ký trong cửa sổ thời gian:

```bash
SINCE=5m bash scripts/week3/app.sh logs
```

**Nói:** “Lệnh lọc nhật ký ứng dụng/cơ sở dữ liệu trong 5 phút gần nhất, kèm dấu thời gian. Em không cần đọc toàn bộ nhật ký từ lúc hệ thống được cài.”

## 3. Bảo mật — 1 phút

**Nói trước lệnh:** “Em kiểm tra cổng, tường lửa, quyền cơ sở dữ liệu và quyền tệp bí mật. Nội dung mật khẩu không được đưa lên màn hình.”

```bash
bash scripts/week3/security-audit.sh
```

**Nói sau kết quả:** “Nginx là cổng vào ứng dụng. Ứng dụng và hệ thống giám sát chỉ lắng nghe tại địa chỉ nội bộ (loopback); PostgreSQL không công bố cổng ra máy chủ. Bảng điều khiển được mở qua đường hầm SSH. Tài khoản ứng dụng có quyền thao tác dữ liệu, không có quyền siêu quản trị hay tạo vai trò. Nhóm Docker là quyền quản trị mạnh nên chỉ cấp cho tài khoản triển khai tin cậy.”

Chỉ nói các kết luận trên nếu kết quả thật khớp danh sách kiểm tra; giải thích và sửa nếu phát hiện cổng thừa.

## 4. Sao lưu → xóa dữ liệu thử → khôi phục — 2–3 phút

**Nói trước lệnh:** “Em sao lưu hệ thống đang phục vụ rồi khôi phục vào cơ sở dữ liệu kiểm chứng riêng. Tại cơ sở dữ liệu kiểm chứng em tạo một bản ghi thử, sao lưu, xóa bản ghi và khôi phục lại. Cách này chứng minh khả năng khôi phục mà vẫn bảo vệ dữ liệu hiện tại.”

```bash
bash scripts/week3/verify-restore.sh
```

Chỉ vào ba dòng `Before deletion`, `After deletion`, `After restore` và bản ghi đánh dấu thử nghiệm.

**Nói:** “Sau khi xóa, số dòng/mã kiểm tra thay đổi. Sau khôi phục, cả số dòng và mã kiểm tra của toàn bộ bảng khớp bản trước khi xóa; bản ghi thử đã trở lại. Sao lưu được lưu ngoài kho mã, tệp chỉ chủ sở hữu đọc được, có mã kiểm tra và giữ 14 ngày.”

Không chỉ nhìn dòng PASS: chỉ ra bản ghi đánh dấu thử nghiệm và giá trị số dòng/mã kiểm tra thật. Cơ sở dữ liệu kiểm chứng còn lại để kiểm tra sau buổi demo.

## 5. Kết thúc — 30 giây

**Nói:** “Em có ba hướng dẫn xử lý sự cố: ứng dụng không phản hồi, mất kết nối cơ sở dữ liệu và khôi phục dữ liệu. Mỗi hướng dẫn có phát hiện, chẩn đoán, phục hồi và bước xác nhận. Sao lưu trên cùng VM chưa bảo vệ khi mất ổ VM; cần thêm bản sao ở thiết bị khác cho tình huống đó.”

Mở `docs/week3/PLAYBOOK.md`, cho xem ba mục. Kết thúc bằng bảng điều khiển health = 1 và ứng dụng hoạt động.

## Dự phòng khi mạng/VM lỗi

Chiếu ảnh/video/nhật ký của lần chạy thật gần nhất; nói rõ đó là bản ghi trước, không mô tả là trình diễn trực tiếp. Nếu ứng dụng chưa phục hồi: `bash scripts/week3/app.sh start`, sau đó kiểm tra `curl -fsS http://127.0.0.1/health`. Không xóa vùng lưu trữ, không khôi phục đè hệ thống đang phục vụ trong lúc trình bày.

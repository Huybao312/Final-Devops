# Câu hỏi bảo vệ — trả lời ngắn, có bằng chứng

| Câu hỏi | Ý trả lời và thứ nên chỉ ra |
|---|---|
| Vì sao không dùng cloud/Kubernetes? | Đề cho VM và không chấm độ phức tạp nghiệp vụ. Compose đủ một VM; cloud/Kubernetes không tự tạo ra backup hay kỹ năng troubleshooting. Chỉ rõ giới hạn điểm lỗi đơn. |
| Image, container, volume khác gì? | Image là gói build; container là tiến trình từ image; volume giữ DB ngoài vòng đời container. Chỉ marker còn sau recreation. |
| depends_on có tự cứu DB không? | Điều kiện healthy hỗ trợ startup; không sửa DB crash sau đó. Script đã thực nghiệm DB stopped và app health 503. |
| /version chứng minh điều gì? | SHA được đưa vào image giúp nối commit/run/app trong pipeline tin cậy. Không chứng minh OS/dependency ngoài image giống nhau, và không nên gắn SHA cũ cho source build khác. |
| Pipeline test DB thật chưa? | Pytest dùng PostgreSQL service riêng. Rehearsal còn dùng role todo_app qua app container và kiểm CREATE TABLE bị từ chối. Không chạy test ghi/xóa trên production. |
| Vì sao nginx -t PASS mà vẫn 502? | Syntax đúng nhưng upstream app:5999 không có service. So sánh app trực tiếp, proxy path và logs; sửa port rồi smoke test. |
| 502 khác 503? | Trong thí nghiệm này 502 do proxy không kết nối upstream, 503 do app báo DB unhealthy. Không coi mã HTTP là nguyên nhân cuối cùng của mọi hệ thống. |
| Giám sát CPU/RAM ở đâu? | Node Exporter chạy trên host namespace và rootfs VM; dữ liệu là Linux VM. Docker Desktop local và máy Mac là phạm vi khác. |
| Cảnh báo có email chưa? | Có rule/state đã thử Pending/Firing/Inactive; chưa tuyên bố notification email. Đề cho notification/state; nếu cần thông báo người trực phải cấu hình receiver và thử delivery riêng. |
| Vì sao không chỉ dùng firewall? | Docker published ports có thể vượt cơ chế UFW thông thường. Loopback binding, DB không publish và internal network là các ranh giới bổ sung. |
| User trong Docker group có ít quyền không? | Không. Truy cập Docker daemon có hiệu lực quản trị mạnh; chỉ cấp cho user/runner tin cậy, không dùng để chạy PR lạ trên self-hosted runner. |
| Vì sao restore vào DB mới? | Kiểm chứng khả năng phục hồi mà không xóa dữ liệu đang dùng. Khôi phục production thật cần dừng ghi, rà quyền, đối chiếu dữ liệu và quyết định cutover có kiểm soát. |
| Checksum có chống được kẻ sửa cả file và hash không? | Không. Nó phát hiện sai khác với digest tin cậy, không xác thực nguồn. Mã hiện tại băm đúng file được chọn và có regression cho lỗi đường dẫn cũ. |
| Có thể mất bao nhiêu dữ liệu? | Archive chỉ có dữ liệu đến lần backup đó. Chưa đo/đảm bảo RPO/RTO chính thức; cron bỏ lỡ khi VM tắt, backup cùng Mac không chịu mất toàn bộ host. |
| Có thể public app ngay không? | Chưa. App demo chưa có auth/CSRF token/public TLS/HA; các biện pháp hiện có không thay thế yêu cầu Internet multi-user. |
| Mỗi người đã tự làm gì? | Trình bày phần việc thật, review/chạy lại và chứng cứ của chính mình. Không chuyển attribution hoặc nói tự viết code hỗ trợ bởi agent để tạo đóng góp giả. |

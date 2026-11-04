# Trạng thái kiểm chứng — 2026-11-04

## Các kiểm tra đã đạt trên máy ảo Ubuntu

- Bốn container giám sát đã chạy; bảng điều khiển Grafana được cấp cấu hình sẵn và kiểm tra trực quan với số liệu CPU/RAM/health.
- Sự cố dừng ứng dụng thực tế: `TodoAppUnavailable` chuyển sang FIRING lúc 04:09:50 UTC; ứng dụng phục hồi và cảnh báo hết lúc 04:10:21 UTC. Một lần thử độc lập trước đó cũng đạt.
- Bản chụp dữ liệu production được khôi phục vào cơ sở dữ liệu cô lập; thêm bản ghi đánh dấu thử nghiệm, sao lưu, xóa và khôi phục vào cơ sở dữ liệu cô lập thứ hai. Trước xóa: 6 dòng; sau xóa: 5; sau khôi phục: 6. Mã kiểm tra toàn bộ dữ liệu công việc trước/sau khôi phục: `8cc09cee92455447381358e714d084ac`.
- Production vẫn có 5 bản ghi công việc. Bài thử xóa dữ liệu chỉ thay đổi cơ sở dữ liệu cô lập.
- Tệp bí mật có quyền 600; thư mục sao lưu quyền 700. Vai trò ứng dụng chỉ được cấp quyền thao tác dữ liệu, không có quyền siêu quản trị/tạo vai trò/tạo cơ sở dữ liệu.
- Ứng dụng và dịch vụ giám sát chỉ nghe loopback. Container DB không công bố cổng ra máy chủ; PostgreSQL cũ tuần 1 nghe loopback tại 5432.
- Đã thêm lịch sao lưu hằng ngày lúc 02:00 UTC vào crontab của người dùng máy ảo, giữ nguyên các mục cũ. Chưa quan sát lần chạy theo lịch; sao lưu và khôi phục thủ công đã đạt.
- Các bài kiểm tra cấu hình/quy tắc cảnh báo trên GitHub và kiểm thử tích hợp ứng dụng với PostgreSQL thật đã đạt.

## Kiểm chứng bảo mật và triển khai cuối

- Chủ máy chạy thiết lập tường lửa bằng sudo tại console máy ảo: UFW hoạt động, chặn kết nối vào, chỉ cho phép 22/80 cho IPv4/IPv6. Kết quả lưu tại `firewall-console.txt`, có ghi nguồn.
- Kiểm tra cổng từ máy Mac: truy cập được 22/80; không truy cập được 5000/5432/3000/9090/9100/9115.
- Tuần 3 được hợp nhất qua PR #4; quy trình trên main triển khai commit `1262dd141a4aeea7ff2ae5bf1226963e37948b07`. Health khỏe và production vẫn có 5 bản ghi.
- Kiểm tra cả ứng dụng/DB xác nhận nhật ký `json-file` với `max-size=10m` và `max-file=3`.
- [Lần chạy quy trình triển khai ban đầu](https://github.com/Huybao312/Final-Devops/actions/runs/41771790899).

Các chức năng của checkpoint đều có minh chứng vận hành. Lần sao lưu tự động đầu tiên vẫn cần kiểm tra sau; sao lưu/khôi phục thủ công đã đạt. Không tạo video giả: cung cấp ảnh và nhật ký thực tế theo hình thức thay thế được chấp nhận.

Minh chứng: `docs/evidence/week3/`. Ảnh chụp và tệp văn bản/JSON là kết quả thực tế, không phải đầu ra minh họa. Không đưa tệp sao lưu cơ sở dữ liệu hoặc thông tin bí mật vào commit.

## Các chỉnh sửa sau rà soát — 2026-11-04

- Tệp mã kiểm tra đi kèm dùng tên tệp thay vì đường dẫn tuyệt đối để dễ di chuyển. Khi khôi phục, kiểm tra đúng nội dung tệp sao lưu được chọn, kể cả tệp mã kiểm tra cũ dùng đường dẫn tuyệt đối. Đã thử khôi phục sau khi di chuyển/đổi tên; bản sao hỏng bị từ chối trước khi tạo DB dù bản gốc vẫn tồn tại. Kiểm thử hồi quy nằm trong CI.
- Cả bốn container giám sát đã được kiểm chứng luân chuyển nhật ký `json-file` (10m × 3), thống nhất với ứng dụng/DB.
- Cổng thống nhất trên Mac: 13000 Grafana / 19090 Prometheus / 18080 ứng dụng. Hướng dẫn trong kho mã và kịch bản ở Downloads dùng cùng ánh xạ. Cổng dịch vụ nội bộ máy ảo không đổi.
- Lần chạy cron sao lưu đầu tiên và sao chép bản sao lưu đã mã hóa sang thiết bị riêng vẫn là việc cần theo dõi; chưa tuyên bố đã kiểm thử.
- Minh chứng: `hardening-verification.txt`.

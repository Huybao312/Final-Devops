# Kịch bản video tổng kết — khoảng 6–7 phút

Đây là lời thoại để thành viên tự thu. Có thể quay mỗi người một đoạn rồi ghép, giữ nguyên nhãn người nói. Không đọc password, token hay IP VM. Dùng cửa sổ app qua localhost và crop dữ liệu cá nhân trong trình duyệt. Lời thoại mô tả bằng chứng thật; nếu dùng ảnh/log đã ghi, nói rõ “trong lần kiểm chứng này”.

## 00:00–00:45 · Tùng · giới thiệu

“Chào thầy và các bạn. Đây là đồ án DevOps của nhóm em với ứng dụng Todo Task Manager. Nhóm giữ chức năng ứng dụng vừa đủ: tạo, sửa, hoàn thành và xóa công việc. Trọng tâm là đưa một thay đổi mã nguồn qua kiểm thử và triển khai, biết hệ thống có khỏe không, và khôi phục được khi có lỗi. Video này đi qua kiến trúc, pipeline, monitoring, backup và một số tình huống xử lý sự cố đã kiểm chứng.”

**Hình:** app + sơ đồ final. **Chuyển:** “Em xin giới thiệu ngắn đường đi của request trước.”

## 00:45–01:35 · Tùng · kiến trúc

“Trình duyệt đi qua Nginx trên VM rồi tới app container ở loopback. App đọc và ghi PostgreSQL qua network nội bộ. Database không publish cổng ra host, còn dữ liệu nằm trong named volume. Monitoring chạy trong project riêng. Từ Mac, nhóm truy cập Grafana, Prometheus và app qua ba cổng SSH tunnel đã thống nhất. Mô hình này phù hợp phạm vi một VM; nhóm không tuyên bố có high availability hay dịch vụ Internet nhiều người dùng.”

**Hình:** chỉ lần lượt Nginx → app → DB → volume; bảng cổng không hiện IP riêng tư.

## 01:35–02:30 · Huy Bảo · code đến deploy

“Với thay đổi mới, em mở pull request để chạy build và test trên GitHub-hosted runner. Database trong test là PostgreSQL thật, tách khỏi production. Test xác nhận CRUD, health, bộ đếm và việc từ chối đầu vào lỗi. Khi merge main, job deploy mới chạy trên runner trong VM. Image được build với SHA commit. Sau deploy, em gọi API version và so sánh với main, rồi refresh giao diện để xác nhận thay đổi nhìn thấy được. Hai bước này giúp tránh nhầm một run cũ xanh với phiên bản thực sự đang phục vụ.”

**Hình:** diff → PR checks → run main xanh → version SHA khớp → app mới. Nếu quay live mất thời gian, cắt đoạn chờ và ghi rõ đã rút gọn thời gian chờ; không tạo output giả.

## 02:30–03:20 · Tuấn Bảo · monitoring và security

“Dashboard hiển thị CPU, RAM, health và độ trễ. Health được probe qua Nginx và app có kiểm tra DB, nên không chỉ phản ánh việc container còn chạy. Khi dừng app trong lần thử, rule chờ lỗi liên tục ba mươi giây rồi chuyển Firing. Sau khi app phục hồi, health trở lại một và cảnh báo hết. Logs có timestamp và lọc theo thời gian; tất cả container có giới hạn dung lượng log. Firewall chỉ cho SSH và HTTP; secrets ở file riêng và GitHub secrets, còn user DB của app không có quyền tạo table hay role.”

**Hình:** dashboard thật, ảnh Firing/Recovered và checklist bảo mật. Không mở .env hoặc docker inspect environment.

## 03:20–04:15 · Tuấn Bảo · backup/restore

“Volume persistence và backup là hai việc khác nhau. Nhóm backup DB bằng pg_dump, lưu archive ngoài repo cùng SHA-256 và giữ bản theo chính sách. Để kiểm chứng restore an toàn, script làm việc trên database riêng: tạo một marker thử, backup, xóa marker rồi restore sang DB mới. Trong lần thử Ubuntu, count đi từ hai xuống một rồi trở lại hai; checksum trước và sau restore khớp, marker xuất hiện lại. Production không bị dùng để xóa dữ liệu. Script cũng từ chối archive bị sửa và không restore đè vào DB production.”

**Hình:** log 2→1→2 và checksum; không quay nội dung bản dump.

## 04:15–05:15 · cả nhóm · troubleshooting

“Nhóm diễn tập ba lỗi trên project riêng. Khi app dừng, proxy trả 502; khi DB dừng, app còn process nhưng health trả 503. Trường hợp thứ ba là proxy sai port: nginx kiểm cú pháp vẫn báo thành công, nhưng request thật trả 502. Vì thế, nhìn trạng thái Running hoặc chỉ chạy nginx -t là chưa đủ. Chúng em so sánh đường qua proxy với app trực tiếp, đọc logs, xác định nguyên nhân rồi sửa đúng thành phần. Sau mỗi lần phục hồi phải kiểm tra health, version và task marker, không dừng ở một lệnh restart đã chạy xong.”

**Hình:** ba đoạn log triệu chứng → nguyên nhân → phục hồi; một thành viên thao tác, người khác giải thích giả thuyết và xác nhận.

## 05:15–06:00 · Tùng · kết luận và giới hạn

“Bản cuối có hướng dẫn triển khai, sơ đồ, release, báo cáo và playbook để người khác có thể kiểm tra lại. Các kết quả trong video là kết quả thực nghiệm có log và source cụ thể, không phải cam kết hệ thống không bao giờ lỗi. Giới hạn hiện tại là một VM, chưa có public TLS, đăng nhập app hoặc HA; backup cùng máy Mac chưa bảo vệ khi mất toàn bộ host. Nhóm chuẩn bị phần bảo vệ trực tiếp để giải thích các giới hạn đó và xử lý tình huống tương tự do thầy lựa chọn. Cảm ơn thầy và các bạn đã theo dõi.”

**Hình:** release + danh sách hồ sơ + app healthy. Trước nộp: nghe lại giọng, kiểm tra thời lượng 5–10 phút, nội dung khớp người phụ trách và không lộ secrets.

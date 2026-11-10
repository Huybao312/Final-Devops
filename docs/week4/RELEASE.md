# Release v1.0.0-final

Release tích hợp đồ án DevOps tuần 1–4. Tag trỏ vào commit main đã qua build-test, independent rehearsal và deployment; SHA cụ thể được ghi trong manifest của release. Endpoint /version phải khớp SHA được deploy. Thay đổi demo sau này tạo SHA mới; release tag cũ vẫn giữ ý nghĩa snapshot của thời điểm phát hành.

## Nội dung

- Flask CRUD/counter, health/version, validation phía server và DB timeouts.
- Docker Compose app/DB với role hạn chế, internal network, persistent volume, log rotation.
- Nginx host/UFW; GitHub-hosted CI và self-hosted deployment runner.
- Monitoring CPU/RAM, end-to-end health, tested alert state, log lookup.
- Backup/restore có checksum chính archive được chọn, guard không restore đè production.
- Fresh-deployment guide, rehearsal độc lập và playbook 5 sự cố.
- Paper PDF 8 trang, kịch bản online ba thành viên, script video và evidence thực nghiệm.

## Không được hiểu sai

Bản final không tuyên bố public Internet production readiness, HA, auth app/CSRF token, TLS public hay disaster recovery mất toàn bộ Mac. Không đưa credentials/database dumps vào release. Bản video giọng tổng hợp tham khảo phải được nhóm thay/xác nhận bằng thuyết minh thật theo yêu cầu môn học trước khi nộp.

## Kiểm tra trước nộp

1. Mở release/tag và clone đúng source; kiểm tra README và links.
2. Đối chiếu workflow main và API /version sau deploy.
3. Mở PDF, ảnh/log; biết ngày/SHA của mỗi bằng chứng.
4. Rehearse với dữ liệu thử và kiểm tra recovery trước khi kết thúc.
5. Ba thành viên xác nhận vai trò/việc thực hiện; video 5–10 phút không lộ secrets/IP riêng tư.

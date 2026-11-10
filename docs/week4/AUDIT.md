# Rà soát và sửa lỗi bản cuối — 2026-11-10

| Phát hiện | Cách sửa / giới hạn | Kiểm chứng |
|---|---|---|
| README tuần 1 mô tả host PostgreSQL/systemd như đường deploy hiện tại | Lưu bản lịch sử; README bản cuối trỏ Compose/Nginx/monitoring và guide sạch | Rà liên kết và source |
| Script vận hành phụ thuộc thư mục `.env` tuần 2 của một user cụ thể | Ưu tiên APP_ENV_FILE, rồi XDG config chuẩn; fallback legacy giữ tương thích | Clean Compose + legacy VM |
| Vượt maxlength qua HTTP hoặc NUL gây lỗi DB | Validate title/description phía server cho create/edit, giới hạn payload | Pytest với PostgreSQL thật |
| DB outage có thể kéo dài connection/query | connect_timeout 3s, statement_timeout 5s, lock_timeout 2s; health 503 và log tên loại lỗi | DB-stopped drill + test health failure |
| Cài mới nhầm sinh password trên volume đã tồn tại | init-env từ chối nếu volume có nhưng không có file secrets; không ghi đè file hiện hữu | Review guard + clean-volume setup |
| Guide chưa chứng minh ≥3 lỗi thực nghiệm | Thêm proxy/app/DB drills với recovery và data checks trên project cô lập | Rehearsal log |
| Cổng rehearsal cố định có thể trùng app khác trên Mac | Lần chạy đầu thật đã fail bind 15000. Giữ log lỗi; sửa chọn cổng rảnh riêng cho rehearsal | Chạy lại PASS; canonical production tunnel giữ 13000/19090/18080 |
| Thiếu release, paper, kịch bản bảo vệ cuối | Chuẩn bị assets, ma trận acceptance, report và lời thoại có phân công | Release manifest và kiểm tra assets |

Không tuyên bố quét hết mọi lỗ hổng hoặc không thể còn lỗi. App chưa có auth/CSRF token, HA/public TLS; không đưa lên Internet như ứng dụng multi-user. Giữ secrets và backup ngoài Git; không sửa attribution/đóng góp thành viên để tạo bằng chứng giả.

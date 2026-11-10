# Tạo lại hồ sơ và video tham khảo

Nguồn báo cáo là report-content.json; REPORT.md/PDF là bản đọc và nộp. Render PDF cần Python 3.12 cùng reportlab, pymupdf, pillow. `python scripts/week4/render-report.py` tạo output/pdf/DevOps_Final_Report.pdf và ảnh để QA. Dùng font Arial trên macOS hoặc DejaVu Sans trên Linux; kiểm tra render trước khi thay PDF versioned.

Video tham khảo cần macOS có giọng Linh, công cụ say/afinfo và Python imageio-ffmpeg, pillow. `python scripts/week4/render-walkthrough.py` tạo output/video/WEEK4_WALKTHROUGH_REFERENCE.mp4. Bản đã kiểm chứng dài khoảng 5 phút 30 giây, 1280×720, H.264/AAC, gắn nhãn giọng tổng hợp xuyên suốt. Nội dung dùng sơ đồ, log kiểm chứng thật và ảnh tuần 3 có ngày, không phải screen recording live hoặc giọng thành viên.

Giữ intermediates ngoài Git (output/ đã ignored). PDF, script video, kịch bản live và evidence bundle có thể đính kèm release; không đưa .env, archive DB, private keys hoặc thông tin đăng nhập vào bundle. Trước nộp, nhóm quay/thuyết minh thật theo VIDEO_SCRIPT.md, kiểm tra nội dung và thời lượng 5–10 phút.

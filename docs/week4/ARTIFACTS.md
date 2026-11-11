# Tạo lại hồ sơ và video tham khảo

Nguồn báo cáo là report-content.json; REPORT.md/PDF là bản đọc và nộp. Render PDF cần Python 3.12 cùng reportlab, pymupdf, pillow. `python scripts/week4/render-report.py` tạo output/pdf/DevOps_Final_Report.pdf và ảnh để QA. Dùng font Arial trên macOS hoặc DejaVu Sans trên Linux; kiểm tra render trước khi thay PDF versioned.

Báo cáo và video cuối do nhóm bổ sung riêng. Repo không chứa kịch bản trình bày hoặc công cụ tạo video thuyết minh.

Giữ intermediates ngoài Git (output/ đã ignored). Không đưa .env, archive DB, private keys hoặc thông tin đăng nhập vào hồ sơ nộp.

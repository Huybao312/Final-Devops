# Kịch bản bảo vệ online Week 4 — 18–23 phút

**Tùng:** kiến trúc và hạ tầng. **Huy Bảo:** ứng dụng và CI/CD. **Tuấn Bảo:** monitoring, backup/restore và điều tra sự cố. Mỗi người phải hiểu cả đường phục vụ; phân vai không có nghĩa chỉ học một lệnh. Dùng lời thoại như ý chính, không đọc máy móc.

## Chuẩn bị riêng trước buổi demo

- Bật VM; kiểm tra IP, Internet và runner online. Terminal Mac A giữ tunnel; terminal Mac B dùng repo; terminal VM C dùng `~/Final-Devops-week4`. Không chia sẻ cửa sổ chứa credentials.
- Mở app localhost:18080, API /version, Actions, Grafana localhost:13000/d/todo-week3 và Prometheus localhost:19090/alerts. Login Grafana trước, không đọc mật khẩu thành tiếng.
- Chuẩn bị rehearsal đã PASS. Lấy config directory từ dòng cuối rehearsal, gán `REHEARSAL` trên VM; đó là project riêng có prefix todo-week4-rehearsal. Không dùng container production để thử lỗi giảng viên.
- `sudo -v` trước buổi demo nếu cần xem UFW. Lưu PDF, ảnh/log và bản ghi dự phòng offline. Video nộp 5–10 phút là sản phẩm riêng, không cố nhồi toàn bộ Q&A vào video.

Mac A (thay VM_IP; nếu tunnel đã chạy và URL healthy thì dùng lại):

```bash
ssh -i ~/.ssh/devops_week2_utm -o ExitOnForwardFailure=yes -N -L 13000:127.0.0.1:3000 -L 19090:127.0.0.1:9090 -L 18080:127.0.0.1:80 ubuntusever@VM_IP
```

## 1. Giới thiệu và kiến trúc — 3 phút · Tùng

**Nói:** “Chào thầy và các bạn. Nhóm em trình bày Todo Task Manager như một hệ thống DevOps hoàn chỉnh. App cố ý giữ đơn giản để chúng em tập trung vào cách triển khai, quan sát và phục hồi có bằng chứng.”

Mở sơ đồ cuối. **Nói:** “Request đi qua Nginx tới app container; PostgreSQL nằm trên network nội bộ và dùng named volume. Một đường khác là CI/CD: PR chạy build và test, main mới được deploy qua runner trong VM. Monitoring chạy riêng để quá trình deploy app không làm mất dashboard.”

Chỉ phân công trên README. **Nói:** “Em phụ trách kiến trúc và hạ tầng; Huy Bảo trình bày app và pipeline; Tuấn Bảo trình bày vận hành và xử lý sự cố. Sau phần demo, chúng em sẽ xác minh nguyên nhân lỗi mà thầy chọn thay vì chỉ restart theo cảm tính.”

## 2. Thay đổi mới → pipeline → app — 5–7 phút · Huy Bảo

**Nói:** “Em sẽ thay một dòng giao diện để kết quả dễ quan sát. Phần cần chứng minh là source mới đi qua test và xuất hiện đúng phiên bản trên VM.”

Mac B, trong clone demo có working tree sạch:

```bash
git switch main
git pull --ff-only
git switch -c "demo/final-$(date +%m%d-%H%M%S)"
python3 - <<'PY'
from pathlib import Path
p=Path('templates/index.html'); s=p.read_text()
a='A clear plan for every day.'
b='Make room for what matters.'
old,new=(a,b) if a in s else (b,a)
if old not in s: raise SystemExit('Subtitle khác dự kiến; kiểm tra trước khi sửa')
p.write_text(s.replace(old,new,1))
PY
git diff -- templates/index.html
```

**Nói:** “Diff chỉ đổi subtitle. Em kiểm tra đúng phạm vi thay đổi rồi mới commit.”

```bash
git add templates/index.html
git commit -m "demo: show final deployment update"
git push -u origin HEAD
gh pr create --base main --title "Final demo: visible update" --body "Small visible change for the final end-to-end demonstration."
```

Mở PR/Actions, chờ check xanh. **Nói:** “Test chạy với PostgreSQL thật, gồm CRUD, health, bộ đếm và đầu vào không hợp lệ. Check rehearsal còn tạo stack riêng để kiểm chứng persistence, quyền DB và các lỗi vận hành. PR chưa deploy production.”

Merge bằng nút trên GitHub sau khi các check xanh. Mở run **push main**, không nhầm với run PR. **Nói:** “Sau merge, main chạy build-test rồi mới deploy. Runner build image với SHA commit và kiểm tra version sau khi khởi động.”

Sau run main xanh, trên Mac B:

```bash
MAIN_SHA="$(git ls-remote origin refs/heads/main | cut -f1)"
APP_SHA="$(curl -fsS http://localhost:18080/version | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')"
printf 'Main: %s\nApp:  %s\n' "$MAIN_SHA" "$APP_SHA"
test "$MAIN_SHA" = "$APP_SHA"
```

Refresh app bằng Cmd+Shift+R. **Nói:** “Subtitle đã đổi, đồng thời SHA app khớp main. Hai tín hiệu này chứng minh bản mới đã được triển khai; chỉ một trang mở được hoặc một run cũ xanh thì chưa đủ.”

Nếu pipeline kéo dài, chuyển sang phần monitoring và quay lại khi run hoàn tất. Nếu thất bại, đọc job/log, không merge tiếp hoặc tuyên bố deploy thành công.

## 3. Monitoring, security, backup/restore — 3–5 phút · Tuấn Bảo

Mở dashboard. **Nói:** “CPU/RAM là số liệu VM; health đi qua Nginx tới app và database. Alert chờ lỗi liên tục 30 giây để tránh báo động thoáng qua. Chúng em có ảnh và log alert FIRING rồi phục hồi từ lần thử thật.”

VM C:

```bash
SINCE=5m bash scripts/week3/app.sh logs
```

**Nói:** “Log có timestamp và được lọc theo thời gian. App, DB và monitoring đều có rotation. Khi process app dừng, proxy error log giúp thấy lỗi upstream; log app không thể ghi request mà nó không nhận được.”

Mở security checklist hoặc audit nếu đã chuẩn bị sudo:

```bash
bash scripts/week3/security-audit.sh
```

**Nói:** “UFW chỉ mở SSH/HTTP. App và monitoring bind loopback, DB không publish host port. User app có quyền dữ liệu nhưng không có quyền tạo table. Secrets nằm ngoài Git; quyền Docker vẫn rất mạnh nên chỉ cấp cho user triển khai tin cậy.”

Chạy restore proof trên DB kiểm chứng:

```bash
bash scripts/week3/verify-restore.sh
```

**Nói:** “Script backup nguồn, tạo database riêng, thêm một marker thử, backup rồi xóa marker và restore lại. Em chỉ vào count/checksum trước xóa và sau restore: chúng phải trùng nhau, marker phải trở lại. Dữ liệu production không bị dùng làm đối tượng xóa.”

## 4. Troubleshooting do giảng viên chọn — 5–10 phút · cả nhóm

**Tuấn Bảo nói:** “Trước khi thao tác, nhóm em xác định phạm vi lỗi và ghi trạng thái ban đầu. Với 502, cần phân biệt app dừng và proxy sai upstream; với 503 cần kiểm tra đường DB. Em sẽ dùng log để loại trừ giả thuyết.”

VM C, gán `REHEARSAL` bằng config directory đã in trong rehearsal. Chỉ chọn đúng bài giảng viên yêu cầu, không chạy tất cả lệnh gây lỗi cùng lúc:

```bash
bash scripts/week4/control-rehearsal.sh "$REHEARSAL" status
bash scripts/week4/control-rehearsal.sh "$REHEARSAL" logs
```

| Nếu chọn lỗi | Tạo lỗi trong project thử | Phục hồi |
|---|---|---|
| App stopped | `control-rehearsal.sh "$REHEARSAL" stop-app` | `start-app` |
| DB disconnected | `control-rehearsal.sh "$REHEARSAL" stop-db` | `start-db` |
| Proxy wrong upstream | `control-rehearsal.sh "$REHEARSAL" break-proxy` | `fix-proxy` |

Các lệnh trong bảng đều chạy bằng `bash scripts/week4/…`. Sau phục hồi, xem lại HTTP health qua proxy, version và task marker. Không suy luận chỉ từ nginx -t hoặc container Running.

**Tùng kết:** “Nguyên nhân gốc là …; bằng chứng là …; thao tác phục hồi là …; hệ thống đã được xác nhận lại bằng …; để phòng tránh, nhóm em …”. Điền theo lỗi thật vừa xác minh, không thuộc lòng một đáp án cho mọi lỗi.

## 5. Kết thúc và Q&A

**Tùng:** “Nhóm em đã chứng minh đường code đến deploy, quan sát và phục hồi. Giới hạn hiện tại là một VM, chưa có HA/public TLS/login app. Backup trên cùng máy Mac chưa bảo vệ mất toàn bộ host. Các minh chứng và release được gắn với source cụ thể để thầy có thể kiểm tra lại.”

Câu hỏi cần luyện: Vì sao Compose/PostgreSQL? Runner được quyền gì? depends_on bảo đảm gì? Volume khác backup thế nào? 502 khác 503 thế nào? Vì sao nginx -t vẫn PASS khi sai port? SHA API chứng minh được gì và không chứng minh được gì? Restore sang DB riêng có phải cutover production không?

Nếu mạng lỗi: nói rõ đang chiếu bản ghi/log từ lần thử trước, nêu ngày/SHA; không mô tả chúng là live. Dừng phần gây lỗi nếu chưa phục hồi, sửa đúng project thử rồi mới kết thúc.

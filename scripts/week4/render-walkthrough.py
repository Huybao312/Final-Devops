"""macOS-only narrated REFERENCE, not a recording/voice of team members."""
import re
import subprocess
import textwrap
from pathlib import Path
import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFont

root=Path(__file__).resolve().parents[2]
out=root/'output/video';out.mkdir(parents=True,exist_ok=True)
font='/System/Library/Fonts/Supplemental/Arial.ttf'
fontbold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
regular=lambda size:ImageFont.truetype(font,size)
bold=lambda size:ImageFont.truetype(fontbold,size)
lines=(root/'docs/week4/VIDEO_SCRIPT.md').read_text().splitlines()
narrations=[s[1:-1] for s in lines if s.startswith('“') and s.endswith('”')]
assert len(narrations)==7
scenes=[
 ('Giới thiệu đồ án','Code → kiểm thử → triển khai → quan sát → phục hồi',['Todo Task Manager','Flask / Gunicorn / PostgreSQL 18','Docker Compose / Nginx / GitHub Actions','Nhóm: Tùng · Huy Bảo · Tuấn Bảo'],None),
 ('Kiến trúc cuối','Hai đường: request và deployment',['Nginx → app → internal DB → volume','Monitoring chạy độc lập','SSH tunnel: 13000 / 19090 / 18080'],root/'output/pdf/architecture-render.png'),
 ('CI/CD và version','Kết quả PR từ CLI · nguồn: ci-checks.txt',['PR chạy build/test, main mới deploy','Test dùng PostgreSQL riêng','Đối chiếu SHA API với commit main'],None),
 ('Monitoring và bảo mật','Ảnh thực nghiệm tuần 3 — 04/11/2026',['CPU / RAM / health / latency','Alert Pending → Firing → Inactive','Loopback + firewall + DB least privilege'],root/'docs/evidence/week3/dashboard-recovered.jpg'),
 ('Backup và restore','Trích log Ubuntu thật — 10/11/2026',['Backup DB rehearsal','Xóa marker tổng hợp trong DB riêng','Restore: count và checksum phải khớp'],None),
 ('Troubleshooting','Ba lỗi được thực nghiệm và phục hồi',['App stopped: proxy 502','DB stopped: health 503','Upstream sai port: nginx -t PASS, HTTP 502','Phải xác nhận dữ liệu sau phục hồi'],None),
 ('Kết luận và giới hạn','Nhóm cần thu giọng thật trước khi nộp',['Guide / playbook / report / release','Một VM; chưa có public TLS, login app, HA','Backup cùng Mac chưa bảo vệ mất host','Q&A: giải thích nguyên nhân và bằng chứng'],None),
]
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
clips=[]; total=0
for i,((title,sub,bullets,picture),narration) in enumerate(zip(scenes,narrations),1):
 frame=Image.new('RGB',(1280,720),'#f1f5f8');d=ImageDraw.Draw(frame)
 d.rectangle((0,0,1280,92),fill='#153d51')
 d.text((42,20),f'{i:02d}   {title}',font=bold(34),fill='white')
 d.text((42,103),sub,font=regular(21),fill='#315a6e')
 d.rounded_rectangle((35,145,575,630),radius=14,fill='white')
 y=172
 for bullet in bullets:
  for j,line in enumerate(textwrap.wrap(bullet,33)):
   d.text((58,y),('• ' if j==0 else '  ')+line,font=regular(25),fill='#163747');y+=38
  y+=12
 if picture:
  im=Image.open(picture).convert('RGB');im.thumbnail((625,465))
  frame.paste(im,(615+(625-im.width)//2,150+(465-im.height)//2))
 else:
  d.rounded_rectangle((605,145,1245,630),radius=14,fill='#e2ecf1')
  checks=[]
  seen=set()
  evidence=root/'docs/evidence/week4/ci-checks.txt'
  if evidence.exists():
   for row in evidence.read_text().splitlines():
    cols=row.split('\t')
    if len(cols)>=3 and cols[0] not in seen:
     seen.add(cols[0]);checks.append(f'{cols[0]}: {cols[1]} ({cols[2]})')
  snippets={
   1:'DEVOPS FINAL PROJECT 2026\n\nPhạm vi: local Ubuntu VM\nGiữ dữ liệu production\nDiễn tập lỗi ở project riêng',
   3:'\n\n'.join(checks)+'\n\nPR: deploy skipped là đúng.\nNguồn: ci-checks.txt / GitHub Actions',
   5:'Before deletion: 2\nAfter deletion:  1\nAfter restore:  2\n\nChecksum trước = sau restore\nMarker thử xuất hiện lại\n\nNguồn: rehearsal-vm.txt',
   6:'Giả thuyết → xác minh → sửa\n\nKhông restart mù quáng\nKhông xóa volume\nKhông suy luận từ Running\n\nNguồn: rehearsal-vm.txt',
   7:'Bản tập giọng tổng hợp\nKhông phải bản ghi thành viên\n\nPDF: 8 trang\nVideo gợi ý: 5–10 phút\nSource + evidence trong repo',
  }
  yy=180
  for line in snippets.get(i,'').splitlines():
   for wrapped in textwrap.wrap(line,45) or ['']:
    d.text((628,yy),wrapped,font=regular(21),fill='#163747');yy+=31
 d.rectangle((0,654,1280,720),fill='#153d51')
 d.text((40,666),'BẢN TẬP · GIỌNG TỔNG HỢP · KHÔNG PHẢI VIDEO THÀNH VIÊN',font=bold(20),fill='white')
 d.text((40,695),'Minh chứng có nguồn/ngày; lời thoại để nhóm tự thu và bảo vệ.',font=regular(15),fill='#d6e8ef')
 png=out/f'scene-{i}.png';frame.save(png)
 txt=out/f'narration-{i}.txt';txt.write_text(narration)
 audio=out/f'narration-{i}.aiff'
 subprocess.run(['say','-v','Linh','-r','135','-f',str(txt),'-o',str(audio)],check=True)
 info=subprocess.check_output(['afinfo',str(audio)],text=True)
 seconds=float(re.search(r'estimated duration: ([0-9.]+)',info,re.I).group(1))
 duration=max(45,seconds+2);total+=duration
 clip=out/f'clip-{i}.mp4'
 subprocess.run([ffmpeg,'-y','-hide_banner','-loglevel','error','-loop','1','-framerate','8','-i',str(png),'-i',str(audio),'-t',str(duration),'-af','apad','-c:v','libx264','-preset','veryfast','-crf','23','-pix_fmt','yuv420p','-r','8','-c:a','aac','-b:a','96k',str(clip)],check=True)
 clips.append(clip)
 print(f'scene {i}: speech={seconds:.1f}s, clip={duration:.1f}s',flush=True)
assert 300 <= total <= 600, total
listing=out/'concat.txt';listing.write_text(''.join(f"file '{p.name}'\n" for p in clips))
final=out/'WEEK4_WALKTHROUGH_REFERENCE.mp4'
subprocess.run([ffmpeg,'-y','-hide_banner','-loglevel','error','-f','concat','-safe','0','-i',str(listing),'-c','copy','-movflags','+faststart',str(final)],check=True)
print(f'{final}: {total:.1f} seconds')

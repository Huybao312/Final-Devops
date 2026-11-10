"""Render the versioned report source to an eight-page PDF (artifact dependencies only)."""
import json
from pathlib import Path
from html import escape
import pymupdf as fitz
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Image, Table, TableStyle

root=Path(__file__).resolve().parents[2]
output=root/'output/pdf/DevOps_Final_Report.pdf'
output.parent.mkdir(parents=True,exist_ok=True)
regular=next(p for p in [Path('/System/Library/Fonts/Supplemental/Arial.ttf'),Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')] if p.exists())
bold=regular.with_name('Arial Bold.ttf') if regular.name=='Arial.ttf' else regular.with_name('DejaVuSans-Bold.ttf')
pdfmetrics.registerFont(TTFont('Report',str(regular)))
pdfmetrics.registerFont(TTFont('ReportBold',str(bold)))
styles={
 'title':ParagraphStyle('title',fontName='ReportBold',fontSize=18,leading=23,textColor=colors.HexColor('#143b50'),spaceAfter=14),
 'sub':ParagraphStyle('sub',fontName='Report',fontSize=10,leading=14,textColor=colors.HexColor('#567080'),spaceAfter=14),
 'heading':ParagraphStyle('heading',fontName='ReportBold',fontSize=11,leading=15,textColor=colors.HexColor('#176877'),spaceBefore=9,spaceAfter=5),
 'body':ParagraphStyle('body',fontName='Report',fontSize=10.5,leading=15,spaceAfter=8),
 'cell':ParagraphStyle('cell',fontName='Report',fontSize=9.3,leading=12.8),
}
width=A4[0]-96
story=[]
for number,page in enumerate(json.loads((root/'docs/week4/report-content.json').read_text())):
 if number:story.append(PageBreak())
 story.append(Paragraph(escape(page['title']),styles['title']))
 if page.get('subtitle'):story.append(Paragraph(escape(page['subtitle']),styles['sub']))
 if page.get('image'):
  image_path=root/page['image']
  if image_path.suffix=='.svg':
   doc=fitz.open(stream=image_path.read_bytes(),filetype='svg')
   image_path=output.parent/'architecture-render.png'
   doc[0].get_pixmap(matrix=fitz.Matrix(1.5,1.5)).save(image_path)
  from PIL import Image as PILImage
  with PILImage.open(image_path) as im:w,h=im.size
  story.append(Image(str(image_path),width=width,height=width*h/w))
  story.append(Spacer(1,10))
 if page.get('table'):
  rows=[[Paragraph(escape(cell),styles['cell']) for cell in row] for row in page['table']]
  table=Table(rows,colWidths=[width*.38,width*.62],hAlign='LEFT')
  table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e0edf2')),('VALIGN',(0,0),(-1,-1),'TOP'),('GRID',(0,0),(-1,-1),.4,colors.HexColor('#c7d5dd')),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6)]))
  story.extend([table,Spacer(1,10)])
 for title,text in page['sections']:
  story.append(Paragraph(escape(title),styles['heading']))
  story.append(Paragraph(escape(text).replace('\n','<br/>'),styles['body']))
def footer(canvas,doc):
 canvas.setStrokeColor(colors.HexColor('#c7d5dd'));canvas.line(48,37,A4[0]-48,37)
 canvas.setFont('Report',8);canvas.setFillColor(colors.HexColor('#567080'))
 canvas.drawString(48,25,'DevOps Final Project 2026 · 10/11/2026')
 canvas.drawRightString(A4[0]-48,25,str(doc.page))
SimpleDocTemplate(str(output),pagesize=A4,leftMargin=48,rightMargin=48,topMargin=42,bottomMargin=48,title='DevOps Final Project 2026 — Technical Report',author='Nhóm DevOps').build(story,onFirstPage=footer,onLaterPages=footer)
doc=fitz.open(output)
print(f'{output}: {len(doc)} pages')
for i,page in enumerate(doc):
 page.get_pixmap(matrix=fitz.Matrix(.9,.9)).save(output.parent/f'review-{i+1}.png')
assert 6 <= len(doc) <= 10, 'Report page count outside recommended range'

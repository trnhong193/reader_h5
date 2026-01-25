#!/usr/bin/env python3
"""
Script để chuyển đổi Word sang PDF hoặc Markdown trực tiếp sang PDF
Sử dụng LibreOffice hoặc unoconv nếu có
"""

import os
import subprocess
import sys

def convert_word_to_pdf_with_libreoffice(word_file, pdf_file):
    """Chuyển Word sang PDF bằng LibreOffice"""
    try:
        # Thử dùng LibreOffice
        cmd = ['libreoffice', '--headless', '--convert-to', 'pdf', 
               '--outdir', os.path.dirname(word_file), word_file]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            # LibreOffice tạo file PDF cùng tên
            expected_pdf = os.path.splitext(word_file)[0] + '.pdf'
            if os.path.exists(expected_pdf):
                if expected_pdf != pdf_file:
                    os.rename(expected_pdf, pdf_file)
                print(f"✓ Đã tạo file PDF bằng LibreOffice: {pdf_file}")
                return True
    except FileNotFoundError:
        pass
    except Exception as e:
        print(f"Lỗi với LibreOffice: {e}")
    
    return False

def convert_with_unoconv(word_file, pdf_file):
    """Chuyển Word sang PDF bằng unoconv"""
    try:
        cmd = ['unoconv', '-f', 'pdf', '-o', pdf_file, word_file]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0 and os.path.exists(pdf_file):
            print(f"✓ Đã tạo file PDF bằng unoconv: {pdf_file}")
            return True
    except FileNotFoundError:
        pass
    except Exception as e:
        print(f"Lỗi với unoconv: {e}")
    
    return False

def convert_with_reportlab(md_file, pdf_file):
    """Chuyển Markdown sang PDF bằng reportlab"""
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import inch
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, Table, TableStyle
        from reportlab.lib import colors
        from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
        from markdown import markdown
        import re
        
        print("Đang chuyển đổi sang PDF bằng reportlab...")
        
        # Đọc markdown
        with open(md_file, 'r', encoding='utf-8') as f:
            md_content = f.read()
        
        # Tạo PDF
        doc = SimpleDocTemplate(pdf_file, pagesize=A4,
                               rightMargin=72, leftMargin=72,
                               topMargin=72, bottomMargin=18)
        
        # Styles
        styles = getSampleStyleSheet()
        story = []
        
        # Xử lý markdown
        lines = md_content.split('\n')
        in_code_block = False
        code_block_lines = []
        
        for line in lines:
            # Code blocks
            if line.strip().startswith('```'):
                if in_code_block:
                    if code_block_lines:
                        code_text = '\n'.join(code_block_lines)
                        story.append(Preformatted(code_text, styles['Code']))
                    code_block_lines = []
                    in_code_block = False
                else:
                    in_code_block = True
                continue
            
            if in_code_block:
                code_block_lines.append(line)
                continue
            
            # Headers
            if line.startswith('# '):
                story.append(Paragraph(line[2:].strip(), styles['Heading1']))
                story.append(Spacer(1, 12))
            elif line.startswith('## '):
                story.append(Paragraph(line[3:].strip(), styles['Heading2']))
                story.append(Spacer(1, 10))
            elif line.startswith('### '):
                story.append(Paragraph(line[4:].strip(), styles['Heading3']))
                story.append(Spacer(1, 8))
            # Tables
            elif '|' in line and line.strip().startswith('|'):
                if not re.match(r'^\|[\s\-\|:]+\|$', line.strip()):
                    cells = [cell.strip() for cell in line.split('|')[1:-1]]
                    # Tạo table (đơn giản hóa)
                    data = [cells]
                    table = Table(data)
                    table.setStyle(TableStyle([
                        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                        ('FONTSIZE', (0, 0), (-1, 0), 10),
                        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                        ('GRID', (0, 0), (-1, -1), 1, colors.black)
                    ]))
                    story.append(table)
                    story.append(Spacer(1, 12))
            # Horizontal rules
            elif line.strip() == '---':
                story.append(Spacer(1, 12))
            # Regular paragraphs
            elif line.strip():
                # Xử lý inline code
                para_text = line.strip()
                para_text = re.sub(r'`([^`]+)`', r'<font name="Courier">\1</font>', para_text)
                story.append(Paragraph(para_text, styles['Normal']))
                story.append(Spacer(1, 6))
        
        doc.build(story)
        print(f"✓ Đã tạo file PDF: {pdf_file}")
        return True
        
    except ImportError:
        print("⚠ Thiếu thư viện reportlab. Cài đặt: pip install reportlab markdown")
        return False
    except Exception as e:
        print(f"Lỗi với reportlab: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    md_file = '/home/tth193/Documents/h5_code/00_CODE_H5/iq_tcp/BAO_CAO_IQTCP_H5.md'
    word_file = '/home/tth193/Documents/h5_code/00_CODE_H5/iq_tcp/BAO_CAO_IQTCP_H5.docx'
    pdf_file = '/home/tth193/Documents/h5_code/00_CODE_H5/iq_tcp/BAO_CAO_IQTCP_H5.pdf'
    
    print("=" * 80)
    print("CHUYỂN ĐỔI SANG PDF")
    print("=" * 80)
    
    # Thử các phương pháp
    if os.path.exists(word_file):
        print(f"\nTìm thấy file Word: {word_file}")
        print("Đang thử chuyển Word sang PDF...")
        
        if convert_word_to_pdf_with_libreoffice(word_file, pdf_file):
            return
        if convert_with_unoconv(word_file, pdf_file):
            return
    
    # Nếu không có LibreOffice/unoconv, thử reportlab
    print("\nĐang thử chuyển trực tiếp từ Markdown sang PDF...")
    if convert_with_reportlab(md_file, pdf_file):
        return
    
    print("\n⚠ Không thể tạo PDF tự động.")
    print("Các cách khác:")
    print("1. Cài đặt LibreOffice và chạy: libreoffice --headless --convert-to pdf BAO_CAO_IQTCP_H5.docx")
    print("2. Mở file Word và xuất sang PDF")
    print("3. Sử dụng dịch vụ online chuyển đổi Word sang PDF")

if __name__ == '__main__':
    main()




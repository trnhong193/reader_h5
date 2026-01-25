#!/bin/bash
# Script để chuyển đổi báo cáo Markdown sang Word và PDF

cd "$(dirname "$0")"
md_file="BAO_CAO_IQTCP_H5.md"

# Chuyển sang Word bằng Python
python3 << 'EOF'
import sys
import os
sys.path.append('../../00_CODE_H5/iq_tcp')

from convert_md import convert_with_python_docx, convert_to_pdf_via_html
from convert_to_pdf import convert_word_to_pdf_with_libreoffice

md_file = 'BAO_CAO_IQTCP_H5.md'
word_file = 'BAO_CAO_IQTCP_H5.docx'
pdf_file = 'BAO_CAO_IQTCP_H5.pdf'

print("=" * 80)
print("CHUYỂN ĐỔI BÁO CÁO MATLAB")
print("=" * 80)

# Chuyển sang Word
if os.path.exists(md_file):
    print(f"\nĐang chuyển {md_file} sang Word...")
    convert_with_python_docx(md_file, word_file)
    
    # Chuyển Word sang PDF
    if os.path.exists(word_file):
        print(f"\nĐang chuyển {word_file} sang PDF...")
        convert_word_to_pdf_with_libreoffice(word_file, pdf_file)
    
    print("\n" + "=" * 80)
    print("HOÀN THÀNH")
    print("=" * 80)
    if os.path.exists(word_file):
        print(f"✓ File Word: {word_file}")
    if os.path.exists(pdf_file):
        print(f"✓ File PDF: {pdf_file}")
else:
    print(f"Lỗi: Không tìm thấy file {md_file}")
EOF




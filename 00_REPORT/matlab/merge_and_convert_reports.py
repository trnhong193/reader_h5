#!/usr/bin/env python3
"""
Script để gộp tất cả các file báo cáo .md thành 1 file chung và chuyển đổi sang Word và PDF
"""

import os
import sys
import glob
from datetime import datetime
from pathlib import Path

# Thêm path để import các module chuyển đổi
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../00_CODE_H5/iq_tcp'))


def merge_reports(output_file='report_matlab.md'):
    """Gộp tất cả các file báo cáo .md thành 1 file"""
    
    report_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Danh sách các file báo cáo theo thứ tự
    report_files = [
        'BAO_CAO_IQETHERNET_H5.md',
        'BAO_CAO_IQTCP_H5.md',
        'BAO_CAO_SPECTRUM_H5.md',
        'BAO_CAO_HISTOGRAM_H5.md',
        'BAO_CAO_DF_H5.md',
        'BAO_CAO_DEMODULATION_H5.md',
        'BAO_CAO_IDENTIFIER_H5.md',
    ]
    
    output_path = os.path.join(report_dir, output_file)
    
    print("=" * 80)
    print("GỘP CÁC FILE BÁO CÁO MATLAB")
    print("=" * 80)
    print(f"\nĐang gộp các file báo cáo...")
    
    merged_content = []
    
    # Thêm tiêu đề chung
    merged_content.append("# BÁO CÁO TỔNG HỢP: CẤU TRÚC CÁC FILE H5 (MATLAB)\n")
    merged_content.append(f"\n**Ngày tạo báo cáo**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    merged_content.append("\n---\n")
    merged_content.append("\n## MỤC LỤC\n\n")
    
    # Tạo mục lục
    toc_items = []
    for i, report_file in enumerate(report_files, 1):
        report_path = os.path.join(report_dir, report_file)
        if os.path.exists(report_path):
            # Đọc tiêu đề đầu tiên từ file
            with open(report_path, 'r', encoding='utf-8') as f:
                first_line = f.readline().strip()
                if first_line.startswith('#'):
                    title = first_line.replace('#', '').strip()
                    # Loại bỏ "(MATLAB)" nếu có
                    title = title.replace(' (MATLAB)', '')
                    toc_items.append(f"{i}. [{title}](#{title.lower().replace(' ', '-').replace(':', '').replace('(', '').replace(')', '')})")
    
    merged_content.append('\n'.join(toc_items))
    merged_content.append("\n\n---\n\n")
    
    # Gộp từng file
    for i, report_file in enumerate(report_files, 1):
        report_path = os.path.join(report_dir, report_file)
        
        if not os.path.exists(report_path):
            print(f"⚠ Cảnh báo: Không tìm thấy file {report_file}")
            continue
        
        print(f"  [{i}/{len(report_files)}] Đang gộp: {report_file}")
        
        # Thêm phân cách giữa các báo cáo
        merged_content.append(f"\n\n{'=' * 80}\n")
        merged_content.append(f"# PHẦN {i}\n")
        merged_content.append(f"{'=' * 80}\n\n")
        
        # Đọc và thêm nội dung file
        with open(report_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Loại bỏ tiêu đề đầu tiên nếu là "# BÁO CÁO..." để tránh trùng lặp
            lines = content.split('\n')
            if lines and lines[0].startswith('# BÁO CÁO'):
                # Giữ lại tiêu đề nhưng điều chỉnh level
                lines[0] = '## ' + lines[0].replace('#', '').strip()
                content = '\n'.join(lines)
            
            merged_content.append(content)
            merged_content.append("\n\n---\n\n")
    
    # Ghi file gộp
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(''.join(merged_content))
    
    print(f"\n✓ Đã gộp thành công: {output_path}")
    print(f"  Tổng số file: {len([f for f in report_files if os.path.exists(os.path.join(report_dir, f))])}")
    
    return output_path


def convert_to_word_and_pdf(md_file):
    """Chuyển đổi file Markdown sang Word và PDF"""
    
    base_name = os.path.splitext(md_file)[0]
    word_file = f"{base_name}.docx"
    pdf_file = f"{base_name}.pdf"
    
    print("\n" + "=" * 80)
    print("CHUYỂN ĐỔI SANG WORD VÀ PDF")
    print("=" * 80)
    
    # Thử import các module chuyển đổi
    try:
        from convert_md import convert_with_python_docx, convert_to_pdf_via_html
        from convert_to_pdf import convert_word_to_pdf_with_libreoffice
        
        # Chuyển sang Word
        print(f"\nĐang chuyển {md_file} sang Word...")
        try:
            convert_with_python_docx(md_file, word_file)
            print(f"✓ Đã tạo file Word: {word_file}")
        except Exception as e:
            print(f"⚠ Lỗi khi chuyển sang Word: {e}")
            print("  Thử phương pháp khác...")
            # Thử pypandoc nếu có
            try:
                import pypandoc
                pypandoc.convert_file(md_file, 'docx', outputfile=word_file, extra_args=['--standalone'])
                print(f"✓ Đã tạo file Word bằng pypandoc: {word_file}")
            except ImportError:
                print("⚠ Không có pypandoc. Cài đặt: pip install pypandoc")
            except Exception as e2:
                print(f"⚠ Lỗi với pypandoc: {e2}")
        
        # Chuyển Word sang PDF
        if os.path.exists(word_file):
            print(f"\nĐang chuyển {word_file} sang PDF...")
            try:
                if convert_word_to_pdf_with_libreoffice(word_file, pdf_file):
                    print(f"✓ Đã tạo file PDF: {pdf_file}")
                else:
                    # Thử phương pháp khác
                    print("  Thử phương pháp khác...")
                    convert_to_pdf_via_html(md_file, pdf_file)
            except Exception as e:
                print(f"⚠ Lỗi khi chuyển sang PDF: {e}")
                print("  Có thể cần cài đặt LibreOffice hoặc sử dụng công cụ khác")
        else:
            print("⚠ Không tìm thấy file Word để chuyển sang PDF")
    
    except ImportError as e:
        print(f"⚠ Không thể import module chuyển đổi: {e}")
        print("\nCài đặt các thư viện cần thiết:")
        print("  pip install python-docx markdown weasyprint")
        print("  pip install pypandoc  # (tùy chọn)")
        print("\nHoặc sử dụng LibreOffice:")
        print(f"  libreoffice --headless --convert-to docx {md_file}")
        print(f"  libreoffice --headless --convert-to pdf {word_file}")
    
    return word_file, pdf_file


def main():
    """Hàm chính"""
    report_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(report_dir)
    
    print("=" * 80)
    print("GỘP VÀ CHUYỂN ĐỔI BÁO CÁO MATLAB")
    print("=" * 80)
    
    # 1. Gộp các file báo cáo
    merged_file = merge_reports('report_matlab.md')
    
    # 2. Chuyển đổi sang Word và PDF
    word_file, pdf_file = convert_to_word_and_pdf(merged_file)
    
    # 3. Tóm tắt
    print("\n" + "=" * 80)
    print("HOÀN THÀNH")
    print("=" * 80)
    print(f"\nFile đã tạo:")
    if os.path.exists(merged_file):
        size_md = os.path.getsize(merged_file) / 1024
        print(f"  ✓ Markdown: {merged_file} ({size_md:.1f} KB)")
    if os.path.exists(word_file):
        size_word = os.path.getsize(word_file) / 1024
        print(f"  ✓ Word: {word_file} ({size_word:.1f} KB)")
    if os.path.exists(pdf_file):
        size_pdf = os.path.getsize(pdf_file) / 1024
        print(f"  ✓ PDF: {pdf_file} ({size_pdf:.1f} KB)")
    
    print("\n" + "=" * 80)


if __name__ == '__main__':
    main()


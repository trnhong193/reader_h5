#!/usr/bin/env python3
"""
Script để kiểm tra cấu trúc file H5 trực tiếp bằng h5py
So sánh với output của các reader MATLAB
"""

import h5py
import os
import sys

def print_h5_structure(name, obj, depth=0, max_depth=3):
    """In cấu trúc H5 file"""
    indent = '  ' * depth
    if depth > max_depth:
        return
    
    if isinstance(obj, h5py.Group):
        print(f"{indent}{name}/ (Group)")
        # In attributes nếu có
        if obj.attrs:
            print(f"{indent}  Attributes:")
            for attr_name in obj.attrs:
                attr_val = obj.attrs[attr_name]
                if isinstance(attr_val, bytes):
                    try:
                        attr_val = attr_val.decode('utf-8')
                    except:
                        attr_val = str(attr_val)
                elif hasattr(attr_val, '__len__') and len(attr_val) > 20:
                    attr_val = f"[array, size={len(attr_val)}]"
                print(f"{indent}    {attr_name}: {attr_val}")
    elif isinstance(obj, h5py.Dataset):
        print(f"{indent}{name} (Dataset: {obj.dtype}, shape={obj.shape})")
        # In attributes nếu có
        if obj.attrs:
            print(f"{indent}  Attributes:")
            for attr_name in obj.attrs:
                attr_val = obj.attrs[attr_name]
                if isinstance(attr_val, bytes):
                    try:
                        attr_val = attr_val.decode('utf-8')
                    except:
                        attr_val = str(attr_val)
                elif hasattr(attr_val, '__len__') and len(attr_val) > 20:
                    attr_val = f"[array, size={len(attr_val)}]"
                print(f"{indent}    {attr_name}: {attr_val}")

def check_h5_file(filepath):
    """Kiểm tra một file H5"""
    if not os.path.exists(filepath):
        print(f"File không tồn tại: {filepath}")
        return
    
    print("=" * 60)
    print(f"File: {os.path.basename(filepath)}")
    print("=" * 60)
    
    try:
        with h5py.File(filepath, 'r') as f:
            print("\nCẤU TRÚC FILE H5:\n")
            f.visititems(print_h5_structure)
            
            # In thông tin tổng quan
            print("\n--- THÔNG TIN TỔNG QUAN ---")
            print(f"Root groups: {list(f.keys())}")
            
            # Kiểm tra /attribute
            if 'attribute' in f:
                print(f"\n/attribute groups: {list(f['attribute'].keys())}")
                print(f"/attribute attributes: {list(f['attribute'].attrs.keys())}")
            
            # Kiểm tra /session
            if 'session' in f:
                sessions = list(f['session'].keys())
                print(f"\n/session: {len(sessions)} sessions")
                if len(sessions) > 0:
                    first_session = sessions[0]
                    print(f"  First session ({first_session}):")
                    print(f"    Groups: {list(f['session'][first_session].keys())}")
                    print(f"    Datasets: {[k for k in f['session'][first_session].keys() if isinstance(f['session'][first_session][k], h5py.Dataset)]}")
                    print(f"    Attributes: {list(f['session'][first_session].attrs.keys())}")
    except Exception as e:
        print(f"Lỗi khi đọc file: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    base_path = '/home/tth193/Documents/h5_code/00_DATA_h5/'
    
    files_to_check = [
        'df.h5',
        'identifier.h5',
        'demodulation.h5',
        'spectrum.h5',
        'histogram.h5',
        'iqethernet.h5',
        'iqtcp.h5'
    ]
    
    for filename in files_to_check:
        filepath = os.path.join(base_path, filename)
        check_h5_file(filepath)
        print("\n" + "=" * 60 + "\n")




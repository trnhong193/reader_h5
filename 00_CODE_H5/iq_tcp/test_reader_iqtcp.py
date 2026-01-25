"""
Test script để đọc và hiển thị chi tiết cấu trúc file iqtcp.h5
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

from reader_iqtcp_h5 import read_iqtcp_h5
import numpy as np

# Đường dẫn file
filename = '/home/tth193/Documents/h5_code/00_DATA_h5/iqtcp.h5'

print('=' * 80)
print('ĐỌC FILE IQTCP.H5')
print('=' * 80)
print(f'File: {filename}\n')

# Đọc file
try:
    data = read_iqtcp_h5(filename)
    
    # 1. GLOBAL INFO
    print('\n' + '=' * 80)
    print('[1] THÔNG TIN CHUNG (GLOBAL INFO)')
    print('=' * 80)
    if 'global_info' in data and data['global_info']:
        print('Các trường có trong global_info:')
        for key, value in data['global_info'].items():
            if isinstance(value, str):
                val_str = value[:50] + '...' if len(value) > 50 else value
                print(f'  • {key} = "{val_str}"')
            elif isinstance(value, (int, float, np.number)):
                print(f'  • {key} = {value}')
            else:
                print(f'  • {key} = {type(value).__name__} (size: {np.size(value) if hasattr(value, "size") else "N/A"})')
    else:
        print('⚠ Không có global_info trong file này.')
    
    # 2. DDC INFO
    print('\n' + '=' * 80)
    print('[2] THÔNG TIN DDC (Digital Down Converter)')
    print('=' * 80)
    if 'ddc_info' in data and data['ddc_info']:
        print('Các trường có trong ddc_info:')
        for key, value in data['ddc_info'].items():
            if isinstance(value, str):
                print(f'  • {key} = "{value}"')
            elif isinstance(value, (int, float, np.number)):
                print(f'  • {key} = {value}')
            else:
                print(f'  • {key} = {type(value).__name__}')
    else:
        print('⚠ Không có ddc_info trong file này.')
    
    # 3. REQUEST INFO
    print('\n' + '=' * 80)
    print('[3] THÔNG TIN REQUEST')
    print('=' * 80)
    if 'request_info' in data and data['request_info']:
        print('Các trường có trong request_info:')
        for key, value in data['request_info'].items():
            if isinstance(value, str):
                val_str = value[:50] + '...' if len(value) > 50 else value
                print(f'  • {key} = "{val_str}"')
            elif isinstance(value, (int, float, np.number)):
                print(f'  • {key} = {value}')
            else:
                print(f'  • {key} = {type(value).__name__}')
    else:
        print('⚠ Không có request_info trong file này.')
    
    # 4. SESSIONS INFO
    print('\n' + '=' * 80)
    print('[4] THÔNG TIN SESSIONS')
    print('=' * 80)
    sessions = data.get('sessions', [])
    print(f'Tổng số sessions: {len(sessions)}')
    
    if sessions:
        # Tìm session đầu tiên có dữ liệu
        target_idx = -1
        for i, sess in enumerate(sessions):
            if sess['i'] is not None and sess['q'] is not None:
                if len(sess['i']) > 0 and len(sess['q']) > 0:
                    target_idx = i
                    break
        
        if target_idx >= 0:
            sess = sessions[target_idx]
            print(f'\nSession có dữ liệu đầu tiên: Index {target_idx}, ID: {sess["id"]}')
            print(f'  - I: shape={sess["i"].shape}, dtype={sess["i"].dtype}, min={sess["i"].min()}, max={sess["i"].max()}, mean={sess["i"].mean():.2f}')
            print(f'  - Q: shape={sess["q"].shape}, dtype={sess["q"].dtype}, min={sess["q"].min()}, max={sess["q"].max()}, mean={sess["q"].mean():.2f}')
            if sess['iq'] is not None:
                iq_mag = np.abs(sess['iq'])
                print(f'  - IQ: shape={sess["iq"].shape}, dtype={sess["iq"].dtype}')
                print(f'    Magnitude: min={iq_mag.min():.2f}, max={iq_mag.max():.2f}, mean={iq_mag.mean():.2f}')
                print(f'    Phase: min={np.angle(sess["iq"]).min():.3f}, max={np.angle(sess["iq"]).max():.3f}')
                print(f'\n  5 giá trị đầu của I: {sess["i"][:5]}')
                print(f'  5 giá trị đầu của Q: {sess["q"][:5]}')
                print(f'  5 giá trị đầu của IQ: {sess["iq"][:5]}')
        else:
            print('⚠ Không tìm thấy session nào có dữ liệu.')
    
    print('\n' + '=' * 80)
    print('HOÀN THÀNH')
    print('=' * 80)
    
except Exception as e:
    print(f'Lỗi: {e}')
    import traceback
    traceback.print_exc()


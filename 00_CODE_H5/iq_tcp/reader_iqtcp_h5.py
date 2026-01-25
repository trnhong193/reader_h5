"""
Reader for IQ TCP H5 files (Narrowband TCP - I/Q samples)
Based on MATLAB code: read_iqtcp_h5_verge2.m

This module reads HDF5 files containing IQ data with the following structure:
- /attribute: Contains metadata (global_info, ddc_info, request_info, etc.)
- /session: Contains multiple sessions, each with 'i' and 'q' datasets

Output:
    data['global_info']: Attributes directly from /attribute
    data['ddc_info']: Attributes from /attribute/ddc
    data['request_info']: Attributes from /attribute/request
    data['sessions']: List of dictionaries containing id, i, q, and iq_complex
"""

import h5py
import numpy as np
import os
from typing import Dict, List, Any, Optional


def read_iqtcp_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu IQ (Narrowband TCP)
    
    Parameters:
    -----------
    filename : str
        Đường dẫn đến file H5 cần đọc
        
    Returns:
    --------
    data : dict
        Dictionary chứa:
        - global_info: Attributes trực tiếp từ /attribute
        - ddc_info: Attributes từ /attribute/ddc
        - request_info: Attributes từ /attribute/request
        - sessions: List các dict chứa id, i, q, và iq_complex
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f'File không tồn tại: {filename}')
    
    print('Đang phân tích cấu trúc file... ', end='', flush=True)
    
    data = {}
    
    with h5py.File(filename, 'r') as f:
        # 1. ĐỌC METADATA (Nested Attributes)
        try:
            if 'attribute' in f:
                attr_group = f['attribute']
                
                # A. Đọc attributes trực tiếp tại /attribute -> data.global_info
                data['global_info'] = _read_attributes(attr_group)
                
                # B. Đọc các group con (ddc, request, label...) -> data.{name}_info
                for sub_name in attr_group.keys():
                    sub_group = attr_group[sub_name]
                    
                    # Tạo tên field: ddc -> ddc_info, request -> request_info
                    if sub_name.endswith('_info'):
                        field_name = sub_name
                    else:
                        field_name = f"{sub_name}_info"
                    
                    # Đọc attributes của group con
                    data[field_name] = _read_attributes(sub_group)
                    
                    # C. Kiểm tra nếu có Dataset bên trong (ví dụ: /attribute/request/label)
                    for ds_name in sub_group.keys():
                        if isinstance(sub_group[ds_name], h5py.Dataset):
                            try:
                                val = sub_group[ds_name][()]
                                # Xử lý string
                                if isinstance(val, bytes):
                                    val = val.decode('utf-8').strip()
                                elif isinstance(val, np.ndarray) and val.dtype.kind == 'S':
                                    val = val.item().decode('utf-8').strip() if val.size == 1 else val
                                data[field_name][ds_name] = val
                            except Exception:
                                pass
        except Exception as e:
            print(f'\nCảnh báo: Lỗi đọc metadata: {e}')
        
        # 2. ĐỌC DỮ LIỆU IQ SESSION
        if 'session' not in f:
            data['sessions'] = []
            print('Xong.')
            return data
        
        session_group = f['session']
        session_keys = sorted(session_group.keys())
        num_sessions = len(session_keys)
        
        print('Xong.')
        print(f'Tìm thấy {num_sessions} sessions. Đang đọc dữ liệu I/Q...')
        
        data['sessions'] = []
        
        for idx, session_id in enumerate(session_keys):
            session_path = f'session/{session_id}'
            session_data = {
                'id': session_id,
                'i': None,
                'q': None,
                'iq': None
            }
            
            # Đọc dataset 'i'
            i_path = f'{session_path}/i'
            if 'i' in session_group[session_id]:
                try:
                    raw_i = session_group[session_id]['i'][:]
                    # Đảm bảo là vector cột
                    if raw_i.ndim > 1 and raw_i.shape[0] == 1:
                        raw_i = raw_i.flatten()
                    session_data['i'] = raw_i
                except Exception:
                    session_data['i'] = np.array([])
            
            # Đọc dataset 'q'
            q_path = f'{session_path}/q'
            if 'q' in session_group[session_id]:
                try:
                    raw_q = session_group[session_id]['q'][:]
                    # Đảm bảo là vector cột
                    if raw_q.ndim > 1 and raw_q.shape[0] == 1:
                        raw_q = raw_q.flatten()
                    session_data['q'] = raw_q
                except Exception:
                    session_data['q'] = np.array([])
            
            # Tạo dữ liệu phức (Complex) để tiện xử lý: I + jQ
            if session_data['i'] is not None and session_data['q'] is not None:
                if len(session_data['i']) > 0 and len(session_data['q']) > 0:
                    # Convert sang float64 để tính toán chính xác
                    session_data['iq'] = session_data['i'].astype(np.float64) + 1j * session_data['q'].astype(np.float64)
            
            data['sessions'].append(session_data)
            
            if (idx + 1) % 100 == 0:
                print(f'  Đã đọc {idx + 1}/{num_sessions} sessions...', end='\r')
        
        print(f'\nHoàn thành. Đã đọc {num_sessions} sessions.')
    
    return data


def _read_attributes(group: h5py.Group) -> Dict[str, Any]:
    """
    Đọc tất cả attributes của một group
    
    Parameters:
    -----------
    group : h5py.Group
        Group cần đọc attributes
        
    Returns:
    --------
    attrs_dict : dict
        Dictionary chứa tất cả attributes
    """
    attrs_dict = {}
    
    for attr_name in group.attrs.keys():
        try:
            val = group.attrs[attr_name]
            # Xử lý các kiểu dữ liệu khác nhau
            if isinstance(val, bytes):
                val = val.decode('utf-8')
            elif isinstance(val, np.ndarray):
                if val.size == 1:
                    val = val.item()
                    if isinstance(val, bytes):
                        val = val.decode('utf-8')
                elif val.dtype.kind == 'S':  # String array
                    val = val.astype(str)
            attrs_dict[attr_name] = val
        except Exception:
            pass
    
    return attrs_dict


if __name__ == '__main__':
    # Test với file iqtcp.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/iqtcp.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_iqtcp_h5(filename)
        
        print('\n==================================================')
        print(' THÔNG TIN TỔNG QUAN')
        print('==================================================')
        print(f'Số sessions: {len(all_data.get("sessions", []))}')
        print(f'Có global_info: {"global_info" in all_data}')
        print(f'Có ddc_info: {"ddc_info" in all_data}')
        print(f'Có request_info: {"request_info" in all_data}')
        
        if all_data.get('sessions'):
            first_session = all_data['sessions'][0]
            print(f'\nSession đầu tiên (ID: {first_session["id"]}):')
            if first_session['i'] is not None:
                print(f'  - I: shape={first_session["i"].shape}, dtype={first_session["i"].dtype}')
            if first_session['q'] is not None:
                print(f'  - Q: shape={first_session["q"].shape}, dtype={first_session["q"].dtype}')
            if first_session['iq'] is not None:
                print(f'  - IQ: shape={first_session["iq"].shape}, dtype={first_session["iq"].dtype}')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


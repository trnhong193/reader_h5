"""
Reader for Demodulation H5 files
Based on MATLAB code: reader_demodulation_no_recursive.m

This module reads HDF5 files containing demodulation IQ data with the following structure:
- /attribute/request: Contains configuration metadata (hwConfiguration, libConfiguration, etc.)
- /session: Contains multiple sessions, each with 'i' and 'q' datasets

Output:
    data['request']: Dictionary of request sub-groups with attributes
    data['sessions']: List of session dictionaries
        data['sessions'][i]: Dictionary containing:
            - 'id': Session ID
            - 'iq': Complex numpy array (I + j*Q)
"""

import h5py
import numpy as np
import os
from typing import Dict, List, Any, Optional


def read_demodulation_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu Demodulation (IQ)
    
    Parameters:
    -----------
    filename : str
        Đường dẫn đến file H5 cần đọc
        
    Returns:
    --------
    data : dict
        Dictionary chứa:
        - request: Request configuration attributes
        - sessions: List các session dictionaries với IQ data
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f'File không tồn tại: {filename}')
    
    print(f'Reading file info: {filename} ... ', end='', flush=True)
    
    data = {}
    
    with h5py.File(filename, 'r') as f:
        print('Done.')
        
        # PHẦN 1: ĐỌC METADATA (/attribute/request)
        print('1. Reading Configuration (/attribute)...')
        
        if 'attribute' in f:
            attr_group = f['attribute']
            
            # Tìm '/attribute/request'
            if 'request' in attr_group:
                req_group = attr_group['request']
                data['request'] = {}
                
                # Duyệt qua các sub-groups của request (hwConfiguration, source, etc.)
                for sub_name in req_group.keys():
                    sub_group = req_group[sub_name]
                    if isinstance(sub_group, h5py.Group):
                        safe_name = _make_valid_name(sub_name)
                        # Đọc attributes của sub-group
                        data['request'][safe_name] = _read_attributes(sub_group)
        
        # PHẦN 2: ĐỌC SESSION DATA (/session)
        print('2. Reading Session Data (IQ)...')
        
        if 'session' in f:
            session_group = f['session']
            session_keys = sorted(session_group.keys())
            num_sess = len(session_keys)
            
            print(f'   Found {num_sess} sessions.')
            data['sessions'] = []
            
            for idx, session_id in enumerate(session_keys):
                session_path = f'session/{session_id}'
                session_data = {}
                
                # 1. Lưu Session ID
                session_data['id'] = session_id
                
                # 2. Đọc 'i' và 'q' datasets
                try:
                    # Đọc raw data
                    if 'i' in session_group[session_id] and 'q' in session_group[session_id]:
                        raw_i = session_group[session_id]['i'][:]
                        raw_q = session_group[session_id]['q'][:]
                        
                        # Convert sang double
                        val_i = raw_i.astype(np.float64)
                        val_q = raw_q.astype(np.float64)
                        
                        # Đảm bảo là 1D array (column vector)
                        if val_i.ndim > 1:
                            val_i = val_i.flatten()
                        if val_q.ndim > 1:
                            val_q = val_q.flatten()
                        
                        # Kết hợp thành Complex
                        len_min = min(len(val_i), len(val_q))
                        session_data['iq'] = val_i[:len_min] + 1j * val_q[:len_min]
                    else:
                        session_data['iq'] = np.array([], dtype=np.complex128)
                except Exception:
                    session_data['iq'] = np.array([], dtype=np.complex128)
                
                data['sessions'].append(session_data)
                
                if (idx + 1) % 100 == 0:
                    print(f'   Đã xử lý {idx + 1}/{num_sess} sessions...', end='\r')
        else:
            print('   Warning: No /session group found.')
            data['sessions'] = []
        
        print(f'\nRead complete.')
    
    return data


def _make_valid_name(name: str) -> str:
    """
    Tạo tên hợp lệ cho Python (tương tự matlab.lang.makeValidName)
    """
    import re
    # Thay thế các ký tự không hợp lệ
    name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    # Đảm bảo không bắt đầu bằng số
    if name and name[0].isdigit():
        name = '_' + name
    return name


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
                    if val.size == 1:
                        val = val.item()
            attrs_dict[_make_valid_name(attr_name)] = val
        except Exception:
            pass
    
    return attrs_dict


if __name__ == '__main__':
    # Test với file demodulation.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/demodulation.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_demodulation_h5(filename)
        
        print('\n==================================================')
        print(' THÔNG TIN TỔNG QUAN')
        print('==================================================')
        print(f'Có request: {"request" in all_data}')
        print(f'Số sessions: {len(all_data.get("sessions", []))}')
        
        # Request
        if 'request' in all_data and all_data['request']:
            print('\nRequest (một số sub-groups):')
            for i, (key, value) in enumerate(all_data['request'].items()):
                if i >= 5:
                    print('  ...')
                    break
                print(f'  {key}: {len(value)} attributes')
        
        # Sessions
        if all_data.get('sessions'):
            first_session = all_data['sessions'][0]
            print(f'\nSession đầu tiên ({first_session.get("id", "N/A")}):')
            if 'iq' in first_session and len(first_session['iq']) > 0:
                iq_data = first_session['iq']
                print(f'  - IQ data: {len(iq_data)} samples, dtype={iq_data.dtype}')
                print(f'  - I (real): Min={iq_data.real.min():.2f}, Max={iq_data.real.max():.2f}, Mean={iq_data.real.mean():.2f}')
                print(f'  - Q (imag): Min={iq_data.imag.min():.2f}, Max={iq_data.imag.max():.2f}, Mean={iq_data.imag.mean():.2f}')
                print(f'  - Magnitude: Min={np.abs(iq_data).min():.2f}, Max={np.abs(iq_data).max():.2f}')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


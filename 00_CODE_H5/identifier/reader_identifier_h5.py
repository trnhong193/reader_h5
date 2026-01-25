"""
Reader for Identifier H5 files
Based on MATLAB code: read_identifier.m

This module reads HDF5 files containing identifier data with the following structure:
- /attribute/estm_bdw: Contains hop parameters (datasets: fc, ...)
- /attribute/request/label: Contains label text (dataset)
- /attribute/doa/position: Contains DOA position datasets (vecDoas, ...)
- /attribute/doa/identity/features: Contains identity feature datasets (meanBws, meanFcs, ...)
- /session: Contains multiple sessions, each with 'iq' dataset (interleaved I, Q, I, Q...)

Output:
    data['estm_bdw']: Dictionary of hop parameter datasets
    data['request']['label']: Parsed label dictionary
    data['doa']['position']: Dictionary of position datasets
    data['doa']['identity']['features']: Dictionary of identity feature datasets
    data['sessions']: List of session dictionaries
        data['sessions'][i]: Dictionary containing:
            - 'id': Session ID
            - 'iq': Complex numpy array (from interleaved I, Q, I, Q...)
"""

import h5py
import numpy as np
import os
from typing import Dict, List, Any, Optional


def read_identifier_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu Identifier
    
    Parameters:
    -----------
    filename : str
        Đường dẫn đến file H5 cần đọc
        
    Returns:
    --------
    data : dict
        Dictionary chứa:
        - estm_bdw: Hop parameters
        - request: Request info (label)
        - doa: DOA data (position, identity)
        - sessions: List các session dictionaries với IQ data
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f'File không tồn tại: {filename}')
    
    print('Đang đọc thông tin file... ', end='', flush=True)
    
    data = {}
    
    with h5py.File(filename, 'r') as f:
        print('Xong.')
        
        # PHẦN 1: ĐỌC METADATA (/attribute)
        print('1. Đang đọc Metadata (/attribute)...')
        
        if 'attribute' in f:
            attr_group = f['attribute']
            
            # A. ĐỌC /attribute/estm_bdw (Tham số Hop)
            if 'estm_bdw' in attr_group:
                bdw_group = attr_group['estm_bdw']
                data['estm_bdw'] = _read_all_datasets(bdw_group)
            
            # B. ĐỌC /attribute/request (Label)
            if 'request' in attr_group:
                req_group = attr_group['request']
                data['request'] = {}
                
                # Tìm dataset 'label'
                if 'label' in req_group:
                    try:
                        raw_label = req_group['label'][:]
                        data['request']['label'] = _parse_label_text(raw_label)
                    except Exception:
                        pass
            
            # C. ĐỌC /attribute/doa (Deep nesting)
            if 'doa' in attr_group:
                doa_group = attr_group['doa']
                data['doa'] = {}
                
                # Đọc Position (vecDoas)
                if 'position' in doa_group:
                    pos_group = doa_group['position']
                    data['doa']['position'] = _read_all_datasets(pos_group)
                
                # Đọc Identity (Features)
                if 'identity' in doa_group:
                    id_group = doa_group['identity']
                    if 'features' in id_group:
                        feat_group = id_group['features']
                        data['doa']['identity'] = {}
                        data['doa']['identity']['features'] = _read_all_datasets(feat_group)
        
        # PHẦN 2: ĐỌC SESSION (/session)
        print('2. Đang đọc Sessions (IQ Data)...')
        
        if 'session' in f:
            session_group = f['session']
            session_keys = sorted(session_group.keys())
            num_sess = len(session_keys)
            
            print(f'   Tìm thấy {num_sess} sessions.')
            data['sessions'] = []
            
            for idx, session_id in enumerate(session_keys):
                session_path = f'session/{session_id}'
                session_data = {}
                
                # 1. Lưu Session ID
                session_data['id'] = session_id
                
                # 2. Đọc dataset 'iq' (xen kẽ I, Q, I, Q...)
                try:
                    if 'iq' in session_group[session_id]:
                        raw_iq = session_group[session_id]['iq'][:]
                        session_data['iq'] = _process_iq_interleaved(raw_iq)
                    else:
                        session_data['iq'] = np.array([], dtype=np.complex128)
                except Exception:
                    session_data['iq'] = np.array([], dtype=np.complex128)
                
                data['sessions'].append(session_data)
                
                if (idx + 1) % 100 == 0:
                    print(f'   Đã xử lý {idx + 1}/{num_sess} sessions...', end='\r')
        else:
            print('   Warning: Không tìm thấy group /session')
            data['sessions'] = []
        
        print(f'\nHoàn thành.')
    
    return data


def _read_all_datasets(group: h5py.Group) -> Dict[str, Any]:
    """
    Đọc tất cả datasets trong một group
    
    Parameters:
    -----------
    group : h5py.Group
        Group cần đọc datasets
        
    Returns:
    --------
    datasets_dict : dict
        Dictionary chứa tất cả datasets
    """
    datasets_dict = {}
    
    def visit_datasets(name, obj):
        if isinstance(obj, h5py.Dataset):
            try:
                val = obj[:]
                # Chuyển row vector -> column vector nếu cần
                if isinstance(val, np.ndarray) and val.ndim == 1 and len(val) > 1:
                    # Giữ nguyên dạng cột
                    pass
                elif isinstance(val, np.ndarray) and val.ndim == 2 and val.shape[0] == 1:
                    # Row vector -> column vector
                    val = val.T
                datasets_dict[_make_valid_name(name)] = val
            except Exception:
                pass
    
    if isinstance(group, h5py.Group):
        group.visititems(visit_datasets)
    
    return datasets_dict


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


def _process_iq_interleaved(raw: np.ndarray) -> np.ndarray:
    """
    Xử lý IQ xen kẽ [I, Q, I, Q...] -> Số phức
    
    Parameters:
    -----------
    raw : np.ndarray
        Raw data (interleaved I, Q, I, Q...)
        
    Returns:
    --------
    iq : np.ndarray
        Complex IQ array
    """
    if not isinstance(raw, np.ndarray):
        return np.array([], dtype=np.complex128)
    
    # Đảm bảo là 1D array
    if raw.ndim > 1:
        raw = raw.flatten()
    
    # Cắt lẻ nếu cần
    if len(raw) % 2 != 0:
        raw = raw[:-1]
    
    if len(raw) == 0:
        return np.array([], dtype=np.complex128)
    
    # Tách I và Q
    i_data = raw[0::2].astype(np.float64)  # Lấy các phần tử chẵn (I)
    q_data = raw[1::2].astype(np.float64)  # Lấy các phần tử lẻ (Q)
    
    # Kết hợp thành complex
    return i_data + 1j * q_data


def _parse_label_text(raw) -> Dict[str, Any]:
    """
    Parse label text thành dictionary
    
    Parameters:
    -----------
    raw : bytes, str, or array
        Raw label data
        
    Returns:
    --------
    label_dict : dict
        Dictionary chứa parsed label
    """
    label_dict = {}
    
    # Xử lý các kiểu dữ liệu khác nhau
    if isinstance(raw, bytes):
        text = raw.decode('utf-8')
        lines = text.split('\n')
    elif isinstance(raw, str):
        lines = raw.split('\n')
    elif isinstance(raw, np.ndarray):
        if raw.dtype.kind == 'S':  # String array
            lines = [item.decode('utf-8') if isinstance(item, bytes) else str(item) 
                    for item in raw.flatten()]
        else:
            return label_dict
    else:
        return label_dict
    
    # Parse từng dòng
    for k, line in enumerate(lines):
        txt = line.strip()
        if not txt:
            continue
        
        if '=' in txt:
            parts = txt.split('=', 1)
            key = _make_valid_name(parts[0].strip())
            value = parts[1].strip() if len(parts) > 1 else ''
            label_dict[key] = value
        else:
            label_dict[f'line_{k+1}'] = txt
    
    return label_dict


if __name__ == '__main__':
    # Test với file identifier.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/identifier.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_identifier_h5(filename)
        
        print('\n==================================================')
        print(' THÔNG TIN TỔNG QUAN')
        print('==================================================')
        print(f'Có estm_bdw: {"estm_bdw" in all_data}')
        print(f'Có request: {"request" in all_data}')
        print(f'Có doa: {"doa" in all_data}')
        print(f'Số sessions: {len(all_data.get("sessions", []))}')
        
        # estm_bdw
        if 'estm_bdw' in all_data and all_data['estm_bdw']:
            print('\nestm_bdw (một số datasets):')
            for i, (key, value) in enumerate(all_data['estm_bdw'].items()):
                if i >= 3:
                    print('  ...')
                    break
                if isinstance(value, np.ndarray):
                    print(f'  {key}: shape={value.shape}, dtype={value.dtype}')
        
        # request label
        if 'request' in all_data and 'label' in all_data['request']:
            print('\nrequest.label:')
            label = all_data['request']['label']
            for i, (key, value) in enumerate(list(label.items())[:5]):
                print(f'  {key}: {value}')
        
        # doa
        if 'doa' in all_data:
            print('\ndoa:')
            if 'position' in all_data['doa']:
                print(f'  position: {len(all_data["doa"]["position"])} datasets')
            if 'identity' in all_data['doa'] and 'features' in all_data['doa']['identity']:
                print(f'  identity.features: {len(all_data["doa"]["identity"]["features"])} datasets')
        
        # Sessions
        if all_data.get('sessions'):
            first_session = all_data['sessions'][0]
            print(f'\nSession đầu tiên ({first_session.get("id", "N/A")}):')
            if 'iq' in first_session and len(first_session['iq']) > 0:
                iq_data = first_session['iq']
                print(f'  - IQ data: {len(iq_data)} samples, dtype={iq_data.dtype}')
                print(f'  - I (real): Min={iq_data.real.min():.2f}, Max={iq_data.real.max():.2f}')
                print(f'  - Q (imag): Min={iq_data.imag.min():.2f}, Max={iq_data.imag.max():.2f}')
                print(f'  - Magnitude: Min={np.abs(iq_data).min():.2f}, Max={np.abs(iq_data).max():.2f}')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


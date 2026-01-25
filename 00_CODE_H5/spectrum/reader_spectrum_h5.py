"""
Reader for Spectrum H5 files
Based on MATLAB code: read_spectrum_data.m

This module reads HDF5 files containing spectrum data with the following structure:
- /attribute: Contains metadata (global_info)
- /session: Contains multiple sessions, each with:
    - Attributes (timestamp, freq, bw, ...)
    - /source: Sub-group with source device info
    - /sample_decoded: Dataset containing decoded spectrum samples

Output:
    data['global_info']: Attributes from /attribute
    data['sessions']: List of session dictionaries
        data['sessions'][i]: Dictionary containing:
            - 'id': Session ID (e.g., '000xx')
            - 'attributes': Dictionary of session attributes
            - 'source_info': Dictionary of source device info
            - 'samples': numpy array of decoded samples
"""

import h5py
import numpy as np
import os
from typing import Dict, List, Any, Optional


def read_spectrum_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu Spectrum
    
    Parameters:
    -----------
    filename : str
        Đường dẫn đến file H5 cần đọc
        
    Returns:
    --------
    data : dict
        Dictionary chứa:
        - global_info: Attributes từ /attribute
        - sessions: List các session dictionaries
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f'File không tồn tại: {filename}')
    
    print('Đang phân tích cấu trúc file... ', end='', flush=True)
    
    data = {}
    
    with h5py.File(filename, 'r') as f:
        # 1. ĐỌC GLOBAL METADATA
        data['global_info'] = {}
        try:
            if 'attribute' in f:
                attr_group = f['attribute']
                # Đọc attributes trực tiếp tại /attribute
                data['global_info'].update(_read_attributes(attr_group))
        except Exception as e:
            print(f'\nCảnh báo: Lỗi đọc Global Metadata: {e}')
            data['global_info'] = {}
        
        # 2. ĐỌC SESSIONS
        if 'session' not in f:
            data['sessions'] = []
            print('Xong.')
            return data
        
        session_group = f['session']
        session_keys = sorted(session_group.keys())
        num_sessions = len(session_keys)
        
        print('Xong.')
        print(f'Tìm thấy {num_sessions} sessions. Đang đọc...')
        
        data['sessions'] = []
        
        for idx, session_id in enumerate(session_keys):
            session_path = f'session/{session_id}'
            session_data = {}
            
            # 1. Lưu Session ID
            session_data['id'] = session_id
            
            # 2. Đọc Session Attributes
            try:
                session_attrs = _read_attributes(session_group[session_id])
                session_data['attributes'] = session_attrs
            except Exception:
                session_data['attributes'] = {}
            
            # 3. Đọc Source Info
            session_data['source_info'] = {}
            try:
                if 'source' in session_group[session_id]:
                    source_group = session_group[session_id]['source']
                    session_data['source_info'] = _read_attributes(source_group)
            except Exception:
                pass
            
            # 4. Đọc Sample Decoded
            session_data['samples'] = np.array([], dtype=np.float64)
            try:
                if 'sample_decoded' in session_group[session_id]:
                    samples = session_group[session_id]['sample_decoded'][:]
                    # Đảm bảo là 1D array (column vector)
                    if samples.ndim > 1:
                        samples = samples.flatten()
                    session_data['samples'] = samples.astype(np.float64)
            except Exception as e:
                pass
            
            data['sessions'].append(session_data)
            
            if (idx + 1) % 100 == 0:
                print(f'  Đã xử lý {idx + 1}/{num_sessions} sessions...', end='\r')
        
        print(f'\nHoàn thành. Đã xử lý {num_sessions} sessions.')
    
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
                    if val.size == 1:
                        val = val.item()
            attrs_dict[attr_name] = val
        except Exception:
            pass
    
    return attrs_dict


if __name__ == '__main__':
    # Test với file spectrum.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/spectrum.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_spectrum_h5(filename)
        
        print('\n==================================================')
        print(' THÔNG TIN TỔNG QUAN')
        print('==================================================')
        print(f'Có global_info: {"global_info" in all_data}')
        print(f'Số sessions: {len(all_data.get("sessions", []))}')
        
        if 'global_info' in all_data and all_data['global_info']:
            print('\nGlobal Info (một số trường):')
            for i, (key, value) in enumerate(all_data['global_info'].items()):
                if i >= 5:  # Chỉ hiển thị 5 trường đầu
                    print('  ...')
                    break
                if isinstance(value, (str, int, float)):
                    print(f'  {key}: {value}')
        
        if all_data.get('sessions'):
            first_session = all_data['sessions'][0]
            print(f'\nSession đầu tiên ({first_session.get("id", "N/A")}):')
            print(f'  - Có attributes: {bool(first_session.get("attributes"))}')
            print(f'  - Có source_info: {bool(first_session.get("source_info"))}')
            if 'samples' in first_session and len(first_session['samples']) > 0:
                samples = first_session['samples']
                print(f'  - Samples: {len(samples)} điểm, dtype={samples.dtype}')
                print(f'  - Min: {samples.min():.2f}, Max: {samples.max():.2f}, Mean: {samples.mean():.2f}')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


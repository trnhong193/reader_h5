"""
Reader for Histogram H5 files
Based on MATLAB code: read_histogram_h5_multitype.m

This module reads HDF5 files containing histogram data with the following structure:
- /attribute: Contains metadata (global_info)
- /session: Contains multiple sessions, each with:
    - Attributes (including message_type)
    - /context: Sub-group with context info
    - /source: Sub-group with source device info
    - Dataset depends on message_type:
        - AccumulatedPower: 'sample_decoded'
        - CrossingThresholdPower: 'acc_sample_decoded' AND 'crx_sample_decoded'

Output:
    data['global_info']: Attributes from /attribute
    data['sessions']: List of session dictionaries
        data['sessions'][i]: Dictionary containing:
            - 'id': Session ID
            - 'type': Message type string
            - 'attributes': Dictionary of session attributes
            - 'context_info': Dictionary of context info
            - 'source_info': Dictionary of source device info
            - 'sample_decoded': numpy array (for AccumulatedPower)
            - 'acc_sample_decoded': numpy array (for CrossingThresholdPower)
            - 'crx_sample_decoded': numpy array (for CrossingThresholdPower)
"""

import h5py
import numpy as np
import os
from typing import Dict, List, Any, Optional


def read_histogram_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu Histogram (hỗ trợ nhiều loại message)
    
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
        print(f'Tìm thấy {num_sessions} sessions. Đang đọc dữ liệu...')
        
        data['sessions'] = []
        
        for idx, session_id in enumerate(session_keys):
            session_path = f'session/{session_id}'
            session_data = {}
            
            # 1. Lưu Session ID
            session_data['id'] = session_id
            
            # 2. Đọc Session Attributes (để lấy message_type)
            session_attrs = {}
            msg_type_str = ''  # Mặc định
            try:
                session_attrs = _read_attributes(session_group[session_id])
                # Lưu riêng message_type để xử lý logic
                if 'message_type' in session_attrs:
                    msg_type_val = session_attrs['message_type']
                    if isinstance(msg_type_val, bytes):
                        msg_type_str = msg_type_val.decode('utf-8')
                    elif isinstance(msg_type_val, str):
                        msg_type_str = msg_type_val
                    else:
                        msg_type_str = str(msg_type_val)
            except Exception:
                pass
            
            session_data['attributes'] = session_attrs
            session_data['type'] = msg_type_str
            
            # 3. XỬ LÝ LOGIC ĐỌC DỮ LIỆU DỰA TRÊN MESSAGE TYPE
            # Khởi tạo các trường dữ liệu
            session_data['sample_decoded'] = np.array([], dtype=np.float64)
            session_data['acc_sample_decoded'] = np.array([], dtype=np.float64)
            session_data['crx_sample_decoded'] = np.array([], dtype=np.float64)
            
            try:
                if 'CrossingThresholdPower' in msg_type_str:
                    # TRƯỜNG HỢP 1: Crossing Threshold Power
                    # Đọc acc_sample_decoded
                    try:
                        if 'acc_sample_decoded' in session_group[session_id]:
                            acc_data = session_group[session_id]['acc_sample_decoded'][:]
                            if acc_data.ndim > 1:
                                acc_data = acc_data.flatten()
                            session_data['acc_sample_decoded'] = acc_data.astype(np.float64)
                    except Exception:
                        pass
                    
                    # Đọc crx_sample_decoded
                    try:
                        if 'crx_sample_decoded' in session_group[session_id]:
                            crx_data = session_group[session_id]['crx_sample_decoded'][:]
                            if crx_data.ndim > 1:
                                crx_data = crx_data.flatten()
                            session_data['crx_sample_decoded'] = crx_data.astype(np.float64)
                    except Exception:
                        pass
                else:
                    # TRƯỜNG HỢP 2: AccumulatedPower (hoặc mặc định)
                    # Đọc sample_decoded
                    try:
                        if 'sample_decoded' in session_group[session_id]:
                            samp_data = session_group[session_id]['sample_decoded'][:]
                            if samp_data.ndim > 1:
                                samp_data = samp_data.flatten()
                            session_data['sample_decoded'] = samp_data.astype(np.float64)
                        else:
                            # Fallback: thử đọc acc_sample_decoded
                            if 'acc_sample_decoded' in session_group[session_id]:
                                acc_data = session_group[session_id]['acc_sample_decoded'][:]
                                if acc_data.ndim > 1:
                                    acc_data = acc_data.flatten()
                                session_data['sample_decoded'] = acc_data.astype(np.float64)
                    except Exception:
                        pass
            except Exception:
                pass
            
            # 4. Đọc Context Info
            session_data['context_info'] = {}
            try:
                if 'context' in session_group[session_id]:
                    context_group = session_group[session_id]['context']
                    session_data['context_info'] = _read_attributes(context_group)
            except Exception:
                pass
            
            # 5. Đọc Source Info
            session_data['source_info'] = {}
            try:
                if 'source' in session_group[session_id]:
                    source_group = session_group[session_id]['source']
                    session_data['source_info'] = _read_attributes(source_group)
            except Exception:
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
    # Test với file histogram.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/histogram.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_histogram_h5(filename)
        
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
            # Tìm session có dữ liệu
            first_session = None
            for sess in all_data['sessions']:
                if (len(sess.get('sample_decoded', [])) > 0 or 
                    len(sess.get('acc_sample_decoded', [])) > 0 or
                    len(sess.get('crx_sample_decoded', [])) > 0):
                    first_session = sess
                    break
            
            if first_session is None:
                first_session = all_data['sessions'][0]
            
            print(f'\nSession đầu tiên có dữ liệu ({first_session.get("id", "N/A")}):')
            print(f'  - Type: {first_session.get("type", "N/A")}')
            print(f'  - Có attributes: {bool(first_session.get("attributes"))}')
            print(f'  - Có context_info: {bool(first_session.get("context_info"))}')
            print(f'  - Có source_info: {bool(first_session.get("source_info"))}')
            
            if len(first_session.get('sample_decoded', [])) > 0:
                samples = first_session['sample_decoded']
                print(f'  - sample_decoded: {len(samples)} điểm, dtype={samples.dtype}')
                print(f'    Min: {samples.min():.2e}, Max: {samples.max():.2e}, Sum: {samples.sum():.2e}')
            
            if len(first_session.get('acc_sample_decoded', [])) > 0:
                acc_samples = first_session['acc_sample_decoded']
                print(f'  - acc_sample_decoded: {len(acc_samples)} điểm, dtype={acc_samples.dtype}')
                print(f'    Min: {acc_samples.min():.2e}, Max: {acc_samples.max():.2e}, Sum: {acc_samples.sum():.2e}')
            
            if len(first_session.get('crx_sample_decoded', [])) > 0:
                crx_samples = first_session['crx_sample_decoded']
                print(f'  - crx_sample_decoded: {len(crx_samples)} điểm, dtype={crx_samples.dtype}')
                print(f'    Min: {crx_samples.min():.2e}, Max: {crx_samples.max():.2e}, Sum: {crx_samples.sum():.2e}')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


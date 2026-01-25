"""
Reader for DF (Direction Finding) H5 files
Based on MATLAB code: reader_df.m

This module reads HDF5 files containing DF/DOA data with the following structure:
- /attribute/configuration: Contains configuration attributes (antParams, filterParams...)
- /attribute/calibration/calibs: Contains calibration datasets (pow1, dps...) in tables (0, 1, 2...)
- /session: Contains multiple sessions, each with:
    - Pulse datasets (amp, fc, bw...)
    - DOA data in nested structure: /doa/doa/0,1,2... with position, velocity, identity

Output:
    data['configuration']: Dictionary of configuration sub-groups with attributes
    data['calibration']: Dictionary of calibration tables (Table_0, Table_1...) with datasets
    data['sessions']: List of session dictionaries
        data['sessions'][i]: Dictionary containing:
            - 'id': Session ID
            - 'pulses': Dictionary of pulse datasets
            - 'doa': Dictionary of DOA targets (Target_0, Target_1...)
                - Each target has: position, velocity, identity_features
"""

import h5py
import numpy as np
import os
from typing import Dict, List, Any, Optional


def read_df_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu DF/DOA
    
    Parameters:
    -----------
    filename : str
        Đường dẫn đến file H5 cần đọc
        
    Returns:
    --------
    data : dict
        Dictionary chứa:
        - configuration: Configuration attributes
        - calibration: Calibration datasets
        - sessions: List các session dictionaries
    """
    if not os.path.isfile(filename):
        raise FileNotFoundError(f'File không tồn tại: {filename}')
    
    print(f'Đang quét file: {filename} ... ', end='', flush=True)
    
    data = {}
    
    with h5py.File(filename, 'r') as f:
        print('Xong.')
        
        # PHẦN 1: ĐỌC ATTRIBUTE & CALIBRATION
        print('1. Đang đọc Cấu hình & Hiệu chuẩn...')
        
        if 'attribute' in f:
            attr_group = f['attribute']
            
            # A. ĐỌC CONFIGURATION (antParams, filterParams...)
            if 'configuration' in attr_group:
                conf_group = attr_group['configuration']
                data['configuration'] = {}
                
                for sub_name in conf_group.keys():
                    sub_group = conf_group[sub_name]
                    if isinstance(sub_group, h5py.Group):
                        valid_name = _make_valid_name(sub_name)
                        data['configuration'][valid_name] = _read_attributes(sub_group)
            
            # B. ĐỌC CALIBRATION (calibs -> 0, 1, 2...)
            if 'calibration' in attr_group:
                cal_main = attr_group['calibration']
                if 'calibs' in cal_main:
                    calibs_group = cal_main['calibs']
                    data['calibration'] = {}
                    
                    # Duyệt qua các folder 0, 1, 2
                    for sub_name in sorted(calibs_group.keys()):
                        sub_group = calibs_group[sub_name]
                        if isinstance(sub_group, h5py.Group):
                            valid_name = f'Table_{sub_name}'  # Table_0, Table_1
                            data['calibration'][valid_name] = _read_datasets(sub_group)
        
        # PHẦN 2: ĐỌC SESSION & DEEP DOA
        print('2. Đang đọc Session & DOA Data...')
        
        if 'session' in f:
            session_group = f['session']
            session_keys = sorted(session_group.keys())
            num_sess = len(session_keys)
            
            print(f'   Tìm thấy {num_sess} sessions.')
            data['sessions'] = []
            
            for idx, session_id in enumerate(session_keys):
                session_path = f'session/{session_id}'
                session_data = {}
                
                # Lưu Session ID
                session_data['id'] = session_id
                
                # A. Đọc thông số xung (amp, fc, bw...) - Nằm ngay tại session
                session_data['pulses'] = _read_datasets(session_group[session_id])
                
                # B. Đọc DOA (Deep Structure: /doa/doa/0/...)
                doa_struct = {}
                
                try:
                    # B1. Vào folder /doa
                    if 'doa' in session_group[session_id]:
                        doa_g1 = session_group[session_id]['doa']
                        
                        # B2. Vào tiếp folder /doa (doa lồng doa)
                        if 'doa' in doa_g1:
                            doa_g2 = doa_g1['doa']
                            
                            # B3. Duyệt qua các ID mục tiêu (0, 1, 2...)
                            for target_name in sorted(doa_g2.keys()):
                                target_group = doa_g2[target_name]
                                if isinstance(target_group, h5py.Group):
                                    t_id = f'Target_{target_name}'
                                    
                                    target_data = {}
                                    
                                    # Đọc Position (vecDoas)
                                    if 'position' in target_group:
                                        target_data['position'] = _read_datasets(target_group['position'])
                                    
                                    # Đọc Velocity (velocDoas)
                                    if 'velocity' in target_group:
                                        target_data['velocity'] = _read_datasets(target_group['velocity'])
                                    
                                    # Đọc Identity (Features -> meanBws...)
                                    if 'identity' in target_group:
                                        id_group = target_group['identity']
                                        if 'features' in id_group:
                                            target_data['identity_features'] = _read_datasets(id_group['features'])
                                    
                                    doa_struct[t_id] = target_data
                except Exception:
                    pass
                
                session_data['doa'] = doa_struct
                data['sessions'].append(session_data)
                
                if (idx + 1) % 100 == 0:
                    print(f'   Đã xử lý {idx + 1}/{num_sess} sessions...', end='\r')
        else:
            data['sessions'] = []
        
        print(f'\nHoàn thành.')
    
    return data


def _make_valid_name(name: str) -> str:
    """
    Tạo tên hợp lệ cho Python (tương tự matlab.lang.makeValidName)
    """
    # Thay thế các ký tự không hợp lệ
    import re
    # Loại bỏ hoặc thay thế các ký tự đặc biệt
    name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    # Đảm bảo không bắt đầu bằng số
    if name and name[0].isdigit():
        name = '_' + name
    return name


def _read_attributes(group: h5py.Group) -> Dict[str, Any]:
    """
    Đọc tất cả attributes của một group (dành cho Configuration)
    
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


def _read_datasets(group: h5py.Group) -> Dict[str, Any]:
    """
    Đọc tất cả datasets của một group (dành cho Calibration, Session, DOA)
    
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
                # Chuyển thành vector cột nếu là row vector
                if isinstance(val, np.ndarray) and val.ndim == 1 and len(val) > 1:
                    # Giữ nguyên dạng cột (không cần transpose vì Python mặc định là row)
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


if __name__ == '__main__':
    # Test với file df.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/df.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_df_h5(filename)
        
        print('\n==================================================')
        print(' THÔNG TIN TỔNG QUAN')
        print('==================================================')
        print(f'Có configuration: {"configuration" in all_data}')
        print(f'Có calibration: {"calibration" in all_data}')
        print(f'Số sessions: {len(all_data.get("sessions", []))}')
        
        # Configuration
        if 'configuration' in all_data and all_data['configuration']:
            print('\nConfiguration (một số trường):')
            for i, (key, value) in enumerate(all_data['configuration'].items()):
                if i >= 3:
                    print('  ...')
                    break
                print(f'  {key}: {type(value).__name__}')
                if isinstance(value, dict):
                    for sub_key in list(value.keys())[:3]:
                        print(f'    {sub_key}: ...')
        
        # Calibration
        if 'calibration' in all_data and all_data['calibration']:
            print('\nCalibration (một số bảng):')
            for i, (key, value) in enumerate(all_data['calibration'].items()):
                if i >= 2:
                    print('  ...')
                    break
                print(f'  {key}: {len(value)} datasets')
                for ds_name in list(value.keys())[:3]:
                    ds_val = value[ds_name]
                    if isinstance(ds_val, np.ndarray):
                        print(f'    {ds_name}: shape={ds_val.shape}, dtype={ds_val.dtype}')
        
        # Sessions
        if all_data.get('sessions'):
            first_session = all_data['sessions'][0]
            print(f'\nSession đầu tiên ({first_session.get("id", "N/A")}):')
            print(f'  - Có pulses: {bool(first_session.get("pulses"))}')
            print(f'  - Có doa: {bool(first_session.get("doa"))}')
            
            if first_session.get('pulses'):
                pulses = first_session['pulses']
                print(f'  - Pulses: {len(pulses)} datasets')
                for pulse_name in list(pulses.keys())[:3]:
                    pulse_val = pulses[pulse_name]
                    if isinstance(pulse_val, np.ndarray):
                        print(f'    {pulse_name}: shape={pulse_val.shape}, dtype={pulse_val.dtype}')
            
            if first_session.get('doa'):
                doa = first_session['doa']
                print(f'  - DOA: {len(doa)} targets')
                for target_name in list(doa.keys())[:2]:
                    target = doa[target_name]
                    print(f'    {target_name}:')
                    if 'position' in target:
                        print(f'      position: {len(target["position"])} datasets')
                    if 'velocity' in target:
                        print(f'      velocity: {len(target["velocity"])} datasets')
                    if 'identity_features' in target:
                        print(f'      identity_features: {len(target["identity_features"])} datasets')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


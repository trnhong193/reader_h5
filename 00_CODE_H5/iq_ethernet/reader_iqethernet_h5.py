"""
Reader for IQ Ethernet H5 files (Ethernet Packets - I/Q samples)
Based on MATLAB code: read_iq_ethernet_h5_verge.m

This module reads HDF5 files containing Ethernet IQ packets with the following structure:
- /attribute: Contains metadata (global_info, ddc_info, request_info, etc.)
- /session: Contains multiple sessions, each with 'raw' dataset containing Ethernet packet bytes

Output:
    data['global_info']: Attributes directly from /attribute and sub-groups
    data['streams']: Dictionary grouped by Stream ID
        data['streams']['Stream_X']: Dictionary containing:
            - 'packets': List of parsed packet dictionaries
            - 'all_iq': (Optional) Concatenated IQ data from all packets
"""

import h5py
import numpy as np
import os
import struct
from typing import Dict, List, Any, Optional


def read_iqethernet_h5(filename: str) -> Dict[str, Any]:
    """
    Đọc file H5 chứa dữ liệu IQ Ethernet (Ethernet Packets)
    
    Parameters:
    -----------
    filename : str
        Đường dẫn đến file H5 cần đọc
        
    Returns:
    --------
    data : dict
        Dictionary chứa:
        - global_info: Attributes từ /attribute và sub-groups
        - streams: Dictionary nhóm theo Stream ID
            - streams['Stream_X']: Dictionary chứa packets và all_iq
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
                
                # A. Đọc attributes trực tiếp tại /attribute
                data['global_info'].update(_read_attributes(attr_group))
                
                # B. Đọc các group con (ddc, request, ...)
                for sub_name in attr_group.keys():
                    sub_group = attr_group[sub_name]
                    if isinstance(sub_group, h5py.Group):
                        # Đọc attributes của group con
                        sub_attrs = _read_attributes(sub_group)
                        if sub_attrs:
                            data['global_info'][sub_name] = sub_attrs
        except Exception as e:
            print(f'\nCảnh báo: Lỗi đọc Global Metadata: {e}')
        
        # 2. ĐỌC VÀ PARSE DỮ LIỆU RAW THEO STREAM_ID
        if 'session' not in f:
            data['streams'] = {}
            print('Xong.')
            return data
        
        session_group = f['session']
        session_keys = sorted(session_group.keys())
        num_sessions = len(session_keys)
        
        print('Xong.')
        print(f'Tìm thấy {num_sessions} sessions (packets). Đang giải mã...')
        
        # Khởi tạo dictionary để chứa các Stream
        # Cấu trúc: stream_map[stream_id] = [packet1, packet2, ...]
        stream_map = {}
        
        for idx, session_id in enumerate(session_keys):
            session_path = f'session/{session_id}'
            
            # 1. Đọc Raw Data (uint8 array)
            try:
                if 'raw' not in session_group[session_id]:
                    continue
                raw_bytes = session_group[session_id]['raw'][:]
                # Đảm bảo là 1D array
                if raw_bytes.ndim > 1:
                    raw_bytes = raw_bytes.flatten()
                raw_bytes = raw_bytes.astype(np.uint8)
            except Exception:
                continue
            
            # 2. GIẢI MÃ GÓI TIN (THEO CẤU TRÚC STRUCT C++)
            # Header size = 40 bytes
            if len(raw_bytes) < 40:
                continue
            
            try:
                packet = _parse_ethernet_packet(raw_bytes)
                packet['h5_session_idx'] = idx  # Lưu lại index session để truy vết
            except Exception as e:
                continue
            
            # 3. GOM NHÓM THEO STREAM_ID
            sid = int(packet['stream_id'])
            
            if sid not in stream_map:
                stream_map[sid] = []
            stream_map[sid].append(packet)
            
            if (idx + 1) % 100 == 0:
                print(f'  Đã xử lý {idx + 1}/{num_sessions} packets...', end='\r')
        
        print(f'\nTổng hợp dữ liệu theo Stream ID...')
        
        # 4. CHUYỂN ĐỔI MAP SANG DICTIONARY DỄ DÙNG
        # Output sẽ là data['streams']['Stream_0'], data['streams']['Stream_1']...
        data['streams'] = {}
        
        for sid, packets in stream_map.items():
            field_name = f'Stream_{sid}'
            
            # Lưu danh sách packets
            data['streams'][field_name] = {
                'packets': packets
            }
            
            # Tùy chọn: Nối toàn bộ IQ data lại thành 1 chuỗi dài
            try:
                all_iq_list = []
                for pkt in packets:
                    if 'iq_data' in pkt and pkt['iq_data'] is not None and len(pkt['iq_data']) > 0:
                        all_iq_list.append(pkt['iq_data'])
                
                if all_iq_list:
                    data['streams'][field_name]['all_iq'] = np.concatenate(all_iq_list)
                else:
                    data['streams'][field_name]['all_iq'] = np.array([], dtype=np.complex128)
            except Exception:
                data['streams'][field_name]['all_iq'] = np.array([], dtype=np.complex128)
            
            print(f' -> {field_name}: {len(packets)} packets')
        
        print(f'Hoàn thành. Đã xử lý {num_sessions} packets, {len(stream_map)} streams.')
    
    return data


def _parse_ethernet_packet(bytes_array: np.ndarray) -> Dict[str, Any]:
    """
    Giải mã raw bytes thành cấu trúc Ethernet packet
    
    Cấu trúc Struct (Little Endian mặc định của x86/ARM):
    1. uint32 header       (bytes 0-3)
    2. uint32 stream_id    (bytes 4-7)
    3. uint64 timestamp    (bytes 8-15)
    4. uint64 frequency    (bytes 16-23)
    5. uint32 length       (bytes 24-27)
    6. uint32 bandwidth    (bytes 28-31)
    7. uint32 switch_id    (bytes 32-35)
    8. uint32 sample_count (bytes 36-39) -> reserved_0
    9. Data                (bytes 40-end)
    
    Parameters:
    -----------
    bytes_array : np.ndarray
        Mảng uint8 chứa raw bytes của packet
        
    Returns:
    --------
    packet : dict
        Dictionary chứa các trường đã giải mã
    """
    packet = {}
    
    # Sử dụng struct.unpack để chuyển đổi mảng byte sang số
    # Little Endian (<) cho x86/ARM
    
    # 1. uint32 header (bytes 0-3)
    packet['header'] = struct.unpack('<I', bytes_array[0:4])[0]
    
    # 2. uint32 stream_id (bytes 4-7)
    packet['stream_id'] = struct.unpack('<I', bytes_array[4:8])[0]
    
    # 3. uint64 timestamp (bytes 8-15)
    packet['timestamp'] = struct.unpack('<Q', bytes_array[8:16])[0]
    
    # 4. uint64 frequency (bytes 16-23)
    packet['frequency'] = struct.unpack('<Q', bytes_array[16:24])[0]
    
    # 5. uint32 length (bytes 24-27)
    packet['len'] = struct.unpack('<I', bytes_array[24:28])[0]
    
    # 6. uint32 bandwidth (bytes 28-31)
    packet['bandwidth'] = struct.unpack('<I', bytes_array[28:32])[0]
    
    # 7. uint32 switch_id (bytes 32-35)
    packet['switch_id'] = struct.unpack('<I', bytes_array[32:36])[0]
    
    # 8. uint32 sample_count (bytes 36-39)
    packet['sample_cnt'] = struct.unpack('<I', bytes_array[36:40])[0]
    
    # 9. GIẢI MÃ SAMPLES (IQ)
    raw_payload = bytes_array[40:]
    
    # Giả sử định dạng chuẩn là Int16 cho I và Q (2 byte mỗi mẫu)
    # Tổng cộng 4 bytes cho 1 cặp IQ
    bytes_per_sample = 4
    
    if bytes_per_sample == 4:
        # Trường hợp Int16 (2 byte I, 2 byte Q) - Phổ biến nhất cho Ethernet Packet
        if len(raw_payload) >= 4 and len(raw_payload) % 2 == 0:
            # Chuyển đổi sang int16 array
            iq_int16 = np.frombuffer(raw_payload.tobytes(), dtype=np.int16)
            
            # Dữ liệu thường xen kẽ: I, Q, I, Q...
            i_val = iq_int16[0::2].astype(np.float64)  # Lấy các phần tử chẵn (I)
            q_val = iq_int16[1::2].astype(np.float64)  # Lấy các phần tử lẻ (Q)
            
            packet['iq_data'] = i_val + 1j * q_val
        else:
            packet['iq_data'] = np.array([], dtype=np.complex128)
    else:
        # Trường hợp lạ, giữ nguyên rỗng
        packet['iq_data'] = np.array([], dtype=np.complex128)
    
    return packet


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
    # Test với file iqethernet.h5
    filename = '/home/tth193/Documents/h5_code/00_DATA_h5/iqethernet.h5'
    
    print(f'>>> Đang đọc dữ liệu từ file: {filename} ...\n')
    
    try:
        all_data = read_iqethernet_h5(filename)
        
        print('\n==================================================')
        print(' THÔNG TIN TỔNG QUAN')
        print('==================================================')
        print(f'Có global_info: {"global_info" in all_data}')
        print(f'Có streams: {"streams" in all_data}')
        
        if 'streams' in all_data:
            stream_keys = sorted(all_data['streams'].keys())
            print(f'Số streams: {len(stream_keys)}')
            
            if stream_keys:
                first_stream_name = stream_keys[0]
                first_stream = all_data['streams'][first_stream_name]
                print(f'\nStream đầu tiên ({first_stream_name}):')
                print(f'  - Số packets: {len(first_stream.get("packets", []))}')
                
                if first_stream.get('packets'):
                    first_packet = first_stream['packets'][0]
                    print(f'\n  Packet đầu tiên:')
                    print(f'    - stream_id: {first_packet.get("stream_id")}')
                    print(f'    - frequency: {first_packet.get("frequency")} Hz ({first_packet.get("frequency", 0)/1e6:.2f} MHz)')
                    print(f'    - bandwidth: {first_packet.get("bandwidth")} Hz ({first_packet.get("bandwidth", 0)/1e6:.2f} MHz)')
                    print(f'    - sample_cnt: {first_packet.get("sample_cnt")}')
                    if 'iq_data' in first_packet and first_packet['iq_data'] is not None:
                        print(f'    - iq_data: {len(first_packet["iq_data"])} mẫu phức')
        
    except Exception as e:
        print(f'Lỗi khi đọc file: {e}')
        import traceback
        traceback.print_exc()


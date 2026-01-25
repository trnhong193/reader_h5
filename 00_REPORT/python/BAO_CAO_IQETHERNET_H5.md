# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE IQETHERNET.H5

## 1. TỔNG QUAN

File `iqethernet.h5` là file HDF5 chứa dữ liệu IQ (In-phase và Quadrature) từ Ethernet Packets. File này được đọc bởi module Python `reader_iqethernet_h5.py` dựa trên code MATLAB `read_iq_ethernet_h5_verge.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: IQ samples (Ethernet Packets)
- **Cấu trúc chính**: 
  - `/attribute`: Chứa metadata (thông tin chung, DDC, request, ...)
  - `/session`: Chứa dữ liệu raw bytes của các Ethernet packets

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
iqethernet.h5
├── /attribute                    # Group chứa metadata
│   ├── Attributes (trực tiếp)    # → global_info
│   ├── /ddc                      # → global_info['ddc']
│   │   └── Attributes
│   ├── /request                  # → global_info['request']
│   │   └── Attributes
│   └── ... (các group con khác)
│
└── /session                      # Group chứa dữ liệu raw packets
    ├── /000000000000000000       # Session ID
    │   └── /raw                  # Dataset: Raw Ethernet packet bytes
    ├── /000000000000000001
    │   └── /raw
    └── ... (nhiều sessions)
```

### Thống kê:
- **Số streams**: 1
- **Tổng số packets**: 12737

### 2.2. Chi tiết các thành phần

#### A. `/attribute` Group

Group này chứa tất cả metadata của file:

1. **Attributes trực tiếp tại `/attribute`**:
   - Được đọc vào `data['global_info']`
   - Chứa thông tin chung như: `client_ip`, `frequency`, `bandwidth`, `channel`, `mission`, ...

2. **Sub-groups trong `/attribute`**:
   - Mỗi sub-group được đọc vào `data['global_info'][sub_name]`
   - Ví dụ: `/attribute/ddc` → `data['global_info']['ddc']`
   - Ví dụ: `/attribute/request` → `data['global_info']['request']`

#### B. `/session` Group

Group này chứa dữ liệu raw bytes của các Ethernet packets:

- Mỗi session có ID dạng: `000000000000000000`, `000000000000000001`, ...
- Mỗi session chứa 1 dataset:
  - `raw`: Raw Ethernet packet bytes (uint8 array)
- Mỗi packet được giải mã theo cấu trúc:
  - Header (40 bytes): header, stream_id, timestamp, frequency, len, bandwidth, switch_id, sample_cnt
  - Payload: IQ samples (Int16, xen kẽ I và Q)

---

## 3. INPUT VÀ OUTPUT CỦA READER

### 3.1. Input

**Hàm**: `read_iqethernet_h5(filename: str)`

**Tham số**:
- `filename` (str): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'../../00_DATA_h5/iqethernet.h5'`

### 3.2. Output

**Kiểu trả về**: `Dict[str, Any]`

**Cấu trúc output**:

```python
{
    'global_info': {
        # Dictionary chứa tất cả attributes từ /attribute
        # Ví dụ:
        # 'client_ip': '192.168.1.100',
        # 'frequency': 1000000000.0,  # Hz
        # 'bandwidth': 20000000.0,    # Hz
        # 'ddc': {...},  # Sub-group attributes
        # 'request': {...},  # Sub-group attributes
        # ...
    },
    
    'streams': {
        'Stream_0': {
            'packets': [
                {
                    'header': uint32,
                    'stream_id': uint32,
                    'timestamp': uint64,
                    'frequency': uint64,  # Hz
                    'len': uint32,
                    'bandwidth': uint32,  # Hz
                    'switch_id': uint32,
                    'sample_cnt': uint32,
                    'iq_data': np.ndarray,  # Complex IQ samples
                    'h5_session_idx': int  # Index trong H5 file
                },
                # ... (nhiều packets)
            ],
            'all_iq': np.ndarray  # (Optional) Tất cả IQ nối lại
        },
        'Stream_1': {...},
        # ... (nhiều streams)
    }
}
```

---

## 4. HƯỚNG DẪN SỬ DỤNG READER

### 4.1. Cài đặt

**Yêu cầu**:
- Python 3.6+
- Thư viện: `h5py`, `numpy`

**Cài đặt dependencies**:
```bash
pip install h5py numpy
```

### 4.2. Cách sử dụng cơ bản

```python
from reader_iqethernet_h5 import read_iqethernet_h5

# Đọc file
filename = 'path/to/iqethernet.h5'
data = read_iqethernet_h5(filename)

# Truy cập thông tin
print(f"Số streams: {len(data['streams'])}")
if 'global_info' in data and 'frequency' in data['global_info']:
    print(f"Frequency: {data['global_info']['frequency']} Hz")
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin chung (Global Info)

```python
# Lấy toàn bộ global_info
global_info = data['global_info']

# Lấy từng trường cụ thể
if 'client_ip' in data['global_info']:
    client_ip = data['global_info']['client_ip']
if 'frequency' in data['global_info']:
    frequency = data['global_info']['frequency']  # Hz
if 'bandwidth' in data['global_info']:
    bandwidth = data['global_info']['bandwidth']  # Hz

# Lấy sub-group (ví dụ: ddc)
if 'ddc' in data['global_info']:
    ddc_info = data['global_info']['ddc']
    # Truy cập các trường trong ddc
    # ddc_channel = ddc_info.get('channelIndex', None)

# In ra tất cả các trường
for key, value in data['global_info'].items():
    if isinstance(value, dict):
        print(f"{key}: (sub-group)")
        for sub_key, sub_value in value.items():
            print(f"  {sub_key}: {sub_value}")
    else:
        print(f"{key}: {value}")
```

#### B. Lấy dữ liệu Streams

**1. Lấy danh sách tất cả streams:**

```python
# Lấy tất cả stream names
stream_names = list(data['streams'].keys())
print(f"Có {len(stream_names)} streams: {stream_names}")

# Lấy một stream cụ thể
stream_0 = data['streams']['Stream_0']
```

**2. Lấy packets từ một stream:**

```python
# Lấy stream
stream = data['streams']['Stream_0']

# Lấy danh sách packets
packets = stream['packets']
print(f"Số packets: {len(packets)}")

# Lấy packet đầu tiên
packet = packets[0]
print(f"Stream ID: {packet['stream_id']}")
print(f"Frequency: {packet['frequency']} Hz ({packet['frequency']/1e6:.2f} MHz)")
print(f"Bandwidth: {packet['bandwidth']} Hz ({packet['bandwidth']/1e6:.2f} MHz)")
print(f"Sample count: {packet['sample_cnt']}")
```

**3. Lấy dữ liệu IQ từ packet:**

```python
import numpy as np

# Lấy packet
packet = data['streams']['Stream_0']['packets'][0]

# Lấy dữ liệu IQ phức
iq_data = packet['iq_data']  # numpy array, dtype: complex128
print(f"IQ data: shape={iq_data.shape}, dtype={iq_data.dtype}")
print(f"IQ samples (5 đầu): {iq_data[:5]}")

# Tính toán từ IQ phức
# Biên độ (Magnitude)
magnitude = np.abs(iq_data)
print(f"Magnitude: min={magnitude.min():.2f}, max={magnitude.max():.2f}")

# Phase (Góc pha)
phase = np.angle(iq_data)
print(f"Phase: min={phase.min():.3f}, max={phase.max():.3f}")

# Power
power = np.abs(iq_data) ** 2
print(f"Power: mean={power.mean():.2f}")
```

**4. Lấy all_iq (tất cả IQ nối lại):**

```python
# Lấy stream
stream = data['streams']['Stream_0']

# Lấy all_iq (nếu có)
if 'all_iq' in stream:
    all_iq = stream['all_iq']  # Tất cả IQ từ tất cả packets nối lại
    print(f"All IQ: {len(all_iq)} samples")
    print(f"Shape: {all_iq.shape}")
else:
    print("Không có all_iq")
```

**5. Duyệt qua tất cả streams và packets:**

```python
import numpy as np

# Duyệt qua tất cả streams
for stream_name, stream_data in data['streams'].items():
    print(f"\nStream: {stream_name}")
    packets = stream_data['packets']
    print(f"  Số packets: {len(packets)}")

    # Duyệt qua từng packet
    for i, packet in enumerate(packets):
        stream_id = packet['stream_id']
        frequency = packet['frequency']
        iq_data = packet['iq_data']

        # Xử lý dữ liệu...
        if len(iq_data) > 0:
            magnitude = np.abs(iq_data)
            phase = np.angle(iq_data)
            print(f"    Packet {i}: Stream ID={stream_id}, "
                  f"Freq={frequency/1e6:.2f} MHz, "
                  f"IQ samples={len(iq_data)}")

        # Ví dụ: chỉ xử lý 10 packets đầu
        if i >= 10:
            break
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```python
#!/usr/bin/env python3
"""
Ví dụ sử dụng reader_iqethernet_h5.py
"""

import numpy as np
from reader_iqethernet_h5 import read_iqethernet_h5

# 1. Đọc file
filename = '../../00_DATA_h5/iqethernet.h5'
print(f"Đang đọc file: {filename}")
data = read_iqethernet_h5(filename)

# 2. Hiển thị thông tin chung
print("\n=== THÔNG TIN CHUNG ===")
print(f"Số streams: {len(data['streams'])}")

if 'global_info' in data:
    print("\nGlobal Info:")
    for key, value in data['global_info'].items():
        if isinstance(value, dict):
            print(f"  {key}: (sub-group)")
            for sub_key, sub_value in value.items():
                print(f"    {sub_key}: {sub_value}")
        else:
            print(f"  {key}: {value}")

# 3. Xử lý dữ liệu từ stream đầu tiên
print("\n=== XỬ LÝ STREAM ĐẦU TIÊN ===")
if data['streams']:
    stream_name = list(data['streams'].keys())[0]
    stream = data['streams'][stream_name]
    print(f"Stream: {stream_name}")
    print(f"Số packets: {len(stream['packets'])}")

    if stream['packets']:
        packet = stream['packets'][0]
        print(f"\nPacket đầu tiên:")
        print(f"  Stream ID: {packet['stream_id']}")
        print(f"  Frequency: {packet['frequency']} Hz ({packet['frequency']/1e6:.2f} MHz)")
        print(f"  Bandwidth: {packet['bandwidth']} Hz ({packet['bandwidth']/1e6:.2f} MHz)")
        print(f"  Sample count: {packet['sample_cnt']}")

        if 'iq_data' in packet and len(packet['iq_data']) > 0:
            iq_data = packet['iq_data']
            iq_mag = np.abs(iq_data)
            print(f"  IQ data: {len(iq_data)} samples")
            print(f"  Magnitude: Min={iq_mag.min():.2f}, Max={iq_mag.max():.2f}, Mean={iq_mag.mean():.2f}")
            print(f"  Phase: Min={np.angle(iq_data).min():.3f}, Max={np.angle(iq_data).max():.3f}")
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `global_info` | `dict` | Attributes từ `/attribute` | `data['global_info']['frequency']` |
| `global_info['ddc']` | `dict` | Attributes từ `/attribute/ddc` | `data['global_info']['ddc']['channelIndex']` |
| `streams` | `dict` | Dictionary các streams | `data['streams']['Stream_0']` |
| `streams['Stream_X']['packets']` | `list` | Danh sách packets | `data['streams']['Stream_0']['packets'][0]` |
| `packets[i]['stream_id']` | `uint32` | Stream ID | `packet['stream_id']` |
| `packets[i]['timestamp']` | `uint64` | Timestamp | `packet['timestamp']` |
| `packets[i]['frequency']` | `uint64` | Frequency (Hz) | `packet['frequency']` |
| `packets[i]['bandwidth']` | `uint32` | Bandwidth (Hz) | `packet['bandwidth']` |
| `packets[i]['iq_data']` | `np.ndarray` | Complex IQ samples | `packet['iq_data']` |
| `streams['Stream_X']['all_iq']` | `np.ndarray` | Tất cả IQ nối lại | `stream['all_iq']` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `iq_data` là `complex128` (số phức 128-bit)
   - Các trường header là `uint32` hoặc `uint64`

2. **Cấu trúc packet**:
   - Header: 40 bytes (header, stream_id, timestamp, frequency, len, bandwidth, switch_id, sample_cnt)
   - Payload: IQ samples (Int16, xen kẽ I và Q)

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `packet['iq_data']` có rỗng không trước khi sử dụng
   - Sử dụng `numpy` để xử lý các phép toán trên mảng

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều packets
   - Có thể tối ưu bằng cách chỉ xử lý một số streams/packets cần thiết

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB gốc**: `read_iq_ethernet_h5_verge.m`
- **Code Python**: `reader_iqethernet_h5.py`
- **HDF5 Documentation**: https://www.hdfgroup.org/solutions/hdf5/

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản reader**: 1.0
**Tương thích với**: MATLAB `read_iq_ethernet_h5_verge.m`

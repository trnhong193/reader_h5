# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE SPECTRUM.H5

## 1. TỔNG QUAN

File `spectrum.h5` là file HDF5 chứa dữ liệu Spectrum. File này được đọc bởi module Python `reader_spectrum_h5.py` dựa trên code MATLAB `read_spectrum_data.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: Spectrum samples (decoded)
- **Số sessions**: 1598 sessions
- **Cấu trúc chính**: 
  - `/attribute`: Chứa metadata (thông tin chung)
  - `/session`: Chứa dữ liệu spectrum của các sessions

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
spectrum.h5
├── /attribute                    # Group chứa metadata
│   └── Attributes (trực tiếp)    # → global_info
│
└── /session                      # Group chứa dữ liệu spectrum
    ├── /000xx                    # Session ID
    │   ├── Attributes            # → sessions[i].attributes
    │   ├── /source               # → sessions[i].source_info
    │   │   └── Attributes
    │   └── /sample_decoded        # Dataset: Decoded spectrum samples
    ├── /000yy
    │   ├── Attributes
    │   ├── /source
    │   │   └── Attributes
    │   └── /sample_decoded
    └── ... (nhiều sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute` Group

Group này chứa tất cả metadata của file:

1. **Attributes trực tiếp tại `/attribute`**:
   - Được đọc vào `data['global_info']`
   - Chứa thông tin chung như: `client_ip`, `frequency`, `bandwidth`, `channel`, `mission`, ...

#### B. `/session` Group

Group này chứa dữ liệu spectrum của các sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa:
  - **Attributes**: Thông tin chung của session (timestamp, freq, bw, ...)
  - **`/source` sub-group**: Thông tin thiết bị (attributes)
  - **`/sample_decoded` dataset**: Vector dữ liệu spectrum đã giải mã (float64 array)

---

## 3. INPUT VÀ OUTPUT CỦA READER

### 3.1. Input

**Hàm**: `read_spectrum_h5(filename: str)`

**Tham số**:
- `filename` (str): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'../../00_DATA_h5/spectrum.h5'`

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
        # 'mission': '...',
        # ...
    },
    
    'sessions': [
        {
            'id': '000xx',                    # Session ID
            'attributes': {                  # Attributes của session
                'timestamp': ...,
                'frequency': ...,              # Hz
                'bandwidth': ...,             # Hz
                # ... các attributes khác
            },
            'source_info': {                 # Thông tin thiết bị
                # Attributes từ /source
                # ...
            },
            'samples': np.ndarray             # Vector dữ liệu spectrum (float64)
        },
        # ... (nhiều sessions)
    ]
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
from reader_spectrum_h5 import read_spectrum_h5

# Đọc file
filename = 'path/to/spectrum.h5'
data = read_spectrum_h5(filename)

# Truy cập thông tin
print(f"Số sessions: {len(data['sessions'])}")
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

# In ra tất cả các trường
for key, value in data['global_info'].items():
    print(f"{key}: {value}")
```

#### B. Lấy dữ liệu Sessions

**1. Lấy danh sách tất cả sessions:**

```python
# Lấy số lượng sessions
num_sessions = len(data['sessions'])
print(f"Có {num_sessions} sessions")

# Lấy session đầu tiên
first_session = data['sessions'][0]
```

**2. Lấy thông tin từ một session:**

```python
# Lấy session theo index
session = data['sessions'][0]

# Lấy Session ID
session_id = session['id']
print(f"Session ID: {session_id}")

# Lấy attributes của session
attributes = session['attributes']
if 'frequency' in attributes:
    freq = attributes['frequency']  # Hz
if 'bandwidth' in attributes:
    bw = attributes['bandwidth']  # Hz
if 'timestamp' in attributes:
    timestamp = attributes['timestamp']
```

**3. Lấy source info:**

```python
# Lấy session
session = data['sessions'][0]

# Lấy source info
source_info = session['source_info']
# Truy cập các trường trong source_info
# Ví dụ: device_name = source_info.get('device_name', None)
```

**4. Lấy dữ liệu samples (spectrum):**

```python
import numpy as np

# Lấy session
session = data['sessions'][0]

# Lấy dữ liệu spectrum
samples = session['samples']  # numpy array, dtype: float64
print(f"Samples: shape={samples.shape}, dtype={samples.dtype}")
print(f"Samples (5 đầu): {samples[:5]}")

# Tính toán từ samples
# Min, Max, Mean
print(f"Min: {samples.min():.2f}, Max: {samples.max():.2f}, Mean: {samples.mean():.2f}")

# Power (nếu cần)
power = samples ** 2
print(f"Power: mean={power.mean():.2f}")
```

**5. Duyệt qua tất cả sessions:**

```python
import numpy as np

# Duyệt qua tất cả sessions
for i, session in enumerate(data['sessions']):
    session_id = session['id']
    attributes = session['attributes']
    source_info = session['source_info']
    samples = session['samples']
    
    # Xử lý dữ liệu...
    if len(samples) > 0:
        print(f"Session {i} ({session_id}): {len(samples)} samples")
        print(f"  Frequency: {attributes.get('frequency', 'N/A')} Hz")
        print(f"  Min: {samples.min():.2f}, Max: {samples.max():.2f}")
    
    # Ví dụ: chỉ xử lý 10 sessions đầu
    if i >= 10:
        break
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```python
#!/usr/bin/env python3
"""
Ví dụ sử dụng reader_spectrum_h5.py
"""

import numpy as np
from reader_spectrum_h5 import read_spectrum_h5

# 1. Đọc file
filename = '../../00_DATA_h5/spectrum.h5'
print(f"Đang đọc file: {filename}")
data = read_spectrum_h5(filename)

# 2. Hiển thị thông tin chung
print("\n=== THÔNG TIN CHUNG ===")
print(f"Số sessions: {len(data['sessions'])}")

if 'global_info' in data:
    print("\nGlobal Info:")
    for key, value in data['global_info'].items():
        print(f"  {key}: {value}")

# 3. Xử lý dữ liệu từ session đầu tiên
print("\n=== XỬ LÝ SESSION ĐẦU TIÊN ===")
if data['sessions']:
    session = data['sessions'][0]
    print(f"Session ID: {session['id']}")
    
    # Attributes
    if session['attributes']:
        print("\nAttributes:")
        for key, value in session['attributes'].items():
            print(f"  {key}: {value}")
    
    # Source info
    if session['source_info']:
        print("\nSource Info:")
        for key, value in session['source_info'].items():
            print(f"  {key}: {value}")
    
    # Samples
    if len(session['samples']) > 0:
        samples = session['samples']
        print(f"\nSamples: {len(samples)} điểm")
        print(f"  Min: {samples.min():.2f}, Max: {samples.max():.2f}, Mean: {samples.mean():.2f}")
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `global_info` | `dict` | Attributes từ `/attribute` | `data['global_info']['frequency']` |
| `sessions` | `list` | Danh sách các sessions | `data['sessions'][0]` |
| `sessions[i]['id']` | `str` | Session ID | `session['id']` |
| `sessions[i]['attributes']` | `dict` | Attributes của session | `session['attributes']['frequency']` |
| `sessions[i]['source_info']` | `dict` | Thông tin thiết bị | `session['source_info']['device_name']` |
| `sessions[i]['samples']` | `np.ndarray` | Vector spectrum samples (float64) | `session['samples']` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `samples` là `float64` (số thực double precision)
   - Các attributes có thể là string, int, float tùy theo file

2. **Cấu trúc session**:
   - Mỗi session có thể có hoặc không có `/source` sub-group
   - Mỗi session có thể có hoặc không có `/sample_decoded` dataset

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `len(session['samples']) > 0` trước khi sử dụng
   - Sử dụng `numpy` để xử lý các phép toán trên mảng
   - Kiểm tra `session['attributes']` và `session['source_info']` có rỗng không

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB gốc**: `read_spectrum_data.m`
- **Code Python**: `reader_spectrum_h5.py`
- **HDF5 Documentation**: https://www.hdfgroup.org/solutions/hdf5/

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản reader**: 1.0
**Tương thích với**: MATLAB `read_spectrum_data.m`

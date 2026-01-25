# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE HISTOGRAM.H5

## 1. TỔNG QUAN

File `histogram.h5` là file HDF5 chứa dữ liệu Histogram. File này được đọc bởi module Python `reader_histogram_h5.py` dựa trên code MATLAB `read_histogram_h5_multitype.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: Histogram samples (decoded)
- **Số sessions**: 6003 sessions
  - AccumulatedPower: 3002 sessions
  - CrossingThresholdPower: 3001 sessions
- **Cấu trúc chính**: 
  - `/attribute`: Chứa metadata (thông tin chung)
  - `/session`: Chứa dữ liệu histogram của các sessions (hỗ trợ nhiều loại message)

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
histogram.h5
├── /attribute                    # Group chứa metadata
│   └── Attributes (trực tiếp)    # → global_info
│
└── /session                      # Group chứa dữ liệu histogram
    ├── /000xx                    # Session ID
    │   ├── Attributes            # → sessions[i].attributes (bao gồm message_type)
    │   ├── /context              # → sessions[i].context_info
    │   │   └── Attributes
    │   ├── /source               # → sessions[i].source_info
    │   │   └── Attributes
    │   └── Dataset (phụ thuộc message_type):
    │       ├── sample_decoded        # Cho AccumulatedPower
    │       ├── acc_sample_decoded    # Cho CrossingThresholdPower
    │       └── crx_sample_decoded    # Cho CrossingThresholdPower
    ├── /000yy
    │   ├── Attributes
    │   ├── /context
    │   │   └── Attributes
    │   ├── /source
    │   │   └── Attributes
    │   └── Dataset (phụ thuộc message_type)
    └── ... (nhiều sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute` Group

Group này chứa tất cả metadata của file:

1. **Attributes trực tiếp tại `/attribute`**:
   - Được đọc vào `data['global_info']`
   - Chứa thông tin chung như: `client_ip`, `frequency`, `bandwidth`, `channel`, `mission`, ...

#### B. `/session` Group

Group này chứa dữ liệu histogram của các sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa:
  - **Attributes**: Thông tin chung của session (timestamp, freq, bw, **message_type**, ...)
  - **`/context` sub-group**: Thông tin ngữ cảnh (attributes)
  - **`/source` sub-group**: Thông tin thiết bị (attributes)
  - **Dataset phụ thuộc vào `message_type`**:
    - **AccumulatedPower**: `sample_decoded` (vector histogram)
    - **CrossingThresholdPower**: `acc_sample_decoded` (accumulated) VÀ `crx_sample_decoded` (crossing)

---

## 3. INPUT VÀ OUTPUT CỦA READER

### 3.1. Input

**Hàm**: `read_histogram_h5(filename: str)`

**Tham số**:
- `filename` (str): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'../../00_DATA_h5/histogram.h5'`

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
            'type': 'AccumulatedPower',       # Message type (hoặc 'CrossingThresholdPower')
            'attributes': {                  # Attributes của session
                'message_type': '...',
                'timestamp': ...,
                'frequency': ...,              # Hz
                'bandwidth': ...,             # Hz
                # ... các attributes khác
            },
            'context_info': {                # Thông tin ngữ cảnh
                # Attributes từ /context
                # ...
            },
            'source_info': {                  # Thông tin thiết bị
                # Attributes từ /source
                # ...
            },
            # Dữ liệu phụ thuộc vào message_type:
            'sample_decoded': np.ndarray,     # Cho AccumulatedPower (float64)
            'acc_sample_decoded': np.ndarray, # Cho CrossingThresholdPower (float64)
            'crx_sample_decoded': np.ndarray  # Cho CrossingThresholdPower (float64)
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
from reader_histogram_h5 import read_histogram_h5

# Đọc file
filename = 'path/to/histogram.h5'
data = read_histogram_h5(filename)

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

# Lấy Message Type
msg_type = session['type']
print(f"Message Type: {msg_type}")

# Lấy attributes của session
attributes = session['attributes']
if 'frequency' in attributes:
    freq = attributes['frequency']  # Hz
if 'bandwidth' in attributes:
    bw = attributes['bandwidth']  # Hz
if 'timestamp' in attributes:
    timestamp = attributes['timestamp']
```

**3. Lấy context info:**

```python
# Lấy session
session = data['sessions'][0]

# Lấy context info
context_info = session['context_info']
# Truy cập các trường trong context_info
# Ví dụ: context_value = context_info.get('some_field', None)
```

**4. Lấy source info:**

```python
# Lấy session
session = data['sessions'][0]

# Lấy source info
source_info = session['source_info']
# Truy cập các trường trong source_info
# Ví dụ: device_name = source_info.get('device', None)
```

**5. Lấy dữ liệu histogram (phụ thuộc vào message_type):**

```python
import numpy as np

# Lấy session
session = data['sessions'][0]
msg_type = session['type']

# Xử lý theo loại message
if 'CrossingThresholdPower' in msg_type:
    # TRƯỜNG HỢP: CrossingThresholdPower
    # Đọc acc_sample_decoded
    acc_data = session['acc_sample_decoded']  # numpy array, dtype: float64
    print(f"acc_sample_decoded: shape={acc_data.shape}, dtype={acc_data.dtype}")
    print(f"  Min: {acc_data.min():.2e}, Max: {acc_data.max():.2e}, Sum: {acc_data.sum():.2e}")
    
    # Đọc crx_sample_decoded
    crx_data = session['crx_sample_decoded']  # numpy array, dtype: float64
    print(f"crx_sample_decoded: shape={crx_data.shape}, dtype={crx_data.dtype}")
    print(f"  Min: {crx_data.min():.2e}, Max: {crx_data.max():.2e}, Sum: {crx_data.sum():.2e}")
else:
    # TRƯỜNG HỢP: AccumulatedPower (hoặc mặc định)
    hist_data = session['sample_decoded']  # numpy array, dtype: float64
    print(f"sample_decoded: shape={hist_data.shape}, dtype={hist_data.dtype}")
    print(f"  Min: {hist_data.min():.2e}, Max: {hist_data.max():.2e}, Sum: {hist_data.sum():.2e}")
```

**6. Duyệt qua tất cả sessions:**

```python
import numpy as np

# Duyệt qua tất cả sessions
for i, session in enumerate(data['sessions']):
    session_id = session['id']
    msg_type = session['type']
    attributes = session['attributes']
    context_info = session['context_info']
    source_info = session['source_info']
    
    # Xử lý dữ liệu theo loại message
    if 'CrossingThresholdPower' in msg_type:
        acc_data = session['acc_sample_decoded']
        crx_data = session['crx_sample_decoded']
        
        if len(acc_data) > 0:
            print(f"Session {i} ({session_id}): CrossingThresholdPower")
            print(f"  acc: {len(acc_data)} bins, Sum={acc_data.sum():.2e}")
            print(f"  crx: {len(crx_data)} bins, Sum={crx_data.sum():.2e}")
    else:
        hist_data = session['sample_decoded']
        
        if len(hist_data) > 0:
            print(f"Session {i} ({session_id}): AccumulatedPower")
            print(f"  samples: {len(hist_data)} bins, Sum={hist_data.sum():.2e}")
    
    # Ví dụ: chỉ xử lý 10 sessions đầu
    if i >= 10:
        break
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```python
#!/usr/bin/env python3
"""
Ví dụ sử dụng reader_histogram_h5.py
"""

import numpy as np
from reader_histogram_h5 import read_histogram_h5

# 1. Đọc file
filename = '../../00_DATA_h5/histogram.h5'
print(f"Đang đọc file: {filename}")
data = read_histogram_h5(filename)

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
    print(f"Message Type: {session['type']}")
    
    # Attributes
    if session['attributes']:
        print("\nAttributes:")
        for key, value in session['attributes'].items():
            print(f"  {key}: {value}")
    
    # Context info
    if session['context_info']:
        print("\nContext Info:")
        for key, value in session['context_info'].items():
            print(f"  {key}: {value}")
    
    # Source info
    if session['source_info']:
        print("\nSource Info:")
        for key, value in session['source_info'].items():
            print(f"  {key}: {value}")
    
    # Samples (phụ thuộc vào message_type)
    msg_type = session['type']
    if 'CrossingThresholdPower' in msg_type:
        if len(session['acc_sample_decoded']) > 0:
            acc_data = session['acc_sample_decoded']
            print(f"\nacc_sample_decoded: {len(acc_data)} bins")
            print(f"  Min: {acc_data.min():.2e}, Max: {acc_data.max():.2e}, Sum: {acc_data.sum():.2e}")
        
        if len(session['crx_sample_decoded']) > 0:
            crx_data = session['crx_sample_decoded']
            print(f"\ncrx_sample_decoded: {len(crx_data)} bins")
            print(f"  Min: {crx_data.min():.2e}, Max: {crx_data.max():.2e}, Sum: {crx_data.sum():.2e}")
    else:
        if len(session['sample_decoded']) > 0:
            hist_data = session['sample_decoded']
            print(f"\nsample_decoded: {len(hist_data)} bins")
            print(f"  Min: {hist_data.min():.2e}, Max: {hist_data.max():.2e}, Sum: {hist_data.sum():.2e}")
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `global_info` | `dict` | Attributes từ `/attribute` | `data['global_info']['frequency']` |
| `sessions` | `list` | Danh sách các sessions | `data['sessions'][0]` |
| `sessions[i]['id']` | `str` | Session ID | `session['id']` |
| `sessions[i]['type']` | `str` | Message type | `session['type']` |
| `sessions[i]['attributes']` | `dict` | Attributes của session | `session['attributes']['frequency']` |
| `sessions[i]['context_info']` | `dict` | Thông tin ngữ cảnh | `session['context_info']['field']` |
| `sessions[i]['source_info']` | `dict` | Thông tin thiết bị | `session['source_info']['device']` |
| `sessions[i]['sample_decoded']` | `np.ndarray` | Histogram (AccumulatedPower) | `session['sample_decoded']` |
| `sessions[i]['acc_sample_decoded']` | `np.ndarray` | Accumulated histogram (CrossingThresholdPower) | `session['acc_sample_decoded']` |
| `sessions[i]['crx_sample_decoded']` | `np.ndarray` | Crossing histogram (CrossingThresholdPower) | `session['crx_sample_decoded']` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - Tất cả samples là `float64` (số thực double precision)
   - Các attributes có thể là string, int, float tùy theo file

2. **Message Type**:
   - **AccumulatedPower**: Sử dụng `sample_decoded`
   - **CrossingThresholdPower**: Sử dụng `acc_sample_decoded` VÀ `crx_sample_decoded`
   - Luôn kiểm tra `session['type']` trước khi truy cập dữ liệu

3. **Cấu trúc session**:
   - Mỗi session có thể có hoặc không có `/context` sub-group
   - Mỗi session có thể có hoặc không có `/source` sub-group
   - Dataset phụ thuộc vào `message_type` trong attributes

4. **Xử lý dữ liệu**:
   - Luôn kiểm tra `len(session['sample_decoded']) > 0` (hoặc tương ứng) trước khi sử dụng
   - Sử dụng `numpy` để xử lý các phép toán trên mảng
   - Kiểm tra `session['attributes']`, `session['context_info']`, `session['source_info']` có rỗng không

5. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB gốc**: `read_histogram_h5_multitype.m`
- **Code Python**: `reader_histogram_h5.py`
- **HDF5 Documentation**: https://www.hdfgroup.org/solutions/hdf5/

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản reader**: 1.0
**Tương thích với**: MATLAB `read_histogram_h5_multitype.m`

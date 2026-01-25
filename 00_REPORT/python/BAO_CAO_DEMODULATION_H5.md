# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE DEMODULATION.H5

## 1. TỔNG QUAN

File `demodulation.h5` là file HDF5 chứa dữ liệu Demodulation (IQ). File này được đọc bởi module Python `reader_demodulation_h5.py` dựa trên code MATLAB `reader_demodulation_no_recursive.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: Demodulation IQ data (In-phase và Quadrature)
- **Số sessions**: 4240 sessions
- **Số nhóm request**: 6 groups
- **Cấu trúc chính**: 
  - `/attribute/request`: Chứa cấu hình (attributes từ các sub-groups)
  - `/session`: Chứa dữ liệu IQ của các sessions (datasets 'i' và 'q')

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
demodulation.h5
├── /attribute
│   └── /request                      # → request
│       ├── /hwConfiguration          # → request['hwConfiguration'] (attributes)
│       ├── /libConfiguration         # → request['libConfiguration'] (attributes)
│       ├── /recordingOptions         # → request['recordingOptions'] (attributes)
│       ├── /source                   # → request['source'] (attributes)
│       ├── /spectrumOptions          # → request['spectrumOptions'] (attributes)
│       ├── /transaction              # → request['transaction'] (attributes)
│       └── ... (các sub-groups khác)
│
└── /session                          # → sessions
    ├── /000xx                        # Session ID
    │   ├── /i                        # Dataset: In-phase samples
    │   └── /q                        # Dataset: Quadrature samples
    ├── /000yy
    │   ├── /i
    │   └── /q
    └── ... (nhiều sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute/request` Group

Group này chứa các cấu hình dưới dạng attributes:

- Mỗi sub-group (hwConfiguration, libConfiguration, recordingOptions, source, spectrumOptions, transaction...) chứa attributes
- Được đọc vào `data['request'][sub_name]`
- Ví dụ: `data['request']['hwConfiguration']` chứa các attributes của hwConfiguration

#### B. `/session` Group

Group này chứa dữ liệu IQ của các sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa 2 datasets:
  - **`i`**: In-phase samples (real part)
  - **`q`**: Quadrature samples (imaginary part)
- Dữ liệu được kết hợp thành complex IQ: `iq = i + j*q`

---

## 3. INPUT VÀ OUTPUT CỦA READER

### 3.1. Input

**Hàm**: `read_demodulation_h5(filename: str)`

**Tham số**:
- `filename` (str): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'../../00_DATA_h5/demodulation.h5'`

### 3.2. Output

**Kiểu trả về**: `Dict[str, Any]`

**Cấu trúc output**:

```python
{
    'request': {
        'hwConfiguration': {                    # Attributes từ /attribute/request/hwConfiguration
            'attr1': value1,
            'attr2': value2,
            # ...
        },
        'libConfiguration': {                   # Attributes từ /attribute/request/libConfiguration
            # ...
        },
        'recordingOptions': {                   # Attributes từ /attribute/request/recordingOptions
            # ...
        },
        'source': {                             # Attributes từ /attribute/request/source
            # ...
        },
        'spectrumOptions': {                    # Attributes từ /attribute/request/spectrumOptions
            # ...
        },
        'transaction': {                        # Attributes từ /attribute/request/transaction
            # ...
        },
        # ... (các sub-groups khác)
    },
    
    'sessions': [
        {
            'id': '000xx',                      # Session ID
            'iq': np.ndarray                    # Complex IQ data (I + j*Q), dtype: complex128
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
from reader_demodulation_h5 import read_demodulation_h5

# Đọc file
filename = 'path/to/demodulation.h5'
data = read_demodulation_h5(filename)

# Truy cập thông tin
print(f"Số sessions: {len(data['sessions'])}")
print(f"Số nhóm request: {len(data.get('request', {}))}")
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin Request Configuration

```python
# Lấy toàn bộ request
request = data['request']

# Lấy hwConfiguration
if 'hwConfiguration' in data['request']:
    hw_config = data['request']['hwConfiguration']
    # Truy cập các attributes
    # attr_value = hw_config.get('attr_name', None)

# Lấy libConfiguration
if 'libConfiguration' in data['request']:
    lib_config = data['request']['libConfiguration']
    # ...

# Lấy recordingOptions
if 'recordingOptions' in data['request']:
    rec_options = data['request']['recordingOptions']
    # ...

# Lấy source
if 'source' in data['request']:
    source = data['request']['source']
    # ...

# Lấy spectrumOptions
if 'spectrumOptions' in data['request']:
    spec_options = data['request']['spectrumOptions']
    # ...

# Lấy transaction
if 'transaction' in data['request']:
    transaction = data['request']['transaction']
    # ...

# Duyệt qua tất cả request groups
for group_name, group_attrs in data['request'].items():
    print(f"{group_name}: {len(group_attrs)} attributes")
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

# Lấy IQ data
iq_data = session['iq']  # numpy array, dtype: complex128
print(f"IQ data: {len(iq_data)} samples, dtype={iq_data.dtype}")
```

**3. Xử lý dữ liệu IQ:**

```python
import numpy as np

# Lấy session
session = data['sessions'][0]
iq_data = session['iq']

# Lấy I và Q riêng biệt
i_data = iq_data.real  # In-phase (real part)
q_data = iq_data.imag  # Quadrature (imaginary part)

print(f"I (real): Min={i_data.min():.2f}, Max={i_data.max():.2f}, Mean={i_data.mean():.2f}")
print(f"Q (imag): Min={q_data.min():.2f}, Max={q_data.max():.2f}, Mean={q_data.mean():.2f}")

# Tính toán từ IQ phức
# Biên độ (Magnitude)
magnitude = np.abs(iq_data)
print(f"Magnitude: Min={magnitude.min():.2f}, Max={magnitude.max():.2f}, Mean={magnitude.mean():.2f}")

# Phase (Góc pha)
phase = np.angle(iq_data)
print(f"Phase: Min={phase.min():.3f}, Max={phase.max():.3f}")

# Power
power = np.abs(iq_data) ** 2
print(f"Power: Mean={power.mean():.2f}")
```

**4. Duyệt qua tất cả sessions:**

```python
import numpy as np

# Duyệt qua tất cả sessions
for i, session in enumerate(data['sessions']):
    session_id = session['id']
    iq_data = session['iq']
    
    # Xử lý dữ liệu...
    if len(iq_data) > 0:
        magnitude = np.abs(iq_data)
        print(f"Session {i} ({session_id}): {len(iq_data)} samples")
        print(f"  Magnitude: Min={magnitude.min():.2f}, Max={magnitude.max():.2f}")
    
    # Ví dụ: chỉ xử lý 10 sessions đầu
    if i >= 10:
        break
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```python
#!/usr/bin/env python3
"""
Ví dụ sử dụng reader_demodulation_h5.py
"""

import numpy as np
import matplotlib.pyplot as plt
from reader_demodulation_h5 import read_demodulation_h5

# 1. Đọc file
filename = '../../00_DATA_h5/demodulation.h5'
print(f"Đang đọc file: {filename}")
data = read_demodulation_h5(filename)

# 2. Hiển thị thông tin chung
print("\n=== THÔNG TIN CHUNG ===")
print(f"Số sessions: {len(data['sessions'])}")
print(f"Số nhóm request: {len(data.get('request', {}))}")

# 3. Request Configuration
if 'request' in data:
    print("\n=== REQUEST CONFIGURATION ===")
    for group_name, group_attrs in data['request'].items():
        print(f"{group_name}: {len(group_attrs)} attributes")
        for attr_name in list(group_attrs.keys())[:3]:
            print(f"  {attr_name}: ...")

# 4. Session đầu tiên
print("\n=== SESSION ĐẦU TIÊN ===")
if data['sessions']:
    session = data['sessions'][0]
    print(f"Session ID: {session['id']}")
    
    if len(session['iq']) > 0:
        iq_data = session['iq']
        print(f"IQ data: {len(iq_data)} samples")
        print(f"  I (real): Min={iq_data.real.min():.2f}, Max={iq_data.real.max():.2f}")
        print(f"  Q (imag): Min={iq_data.imag.min():.2f}, Max={iq_data.imag.max():.2f}")
        print(f"  Magnitude: Min={np.abs(iq_data).min():.2f}, Max={np.abs(iq_data).max():.2f}")
        
        # Vẽ biểu đồ (nếu có matplotlib)
        # plt.figure(figsize=(12, 6))
        # 
        # plt.subplot(2, 1, 1)
        # plt.plot(iq_data.real, 'b', label='I')
        # plt.plot(iq_data.imag, 'r', label='Q')
        # plt.title('Time Domain (I & Q)')
        # plt.legend()
        # plt.grid(True)
        # 
        # plt.subplot(2, 1, 2)
        # plt.plot(iq_data.real, iq_data.imag, '.')
        # plt.title('Constellation Diagram')
        # plt.axis('equal')
        # plt.grid(True)
        # 
        # plt.tight_layout()
        # plt.show()
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `request` | `dict` | Request configuration groups với attributes | `data['request']['hwConfiguration']` |
| `request['hwConfiguration']` | `dict` | Hardware configuration attributes | `data['request']['hwConfiguration']['attr']` |
| `request['libConfiguration']` | `dict` | Library configuration attributes | `data['request']['libConfiguration']['attr']` |
| `request['recordingOptions']` | `dict` | Recording options attributes | `data['request']['recordingOptions']['attr']` |
| `request['source']` | `dict` | Source attributes | `data['request']['source']['attr']` |
| `request['spectrumOptions']` | `dict` | Spectrum options attributes | `data['request']['spectrumOptions']['attr']` |
| `request['transaction']` | `dict` | Transaction attributes | `data['request']['transaction']['attr']` |
| `sessions` | `list` | Danh sách các sessions | `data['sessions'][0]` |
| `sessions[i]['id']` | `str` | Session ID | `session['id']` |
| `sessions[i]['iq']` | `np.ndarray` | Complex IQ data (I + j*Q) | `session['iq']` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `iq` là `complex128` (số phức 128-bit)
   - I và Q được đọc từ datasets riêng biệt và kết hợp thành complex
   - Request attributes có thể là string, int, float tùy theo file

2. **Cấu trúc session**:
   - Mỗi session có 2 datasets: `i` và `q`
   - Dữ liệu được kết hợp: `iq = i + j*q`
   - Nếu `i` và `q` có độ dài khác nhau, chỉ lấy phần chung (min length)

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `len(session['iq']) > 0` trước khi sử dụng
   - Sử dụng `numpy` để xử lý các phép toán trên mảng
   - Sử dụng `.real` và `.imag` để lấy I và Q riêng biệt
   - Sử dụng `np.abs()` và `np.angle()` để tính magnitude và phase

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

5. **Visualization**:
   - Có thể vẽ time domain (I và Q theo thời gian)
   - Có thể vẽ constellation diagram (Q vs I)

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB gốc**: `reader_demodulation_no_recursive.m`
- **Code Python**: `reader_demodulation_h5.py`
- **HDF5 Documentation**: https://www.hdfgroup.org/solutions/hdf5/

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản reader**: 1.0
**Tương thích với**: MATLAB `reader_demodulation_no_recursive.m`

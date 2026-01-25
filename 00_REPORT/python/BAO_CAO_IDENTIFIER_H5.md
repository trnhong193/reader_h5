# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE IDENTIFIER.H5

## 1. TỔNG QUAN

File `identifier.h5` là file HDF5 chứa dữ liệu Identifier. File này được đọc bởi module Python `reader_identifier_h5.py` dựa trên code MATLAB `read_identifier.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: Identifier data (Hop parameters, DOA, IQ)
- **Số sessions**: 750 sessions
- **Cấu trúc chính**: 
  - `/attribute/estm_bdw`: Chứa tham số Hop (datasets: fc, ...)
  - `/attribute/request/label`: Chứa label text (dataset)
  - `/attribute/doa/position`: Chứa DOA position datasets (vecDoas, ...)
  - `/attribute/doa/identity/features`: Chứa identity feature datasets (meanBws, meanFcs, ...)
  - `/session`: Chứa dữ liệu IQ của các sessions (dataset 'iq' xen kẽ I, Q, I, Q...)

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
identifier.h5
├── /attribute
│   ├── /estm_bdw                      # → estm_bdw (datasets: fc, ...)
│   │   └── Datasets                   # Tham số Hop
│   │
│   ├── /request                       # → request
│   │   └── /label                     # Dataset: Label text
│   │
│   └── /doa                           # → doa
│       ├── /position                  # → doa['position'] (datasets: vecDoas, ...)
│       └── /identity
│           └── /features              # → doa['identity']['features'] (datasets: meanBws, meanFcs, ...)
│
└── /session                           # → sessions
    ├── /000xx                         # Session ID
    │   └── /iq                        # Dataset: IQ data (xen kẽ I, Q, I, Q...)
    ├── /000yy
    │   └── /iq
    └── ... (nhiều sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute/estm_bdw` Group

Group này chứa tham số Hop dưới dạng datasets:

- Các datasets như: `fc` (frequency center), ...
- Được đọc vào `data['estm_bdw']`
- Ví dụ: `data['estm_bdw']['fc']` chứa frequency centers của các hops

#### B. `/attribute/request/label` Dataset

Dataset này chứa label text:

- Được đọc và parse thành dictionary
- Được đọc vào `data['request']['label']`
- Format: text với các dòng dạng `key=value` hoặc plain text

#### C. `/attribute/doa` Group

Group này chứa dữ liệu DOA:

- **`/position`**: Datasets như `vecDoas` (DOA vectors)
- **`/identity/features`**: Datasets như `meanBws`, `meanFcs` (identity features)

#### D. `/session` Group

Group này chứa dữ liệu IQ của các sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa 1 dataset:
  - **`iq`**: IQ data xen kẽ (I, Q, I, Q, ...)
  - Dữ liệu được xử lý thành complex IQ: `iq = I + j*Q`

---

## 3. INPUT VÀ OUTPUT CỦA READER

### 3.1. Input

**Hàm**: `read_identifier_h5(filename: str)`

**Tham số**:
- `filename` (str): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'../../00_DATA_h5/identifier.h5'`

### 3.2. Output

**Kiểu trả về**: `Dict[str, Any]`

**Cấu trúc output**:

```python
{
    'estm_bdw': {
        'fc': np.ndarray,              # Frequency centers (Hop parameters)
        # ... (các datasets khác)
    },
    
    'request': {
        'label': {                     # Parsed label dictionary
            'key1': 'value1',
            'key2': 'value2',
            # ... (các key-value pairs từ label text)
        }
    },
    
    'doa': {
        'position': {
            'vecDoas': np.ndarray,     # DOA vectors
            # ... (các datasets khác)
        },
        'identity': {
            'features': {
                'meanBws': np.ndarray, # Mean bandwidths
                'meanFcs': np.ndarray,  # Mean frequency centers
                # ... (các datasets khác)
            }
        }
    },
    
    'sessions': [
        {
            'id': '000xx',              # Session ID
            'iq': np.ndarray            # Complex IQ data (I + j*Q), dtype: complex128
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
from reader_identifier_h5 import read_identifier_h5

# Đọc file
filename = 'path/to/identifier.h5'
data = read_identifier_h5(filename)

# Truy cập thông tin
print(f"Số sessions: {len(data['sessions'])}")
print(f"Có estm_bdw: True")
print(f"Có doa: True")
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin estm_bdw (Hop Parameters)

```python
# Lấy estm_bdw
if 'estm_bdw' in data:
    estm_bdw = data['estm_bdw']
    
    # Lấy fc (frequency centers)
    if 'fc' in estm_bdw:
        fc = estm_bdw['fc']  # numpy array
        print(f"Frequency centers: {len(fc)} hops")
        print(f"  Min: {fc.min():.2f}, Max: {fc.max():.2f}")
    
    # Duyệt qua tất cả datasets
    for ds_name, ds_value in estm_bdw.items():
        if isinstance(ds_value, np.ndarray):
            print(f"{ds_name}: shape={ds_value.shape}, dtype={ds_value.dtype}")
```

#### B. Lấy thông tin Request Label

```python
# Lấy request label
if 'request' in data and 'label' in data['request']:
    label = data['request']['label']
    
    # Truy cập các key-value pairs
    for key, value in label.items():
        print(f"{key}: {value}")
    
    # Lấy giá trị cụ thể nếu biết key
    # value = label.get('key_name', None)
```

#### C. Lấy dữ liệu DOA

```python
# Lấy DOA
if 'doa' in data:
    doa = data['doa']
    
    # Lấy position (vecDoas)
    if 'position' in doa:
        position = doa['position']
        if 'vecDoas' in position:
            vec_doas = position['vecDoas']  # numpy array
            print(f"DOA vectors: shape={vec_doas.shape}, dtype={vec_doas.dtype}")
    
    # Lấy identity features
    if 'identity' in doa and 'features' in doa['identity']:
        features = doa['identity']['features']
        
        if 'meanBws' in features:
            mean_bws = features['meanBws']  # numpy array
            print(f"Mean BWs: shape={mean_bws.shape}, dtype={mean_bws.dtype}")
        
        if 'meanFcs' in features:
            mean_fcs = features['meanFcs']  # numpy array
            print(f"Mean FCs: shape={mean_fcs.shape}, dtype={mean_fcs.dtype}")
```

#### D. Lấy dữ liệu Sessions

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
Ví dụ sử dụng reader_identifier_h5.py
"""

import numpy as np
from reader_identifier_h5 import read_identifier_h5

# 1. Đọc file
filename = '../../00_DATA_h5/identifier.h5'
print(f"Đang đọc file: {filename}")
data = read_identifier_h5(filename)

# 2. Hiển thị thông tin chung
print("\n=== THÔNG TIN CHUNG ===")
print(f"Số sessions: {len(data['sessions'])}")
print(f"Có estm_bdw: True")
print(f"Có request: True")
print(f"Có doa: True")

# 3. estm_bdw (Hop Parameters)
if 'estm_bdw' in data:
    print("\n=== ESTM_BDW (HOP PARAMETERS) ===")
    for ds_name, ds_value in data['estm_bdw'].items():
        if isinstance(ds_value, np.ndarray):
            print(f"{ds_name}: shape={ds_value.shape}, dtype={ds_value.dtype}")
            if ds_name == 'fc' and len(ds_value) > 0:
                print(f"  Min: {ds_value.min():.2f}, Max: {ds_value.max():.2f}")

# 4. Request Label
if 'request' in data and 'label' in data['request']:
    print("\n=== REQUEST LABEL ===")
    label = data['request']['label']
    for key, value in list(label.items())[:10]:  # Hiển thị 10 dòng đầu
        print(f"{key}: {value}")

# 5. DOA
if 'doa' in data:
    print("\n=== DOA ===")
    if 'position' in data['doa']:
        print("Position:")
        for ds_name, ds_value in data['doa']['position'].items():
            if isinstance(ds_value, np.ndarray):
                print(f"  {ds_name}: shape={ds_value.shape}, dtype={ds_value.dtype}")
    
    if 'identity' in data['doa'] and 'features' in data['doa']['identity']:
        print("Identity Features:")
        for ds_name, ds_value in data['doa']['identity']['features'].items():
            if isinstance(ds_value, np.ndarray):
                print(f"  {ds_name}: shape={ds_value.shape}, dtype={ds_value.dtype}")

# 6. Session đầu tiên
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
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `estm_bdw` | `dict` | Hop parameters datasets | `data['estm_bdw']['fc']` |
| `request` | `dict` | Request info | `data['request']['label']` |
| `request['label']` | `dict` | Parsed label dictionary | `data['request']['label']['key']` |
| `doa` | `dict` | DOA data | `data['doa']['position']` |
| `doa['position']` | `dict` | Position datasets | `data['doa']['position']['vecDoas']` |
| `doa['identity']['features']` | `dict` | Identity feature datasets | `data['doa']['identity']['features']['meanBws']` |
| `sessions` | `list` | Danh sách các sessions | `data['sessions'][0]` |
| `sessions[i]['id']` | `str` | Session ID | `session['id']` |
| `sessions[i]['iq']` | `np.ndarray` | Complex IQ data (I + j*Q) | `session['iq']` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `iq` là `complex128` (số phức 128-bit)
   - IQ được đọc từ dataset xen kẽ (I, Q, I, Q...) và xử lý thành complex
   - Các datasets khác có thể là float, int tùy theo file

2. **Cấu trúc IQ**:
   - Dataset `iq` chứa dữ liệu xen kẽ: [I, Q, I, Q, ...]
   - Được xử lý thành complex: `iq = I + j*Q`
   - Nếu số lượng phần tử lẻ, phần tử cuối sẽ bị bỏ qua

3. **Label parsing**:
   - Label được parse từ text thành dictionary
   - Format: các dòng dạng `key=value` hoặc plain text
   - Plain text được lưu với key dạng `line_1`, `line_2`, ...

4. **Xử lý dữ liệu**:
   - Luôn kiểm tra `len(session['iq']) > 0` trước khi sử dụng
   - Sử dụng `numpy` để xử lý các phép toán trên mảng
   - Sử dụng `.real` và `.imag` để lấy I và Q riêng biệt
   - Sử dụng `np.abs()` và `np.angle()` để tính magnitude và phase

5. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB gốc**: `read_identifier.m`
- **Code Python**: `reader_identifier_h5.py`
- **HDF5 Documentation**: https://www.hdfgroup.org/solutions/hdf5/

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản reader**: 1.0
**Tương thích với**: MATLAB `read_identifier.m`

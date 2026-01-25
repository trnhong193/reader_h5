# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE DF.H5

## 1. TỔNG QUAN

File `df.h5` là file HDF5 chứa dữ liệu DF/DOA (Direction Finding / Direction of Arrival). File này được đọc bởi module Python `reader_df_h5.py` dựa trên code MATLAB `reader_df.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: DF/DOA data (Pulses, DOA vectors, Calibration)
- **Số sessions**: 53 sessions
- **Số bảng calibration**: 3 tables
- **Số nhóm configuration**: 5 groups
- **Cấu trúc chính**: 
  - `/attribute/configuration`: Chứa cấu hình (attributes)
  - `/attribute/calibration/calibs`: Chứa dữ liệu hiệu chuẩn (datasets)
  - `/session`: Chứa dữ liệu pulses và DOA của các sessions

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
df.h5
├── /attribute
│   ├── /configuration              # → configuration
│   │   ├── /antParams               # → configuration['antParams'] (attributes)
│   │   ├── /filterParams            # → configuration['filterParams'] (attributes)
│   │   └── ... (các sub-groups khác)
│   │
│   └── /calibration
│       └── /calibs                  # → calibration
│           ├── /0                   # → calibration['Table_0'] (datasets: pow1, dps...)
│           ├── /1                   # → calibration['Table_1'] (datasets)
│           └── ... (các bảng khác)
│
└── /session                         # → sessions
    ├── /000xx                       # Session ID
    │   ├── Datasets (pulses)        # → sessions[i].pulses (amp, fc, bw...)
    │   └── /doa
    │       └── /doa
    │           ├── /0               # → sessions[i].doa['Target_0']
    │           │   ├── /position    # → position (datasets: vecDoas...)
    │           │   ├── /velocity     # → velocity (datasets: velocDoas...)
    │           │   └── /identity
    │           │       └── /features # → identity_features (datasets: meanBws, meanFcs...)
    │           ├── /1               # → sessions[i].doa['Target_1']
    │           │   └── ...
    │           └── ... (các targets khác)
    ├── /000yy
    │   └── ...
    └── ... (nhiều sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute/configuration` Group

Group này chứa các cấu hình dưới dạng attributes:

- Mỗi sub-group (antParams, filterParams...) chứa attributes
- Được đọc vào `data['configuration'][sub_name]`
- Ví dụ: `data['configuration']['antParams']` chứa các attributes của antParams

#### B. `/attribute/calibration/calibs` Group

Group này chứa các bảng hiệu chuẩn dưới dạng datasets:

- Mỗi sub-group (0, 1, 2...) chứa datasets (pow1, dps...)
- Được đọc vào `data['calibration']['Table_0']`, `data['calibration']['Table_1']`, ...
- Mỗi bảng chứa các datasets như: pow1, dps, ...

#### C. `/session` Group

Group này chứa dữ liệu sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa:
  - **Pulses datasets**: Trực tiếp tại session (amp, fc, bw...)
  - **DOA data**: Cấu trúc lồng nhau `/doa/doa/0,1,2...`
    - Mỗi target (0, 1, 2...) có:
      - `position`: Datasets (vecDoas...)
      - `velocity`: Datasets (velocDoas...)
      - `identity_features`: Datasets (meanBws, meanFcs...)

---

## 3. INPUT VÀ OUTPUT CỦA READER

### 3.1. Input

**Hàm**: `read_df_h5(filename: str)`

**Tham số**:
- `filename` (str): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'../../00_DATA_h5/df.h5'`

### 3.2. Output

**Kiểu trả về**: `Dict[str, Any]`

**Cấu trúc output**:

```python
{
    'configuration': {
        'antParams': {                    # Attributes từ /attribute/configuration/antParams
            'attr1': value1,
            'attr2': value2,
            # ...
        },
        'filterParams': {                  # Attributes từ /attribute/configuration/filterParams
            # ...
        },
        # ... (các sub-groups khác)
    },
    
    'calibration': {
        'Table_0': {                       # Datasets từ /attribute/calibration/calibs/0
            'pow1': np.ndarray,
            'dps': np.ndarray,
            # ... (các datasets khác)
        },
        'Table_1': {                       # Datasets từ /attribute/calibration/calibs/1
            # ...
        },
        # ... (các bảng khác)
    },
    
    'sessions': [
        {
            'id': '000xx',                  # Session ID
            'pulses': {                    # Datasets từ session (pulses)
                'amp': np.ndarray,
                'fc': np.ndarray,           # Frequency center
                'bw': np.ndarray,           # Bandwidth
                # ... (các datasets khác)
            },
            'doa': {
                'Target_0': {
                    'position': {           # Datasets từ /doa/doa/0/position
                        'vecDoas': np.ndarray,  # DOA vectors
                        # ... (các datasets khác)
                    },
                    'velocity': {           # Datasets từ /doa/doa/0/velocity
                        'velocDoas': np.ndarray,
                        # ... (các datasets khác)
                    },
                    'identity_features': {  # Datasets từ /doa/doa/0/identity/features
                        'meanBws': np.ndarray,
                        'meanFcs': np.ndarray,
                        # ... (các datasets khác)
                    }
                },
                'Target_1': {...},
                # ... (các targets khác)
            }
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
from reader_df_h5 import read_df_h5

# Đọc file
filename = 'path/to/df.h5'
data = read_df_h5(filename)

# Truy cập thông tin
print(f"Số sessions: {len(data['sessions'])}")
print(f"Số bảng calibration: {len(data.get('calibration', {}))}")
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin Configuration

```python
# Lấy toàn bộ configuration
configuration = data['configuration']

# Lấy antParams
if 'antParams' in data['configuration']:
    ant_params = data['configuration']['antParams']
    # Truy cập các attributes
    # attr_value = ant_params.get('attr_name', None)

# Lấy filterParams
if 'filterParams' in data['configuration']:
    filter_params = data['configuration']['filterParams']
    # ...

# Duyệt qua tất cả configuration groups
for group_name, group_attrs in data['configuration'].items():
    print(f"{group_name}: {len(group_attrs)} attributes")
```

#### B. Lấy dữ liệu Calibration

```python
# Lấy toàn bộ calibration
calibration = data['calibration']

# Lấy Table_0
if 'Table_0' in data['calibration']:
    table_0 = data['calibration']['Table_0']
    
    # Lấy pow1
    if 'pow1' in table_0:
        pow1 = table_0['pow1']  # numpy array
        print(f"pow1: shape={pow1.shape}, dtype={pow1.dtype}")
    
    # Lấy dps
    if 'dps' in table_0:
        dps = table_0['dps']  # numpy array
        print(f"dps: shape={dps.shape}, dtype={dps.dtype}")

# Duyệt qua tất cả calibration tables
for table_name, table_data in data['calibration'].items():
    print(f"{table_name}: {len(table_data)} datasets")
    for ds_name, ds_value in table_data.items():
        if isinstance(ds_value, np.ndarray):
            print(f"  {ds_name}: shape={ds_value.shape}, dtype={ds_value.dtype}")
```

#### C. Lấy dữ liệu Sessions

**1. Lấy danh sách tất cả sessions:**

```python
# Lấy số lượng sessions
num_sessions = len(data['sessions'])
print(f"Có {num_sessions} sessions")

# Lấy session đầu tiên
first_session = data['sessions'][0]
```

**2. Lấy thông tin pulses từ một session:**

```python
# Lấy session theo index
session = data['sessions'][0]

# Lấy Session ID
session_id = session['id']
print(f"Session ID: {session_id}")

# Lấy pulses
pulses = session['pulses']

# Lấy các trường cụ thể
if 'fc' in pulses:
    fc = pulses['fc']  # Frequency center
    print(f"Frequency center: {len(fc)} pulses")
    print(f"  Min: {fc.min():.2f}, Max: {fc.max():.2f}")

if 'bw' in pulses:
    bw = pulses['bw']  # Bandwidth
    print(f"Bandwidth: {len(bw)} pulses")

if 'amp' in pulses:
    amp = pulses['amp']  # Amplitude
    print(f"Amplitude: {len(amp)} pulses")
```

**3. Lấy dữ liệu DOA từ một session:**

```python
# Lấy session
session = data['sessions'][0]

# Lấy DOA
doa = session['doa']

# Lấy Target_0
if 'Target_0' in doa:
    target_0 = doa['Target_0']
    
    # Lấy position (vecDoas)
    if 'position' in target_0:
        position = target_0['position']
        if 'vecDoas' in position:
            vec_doas = position['vecDoas']  # numpy array
            print(f"DOA vectors: shape={vec_doas.shape}, dtype={vec_doas.dtype}")
            # vec_doas có thể là 2D array: [n_samples, n_dimensions]
    
    # Lấy velocity (velocDoas)
    if 'velocity' in target_0:
        velocity = target_0['velocity']
        if 'velocDoas' in velocity:
            veloc_doas = velocity['velocDoas']  # numpy array
            print(f"Velocity DOA: shape={veloc_doas.shape}, dtype={veloc_doas.dtype}")
    
    # Lấy identity_features
    if 'identity_features' in target_0:
        identity = target_0['identity_features']
        if 'meanBws' in identity:
            mean_bws = identity['meanBws']  # numpy array
            print(f"Mean BWs: shape={mean_bws.shape}, dtype={mean_bws.dtype}")
        
        if 'meanFcs' in identity:
            mean_fcs = identity['meanFcs']  # numpy array
            print(f"Mean FCs: shape={mean_fcs.shape}, dtype={mean_fcs.dtype}")
```

**4. Duyệt qua tất cả sessions và targets:**

```python
import numpy as np

# Duyệt qua tất cả sessions
for i, session in enumerate(data['sessions']):
    session_id = session['id']
    pulses = session['pulses']
    doa = session['doa']
    
    print(f"\nSession {i} ({session_id}):")
    
    # Pulses
    if 'fc' in pulses:
        print(f"  Pulses: {len(pulses['fc'])} xung")
    
    # DOA targets
    print(f"  DOA Targets: {len(doa)} targets")
    for target_name, target_data in doa.items():
        print(f"    {target_name}:")
        if 'position' in target_data and 'vecDoas' in target_data['position']:
            vec = target_data['position']['vecDoas']
            print(f"      Position vectors: {vec.shape}")
        if 'identity_features' in target_data:
            print(f"      Identity features: {len(target_data['identity_features'])} datasets")
    
    # Ví dụ: chỉ xử lý 5 sessions đầu
    if i >= 5:
        break
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```python
#!/usr/bin/env python3
"""
Ví dụ sử dụng reader_df_h5.py
"""

import numpy as np
from reader_df_h5 import read_df_h5

# 1. Đọc file
filename = '../../00_DATA_h5/df.h5'
print(f"Đang đọc file: {filename}")
data = read_df_h5(filename)

# 2. Hiển thị thông tin chung
print("\n=== THÔNG TIN CHUNG ===")
print(f"Số sessions: {len(data['sessions'])}")
print(f"Số bảng calibration: {len(data.get('calibration', {}))}")
print(f"Số nhóm configuration: {len(data.get('configuration', {}))}")

# 3. Configuration
if 'configuration' in data:
    print("\n=== CONFIGURATION ===")
    for group_name, group_attrs in data['configuration'].items():
        print(f"{group_name}: {len(group_attrs)} attributes")
        for attr_name in list(group_attrs.keys())[:3]:
            print(f"  {attr_name}: ...")

# 4. Calibration
if 'calibration' in data:
    print("\n=== CALIBRATION ===")
    for table_name, table_data in data['calibration'].items():
        print(f"{table_name}: {len(table_data)} datasets")
        for ds_name in list(table_data.keys())[:3]:
            ds_val = table_data[ds_name]
            if isinstance(ds_val, np.ndarray):
                print(f"  {ds_name}: shape={ds_val.shape}, dtype={ds_val.dtype}")

# 5. Session đầu tiên
print("\n=== SESSION ĐẦU TIÊN ===")
if data['sessions']:
    session = data['sessions'][0]
    print(f"Session ID: {session['id']}")
    
    # Pulses
    if session['pulses']:
        print("\nPulses:")
        for pulse_name, pulse_val in session['pulses'].items():
            if isinstance(pulse_val, np.ndarray):
                print(f"  {pulse_name}: shape={pulse_val.shape}, dtype={pulse_val.dtype}")
    
    # DOA
    if session['doa']:
        print("\nDOA:")
        for target_name, target_data in session['doa'].items():
            print(f"  {target_name}:")
            if 'position' in target_data:
                print(f"    position: {len(target_data['position'])} datasets")
            if 'velocity' in target_data:
                print(f"    velocity: {len(target_data['velocity'])} datasets")
            if 'identity_features' in target_data:
                print(f"    identity_features: {len(target_data['identity_features'])} datasets")
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `configuration` | `dict` | Configuration groups với attributes | `data['configuration']['antParams']` |
| `calibration` | `dict` | Calibration tables với datasets | `data['calibration']['Table_0']` |
| `calibration['Table_X']` | `dict` | Datasets trong bảng calibration | `data['calibration']['Table_0']['pow1']` |
| `sessions` | `list` | Danh sách các sessions | `data['sessions'][0]` |
| `sessions[i]['id']` | `str` | Session ID | `session['id']` |
| `sessions[i]['pulses']` | `dict` | Pulse datasets | `session['pulses']['fc']` |
| `sessions[i]['doa']` | `dict` | DOA targets | `session['doa']['Target_0']` |
| `sessions[i]['doa']['Target_X']['position']` | `dict` | Position datasets | `target['position']['vecDoas']` |
| `sessions[i]['doa']['Target_X']['velocity']` | `dict` | Velocity datasets | `target['velocity']['velocDoas']` |
| `sessions[i]['doa']['Target_X']['identity_features']` | `dict` | Identity feature datasets | `target['identity_features']['meanBws']` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - Tất cả datasets là `numpy.ndarray`
   - Configuration attributes có thể là string, int, float tùy theo file

2. **Cấu trúc lồng nhau**:
   - DOA có cấu trúc lồng nhau sâu: `/doa/doa/0/position`
   - Mỗi session có thể có nhiều targets (Target_0, Target_1, ...)
   - Mỗi target có position, velocity, và identity_features

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra key có tồn tại trước khi truy cập (sử dụng `in` hoặc `.get()`)
   - Sử dụng `numpy` để xử lý các phép toán trên mảng
   - Kiểm tra shape của arrays trước khi xử lý

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

5. **Cấu trúc DOA**:
   - Cấu trúc DOA rất lồng nhau, cần chú ý khi truy cập
   - Mỗi target có thể có hoặc không có position, velocity, identity_features

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB gốc**: `reader_df.m`
- **Code Python**: `reader_df_h5.py`
- **HDF5 Documentation**: https://www.hdfgroup.org/solutions/hdf5/

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản reader**: 1.0
**Tương thích với**: MATLAB `reader_df.m`

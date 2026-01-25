# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE SPECTRUM.H5 (MATLAB)

## 1. TỔNG QUAN

File `spectrum.h5` là file HDF5 chứa dữ liệu Spectrum. File này được đọc bởi hàm MATLAB `read_spectrum_data.m`.

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
│   └── Attributes (trực tiếp)    # → data.global_info
│
└── /session                      # Group chứa dữ liệu spectrum
    ├── /000xx                    # Session ID
    │   ├── Attributes            # → data.sessions(i).attributes
    │   ├── /source               # → data.sessions(i).source_info
    │   │   └── Attributes
    │   └── /sample_decoded       # Dataset: Decoded spectrum samples
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
   - Được đọc vào `data.global_info`
   - Chứa thông tin chung như: `client_ip`, `frequency`, `bandwidth`, `channel`, `mission`, ...

#### B. `/session` Group

Group này chứa dữ liệu spectrum của các sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa:
  - **Attributes**: Thông tin chung của session (timestamp, freq, bw, ...)
  - **`/source` sub-group**: Thông tin thiết bị (attributes)
  - **`/sample_decoded` dataset**: Vector dữ liệu spectrum đã giải mã (double array)

---

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `read_spectrum_data(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/spectrum.h5'`
  - Ví dụ: `'../../00_DATA_h5/spectrum.h5'`

**Yêu cầu**:
- MATLAB R2016b trở lên (để sử dụng `isfile`)
- Toolbox: Không cần toolbox đặc biệt, chỉ cần HDF5 support (có sẵn trong MATLAB)

### 3.2. Output

**Kiểu trả về**: `struct`

**Cấu trúc output**:

```matlab
data = 
    global_info: [1×1 struct]      % Attributes từ /attribute
    sessions:    [N×1 struct]      % Struct array chứa các sessions

% Chi tiết global_info:
data.global_info = 
    client_ip: '10.61.169.181'
    frequency: 5800000000
    bandwidth: 480000
    ...

% Chi tiết sessions:
data.sessions(1) = 
    id:          '000xx'           % Session ID
    attributes:  [1×1 struct]      % Attributes của session
    source_info: [1×1 struct]      % Thông tin thiết bị
    samples:     [M×1 double]      % Vector dữ liệu spectrum

% Chi tiết attributes:
data.sessions(1).attributes = 
    timestamp: ...
    frequency: ...                 % Hz
    bandwidth: ...                 % Hz
    ...

% Chi tiết source_info:
data.sessions(1).source_info = 
    device_name: ...
    ...
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `read_spectrum_data.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/spectrum.h5';
data = read_spectrum_data(filename);

% Truy cập thông tin
fprintf('Số sessions: %d\n', length(data.sessions));
if isfield(data.global_info, 'frequency')
    fprintf('Frequency: %g Hz\n', data.global_info.frequency);
end
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin chung (Global Info)

```matlab
% Lấy toàn bộ global_info
global_info = data.global_info;

% Lấy từng trường cụ thể
if isfield(data.global_info, 'client_ip')
    client_ip = data.global_info.client_ip;
end
if isfield(data.global_info, 'frequency')
    frequency = data.global_info.frequency;  % Hz
end
if isfield(data.global_info, 'bandwidth')
    bandwidth = data.global_info.bandwidth;  % Hz
end

% In ra tất cả các trường
fields = fieldnames(data.global_info);
for i = 1:length(fields)
    field_name = fields{i};
    field_value = data.global_info.(field_name);
    if ischar(field_value) || isstring(field_value)
        fprintf('%s: %s\n', field_name, char(field_value));
    else
        fprintf('%s: %g\n', field_name, field_value);
    end
end
```

#### B. Lấy dữ liệu Sessions

**1. Lấy danh sách tất cả sessions:**

```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);
fprintf('Có %d sessions\n', num_sessions);

% Lấy session đầu tiên
first_session = data.sessions(1);
```

**2. Lấy thông tin từ một session:**

```matlab
% Lấy session theo index
session = data.sessions(1);

% Lấy Session ID
session_id = session.id;
fprintf('Session ID: %s\n', session_id);

% Lấy attributes của session
if ~isempty(session.attributes)
    attributes = session.attributes;
    if isfield(attributes, 'frequency')
        freq = attributes.frequency;  % Hz
    end
    if isfield(attributes, 'bandwidth')
        bw = attributes.bandwidth;  % Hz
    end
    if isfield(attributes, 'timestamp')
        timestamp = attributes.timestamp;
    end
end
```

**3. Lấy source info:**

```matlab
% Lấy session
session = data.sessions(1);

% Lấy source info
if ~isempty(session.source_info)
    source_info = session.source_info;
    % Truy cập các trường trong source_info
    % Ví dụ: device_name = source_info.device_name;
end
```

**4. Lấy dữ liệu samples (spectrum):**

```matlab
% Lấy session
session = data.sessions(1);

% Lấy dữ liệu spectrum
samples = session.samples;  % double array
fprintf('Samples: size=%s, class=%s\n', ...
    mat2str(size(samples)), class(samples));
fprintf('Samples (5 đầu): %s\n', mat2str(samples(1:5)));

% Tính toán từ samples
% Min, Max, Mean
fprintf('Min: %.2f, Max: %.2f, Mean: %.2f\n', ...
    min(samples), max(samples), mean(samples));

% Power (nếu cần)
power = samples .^ 2;
fprintf('Power: mean=%.2f\n', mean(power));
```

**5. Duyệt qua tất cả sessions:**

```matlab
% Duyệt qua tất cả sessions
for i = 1:length(data.sessions)
    session = data.sessions(i);
    session_id = session.id;
    attributes = session.attributes;
    source_info = session.source_info;
    samples = session.samples;
    
    % Xử lý dữ liệu...
    if ~isempty(samples)
        fprintf('Session %d (%s): %d samples\n', ...
            i, session_id, length(samples));
        if ~isempty(attributes) && isfield(attributes, 'frequency')
            fprintf('  Frequency: %g Hz\n', attributes.frequency);
        end
        fprintf('  Min: %.2f, Max: %.2f\n', ...
            min(samples), max(samples));
    end
    
    % Ví dụ: chỉ xử lý 10 sessions đầu
    if i >= 10
        break;
    end
end
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```matlab
%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5
filename = '../../00_DATA_h5/spectrum.h5';

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_spectrum_data
try
    allData = read_spectrum_data(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. HIỂN THỊ THÔNG TIN CHUNG
fprintf('\n==================================================\n');
fprintf(' THÔNG TIN TỔNG QUAN\n');
fprintf('==================================================\n');
fprintf('Số sessions: %d\n', length(allData.sessions));

if isfield(allData, 'global_info') && ~isempty(allData.global_info)
    fprintf('\nGlobal Info:\n');
    fields = fieldnames(allData.global_info);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = allData.global_info.(field_name);
        if ischar(field_value) || isstring(field_value)
            fprintf('  %s: %s\n', field_name, char(field_value));
        else
            fprintf('  %s: %g\n', field_name, field_value);
        end
    end
end

%% 3. XỬ LÝ DỮ LIỆU TỪ SESSION ĐẦU TIÊN
fprintf('\n==================================================\n');
fprintf(' XỬ LÝ SESSION ĐẦU TIÊN\n');
fprintf('==================================================\n');

if ~isempty(allData.sessions)
    session = allData.sessions(1);
    fprintf('Session ID: %s\n', session.id);
    
    % Attributes
    if ~isempty(session.attributes)
        fprintf('\nAttributes:\n');
        fields = fieldnames(session.attributes);
        for i = 1:length(fields)
            field_name = fields{i};
            field_value = session.attributes.(field_name);
            if ischar(field_value) || isstring(field_value)
                fprintf('  %s: %s\n', field_name, char(field_value));
            else
                fprintf('  %s: %g\n', field_name, field_value);
            end
        end
    end
    
    % Source info
    if ~isempty(session.source_info)
        fprintf('\nSource Info:\n');
        fields = fieldnames(session.source_info);
        for i = 1:length(fields)
            field_name = fields{i};
            field_value = session.source_info.(field_name);
            if ischar(field_value) || isstring(field_value)
                fprintf('  %s: %s\n', field_name, char(field_value));
            else
                fprintf('  %s: %g\n', field_name, field_value);
            end
        end
    end
    
    % Samples
    if ~isempty(session.samples)
        samples = session.samples;
        fprintf('\nSamples: %d điểm\n', length(samples));
        fprintf('  Min: %.2f, Max: %.2f, Mean: %.2f\n', ...
            min(samples), max(samples), mean(samples));
    end
end
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `global_info` | `struct` | Attributes từ `/attribute` | `data.global_info.frequency` |
| `sessions` | `struct array` | Mảng các sessions | `data.sessions(1)` |
| `sessions(i).id` | `char/string` | Session ID | `session.id` |
| `sessions(i).attributes` | `struct` | Attributes của session | `session.attributes.frequency` |
| `sessions(i).source_info` | `struct` | Thông tin thiết bị | `session.source_info.device_name` |
| `sessions(i).samples` | `double array` | Vector spectrum samples | `session.samples` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `samples` là `double` (số thực double precision)
   - Các attributes có thể là string, int, float tùy theo file

2. **Cấu trúc session**:
   - Mỗi session có thể có hoặc không có `/source` sub-group
   - Mỗi session có thể có hoặc không có `/sample_decoded` dataset
   - Kiểm tra `isempty()` trước khi sử dụng

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `~isempty(session.samples)` trước khi sử dụng
   - Sử dụng `isfield()` để kiểm tra trường có tồn tại không
   - Sử dụng `double()` để convert nếu cần

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

5. **Struct array vs Cell array**:
   - `sessions` là struct array, không phải cell array
   - Truy cập: `data.sessions(1)` (không phải `data.sessions{1}`)
   - Duyệt: `for i = 1:length(data.sessions)` hoặc `for session = data.sessions'`

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB**: `read_spectrum_data.m`
- **File debug/test**: `debug_spectrum.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản hàm**: 1.0
**Tương thích với**: MATLAB R2016b trở lên

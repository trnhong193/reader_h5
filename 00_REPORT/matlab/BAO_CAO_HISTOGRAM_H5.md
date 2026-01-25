# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE HISTOGRAM.H5 (MATLAB)

## 1. TỔNG QUAN

File `histogram.h5` là file HDF5 chứa dữ liệu Histogram. File này được đọc bởi hàm MATLAB `read_histogram_h5_multitype.m`.

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
│   └── Attributes (trực tiếp)    # → data.global_info
│
└── /session                      # Group chứa dữ liệu histogram
    ├── /000xx                    # Session ID
    │   ├── Attributes            # → data.sessions(i).attributes (bao gồm message_type)
    │   ├── /context              # → data.sessions(i).context_info
    │   │   └── Attributes
    │   ├── /source               # → data.sessions(i).source_info
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
   - Được đọc vào `data.global_info`
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

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `read_histogram_h5_multitype(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/histogram.h5'`
  - Ví dụ: `'../../00_DATA_h5/histogram.h5'`

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
    id:              '000xx'           % Session ID
    type:            'AccumulatedPower' % Message type
    attributes:      [1×1 struct]      % Attributes của session
    context_info:    [1×1 struct]      % Thông tin ngữ cảnh
    source_info:     [1×1 struct]      % Thông tin thiết bị
    sample_decoded:  [M×1 double]      % Histogram (AccumulatedPower)
    acc_sample_decoded: []             % Accumulated (CrossingThresholdPower)
    crx_sample_decoded: []             % Crossing (CrossingThresholdPower)

% Chi tiết attributes:
data.sessions(1).attributes = 
    message_type: 'AccumulatedPower'
    timestamp: ...
    frequency: ...                 % Hz
    bandwidth: ...                 % Hz
    ...

% Chi tiết context_info:
data.sessions(1).context_info = 
    field1: ...
    ...

% Chi tiết source_info:
data.sessions(1).source_info = 
    device: ...
    ...
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `read_histogram_h5_multitype.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/histogram.h5';
data = read_histogram_h5_multitype(filename);

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

% Lấy Message Type
msg_type = session.type;
fprintf('Message Type: %s\n', msg_type);

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

**3. Lấy context info:**

```matlab
% Lấy session
session = data.sessions(1);

% Lấy context info
if ~isempty(session.context_info)
    context_info = session.context_info;
    % Truy cập các trường trong context_info
    % Ví dụ: value = context_info.field;
end
```

**4. Lấy source info:**

```matlab
% Lấy session
session = data.sessions(1);

% Lấy source info
if ~isempty(session.source_info)
    source_info = session.source_info;
    % Truy cập các trường trong source_info
    % Ví dụ: device = source_info.device;
end
```

**5. Lấy dữ liệu histogram (phụ thuộc vào message_type):**

```matlab
% Lấy session
session = data.sessions(1);
msg_type = session.type;

% Xử lý theo loại message
if contains(msg_type, 'CrossingThresholdPower')
    % TRƯỜNG HỢP: CrossingThresholdPower
    % Đọc acc_sample_decoded
    acc_data = session.acc_sample_decoded;  % double array
    fprintf('acc_sample_decoded: size=%s, class=%s\n', ...
        mat2str(size(acc_data)), class(acc_data));
    fprintf('  Min: %.2e, Max: %.2e, Sum: %.2e\n', ...
        min(acc_data), max(acc_data), sum(acc_data));
    
    % Đọc crx_sample_decoded
    crx_data = session.crx_sample_decoded;  % double array
    fprintf('crx_sample_decoded: size=%s, class=%s\n', ...
        mat2str(size(crx_data)), class(crx_data));
    fprintf('  Min: %.2e, Max: %.2e, Sum: %.2e\n', ...
        min(crx_data), max(crx_data), sum(crx_data));
else
    % TRƯỜNG HỢP: AccumulatedPower (hoặc mặc định)
    hist_data = session.sample_decoded;  % double array
    fprintf('sample_decoded: size=%s, class=%s\n', ...
        mat2str(size(hist_data)), class(hist_data));
    fprintf('  Min: %.2e, Max: %.2e, Sum: %.2e\n', ...
        min(hist_data), max(hist_data), sum(hist_data));
end
```

**6. Duyệt qua tất cả sessions:**

```matlab
% Duyệt qua tất cả sessions
for i = 1:length(data.sessions)
    session = data.sessions(i);
    session_id = session.id;
    msg_type = session.type;
    attributes = session.attributes;
    context_info = session.context_info;
    source_info = session.source_info;
    
    % Xử lý dữ liệu theo loại message
    if contains(msg_type, 'CrossingThresholdPower')
        acc_data = session.acc_sample_decoded;
        crx_data = session.crx_sample_decoded;
        
        if ~isempty(acc_data)
            fprintf('Session %d (%s): CrossingThresholdPower\n', i, session_id);
            fprintf('  acc: %d bins, Sum=%.2e\n', length(acc_data), sum(acc_data));
            fprintf('  crx: %d bins, Sum=%.2e\n', length(crx_data), sum(crx_data));
        end
    else
        hist_data = session.sample_decoded;
        
        if ~isempty(hist_data)
            fprintf('Session %d (%s): AccumulatedPower\n', i, session_id);
            fprintf('  samples: %d bins, Sum=%.2e\n', length(hist_data), sum(hist_data));
        end
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
filename = '../../00_DATA_h5/histogram.h5';

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_histogram_h5_multitype
try
    allData = read_histogram_h5_multitype(filename);
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
    fprintf('Message Type: %s\n', session.type);
    
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
    
    % Context info
    if ~isempty(session.context_info)
        fprintf('\nContext Info:\n');
        fields = fieldnames(session.context_info);
        for i = 1:length(fields)
            field_name = fields{i};
            field_value = session.context_info.(field_name);
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
    
    % Samples (phụ thuộc vào message_type)
    msg_type = session.type;
    if contains(msg_type, 'CrossingThresholdPower')
        if ~isempty(session.acc_sample_decoded)
            acc_data = session.acc_sample_decoded;
            fprintf('\nacc_sample_decoded: %d bins\n', length(acc_data));
            fprintf('  Min: %.2e, Max: %.2e, Sum: %.2e\n', ...
                min(acc_data), max(acc_data), sum(acc_data));
        end
        
        if ~isempty(session.crx_sample_decoded)
            crx_data = session.crx_sample_decoded;
            fprintf('\ncrx_sample_decoded: %d bins\n', length(crx_data));
            fprintf('  Min: %.2e, Max: %.2e, Sum: %.2e\n', ...
                min(crx_data), max(crx_data), sum(crx_data));
        end
    else
        if ~isempty(session.sample_decoded)
            hist_data = session.sample_decoded;
            fprintf('\nsample_decoded: %d bins\n', length(hist_data));
            fprintf('  Min: %.2e, Max: %.2e, Sum: %.2e\n', ...
                min(hist_data), max(hist_data), sum(hist_data));
        end
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
| `sessions(i).type` | `char/string` | Message type | `session.type` |
| `sessions(i).attributes` | `struct` | Attributes của session | `session.attributes.frequency` |
| `sessions(i).context_info` | `struct` | Thông tin ngữ cảnh | `session.context_info.field` |
| `sessions(i).source_info` | `struct` | Thông tin thiết bị | `session.source_info.device` |
| `sessions(i).sample_decoded` | `double array` | Histogram (AccumulatedPower) | `session.sample_decoded` |
| `sessions(i).acc_sample_decoded` | `double array` | Accumulated histogram (CrossingThresholdPower) | `session.acc_sample_decoded` |
| `sessions(i).crx_sample_decoded` | `double array` | Crossing histogram (CrossingThresholdPower) | `session.crx_sample_decoded` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - Tất cả samples là `double` (số thực double precision)
   - Các attributes có thể là string, int, float tùy theo file

2. **Message Type**:
   - **AccumulatedPower**: Sử dụng `sample_decoded`
   - **CrossingThresholdPower**: Sử dụng `acc_sample_decoded` VÀ `crx_sample_decoded`
   - Luôn kiểm tra `session.type` hoặc `session.attributes.message_type` trước khi truy cập dữ liệu

3. **Cấu trúc session**:
   - Mỗi session có thể có hoặc không có `/context` sub-group
   - Mỗi session có thể có hoặc không có `/source` sub-group
   - Dataset phụ thuộc vào `message_type` trong attributes

4. **Xử lý dữ liệu**:
   - Luôn kiểm tra `~isempty(session.sample_decoded)` (hoặc tương ứng) trước khi sử dụng
   - Sử dụng `isfield()` để kiểm tra trường có tồn tại không
   - Sử dụng `double()` để convert nếu cần

5. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Hàm có waitbar để hiển thị tiến trình
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

6. **Struct array vs Cell array**:
   - `sessions` là struct array, không phải cell array
   - Truy cập: `data.sessions(1)` (không phải `data.sessions{1}`)
   - Duyệt: `for i = 1:length(data.sessions)` hoặc `for session = data.sessions'`

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB**: `read_histogram_h5_multitype.m`
- **File debug/test**: `debug_histogram.m`, `check_histogram.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản hàm**: multitype
**Tương thích với**: MATLAB R2016b trở lên

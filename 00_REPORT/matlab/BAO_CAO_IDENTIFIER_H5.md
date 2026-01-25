# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE IDENTIFIER.H5 (MATLAB)

## 1. TỔNG QUAN

File `identifier.h5` là file HDF5 chứa dữ liệu Identifier. File này được đọc bởi hàm MATLAB `read_identifier.m`.

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
│   ├── /estm_bdw                      # → data.estm_bdw (datasets: fc, ...)
│   │   └── Datasets                   # Tham số Hop
│   │
│   ├── /request                       # → data.request
│   │   └── /label                     # Dataset: Label text
│   │
│   └── /doa                           # → data.doa
│       ├── /position                  # → data.doa.position (datasets: vecDoas, ...)
│       └── /identity
│           └── /features              # → data.doa.identity.features (datasets: meanBws, meanFcs, ...)
│
└── /session                           # → data.sessions
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
- Được đọc vào `data.estm_bdw`
- Ví dụ: `data.estm_bdw.fc` chứa frequency centers của các hops

#### B. `/attribute/request/label` Dataset

Dataset này chứa label text:

- Được đọc và parse thành struct
- Được đọc vào `data.request.label`
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
  - Dữ liệu được xử lý thành complex IQ: `iq = complex(I, Q)`

---

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `read_identifier(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/identifier.h5'`
  - Ví dụ: `'../../00_DATA_h5/identifier.h5'`

**Yêu cầu**:
- MATLAB R2016b trở lên (để sử dụng `isfile`)
- Toolbox: Không cần toolbox đặc biệt, chỉ cần HDF5 support (có sẵn trong MATLAB)

### 3.2. Output

**Kiểu trả về**: `struct`

**Cấu trúc output**:

```matlab
data = 
    estm_bdw:  [1×1 struct]      % Hop parameters
    request:   [1×1 struct]      % Request info
    doa:       [1×1 struct]      % DOA data
    sessions:  [N×1 struct]      % Struct array chứa các sessions

% Chi tiết estm_bdw:
data.estm_bdw = 
    fc:        [M×1 double]      % Frequency centers (Hop parameters)
    ...

% Chi tiết request:
data.request = 
    label:     [1×1 struct]      % Parsed label struct

% Chi tiết request.label:
data.request.label = 
    key1:      'value1'
    key2:      'value2'
    ...

% Chi tiết doa:
data.doa = 
    position:  [1×1 struct]      % Position datasets
    identity:  [1×1 struct]      % Identity data

% Chi tiết doa.position:
data.doa.position = 
    vecDoas:   [M×N double]      % DOA vectors
    ...

% Chi tiết doa.identity.features:
data.doa.identity.features = 
    meanBws:   [P×1 double]      % Mean bandwidths
    meanFcs:   [P×1 double]      % Mean frequency centers
    ...

% Chi tiết sessions:
data.sessions(1) = 
    id:        '000xx'            % Session ID
    iq:        [K×1 complex double]  % Complex IQ data (I + j*Q)
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `read_identifier.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/identifier.h5';
data = read_identifier(filename);

% Truy cập thông tin
fprintf('Số sessions: %d\n', length(data.sessions));
fprintf('Có estm_bdw: %d\n', isfield(data, 'estm_bdw'));
fprintf('Có doa: %d\n', isfield(data, 'doa'));
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin estm_bdw (Hop Parameters)

```matlab
% Lấy estm_bdw
if isfield(data, 'estm_bdw')
    estm_bdw = data.estm_bdw;
    
    % Lấy fc (frequency centers)
    if isfield(estm_bdw, 'fc')
        fc = estm_bdw.fc;  % double array
        fprintf('Frequency centers: %d hops\n', length(fc));
        fprintf('  Min: %.2f, Max: %.2f\n', min(fc), max(fc));
    end
    
    % Duyệt qua tất cả datasets
    fields = fieldnames(estm_bdw);
    for i = 1:length(fields)
        ds_name = fields{i};
        ds_value = estm_bdw.(ds_name);
        fprintf('%s: size=%s, class=%s\n', ...
            ds_name, mat2str(size(ds_value)), class(ds_value));
    end
end
```

#### B. Lấy thông tin Request Label

```matlab
% Lấy request label
if isfield(data, 'request') && isfield(data.request, 'label')
    label = data.request.label;
    
    % Truy cập các key-value pairs
    fields = fieldnames(label);
    for i = 1:length(fields)
        key = fields{i};
        value = label.(key);
        fprintf('%s: %s\n', key, char(value));
    end
    
    % Lấy giá trị cụ thể nếu biết key
    % value = label.key_name;
end
```

#### C. Lấy dữ liệu DOA

```matlab
% Lấy DOA
if isfield(data, 'doa')
    doa = data.doa;
    
    % Lấy position (vecDoas)
    if isfield(doa, 'position') && isfield(doa.position, 'vecDoas')
        vec_doas = doa.position.vecDoas;  % double array
        fprintf('DOA vectors: size=%s, class=%s\n', ...
            mat2str(size(vec_doas)), class(vec_doas));
    end
    
    % Lấy identity features
    if isfield(doa, 'identity') && isfield(doa.identity, 'features')
        features = doa.identity.features;
        
        if isfield(features, 'meanBws')
            mean_bws = features.meanBws;  % double array
            fprintf('Mean BWs: size=%s, class=%s\n', ...
                mat2str(size(mean_bws)), class(mean_bws));
        end
        
        if isfield(features, 'meanFcs')
            mean_fcs = features.meanFcs;  % double array
            fprintf('Mean FCs: size=%s, class=%s\n', ...
                mat2str(size(mean_fcs)), class(mean_fcs));
        end
    end
end
```

#### D. Lấy dữ liệu Sessions

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

% Lấy IQ data
iq_data = session.iq;  % complex double array
fprintf('IQ data: %d samples, class=%s\n', length(iq_data), class(iq_data));
```

**3. Xử lý dữ liệu IQ:**

```matlab
% Lấy session
session = data.sessions(1);
iq_data = session.iq;

% Lấy I và Q riêng biệt
i_data = real(iq_data);  % In-phase (real part)
q_data = imag(iq_data);  % Quadrature (imaginary part)

fprintf('I (real): Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
    min(i_data), max(i_data), mean(i_data));
fprintf('Q (imag): Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
    min(q_data), max(q_data), mean(q_data));

% Tính toán từ IQ phức
% Biên độ (Magnitude)
magnitude = abs(iq_data);
fprintf('Magnitude: Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
    min(magnitude), max(magnitude), mean(magnitude));

% Phase (Góc pha)
phase = angle(iq_data);
fprintf('Phase: Min=%.3f, Max=%.3f\n', min(phase), max(phase));

% Power
power = abs(iq_data).^2;
fprintf('Power: Mean=%.2f\n', mean(power));
```

**4. Duyệt qua tất cả sessions:**

```matlab
% Duyệt qua tất cả sessions
for i = 1:length(data.sessions)
    session = data.sessions(i);
    session_id = session.id;
    iq_data = session.iq;
    
    % Xử lý dữ liệu...
    if ~isempty(iq_data)
        magnitude = abs(iq_data);
        fprintf('Session %d (%s): %d samples\n', i, session_id, length(iq_data));
        fprintf('  Magnitude: Min=%.2f, Max=%.2f\n', ...
            min(magnitude), max(magnitude));
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
filename = '../../00_DATA_h5/identifier.h5';

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_identifier
try
    allData = read_identifier(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. HIỂN THỊ THÔNG TIN CHUNG
fprintf('\n==================================================\n');
fprintf(' THÔNG TIN TỔNG QUAN\n');
fprintf('==================================================\n');
fprintf('Số sessions: %d\n', length(allData.sessions));
fprintf('Có estm_bdw: %d\n', isfield(allData, 'estm_bdw'));
fprintf('Có request: %d\n', isfield(allData, 'request'));
fprintf('Có doa: %d\n', isfield(allData, 'doa'));

%% 3. ESTM_BDW (HOP PARAMETERS)
fprintf('\n==================================================\n');
fprintf(' ESTM_BDW (HOP PARAMETERS)\n');
fprintf('==================================================\n');
if isfield(allData, 'estm_bdw')
    fields = fieldnames(allData.estm_bdw);
    for i = 1:length(fields)
        ds_name = fields{i};
        ds_value = allData.estm_bdw.(ds_name);
        fprintf('%s: size=%s, class=%s\n', ...
            ds_name, mat2str(size(ds_value)), class(ds_value));
        if strcmp(ds_name, 'fc') && ~isempty(ds_value)
            fprintf('  Min: %.2f, Max: %.2f\n', min(ds_value), max(ds_value));
        end
    end
end

%% 4. REQUEST LABEL
fprintf('\n==================================================\n');
fprintf(' REQUEST LABEL\n');
fprintf('==================================================\n');
if isfield(allData, 'request') && isfield(allData.request, 'label')
    label = allData.request.label;
    fields = fieldnames(label);
    for i = 1:min(10, length(fields))
        key = fields{i};
        value = label.(key);
        if ischar(value) || isstring(value)
            fprintf('%s: %s\n', key, char(value));
        else
            fprintf('%s: %g\n', key, value);
        end
    end
end

%% 5. DOA
fprintf('\n==================================================\n');
fprintf(' DOA\n');
fprintf('==================================================\n');
if isfield(allData, 'doa')
    if isfield(allData.doa, 'position')
        fprintf('Position:\n');
        fields = fieldnames(allData.doa.position);
        for i = 1:length(fields)
            ds_name = fields{i};
            ds_value = allData.doa.position.(ds_name);
            fprintf('  %s: size=%s\n', ds_name, mat2str(size(ds_value)));
        end
    end
    
    if isfield(allData.doa, 'identity') && isfield(allData.doa.identity, 'features')
        fprintf('Identity Features:\n');
        fields = fieldnames(allData.doa.identity.features);
        for i = 1:length(fields)
            ds_name = fields{i};
            ds_value = allData.doa.identity.features.(ds_name);
            fprintf('  %s: size=%s\n', ds_name, mat2str(size(ds_value)));
        end
    end
end

%% 6. SESSION ĐẦU TIÊN
fprintf('\n==================================================\n');
fprintf(' SESSION ĐẦU TIÊN\n');
fprintf('==================================================\n');
if ~isempty(allData.sessions)
    session = allData.sessions(1);
    fprintf('Session ID: %s\n', session.id);
    
    if ~isempty(session.iq)
        iq_data = session.iq;
        fprintf('IQ data: %d samples\n', length(iq_data));
        fprintf('  I (real): Min=%.2f, Max=%.2f\n', ...
            min(real(iq_data)), max(real(iq_data)));
        fprintf('  Q (imag): Min=%.2f, Max=%.2f\n', ...
            min(imag(iq_data)), max(imag(iq_data)));
        fprintf('  Magnitude: Min=%.2f, Max=%.2f\n', ...
            min(abs(iq_data)), max(abs(iq_data)));
        
        % Vẽ biểu đồ
        figure('Name', ['Identifier: ' session.id], 'Color', 'w');
        plot(iq_data, '.');
        title('Constellation Diagram');
        axis equal; grid on;
    end
end
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `estm_bdw` | `struct` | Hop parameters datasets | `data.estm_bdw.fc` |
| `request` | `struct` | Request info | `data.request.label` |
| `request.label` | `struct` | Parsed label struct | `data.request.label.key` |
| `doa` | `struct` | DOA data | `data.doa.position` |
| `doa.position` | `struct` | Position datasets | `data.doa.position.vecDoas` |
| `doa.identity.features` | `struct` | Identity feature datasets | `data.doa.identity.features.meanBws` |
| `sessions` | `struct array` | Mảng các sessions | `data.sessions(1)` |
| `sessions(i).id` | `char/string` | Session ID | `session.id` |
| `sessions(i).iq` | `complex double array` | Complex IQ data (I + j*Q) | `session.iq` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `iq` là `complex double` (số phức double precision)
   - IQ được đọc từ dataset xen kẽ (I, Q, I, Q...) và xử lý thành complex
   - Các datasets khác có thể là float, int tùy theo file

2. **Cấu trúc IQ**:
   - Dataset `iq` chứa dữ liệu xen kẽ: [I, Q, I, Q, ...]
   - Được xử lý thành complex: `iq = complex(I, Q)`
   - Nếu số lượng phần tử lẻ, phần tử cuối sẽ bị bỏ qua

3. **Label parsing**:
   - Label được parse từ text thành struct
   - Format: các dòng dạng `key=value` hoặc plain text
   - Plain text được lưu với key dạng `line_1`, `line_2`, ...

4. **Xử lý dữ liệu**:
   - Luôn kiểm tra `~isempty(session.iq)` trước khi sử dụng
   - Sử dụng `real()` và `imag()` để lấy I và Q riêng biệt
   - Sử dụng `abs()` và `angle()` để tính magnitude và phase
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

- **Code MATLAB**: `read_identifier.m`
- **File debug/test**: `test_identifier.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản hàm**: 1.0
**Tương thích với**: MATLAB R2016b trở lên

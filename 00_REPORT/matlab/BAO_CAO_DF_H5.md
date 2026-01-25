# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE DF.H5 (MATLAB)

## 1. TỔNG QUAN

File `df.h5` là file HDF5 chứa dữ liệu DF/DOA (Direction Finding / Direction of Arrival). File này được đọc bởi hàm MATLAB `reader_df.m`.

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
│   ├── /configuration              # → data.configuration
│   │   ├── /antParams               # → data.configuration.antParams (attributes)
│   │   ├── /filterParams            # → data.configuration.filterParams (attributes)
│   │   └── ... (các sub-groups khác)
│   │
│   └── /calibration
│       └── /calibs                  # → data.calibration
│           ├── /0                   # → data.calibration.Table_0 (datasets: pow1, dps...)
│           ├── /1                   # → data.calibration.Table_1 (datasets)
│           └── ... (các bảng khác)
│
└── /session                         # → data.sessions
    ├── /000xx                       # Session ID
    │   ├── Datasets (pulses)        # → data.sessions(i).pulses (amp, fc, bw...)
    │   └── /doa
    │       └── /doa
    │           ├── /0               # → data.sessions(i).doa.Target_0
    │           │   ├── /position    # → position (datasets: vecDoas...)
    │           │   ├── /velocity     # → velocity (datasets: velocDoas...)
    │           │   └── /identity
    │           │       └── /features # → identity_features (datasets: meanBws, meanFcs...)
    │           ├── /1               # → data.sessions(i).doa.Target_1
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
- Được đọc vào `data.configuration.antParams`, `data.configuration.filterParams`, ...
- Ví dụ: `data.configuration.antParams` chứa các attributes của antParams

#### B. `/attribute/calibration/calibs` Group

Group này chứa các bảng hiệu chuẩn dưới dạng datasets:

- Mỗi sub-group (0, 1, 2...) chứa datasets (pow1, dps...)
- Được đọc vào `data.calibration.Table_0`, `data.calibration.Table_1`, ...
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

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `read_df(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/df.h5'`
  - Ví dụ: `'../../00_DATA_h5/df.h5'`

**Yêu cầu**:
- MATLAB R2016b trở lên (để sử dụng `isfile`)
- Toolbox: Không cần toolbox đặc biệt, chỉ cần HDF5 support (có sẵn trong MATLAB)

### 3.2. Output

**Kiểu trả về**: `struct`

**Cấu trúc output**:

```matlab
data = 
    configuration: [1×1 struct]      % Configuration groups
    calibration:   [1×1 struct]      % Calibration tables
    sessions:      [N×1 struct]      % Struct array chứa các sessions

% Chi tiết configuration:
data.configuration = 
    antParams:     [1×1 struct]      % Attributes từ /attribute/configuration/antParams
    filterParams:  [1×1 struct]      % Attributes từ /attribute/configuration/filterParams
    ...

% Chi tiết calibration:
data.calibration = 
    Table_0:       [1×1 struct]      % Datasets từ /attribute/calibration/calibs/0
    Table_1:       [1×1 struct]      % Datasets từ /attribute/calibration/calibs/1
    ...

% Chi tiết Table_0:
data.calibration.Table_0 = 
    pow1:          [M×1 double]      % Dataset pow1
    dps:           [M×1 double]      % Dataset dps
    ...

% Chi tiết sessions:
data.sessions(1) = 
    id:            '000xx'           % Session ID
    pulses:        [1×1 struct]      % Pulse datasets
    doa:           [1×1 struct]     % DOA targets

% Chi tiết pulses:
data.sessions(1).pulses = 
    amp:           [K×1 double]     % Amplitude
    fc:            [K×1 double]      % Frequency center
    bw:            [K×1 double]      % Bandwidth
    ...

% Chi tiết doa:
data.sessions(1).doa = 
    Target_0:      [1×1 struct]     % Target 0
    Target_1:      [1×1 struct]     % Target 1
    ...

% Chi tiết Target_0:
data.sessions(1).doa.Target_0 = 
    position:      [1×1 struct]     % Position datasets
    velocity:      [1×1 struct]     % Velocity datasets
    identity_features: [1×1 struct] % Identity feature datasets

% Chi tiết position:
data.sessions(1).doa.Target_0.position = 
    vecDoas:       [M×N double]      % DOA vectors
    ...

% Chi tiết identity_features:
data.sessions(1).doa.Target_0.identity_features = 
    meanBws:       [P×1 double]      % Mean bandwidths
    meanFcs:       [P×1 double]      % Mean frequency centers
    ...
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `reader_df.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/df.h5';
data = read_df(filename);

% Truy cập thông tin
fprintf('Số sessions: %d\n', length(data.sessions));
fprintf('Số bảng calibration: %d\n', length(fieldnames(data.calibration)));
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin Configuration

```matlab
% Lấy toàn bộ configuration
configuration = data.configuration;

% Lấy antParams
if isfield(data.configuration, 'antParams')
    ant_params = data.configuration.antParams;
    % Truy cập các attributes
    % attr_value = ant_params.attr_name;
end

% Lấy filterParams
if isfield(data.configuration, 'filterParams')
    filter_params = data.configuration.filterParams;
    % ...
end

% Duyệt qua tất cả configuration groups
fields = fieldnames(data.configuration);
for i = 1:length(fields)
    group_name = fields{i};
    group_attrs = data.configuration.(group_name);
    fprintf('%s: %d attributes\n', group_name, length(fieldnames(group_attrs)));
end
```

#### B. Lấy dữ liệu Calibration

```matlab
% Lấy toàn bộ calibration
calibration = data.calibration;

% Lấy Table_0
if isfield(data.calibration, 'Table_0')
    table_0 = data.calibration.Table_0;
    
    % Lấy pow1
    if isfield(table_0, 'pow1')
        pow1 = table_0.pow1;  % double array
        fprintf('pow1: size=%s, class=%s\n', ...
            mat2str(size(pow1)), class(pow1));
    end
    
    % Lấy dps
    if isfield(table_0, 'dps')
        dps = table_0.dps;  % double array
        fprintf('dps: size=%s, class=%s\n', ...
            mat2str(size(dps)), class(dps));
    end
end

% Duyệt qua tất cả calibration tables
fields = fieldnames(data.calibration);
for i = 1:length(fields)
    table_name = fields{i};
    table_data = data.calibration.(table_name);
    fprintf('%s: %d datasets\n', table_name, length(fieldnames(table_data)));
end
```

#### C. Lấy dữ liệu Sessions

**1. Lấy danh sách tất cả sessions:**

```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);
fprintf('Có %d sessions\n', num_sessions);

% Lấy session đầu tiên
first_session = data.sessions(1);
```

**2. Lấy thông tin pulses từ một session:**

```matlab
% Lấy session theo index
session = data.sessions(1);

% Lấy Session ID
session_id = session.id;
fprintf('Session ID: %s\n', session_id);

% Lấy pulses
pulses = session.pulses;

% Lấy các trường cụ thể
if isfield(pulses, 'fc')
    fc = pulses.fc;  % Frequency center
    fprintf('Frequency center: %d pulses\n', length(fc));
    fprintf('  Min: %.2f, Max: %.2f\n', min(fc), max(fc));
end

if isfield(pulses, 'bw')
    bw = pulses.bw;  % Bandwidth
    fprintf('Bandwidth: %d pulses\n', length(bw));
end

if isfield(pulses, 'amp')
    amp = pulses.amp;  % Amplitude
    fprintf('Amplitude: %d pulses\n', length(amp));
end
```

**3. Lấy dữ liệu DOA từ một session:**

```matlab
% Lấy session
session = data.sessions(1);

% Lấy DOA
doa = session.doa;

% Lấy Target_0
if isfield(doa, 'Target_0')
    target_0 = doa.Target_0;
    
    % Lấy position (vecDoas)
    if isfield(target_0, 'position') && isfield(target_0.position, 'vecDoas')
        vec_doas = target_0.position.vecDoas;  % double array
        fprintf('DOA vectors: size=%s, class=%s\n', ...
            mat2str(size(vec_doas)), class(vec_doas));
        % vec_doas có thể là 2D array: [n_samples, n_dimensions]
    end
    
    % Lấy velocity (velocDoas)
    if isfield(target_0, 'velocity') && isfield(target_0.velocity, 'velocDoas')
        veloc_doas = target_0.velocity.velocDoas;  % double array
        fprintf('Velocity DOA: size=%s, class=%s\n', ...
            mat2str(size(veloc_doas)), class(veloc_doas));
    end
    
    % Lấy identity_features
    if isfield(target_0, 'identity_features')
        identity = target_0.identity_features;
        if isfield(identity, 'meanBws')
            mean_bws = identity.meanBws;  % double array
            fprintf('Mean BWs: size=%s, class=%s\n', ...
                mat2str(size(mean_bws)), class(mean_bws));
        end
        
        if isfield(identity, 'meanFcs')
            mean_fcs = identity.meanFcs;  % double array
            fprintf('Mean FCs: size=%s, class=%s\n', ...
                mat2str(size(mean_fcs)), class(mean_fcs));
        end
    end
end
```

**4. Duyệt qua tất cả sessions và targets:**

```matlab
% Duyệt qua tất cả sessions
for i = 1:length(data.sessions)
    session = data.sessions(i);
    session_id = session.id;
    pulses = session.pulses;
    doa = session.doa;
    
    fprintf('\nSession %d (%s):\n', i, session_id);
    
    % Pulses
    if isfield(pulses, 'fc')
        fprintf('  Pulses: %d xung\n', length(pulses.fc));
    end
    
    % DOA targets
    doa_fields = fieldnames(doa);
    fprintf('  DOA Targets: %d targets\n', length(doa_fields));
    for j = 1:length(doa_fields)
        target_name = doa_fields{j};
        target_data = doa.(target_name);
        fprintf('    %s:\n', target_name);
        if isfield(target_data, 'position') && isfield(target_data.position, 'vecDoas')
            vec = target_data.position.vecDoas;
            fprintf('      Position vectors: %s\n', mat2str(size(vec)));
        end
        if isfield(target_data, 'identity_features')
            fprintf('      Identity features: %d datasets\n', ...
                length(fieldnames(target_data.identity_features)));
        end
    end
    
    % Ví dụ: chỉ xử lý 5 sessions đầu
    if i >= 5
        break;
    end
end
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```matlab
%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5
filename = '../../00_DATA_h5/df.h5';

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_df
try
    allData = read_df(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. HIỂN THỊ THÔNG TIN CHUNG
fprintf('\n==================================================\n');
fprintf(' THÔNG TIN TỔNG QUAN\n');
fprintf('==================================================\n');
fprintf('Số sessions: %d\n', length(allData.sessions));
fprintf('Số bảng calibration: %d\n', length(fieldnames(allData.calibration)));
fprintf('Số nhóm configuration: %d\n', length(fieldnames(allData.configuration)));

%% 3. CONFIGURATION
fprintf('\n==================================================\n');
fprintf(' CONFIGURATION\n');
fprintf('==================================================\n');
if isfield(allData, 'configuration')
    fields = fieldnames(allData.configuration);
    for i = 1:length(fields)
        group_name = fields{i};
        group_attrs = allData.configuration.(group_name);
        fprintf('%s: %d attributes\n', group_name, length(fieldnames(group_attrs)));
    end
end

%% 4. CALIBRATION
fprintf('\n==================================================\n');
fprintf(' CALIBRATION\n');
fprintf('==================================================\n');
if isfield(allData, 'calibration')
    fields = fieldnames(allData.calibration);
    for i = 1:length(fields)
        table_name = fields{i};
        table_data = allData.calibration.(table_name);
        fprintf('%s: %d datasets\n', table_name, length(fieldnames(table_data)));
        % Hiển thị một số datasets
        ds_fields = fieldnames(table_data);
        for j = 1:min(3, length(ds_fields))
            ds_name = ds_fields{j};
            ds_val = table_data.(ds_name);
            fprintf('  %s: size=%s\n', ds_name, mat2str(size(ds_val)));
        end
    end
end

%% 5. SESSION ĐẦU TIÊN
fprintf('\n==================================================\n');
fprintf(' SESSION ĐẦU TIÊN\n');
fprintf('==================================================\n');
if ~isempty(allData.sessions)
    session = allData.sessions(1);
    fprintf('Session ID: %s\n', session.id);
    
    % Pulses
    if ~isempty(session.pulses)
        fprintf('\nPulses:\n');
        pulse_fields = fieldnames(session.pulses);
        for i = 1:length(pulse_fields)
            pulse_name = pulse_fields{i};
            pulse_val = session.pulses.(pulse_name);
            fprintf('  %s: size=%s\n', pulse_name, mat2str(size(pulse_val)));
        end
    end
    
    % DOA
    if ~isempty(session.doa)
        fprintf('\nDOA:\n');
        doa_fields = fieldnames(session.doa);
        for i = 1:length(doa_fields)
            target_name = doa_fields{i};
            target_data = session.doa.(target_name);
            fprintf('  %s:\n', target_name);
            if isfield(target_data, 'position')
                fprintf('    position: %d datasets\n', length(fieldnames(target_data.position)));
            end
            if isfield(target_data, 'velocity')
                fprintf('    velocity: %d datasets\n', length(fieldnames(target_data.velocity)));
            end
            if isfield(target_data, 'identity_features')
                fprintf('    identity_features: %d datasets\n', ...
                    length(fieldnames(target_data.identity_features)));
            end
        end
    end
end
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `configuration` | `struct` | Configuration groups với attributes | `data.configuration.antParams` |
| `calibration` | `struct` | Calibration tables với datasets | `data.calibration.Table_0` |
| `calibration.Table_X` | `struct` | Datasets trong bảng calibration | `data.calibration.Table_0.pow1` |
| `sessions` | `struct array` | Mảng các sessions | `data.sessions(1)` |
| `sessions(i).id` | `char/string` | Session ID | `session.id` |
| `sessions(i).pulses` | `struct` | Pulse datasets | `session.pulses.fc` |
| `sessions(i).doa` | `struct` | DOA targets | `session.doa.Target_0` |
| `sessions(i).doa.Target_X.position` | `struct` | Position datasets | `target.position.vecDoas` |
| `sessions(i).doa.Target_X.velocity` | `struct` | Velocity datasets | `target.velocity.velocDoas` |
| `sessions(i).doa.Target_X.identity_features` | `struct` | Identity feature datasets | `target.identity_features.meanBws` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - Tất cả datasets là `double` arrays
   - Configuration attributes có thể là string, int, float tùy theo file

2. **Cấu trúc lồng nhau**:
   - DOA có cấu trúc lồng nhau sâu: `/doa/doa/0/position`
   - Mỗi session có thể có nhiều targets (Target_0, Target_1, ...)
   - Mỗi target có position, velocity, và identity_features

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `isfield()` trước khi truy cập
   - Sử dụng `double()` để convert nếu cần
   - Kiểm tra size của arrays trước khi xử lý

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Hàm có waitbar để hiển thị tiến trình
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

5. **Struct array vs Cell array**:
   - `sessions` là struct array, không phải cell array
   - Truy cập: `data.sessions(1)` (không phải `data.sessions{1}`)
   - Duyệt: `for i = 1:length(data.sessions)` hoặc `for session = data.sessions'`

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB**: `reader_df.m`
- **File debug/test**: `test_df.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản hàm**: 1.0
**Tương thích với**: MATLAB R2016b trở lên

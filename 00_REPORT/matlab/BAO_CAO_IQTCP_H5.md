# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE IQTCP.H5 (MATLAB)

## 1. TỔNG QUAN

File `iqtcp.h5` là file HDF5 chứa dữ liệu IQ (In-phase và Quadrature) từ Narrowband TCP. File này được đọc bởi hàm MATLAB `read_iqtcp_h5_verge2.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: IQ samples (Narrowband TCP)
- **Số sessions**: 46,072 sessions
- **Cấu trúc chính**: 
  - `/attribute`: Chứa metadata (thông tin chung, DDC, request, ...)
  - `/session`: Chứa dữ liệu IQ của các sessions

---

## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
iqtcp.h5
├── /attribute                    # Group chứa metadata
│   ├── Attributes (trực tiếp)    # → data.global_info
│   ├── /ddc                      # → data.ddc_info
│   │   └── Attributes
│   ├── /request                  # → data.request_info
│   │   └── Attributes
│   └── ... (các group con khác)
│
└── /session                      # Group chứa dữ liệu IQ
    ├── /000000000000000000       # Session ID
    │   ├── /i                    # Dataset: In-phase samples
    │   └── /q                    # Dataset: Quadrature samples
    ├── /000000000000000001
    │   ├── /i
    │   └── /q
    └── ... (46,072 sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute` Group

Group này chứa tất cả metadata của file:

1. **Attributes trực tiếp tại `/attribute`**:
   - Được đọc vào `data.global_info`
   - Chứa thông tin chung như: `client_ip`, `frequency`, `bandwidth`, `channel`, `mission`, ...

2. **Sub-groups trong `/attribute`**:
   - Mỗi sub-group được đọc vào `data.{name}_info`
   - Ví dụ: `/attribute/ddc` → `data.ddc_info`
   - Ví dụ: `/attribute/request` → `data.request_info`
   - Các sub-group có thể chứa:
     - Attributes (metadata)
     - Datasets (dữ liệu bổ sung, ví dụ: labels)

#### B. `/session` Group

Group này chứa dữ liệu IQ của tất cả sessions:

- Mỗi session có ID dạng: `000000000000000000`, `000000000000000001`, ...
- Mỗi session chứa 2 datasets:
  - `i`: In-phase samples (kiểu int32, shape: (512,))
  - `q`: Quadrature samples (kiểu int32, shape: (512,))

---

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `read_iqtcp_h5_verge2(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/iqtcp.h5'`
  - Ví dụ: `'../../00_DATA_h5/iqtcp.h5'`

**Yêu cầu**:
- MATLAB R2016b trở lên (để sử dụng `isfile`)
- Toolbox: Không cần toolbox đặc biệt, chỉ cần HDF5 support (có sẵn trong MATLAB)

### 3.2. Output

**Kiểu trả về**: `struct`

**Cấu trúc output**:

```matlab
data = 
    global_info: [1×1 struct]      % Attributes từ /attribute
    ddc_info:    [1×1 struct]      % Attributes từ /attribute/ddc
    request_info: [1×1 struct]     % Attributes từ /attribute/request
    sessions:    [46072×1 struct] % Mảng struct chứa các sessions

% Chi tiết global_info:
data.global_info = 
    client_ip: '10.61.169.181'
    frequency: 5800000000
    bandwidth: 480000
    channel: 0
    mission: 'Fc: 5800 MHz| Bw: 200 MHz| ...'
    ...

% Chi tiết ddc_info:
data.ddc_info = 
    channelIndex: 0
    frequency: '5800000000'
    deviceId: '0'
    ...

% Chi tiết request_info:
data.request_info = 
    fileName: 'narrowband_tcp'
    duration: '60000000000'
    checkpoint: '1768294156'
    ...

% Chi tiết sessions:
data.sessions(1) = 
    id: '000000000000000000'  % Session ID (char)
    i:  [512×1 int32]         % In-phase samples
    q:  [512×1 int32]         % Quadrature samples
    iq: [512×1 double]        % Complex IQ = I + j*Q (complex double)
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `read_iqtcp_h5_verge2.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/iqtcp.h5';
data = read_iqtcp_h5_verge2(filename);

% Truy cập thông tin
fprintf('Số sessions: %d\n', length(data.sessions));
fprintf('Frequency: %g Hz\n', data.global_info.frequency);
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin chung (Global Info)

```matlab
% Lấy toàn bộ global_info
global_info = data.global_info;

% Lấy từng trường cụ thể
client_ip = data.global_info.client_ip;
frequency = data.global_info.frequency;  % Hz
bandwidth = data.global_info.bandwidth;  % Hz
channel = data.global_info.channel;
mission = data.global_info.mission;

% In ra tất cả các trường
fields = fieldnames(data.global_info);
for i = 1:length(fields)
    field_name = fields{i};
    field_value = data.global_info.(field_name);
    fprintf('%s: %s\n', field_name, num2str(field_value));
end
```

#### B. Lấy thông tin DDC

```matlab
% Lấy toàn bộ ddc_info
ddc_info = data.ddc_info;

% Lấy từng trường cụ thể
channel_index = data.ddc_info.channelIndex;
ddc_frequency = data.ddc_info.frequency;
device_id = data.ddc_info.deviceId;
```

#### C. Lấy thông tin Request

```matlab
% Lấy toàn bộ request_info
request_info = data.request_info;

% Lấy từng trường cụ thể
file_name = data.request_info.fileName;
duration = data.request_info.duration;  % nanoseconds (string)
checkpoint = data.request_info.checkpoint;
```

#### D. Lấy dữ liệu IQ từ Sessions

**1. Lấy một session cụ thể:**

```matlab
% Lấy session đầu tiên
session_0 = data.sessions(1);

% Lấy session theo index
session_idx = 100;
session_100 = data.sessions(session_idx);

% Lấy session theo ID
target_id = '000000000000000100';
session = [];
for i = 1:length(data.sessions)
    if strcmp(data.sessions(i).id, target_id)
        session = data.sessions(i);
        break;
    end
end
```

**2. Lấy dữ liệu I, Q, và IQ:**

```matlab
% Lấy session
session = data.sessions(1);

% Lấy Session ID
session_id = session.id;
fprintf('Session ID: %s\n', session_id);

% Lấy dữ liệu I (In-phase)
i_data = session.i;  % int32 array, shape: [512×1]
fprintf('I data: size=%s, class=%s\n', mat2str(size(i_data)), class(i_data));
fprintf('I samples (5 đầu): %s\n', mat2str(i_data(1:5)));

% Lấy dữ liệu Q (Quadrature)
q_data = session.q;  % int32 array, shape: [512×1]
fprintf('Q data: size=%s, class=%s\n', mat2str(size(q_data)), class(q_data));
fprintf('Q samples (5 đầu): %s\n', mat2str(q_data(1:5)));

% Lấy dữ liệu IQ phức (I + j*Q)
iq_data = session.iq;  % complex double array, shape: [512×1]
fprintf('IQ data: size=%s, class=%s\n', mat2str(size(iq_data)), class(iq_data));
fprintf('IQ samples (5 đầu): %s\n', mat2str(iq_data(1:5)));

% Tính toán từ IQ phức
% Biên độ (Magnitude)
magnitude = abs(iq_data);
fprintf('Magnitude: min=%.2f, max=%.2f, mean=%.2f\n', ...
    min(magnitude), max(magnitude), mean(magnitude));

% Phase (Góc pha)
phase = angle(iq_data);
fprintf('Phase: min=%.3f, max=%.3f\n', min(phase), max(phase));

% Power
power = abs(iq_data).^2;
fprintf('Power: mean=%.2f\n', mean(power));
```

**3. Duyệt qua tất cả sessions:**

```matlab
% Duyệt qua tất cả sessions
for i = 1:length(data.sessions)
    session = data.sessions(i);
    session_id = session.id;
    i_data = session.i;
    q_data = session.q;
    iq_data = session.iq;
    
    % Xử lý dữ liệu...
    magnitude = abs(iq_data);
    phase = angle(iq_data);
    
    % Ví dụ: chỉ xử lý 10 sessions đầu
    if i >= 10
        break;
    end
end
```

**4. Lọc sessions có dữ liệu:**

```matlab
% Chỉ lấy các sessions có dữ liệu I và Q
valid_sessions = [];
for i = 1:length(data.sessions)
    session = data.sessions(i);
    if ~isempty(session.i) && ~isempty(session.q) && ...
       length(session.i) > 0 && length(session.q) > 0
        valid_sessions = [valid_sessions; session];
    end
end

fprintf('Số sessions có dữ liệu: %d\n', length(valid_sessions));
```

**5. Lấy thống kê của một session:**

```matlab
session = data.sessions(1);

if ~isempty(session.i) && length(session.i) > 0
    i_stats = struct();
    i_stats.min = min(session.i);
    i_stats.max = max(session.i);
    i_stats.mean = mean(double(session.i)));
    i_stats.std = std(double(session.i));
    i_stats.size = length(session.i);
    fprintf('I statistics:\n');
    disp(i_stats);
end

if ~isempty(session.q) && length(session.q) > 0
    q_stats = struct();
    q_stats.min = min(session.q);
    q_stats.max = max(session.q);
    q_stats.mean = mean(double(session.q)));
    q_stats.std = std(double(session.q));
    q_stats.size = length(session.q);
    fprintf('Q statistics:\n');
    disp(q_stats);
end

if ~isempty(session.iq) && length(session.iq) > 0
    iq_mag = abs(session.iq);
    iq_stats = struct();
    iq_stats.magnitude_min = min(iq_mag);
    iq_stats.magnitude_max = max(iq_mag);
    iq_stats.magnitude_mean = mean(iq_mag);
    iq_stats.phase_min = min(angle(session.iq));
    iq_stats.phase_max = max(angle(session.iq));
    iq_stats.size = length(session.iq);
    fprintf('IQ statistics:\n');
    disp(iq_stats);
end
```

**6. Vẽ biểu đồ I/Q data:**

```matlab
session = data.sessions(1);

if ~isempty(session.i) && ~isempty(session.q)
    figure('Name', ['IQ Data - Session ' session.id], 'Color', 'w');
    
    % Subplot 1: I & Q theo thời gian
    subplot(2,2,1);
    plot(session.i, 'b-', 'LineWidth', 0.5); hold on;
    plot(session.q, 'r-', 'LineWidth', 0.5);
    title(sprintf('Time Domain - I & Q (Session %s)', session.id), 'Interpreter', 'none');
    xlabel('Sample Index');
    ylabel('Amplitude');
    legend('I (In-phase)', 'Q (Quadrature)', 'Location', 'best');
    grid on;
    
    % Subplot 2: Constellation Diagram
    subplot(2,2,2);
    plot(session.i, session.q, '.', 'MarkerSize', 2);
    title('Constellation Diagram (I vs Q)');
    xlabel('I (In-phase)');
    ylabel('Q (Quadrature)');
    axis equal;
    grid on;
    
    % Subplot 3: Biên độ của tín hiệu phức
    subplot(2,2,3);
    iq_magnitude = abs(session.iq);
    plot(iq_magnitude, 'g-', 'LineWidth', 0.5);
    title('Magnitude |I + jQ|');
    xlabel('Sample Index');
    ylabel('|IQ|');
    grid on;
    
    % Subplot 4: Phase của tín hiệu phức
    subplot(2,2,4);
    iq_phase = angle(session.iq);
    plot(iq_phase, 'm-', 'LineWidth', 0.5);
    title('Phase (angle)');
    xlabel('Sample Index');
    ylabel('Phase (rad)');
    grid on;
    
    % Tạo title chung nếu có thông tin frequency
    if isfield(data.global_info, 'frequency')
        freq_mhz = data.global_info.frequency / 1e6;
        sgtitle(sprintf('IQ Data Analysis - Freq: %.2f MHz', freq_mhz), ...
            'FontSize', 12, 'FontWeight', 'bold');
    end
end
```

---

## 5. VÍ DỤ CODE HOÀN CHỈNH

```matlab
%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5 của bạn (Narrowband TCP - I/Q samples)
filename = '/path/to/iqtcp.h5'; 

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_iq_tcp_h5_verge2
try
    allData = read_iqtcp_h5_verge2(filename);
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

if isfield(allData, 'ddc_info') && ~isempty(allData.ddc_info)
    fprintf('\nDDC Info:\n');
    fields = fieldnames(allData.ddc_info);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = allData.ddc_info.(field_name);
        fprintf('  %s: %s\n', field_name, num2str(field_value));
    end
end

if isfield(allData, 'request_info') && ~isempty(allData.request_info)
    fprintf('\nRequest Info:\n');
    fields = fieldnames(allData.request_info);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = allData.request_info.(field_name);
        fprintf('  %s: %s\n', field_name, num2str(field_value));
    end
end

%% 3. XỬ LÝ DỮ LIỆU TỪ SESSION ĐẦU TIÊN
fprintf('\n==================================================\n');
fprintf(' XỬ LÝ SESSION ĐẦU TIÊN\n');
fprintf('==================================================\n');

if ~isempty(allData.sessions)
    session = allData.sessions(1);
    fprintf('Session ID: %s\n', session.id);
    
    if ~isempty(session.i)
        fprintf('I: size=%s, class=%s\n', mat2str(size(session.i)), class(session.i));
        fprintf('  Min=%d, Max=%d, Mean=%.2f\n', ...
            min(session.i), max(session.i), mean(double(session.i)));
    end
    
    if ~isempty(session.q)
        fprintf('Q: size=%s, class=%s\n', mat2str(size(session.q)), class(session.q));
        fprintf('  Min=%d, Max=%d, Mean=%.2f\n', ...
            min(session.q), max(session.q), mean(double(session.q)));
    end
    
    if ~isempty(session.iq)
        iq_mag = abs(session.iq);
        fprintf('IQ: size=%s, class=%s\n', mat2str(size(session.iq)), class(session.iq));
        fprintf('  Magnitude: Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
            min(iq_mag), max(iq_mag), mean(iq_mag));
        fprintf('  Phase: Min=%.3f, Max=%.3f\n', ...
            min(angle(session.iq)), max(angle(session.iq)));
    end
end

%% 4. DUYỆT QUA MỘT SỐ SESSIONS
fprintf('\n==================================================\n');
fprintf(' DUYỆT QUA 5 SESSIONS ĐẦU\n');
fprintf('==================================================\n');

num_display = min(5, length(allData.sessions));
for i = 1:num_display
    session = allData.sessions(i);
    if ~isempty(session.iq) && length(session.iq) > 0
        iq_mag = abs(session.iq);
        fprintf('Session %d (ID: %s): Magnitude mean=%.2f, Size=%d\n', ...
            i, session.id, mean(iq_mag), length(session.iq));
    end
end
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `global_info` | `struct` | Attributes từ `/attribute` | `data.global_info.frequency` |
| `ddc_info` | `struct` | Attributes từ `/attribute/ddc` | `data.ddc_info.channelIndex` |
| `request_info` | `struct` | Attributes từ `/attribute/request` | `data.request_info.fileName` |
| `sessions` | `struct array` | Mảng struct chứa các sessions | `data.sessions(1)` |
| `sessions(i).id` | `char` | ID của session thứ i | `data.sessions(1).id` |
| `sessions(i).i` | `int32 array` | In-phase samples | `data.sessions(1).i` |
| `sessions(i).q` | `int32 array` | Quadrature samples | `data.sessions(1).q` |
| `sessions(i).iq` | `complex double array` | Complex IQ = I + j*Q | `data.sessions(1).iq` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `i` và `q` là `int32` (số nguyên 32-bit)
   - `iq` là `complex double` (số phức double precision, được tính từ I và Q)

2. **Kích thước**:
   - Mỗi session có 512 samples (I và Q)
   - File có 46,072 sessions
   - `sessions` là struct array, truy cập bằng `data.sessions(i)` không phải `data.sessions{i}`

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `isempty()` trước khi sử dụng dữ liệu
   - Sử dụng `double()` để convert int32 sang double khi tính toán
   - Sử dụng `abs()` và `angle()` để tính magnitude và phase từ complex IQ

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian (46,072 sessions)
   - Hàm có waitbar để hiển thị tiến trình
   - Có thể tối ưu bằng cách chỉ đọc một số sessions cần thiết (cần sửa code)

5. **Tên field**:
   - MATLAB tự động chuyển đổi tên field thành valid MATLAB identifier
   - Ví dụ: `client_ip` → `client_ip` (nếu hợp lệ)
   - Sử dụng `matlab.lang.makeValidName()` để đảm bảo tên hợp lệ

6. **Struct array vs Cell array**:
   - `sessions` là struct array, không phải cell array
   - Truy cập: `data.sessions(1).id` (không phải `data.sessions{1}.id`)
   - Duyệt: `for i = 1:length(data.sessions)` hoặc `for session = data.sessions'`

---

## 8. SO SÁNH VỚI PYTHON

| Tính năng | MATLAB | Python |
|-----------|--------|--------|
| Kiểu dữ liệu output | `struct` | `dict` |
| Truy cập field | `data.global_info.frequency` | `data['global_info']['frequency']` |
| Sessions | Struct array `[N×1 struct]` | List of dicts `[{...}, {...}]` |
| Truy cập session | `data.sessions(1)` | `data['sessions'][0]` |
| Kiểu I/Q | `int32` | `int32` (numpy) |
| Kiểu IQ phức | `complex double` | `complex128` (numpy) |
| Indexing | 1-based | 0-based |
| Waitbar | Có sẵn | Không (có thể dùng tqdm) |

---

## 9. TÀI LIỆU THAM KHẢO

- **Code MATLAB**: `read_iqtcp_h5_verge2.m`
- **File debug/test**: `debug_iqtcp_verge2.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2025-01-XX  
**Phiên bản hàm**: verge2  
**Tương thích với**: MATLAB R2016b trở lên




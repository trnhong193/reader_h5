# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE DEMODULATION.H5 (MATLAB)

## 1. TỔNG QUAN

File `demodulation.h5` là file HDF5 chứa dữ liệu Demodulation (IQ). File này được đọc bởi hàm MATLAB `reader_demodulation_no_recursive.m`.

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
│   └── /request                      # → data.request
│       ├── /hwConfiguration          # → data.request.hwConfiguration (attributes)
│       ├── /libConfiguration         # → data.request.libConfiguration (attributes)
│       ├── /recordingOptions         # → data.request.recordingOptions (attributes)
│       ├── /source                   # → data.request.source (attributes)
│       ├── /spectrumOptions          # → data.request.spectrumOptions (attributes)
│       ├── /transaction              # → data.request.transaction (attributes)
│       └── ... (các sub-groups khác)
│
└── /session                          # → data.sessions
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
- Được đọc vào `data.request.hwConfiguration`, `data.request.libConfiguration`, ...
- Ví dụ: `data.request.hwConfiguration` chứa các attributes của hwConfiguration

#### B. `/session` Group

Group này chứa dữ liệu IQ của các sessions:

- Mỗi session có ID dạng: `000xx`, `000yy`, ...
- Mỗi session chứa 2 datasets:
  - **`i`**: In-phase samples (real part)
  - **`q`**: Quadrature samples (imaginary part)
- Dữ liệu được kết hợp thành complex IQ: `iq = i + j*q`

---

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `reader_demodulation_no_recursive(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/demodulation.h5'`
  - Ví dụ: `'../../00_DATA_h5/demodulation.h5'`

**Yêu cầu**:
- MATLAB R2016b trở lên (để sử dụng `isfile`)
- Toolbox: Không cần toolbox đặc biệt, chỉ cần HDF5 support (có sẵn trong MATLAB)

### 3.2. Output

**Kiểu trả về**: `struct`

**Cấu trúc output**:

```matlab
data = 
    request:  [1×1 struct]      % Request configuration
    sessions: [N×1 struct]      % Struct array chứa các sessions

% Chi tiết request:
data.request = 
    hwConfiguration:  [1×1 struct]      % Attributes từ /attribute/request/hwConfiguration
    libConfiguration: [1×1 struct]      % Attributes từ /attribute/request/libConfiguration
    recordingOptions: [1×1 struct]      % Attributes từ /attribute/request/recordingOptions
    source:           [1×1 struct]      % Attributes từ /attribute/request/source
    spectrumOptions:  [1×1 struct]      % Attributes từ /attribute/request/spectrumOptions
    transaction:      [1×1 struct]      % Attributes từ /attribute/request/transaction
    ...

% Chi tiết sessions:
data.sessions(1) = 
    id: '000xx'                  % Session ID
    iq: [M×1 complex double]     % Complex IQ data (I + j*Q)

% Chi tiết iq:
% iq là complex double array, được tạo từ datasets 'i' và 'q'
% iq = complex(i, q)
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `reader_demodulation_no_recursive.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/demodulation.h5';
data = reader_demodulation_no_recursive(filename);

% Truy cập thông tin
fprintf('Số sessions: %d\n', length(data.sessions));
fprintf('Số nhóm request: %d\n', length(fieldnames(data.request)));
```

### 4.3. Cách lấy các trường thông tin output

#### A. Lấy thông tin Request Configuration

```matlab
% Lấy toàn bộ request
request = data.request;

% Lấy hwConfiguration
if isfield(data.request, 'hwConfiguration')
    hw_config = data.request.hwConfiguration;
    % Truy cập các attributes
    % attr_value = hw_config.attr_name;
end

% Lấy libConfiguration
if isfield(data.request, 'libConfiguration')
    lib_config = data.request.libConfiguration;
    % ...
end

% Lấy recordingOptions
if isfield(data.request, 'recordingOptions')
    rec_options = data.request.recordingOptions;
    % ...
end

% Lấy source
if isfield(data.request, 'source')
    source = data.request.source;
    % ...
end

% Lấy spectrumOptions
if isfield(data.request, 'spectrumOptions')
    spec_options = data.request.spectrumOptions;
    % ...
end

% Lấy transaction
if isfield(data.request, 'transaction')
    transaction = data.request.transaction;
    % ...
end

% Duyệt qua tất cả request groups
fields = fieldnames(data.request);
for i = 1:length(fields)
    group_name = fields{i};
    group_attrs = data.request.(group_name);
    fprintf('%s: %d attributes\n', group_name, length(fieldnames(group_attrs)));
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
filename = '../../00_DATA_h5/demodulation.h5';

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm reader_demodulation_no_recursive
try
    allData = reader_demodulation_no_recursive(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. HIỂN THỊ THÔNG TIN CHUNG
fprintf('\n==================================================\n');
fprintf(' THÔNG TIN TỔNG QUAN\n');
fprintf('==================================================\n');
fprintf('Số sessions: %d\n', length(allData.sessions));
fprintf('Số nhóm request: %d\n', length(fieldnames(allData.request)));

%% 3. REQUEST CONFIGURATION
fprintf('\n==================================================\n');
fprintf(' REQUEST CONFIGURATION\n');
fprintf('==================================================\n');
if isfield(allData, 'request')
    fields = fieldnames(allData.request);
    for i = 1:length(fields)
        group_name = fields{i};
        group_attrs = allData.request.(group_name);
        fprintf('%s: %d attributes\n', group_name, length(fieldnames(group_attrs)));
    end
end

%% 4. SESSION ĐẦU TIÊN
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
        figure('Name', ['Demodulation: ' session.id], 'Color', 'w');
        
        % Subplot 1: Time Domain
        subplot(2,1,1);
        plot(real(iq_data), 'b'); hold on;
        plot(imag(iq_data), 'r');
        title('Time Domain (I & Q)');
        legend('I', 'Q'); grid on;
        
        % Subplot 2: Constellation
        subplot(2,1,2);
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
| `request` | `struct` | Request configuration groups với attributes | `data.request.hwConfiguration` |
| `request.hwConfiguration` | `struct` | Hardware configuration attributes | `data.request.hwConfiguration.attr` |
| `request.libConfiguration` | `struct` | Library configuration attributes | `data.request.libConfiguration.attr` |
| `request.recordingOptions` | `struct` | Recording options attributes | `data.request.recordingOptions.attr` |
| `request.source` | `struct` | Source attributes | `data.request.source.attr` |
| `request.spectrumOptions` | `struct` | Spectrum options attributes | `data.request.spectrumOptions.attr` |
| `request.transaction` | `struct` | Transaction attributes | `data.request.transaction.attr` |
| `sessions` | `struct array` | Mảng các sessions | `data.sessions(1)` |
| `sessions(i).id` | `char/string` | Session ID | `session.id` |
| `sessions(i).iq` | `complex double array` | Complex IQ data (I + j*Q) | `session.iq` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `iq` là `complex double` (số phức double precision)
   - I và Q được đọc từ datasets riêng biệt và kết hợp thành complex
   - Request attributes có thể là string, int, float tùy theo file

2. **Cấu trúc session**:
   - Mỗi session có 2 datasets: `i` và `q`
   - Dữ liệu được kết hợp: `iq = complex(i, q)`
   - Nếu `i` và `q` có độ dài khác nhau, chỉ lấy phần chung (min length)

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `~isempty(session.iq)` trước khi sử dụng
   - Sử dụng `real()` và `imag()` để lấy I và Q riêng biệt
   - Sử dụng `abs()` và `angle()` để tính magnitude và phase
   - Sử dụng `double()` để convert nếu cần

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều sessions
   - Hàm có waitbar để hiển thị tiến trình
   - Có thể tối ưu bằng cách chỉ xử lý một số sessions cần thiết

5. **Visualization**:
   - Có thể vẽ time domain (I và Q theo thời gian)
   - Có thể vẽ constellation diagram (Q vs I)

6. **Struct array vs Cell array**:
   - `sessions` là struct array, không phải cell array
   - Truy cập: `data.sessions(1)` (không phải `data.sessions{1}`)
   - Duyệt: `for i = 1:length(data.sessions)` hoặc `for session = data.sessions'`

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB**: `reader_demodulation_no_recursive.m`
- **File debug/test**: `test_demodulation_no_recursive.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản hàm**: no_recursive
**Tương thích với**: MATLAB R2016b trở lên

# BÁO CÁO CHI TIẾT: CẤU TRÚC FILE IQETHERNET.H5 (MATLAB)

## 1. TỔNG QUAN

File `iqethernet.h5` là file HDF5 chứa dữ liệu IQ (In-phase và Quadrature) từ Ethernet Packets. File này được đọc bởi hàm MATLAB `read_iq_ethernet_h5_verge.m`.

### Thông tin cơ bản:
- **Định dạng**: HDF5 (Hierarchical Data Format version 5)
- **Loại dữ liệu**: IQ samples (Ethernet Packets)
- **Cấu trúc chính**: 
  - `/attribute`: Chứa metadata (thông tin chung, DDC, request, ...)
  - `/session`: Chứa dữ liệu raw bytes của các Ethernet packets

---
## 2. CẤU TRÚC FILE H5

### 2.1. Cấu trúc tổng thể

```
iqethernet.h5
├── /attribute                    # Group chứa metadata
│   ├── Attributes (trực tiếp)    # → data.global_info
│   ├── /ddc                      # → data.global_info.ddc
│   │   └── Attributes
│   ├── /request                  # → data.global_info.request
│   │   └── Attributes
│   └── ... (các group con khác)
│
└── /session                      # Group chứa dữ liệu raw packets
    ├── /000000000000000000       # Session ID
    │   └── /raw                  # Dataset: Raw Ethernet packet bytes
    ├── /000000000000000001
    │   └── /raw
    └── ... (nhiều sessions)
```

### 2.2. Chi tiết các thành phần

#### A. `/attribute` Group

Group này chứa tất cả metadata của file:

1. **Attributes trực tiếp tại `/attribute`**:
   - Được đọc vào `data.global_info`
   - Chứa thông tin chung như: `client_ip`, `frequency`, `bandwidth`, `channel`, `mission`, ...

2. **Sub-groups trong `/attribute`**:
   - Mỗi sub-group được đọc vào `data.global_info.{sub_name}`
   - Ví dụ: `/attribute/ddc` → `data.global_info.ddc`
   - Ví dụ: `/attribute/request` → `data.global_info.request`

#### B. `/session` Group

Group này chứa dữ liệu raw bytes của các Ethernet packets:

- Mỗi session có ID dạng: `000000000000000000`, `000000000000000001`, ...
- Mỗi session chứa 1 dataset:
  - `raw`: Raw Ethernet packet bytes (uint8 array)
- Mỗi packet được giải mã theo cấu trúc:
  - Header (40 bytes): header, stream_id, timestamp, frequency, len, bandwidth, switch_id, sample_cnt
  - Payload: IQ samples (Int16, xen kẽ I và Q)

---

## 3. INPUT VÀ OUTPUT CỦA HÀM MATLAB

### 3.1. Input

**Hàm**: `read_iq_ethernet_h5_verge(filename)`

**Tham số**:
- `filename` (char/string): Đường dẫn đến file H5 cần đọc
  - Ví dụ: `'/path/to/iqethernet.h5'`
  - Ví dụ: `'../../00_DATA_h5/iqethernet.h5'`

**Yêu cầu**:
- MATLAB R2016b trở lên (để sử dụng `isfile`)
- Toolbox: Không cần toolbox đặc biệt, chỉ cần HDF5 support (có sẵn trong MATLAB)

### 3.2. Output

**Kiểu trả về**: `struct`

**Cấu trúc output**:

```matlab
data = 
    global_info: [1×1 struct]      % Attributes từ /attribute
    streams:    [1×1 struct]       % Struct chứa các streams

% Chi tiết global_info:
data.global_info = 
    client_ip: '10.61.169.181'
    frequency: 5800000000
    bandwidth: 480000
    ddc: [1×1 struct]              % Sub-group
    request: [1×1 struct]          % Sub-group
    ...

% Chi tiết streams:
data.streams.Stream_0 = 
    packets: [N×1 struct]         % Mảng các packets
    all_iq:  [M×1 double]         % (Optional) Tất cả IQ nối lại

% Chi tiết packet:
data.streams.Stream_0.packets(1) = 
    header:      uint32            % Header
    stream_id:   uint32            % Stream ID
    timestamp:   uint64            % Timestamp
    frequency:   uint64            % Frequency (Hz)
    len:         uint32            % Length
    bandwidth:   uint32            % Bandwidth (Hz)
    switch_id:   uint32            % Switch ID
    sample_cnt:  uint32            % Sample count
    iq_data:     [K×1 double]      % Complex IQ samples
    h5_session_idx: double         % Index trong H5 file
```

---

## 4. HƯỚNG DẪN SỬ DỤNG HÀM MATLAB

### 4.1. Cài đặt

**Yêu cầu**:
- MATLAB R2016b trở lên
- HDF5 support (có sẵn trong MATLAB)

**Cách sử dụng**:
1. Đảm bảo file `read_iq_ethernet_h5_verge.m` nằm trong MATLAB path
2. Gọi hàm với đường dẫn đến file H5

### 4.2. Cách sử dụng cơ bản

```matlab
% Đọc file
filename = '../../00_DATA_h5/iqethernet.h5';
data = read_iq_ethernet_h5_verge(filename);

% Truy cập thông tin
fprintf('Số streams: %d\n', length(fieldnames(data.streams)));
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

% Lấy sub-group (ví dụ: ddc)
if isfield(data.global_info, 'ddc')
    ddc_info = data.global_info.ddc;
    % Truy cập các trường trong ddc
    % ddc_channel = ddc_info.channelIndex;
end

% In ra tất cả các trường
fields = fieldnames(data.global_info);
for i = 1:length(fields)
    field_name = fields{i};
    field_value = data.global_info.(field_name);
    if isstruct(field_value)
        fprintf('%s: [struct]\n', field_name);
    else
        fprintf('%s: %s\n', field_name, num2str(field_value));
    end
end
```

#### B. Lấy dữ liệu Streams

**1. Lấy danh sách tất cả streams:**

```matlab
% Lấy tất cả stream names
stream_fields = fieldnames(data.streams);
fprintf('Có %d streams: ', length(stream_fields));
for i = 1:length(stream_fields)
    fprintf('%s ', stream_fields{i});
end
fprintf('\n');

% Lấy một stream cụ thể
stream_0 = data.streams.Stream_0;
```

**2. Lấy packets từ một stream:**

```matlab
% Lấy stream
stream = data.streams.Stream_0;

% Lấy danh sách packets
packets = stream.packets;
fprintf('Số packets: %d\n', length(packets));

% Lấy packet đầu tiên
packet = packets(1);
fprintf('Stream ID: %u\n', packet.stream_id);
fprintf('Frequency: %u Hz (%.2f MHz)\n', ...
    packet.frequency, double(packet.frequency)/1e6);
fprintf('Bandwidth: %u Hz (%.2f MHz)\n', ...
    packet.bandwidth, double(packet.bandwidth)/1e6);
fprintf('Sample count: %u\n', packet.sample_cnt);
```

**3. Lấy dữ liệu IQ từ packet:**

```matlab
% Lấy packet
packet = data.streams.Stream_0.packets(1);

% Lấy dữ liệu IQ phức
iq_data = packet.iq_data;  % complex double array
fprintf('IQ data: size=%s, class=%s\n', ...
    mat2str(size(iq_data)), class(iq_data));
fprintf('IQ samples (5 đầu): %s\n', mat2str(iq_data(1:5)));

% Tính toán từ IQ phức
% Biên độ (Magnitude)
magnitude = abs(iq_data);
fprintf('Magnitude: min=%.2f, max=%.2f\n', ...
    min(magnitude), max(magnitude));

% Phase (Góc pha)
phase = angle(iq_data);
fprintf('Phase: min=%.3f, max=%.3f\n', min(phase), max(phase));

% Power
power = abs(iq_data).^2;
fprintf('Power: mean=%.2f\n', mean(power));
```

**4. Lấy all_iq (tất cả IQ nối lại):**

```matlab
% Lấy stream
stream = data.streams.Stream_0;

% Lấy all_iq (nếu có)
if isfield(stream, 'all_iq')
    all_iq = stream.all_iq;  % Tất cả IQ từ tất cả packets nối lại
    fprintf('All IQ: %d samples\n', length(all_iq));
    fprintf('Size: %s\n', mat2str(size(all_iq)));
else
    fprintf('Không có all_iq\n');
end
```

**5. Duyệt qua tất cả streams và packets:**

```matlab
% Duyệt qua tất cả streams
stream_fields = fieldnames(data.streams);
for i = 1:length(stream_fields)
    stream_name = stream_fields{i};
    stream_data = data.streams.(stream_name);
    fprintf('\nStream: %s\n', stream_name);
    packets = stream_data.packets;
    fprintf('  Số packets: %d\n', length(packets));

    % Duyệt qua từng packet
    for j = 1:length(packets)
        packet = packets(j);
        stream_id = packet.stream_id;
        frequency = packet.frequency;
        iq_data = packet.iq_data;

        % Xử lý dữ liệu...
        if ~isempty(iq_data)
            magnitude = abs(iq_data);
            phase = angle(iq_data);
            fprintf('    Packet %d: Stream ID=%u, ', j, stream_id);
            fprintf('Freq=%.2f MHz, ', double(frequency)/1e6);
            fprintf('IQ samples=%d\n', length(iq_data));
        end

        % Ví dụ: chỉ xử lý 10 packets đầu
        if j >= 10
            break;
        end
    end
end
```

## 5. VÍ DỤ CODE HOÀN CHỈNH

```matlab
%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5
filename = '../../00_DATA_h5/iqethernet.h5';

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_iq_ethernet_h5_verge
try
    allData = read_iq_ethernet_h5_verge(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. HIỂN THỊ THÔNG TIN CHUNG
fprintf('\n==================================================\n');
fprintf(' THÔNG TIN TỔNG QUAN\n');
fprintf('==================================================\n');
stream_fields = fieldnames(allData.streams);
fprintf('Số streams: %d\n', length(stream_fields));

if isfield(allData, 'global_info') && ~isempty(allData.global_info)
    fprintf('\nGlobal Info:\n');
    fields = fieldnames(allData.global_info);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = allData.global_info.(field_name);
        if isstruct(field_value)
            fprintf('  %s: [struct]\n', field_name);
        elseif ischar(field_value) || isstring(field_value)
            fprintf('  %s: %s\n', field_name, char(field_value));
        else
            fprintf('  %s: %g\n', field_name, field_value);
        end
    end
end

%% 3. XỬ LÝ DỮ LIỆU TỪ STREAM ĐẦU TIÊN
fprintf('\n==================================================\n');
fprintf(' XỬ LÝ STREAM ĐẦU TIÊN\n');
fprintf('==================================================\n');

if ~isempty(stream_fields)
    stream_name = stream_fields{1};
    stream = allData.streams.(stream_name);
    fprintf('Stream: %s\n', stream_name);
    fprintf('Số packets: %d\n', length(stream.packets));

    if ~isempty(stream.packets)
        packet = stream.packets(1);
        fprintf('\nPacket đầu tiên:\n');
        fprintf('  Stream ID: %u\n', packet.stream_id);
        fprintf('  Frequency: %u Hz (%.2f MHz)\n', ...
            packet.frequency, double(packet.frequency)/1e6);
        fprintf('  Bandwidth: %u Hz (%.2f MHz)\n', ...
            packet.bandwidth, double(packet.bandwidth)/1e6);
        fprintf('  Sample count: %u\n', packet.sample_cnt);

        if ~isempty(packet.iq_data)
            iq_data = packet.iq_data;
            iq_mag = abs(iq_data);
            fprintf('  IQ data: %d samples\n', length(iq_data));
            fprintf('  Magnitude: Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
                min(iq_mag), max(iq_mag), mean(iq_mag));
            fprintf('  Phase: Min=%.3f, Max=%.3f\n', ...
                min(angle(iq_data)), max(angle(iq_data)));
        end
    end
end
```

---

## 6. BẢNG TÓM TẮT CẤU TRÚC OUTPUT

| Trường | Kiểu dữ liệu | Mô tả | Ví dụ truy cập |
|--------|--------------|-------|----------------|
| `global_info` | `struct` | Attributes từ `/attribute` | `data.global_info.frequency` |
| `global_info.ddc` | `struct` | Attributes từ `/attribute/ddc` | `data.global_info.ddc.channelIndex` |
| `streams` | `struct` | Struct chứa các streams | `data.streams.Stream_0` |
| `streams.Stream_X.packets` | `struct array` | Mảng các packets | `data.streams.Stream_0.packets(1)` |
| `packets(i).stream_id` | `uint32` | Stream ID | `packet.stream_id` |
| `packets(i).timestamp` | `uint64` | Timestamp | `packet.timestamp` |
| `packets(i).frequency` | `uint64` | Frequency (Hz) | `packet.frequency` |
| `packets(i).bandwidth` | `uint32` | Bandwidth (Hz) | `packet.bandwidth` |
| `packets(i).iq_data` | `complex double array` | Complex IQ samples | `packet.iq_data` |
| `streams.Stream_X.all_iq` | `complex double array` | Tất cả IQ nối lại | `stream.all_iq` |

---

## 7. LƯU Ý QUAN TRỌNG

1. **Kiểu dữ liệu**:
   - `iq_data` là `complex double` (số phức double precision)
   - Các trường header là `uint32` hoặc `uint64`

2. **Cấu trúc packet**:
   - Header: 40 bytes (header, stream_id, timestamp, frequency, len, bandwidth, switch_id, sample_cnt)
   - Payload: IQ samples (Int16, xen kẽ I và Q)

3. **Xử lý dữ liệu**:
   - Luôn kiểm tra `isempty()` trước khi sử dụng dữ liệu
   - Sử dụng `double()` để convert uint32/uint64 sang double khi tính toán
   - Sử dụng `abs()` và `angle()` để tính magnitude và phase từ complex IQ

4. **Hiệu năng**:
   - Đọc toàn bộ file có thể mất thời gian nếu có nhiều packets
   - Hàm có waitbar để hiển thị tiến trình
   - Có thể tối ưu bằng cách chỉ xử lý một số streams/packets cần thiết

5. **Struct array vs Cell array**:
   - `packets` là struct array, không phải cell array
   - Truy cập: `data.streams.Stream_0.packets(1)` (không phải `data.streams.Stream_0.packets{1}`)
   - Duyệt: `for i = 1:length(packets)` hoặc `for packet = packets'`

---

## 8. TÀI LIỆU THAM KHẢO

- **Code MATLAB**: `read_iq_ethernet_h5_verge.m`
- **File debug/test**: `debug_iqethernet_verge.m`
- **MATLAB HDF5 Documentation**: https://www.mathworks.com/help/matlab/ref/h5read.html
- **MATLAB Struct Documentation**: https://www.mathworks.com/help/matlab/ref/struct.html

---

**Ngày tạo báo cáo**: 2026-01-25
**Phiên bản hàm**: verge
**Tương thích với**: MATLAB R2016b trở lên

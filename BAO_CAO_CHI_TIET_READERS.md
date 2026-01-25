# BÁO CÁO CHI TIẾT CÁC FILE READER H5

## MỤC LỤC
1. [DF Reader (reader_df.m)](#1-df-reader-reader_dfm)
2. [Identifier Reader (read_identifier.m)](#2-identifier-reader-read_identifierm)
3. [Demodulation Reader (reader_demodulation_no_recursive.m)](#3-demodulation-reader-reader_demodulation_no_recursivem)
4. [Spectrum Reader (read_spectrum_data.m)](#4-spectrum-reader-read_spectrum_datam)
5. [Histogram Reader (read_histogram_h5_multitype.m)](#5-histogram-reader-read_histogram_h5_multitypem)
6. [IQ Ethernet Reader (read_iq_ethernet_h5_verge.m)](#6-iq-ethernet-reader-read_iq_ethernet_h5_vergem)
7. [IQ TCP Reader (read_iqtcp_h5_verge2.m)](#7-iq-tcp-reader-read_iqtcp_h5_verge2m)

---

## 1. DF READER (reader_df.m)

### 1.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/df/reader_df.m`
- **Hàm chính**: `read_df(filename)`
- **File H5 tương ứng**: `df.h5`
- **Mục đích**: Đọc file DF/DOA (Direction Finding/Direction of Arrival)

### 1.2. Cấu trúc file H5 được đọc

```
/attribute
  /configuration
    /antParams (Attributes)
    /filterParams (Attributes)
    ...
  /calibration
    /calibs
      /0 (Datasets: pow1, dps, ...)
      /1 (Datasets: pow1, dps, ...)
      /2 (Datasets: pow1, dps, ...)
      ...
/session
  /000000 (Datasets: amp, fc, bw, ...)
    /doa
      /doa
        /0
          /position (Datasets: vecDoas, ...)
          /velocity (Datasets: velocDoas, ...)
          /identity
            /features (Datasets: meanBws, ...)
        /1
          ...
        ...
  /000001
    ...
  ...
```

### 1.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.configuration`: Cấu hình (antParams, filterParams...)
  - `data.calibration`: Hiệu chuẩn (Table_0, Table_1, Table_2...)
  - `data.sessions`: Mảng struct chứa dữ liệu session

### 1.4. Cách lấy từng trường thông tin

#### 1.4.1. Configuration (Cấu hình)
```matlab
% Lấy tất cả các tham số cấu hình
config = data.configuration;

% Lấy tham số antenna
antParams = data.configuration.antParams;

% Lấy tham số filter
filterParams = data.configuration.filterParams;

% Xem tất cả các trường có trong configuration
fields = fieldnames(data.configuration);
```

#### 1.4.2. Calibration (Hiệu chuẩn)
```matlab
% Lấy tất cả các bảng hiệu chuẩn
calib = data.calibration;

% Lấy bảng hiệu chuẩn số 0
table0 = data.calibration.Table_0;

% Lấy dữ liệu pow1 trong Table_0
pow1_table0 = data.calibration.Table_0.pow1;

% Lấy dữ liệu dps trong Table_0
dps_table0 = data.calibration.Table_0.dps;

% Lấy bảng hiệu chuẩn số 1
table1 = data.calibration.Table_1;

% Xem tất cả các bảng có sẵn
tables = fieldnames(data.calibration);
```

#### 1.4.3. Sessions (Dữ liệu session)
```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);

% Lấy session đầu tiên
session1 = data.sessions(1);

% Lấy ID của session đầu tiên
session1_id = data.sessions(1).id;  % Ví dụ: '000000'

% Lấy dữ liệu pulses (xung) của session đầu tiên
pulses = data.sessions(1).pulses;

% Lấy các tham số xung cụ thể
amp = data.sessions(1).pulses.amp;  % Biên độ
fc = data.sessions(1).pulses.fc;    % Tần số trung tâm
bw = data.sessions(1).pulses.bw;    % Băng thông

% Xem tất cả các trường trong pulses
pulse_fields = fieldnames(data.sessions(1).pulses);
```

#### 1.4.4. DOA (Direction of Arrival)
```matlab
% Lấy dữ liệu DOA của session đầu tiên
doa = data.sessions(1).doa;

% Lấy target đầu tiên (Target_0)
target0 = data.sessions(1).doa.Target_0;

% Lấy vị trí (position) của target 0
position = data.sessions(1).doa.Target_0.position;

% Lấy vecDoas (vector DOA)
vecDoas = data.sessions(1).doa.Target_0.position.vecDoas;

% Lấy vận tốc (velocity) của target 0
velocity = data.sessions(1).doa.Target_0.velocity;

% Lấy velocDoas (vector vận tốc DOA)
velocDoas = data.sessions(1).doa.Target_0.velocity.velocDoas;

% Lấy identity features của target 0
features = data.sessions(1).doa.Target_0.identity_features;

% Lấy meanBws (mean bandwidths)
meanBws = data.sessions(1).doa.Target_0.identity_features.meanBws;

% Xem tất cả các target có trong session
targets = fieldnames(data.sessions(1).doa);

% Duyệt qua tất cả các target
for i = 1:length(targets)
    target_name = targets{i};
    target_data = data.sessions(1).doa.(target_name);
    % Xử lý dữ liệu target...
end
```

#### 1.4.5. Ví dụ duyệt qua tất cả sessions
```matlab
for k = 1:length(data.sessions)
    session_id = data.sessions(k).id;
    pulses = data.sessions(k).pulses;
    doa = data.sessions(k).doa;
    
    % Xử lý dữ liệu...
end
```

---

## 2. IDENTIFIER READER (read_identifier.m)

### 2.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/identifier/read_identifier.m`
- **Hàm chính**: `read_identifier(filename)`
- **File H5 tương ứng**: `identifier.h5`
- **Mục đích**: Đọc file Identifier/MAVIC (Nhận dạng mục tiêu)

### 2.2. Cấu trúc file H5 được đọc

```
/attribute
  /estm_bdw (Datasets: các tham số hop)
  /request
    /label (Dataset: text label)
  /doa
    /position (Datasets: vecDoas, ...)
    /identity
      /features (Datasets: meanBws, ...)
/session
  /000000
    /iq (Dataset: dữ liệu IQ xen kẽ [I, Q, I, Q...])
  /000001
    ...
  ...
```

### 2.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.estm_bdw`: Tham số ước lượng băng thông
  - `data.request.label`: Label từ request
  - `data.doa`: Thông tin DOA (position, identity)
  - `data.sessions`: Mảng struct chứa dữ liệu IQ

### 2.4. Cách lấy từng trường thông tin

#### 2.4.1. Estimated Bandwidth (estm_bdw)
```matlab
% Lấy tất cả tham số ước lượng băng thông
estm_bdw = data.estm_bdw;

% Xem tất cả các trường có trong estm_bdw
fields = fieldnames(data.estm_bdw);

% Lấy giá trị cụ thể (tùy thuộc vào dataset trong file)
% Ví dụ: nếu có dataset 'hop'
hop = data.estm_bdw.hop;
```

#### 2.4.2. Request Label
```matlab
% Lấy label từ request
label = data.request.label;

% Label được parse thành struct với các key-value pairs
% Ví dụ: nếu label có dạng "key1=value1\nkey2=value2"
% Thì có thể truy cập:
value1 = data.request.label.key1;
value2 = data.request.label.key2;

% Xem tất cả các trường trong label
label_fields = fieldnames(data.request.label);
```

#### 2.4.3. DOA Information
```matlab
% Lấy thông tin DOA
doa = data.doa;

% Lấy position
position = data.doa.position;

% Lấy vecDoas
vecDoas = data.doa.position.vecDoas;

% Lấy identity features
features = data.doa.identity.features;

% Lấy meanBws
meanBws = data.doa.identity.features.meanBws;

% Xem tất cả các trường trong position
pos_fields = fieldnames(data.doa.position);

% Xem tất cả các trường trong features
feat_fields = fieldnames(data.doa.identity.features);
```

#### 2.4.4. Sessions (IQ Data)
```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);

% Lấy session đầu tiên
session1 = data.sessions(1);

% Lấy ID của session đầu tiên
session1_id = data.sessions(1).id;  % Ví dụ: '000000'

% Lấy dữ liệu IQ của session đầu tiên
iq_data = data.sessions(1).iq;

% IQ data là số phức (complex), đã được xử lý từ dữ liệu xen kẽ
% Có thể lấy phần thực (I) và phần ảo (Q):
I = real(data.sessions(1).iq);
Q = imag(data.sessions(1).iq);

% Lấy biên độ
magnitude = abs(data.sessions(1).iq);

% Lấy phase
phase = angle(data.sessions(1).iq);

% Duyệt qua tất cả sessions
for k = 1:length(data.sessions)
    session_id = data.sessions(k).id;
    iq = data.sessions(k).iq;
    
    % Xử lý dữ liệu IQ...
end
```

---

## 3. DEMODULATION READER (reader_demodulation_no_recursive.m)

### 3.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/demodulation/reader_demodulation_no_recursive.m`
- **Hàm chính**: `reader_demodulation_no_recursive(filename)`
- **File H5 tương ứng**: `demodulation.h5`
- **Mục đích**: Đọc file Demodulation (Giải điều chế)

### 3.2. Cấu trúc file H5 được đọc

```
/attribute
  /request
    /hwConfiguration (Attributes)
    /source (Attributes)
    ...
/session
  /000000
    /i (Dataset: In-phase data, int32)
    /q (Dataset: Quadrature data, int32)
  /000001
    ...
  ...
```

### 3.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.request`: Thông tin cấu hình request
  - `data.sessions`: Mảng struct chứa ID và dữ liệu IQ phức

### 3.4. Cách lấy từng trường thông tin

#### 3.4.1. Request Information
```matlab
% Lấy tất cả thông tin request
request = data.request;

% Lấy thông tin hardware configuration
hwConfig = data.request.hwConfiguration;

% Lấy thông tin source
source = data.request.source;

% Xem tất cả các trường có trong request
request_fields = fieldnames(data.request);

% Xem các trường trong hwConfiguration
hw_fields = fieldnames(data.request.hwConfiguration);
```

#### 3.4.2. Sessions (IQ Data)
```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);

% Lấy session đầu tiên
session1 = data.sessions(1);

% Lấy ID của session đầu tiên
session1_id = data.sessions(1).id;  % Ví dụ: '000000'

% Lấy dữ liệu IQ phức (đã được kết hợp từ I và Q)
iq_complex = data.sessions(1).iq;

% IQ là số phức (complex double)
% Lấy phần thực (I) và phần ảo (Q):
I = real(data.sessions(1).iq);
Q = imag(data.sessions(1).iq);

% Lấy biên độ
magnitude = abs(data.sessions(1).iq);

% Lấy phase
phase = angle(data.sessions(1).iq);

% Lấy số lượng mẫu
num_samples = length(data.sessions(1).iq);

% Duyệt qua tất cả sessions
for k = 1:length(data.sessions)
    session_id = data.sessions(k).id;
    iq = data.sessions(k).iq;
    
    % Xử lý dữ liệu IQ...
end
```

---

## 4. SPECTRUM READER (read_spectrum_data.m)

### 4.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/spectrum/read_spectrum_data.m`
- **Hàm chính**: `read_spectrum_data(filename)`
- **File H5 tương ứng**: `spectrum.h5`
- **Mục đích**: Đọc file Spectrum (Phổ tần số)

### 4.2. Cấu trúc file H5 được đọc

```
/attribute (Attributes: client_ip, mission, frequency, bandwidth, ...)
/session
  /000000 (Attributes: timestamp, freq, bw, ...)
    /source (Attributes: device info)
    /sample_decoded (Dataset: vector dữ liệu phổ)
  /000001
    ...
  ...
```

### 4.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.global_info`: Thông tin chung từ /attribute
  - `data.sessions`: Mảng struct chứa dữ liệu từng session

### 4.4. Cách lấy từng trường thông tin

#### 4.4.1. Global Info
```matlab
% Lấy tất cả thông tin chung
global_info = data.global_info;

% Lấy các trường thông tin cụ thể (tùy thuộc vào file)
client_ip = data.global_info.client_ip;
mission = data.global_info.mission;
frequency = data.global_info.frequency;  % Tần số (Hz)
bandwidth = data.global_info.bandwidth;  % Băng thông (Hz)
channel = data.global_info.channel;

% Xem tất cả các trường có trong global_info
global_fields = fieldnames(data.global_info);
```

#### 4.4.2. Sessions
```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);

% Lấy session đầu tiên
session1 = data.sessions(1);

% Lấy ID của session đầu tiên
session1_id = data.sessions(1).id;  % Ví dụ: '000000'

% Lấy attributes của session (timestamp, freq, bw, ...)
session_attrs = data.sessions(1).attributes;

% Lấy các giá trị cụ thể từ attributes
timestamp = data.sessions(1).attributes.timestamp;
freq = data.sessions(1).attributes.freq;
bw = data.sessions(1).attributes.bw;

% Xem tất cả các trường trong attributes
attr_fields = fieldnames(data.sessions(1).attributes);
```

#### 4.4.3. Source Info
```matlab
% Lấy thông tin thiết bị (source) của session đầu tiên
source_info = data.sessions(1).source_info;

% Xem tất cả các trường trong source_info
source_fields = fieldnames(data.sessions(1).source_info);

% Lấy giá trị cụ thể (tùy thuộc vào file)
% Ví dụ:
device_id = data.sessions(1).source_info.deviceId;
```

#### 4.4.4. Samples (Dữ liệu phổ)
```matlab
% Lấy dữ liệu mẫu đã giải mã (sample_decoded)
samples = data.sessions(1).samples;

% samples là vector chứa dữ liệu phổ tần số
% Lấy số lượng mẫu
num_samples = length(data.sessions(1).samples);

% Lấy giá trị min, max, mean
min_val = min(data.sessions(1).samples);
max_val = max(data.sessions(1).samples);
mean_val = mean(data.sessions(1).samples);

% Duyệt qua tất cả sessions
for k = 1:length(data.sessions)
    session_id = data.sessions(k).id;
    attributes = data.sessions(k).attributes;
    source_info = data.sessions(k).source_info;
    samples = data.sessions(k).samples;
    
    % Xử lý dữ liệu...
end
```

---

## 5. HISTOGRAM READER (read_histogram_h5_multitype.m)

### 5.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/histogram/read_histogram_h5_multitype.m`
- **Hàm chính**: `read_histogram_h5_multitype(filename)`
- **File H5 tương ứng**: `histogram.h5`
- **Mục đích**: Đọc file Histogram với hỗ trợ nhiều loại message

### 5.2. Cấu trúc file H5 được đọc

```
/attribute (Attributes: client_ip, mission, ...)
/session
  /000000 (Attributes: message_type, ...)
    /context (Attributes: ...)
    /source (Attributes: ...)
    /sample_decoded (Dataset: cho AccumulatedPower)
    HOẶC
    /acc_sample_decoded (Dataset: cho CrossingThresholdPower)
    /crx_sample_decoded (Dataset: cho CrossingThresholdPower)
  /000001
    ...
  ...
```

**Lưu ý**: File này hỗ trợ 2 loại message:
- **AccumulatedPower**: Đọc `sample_decoded`
- **CrossingThresholdPower**: Đọc `acc_sample_decoded` VÀ `crx_sample_decoded`

### 5.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.global_info`: Thông tin chung từ /attribute
  - `data.sessions`: Mảng struct chứa dữ liệu từng session

### 5.4. Cách lấy từng trường thông tin

#### 5.4.1. Global Info
```matlab
% Lấy tất cả thông tin chung
global_info = data.global_info;

% Lấy các trường thông tin cụ thể
client_ip = data.global_info.client_ip;
mission = data.global_info.mission;

% Xem tất cả các trường có trong global_info
global_fields = fieldnames(data.global_info);
```

#### 5.4.2. Sessions - Kiểm tra loại message
```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);

% Lấy session đầu tiên
session1 = data.sessions(1);

% Lấy ID của session đầu tiên
session1_id = data.sessions(1).id;

% Lấy loại message (type)
message_type = data.sessions(1).type;
% Có thể là: 'AccumulatedPower' hoặc 'CrossingThresholdPower'

% Lấy attributes của session
attributes = data.sessions(1).attributes;

% Kiểm tra loại message để biết cách lấy dữ liệu
if contains(data.sessions(1).type, 'CrossingThresholdPower')
    % Loại CrossingThresholdPower
    acc_samples = data.sessions(1).acc_sample_decoded;
    crx_samples = data.sessions(1).crx_sample_decoded;
else
    % Loại AccumulatedPower (hoặc mặc định)
    samples = data.sessions(1).sample_decoded;
end
```

#### 5.4.3. AccumulatedPower Type
```matlab
% Lấy dữ liệu sample_decoded cho loại AccumulatedPower
samples = data.sessions(1).sample_decoded;

% Lấy số lượng mẫu
num_samples = length(data.sessions(1).sample_decoded);

% Lấy giá trị min, max, mean
min_val = min(data.sessions(1).sample_decoded);
max_val = max(data.sessions(1).sample_decoded);
mean_val = mean(data.sessions(1).sample_decoded);
```

#### 5.4.4. CrossingThresholdPower Type
```matlab
% Lấy dữ liệu acc_sample_decoded (accumulated)
acc_samples = data.sessions(1).acc_sample_decoded;

% Lấy dữ liệu crx_sample_decoded (crossing)
crx_samples = data.sessions(1).crx_sample_decoded;

% Lấy số lượng mẫu
num_acc = length(data.sessions(1).acc_sample_decoded);
num_crx = length(data.sessions(1).crx_sample_decoded);

% Lấy giá trị thống kê
acc_min = min(data.sessions(1).acc_sample_decoded);
acc_max = max(data.sessions(1).acc_sample_decoded);
crx_min = min(data.sessions(1).crx_sample_decoded);
crx_max = max(data.sessions(1).crx_sample_decoded);
```

#### 5.4.5. Context và Source Info
```matlab
% Lấy context info
context_info = data.sessions(1).context_info;

% Xem các trường trong context
context_fields = fieldnames(data.sessions(1).context_info);

% Lấy source info
source_info = data.sessions(1).source_info;

% Xem các trường trong source
source_fields = fieldnames(data.sessions(1).source_info);
```

#### 5.4.6. Ví dụ duyệt qua tất cả sessions
```matlab
for k = 1:length(data.sessions)
    session_id = data.sessions(k).id;
    msg_type = data.sessions(k).type;
    attributes = data.sessions(k).attributes;
    
    % Xử lý theo loại message
    if contains(msg_type, 'CrossingThresholdPower')
        acc = data.sessions(k).acc_sample_decoded;
        crx = data.sessions(k).crx_sample_decoded;
        % Xử lý dữ liệu crossing...
    else
        samples = data.sessions(k).sample_decoded;
        % Xử lý dữ liệu accumulated...
    end
end
```

---

## 6. IQ ETHERNET READER (read_iq_ethernet_h5_verge.m)

### 6.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/iq_ethernet/read_iq_ethernet_h5_verge.m`
- **Hàm chính**: `read_iq_ethernet_h5_verge(filename)`
- **File H5 tương ứng**: `iqethernet.h5`
- **Mục đích**: Đọc và giải mã gói tin Ethernet IQ từ file H5

### 6.2. Cấu trúc file H5 được đọc

```
/attribute
  (Attributes: ...)
  /ddc (Attributes: ...)
  /request (Attributes: ...)
  ...
/session
  /000000
    /raw (Dataset: uint8 array - gói tin Ethernet thô)
    /context (Attributes: timestamp, ...)
  /000001
    ...
  ...
```

**Lưu ý**: Mỗi session chứa một gói tin Ethernet thô (raw bytes). Hàm sẽ giải mã gói tin và nhóm theo Stream ID.

### 6.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.global_info`: Thông tin chung từ /attribute
  - `data.streams`: Struct chứa dữ liệu đã phân loại theo Stream ID

### 6.4. Cấu trúc gói tin Ethernet (được giải mã)

Mỗi gói tin Ethernet có cấu trúc:
- Header (4 bytes): uint32
- Stream ID (4 bytes): uint32
- Timestamp (8 bytes): uint64
- Frequency (8 bytes): uint64
- Length (4 bytes): uint32
- Bandwidth (4 bytes): uint32
- Switch ID (4 bytes): uint32
- Sample Count (4 bytes): uint32
- Data: IQ samples (Int16, xen kẽ I và Q)

### 6.5. Cách lấy từng trường thông tin

#### 6.5.1. Global Info
```matlab
% Lấy tất cả thông tin chung
global_info = data.global_info;

% Lấy thông tin DDC
ddc_info = data.global_info.ddc;

% Lấy thông tin request
request_info = data.global_info.request;

% Xem tất cả các trường có trong global_info
global_fields = fieldnames(data.global_info);
```

#### 6.5.2. Streams (theo Stream ID)
```matlab
% Lấy tất cả các stream
streams = data.streams;

% Xem tất cả các stream có sẵn
stream_names = fieldnames(data.streams);
% Ví dụ: {'Stream_101', 'Stream_102', ...}

% Lấy stream đầu tiên (ví dụ Stream_101)
stream_101 = data.streams.Stream_101;

% Lấy danh sách các gói tin trong stream
packets = data.streams.Stream_101.packets;

% Lấy số lượng gói tin trong stream
num_packets = length(data.streams.Stream_101.packets);
```

#### 6.5.3. Thông tin từng gói tin (Packet)
```matlab
% Lấy gói tin đầu tiên trong Stream_101
packet1 = data.streams.Stream_101.packets(1);

% Lấy các trường thông tin của gói tin
header = packet1.header;          % uint32
stream_id = packet1.stream_id;   % uint32
timestamp = packet1.timestamp;    % uint64
frequency = packet1.frequency;     % uint64
len = packet1.len;                % uint32 (length)
bandwidth = packet1.bandwidth;    % uint32
switch_id = packet1.switch_id;    % uint32
sample_cnt = packet1.sample_cnt;  % uint32

% Lấy dữ liệu IQ (số phức)
iq_data = packet1.iq_data;
% iq_data là vector số phức (complex)

% Lấy phần thực (I) và phần ảo (Q)
I = real(packet1.iq_data);
Q = imag(packet1.iq_data);

% Lấy biên độ
magnitude = abs(packet1.iq_data);

% Lấy phase
phase = angle(packet1.iq_data);

% Lấy số lượng mẫu IQ
num_samples = length(packet1.iq_data);
```

#### 6.5.4. All IQ (Tất cả IQ của stream)
```matlab
% Lấy tất cả dữ liệu IQ của stream đã được nối lại
all_iq = data.streams.Stream_101.all_iq;

% all_iq là vector số phức chứa tất cả IQ samples của stream
% Đã được nối từ tất cả các gói tin trong stream

% Lấy số lượng mẫu tổng
total_samples = length(data.streams.Stream_101.all_iq);
```

#### 6.5.5. Ví dụ duyệt qua tất cả streams
```matlab
% Lấy tất cả tên stream
stream_names = fieldnames(data.streams);

for i = 1:length(stream_names)
    stream_name = stream_names{i};
    stream_data = data.streams.(stream_name);
    
    % Lấy danh sách gói tin
    packets = stream_data.packets;
    
    % Lấy tất cả IQ
    all_iq = stream_data.all_iq;
    
    % Xử lý dữ liệu stream...
    
    % Duyệt qua từng gói tin
    for j = 1:length(packets)
        packet = packets(j);
        iq = packet.iq_data;
        % Xử lý từng gói tin...
    end
end
```

---

## 7. IQ TCP READER (read_iqtcp_h5_verge2.m)

### 7.1. Thông tin cơ bản
- **File Reader**: `00_CODE_H5/iq_tcp/read_iqtcp_h5_verge2.m`
- **Hàm chính**: `read_iqtcp_h5_verge2(filename)`
- **File H5 tương ứng**: `iqtcp.h5`
- **Mục đích**: Đọc file H5 chứa dữ liệu IQ (Narrowband TCP)

### 7.2. Cấu trúc file H5 được đọc

```
/attribute
  (Attributes: client_ip, frequency, bandwidth, ...)
  /ddc (Attributes: channelIndex, frequency, deviceId, ...)
  /request (Attributes: fileName, duration, checkpoint, ...)
    /label (Dataset: text label - nếu có)
  ...
/session
  /000000
    /i (Dataset: In-phase data)
    /q (Dataset: Quadrature data)
  /000001
    ...
  ...
```

### 7.3. Input/Output

**INPUT:**
- `filename` (string): Đường dẫn đến file `.h5`

**OUTPUT:**
- `data` (struct): Cấu trúc dữ liệu chứa:
  - `data.global_info`: Attributes trực tiếp từ /attribute
  - `data.ddc_info`: Attributes từ /attribute/ddc
  - `data.request_info`: Attributes từ /attribute/request
  - `data.sessions`: Mảng struct chứa id, i, q, và iq

### 7.4. Cách lấy từng trường thông tin

#### 7.4.1. Global Info
```matlab
% Lấy tất cả thông tin chung
global_info = data.global_info;

% Lấy các trường thông tin cụ thể
client_ip = data.global_info.client_ip;
frequency = data.global_info.frequency;  % Tần số (Hz)
bandwidth = data.global_info.bandwidth;  % Băng thông (Hz)
channel = data.global_info.channel;
mission = data.global_info.mission;

% Xem tất cả các trường có trong global_info
global_fields = fieldnames(data.global_info);
```

#### 7.4.2. DDC Info (Digital Down Converter)
```matlab
% Lấy thông tin DDC
ddc_info = data.ddc_info;

% Lấy các trường cụ thể
channel_index = data.ddc_info.channelIndex;
ddc_frequency = data.ddc_info.frequency;
device_id = data.ddc_info.deviceId;

% Xem tất cả các trường có trong ddc_info
ddc_fields = fieldnames(data.ddc_info);
```

#### 7.4.3. Request Info
```matlab
% Lấy thông tin request
request_info = data.request_info;

% Lấy các trường cụ thể
file_name = data.request_info.fileName;
duration = data.request_info.duration;
checkpoint = data.request_info.checkpoint;

% Nếu có label (dataset)
if isfield(data.request_info, 'label')
    label = data.request_info.label;
end

% Xem tất cả các trường có trong request_info
request_fields = fieldnames(data.request_info);
```

#### 7.4.4. Sessions (IQ Data)
```matlab
% Lấy số lượng sessions
num_sessions = length(data.sessions);

% Lấy session đầu tiên
session1 = data.sessions(1);

% Lấy ID của session đầu tiên
session1_id = data.sessions(1).id;  % Ví dụ: '000000'

% Lấy dữ liệu I (In-phase) riêng biệt
I_data = data.sessions(1).i;

% Lấy dữ liệu Q (Quadrature) riêng biệt
Q_data = data.sessions(1).q;

% Lấy dữ liệu IQ phức (đã được kết hợp: I + j*Q)
iq_complex = data.sessions(1).iq;

% IQ là số phức (complex double)
% Có thể lấy phần thực và phần ảo:
I = real(data.sessions(1).iq);
Q = imag(data.sessions(1).iq);

% Lấy biên độ
magnitude = abs(data.sessions(1).iq);

% Lấy phase
phase = angle(data.sessions(1).iq);

% Lấy số lượng mẫu
num_samples = length(data.sessions(1).iq);

% Kiểm tra độ dài I và Q (phải bằng nhau)
len_I = length(data.sessions(1).i);
len_Q = length(data.sessions(1).q);
```

#### 7.4.5. Ví dụ duyệt qua tất cả sessions
```matlab
for k = 1:length(data.sessions)
    session_id = data.sessions(k).id;
    I = data.sessions(k).i;
    Q = data.sessions(k).q;
    iq = data.sessions(k).iq;
    
    % Xử lý dữ liệu IQ...
    % Ví dụ: vẽ constellation diagram
    plot(real(iq), imag(iq), '.');
end
```

---

## TÓM TẮT SO SÁNH CÁC READER

| Reader | File H5 | Dữ liệu chính | Đặc điểm |
|--------|---------|---------------|----------|
| DF | df.h5 | Pulses, DOA | Cấu trúc phức tạp với calibration tables |
| Identifier | identifier.h5 | IQ xen kẽ | Hỗ trợ parse label text |
| Demodulation | demodulation.h5 | IQ (I, Q riêng) | Đơn giản, chỉ có I và Q |
| Spectrum | spectrum.h5 | sample_decoded | Có source_info cho mỗi session |
| Histogram | histogram.h5 | sample_decoded hoặc acc/crx | Hỗ trợ 2 loại message type |
| IQ Ethernet | iqethernet.h5 | Raw packets | Giải mã gói tin, nhóm theo Stream ID |
| IQ TCP | iqtcp.h5 | IQ (I, Q riêng) | Có DDC và request info chi tiết |

---

## LƯU Ý CHUNG

1. **Kiểm tra file tồn tại**: Tất cả các hàm đều kiểm tra file có tồn tại trước khi đọc
2. **Xử lý lỗi**: Các hàm sử dụng try-catch để xử lý lỗi một cách an toàn
3. **Vector cột**: Hầu hết dữ liệu được chuyển thành vector cột (column vector)
4. **matlab.lang.makeValidName**: Tên trường được làm sạch để hợp lệ với MATLAB
5. **Waitbar**: Một số hàm hiển thị waitbar khi đọc nhiều sessions
6. **Kiểu dữ liệu**: 
   - IQ data thường là `complex double`
   - Raw data có thể là `int32`, `int16`, `uint8` tùy loại

---

**Ngày tạo báo cáo**: $(date)
**Phiên bản**: 1.0




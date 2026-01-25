# HƯỚNG DẪN KIỂM TRA CẤU TRÚC FILE H5

## Cách 1: Chạy script MATLAB (Khuyến nghị)

### Bước 1: Mở MATLAB
```bash
# Nếu MATLAB đã được cài đặt
matlab
```

### Bước 2: Chạy script
Trong MATLAB command window:
```matlab
cd('/home/tth193/Documents/h5_code')
run_structure_check
```

Script sẽ:
- Đọc tất cả các file H5 bằng các reader tương ứng
- In ra cấu trúc output chi tiết
- Lưu kết quả vào biến `results` để kiểm tra thêm

### Bước 3: Kiểm tra chi tiết (tùy chọn)
```matlab
% Kiểm tra cấu trúc df.h5
results.dfh5

% Kiểm tra cấu trúc identifier.h5
results.identifierh5

% Kiểm tra session đầu tiên của spectrum
results.spectrumh5.sessions(1)

% Xem tất cả fields
fieldnames(results.dfh5)
```

## Cách 2: Chạy script chi tiết hơn

Nếu muốn kết quả chi tiết hơn và lưu vào file:
```matlab
cd('/home/tth193/Documents/h5_code')
check_h5_structure_real
```

Kết quả sẽ được lưu vào: `STRUCTURE_CHECK_RESULT.txt`

## Cách 3: Kiểm tra từng file riêng lẻ

### DF Reader
```matlab
cd('/home/tth193/Documents/h5_code')
addpath(genpath('00_CODE_H5'))
data = read_df('00_DATA_h5/df.h5');
disp(data)
```

### Identifier Reader
```matlab
data = read_identifier('00_DATA_h5/identifier.h5');
disp(data)
```

### Demodulation Reader
```matlab
data = reader_demodulation_no_recursive('00_DATA_h5/demodulation.h5');
disp(data)
```

### Spectrum Reader
```matlab
data = read_spectrum_data('00_DATA_h5/spectrum.h5');
disp(data)
```

### Histogram Reader
```matlab
data = read_histogram_h5_multitype('00_DATA_h5/histogram.h5');
disp(data)
```

### IQ Ethernet Reader
```matlab
data = read_iq_ethernet_h5_verge('00_DATA_h5/iqethernet.h5');
disp(data)
```

### IQ TCP Reader
```matlab
data = read_iqtcp_h5_verge2('00_DATA_h5/iqtcp.h5');
disp(data)
```

## Cách 4: Sử dụng Python (nếu có h5py)

Cài đặt h5py:
```bash
pip3 install h5py
```

Chạy script:
```bash
cd /home/tth193/Documents/h5_code
python3 check_h5_direct.py
```

## Lưu ý

1. **Đảm bảo đường dẫn đúng**: Các file H5 phải nằm trong `00_DATA_h5/`
2. **Kiểm tra file tồn tại**: Script sẽ bỏ qua file không tồn tại
3. **Xử lý lỗi**: Nếu có lỗi, script sẽ in ra thông báo lỗi và tiếp tục với file tiếp theo

## So sánh với tài liệu API

Sau khi chạy script, so sánh kết quả với:
- File: `API_log_dữ_liệu_v1.0(3).docx_0.odt`
- Báo cáo: `BAO_CAO_CHI_TIET_READERS_CHINH_XAC.md`

Để đảm bảo cấu trúc output khớp với tài liệu.




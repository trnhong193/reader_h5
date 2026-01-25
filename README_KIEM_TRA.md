# HƯỚNG DẪN KIỂM TRA VÀ TẠO BÁO CÁO

## Tổng quan

Các script này được tạo để:
1. Kiểm tra cấu trúc file H5 thực tế bằng cách chạy các reader MATLAB
2. So sánh với tài liệu API
3. Tạo báo cáo chi tiết

## Các file đã tạo

1. **run_structure_check.m** - Script đơn giản để kiểm tra nhanh
2. **check_h5_structure_real.m** - Script chi tiết với output vào file
3. **create_final_report.m** - Tạo báo cáo cuối cùng
4. **check_h5_direct.py** - Script Python (cần h5py)
5. **HUONG_DAN_KIEM_TRA.md** - Hướng dẫn chi tiết

## Cách sử dụng nhanh

### Bước 1: Mở MATLAB
```bash
matlab
```

### Bước 2: Chạy script kiểm tra
```matlab
cd('/home/tth193/Documents/h5_code')
run_structure_check
```

### Bước 3: Tạo báo cáo (tùy chọn)
```matlab
create_final_report
```

Báo cáo sẽ được lưu vào: `BAO_CAO_FINAL_KIEM_TRA.txt`

## So sánh với tài liệu API

Sau khi có kết quả, so sánh với:
- **Tài liệu API**: `API_log_dữ_liệu_v1.0(3).docx_0.odt`
- **Báo cáo hiện tại**: `BAO_CAO_CHI_TIET_READERS_CHINH_XAC.md`

## Kiểm tra từng loại file

### 1. DF (df.h5)
```matlab
data = read_df('00_DATA_h5/df.h5');
% Kiểm tra:
% - data.configuration
% - data.calibration
% - data.sessions
```

### 2. Identifier (identifier.h5)
```matlab
data = read_identifier('00_DATA_h5/identifier.h5');
% Kiểm tra:
% - data.estm_bdw
% - data.request.label
% - data.doa
% - data.sessions
```

### 3. Demodulation (demodulation.h5)
```matlab
data = reader_demodulation_no_recursive('00_DATA_h5/demodulation.h5');
% Kiểm tra:
% - data.request
% - data.sessions
```

### 4. Spectrum (spectrum.h5)
```matlab
data = read_spectrum_data('00_DATA_h5/spectrum.h5');
% Kiểm tra:
% - data.global_info
% - data.sessions (attributes, source_info, samples)
```

### 5. Histogram (histogram.h5)
```matlab
data = read_histogram_h5_multitype('00_DATA_h5/histogram.h5');
% Kiểm tra:
% - data.global_info
% - data.sessions (type, attributes, context_info, source_info, 
%                  sample_decoded hoặc acc_sample_decoded/crx_sample_decoded)
```

### 6. IQ Ethernet (iqethernet.h5)
```matlab
data = read_iq_ethernet_h5_verge('00_DATA_h5/iqethernet.h5');
% Kiểm tra:
% - data.global_info
% - data.streams (Stream_X với packets, all_iq)
```

### 7. IQ TCP (iqtcp.h5)
```matlab
data = read_iqtcp_h5_verge2('00_DATA_h5/iqtcp.h5');
% Kiểm tra:
% - data.global_info
% - data.ddc_info
% - data.request_info
% - data.sessions (i, q, iq)
```

## Lưu ý quan trọng

1. **Đường dẫn**: Đảm bảo bạn đang ở đúng thư mục hoặc sử dụng đường dẫn đầy đủ
2. **Path MATLAB**: Script tự động thêm path, nhưng nếu có lỗi, thêm thủ công:
   ```matlab
   addpath(genpath('/home/tth193/Documents/h5_code/00_CODE_H5'))
   ```
3. **File không tồn tại**: Script sẽ bỏ qua và tiếp tục
4. **Lỗi đọc file**: Kiểm tra quyền truy cập file và định dạng file

## Kết quả mong đợi

Sau khi chạy, bạn sẽ có:
- Cấu trúc output chi tiết của từng reader
- So sánh với code reader để đảm bảo chính xác
- Thông tin để cập nhật báo cáo nếu cần

## Cập nhật báo cáo

Sau khi kiểm tra, nếu phát hiện khác biệt:
1. So sánh với `BAO_CAO_CHI_TIET_READERS_CHINH_XAC.md`
2. Cập nhật báo cáo với thông tin thực tế
3. Ghi chú các điểm khác biệt nếu có




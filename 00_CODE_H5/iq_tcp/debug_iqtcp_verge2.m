%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5 của bạn (Narrowband TCP - I/Q samples)
filename = '/home/vht/Documents/PRJ/01_data_h5/digitizer_200_1/2026_01_13/20260113_154842_narrowband_tcp.h5'; 

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);

% Gọi hàm read_iq_tcp_h5_verge2 (Đảm bảo file hàm nằm cùng thư mục)
try
    allData = read_iqtcp_h5_verge2(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. CÁCH LẤY DỮ LIỆU CHUNG (GLOBAL INFO)
fprintf('\n==================================================\n');
fprintf(' [1] THÔNG TIN CHUNG (GLOBAL INFO)\n');
fprintf('==================================================\n');
fprintf('Cú pháp: data.global_info\n\n');

% Truy cập vào struct global_info
g_info = allData.global_info;

if ~isempty(g_info)
    fprintf('Các trường có trong global_info:\n');
    fields = fieldnames(g_info); % get all fields in 
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = g_info.(field_name);
        
        % Hiển thị giá trị (xử lý các kiểu khác nhau)
        if ischar(field_value) || isstring(field_value)
            val_str = char(field_value);
            if length(val_str) > 50
                val_str = [val_str(1:47) '...'];
            end
            fprintf('  • data.global_info.%s = "%s"\n', field_name, val_str);
        elseif isnumeric(field_value) && numel(field_value) == 1
            fprintf('  • data.global_info.%s = %g\n', field_name, field_value);
        else
            fprintf('  • data.global_info.%s = [%s, size=%s]\n', ...
                field_name, class(field_value), mat2str(size(field_value)));
        end
    end
    
    % Ví dụ truy cập trực tiếp
    fprintf('\nVí dụ truy cập trực tiếp:\n');
    if isfield(g_info, 'client_ip')
        fprintf('  client_ip = data.global_info.client_ip;\n');
    end
    if isfield(g_info, 'frequency')
        fprintf('  frequency = data.global_info.frequency;\n');
        fprintf('  → Kết quả: %g Hz (%.2f MHz)\n', ...
            double(g_info.frequency), double(g_info.frequency)/1e6);
    end
    if isfield(g_info, 'bandwidth')
        fprintf('  bandwidth = data.global_info.bandwidth;\n');
        fprintf('  → Kết quả: %g Hz (%.2f MHz)\n', ...
            double(g_info.bandwidth), double(g_info.bandwidth)/1e6);
    end
else
    fprintf('⚠ Không có global_info trong file này.\n');
end
fprintf('\n');

%% 3. CÁCH LẤY DDC INFO
fprintf('\n==================================================\n');
fprintf(' [2] THÔNG TIN DDC (Digital Down Converter)\n');
fprintf('==================================================\n');
fprintf('Cú pháp: data.ddc_info\n\n');

if isfield(allData, 'ddc_info') && ~isempty(allData.ddc_info)
    ddc = allData.ddc_info;
    fprintf('Các trường có trong ddc_info:\n');
    fields = fieldnames(ddc);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = ddc.(field_name);
        
        if ischar(field_value) || isstring(field_value)
            fprintf('  • data.ddc_info.%s = "%s"\n', field_name, char(field_value));
        elseif isnumeric(field_value) && numel(field_value) == 1
            fprintf('  • data.ddc_info.%s = %g\n', field_name, field_value);
        else
            fprintf('  • data.ddc_info.%s = [%s]\n', field_name, class(field_value));
        end
    end
    
    fprintf('\nVí dụ truy cập:\n');
    if isfield(ddc, 'frequency')
        fprintf('  ddc_freq = data.ddc_info.frequency;\n');
    end
    if isfield(ddc, 'channelIndex')
        fprintf('  channel = data.ddc_info.channelIndex;\n');
    end
else
    fprintf('⚠ Không có ddc_info trong file này.\n');
end
fprintf('\n');

%% 4. CÁCH LẤY REQUEST INFO
fprintf('\n==================================================\n');
fprintf(' [3] THÔNG TIN REQUEST\n');
fprintf('==================================================\n');
fprintf('Cú pháp: data.request_info\n\n');

if isfield(allData, 'request_info') && ~isempty(allData.request_info)
    req = allData.request_info;
    fprintf('Các trường có trong request_info:\n');
    fields = fieldnames(req);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = req.(field_name);
        
        if ischar(field_value) || isstring(field_value)
            val_str = char(field_value);
            if length(val_str) > 50
                val_str = [val_str(1:47) '...'];
            end
            fprintf('  • data.request_info.%s = "%s"\n', field_name, val_str);
        elseif isnumeric(field_value) && numel(field_value) == 1
            fprintf('  • data.request_info.%s = %g\n', field_name, field_value);
        else
            fprintf('  • data.request_info.%s = [%s]\n', field_name, class(field_value));
        end
    end
    
    fprintf('\nVí dụ truy cập:\n');
    if isfield(req, 'fileName')
        fprintf('  file_name = data.request_info.fileName;\n');
    end
    if isfield(req, 'duration')
        fprintf('  duration = data.request_info.duration;\n');
    end
else
    fprintf('⚠ Không có request_info trong file này.\n');
end
fprintf('\n');

%% 5. CÁCH LẤY DỮ LIỆU I/Q SESSIONS
fprintf('\n==================================================\n');
fprintf(' [4] TRUY XUẤT DỮ LIỆU I/Q SESSIONS\n');
fprintf('==================================================\n');
fprintf('Cú pháp: data.sessions(i)\n\n');

sessions = allData.sessions;
num_sess = length(sessions);

% Tìm session đầu tiên có dữ liệu thực
target_idx = -1;
for i = 1:num_sess
    % Kiểm tra có dữ liệu I/Q không
    if ~isempty(sessions(i).i) && ~isempty(sessions(i).q)
        if max(abs(sessions(i).i)) > 0 || max(abs(sessions(i).q)) > 0
            target_idx = i;
            break;
        end
    end
end

if target_idx == -1
    fprintf('CẢNH BÁO: Đã duyệt qua %d session nhưng không tìm thấy dữ liệu.\n', num_sess);
    target_idx = 1; % Vẫn lấy session 1 để minh họa
else
    fprintf('-> Tìm thấy dữ liệu thực tại Session thứ: %d (ID: %s)\n', ...
        target_idx, sessions(target_idx).id);
end

% Lấy session ra biến tạm
sess = sessions(target_idx);

% ---------------------------------------------------------
% A. LẤY ID VÀ THÔNG TIN CƠ BẢN
% ---------------------------------------------------------
fprintf('\n--- A. Session ID và Thông tin cơ bản ---\n');
fprintf('   Session ID: %s\n', sess.id);
fprintf('   Cú pháp: data.sessions(%d).id\n', target_idx);
fprintf('\n');

% ---------------------------------------------------------
% B. LẤY DỮ LIỆU I (IN-PHASE)
% ---------------------------------------------------------
fprintf('--- B. Dữ liệu I (In-phase) ---\n');
fprintf('   Cú pháp: data.sessions(%d).i\n', target_idx);

if ~isempty(sess.i)
    fprintf('   Kích thước: %d mẫu (%d dòng x %d cột)\n', ...
        length(sess.i), size(sess.i, 1), size(sess.i, 2));
    fprintf('   Kiểu dữ liệu: %s\n', class(sess.i));
    
    fprintf('   5 giá trị đầu:\n');
    num_display = min(5, length(sess.i));
    for m = 1:num_display
        fprintf('     [%d] I = %d\n', m, sess.i(m));
    end
    
    fprintf('   Thống kê: Min=%d, Max=%d, Mean=%.2f\n', ...
        min(sess.i), max(sess.i), mean(double(sess.i)));
else
    fprintf('   ⚠ Không có dữ liệu I\n');
end
fprintf('\n');

% ---------------------------------------------------------
% C. LẤY DỮ LIỆU Q (QUADRATURE)
% ---------------------------------------------------------
fprintf('--- C. Dữ liệu Q (Quadrature) ---\n');
fprintf('   Cú pháp: data.sessions(%d).q\n', target_idx);

if ~isempty(sess.q)
    fprintf('   Kích thước: %d mẫu (%d dòng x %d cột)\n', ...
        length(sess.q), size(sess.q, 1), size(sess.q, 2));
    fprintf('   Kiểu dữ liệu: %s\n', class(sess.q));
    
    fprintf('   5 giá trị đầu:\n');
    num_display = min(5, length(sess.q));
    for m = 1:num_display
        fprintf('     [%d] Q = %d\n', m, sess.q(m));
    end
    
    fprintf('   Thống kê: Min=%d, Max=%d, Mean=%.2f\n', ...
        min(sess.q), max(sess.q), mean(double(sess.q)));
else
    fprintf('   ⚠ Không có dữ liệu Q\n');
end
fprintf('\n');

% ---------------------------------------------------------
% D. LẤY DỮ LIỆU PHỨC IQ (I + j*Q)
% ---------------------------------------------------------
fprintf('--- D. Dữ liệu phức IQ (I + j*Q) ---\n');
fprintf('   Cú pháp: data.sessions(%d).iq\n', target_idx);
fprintf('   (Đã tự động tạo từ I và Q)\n\n');

if ~isempty(sess.iq)
    fprintf('   Kích thước: %d mẫu phức\n', length(sess.iq));
    fprintf('   Kiểu dữ liệu: %s\n', class(sess.iq));
    
    fprintf('   5 giá trị đầu (dạng phức):\n');
    num_display = min(5, length(sess.iq));
    for m = 1:num_display
        fprintf('     [%d] IQ = %g + %gj\n', m, real(sess.iq(m)), imag(sess.iq(m)));
    end
    
    % Thống kê
    iq_mag = abs(sess.iq);
    fprintf('   Thống kê:\n');
    fprintf('     - Biên độ (|IQ|): Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
        min(iq_mag), max(iq_mag), mean(iq_mag));
    fprintf('     - Phase (rad): Min=%.3f, Max=%.3f\n', ...
        min(angle(sess.iq)), max(angle(sess.iq)));
else
    fprintf('   ⚠ Không có dữ liệu IQ phức\n');
end
fprintf('\n');

%% 6. VẼ BIỂU ĐỒ (VISUALIZATION)
if ~isempty(sess.i) && ~isempty(sess.q)
    fprintf('==================================================\n');
    fprintf(' [5] VẼ BIỂU ĐỒ I/Q DATA\n');
    fprintf('==================================================\n');
    
    figure('Name', ['IQ Data - Session ' sess.id], 'Color', 'w');
    
    % Subplot 1: I & Q theo thời gian
    subplot(2,2,1);
    plot(sess.i, 'b-', 'LineWidth', 0.5); hold on;
    plot(sess.q, 'r-', 'LineWidth', 0.5);
    title(sprintf('Time Domain - I & Q (Session %s)', sess.id), 'Interpreter', 'none');
    xlabel('Sample Index');
    ylabel('Amplitude');
    legend('I (In-phase)', 'Q (Quadrature)', 'Location', 'best');
    grid on;
    
    % Subplot 2: Constellation Diagram
    subplot(2,2,2);
    plot(sess.i, sess.q, '.', 'MarkerSize', 2);
    title('Constellation Diagram (I vs Q)');
    xlabel('I (In-phase)');
    ylabel('Q (Quadrature)');
    axis equal;
    grid on;
    
    % Subplot 3: Biên độ của tín hiệu phức
    subplot(2,2,3);
    iq_magnitude = abs(sess.iq);
    plot(iq_magnitude, 'g-', 'LineWidth', 0.5);
    title('Magnitude |I + jQ|');
    xlabel('Sample Index');
    ylabel('|IQ|');
    grid on;
    
    % Subplot 4: Phase của tín hiệu phức
    subplot(2,2,4);
    iq_phase = angle(sess.iq);
    plot(iq_phase, 'm-', 'LineWidth', 0.5);
    title('Phase (angle)');
    xlabel('Sample Index');
    ylabel('Phase (rad)');
    grid on;
    
    % Tạo title chung nếu có thông tin frequency
    if isfield(g_info, 'frequency')
        freq_mhz = double(g_info.frequency) / 1e6;
        sgtitle(sprintf('IQ Data Analysis - Freq: %.2f MHz', freq_mhz), ...
            'FontSize', 12, 'FontWeight', 'bold');
    end
    
    fprintf('→ Đã vẽ 4 biểu đồ I/Q data.\n');
else
    fprintf('⚠ Không có dữ liệu để vẽ biểu đồ.\n');
end
fprintf('\n');

%% 7. VÍ DỤ: DUYỆT QUA TẤT CẢ SESSIONS
fprintf('==================================================\n');
fprintf(' [6] VÍ DỤ: DUYỆT QUA TẤT CẢ SESSIONS\n');
fprintf('==================================================\n');
fprintf('Code mẫu:\n\n');
fprintf('for i = 1:length(allData.sessions)\n');
fprintf('    session = allData.sessions(i);\n');
fprintf('    \n');
fprintf('    %% Lấy thông tin session\n');
fprintf('    session_id = session.id;\n');
fprintf('    \n');
fprintf('    %% Lấy dữ liệu I/Q\n');
fprintf('    i_data = session.i;      %% In-phase\n');
fprintf('    q_data = session.q;      %% Quadrature\n');
fprintf('    iq_complex = session.iq; %% I + j*Q (số phức)\n');
fprintf('    \n');
fprintf('    %% Xử lý dữ liệu...\n');
fprintf('    magnitude = abs(iq_complex);\n');
fprintf('    phase = angle(iq_complex);\n');
fprintf('end\n\n');

%% 8. BẢNG TÓM TẮT CẤU TRÚC OUTPUT
fprintf('==================================================\n');
fprintf(' [7] BẢNG TÓM TẮT CẤU TRÚC OUTPUT\n');
fprintf('==================================================\n');
fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
fprintf('│ TRƯỜNG                              │ MÔ TẢ                        │\n');
fprintf('├─────────────────────────────────────────────────────────────────────┤\n');
fprintf('│ data.global_info                    │ Attributes từ /attribute     │\n');
fprintf('│   .client_ip                        │ IP client                    │\n');
fprintf('│   .frequency                        │ Tần số trung tâm (Hz)        │\n');
fprintf('│   .bandwidth                        │ Băng thông (Hz)              │\n');
fprintf('│   .channel                          │ Kênh                         │\n');
fprintf('│   .mission                          │ Nhiệm vụ                     │\n');
fprintf('│   ...                               │                              │\n');
fprintf('├─────────────────────────────────────────────────────────────────────┤\n');
fprintf('│ data.ddc_info                       │ Attributes từ /attribute/ddc │\n');
fprintf('│   .channelIndex                     │ Chỉ số kênh                  │\n');
fprintf('│   .frequency                        │ Tần số DDC                   │\n');
fprintf('│   .deviceId                         │ ID thiết bị                  │\n');
fprintf('│   ...                               │                              │\n');
fprintf('├─────────────────────────────────────────────────────────────────────┤\n');
fprintf('│ data.request_info                   │ Attributes từ /attribute/req │\n');
fprintf('│   .fileName                         │ Tên file                     │\n');
fprintf('│   .duration                         │ Thời lượng                   │\n');
fprintf('│   .checkpoint                       │ Checkpoint                   │\n');
fprintf('│   ...                               │                              │\n');
fprintf('├─────────────────────────────────────────────────────────────────────┤\n');
fprintf('│ data.sessions(i)                    │ Session thứ i                │\n');
fprintf('│   .id                               │ ID của session               │\n');
fprintf('│   .i                                │ Dữ liệu I (In-phase)         │\n');
fprintf('│   .q                                │ Dữ liệu Q (Quadrature)       │\n');
fprintf('│   .iq                               │ Dữ liệu phức I + j*Q         │\n');
fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
fprintf('\n');

fprintf('=== HOÀN THÀNH HƯỚNG DẪN ===\n');


%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5 của bạn (Phổ histogram - mô-đun survey)
filename = '/home/vht/Documents/PRJ/01_data_h5/digitizer_200_0/2026_01_15/20260115_143531_histogram.0.h5'; 

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);
fprintf('>>> (Sử dụng read_histgram_h5_multitype - hỗ trợ AccumulatedPower và CrossingThresholdPower)\n\n');

% Gọi hàm read_histgram_h5_multitype (Đảm bảo file hàm nằm cùng thư mục)
try
    allData = read_histogram_h5_multitype(filename);
catch ME
    error('Lỗi khi đọc file: %s', ME.message);
end

%% 2. CÁCH LẤY DỮ LIỆU CHUNG (GLOBAL INFO)
fprintf('\n==================================================\n');
fprintf(' [1] THÔNG TIN CHUNG (GLOBAL INFO)\n');
fprintf('==================================================\n');

% Truy cập vào struct global_info
g_info = allData.global_info;

if ~isempty(g_info)
    disp(g_info);
    
    % --- VÍ DỤ CÚ PHÁP LẤY GIÁ TRỊ CỤ THỂ ---
    % Cú pháp: allData.global_info.(tên_trường)
    if isfield(g_info, 'client_ip')
        ip = g_info.client_ip; 
        fprintf('-> Client IP: %s\n', ip);
    end
    if isfield(g_info, 'mission')
        mission = g_info.mission;
        fprintf('-> Mission: %s\n', mission);
    end
else
    disp('Không có thông tin Global.');
end

%% 3. CÁCH LẤY DỮ LIỆU SESSION (ATTRIBUTES, SOURCE, CONTEXT, SAMPLES)
fprintf('\n==================================================\n');
fprintf(' [2] TRUY XUẤT DỮ LIỆU SESSION\n');
fprintf('==================================================\n');

sessions = allData.sessions;
num_sess = length(sessions);

% Tìm session đầu tiên có dữ liệu thực để làm mẫu
target_idx = -1;
for i = 1:num_sess
    % Kiểm tra có dữ liệu không (có thể là sample_decoded, acc_sample_decoded, hoặc crx_sample_decoded)
    has_data = false;
    if ~isempty(sessions(i).sample_decoded) && max(abs(sessions(i).sample_decoded)) > 0
        has_data = true;
    elseif ~isempty(sessions(i).acc_sample_decoded) && max(abs(sessions(i).acc_sample_decoded)) > 0
        has_data = true;
    elseif ~isempty(sessions(i).crx_sample_decoded) && max(abs(sessions(i).crx_sample_decoded)) > 0
        has_data = true;
    end
    
    if has_data
        target_idx = i;
        break; 
    end
end

if target_idx == -1
    fprintf('CẢNH BÁO: Đã duyệt qua %d session nhưng không tìm thấy dữ liệu.\n', num_sess);
    % Vẫn lấy session 1 để minh họa code
    target_idx = 1; 
else
    fprintf('-> Tìm thấy dữ liệu thực tại Session thứ: %d (ID: %s)\n', ...
        target_idx, sessions(target_idx).id);
end

% Lấy session ra biến tạm cho gọn
sess = sessions(target_idx);

% ---------------------------------------------------------
% A. CÁCH LẤY LOẠI MESSAGE TYPE
% ---------------------------------------------------------
fprintf('\n--- A. Message Type (Loại bản tin) ---\n');
% Cú pháp: data.sessions(i).type

msg_type = sess.type;
if ~isempty(msg_type)
    fprintf('   Message Type: %s\n', msg_type);
    
    if contains(msg_type, 'AccumulatedPower')
        fprintf('   → Loại: AccumulatedPower (sử dụng sample_decoded)\n');
    elseif contains(msg_type, 'CrossingThresholdPower')
        fprintf('   → Loại: CrossingThresholdPower (sử dụng acc_sample_decoded và crx_sample_decoded)\n');
    else
        fprintf('   → Loại: Không xác định hoặc mặc định\n');
    end
else
    fprintf('   (Không có message_type)\n');
end

% ---------------------------------------------------------
% B. CÁCH LẤY THÔNG SỐ KỸ THUẬT (ATTRIBUTES)
% ---------------------------------------------------------
fprintf('\n--- B. Attributes (Tần số, Băng thông, Timestamp...) ---\n');
% Cú pháp: data.sessions(i).attributes.(tên_thuộc_tính)

if ~isempty(sess.attributes)
    % Hiển thị message_type nếu có
    if isfield(sess.attributes, 'message_type')
        msg_attr = sess.attributes.message_type;
        fprintf('   message_type: %s\n', char(msg_attr));
    end
    
    if isfield(sess.attributes, 'frequency')
        freq = sess.attributes.frequency; 
        % Lưu ý: freq có thể là int64, nên convert sang double để tính toán
        fprintf('   Frequency : %.2f MHz\n', double(freq)/1e6);
    end

    if isfield(sess.attributes, 'bandwidth')
        bw = sess.attributes.bandwidth;
        fprintf('   Bandwidth : %.2f MHz\n', double(bw)/1e6);
    end

    if isfield(sess.attributes, 'timestamp')
        ts = sess.attributes.timestamp;
        fprintf('   Timestamp : %d\n', ts);
    end
    
    % Hiển thị các attributes khác nếu có
    attr_fields = fieldnames(sess.attributes);
    other_attrs = setdiff(attr_fields, {'message_type', 'frequency', 'bandwidth', 'timestamp'});
    if ~isempty(other_attrs)
        fprintf('   Các attributes khác:\n');
        for i = 1:length(other_attrs)
            attr_name = other_attrs{i};
            attr_val = sess.attributes.(attr_name);
            if isnumeric(attr_val) && numel(attr_val) == 1
                fprintf('     - %s: %g\n', attr_name, attr_val);
            elseif ischar(attr_val) || isstring(attr_val)
                fprintf('     - %s: %s\n', attr_name, char(attr_val));
            else
                fprintf('     - %s: [%s]\n', attr_name, class(attr_val));
            end
        end
    end
else
    fprintf('   (Không có attributes)\n');
end

% ---------------------------------------------------------
% C. CÁCH LẤY THÔNG TIN CONTEXT (Nếu có)
% ---------------------------------------------------------
fprintf('\n--- C. Context Info (Thông tin ngữ cảnh) ---\n');
% Cú pháp: data.sessions(i).context_info

if ~isempty(sess.context_info)
    disp(sess.context_info);
    
    % Lấy giá trị cụ thể nếu có
    ctx_fields = fieldnames(sess.context_info);
    if ~isempty(ctx_fields)
        fprintf('   Các trường trong context_info:\n');
        for i = 1:length(ctx_fields)
            field_name = ctx_fields{i};
            field_val = sess.context_info.(field_name);
            if isnumeric(field_val) && numel(field_val) == 1
                fprintf('     - %s: %g\n', field_name, field_val);
            elseif ischar(field_val) || isstring(field_val)
                fprintf('     - %s: %s\n', field_name, char(field_val));
            else
                fprintf('     - %s: [%s]\n', field_name, class(field_val));
            end
        end
    end
else
    fprintf('   (Không có thông tin Context)\n');
end

% ---------------------------------------------------------
% D. CÁCH LẤY THÔNG TIN THIẾT BỊ (SOURCE INFO)
% ---------------------------------------------------------
fprintf('\n--- D. Source Info (Thiết bị, Anten...) ---\n');
% Cú pháp: data.sessions(i).source_info.(tên_thuộc_tính)

if ~isempty(sess.source_info)
    disp(sess.source_info); % In toàn bộ struct
    
    % Lấy giá trị cụ thể
    if isfield(sess.source_info, 'device')
        dev = sess.source_info.device;
        fprintf('   Tên thiết bị: %s\n', dev);
    end
    if isfield(sess.source_info, 'antenna')
        ant = sess.source_info.antenna;
        fprintf('   Anten: %s\n', ant);
    end
else
    fprintf('   (Không có thông tin Source)\n');
end

% ---------------------------------------------------------
% E. CÁCH LẤY DỮ LIỆU MẪU (SAMPLES - Histogram)
% ---------------------------------------------------------
fprintf('\n--- E. Samples (Dữ liệu histogram) ---\n');
% Cú pháp phụ thuộc vào message_type:
%   - AccumulatedPower: data.sessions(i).sample_decoded
%   - CrossingThresholdPower: data.sessions(i).acc_sample_decoded và crx_sample_decoded

% Kiểm tra loại message và đọc dữ liệu tương ứng
if contains(msg_type, 'CrossingThresholdPower')
    % --- TRƯỜNG HỢP: CrossingThresholdPower ---
    fprintf('   Loại: CrossingThresholdPower\n');
    
    % Đọc acc_sample_decoded
    fprintf('\n   [1] acc_sample_decoded (Accumulated):\n');
    acc_data = sess.acc_sample_decoded;
    if ~isempty(acc_data)
        fprintf('      Kích thước: %d dòng x %d cột\n', size(acc_data));
        fprintf('      Kiểu dữ liệu: %s\n', class(acc_data));
        fprintf('      5 giá trị đầu: \n');
        disp(acc_data(1:min(5, length(acc_data))));
        fprintf('      Min: %e, Max: %e, Sum: %e\n', ...
            min(acc_data), max(acc_data), sum(acc_data));
    else
        fprintf('      (Không có dữ liệu)\n');
    end
    
    % Đọc crx_sample_decoded
    fprintf('\n   [2] crx_sample_decoded (Crossing):\n');
    crx_data = sess.crx_sample_decoded;
    if ~isempty(crx_data)
        fprintf('      Kích thước: %d dòng x %d cột\n', size(crx_data));
        fprintf('      Kiểu dữ liệu: %s\n', class(crx_data));
        fprintf('      5 giá trị đầu: \n');
        disp(crx_data(1:min(5, length(crx_data))));
        fprintf('      Min: %e, Max: %e, Sum: %e\n', ...
            min(crx_data), max(crx_data), sum(crx_data));
    else
        fprintf('      (Không có dữ liệu)\n');
    end
    
    histogram_data = acc_data; % Dùng acc_data làm dữ liệu chính để vẽ
    has_crx_data = ~isempty(crx_data);
    
else
    % --- TRƯỜNG HỢP: AccumulatedPower hoặc mặc định ---
    fprintf('   Loại: AccumulatedPower (hoặc mặc định)\n');
    
    fprintf('\n   sample_decoded:\n');
    histogram_data = sess.sample_decoded;
    if ~isempty(histogram_data)
        fprintf('      Kích thước: %d dòng x %d cột\n', size(histogram_data));
        fprintf('      Kiểu dữ liệu: %s\n', class(histogram_data));
        fprintf('      5 giá trị đầu: \n');
        disp(histogram_data(1:min(5, length(histogram_data))));
        fprintf('      Min: %e, Max: %e, Sum: %e\n', ...
            min(histogram_data), max(histogram_data), sum(histogram_data));
    else
        fprintf('      (Không có dữ liệu)\n');
    end
    
    has_crx_data = false;
end

%% 4. VẼ BIỂU ĐỒ (VISUALIZATION)
if ~isempty(histogram_data)
    figure('Name', ['Histogram Session ' sess.id], 'Color', 'w');
    
    if contains(msg_type, 'CrossingThresholdPower') && has_crx_data
        % Vẽ cả 2 loại dữ liệu cho CrossingThresholdPower
        subplot(2,1,1);
        bar(acc_data);
        grid on;
        title('Accumulated (acc\_sample\_decoded)', 'Interpreter', 'none');
        xlabel('Bin Index');
        ylabel('Count / Frequency');
        
        subplot(2,1,2);
        bar(crx_data);
        grid on;
        title('Crossing (crx\_sample\_decoded)', 'Interpreter', 'none');
        xlabel('Bin Index');
        ylabel('Count / Frequency');
        
        % Tạo tiêu đề chung
        if isfield(sess.attributes, 'frequency')
            sgtitle(sprintf('Histogram - Session: %s | Type: %s | Freq: %.1f MHz', ...
                sess.id, msg_type, double(sess.attributes.frequency)/1e6), ...
                'Interpreter', 'none');
        else
            sgtitle(sprintf('Histogram - Session: %s | Type: %s', sess.id, msg_type), ...
                'Interpreter', 'none');
        end
    else
        % Vẽ 1 loại dữ liệu cho AccumulatedPower
        bar(histogram_data);
        grid on;
        
        % Tạo tiêu đề tự động từ dữ liệu đọc được
        if isfield(sess.attributes, 'frequency')
            title_str = sprintf('Histogram Data - Session: %s\nType: %s | Freq: %.1f MHz', ...
                sess.id, msg_type, double(sess.attributes.frequency)/1e6);
        else
            title_str = sprintf('Histogram Data - Session: %s\nType: %s', sess.id, msg_type);
        end
        title(title_str, 'Interpreter', 'none');
        xlabel('Bin Index');
        ylabel('Count / Frequency');
        legend('sample\_decoded', 'Location', 'best');
    end
else
    disp('Không có dữ liệu để vẽ biểu đồ.');
end

%% 5. VÍ DỤ: DUYỆT QUA TẤT CẢ SESSIONS
fprintf('\n==================================================\n');
fprintf(' [3] VÍ DỤ: DUYỆT QUA TẤT CẢ SESSIONS\n');
fprintf('==================================================\n');
fprintf('Code mẫu để xử lý tất cả sessions:\n\n');
fprintf('for i = 1:length(allData.sessions)\n');
fprintf('    session = allData.sessions(i);\n');
fprintf('    \n');
fprintf('    %% Lấy thông tin session\n');
fprintf('    session_id = session.id;\n');
fprintf('    msg_type = session.type;\n');
fprintf('    \n');
fprintf('    %% Xử lý theo loại message\n');
fprintf('    if contains(msg_type, ''CrossingThresholdPower'')\n');
fprintf('        %% Xử lý CrossingThresholdPower\n');
fprintf('        acc_data = session.acc_sample_decoded;\n');
fprintf('        crx_data = session.crx_sample_decoded;\n');
fprintf('        %% ... xử lý dữ liệu ...\n');
fprintf('    else\n');
fprintf('        %% Xử lý AccumulatedPower\n');
fprintf('        hist_data = session.sample_decoded;\n');
fprintf('        %% ... xử lý dữ liệu ...\n');
fprintf('    end\n');
fprintf('end\n\n');

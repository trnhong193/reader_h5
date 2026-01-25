% test.m
clc; clear; close all;

% =========================================================================
% CẤU HÌNH: ĐIỀN TÊN FILE H5 CẦN TEST VÀO ĐÂY
filename = '/home/vht/Documents/PRJ/01_data_h5/digitizer_200_0/2026_01_15/20260115_143531_histogram.0.h5'; 
% =========================================================================

fprintf('--- BẮT ĐẦU TEST FILE: %s ---\n', filename);

% 1. Gọi hàm đọc file
try
    tic;
    data = read_histogram_h5_multitype(filename);
    time_elapsed = toc;
    fprintf('Đọc file thành công trong %.4f giây.\n', time_elapsed);
catch ME
    error('LỖI KHI ĐỌC FILE: %s', ME.message);
end

% 2. Kiểm tra Global Info (So sánh với Attributes của group /attribute trong HDFView)
fprintf('\n========================================\n');
fprintf(' [1] GLOBAL INFO (/attribute)\n');
fprintf('========================================\n');
if isfield(data, 'global_info') && ~isempty(data.global_info)
    disp(data.global_info);
else
    fprintf('Warning: Không tìm thấy Global Info.\n');
end

% 3. Kiểm tra Sessions
if ~isfield(data, 'sessions') || isempty(data.sessions)
    fprintf('Warning: Không tìm thấy session nào.\n');
    return;
end

num_sessions = length(data.sessions);
fprintf('\n========================================\n');
fprintf(' [2] SESSIONS FOUND: %d\n', num_sessions);
fprintf('========================================\n');

% Chỉ test chi tiết tối đa 3 sessions đầu tiên để tránh spam terminal
num_test = min(3, num_sessions); 

for i = 1:num_test
    sess = data.sessions(i);
    
    fprintf('\n----------------------------------------\n');
    fprintf('>> SESSION #%d (ID: %s)\n', i, sess.id);
    fprintf('----------------------------------------\n');
    
    % A. Attributes
    fprintf('   + Message Type: %s\n', sess.type);
    fprintf('   + Attributes (Check HDFView attributes):\n');
    disp(sess.attributes);
    
    % B. Context & Source
    if ~isempty(sess.context_info)
        fprintf('   + Context Info:\n');
        disp(sess.context_info);
    end
    
    % C. Data Arrays (Phần quan trọng nhất để so sánh)
    fprintf('   + DATA CHECK:\n');
    
    % Logic hiển thị dựa trên loại bản tin
    if contains(sess.type, 'CrossingThresholdPower')
        % --- Kiểm tra dữ liệu Crossing ---
        % ACC
        if ~isempty(sess.acc_sample_decoded)
            vals = sess.acc_sample_decoded;
            n = length(vals);
            fprintf('     -> [acc_sample_decoded]: Size = %d\n', n);
            fprintf('        First 5 values: %s\n', mat2str(vals(1:min(5,n)), 4));
            fprintf('        Last  5 values: %s\n', mat2str(vals(max(1,n-4):n), 4));
        else
            fprintf('     -> [acc_sample_decoded]: EMPTY!\n');
        end
        
        % CRX
        if ~isempty(sess.crx_sample_decoded)
            vals = sess.crx_sample_decoded;
            n = length(vals);
            fprintf('     -> [crx_sample_decoded]: Size = %d\n', n);
            fprintf('        First 5 values: %s\n', mat2str(vals(1:min(5,n)), 4));
        else
            fprintf('     -> [crx_sample_decoded]: EMPTY!\n');
        end
        
    else
        % --- Kiểm tra dữ liệu Accumulated / Normal ---
        if ~isempty(sess.sample_decoded)
            vals = sess.sample_decoded;
            n = length(vals);
            fprintf('     -> [sample_decoded]: Size = %d\n', n);
            fprintf('        First 5 values: %s\n', mat2str(vals(1:min(5,n)), 4));
            fprintf('        Last  5 values: %s\n', mat2str(vals(max(1,n-4):n), 4));
        else
            fprintf('     -> [sample_decoded]: EMPTY!\n');
            % Check thử xem có bị nhầm sang acc không
            if ~isempty(sess.acc_sample_decoded)
                fprintf('        (NOTE: Tìm thấy dữ liệu ở acc_sample_decoded nhưng type không phải Crossing)\n');
            end
        end
    end
end

fprintf('\nDone check.\n');
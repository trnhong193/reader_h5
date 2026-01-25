%% TEST SCRIPT (FLAT / NORMAL CODE VERSION)
clc; clear; close all;

filename = '/home/vht/Documents/PRJ/00_DATA_h5/4test/identifier.h5'; % Thay tên file của bạn

% 1. Đọc file bằng hàm mới (không đệ quy)
try
    data = reader_identifier_no_recursive(filename);
    disp('Đọc file thành công!');
catch ME
    error('Lỗi đọc file: %s', ME.message);
end

% 2. Kiểm tra thông tin Label
fprintf('\n--- LABEL INFO ---\n');
if isfield(data, 'request') && isfield(data.request, 'label')
    disp(data.request.label);
end

% 3. Kiểm tra thông số Hop (/estm_bdw)
fprintf('\n--- HOP PARAMETERS ---\n');
if isfield(data, 'estm_bdw') && isfield(data.estm_bdw, 'fc')
    fprintf('Số lượng Hop: %d\n', length(data.estm_bdw.fc));
    fprintf('Freq Hop 1: %.2f MHz\n', double(data.estm_bdw.fc(1))/1e6);
end

% 4. Kiểm tra DOA (Position)
fprintf('\n--- DOA POSITION ---\n');
if isfield(data, 'doa') && isfield(data.doa, 'position')
    if isfield(data.doa.position, 'vecDoas')
        sz = size(data.doa.position.vecDoas);
        fprintf('Kích thước vecDoas: %d x %d\n', sz(1), sz(2));
    end
end

% 5. Kiểm tra Session IQ
fprintf('\n--- SESSION IQ ---\n');
if isfield(data, 'sessions') && ~isempty(data.sessions)
    % Lấy session đầu tiên
    sess1 = data.sessions(1);
    fprintf('Session ID: %s\n', sess1.id);
    
    if ~isempty(sess1.iq)
        fprintf('IQ Data Length: %d (Complex)\n', length(sess1.iq));
        
        % Vẽ đồ thị
        figure;
        plot(sess1.iq, '.');
        title(['Constellation: ' sess1.id], 'Interpreter', 'none');
        axis equal; grid on;
    else
        fprintf('Session này không có dữ liệu IQ.\n');
    end
else
    fprintf('Không tìm thấy session nào.\n');
end

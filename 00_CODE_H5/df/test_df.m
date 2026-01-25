%% TEST DF READER (FLAT STRUCTURE)
clc; clear; close all;

filename = '/home/vht/Documents/PRJ/00_DATA_h5/4test/df.h5'; % Thay tên file của bạn

try
    data = reader_df(filename);
    disp('Đọc file thành công!');
catch ME
    error('Lỗi: %s', ME.message);
end

% 1. Kiểm tra Configuration (Attributes)
fprintf('\n--- CONFIGURATION (Attributes) ---\n');
if isfield(data, 'configuration')
    % Kiểm tra thử antParams (dựa theo ảnh 1)
    if isfield(data.configuration, 'antParams')
        disp('Antenna Params:');
        disp(data.configuration.antParams);
    end
end

% 2. Kiểm tra Calibration (Datasets)
fprintf('\n--- CALIBRATION (Datasets) ---\n');
if isfield(data, 'calibration') && isfield(data.calibration, 'Table_0')
    cal0 = data.calibration.Table_0;
    if isfield(cal0, 'pow1')
        fprintf('Calibration Table 0 - pow1 size: %d\n', length(cal0.pow1));
    end
end

% 3. Kiểm tra Session & DOA Vectors
fprintf('\n--- SESSION & DOA ---\n');
if ~isempty(data.sessions)
    s1 = data.sessions(1);
    fprintf('Session ID: %s\n', s1.id);
    
    % Kiểm tra Pulse Data
    if isfield(s1.pulses, 'fc')
        fprintf('Số lượng xung (Pulses): %d\n', length(s1.pulses.fc));
    end
    
    % Kiểm tra DOA (Target_0)
    if isfield(s1.doa, 'Target_0')
        tgt0 = s1.doa.Target_0;
        
        % Vị trí (vecDoas)
        if isfield(tgt0, 'position') && isfield(tgt0.position, 'vecDoas')
            vec = tgt0.position.vecDoas;
            fprintf('DOA Vectors (Target 0): %dx%d\n', size(vec,1), size(vec,2));
            
            % Vẽ biểu đồ nếu có dữ liệu
            figure; plot(vec, '.-'); title('DOA Vectors'); grid on;
        end
        
        % Đặc trưng (meanBws) - Nằm sâu trong identity/features
        if isfield(tgt0, 'identity_features')
            disp('Identity Features found (meanBws/meanFcs).');
            disp(tgt0.identity_features);
        end
    else
        disp('Không tìm thấy Target_0 trong session này.');
    end
end

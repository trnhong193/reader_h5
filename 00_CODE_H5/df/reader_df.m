function data = read_df(filename)
% READ_DF_FLAT Đọc file DF/DOA (Cấu trúc cố định, Không đệ quy)
%   Dựa trên cấu trúc ảnh chụp:
%   1. /attribute/configuration -> Đọc Attributes
%   2. /attribute/calibration/calibs -> Đọc Datasets (pow1, dps...)
%   3. /session -> Đọc Pulses (amp, fc...) và DOA (vecDoas...)

    if ~isfile(filename)
        error('File không tồn tại: %s', filename);
    end

    fprintf('Đang quét file: %s ... ', filename);
    info = h5info(filename);
    fprintf('Xong.\n');
    
    data = struct();
    
    %% --- PHẦN 1: ĐỌC ATTRIBUTE & CALIBRATION ---
    fprintf('1. Đang đọc Cấu hình & Hiệu chuẩn...\n');
    
    attr_idx = find_idx(info.Groups, '/attribute');
    if attr_idx > 0
        attr_group = info.Groups(attr_idx);
        
        % A. ĐỌC CONFIGURATION (antParams, filterParams...)
        % Dữ liệu nằm trong "Object Attribute Info" (Attributes)
        conf_idx = find_idx(attr_group.Groups, '/attribute/configuration');
        if conf_idx > 0
            conf_grp = attr_group.Groups(conf_idx);
            data.configuration = struct();
            
            for i = 1:length(conf_grp.Groups)
                sub = conf_grp.Groups(i);
                [~, name] = fileparts(sub.Name);
                % Đọc Attributes đính kèm folder
                data.configuration.(matlab.lang.makeValidName(name)) = read_attrs(sub);
            end
        end
        
        % B. ĐỌC CALIBRATION (calibs -> 0, 1, 2...)
        % Dữ liệu nằm trong Datasets (pow1, dps...)
        cal_idx = find_idx(attr_group.Groups, '/attribute/calibration');
        if cal_idx > 0
            cal_main = attr_group.Groups(cal_idx);
            % Tìm folder 'calibs'
            calibs_idx = find_idx(cal_main.Groups, [cal_main.Name '/calibs']);
            
            if calibs_idx > 0
                calibs_grp = cal_main.Groups(calibs_idx);
                data.calibration = struct();
                
                % Duyệt qua các folder 0, 1, 2
                for i = 1:length(calibs_grp.Groups)
                    sub = calibs_grp.Groups(i);
                    [~, name] = fileparts(sub.Name);
                    valid_name = ['Table_' name]; % Table_0, Table_1
                    
                    % Đọc Datasets bên trong (pow1, dps...)
                    data.calibration.(valid_name) = read_datasets(filename, sub);
                end
            end
        end
    end

    %% --- PHẦN 2: ĐỌC SESSION & DEEP DOA ---
    fprintf('2. Đang đọc Session & DOA Data...\n');
    
    sess_root_idx = find_idx(info.Groups, '/session');
    if sess_root_idx > 0
        session_folders = info.Groups(sess_root_idx).Groups;
        num_sess = length(session_folders);
        
        fprintf('   Tìm thấy %d sessions.\n', num_sess);
        data.sessions = repmat(struct('id', '', 'pulses', [], 'doa', []), num_sess, 1);
        
        h = waitbar(0, 'Đang đọc dữ liệu Session...');
        
        for k = 1:num_sess
            curr = session_folders(k);
            [~, sid] = fileparts(curr.Name);
            data.sessions(k).id = sid;
            
            % A. Đọc thông số xung (amp, fc, bw...) - Nằm ngay tại session
            data.sessions(k).pulses = read_datasets(filename, curr);
            
            % B. Đọc DOA (Deep Structure: /doa/doa/0/...)
            % Cấu trúc trong ảnh: session -> doa -> doa -> 0 -> (position, identity...)
            doa_struct = struct();
            
            % B1. Vào folder /doa
            doa_g1_idx = find_idx(curr.Groups, [curr.Name '/doa']);
            if doa_g1_idx > 0
                doa_g1 = curr.Groups(doa_g1_idx);
                
                % B2. Vào tiếp folder /doa (doa lồng doa)
                doa_g2_idx = find_idx(doa_g1.Groups, [doa_g1.Name '/doa']);
                if doa_g2_idx > 0
                    doa_g2 = doa_g1.Groups(doa_g2_idx);
                    
                    % B3. Duyệt qua các ID mục tiêu (0, 1, 2...)
                    for t = 1:length(doa_g2.Groups)
                        target_grp = doa_g2.Groups(t);
                        [~, t_name] = fileparts(target_grp.Name);
                        t_id = ['Target_' t_name];
                        
                        target_data = struct();
                        
                        % --- Đọc Position (vecDoas) ---
                        pos_idx = find_idx(target_grp.Groups, [target_grp.Name '/position']);
                        if pos_idx > 0
                            target_data.position = read_datasets(filename, target_grp.Groups(pos_idx));
                        end
                        
                        % --- Đọc Velocity (velocDoas) ---
                        vel_idx = find_idx(target_grp.Groups, [target_grp.Name '/velocity']);
                        if vel_idx > 0
                            target_data.velocity = read_datasets(filename, target_grp.Groups(vel_idx));
                        end
                        
                        % --- Đọc Identity (Features -> meanBws...) ---
                        id_idx = find_idx(target_grp.Groups, [target_grp.Name '/identity']);
                        if id_idx > 0
                            id_grp = target_grp.Groups(id_idx);
                            % Vào tiếp features
                            feat_idx = find_idx(id_grp.Groups, [id_grp.Name '/features']);
                            if feat_idx > 0
                                target_data.identity_features = read_datasets(filename, id_grp.Groups(feat_idx));
                            end
                        end
                        
                        doa_struct.(t_id) = target_data;
                    end
                end
            end
            
            data.sessions(k).doa = doa_struct;
            
            if mod(k, 100) == 0, waitbar(k/num_sess, h); end
        end
        close(h);
    else
        data.sessions = [];
    end
    
    fprintf('Hoàn thành.\n');
end

%% --- HÀM PHỤ TRỢ (HELPERS) ---

% 1. Tìm index của group theo tên
function idx = find_idx(groups, name)
    idx = -1;
    if isempty(groups), return; end
    match = strcmp({groups.Name}, name);
    idx = find(match, 1);
    if isempty(idx), idx = -1; end
end

% 2. Đọc Attributes (Dành cho Configuration)
function s = read_attrs(group_info)
    s = struct();
    if isempty(group_info.Attributes), return; end
    for i = 1:length(group_info.Attributes)
        attr = group_info.Attributes(i);
        s.(matlab.lang.makeValidName(attr.Name)) = attr.Value;
    end
end

% 3. Đọc Datasets (Dành cho Calibration, Session, DOA)
function s = read_datasets(filename, group_info)
    s = struct();
    if isempty(group_info.Datasets), return; end
    for i = 1:length(group_info.Datasets)
        ds = group_info.Datasets(i);
        path = [group_info.Name '/' ds.Name];
        try
            val = h5read(filename, path);
            % Chuyển thành vector cột
            if isnumeric(val) && isrow(val) && length(val) > 1
                val = val';
            end
            s.(matlab.lang.makeValidName(ds.Name)) = val;
        catch
        end
    end
end

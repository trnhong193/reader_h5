function data = read_identifier(filename)
% READ_MAVIC_FLAT Đọc file H5 theo cách tuần tự (Không dùng đệ quy)
%   Cách tiếp cận: "Chỉ đâu đọc đó". Dễ hiểu, dễ sửa.

    if ~isfile(filename)
        error('File không tồn tại: %s', filename);
    end

    % 1. Lấy thông tin cấu trúc file
    fprintf('Đang đọc thông tin file... ');
    info = h5info(filename);
    fprintf('Xong.\n');
    
    data = struct();

    %% --- PHẦN 1: ĐỌC METADATA (/attribute) ---
    fprintf('1. Đang đọc Metadata (/attribute)...\n');
    
    % Tìm group /attribute trong info
    attr_idx = find_group_by_name(info.Groups, '/attribute');
    
    if attr_idx > 0
        attr_group = info.Groups(attr_idx);
        
        % A. ĐỌC /attribute/estm_bdw (Tham số Hop)
        % Thay vì đệ quy, ta tìm group con tên là 'estm_bdw'
        bdw_idx = find_group_by_name(attr_group.Groups, '/attribute/estm_bdw');
        if bdw_idx > 0
            data.estm_bdw = read_all_datasets_in_group(filename, attr_group.Groups(bdw_idx));
        end
        
        % B. ĐỌC /attribute/request (Label)
        req_idx = find_group_by_name(attr_group.Groups, '/attribute/request');
        if req_idx > 0
            req_grp = attr_group.Groups(req_idx);
            % Tìm dataset 'label' bên trong
            try
                raw_lbl = h5read(filename, [req_grp.Name, '/label']);
                data.request.label = parse_label_text(raw_lbl);
            catch
                % Không có label
            end
        end
        
        % C. ĐỌC /attribute/doa (Deep nesting - Đọc thủ công các nhánh quan trọng)
        doa_idx = find_group_by_name(attr_group.Groups, '/attribute/doa');
        if doa_idx > 0
            doa_grp = attr_group.Groups(doa_idx);
            
            % -- Đọc Position (vecDoas) --
            pos_idx = find_group_by_name(doa_grp.Groups, [doa_grp.Name, '/position']);
            if pos_idx > 0
                data.doa.position = read_all_datasets_in_group(filename, doa_grp.Groups(pos_idx));
            end
            
            % -- Đọc Identity (Features) --
            id_idx = find_group_by_name(doa_grp.Groups, [doa_grp.Name, '/identity']);
            if id_idx > 0
                % Trong identity có features
                feat_idx = find_group_by_name(doa_grp.Groups(id_idx).Groups, [doa_grp.Name, '/identity/features']);
                if feat_idx > 0
                    data.doa.identity.features = read_all_datasets_in_group(filename, doa_grp.Groups(id_idx).Groups(feat_idx));
                end
            end
        end
    end

    %% --- PHẦN 2: ĐỌC SESSION (/session) ---
    fprintf('2. Đang đọc Sessions (IQ Data)...\n');
    
    sess_root_idx = find_group_by_name(info.Groups, '/session');
    
    if sess_root_idx > 0
        % Lấy danh sách các folder con (000000...)
        session_folders = info.Groups(sess_root_idx).Groups;
        num_sess = length(session_folders);
        
        fprintf('   Tìm thấy %d sessions.\n', num_sess);
        
        % Dùng struct array cho gọn: data.sessions(1), data.sessions(2)...
        % Thay vì S_0000 dynamic field phức tạp
        data.sessions = repmat(struct('id', '', 'iq', []), num_sess, 1);
        
        h = waitbar(0, 'Đang đọc IQ từng session...');
        
        for k = 1:num_sess
            this_sess = session_folders(k);
            
            % 1. Lấy ID (Tên folder)
            [~, folder_name] = fileparts(this_sess.Name);
            data.sessions(k).id = folder_name;
            
            % 2. Đọc dataset 'iq'
            iq_path = [this_sess.Name, '/iq'];
            try
                raw_iq = h5read(filename, iq_path);
                data.sessions(k).iq = process_iq_interleaved(raw_iq);
            catch
                data.sessions(k).iq = [];
            end
            
            if mod(k, 100) == 0, waitbar(k/num_sess, h); end
        end
        close(h);
    else
        warning('Không tìm thấy group /session');
        data.sessions = [];
    end
    
    fprintf('Hoàn thành.\n');
end

%% --- CÁC HÀM PHỤ TRỢ (HELPER FUNCTIONS) ---

% 1. Hàm đọc tất cả dataset trong 1 group (Thay thế cho đệ quy phức tạp)
function out = read_all_datasets_in_group(filename, group_info)
    out = struct();
    if isempty(group_info.Datasets), return; end
    
    for i = 1:length(group_info.Datasets)
        ds_name = group_info.Datasets(i).Name;
        full_path = [group_info.Name, '/', ds_name];
        
        try
            val = h5read(filename, full_path);
            % Chuyển vector hàng -> cột
            if isnumeric(val) && isrow(val) && length(val) > 1
                val = val';
            end
            out.(matlab.lang.makeValidName(ds_name)) = val;
        catch
        end
    end
end

% 2. Hàm tìm index của group theo tên (Thay vì loop thủ công)
function idx = find_group_by_name(group_struct_array, target_name)
    idx = -1;
    if isempty(group_struct_array), return; end
    
    % So sánh chuỗi
    match = strcmp({group_struct_array.Name}, target_name);
    idx = find(match, 1);
    
    if isempty(idx), idx = -1; end
end

% 3. Hàm xử lý IQ Xen kẽ [I, Q, I, Q...] -> Số phức
function iq = process_iq_interleaved(raw)
    if isnumeric(raw) && isreal(raw)
        if isrow(raw), raw = raw'; end
        % Cắt lẻ nếu cần
        if mod(length(raw), 2) ~= 0, raw = raw(1:end-1); end
        
        i_data = double(raw(1:2:end));
        q_data = double(raw(2:2:end));
        iq = complex(i_data, q_data);
    elseif isstruct(raw) && isfield(raw, 'r')
        iq = complex(double(raw.r), double(raw.i));
    else
        iq = raw;
    end
end

% 4. Hàm parse label text
function out = parse_label_text(raw)
    out = struct();
    if ischar(raw), strs = cellstr(raw);
    elseif isstring(raw), strs = cellstr(raw);
    elseif iscell(raw), strs = raw; else, return; end
    
    for k = 1:length(strs)
        txt = strtrim(strs{k});
        if contains(txt, '=')
            parts = split(txt, '=');
            out.(matlab.lang.makeValidName(parts{1})) = strtrim(strjoin(parts(2:end), '='));
        else
            out.(sprintf('line_%d', k)) = txt;
        end
    end
end

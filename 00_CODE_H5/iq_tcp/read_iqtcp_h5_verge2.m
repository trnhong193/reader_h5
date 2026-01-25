function data = read_iqtcp_h5_verge2(filename)
% READ_IQ_TCP_H5_VERGE2 Đọc file H5 chứa dữ liệu IQ (Narrowband TCP)
%
%   Output:
%       data.global_info : Attributes trực tiếp từ /attribute
%       data.ddc_info    : Attributes từ /attribute/ddc
%       data.request_info: Attributes từ /attribute/request
%       data.sessions    : Mảng struct chứa id, i, q, và iq_complex

    if ~isfile(filename)
        error('File không tồn tại: %s', filename);
    end

    fprintf('Đang phân tích cấu trúc file... ');
    info = h5info(filename);
    fprintf('Xong.\n');
    
    data = struct();
    
    %% 1. ĐỌC METADATA (Nested Attributes)
    
    try
        attr_group_idx = find(strcmp({info.Groups.Name}, '/attribute'));
        
        if ~isempty(attr_group_idx)
            mainAttrGroup = info.Groups(attr_group_idx);
            
            % A. Đọc attributes trực tiếp tại /attribute -> data.global_info
            data.global_info = read_attributes(mainAttrGroup);
            
            % B. Đọc các group con (ddc, request, label...) -> data.{name}_info
            subAttrs = mainAttrGroup.Groups;
            for j = 1:length(subAttrs)
                subName = get_name(subAttrs(j).Name);
                
                % Tạo tên field: ddc -> ddc_info, request -> request_info
                % Kiểm tra nếu đã kết thúc bằng '_info' thì giữ nguyên
                if length(subName) > 5 && strcmp(subName(end-4:end), '_info')
                    fieldName = subName;  % Đã có _info rồi
                else
                    fieldName = [subName, '_info'];
                end
                
                % Đọc attributes của group con
                data.(fieldName) = read_attributes(subAttrs(j));
                
                % C. Kiểm tra nếu có Dataset bên trong (ví dụ: /attribute/request/label)
                if ~isempty(subAttrs(j).Datasets)
                    for d = 1:length(subAttrs(j).Datasets)
                        dsName = subAttrs(j).Datasets(d).Name;
                        dsPath = [subAttrs(j).Name, '/', dsName];
                        try
                            val = h5read(filename, dsPath);
                            % Nếu là string, convert cho đẹp
                            if isa(val, 'char') || isa(val, 'string')
                                val = strtrim(string(val));
                            end
                            data.(fieldName).(dsName) = val;
                        catch
                        end
                    end
                end
            end
        end
    catch ME
        warning('Lỗi đọc metadata: %s', ME.message);
    end

    %% 2. ĐỌC DỮ LIỆU IQ SESSION
    sess_idx = find(strcmp({info.Groups.Name}, '/session'));
    if isempty(sess_idx)
        data.sessions = [];
        return;
    end

    subgroups = info.Groups(sess_idx).Groups;
    num_sessions = length(subgroups);
    fprintf('Tìm thấy %d sessions. Đang đọc dữ liệu I/Q...\n', num_sessions);
    
    % Pre-allocate
    emptyStruct = struct('id', '', 'i', [], 'q', [], 'iq', []);
    data.sessions = repmat(emptyStruct, num_sessions, 1);
    
    h = waitbar(0, 'Đang đọc I/Q data...');
    
    for k = 1:num_sessions
        this_group = subgroups(k);
        [~, folder_name] = fileparts(this_group.Name);
        data.sessions(k).id = folder_name;
        
        % Đọc dataset 'i'
        path_i = [this_group.Name, '/i'];
        try
            raw_i = h5read(filename, path_i);
            if isrow(raw_i), raw_i = raw_i'; end
            data.sessions(k).i = raw_i;
        catch
            data.sessions(k).i = [];
        end
        
        % Đọc dataset 'q'
        path_q = [this_group.Name, '/q'];
        try
            raw_q = h5read(filename, path_q);
            if isrow(raw_q), raw_q = raw_q'; end
            data.sessions(k).q = raw_q;
        catch
            data.sessions(k).q = [];
        end
        
        % Tạo dữ liệu phức (Complex) để tiện xử lý: I + jQ
        if ~isempty(data.sessions(k).i) && ~isempty(data.sessions(k).q)
            % Convert sang double để tính toán chính xác
            data.sessions(k).iq = double(data.sessions(k).i) + 1j * double(data.sessions(k).q);
        end
        
        if mod(k, 100) == 0, waitbar(k/num_sessions, h); end
    end
    close(h);
    fprintf('Hoàn thành.\n');
end

% --- Hàm phụ trợ: Lấy tên folder cuối ---
function name = get_name(path)
    [~, name] = fileparts(path);
    name = matlab.lang.makeValidName(name);
end

% --- Hàm phụ trợ: Đọc attributes của 1 group ---
function s = read_attributes(group_info)
    s = struct();
    attrs = group_info.Attributes;
    for i = 1:length(attrs)
        name = matlab.lang.makeValidName(attrs(i).Name);
        s.(name) = attrs(i).Value;
    end
end


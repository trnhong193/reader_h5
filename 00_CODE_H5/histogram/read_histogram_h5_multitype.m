function data = read_histogram_h5_multitype(filename)
% READ_HISTOGRAM_H5_MULTITYPE Đọc file H5 với cấu trúc động dựa trên message_type
%   Hỗ trợ:
%     1. AccumulatedPower       -> đọc 'sample_decoded'
%     2. CrossingThresholdPower -> đọc 'acc_sample_decoded' VÀ 'crx_sample_decoded'

    if ~isfile(filename)
        error('File không tồn tại: %s', filename);
    end

    fprintf('Đang phân tích cấu trúc file... ');
    info = h5info(filename);
    fprintf('Xong.\n');
    
    data = struct();
    
    %% 1. GLOBAL INFO
    try
        attr_idx = find(strcmp({info.Groups.Name}, '/attribute'));
        if ~isempty(attr_idx)
            raw_attrs = info.Groups(attr_idx).Attributes;
            for i = 1:length(raw_attrs)
                name = matlab.lang.makeValidName(raw_attrs(i).Name);
                data.global_info.(name) = raw_attrs(i).Value;
            end
        else
            data.global_info = [];
        end
    catch
        data.global_info = [];
    end

    %% 2. SESSION DATA
    sess_idx = find(strcmp({info.Groups.Name}, '/session'));
    if isempty(sess_idx)
        data.sessions = [];
        return;
    end

    subgroups = info.Groups(sess_idx).Groups;
    num_sessions = length(subgroups);
    fprintf('Tìm thấy %d sessions. Đang đọc dữ liệu...\n', num_sessions);
    
    % Tạo struct rỗng bao gồm tất cả các trường có thể có
    emptyStruct = struct('id', '', ...
                         'type', '', ...           % Loại bản tin (Accumulated hay Crossing)
                         'attributes', [], ...
                         'context_info', [], ...
                         'source_info', [], ...
                         'sample_decoded', [], ...      % Cho AccumulatedPower
                         'acc_sample_decoded', [], ...  % Cho CrossingThresholdPower
                         'crx_sample_decoded', []);     % Cho CrossingThresholdPower
                         
    data.sessions = repmat(emptyStruct, num_sessions, 1);
    
    h = waitbar(0, 'Đang xử lý...');
    
    for k = 1:num_sessions
        this_group = subgroups(k);
        [~, folder_name] = fileparts(this_group.Name);
        data.sessions(k).id = folder_name;
        
        % --- A. Đọc Attributes (để lấy message_type) ---
        s_attrs = struct();
        raw_sess_attrs = this_group.Attributes;
        msg_type_str = ''; % Mặc định
        
        for i = 1:length(raw_sess_attrs)
            a_name = matlab.lang.makeValidName(raw_sess_attrs(i).Name);
            s_attrs.(a_name) = raw_sess_attrs(i).Value;
            
            % Lưu riêng message_type để xử lý logic
            if strcmp(a_name, 'message_type')
                msg_type_str = char(raw_sess_attrs(i).Value);
            end
        end
        data.sessions(k).attributes = s_attrs;
        data.sessions(k).type = msg_type_str;
        
        % --- B. Xử lý Logic Đọc Dữ Liệu dựa trên Message Type ---
        % Lưu ý: Dùng contains để check chuỗi vì tên có thể dài (ví dụ: '...AccumulatedPower')
        
        try
            if contains(msg_type_str, 'CrossingThresholdPower')
                % --- TRƯỜNG HỢP 1: Crossing Threshold ---
                % Đọc acc_sample_decoded
                path_acc = [this_group.Name, '/acc_sample_decoded'];
                raw_acc = h5read(filename, path_acc);
                if isrow(raw_acc), raw_acc = raw_acc'; end
                data.sessions(k).acc_sample_decoded = raw_acc;
                
                % Đọc crx_sample_decoded
                path_crx = [this_group.Name, '/crx_sample_decoded'];
                raw_crx = h5read(filename, path_crx);
                if isrow(raw_crx), raw_crx = raw_crx'; end
                data.sessions(k).crx_sample_decoded = raw_crx;
                
            else 
                % --- TRƯỜNG HỢP 2: AccumulatedPower (Hoặc mặc định) ---
                % Đọc sample_decoded
                path_samp = [this_group.Name, '/sample_decoded'];
                
                % Kiểm tra file có dataset này không trước khi đọc để tránh lỗi
                try
                    raw_samp = h5read(filename, path_samp);
                    if isrow(raw_samp), raw_samp = raw_samp'; end
                    data.sessions(k).sample_decoded = raw_samp;
                catch
                    % Nếu không thấy sample_decoded, thử tìm acc_sample_decoded (fallback)
                    try
                         path_fallback = [this_group.Name, '/acc_sample_decoded'];
                         raw_fb = h5read(filename, path_fallback);
                         if isrow(raw_fb), raw_fb = raw_fb'; end
                         data.sessions(k).sample_decoded = raw_fb;
                    catch
                        data.sessions(k).sample_decoded = [];
                    end
                end
            end
        catch ME
            % Ghi nhận lỗi nhưng không dừng chương trình
        end
        
        % --- C. Đọc Context & Source (Giữ nguyên) ---
        % (Context)
        ctx_idx = find(contains({this_group.Groups.Name}, '/context'));
        if ~isempty(ctx_idx)
            raw_ctx = this_group.Groups(ctx_idx).Attributes;
            c_info = struct();
            for i=1:length(raw_ctx), c_info.(matlab.lang.makeValidName(raw_ctx(i).Name)) = raw_ctx(i).Value; end
            data.sessions(k).context_info = c_info;
        end
        
        % (Source)
        src_idx = find(contains({this_group.Groups.Name}, '/source'));
        if ~isempty(src_idx)
            raw_src = this_group.Groups(src_idx).Attributes;
            s_info = struct();
            for i=1:length(raw_src), s_info.(matlab.lang.makeValidName(raw_src(i).Name)) = raw_src(i).Value; end
            data.sessions(k).source_info = s_info;
        end
        
        if mod(k, 100) == 0, waitbar(k/num_sessions, h); end
    end
    close(h);
    fprintf('Hoàn thành đọc %d sessions.\n', num_sessions);
% READ_HISTOGRAM_H5_MULTITYPE Đọc file H5 với cấu trúc động dựa trên message_type
%   Hỗ trợ:
%     1. AccumulatedPower       -> đọc 'sample_decoded'
%     2. CrossingThresholdPower -> đọc 'acc_sample_decoded' VÀ 'crx_sample_decoded'

    if ~isfile(filename)
        error('File không tồn tại: %s', filename);
    end

    fprintf('Đang phân tích cấu trúc file... ');
    info = h5info(filename);
    fprintf('Xong.\n');
    
    data = struct();
    
    %% 1. GLOBAL INFO
    try
        attr_idx = find(strcmp({info.Groups.Name}, '/attribute'));
        if ~isempty(attr_idx)
            raw_attrs = info.Groups(attr_idx).Attributes;
            for i = 1:length(raw_attrs)
                name = matlab.lang.makeValidName(raw_attrs(i).Name);
                data.global_info.(name) = raw_attrs(i).Value;
            end
        else
            data.global_info = [];
        end
    catch
        data.global_info = [];
    end

    %% 2. SESSION DATA
    sess_idx = find(strcmp({info.Groups.Name}, '/session'));
    if isempty(sess_idx)
        data.sessions = [];
        return;
    end

    subgroups = info.Groups(sess_idx).Groups;
    num_sessions = length(subgroups);
    fprintf('Tìm thấy %d sessions. Đang đọc dữ liệu...\n', num_sessions);
    
    % Tạo struct rỗng bao gồm tất cả các trường có thể có
    emptyStruct = struct('id', '', ...
                         'type', '', ...           % Loại bản tin (Accumulated hay Crossing)
                         'attributes', [], ...
                         'context_info', [], ...
                         'source_info', [], ...
                         'sample_decoded', [], ...      % Cho AccumulatedPower
                         'acc_sample_decoded', [], ...  % Cho CrossingThresholdPower
                         'crx_sample_decoded', []);     % Cho CrossingThresholdPower
                         
    data.sessions = repmat(emptyStruct, num_sessions, 1);
    
    h = waitbar(0, 'Đang xử lý...');
    
    for k = 1:num_sessions
        this_group = subgroups(k);
        [~, folder_name] = fileparts(this_group.Name);
        data.sessions(k).id = folder_name;
        
        % --- A. Đọc Attributes (để lấy message_type) ---
        s_attrs = struct();
        raw_sess_attrs = this_group.Attributes;
        msg_type_str = ''; % Mặc định
        
        for i = 1:length(raw_sess_attrs)
            a_name = matlab.lang.makeValidName(raw_sess_attrs(i).Name);
            s_attrs.(a_name) = raw_sess_attrs(i).Value;
            
            % Lưu riêng message_type để xử lý logic
            if strcmp(a_name, 'message_type')
                msg_type_str = char(raw_sess_attrs(i).Value);
            end
        end
        data.sessions(k).attributes = s_attrs;
        data.sessions(k).type = msg_type_str;
        
        % --- B. Xử lý Logic Đọc Dữ Liệu dựa trên Message Type ---
        % Lưu ý: Dùng contains để check chuỗi vì tên có thể dài (ví dụ: '...AccumulatedPower')
        
        try
            if contains(msg_type_str, 'CrossingThresholdPower')
                % --- TRƯỜNG HỢP 1: Crossing Threshold ---
                % Đọc acc_sample_decoded
                path_acc = [this_group.Name, '/acc_sample_decoded'];
                raw_acc = h5read(filename, path_acc);
                if isrow(raw_acc), raw_acc = raw_acc'; end
                data.sessions(k).acc_sample_decoded = raw_acc;
                
                % Đọc crx_sample_decoded
                path_crx = [this_group.Name, '/crx_sample_decoded'];
                raw_crx = h5read(filename, path_crx);
                if isrow(raw_crx), raw_crx = raw_crx'; end
                data.sessions(k).crx_sample_decoded = raw_crx;
                
            else 
                % --- TRƯỜNG HỢP 2: AccumulatedPower (Hoặc mặc định) ---
                % Đọc sample_decoded
                path_samp = [this_group.Name, '/sample_decoded'];
                
                % Kiểm tra file có dataset này không trước khi đọc để tránh lỗi
                try
                    raw_samp = h5read(filename, path_samp);
                    if isrow(raw_samp), raw_samp = raw_samp'; end
                    data.sessions(k).sample_decoded = raw_samp;
                catch
                    % Nếu không thấy sample_decoded, thử tìm acc_sample_decoded (fallback)
                    try
                         path_fallback = [this_group.Name, '/acc_sample_decoded'];
                         raw_fb = h5read(filename, path_fallback);
                         if isrow(raw_fb), raw_fb = raw_fb'; end
                         data.sessions(k).sample_decoded = raw_fb;
                    catch
                        data.sessions(k).sample_decoded = [];
                    end
                end
            end
        catch ME
            % Ghi nhận lỗi nhưng không dừng chương trình
        end
        
        % --- C. Đọc Context & Source (Giữ nguyên) ---
        % (Context)
        ctx_idx = find(contains({this_group.Groups.Name}, '/context'));
        if ~isempty(ctx_idx)
            raw_ctx = this_group.Groups(ctx_idx).Attributes;
            c_info = struct();
            for i=1:length(raw_ctx), c_info.(matlab.lang.makeValidName(raw_ctx(i).Name)) = raw_ctx(i).Value; end
            data.sessions(k).context_info = c_info;
        end
        
        % (Source)
        src_idx = find(contains({this_group.Groups.Name}, '/source'));
        if ~isempty(src_idx)
            raw_src = this_group.Groups(src_idx).Attributes;
            s_info = struct();
            for i=1:length(raw_src), s_info.(matlab.lang.makeValidName(raw_src(i).Name)) = raw_src(i).Value; end
            data.sessions(k).source_info = s_info;
        end
        
        if mod(k, 100) == 0, waitbar(k/num_sessions, h); end
    end
    close(h);
    fprintf('Hoàn thành đọc %d sessions.\n', num_sessions);
end

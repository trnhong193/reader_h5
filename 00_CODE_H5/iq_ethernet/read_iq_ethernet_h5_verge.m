function data = read_iq_ethernet_h5_verge(filename)
% READ_H5_IQETHERNET Đọc và giải mã gói tin Ethernet IQ từ file H5
%   Input: filename (.h5)
%   Output: data struct chứa:
%       data.global_info: Thông tin chung
%       data.streams: Struct chứa dữ liệu đã phân loại theo Stream ID
%           data.streams.ID_x.packets: Mảng các gói tin thuộc stream x
%           data.streams.ID_x.all_iq: (Tùy chọn) Nối toàn bộ IQ của stream

    if ~isfile(filename)
        error('File không tồn tại: %s', filename);
    end

    fprintf('Đang phân tích cấu trúc file... ');
    info = h5info(filename);
    fprintf('Xong.\n');
    
    data = struct();
    
    %% 1. ĐỌC GLOBAL METADATA
    % (Phần này giữ nguyên như các code trước để lấy thông tin chung)
    data.global_info = struct();
    try
        attr_idx = find(strcmp({info.Groups.Name}, '/attribute'));
        if ~isempty(attr_idx)
            mainAttr = info.Groups(attr_idx);
            % Đọc attributes gốc
            for i = 1:length(mainAttr.Attributes)
                data.global_info.(matlab.lang.makeValidName(mainAttr.Attributes(i).Name)) = mainAttr.Attributes(i).Value;
            end
            % Đọc subgroups (ddc, request...)
            for i = 1:length(mainAttr.Groups)
                subName = get_name(mainAttr.Groups(i).Name);
                attrs = mainAttr.Groups(i).Attributes;
                s_sub = struct();
                for j = 1:length(attrs)
                     s_sub.(matlab.lang.makeValidName(attrs(j).Name)) = attrs(j).Value;
                end
                data.global_info.(subName) = s_sub;
            end
        end
    catch
        warning('Lỗi đọc Global Metadata');
    end

    %% 2. ĐỌC VÀ PARSE DỮ LIỆU RAW THEO STREAM_ID
    sess_idx = find(strcmp({info.Groups.Name}, '/session'));
    if isempty(sess_idx)
        data.streams = [];
        return;
    end

    subgroups = info.Groups(sess_idx).Groups;
    num_sessions = length(subgroups);
    fprintf('Tìm thấy %d sessions (packets). Đang giải mã...\n', num_sessions);
    
    % Khởi tạo struct để chứa các Stream
    % Cấu trúc: streams.ID_101 = [packet1, packet2...]
    stream_map = containers.Map('KeyType', 'double', 'ValueType', 'any');
    
    h = waitbar(0, 'Đang giải mã Ethernet Packets...');
    
    for k = 1:num_sessions
        this_group = subgroups(k);
        
        % 1. Đọc Raw Data (uint8 array)
        path_raw = [this_group.Name, '/raw'];
        try
            raw_bytes = h5read(filename, path_raw);
        catch
            continue; % Bỏ qua nếu lỗi
        end
        
        % 2. Đọc Context (Timestamp của H5 log)
        h5_timestamp = 0;
        try
            path_ctx = [this_group.Name, '/context'];
            % Lấy attribute timestamp trong context (nếu có)
            % Đoạn này cần check kỹ cách lưu attribute
            % (Giả sử logic cũ)
        catch
        end
        
        % 3. GIẢI MÃ GÓI TIN (THEO ẢNH STRUCT C++)
        % Header size = 40 bytes (Tính tổng các trường uint32/64 trước sample)
        if length(raw_bytes) < 40
            warning('Packet %d quá ngắn (%d bytes)', k, length(raw_bytes));
            continue;
        end
        
        packet = parse_ethernet_packet(raw_bytes);
        packet.h5_session_idx = k; % Lưu lại index session để truy vết
        
        % 4. GOM NHÓM THEO STREAM_ID
        sid = double(packet.stream_id);
        
        if isKey(stream_map, sid)
            % Nếu stream đã tồn tại, nối thêm packet vào danh sách
            current_list = stream_map(sid);
            current_list{end+1} = packet;
            stream_map(sid) = current_list;
        else
            % Nếu stream chưa tồn tại, tạo mới
            stream_map(sid) = {packet};
        end
        
        if mod(k, 100) == 0, waitbar(k/num_sessions, h); end
    end
    close(h);
    
    %% 3. CHUYỂN ĐỔI MAP SANG STRUCT DỄ DÙNG
    % Output sẽ là data.streams.Stream_0, data.streams.Stream_1...
    all_keys = keys(stream_map);
    data.streams = struct();
    
    fprintf('Tổng hợp dữ liệu theo Stream ID...\n');
    for i = 1:length(all_keys)
        sid = all_keys{i};
        field_name = sprintf('Stream_%d', sid);
        
        % Lấy danh sách packet cell array
        pkt_cell = stream_map(sid);
        
        % Chuyển từ cell array sang struct array
        pkt_struct = [pkt_cell{:}];
        
        % Lưu vào output
        data.streams.(field_name).packets = pkt_struct;
        
        % Tùy chọn: Nối toàn bộ IQ data lại thành 1 chuỗi dài để vẽ
        try
            data.streams.(field_name).all_iq = vertcat(pkt_struct.iq_data);
        catch
            data.streams.(field_name).all_iq = [];
        end
        
        fprintf(' -> %s: %d packets\n', field_name, length(pkt_struct));
    end
end

%% HÀM GIẢI MÃ RAW BYTES (QUAN TRỌNG NHẤT)
function pkt = parse_ethernet_packet(bytes)
    % bytes: Mảng uint8 (cột)
    
    % Cấu trúc Struct (Little Endian mặc định của x86/ARM)
    % 1. uint32 header       (bytes 1-4)
    % 2. uint32 stream_id    (bytes 5-8)
    % 3. uint64 timestamp    (bytes 9-16)
    % 4. uint64 frequency    (bytes 17-24)
    % 5. uint32 length       (bytes 25-28)
    % 6. uint32 bandwidth    (bytes 29-32)
    % 7. uint32 switch_id    (bytes 33-36)
    % 8. uint32 sample_count (bytes 37-40) -> reserved_0
    % 9. Data                (bytes 41-end)
    
    pkt = struct();
    
    % Sử dụng typecast để chuyển đổi mảng byte sang số
    % Lưu ý: typecast yêu cầu input đúng số lượng byte
    
    pkt.header      = typecast(bytes(1:4),   'uint32');
    pkt.stream_id   = typecast(bytes(5:8),   'uint32');
    pkt.timestamp   = typecast(bytes(9:16),  'uint64');
    pkt.frequency   = typecast(bytes(17:24), 'uint64');
    pkt.len         = typecast(bytes(25:28), 'uint32'); % Tên length trùng keyword matlab nên đặt là len
    pkt.bandwidth   = typecast(bytes(29:32), 'uint32');
    pkt.switch_id   = typecast(bytes(33:36), 'uint32');
    pkt.sample_cnt  = typecast(bytes(37:40), 'uint32');
    
    % --- GIẢI MÃ SAMPLES (IQ) ---
    raw_payload = bytes(41:end);
    
    % Giả sử định dạng chuẩn là Int16 cho I và Q (2 byte mỗi mẫu)
    % Tổng cộng 4 bytes cho 1 cặp IQ
    
    % Kiểm tra xem số lượng byte còn lại có khớp với sample_count không
    % 1 sample (I+Q) thường là 4 bytes (Int16) hoặc 2 bytes (Int8)
    bytes_per_sample = 4;
    if bytes_per_sample == 4
        % Trường hợp Int16 (2 byte I, 2 byte Q) - Phổ biến nhất cho Ethernet Packet
        iq_int16 = typecast(raw_payload, 'int16');
        
        % Dữ liệu thường xen kẽ: I, Q, I, Q...
        i_val = double(iq_int16(1:2:end));
        q_val = double(iq_int16(2:2:end));
        
        pkt.iq_data = complex(i_val, q_val);
        
    %elseif bytes_per_sample == 2
        % Trường hợp Int8 (1 byte I, 1 byte Q)
        %iq_int8 = typecast(raw_payload, 'int8');
        %i_val = double(iq_int8(1:2:end));
        %q_val = double(iq_int8(2:2:end));
        
        %pkt.iq_data = complex(i_val, q_val);
    else
        % Trường hợp lạ, giữ nguyên raw hoặc thử ép kiểu Int16 mặc định
        % warning('Số byte không khớp sample count. Bytes: %d, Count: %d', length(raw_payload), pkt.sample_cnt);
        pkt.iq_data = []; 
    end
end

% Hàm lấy tên folder
function name = get_name(path)
    [~, name] = fileparts(path);
end
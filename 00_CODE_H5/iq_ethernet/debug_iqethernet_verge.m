%% 1. KHỞI TẠO VÀ ĐỌC FILE
clc; clear; close all;

% Tên file H5 của bạn (Narrowband Ethernet - I/Q samples)
filename = '/home/vht/Documents/PRJ/01_data_h5/ethernet_200_0/2026_01_13/20260113_145928_narrowband_eth.10.h5'; 

fprintf('>>> Đang đọc dữ liệu từ file: %s ...\n', filename);
fprintf('>>> (Sử dụng read_h5_iqethernet - cấu trúc với streams theo Stream ID)\n\n');

% Gọi hàm read_h5_iqethernet (Đảm bảo file hàm nằm cùng thư mục)
try
    allData = read_iq_ethernet_h5_verge(filename);
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
    fields = fieldnames(g_info);
    for i = 1:length(fields)
        field_name = fields{i};
        field_value = g_info.(field_name);
        
        % Xử lý các kiểu khác nhau (struct con, string, number...)
        if isstruct(field_value)
            fprintf('  • data.global_info.%s: [struct]\n', field_name);
            sub_fields = fieldnames(field_value);
            for j = 1:length(sub_fields)
                sub_name = sub_fields{j};
                sub_val = field_value.(sub_name);
                if ischar(sub_val) || isstring(sub_val)
                    val_str = char(sub_val);
                    if length(val_str) > 40
                        val_str = [val_str(1:37) '...'];
                    end
                    fprintf('      - %s.%s = "%s"\n', field_name, sub_name, val_str);
                elseif isnumeric(sub_val) && numel(sub_val) == 1
                    fprintf('      - %s.%s = %g\n', field_name, sub_name, sub_val);
                end
            end
        elseif ischar(field_value) || isstring(field_value)
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
    if isfield(g_info, 'mission')
        fprintf('  mission = data.global_info.mission;\n');
    end
else
    fprintf('⚠ Không có global_info trong file này.\n');
end
fprintf('\n');

%% 3. CÁCH LẤY DỮ LIỆU STREAMS THEO STREAM_ID
fprintf('\n==================================================\n');
fprintf(' [2] TRUY XUẤT DỮ LIỆU STREAMS THEO STREAM_ID\n');
fprintf('==================================================\n');
fprintf('Cú pháp: data.streams.Stream_X\n\n');

if isfield(allData, 'streams') && ~isempty(allData.streams)
    stream_fields = fieldnames(allData.streams);
    num_streams = length(stream_fields);
    
    fprintf('Tổng số streams: %d\n\n', num_streams);
    
    % Hiển thị thông tin các stream
    for i = 1:min(3, num_streams) % Chỉ hiển thị 3 stream đầu tiên
        stream_name = stream_fields{i};
        stream_data = allData.streams.(stream_name);
        
        fprintf('--- %s ---\n', stream_name);
        fprintf('   Cú pháp: data.streams.%s\n', stream_name);
        
        % Lấy thông tin packets
        if isfield(stream_data, 'packets')
            packets = stream_data.packets;
            num_packets = length(packets);
            fprintf('   • Số packets: %d\n', num_packets);
            
            % Hiển thị thông tin packet đầu tiên
            if num_packets > 0
                pkt = packets(1);
                fprintf('   • Packet đầu tiên:\n');
                if isfield(pkt, 'stream_id')
                    fprintf('     - stream_id = %u\n', pkt.stream_id);
                end
                if isfield(pkt, 'frequency')
                    fprintf('     - frequency = %u Hz (%.2f MHz)\n', ...
                        pkt.frequency, double(pkt.frequency)/1e6);
                end
                if isfield(pkt, 'bandwidth')
                    fprintf('     - bandwidth = %u Hz (%.2f MHz)\n', ...
                        pkt.bandwidth, double(pkt.bandwidth)/1e6);
                end
                if isfield(pkt, 'sample_cnt')
                    fprintf('     - sample_cnt = %u\n', pkt.sample_cnt);
                end
                if isfield(pkt, 'iq_data') && ~isempty(pkt.iq_data)
                    fprintf('     - iq_data: %d mẫu phức\n', length(pkt.iq_data));
                end
            end
        end
        
        % Lấy all_iq nếu có
        if isfield(stream_data, 'all_iq')
            all_iq = stream_data.all_iq;
            if ~isempty(all_iq)
                fprintf('   • all_iq: %d mẫu phức (nối tất cả packets)\n', length(all_iq));
            else
                fprintf('   • all_iq: [] (rỗng)\n');
            end
        end
        
        fprintf('\n');
    end
    
    if num_streams > 3
        fprintf('   ... (còn %d stream khác)\n\n', num_streams - 3);
    end
else
    fprintf('⚠ Không có streams trong file này.\n');
end
fprintf('\n');

%% 4. CHI TIẾT PACKET ĐẦU TIÊN
fprintf('\n==================================================\n');
fprintf(' [3] CHI TIẾT PACKET ĐẦU TIÊN\n');
fprintf('==================================================\n');

if isfield(allData, 'streams') && ~isempty(allData.streams)
    stream_fields = fieldnames(allData.streams);
    if ~isempty(stream_fields)
        stream_name = stream_fields{1};
        stream_data = allData.streams.(stream_name);
        
        if isfield(stream_data, 'packets') && ~isempty(stream_data.packets)
            pkt = stream_data.packets(1);
            
            fprintf('Stream: %s, Packet đầu tiên\n\n', stream_name);
            
            % Hiển thị tất cả fields của packet
            fprintf('--- Header Fields ---\n');
            pkt_fields = fieldnames(pkt);
            for i = 1:length(pkt_fields)
                field_name = pkt_fields{i};
                field_value = pkt.(field_name);
                
                if strcmp(field_name, 'iq_data')
                    % Xử lý riêng cho iq_data
                    if ~isempty(field_value)
                        fprintf('  • %s: %d mẫu phức\n', field_name, length(field_value));
                        fprintf('    5 giá trị đầu:\n');
                        num_display = min(5, length(field_value));
                        for m = 1:num_display
                            fprintf('      [%d] %g + %gj\n', m, ...
                                real(field_value(m)), imag(field_value(m)));
                        end
                        
                        % Thống kê
                        iq_mag = abs(field_value);
                        fprintf('    Thống kê:\n');
                        fprintf('      - Biên độ: Min=%.2f, Max=%.2f, Mean=%.2f\n', ...
                            min(iq_mag), max(iq_mag), mean(iq_mag));
                    else
                        fprintf('  • %s: [] (rỗng)\n', field_name);
                    end
                elseif isnumeric(field_value) && numel(field_value) == 1
                    if strcmp(field_name, 'frequency') || strcmp(field_name, 'bandwidth')
                        fprintf('  • %s = %u Hz (%.2f MHz)\n', field_name, ...
                            field_value, double(field_value)/1e6);
                    else
                        fprintf('  • %s = %u\n', field_name, field_value);
                    end
                elseif ischar(field_value) || isstring(field_value)
                    fprintf('  • %s = "%s"\n', field_name, char(field_value));
                else
                    fprintf('  • %s = [%s, size=%s]\n', field_name, ...
                        class(field_value), mat2str(size(field_value)));
                end
            end
            
            fprintf('\nCú pháp truy cập:\n');
            fprintf('  stream = data.streams.%s;\n', stream_name);
            fprintf('  packet = stream.packets(1);\n');
            fprintf('  stream_id = packet.stream_id;\n');
            fprintf('  frequency = packet.frequency;\n');
            fprintf('  iq_data = packet.iq_data;\n');
        else
            fprintf('⚠ Không có packets trong stream đầu tiên.\n');
        end
    else
        fprintf('⚠ Không có stream nào.\n');
    end
else
    fprintf('⚠ Không có streams.\n');
end
fprintf('\n');

%% 5. VẼ BIỂU ĐỒ (VISUALIZATION)
if isfield(allData, 'streams') && ~isempty(allData.streams)
    stream_fields = fieldnames(allData.streams);
    if ~isempty(stream_fields)
        stream_name = stream_fields{1};
        stream_data = allData.streams.(stream_name);
        
        % Tìm packet có dữ liệu IQ
        target_pkt = [];
        if isfield(stream_data, 'packets') && ~isempty(stream_data.packets)
            for i = 1:length(stream_data.packets)
                pkt = stream_data.packets(i);
                if isfield(pkt, 'iq_data') && ~isempty(pkt.iq_data)
                    target_pkt = pkt;
                    break;
                end
            end
        end
        
        % Hoặc sử dụng all_iq
        if isempty(target_pkt) && isfield(stream_data, 'all_iq') && ~isempty(stream_data.all_iq)
            % Tạo packet giả từ all_iq
            target_pkt = struct();
            target_pkt.iq_data = stream_data.all_iq;
            target_pkt.stream_id = 0;
            if isfield(stream_data, 'packets') && ~isempty(stream_data.packets)
                if isfield(stream_data.packets(1), 'stream_id')
                    target_pkt.stream_id = stream_data.packets(1).stream_id;
                end
                if isfield(stream_data.packets(1), 'frequency')
                    target_pkt.frequency = stream_data.packets(1).frequency;
                end
            end
        end
        
        if ~isempty(target_pkt) && isfield(target_pkt, 'iq_data') && ~isempty(target_pkt.iq_data)
            fprintf('\n==================================================\n');
            fprintf(' [4] VẼ BIỂU ĐỒ I/Q DATA\n');
            fprintf('==================================================\n');
            
            iq_data = target_pkt.iq_data;
            i_data = real(iq_data);
            q_data = imag(iq_data);
            
            figure('Name', sprintf('IQ Data - %s', stream_name), 'Color', 'w');
            
            % Subplot 1: I & Q theo thời gian
            subplot(2,2,1);
            plot(i_data, 'b-', 'LineWidth', 0.5); hold on;
            plot(q_data, 'r-', 'LineWidth', 0.5);
            title(sprintf('Time Domain - I & Q (%s)', stream_name), 'Interpreter', 'none');
            xlabel('Sample Index');
            ylabel('Amplitude');
            legend('I (In-phase)', 'Q (Quadrature)', 'Location', 'best');
            grid on;
            
            % Subplot 2: Constellation Diagram
            subplot(2,2,2);
            plot(i_data, q_data, '.', 'MarkerSize', 2);
            title('Constellation Diagram (I vs Q)');
            xlabel('I (In-phase)');
            ylabel('Q (Quadrature)');
            axis equal;
            grid on;
            
            % Subplot 3: Biên độ của tín hiệu phức
            subplot(2,2,3);
            iq_magnitude = abs(iq_data);
            plot(iq_magnitude, 'g-', 'LineWidth', 0.5);
            title('Magnitude |I + jQ|');
            xlabel('Sample Index');
            ylabel('|IQ|');
            grid on;
            
            % Subplot 4: Phase của tín hiệu phức
            subplot(2,2,4);
            iq_phase = angle(iq_data);
            plot(iq_phase, 'm-', 'LineWidth', 0.5);
            title('Phase (angle)');
            xlabel('Sample Index');
            ylabel('Phase (rad)');
            grid on;
            
            % Tạo title chung
            title_str = sprintf('IQ Data Analysis - %s', stream_name);
            if isfield(target_pkt, 'frequency')
                freq_mhz = double(target_pkt.frequency) / 1e6;
                title_str = sprintf('%s, Freq: %.2f MHz', title_str, freq_mhz);
            end
            if isfield(target_pkt, 'stream_id')
                title_str = sprintf('%s, Stream ID: %u', title_str, target_pkt.stream_id);
            end
            sgtitle(title_str, 'FontSize', 12, 'FontWeight', 'bold');
            
            fprintf('→ Đã vẽ 4 biểu đồ I/Q data.\n');
        else
            fprintf('⚠ Không có dữ liệu IQ để vẽ biểu đồ.\n');
        end
    end
end
fprintf('\n');

%% 6. VÍ DỤ: DUYỆT QUA TẤT CẢ STREAMS VÀ PACKETS
fprintf('\n==================================================\n');
fprintf(' [5] VÍ DỤ: DUYỆT QUA TẤT CẢ STREAMS VÀ PACKETS\n');
fprintf('==================================================\n');
fprintf('Code mẫu:\n\n');
fprintf('stream_fields = fieldnames(data.streams);\n');
fprintf('for i = 1:length(stream_fields)\n');
fprintf('    stream_name = stream_fields{i};\n');
fprintf('    stream_data = data.streams.(stream_name);\n');
fprintf('    \n');
fprintf('    %% Lấy packets\n');
fprintf('    packets = stream_data.packets;\n');
fprintf('    num_packets = length(packets);\n');
fprintf('    \n');
fprintf('    %% Lấy all_iq (nếu có)\n');
fprintf('    if isfield(stream_data, ''all_iq'')\n');
fprintf('        all_iq = stream_data.all_iq;\n');
fprintf('    end\n');
fprintf('    \n');
fprintf('    %% Duyệt qua từng packet\n');
fprintf('    for j = 1:num_packets\n');
fprintf('        packet = packets(j);\n');
fprintf('        stream_id = packet.stream_id;\n');
fprintf('        frequency = packet.frequency;\n');
fprintf('        iq_data = packet.iq_data;\n');
fprintf('        \n');
fprintf('        %% Xử lý dữ liệu...\n');
fprintf('        magnitude = abs(iq_data);\n');
fprintf('        phase = angle(iq_data);\n');
fprintf('    end\n');
fprintf('end\n\n');

%% 7. BẢNG TÓM TẮT CẤU TRÚC OUTPUT
fprintf('\n==================================================\n');
fprintf(' [6] BẢNG TÓM TẮT CẤU TRÚC OUTPUT\n');
fprintf('==================================================\n');
fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
fprintf('│ TRƯỜNG                              │ MÔ TẢ                        │\n');
fprintf('├─────────────────────────────────────────────────────────────────────┤\n');
fprintf('│ data.global_info                    │ Attributes từ /attribute     │\n');
fprintf('│   .client_ip                        │ IP client                    │\n');
fprintf('│   .mission                          │ Nhiệm vụ                     │\n');
fprintf('│   .ddc                              │ DDC info (struct)            │\n');
fprintf('│   .request                          │ Request info (struct)        │\n');
fprintf('│   ...                               │                              │\n');
fprintf('├─────────────────────────────────────────────────────────────────────┤\n');
fprintf('│ data.streams.Stream_X               │ Stream có ID = X             │\n');
fprintf('│   .packets                          │ Mảng các packets (struct)    │\n');
fprintf('│     (i).stream_id                   │ Stream ID (uint32)           │\n');
fprintf('│     (i).timestamp                   │ Timestamp (uint64)           │\n');
fprintf('│     (i).frequency                   │ Frequency (uint64)           │\n');
fprintf('│     (i).len                         │ Length (uint32)              │\n');
fprintf('│     (i).bandwidth                   │ Bandwidth (uint32)           │\n');
fprintf('│     (i).switch_id                   │ Switch ID (uint32)           │\n');
fprintf('│     (i).sample_cnt                  │ Số lượng samples (uint32)    │\n');
fprintf('│     (i).iq_data                     │ Dữ liệu phức IQ              │\n');
fprintf('│   .all_iq                           │ Tất cả IQ nối lại (optional) │\n');
fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
fprintf('\n');

fprintf('=== HOÀN THÀNH HƯỚNG DẪN ===\n');


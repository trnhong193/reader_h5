% Script để kiểm tra cấu trúc file H5 thực tế bằng cách chạy các reader
% Tạo báo cáo chi tiết về output structure

clc; clear; close all;

% Thêm đường dẫn code vào path
addpath(genpath('/home/tth193/Documents/h5_code/00_CODE_H5'));

base_path = '/home/tth193/Documents/h5_code/00_DATA_h5/';

% Danh sách các file cần kiểm tra
files_to_check = {
    'df.h5', 'read_df', 'df';
    'identifier.h5', 'read_identifier', 'identifier';
    'demodulation.h5', 'reader_demodulation_no_recursive', 'demodulation';
    'spectrum.h5', 'read_spectrum_data', 'spectrum';
    'histogram.h5', 'read_histogram_h5_multitype', 'histogram';
    'iqethernet.h5', 'read_iq_ethernet_h5_verge', 'iq_ethernet';
    'iqtcp.h5', 'read_iqtcp_h5_verge2', 'iq_tcp';
};

% File để lưu kết quả
output_file = '/home/tth193/Documents/h5_code/STRUCTURE_CHECK_RESULT.txt';
fid = fopen(output_file, 'w');
if fid == -1
    error('Không thể tạo file output');
end

fprintf('=== KIỂM TRA CẤU TRÚC FILE H5 THỰC TẾ ===\n\n');
fprintf(fid, '=== KIỂM TRA CẤU TRÚC FILE H5 THỰC TẾ ===\n\n');

for i = 1:size(files_to_check, 1)
    filename = fullfile(base_path, files_to_check{i,1});
    reader_func = files_to_check{i,2};
    reader_name = files_to_check{i,3};
    
    if ~isfile(filename)
        fprintf('SKIP: %s (không tồn tại)\n\n', filename);
        fprintf(fid, 'SKIP: %s (không tồn tại)\n\n', filename);
        continue;
    end
    
    fprintf('========================================\n');
    fprintf('File: %s\n', files_to_check{i,1});
    fprintf('Reader: %s\n', reader_func);
    fprintf('========================================\n');
    
    fprintf(fid, '========================================\n');
    fprintf(fid, 'File: %s\n', files_to_check{i,1});
    fprintf(fid, 'Reader: %s\n', reader_func);
    fprintf(fid, '========================================\n');
    
    try
        % Gọi hàm reader tương ứng
        switch reader_func
            case 'read_df'
                data = read_df(filename);
            case 'read_identifier'
                data = read_identifier(filename);
            case 'reader_demodulation_no_recursive'
                data = reader_demodulation_no_recursive(filename);
            case 'read_spectrum_data'
                data = read_spectrum_data(filename);
            case 'read_histogram_h5_multitype'
                data = read_histogram_h5_multitype(filename);
            case 'read_iq_ethernet_h5_verge'
                data = read_iq_ethernet_h5_verge(filename);
            case 'read_iqtcp_h5_verge2'
                data = read_iqtcp_h5_verge2(filename);
        end
        
        % In cấu trúc output chi tiết
        fprintf('\nCẤU TRÚC OUTPUT:\n');
        fprintf(fid, '\nCẤU TRÚC OUTPUT:\n');
        print_struct_detailed(data, '', 0, 3, fid);
        
        % In thông tin về sessions nếu có
        if isfield(data, 'sessions') && ~isempty(data.sessions)
            fprintf('\n--- THÔNG TIN SESSIONS ---\n');
            fprintf(fid, '\n--- THÔNG TIN SESSIONS ---\n');
            fprintf('Số lượng sessions: %d\n', length(data.sessions));
            fprintf(fid, 'Số lượng sessions: %d\n', length(data.sessions));
            
            if length(data.sessions) > 0
                fprintf('\nSession đầu tiên:\n');
                fprintf(fid, '\nSession đầu tiên:\n');
                sess1 = data.sessions(1);
                print_struct_detailed(sess1, 'sessions(1)', 0, 2, fid);
            end
        end
        
        % In thông tin về streams nếu có (IQ Ethernet)
        if isfield(data, 'streams') && ~isempty(data.streams)
            fprintf('\n--- THÔNG TIN STREAMS ---\n');
            fprintf(fid, '\n--- THÔNG TIN STREAMS ---\n');
            stream_fields = fieldnames(data.streams);
            fprintf('Số lượng streams: %d\n', length(stream_fields));
            fprintf(fid, 'Số lượng streams: %d\n', length(stream_fields));
            
            if length(stream_fields) > 0
                fprintf('\nStream đầu tiên (%s):\n', stream_fields{1});
                fprintf(fid, '\nStream đầu tiên (%s):\n', stream_fields{1});
                stream1 = data.streams.(stream_fields{1});
                print_struct_detailed(stream1, ['streams.' stream_fields{1}], 0, 2, fid);
            end
        end
        
    catch ME
        fprintf('LỖI: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for k = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
        end
        fprintf(fid, 'LỖI: %s\n', ME.message);
        fprintf(fid, 'Stack trace:\n');
        for k = 1:length(ME.stack)
            fprintf(fid, '  %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
        end
    end
    
    fprintf('\n\n');
    fprintf(fid, '\n\n');
end

fclose(fid);
fprintf('Kết quả đã được lưu vào: %s\n', output_file);

function print_struct_detailed(s, prefix, depth, max_depth, fid)
    if depth > max_depth
        return;
    end
    
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:length(fields)
            field_name = fields{i};
            field_value = s.(field_name);
            
            indent = repmat('  ', 1, depth);
            full_path = [prefix '.' field_name];
            if isempty(prefix)
                full_path = field_name;
            end
            
            fprintf('%s%s', indent, full_path);
            fprintf(fid, '%s%s', indent, full_path);
            
            if isstruct(field_value)
                if isscalar(field_value)
                    fprintf(' [struct]\n');
                    fprintf(fid, ' [struct]\n');
                    print_struct_detailed(field_value, full_path, depth+1, max_depth, fid);
                else
                    fprintf(' [struct array, size=%s]\n', mat2str(size(field_value)));
                    fprintf(fid, ' [struct array, size=%s]\n', mat2str(size(field_value)));
                    if length(field_value) > 0
                        fprintf('%s  → First element fields:\n', indent);
                        fprintf(fid, '%s  → First element fields:\n', indent);
                        first_fields = fieldnames(field_value(1));
                        for j = 1:min(10, length(first_fields))
                            fprintf('%s    - %s\n', indent, first_fields{j});
                            fprintf(fid, '%s    - %s\n', indent, first_fields{j});
                        end
                        if length(first_fields) > 10
                            fprintf('%s    ... (còn %d fields)\n', indent, length(first_fields)-10);
                            fprintf(fid, '%s    ... (còn %d fields)\n', indent, length(first_fields)-10);
                        end
                    end
                end
            elseif isnumeric(field_value) || islogical(field_value)
                if isscalar(field_value)
                    fprintf(' = %g [%s]\n', field_value, class(field_value));
                    fprintf(fid, ' = %g [%s]\n', field_value, class(field_value));
                else
                    fprintf(' [%s, size=%s]\n', class(field_value), mat2str(size(field_value)));
                    fprintf(fid, ' [%s, size=%s]\n', class(field_value), mat2str(size(field_value)));
                    if numel(field_value) <= 10 && numel(field_value) > 0
                        fprintf('%s    Values: %s\n', indent, mat2str(field_value(:)'));
                        fprintf(fid, '%s    Values: %s\n', indent, mat2str(field_value(:)'));
                    elseif numel(field_value) > 10
                        fprintf('%s    First 5: %s\n', indent, mat2str(field_value(1:min(5, numel(field_value)))));
                        fprintf(fid, '%s    First 5: %s\n', indent, mat2str(field_value(1:min(5, numel(field_value)))));
                    end
                end
            elseif ischar(field_value) || isstring(field_value)
                str_val = char(field_value);
                if length(str_val) > 80
                    str_val = [str_val(1:77) '...'];
                end
                fprintf(' = "%s" [%s]\n', str_val, class(field_value));
                fprintf(fid, ' = "%s" [%s]\n', str_val, class(field_value));
            elseif iscell(field_value)
                fprintf(' [cell, size=%s]\n', mat2str(size(field_value)));
                fprintf(fid, ' [cell, size=%s]\n', mat2str(size(field_value)));
            else
                fprintf(' [%s]\n', class(field_value));
                fprintf(fid, ' [%s]\n', class(field_value));
            end
        end
    end
end




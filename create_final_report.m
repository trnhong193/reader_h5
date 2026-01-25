% Script để tạo báo cáo cuối cùng dựa trên kiểm tra thực tế
% Chạy script này sau khi đã chạy run_structure_check.m

clc; clear; close all;

% Thêm đường dẫn code
addpath(genpath('/home/tth193/Documents/h5_code/00_CODE_H5'));

base_path = '/home/tth193/Documents/h5_code/00_DATA_h5/';
report_file = '/home/tth193/Documents/h5_code/BAO_CAO_FINAL_KIEM_TRA.txt';

fid = fopen(report_file, 'w');
if fid == -1
    error('Không thể tạo file báo cáo');
end

fprintf('Đang tạo báo cáo...\n');
fprintf(fid, 'BÁO CÁO KIỂM TRA CẤU TRÚC FILE H5 THỰC TẾ\n');
fprintf(fid, 'Ngày: %s\n\n', datestr(now));

files_config = {
    'df.h5', 'read_df', 'DF Reader';
    'identifier.h5', 'read_identifier', 'Identifier Reader';
    'demodulation.h5', 'reader_demodulation_no_recursive', 'Demodulation Reader';
    'spectrum.h5', 'read_spectrum_data', 'Spectrum Reader';
    'histogram.h5', 'read_histogram_h5_multitype', 'Histogram Reader';
    'iqethernet.h5', 'read_iq_ethernet_h5_verge', 'IQ Ethernet Reader';
    'iqtcp.h5', 'read_iqtcp_h5_verge2', 'IQ TCP Reader';
};

for i = 1:size(files_config, 1)
    filename = fullfile(base_path, files_config{i,1});
    reader_func = files_config{i,2};
    reader_name = files_config{i,3};
    
    fprintf('\nĐang xử lý: %s\n', files_config{i,1});
    fprintf(fid, '\n%s\n', repmat('=', 80, 1));
    fprintf(fid, '%s\n', reader_name);
    fprintf(fid, 'File: %s\n', files_config{i,1});
    fprintf(fid, 'Reader function: %s\n', reader_func);
    fprintf(fid, '%s\n\n', repmat('=', 80, 1));
    
    if ~isfile(filename)
        fprintf(fid, 'SKIP: File không tồn tại\n\n');
        continue;
    end
    
    try
        % Gọi reader
        eval(sprintf('data = %s(''%s'');', reader_func, filename));
        
        % In cấu trúc output
        fprintf(fid, 'CẤU TRÚC OUTPUT:\n\n');
        print_structure_to_file(data, '', 0, 3, fid);
        
        % Thống kê
        fprintf(fid, '\n--- THỐNG KÊ ---\n');
        if isfield(data, 'sessions')
            fprintf(fid, 'Số sessions: %d\n', length(data.sessions));
            if length(data.sessions) > 0
                sess1 = data.sessions(1);
                fprintf(fid, 'Fields trong session đầu tiên: %s\n', ...
                    strjoin(fieldnames(sess1), ', '));
            end
        end
        if isfield(data, 'streams')
            stream_fields = fieldnames(data.streams);
            fprintf(fid, 'Số streams: %d\n', length(stream_fields));
            if length(stream_fields) > 0
                fprintf(fid, 'Stream IDs: %s\n', strjoin(stream_fields, ', '));
            end
        end
        
    catch ME
        fprintf(fid, 'LỖI: %s\n', ME.message);
        fprintf(fid, 'File: %s, Line: %d\n', ME.stack(1).file, ME.stack(1).line);
    end
    
    fprintf(fid, '\n\n');
end

fclose(fid);
fprintf('\nBáo cáo đã được lưu vào: %s\n', report_file);

function print_structure_to_file(s, prefix, depth, max_depth, fid)
    if depth > max_depth, return; end
    
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:length(fields)
            fn = fields{i};
            fv = s.(fn);
            indent = repmat('  ', 1, depth);
            full_name = [prefix '.' fn];
            if isempty(prefix), full_name = fn; end
            
            fprintf(fid, '%s%s', indent, full_name);
            
            if isstruct(fv)
                if isscalar(fv)
                    fprintf(fid, ' [struct]\n');
                    print_structure_to_file(fv, full_name, depth+1, max_depth, fid);
                else
                    fprintf(fid, ' [struct array, %d elements]\n', length(fv));
                    if length(fv) > 0 && depth < max_depth
                        fprintf(fid, '%s  Fields: %s\n', indent, ...
                            strjoin(fieldnames(fv(1)), ', '));
                        % In thông tin element đầu tiên
                        fprintf(fid, '%s  First element:\n', indent);
                        print_structure_to_file(fv(1), [full_name '(1)'], depth+1, max_depth, fid);
                    end
                end
            elseif isnumeric(fv) || islogical(fv)
                if isscalar(fv)
                    fprintf(fid, ' = %g [%s]\n', fv, class(fv));
                else
                    fprintf(fid, ' [%s, size=%s]\n', class(fv), mat2str(size(fv)));
                    if numel(fv) <= 5 && numel(fv) > 0
                        fprintf(fid, '%s    Values: %s\n', indent, mat2str(fv(:)'));
                    end
                end
            elseif ischar(fv) || isstring(fv)
                str = char(fv);
                if length(str) > 100, str = [str(1:97) '...']; end
                fprintf(fid, ' = "%s" [%s]\n', str, class(fv));
            else
                fprintf(fid, ' [%s]\n', class(fv));
            end
        end
    end
end




% Script để kiểm tra cấu trúc file H5 thực tế
% Chạy script này để xem cấu trúc output của các reader

clc; clear; close all;

base_path = '/home/tth193/Documents/h5_code/00_DATA_h5/';

% Danh sách các file cần kiểm tra
files_to_check = {
    'df.h5', 'read_df';
    'identifier.h5', 'read_identifier';
    'demodulation.h5', 'reader_demodulation_no_recursive';
    'spectrum.h5', 'read_spectrum_data';
    'histogram.h5', 'read_histogram_h5_multitype';
    'iqethernet.h5', 'read_iq_ethernet_h5_verge';
    'iqtcp.h5', 'read_iqtcp_h5_verge2';
};

fprintf('=== KIỂM TRA CẤU TRÚC FILE H5 ===\n\n');

for i = 1:size(files_to_check, 1)
    filename = fullfile(base_path, files_to_check{i,1});
    reader_func = files_to_check{i,2};
    
    if ~isfile(filename)
        fprintf('SKIP: %s (không tồn tại)\n\n', filename);
        continue;
    end
    
    fprintf('========================================\n');
    fprintf('File: %s\n', files_to_check{i,1});
    fprintf('Reader: %s\n', reader_func);
    fprintf('========================================\n');
    
    try
        % Thêm đường dẫn code vào path
        addpath('/home/tth193/Documents/h5_code/00_CODE_H5');
        
        % Gọi hàm reader tương ứng
        switch reader_func
            case 'read_df'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/df');
                data = read_df(filename);
            case 'read_identifier'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/identifier');
                data = read_identifier(filename);
            case 'reader_demodulation_no_recursive'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/demodulation');
                data = reader_demodulation_no_recursive(filename);
            case 'read_spectrum_data'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/spectrum');
                data = read_spectrum_data(filename);
            case 'read_histogram_h5_multitype'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/histogram');
                data = read_histogram_h5_multitype(filename);
            case 'read_iq_ethernet_h5_verge'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/iq_ethernet');
                data = read_iq_ethernet_h5_verge(filename);
            case 'read_iqtcp_h5_verge2'
                addpath('/home/tth193/Documents/h5_code/00_CODE_H5/iq_tcp');
                data = read_iqtcp_h5_verge2(filename);
        end
        
        % In cấu trúc output
        fprintf('\nCẤU TRÚC OUTPUT:\n');
        print_struct(data, '', 0, 2);
        
    catch ME
        fprintf('LỖI: %s\n', ME.message);
    end
    
    fprintf('\n\n');
end

function print_struct(s, prefix, depth, max_depth)
    if depth > max_depth
        return;
    end
    
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:length(fields)
            field_name = fields{i};
            field_value = s.(field_name);
            
            indent = repmat('  ', 1, depth);
            fprintf('%s%s.%s', prefix, indent, field_name);
            
            if isstruct(field_value)
                if isscalar(field_value)
                    fprintf(' [struct]\n');
                    print_struct(field_value, [prefix field_name '.'], depth+1, max_depth);
                else
                    fprintf(' [struct array, size=%s]\n', mat2str(size(field_value)));
                    if length(field_value) > 0
                        fprintf('%s  → First element fields:\n', indent);
                        first_fields = fieldnames(field_value(1));
                        for j = 1:min(5, length(first_fields))
                            fprintf('%s    - %s\n', indent, first_fields{j});
                        end
                    end
                end
            elseif isnumeric(field_value) || islogical(field_value)
                if isscalar(field_value)
                    fprintf(' = %g\n', field_value);
                else
                    fprintf(' [%s, size=%s]\n', class(field_value), mat2str(size(field_value)));
                end
            elseif ischar(field_value) || isstring(field_value)
                str_val = char(field_value);
                if length(str_val) > 50
                    str_val = [str_val(1:47) '...'];
                end
                fprintf(' = "%s"\n', str_val);
            elseif iscell(field_value)
                fprintf(' [cell, size=%s]\n', mat2str(size(field_value)));
            else
                fprintf(' [%s]\n', class(field_value));
            end
        end
    end
end




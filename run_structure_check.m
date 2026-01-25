% Script đơn giản để kiểm tra cấu trúc file H5 bằng các reader
% Chạy script này trong MATLAB: run_structure_check

clc; clear; close all;

% Thêm đường dẫn code
addpath(genpath('/home/tth193/Documents/h5_code/00_CODE_H5'));

base_path = '/home/tth193/Documents/h5_code/00_DATA_h5/';

% Danh sách file và reader
files_config = {
    'df.h5', 'read_df';
    'identifier.h5', 'read_identifier';
    'demodulation.h5', 'reader_demodulation_no_recursive';
    'spectrum.h5', 'read_spectrum_data';
    'histogram.h5', 'read_histogram_h5_multitype';
    'iqethernet.h5', 'read_iq_ethernet_h5_verge';
    'iqtcp.h5', 'read_iqtcp_h5_verge2';
};

fprintf('=== KIỂM TRA CẤU TRÚC FILE H5 ===\n\n');

results = struct();

for i = 1:size(files_config, 1)
    filename = fullfile(base_path, files_config{i,1});
    reader_func = files_config{i,2};
    
    if ~isfile(filename)
        fprintf('SKIP: %s\n', files_config{i,1});
        continue;
    end
    
    fprintf('\n========================================\n');
    fprintf('File: %s\n', files_config{i,1});
    fprintf('Reader: %s\n', reader_func);
    fprintf('========================================\n');
    
    try
        % Gọi reader
        eval(sprintf('data = %s(''%s'');', reader_func, filename));
        
        % Lưu kết quả
        results.(matlab.lang.makeValidName(files_config{i,1})) = data;
        
        % In cấu trúc
        fprintf('\nCẤU TRÚC OUTPUT:\n');
        print_structure(data, '', 0, 2);
        
    catch ME
        fprintf('LỖI: %s\n', ME.message);
    end
end

fprintf('\n=== HOÀN THÀNH ===\n');
fprintf('Kết quả đã được lưu trong biến ''results''\n');
fprintf('Bạn có thể kiểm tra chi tiết bằng cách:\n');
fprintf('  results.dfh5  (cho df.h5)\n');
fprintf('  results.identifierh5  (cho identifier.h5)\n');
fprintf('  ...\n');

function print_structure(s, prefix, depth, max_depth)
    if depth > max_depth, return; end
    
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:length(fields)
            fn = fields{i};
            fv = s.(fn);
            indent = repmat('  ', 1, depth);
            full_name = [prefix '.' fn];
            if isempty(prefix), full_name = fn; end
            
            fprintf('%s%s', indent, full_name);
            
            if isstruct(fv)
                if isscalar(fv)
                    fprintf(' [struct]\n');
                    print_structure(fv, full_name, depth+1, max_depth);
                else
                    fprintf(' [struct array, %d elements]\n', length(fv));
                    if length(fv) > 0
                        fprintf('%s  Fields: %s\n', indent, strjoin(fieldnames(fv(1)), ', '));
                    end
                end
            elseif isnumeric(fv) || islogical(fv)
                if isscalar(fv)
                    fprintf(' = %g [%s]\n', fv, class(fv));
                else
                    fprintf(' [%s, size=%s]\n', class(fv), mat2str(size(fv)));
                end
            elseif ischar(fv) || isstring(fv)
                str = char(fv);
                if length(str) > 50, str = [str(1:47) '...']; end
                fprintf(' = "%s"\n', str);
            else
                fprintf(' [%s]\n', class(fv));
            end
        end
    end
end




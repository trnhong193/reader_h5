function data = reader_demodulation_no_recursive(filename)
% READER_DEMODULATION_H5 Reads Demodulation H5 files (Non-recursive)
%   Structure:
%       /attribute/request/... (Metadata)
%       /session/000.../i      (In-phase data)
%       /session/000.../q      (Quadrature data)
%
%   Output:
%       data.request : Configuration info
%       data.sessions: Struct array containing ID and complex IQ data

    if ~isfile(filename)
        error('File not found: %s', filename);
    end

    fprintf('Reading file info: %s ... ', filename);
    info = h5info(filename);
    fprintf('Done.\n');
    
    data = struct();
    
    %% --- PART 1: READ METADATA (/attribute) ---
    fprintf('1. Reading Configuration (/attribute)...\n');
    
    % Find the '/attribute' group index
    attr_idx = find_group_idx(info.Groups, '/attribute');
    
    if attr_idx > 0
        attr_group = info.Groups(attr_idx);
        
        % Specifically look for '/attribute/request'
        req_idx = find_group_idx(attr_group.Groups, '/attribute/request');
        
        if req_idx > 0
            req_group = attr_group.Groups(req_idx);
            data.request = struct();
            
            % Loop through subgroups of request (hwConfiguration, source, etc.)
            % In the image, these appear as folders (Groups)
            for i = 1:length(req_group.Groups)
                sub_g = req_group.Groups(i);
                [~, name] = fileparts(sub_g.Name);
                safe_name = matlab.lang.makeValidName(name);
                
                % Read HDF5 Attributes attached to this group
                data.request.(safe_name) = read_attributes_of_group(sub_g);
            end
            
            % Also check if 'request' itself has datasets (like 'label')
            % (Optional based on previous file types)
        end
    end

    %% --- PART 2: READ SESSION DATA (/session) ---
    fprintf('2. Reading Session Data (IQ)...\n');
    
    % Find the '/session' group index
    sess_root_idx = find_group_idx(info.Groups, '/session');
    
    if sess_root_idx > 0
        % Get all session folders (000000...)
        session_folders = info.Groups(sess_root_idx).Groups;
        num_sess = length(session_folders);
        
        fprintf('   Found %d sessions.\n', num_sess);
        
        % Pre-allocate struct array for speed
        % Fields: id, iq
        data.sessions = repmat(struct('id', '', 'iq', []), num_sess, 1);
        
        h = waitbar(0, 'Reading I/Q Data...');
        
        for k = 1:num_sess
            curr_sess = session_folders(k);
            
            % 1. Get Session ID
            [~, folder_name] = fileparts(curr_sess.Name);
            data.sessions(k).id = folder_name;
            
            % 2. Read 'i' and 'q' datasets explicitly
            path_i = [curr_sess.Name, '/i'];
            path_q = [curr_sess.Name, '/q'];
            
            try
                % Read raw 32-bit integers
                raw_i = h5read(filename, path_i);
                raw_q = h5read(filename, path_q);
                
                % Convert to double for processing
                val_i = double(raw_i);
                val_q = double(raw_q);
                
                % Ensure column vectors
                if isrow(val_i), val_i = val_i'; end
                if isrow(val_q), val_q = val_q'; end
                
                % Combine into Complex Double
                % Handle length mismatch just in case
                len = min(length(val_i), length(val_q));
                data.sessions(k).iq = complex(val_i(1:len), val_q(1:len));
                
            catch
                % If 'i' or 'q' is missing
                data.sessions(k).iq = [];
            end
            
            if mod(k, 100) == 0, waitbar(k/num_sess, h); end
        end
        close(h);
    else
        warning('No /session group found.');
        data.sessions = [];
    end
    
    fprintf('Read complete.\n');
end

%% --- HELPER FUNCTIONS ---

% 1. Find group index by exact name
function idx = find_group_idx(group_list, name_to_find)
    idx = -1;
    if isempty(group_list), return; end
    
    % Compare names
    match = strcmp({group_list.Name}, name_to_find);
    idx = find(match, 1);
    if isempty(idx), idx = -1; end
end

% 2. Read all HDF5 Attributes attached to a group
function attrs = read_attributes_of_group(group_info)
    attrs = struct();
    if isempty(group_info.Attributes), return; end
    
    for k = 1:length(group_info.Attributes)
        att = group_info.Attributes(k);
        clean_name = matlab.lang.makeValidName(att.Name);
        attrs.(clean_name) = att.Value;
    end
end

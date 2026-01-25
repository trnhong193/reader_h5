function data = read_spectrum_data(filename)
%   READ H5 SPECTRUM
%   read_spectrum_data(filename) return a struct
%   - global_info: /attribute group
%   - sessions: struct array contains data in each sub-session

%   Input: filename - path to h5 file
%   Output:
%       data.global_info.(field) - Thong tin chung (client, ip, mission, ... )
%       data.sessions(i).id - Ten session (000xx)
%       data.sessions(i).attributes - Thong tin chung tung session (timestamp, freq, bw...)
%       data.sessions(i).source_info.(field) -  Thong tin thiet bi
%       data.sessions(i).samples (Vector data sample_decoded)

%   Check file's exist
if ~isfile(filename)
    error('File dont exist: %s', filename);
end

% get struct file
info = h5info(filename);
%   Init output
data = struct();

%% 1. Read global info /attribute
try
    attr_idx = find(strcmp({info.Groups.Name}, '/attribute'));
    if ~isempty(attr_idx)
        raw_attrs = info.Groups(attr_idx).Attributes;

        for i = 1:length(raw_attrs)
            name = raw_attrs(i).Name;
            value = raw_attrs(i).Value;
            valid_name = matlab.lang.makeValidName(name);
            data.global_info.(valid_name) = value;
        end
    else
    
        warning("Not found any attributes in /attribute");
        data.global_info = [];
    end 
catch 
    warning("Can not run group /attribute. Check path");
    data.global_info = [];
end 

%% 2. Read Session and Source
try
    session_idx = find(strcmp({info.Groups.Name}, '/session'));
    if isempty(session_idx)
        warning("Dont find /session ");
        data.sessions = [];
        return;
    end
    subgroups = info.Groups(session_idx).Groups;
    num_sessions = length(subgroups);
    fprintf("Find %d sessions", num_sessions);

    % pre-allocate the struct array
    data.sessions = struct('id', {}, 'attributes', {},'source_info', {}, 'samples', {});

    % waitbar follow process
    %h = waitbar(0, 'Reading sessions ..');

    for k = 1:num_sessions
        this_group = subgroups(k);
        % --- 1. Get ID ---
        [~, folder_name] = fileparts(this_group.Name);
        data.sessions(k).id = folder_name;

        % --- 2. Get attributes
        s_attrs = struct();
        raw_sess_attrs = this_group.Attributes;
        for i = 1:length(raw_sess_attrs)
            a_name = matlab.lang.makeValidName(raw_sess_attrs(i).Name);
            s_attrs.(a_name) = raw_sess_attrs(i).Value;
        end
        data.sessions(k).attributes = s_attrs;

        % ----3. get info Source
        source_idx = find(contains({this_group.Groups.Name}, '/source'));
        if ~isempty(source_idx)
            % get attributes of group source
            raw_src_attrs = this_group.Groups(source_idx).Attributes;
            src_info = struct();
            for i = 1:length(raw_src_attrs)
                s_name = matlab.lang.makeValidName(raw_src_attrs(i).Name);
                src_info.(s_name) = raw_src_attrs(i).Value;
            end
            data.sessions(k).source_info = src_info;
        else
            data.sessions(k).source_info = [];
        end

 
        % ---4. get info sample_decode
        dataset_path = [this_group.Name, '/sample_decoded'];
        try
            raw_data = h5read(filename, dataset_path);
            
            if isrow(raw_data)
                raw_data = raw_data';
            end
            data.sessions(k).samples = raw_data;
            %disp("max value in decoded sample");
            %disp(max(abs(raw_data)));
            %disp(min(abs(raw_data)));


        catch
            warning("Dont read sample_decoded in session %s", folder_name);
            data.sessions(k).samples = [];
        end

        % Update waitbar after each 100 session
        %if mod(k, 100) == 0
            % waitbar(k/num_sessions, h, sprintf('Done: %d/%d', k, num_sessions));
        %end
    end
    %close(h);
catch ME
    error("Error when read /sessions: %s", ME.message);
end
fprintf("Done file! \n");
end

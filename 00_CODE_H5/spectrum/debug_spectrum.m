filename = "/home/vht/Documents/PRJ/01_data_h5/digitizer_200_1/2026_01_07/20260107_123701_spectrum.0.h5"
%h5disp
try 
    allData = read_spectrum_data(filename);
    %data = read_spectrum_data2(filename);
catch ME
    error("Error when read file: %s", filename);
end 

% --- global info ---
g_info = allData.global_info;
%disp(g_info.client_ip);

% --- sessions
num_sessions = length(allData.sessions);
for k = 1:num_sessions
    sess_k = allData.sessions(k);
    attr_sess_k = sess_k.attributes;
    disp(attr_sess_k);
    src_sess_k = sess_k.source_info;
    disp(src_sess_k);
    samples_sess_k = sess_k.samples;
    %disp(samples_sess_k);
    disp(max(abs(samples_sess_k)));



end


%-------------------------------------------------------------------------------

% -- sessions
if (0)
sessions = allData.sessions;
num_sessions = length(sessions);
valid_session = false;
target_idx = -1; 

for k = 1:num_sessions
    samples = sessions(k).samples;
    if ~isempty(samples) && max(abs(samples)) == 0
        valid_session = true;
        target_idx = k;

        fprintf("hahahahhahahahah: %d", k)
        break;
    end
end

sess = sessions(target_idx);
data_vec = sess.samples;
for i = 1:length(data_vec)
    %disp(data_vec(i));
end
disp(size(data_vec,1));
disp(size(data_vec,2));
disp(class(data_vec));
end

%--------------------------------------------------------------------------------
if (0)
for k = 1:numel(data.sessions)
    fprintf('\nSession %s:\n', data.sessions(k).id);
    disp('Attributes:'); disp(data.sessions(k).attributes);
    disp('Source info:'); disp(data.sessions(k).source_info);
    fprintf('Samples: %d points, class=%s\n', ...
        numel(data.sessions(k).samples), class(data.sessions(k).samples));
    % Ví dụ vẽ 1 vài mẫu
    if ~isempty(data.sessions(k).samples)
        figure; plot(real(data.sessions(k).samples(1:100)));
        title(sprintf('Session %s – first 100 real samples', data.sessions(k).id));
    end
end
end 

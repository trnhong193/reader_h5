%% TEST SCRIPT FOR DEMODULATION READER (NON-RECURSIVE)
clc; clear; close all;

% REPLACE with your filename
filename = '/home/vht/Documents/PRJ/01_data_h5/hongtt47/demodulation_fc_121000117_bw_5554_type_am_fs_120000_2025_12_17_12_13_30.h5';
fprintf('>>> Loading File: %s\n', filename);

try
    data = reader_demodulation_no_recursive(filename);
    disp('File read successfully.');
catch ME
    error('Read Error: %s', ME.message);
end

%% 1. CHECK CONFIGURATION (/attribute/request)
fprintf('\n--- CONFIGURATION INFO ---\n');

if isfield(data, 'request')
    req = data.request;
    disp("=============================================")
    disp(req);
    
    % Check Hardware Config
    if isfield(req, 'hwConfiguration')
        disp('Hardware Config:');
        disp(req.hwConfiguration);
    end

    % Check libConfiguration Config
    if isfield(req, 'libConfiguration')
        disp('libConfiguration Config:');
        disp(req.libConfiguration);
    end

    % Check recordingOptions
    if isfield(req, 'recordingOptions')
        disp('recordingOptions Config:');
        disp(req.recordingOptions);
    end

    
    % Check Source
    if isfield(req, 'source')
        disp('Source Info:');
        disp(req.source);
    end
    
    % Check spectrumOptions
    if isfield(req, 'spectrumOptions')
        disp('spectrumOptions Config:');
        disp(req.spectrumOptions);
    end

    % Check transaction
    if isfield(req, 'transaction')
        disp('transaction Config:');
        disp(req.transaction);
    end

else
    disp('No Request configuration found.');
end

%% 2. CHECK SESSION IQ DATA
fprintf('\n--- SESSION DATA ---\n');

if isfield(data, 'sessions') && ~isempty(data.sessions)
    num_sess = length(data.sessions);
    fprintf('Total Sessions: %d\n', num_sess);
    
    % Analyze the first session
    sess1 = data.sessions(1);
    fprintf('Session ID: %s\n', sess1.id);
    
    if ~isempty(sess1.iq)
        iq = sess1.iq;
        disp("----------------------------------------------------------------------------------------");
        %disp(iq);
        %fprintf('IQ Data : %d + j* \n', (iq));
        fprintf('IQ Data Length: %d samples\n', length(iq));
        fprintf('Data Type: %s\n', class(iq));
        
        % PLOT
        figure('Name', ['Demodulation: ' sess1.id], 'Color', 'w');
        
        % Subplot 1: Time Domain
        subplot(2,1,1);
        plot(real(iq), 'b'); hold on;
        plot(imag(iq), 'r');
        title('Time Domain (I & Q)');
        legend('I', 'Q'); grid on;
        
        % Subplot 2: Constellation
        subplot(2,1,2);
        plot(iq, '.');
        title('Constellation Diagram');
        axis equal; grid on;
        
    else
        disp('No IQ data in this session.');
    end
else
    disp('No sessions found.');
end

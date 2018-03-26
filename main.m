%% MULTI-TE IMAGE PROCESSING: ENTRY POINT

% Author(s): Alex Cochran
% Email: Alexander.Cochran@cchmc.org, acochran50@gmail.com
% Group: CCHMC CPIR
% Date: 2018

% This is the entry point for multi-TE image processing. From here, retrospective gating, image
% reconstruction, and parameter mapping can be done. All configuration options should be entered in
% the input.yml file found in the top-level directory.
%
% NOTE: This program has options for manual and automatic definition of input and output
% filenames/locations. Carefully review defaults if you aren't sure if they are compatible with your
% datasets/workflow.
%
% The following directory tree shows how files should be structured for best results. The
% 'automatic' settings in the program setup process will place things this way.
%   * __________ is the top-level path for the use of this script. Note: this program does NOT
%     need to be in the same path. This script (multi-te/main.m) will prompt the user to specify the
%     directories that should be parsed.
%   * __________ content should contain sub-directories for each set of MRI scan datafiles
%     (acqp, traj, method, fid, etc.)
%   * __________ content will be created as needed during the course of the analysis
%
% TOP_PATH
% |--- SCAN_DATA_PATH
% |   |--- SCAN_DATA_1
% |   |--- SCAN_DATA_2
% |   |--- SCAN_DATA_N
% |        |--- acqp
% |        |--- traj
% |        |--- method
% |        |--- fid
% |        |--- ...
% |--- PROCESSED_PATH
% |   |--- SCAN_DATA_1_PROCESSED    NOTE: 'SCAN_DATA_1' here means the same directory name as the
% |   |--- SCAN_DATA_2_PROCESSED    sub-directories the SCAN_DATA_PATH directory above for contin-
% |   |--- SCAN_DATA_N_PROCESSED    uity in the processing workflow. 
% |        |--- GATING
% |        |   |--- gating_file_1
% |        |   |--- gating_file_2
% |        |   |--- ...
% |        |--- RECONSTRUCTION
% |        |   |--- recon_file_1
% |        |   |--- recon_file_2
% |        |   |--- ...
% |        |--- MAPPING
% |        |   |--- map_file_1
% |        |   |--- map_file_2
% |        |   |--- ...
% |        |--- scan_report.log (any additional information on this particular scan)
% |--- readme.txt (or any other additional files relating to the dataset)


%% add paths to 3rd party/self-written utility classes/functions

addpath('./tools/yaml-matlab');
addpath('./tools/uigetmult');
addpath('./control'); % displaybanner.m, invalidselection.m


%% CLI startup output

% display fun program banner
displaybanner;

% notify user that having all data files in the same directories is a good idea
fprintf('\nThis program is designed to perform image processing on multi-TE UTE MRI data.');
fprintf('\nSettings can be changed from the input.yml file in the top-level directory.\n');
fprintf('\nBEST RESULTS: have FID, ACQP, trajectory, and method files in the same folders.\n')


%% ask to clear workspace if already populated

if ~isempty(who)
    clearPrompt = questdlg('Clear workspace?', 'Clear?', 'Yes', 'No', 'No');
    if strcmp(clearPrompt, 'Yes')
        clear;
    end
end


%% capture program start time

timeStart = datetime('now');


%% read YAML input file (input.yml)

% add paths to use and test YAML input
addpath('./tools/yaml-matlab');

while ~exist('configStruct', 'var')
    configFile = './input.yml';
    configStruct = ReadYaml(configFile);
end


%% define any constants/prefixes/suffixes

GATE_SUFFIX = 'gated';
RECON_SUFFIX = 'reconstructed';
MAP_SUFFIX = 'mapped';


%% Select scan data directory

while ~exist('DATA_PATH', 'var') || ~isa(DATA_PATH, 'char')
    DATA_PATH = uigetdir('', 'Choose data directory');
    if invalidselection(DATA_PATH, 'char')
        return;
    end
end


%% select datasets

% select the datasets in DATA_PATH to process
while ~exist('datasetPaths', 'var') || isempty(datasetPaths)
    datasetPaths = uigetmult(DATA_PATH, 'Select dataset folders');
    if invalidselection(datasetPaths, 'cell')
        clear datasetPaths
        return;
    end
end


%% select datafiles

% scan data file path structure preallocation
if ~exist('rawDatafilePaths', 'var')
    rawDatafilePaths = struct( ...
        'ACQP_PATH', cell(1), ...
        'TRAJ_PATH', cell(1), ...
        'METH_PATH', cell(1), ...
        'FID_PATH', cell(1) ...
    );
end

while ~exist('INPUT_MODE', 'var') || isempty(INPUT_MODE)
    INPUT_MODE = questdlg('Select ACQP, METHOD, FID, and TRAJ files automatically or manually?', ...
        'Selection mode', 'Manually', 'Automatically', 'Quit', 'Quit');
    switch INPUT_MODE
        case 'Automatically'
            % define the filenames of ACQP, traj, method, and FID files by assuming their names
            for n = 1:length(datasetPaths)
                rawDatafilePaths(n).ACQP_PATH = fullfile(datasetPaths(n), 'acqp');
                rawDatafilePaths(n).TRAJ_PATH = fullfile(datasetPaths(n), 'traj');
                rawDatafilePaths(n).METH_PATH = fullfile(datasetPaths(n), 'method');
                rawDatafilePaths(n).FID_PATH = fullfile(datasetPaths(n), 'fid');
            end
        case 'Manually'
            % define the filenames of ACQP, traj, method, and FID files manually (via UI)
            for n = 1:length(datasetPaths)
                rawDatafilePaths(n).ACQP_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose ACQP', datasetPaths(n));
                if invalidselection(rawDatafilePaths(n).ACQP_PATH, 'cell')
                    return;
                end

                rawDatafilePaths(n).TRAJ_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose TRAJ', datasetPaths(n));
                if invalidselection(rawDatafilePaths(n).TRAJ_PATH, 'cell')
                    return;
                end

                rawDatafilePaths(n).METH_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose METH', datasetPaths(n));
                if invalidselection(rawDatafilePaths(n).METH_PATH, 'cell')
                    return;
                end

                rawDatafilePaths(n).FID_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose FID', datasetPaths(n));
                if invalidselection(rawDatafilePaths(n).FID_PATH, 'cell')
                    return;
                end
            end
        case 'Quit'
            clear INPUT_MODE;
            return
        otherwise % if the user closes the window
            if invalidselection(DATA_PATH, 'char') % might not be the correct path variable...
                return;
            end
    end
end


%% check for ACQP, traj, method, and FID file existence

for n = 1:length(datasetPaths)
    checkACQP = exist(char(rawDatafilePaths(n).ACQP_PATH), 'file');
    checkTraj = exist(char(rawDatafilePaths(n).TRAJ_PATH), 'file');
    checkMeth = exist(char(rawDatafilePaths(n).METH_PATH), 'file');
    checkFID = exist(char(rawDatafilePaths(n).FID_PATH), 'file');
    
    if ~checkACQP || ~checkTraj || ~checkMeth || ~checkFID
        error('One or more datafiles is not properly specified/does not exist.');
    end
end


%% define output location(s)

% allow the user to define output paths automatically or manually
while ~exist('OUTPUT_MODE', 'var') || isempty(OUTPUT_MODE)
    OUTPUT_MODE = questdlg('Define output location and prefix automatically or manually?', ...
        'Selection mode', 'Manually', 'Automatically', 'Quit', 'Quit');
    switch OUTPUT_MODE
        case 'Automatically'
            TOP_PATH = fileparts(DATA_PATH); % represents one directory above the data path
            outputPrefix = datestr(timeStart, 'yyyy-mm-dd_HH-MM-SS'); % date prefix
        case 'Manually'
            TOP_PATH = uigetdir('', 'Choose output directory'); % top lebel
            outputPrefix = inputdlg('Enter a prefix for output files:');
        case 'Quit'
            return
        otherwise % if the user closes the window
            if invalidselection(DATA_PATH, 'char')
                return;
            end
    end
end

% define top-level output path in the specified location
OUT_PATH = fullfile(TOP_PATH, 'processed_data');

% safely create top-level output directory for this execution
if ~exist(OUT_PATH, 'dir')
    mkdir(OUT_PATH);
end

% preallocate processed data paths
if ~exist('processedFilePaths', 'var')
    processedFilePaths = struct( ...
        'SET_OUT_PATH', cell(1), ...
        'GATE_PATH', cell(1), ...
        'RECON_PATH', cell(1), ...
        'MAP_PATH', cell(1) ...
    );
end

% define output paths for each scan dataset
for n = 1:length(datasetPaths)
    % define the output path specific to scan 'n'
    fullScanPath = strsplit(char(datasetPaths(n)), filesep);
    scanPath = fullScanPath(end);
    processedFilePaths(n).SET_OUT_PATH = fullfile(OUT_PATH, strcat(scanPath, '_processed'));
    
    % create the output path for this scan if it doesn't exist
    if ~exist(char(processedFilePaths(n).SET_OUT_PATH), 'dir')
        mkdir(char(processedFilePaths(n).SET_OUT_PATH))
    end
    
    % define output path names for each type of data
    processedFilePaths(n).GATE_PATH = fullfile(processedFilePaths(n).SET_OUT_PATH, GATE_SUFFIX);
    processedFilePaths(n).RECON_PATH = fullfile(processedFilePaths(n).SET_OUT_PATH, RECON_SUFFIX);
    processedFilePaths(n).MAP_PATH = fullfile(processedFilePaths(n).SET_OUT_PATH, MAP_SUFFIX);
    
    % safely create output directories for each type of data in scan 'n'
    if ~exist(char(processedFilePaths(n).GATE_PATH), 'dir')
        mkdir(char(processedFilePaths(n).GATE_PATH));
    end
    
    if ~exist(char(processedFilePaths(n).RECON_PATH), 'dir')
        mkdir(char(processedFilePaths(n).RECON_PATH));
    end
    
    if ~exist(char(processedFilePaths(n).MAP_PATH), 'dir')
        mkdir(char(processedFilePaths(n).MAP_PATH));
    end
end


%% = = = = = retrospective gating = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

if configStruct.mode.gate
    % record gating start time
    gateStartTime = tic;

    % import from gating package
    import gating.retrogatingleadmag
    
    for n = 1:length(rawDatafilePaths)
        % gating operation
        retrogatingleadmag( ...
            configStruct.settings.num_projections, ...
            configStruct.settings.num_cut_projections, ...
            configStruct.settings.num_points, ...
            configStruct.settings.num_sep, ...
            configStruct.settings.exp_threshold, ...
            configStruct.settings.insp_threshold, ...
            configStruct.settings.echo_times, ...
            char(datasetPaths(n)), ...
            char(rawDatafilePaths(n).FID_PATH), ...
            char(processedFilePaths(n).GATE_PATH), ...
            outputPrefix ...
        );
    end
    
    % record gating time elapsed
    gateTimeElapsed = toc(gateStartTime);
end


%% isolate and specify gated file paths

% Get the full paths for each gated data file and organize them into sets (MATLAB structs) to enable
% reconstruction of gated data. This step should not execute if the user does not specify gated
% reconstruction in the input file.

if configStruct.mode.gated_reconstruction
    % gated data file path structure preallocation
    if ~exist('dataForRecon', 'var')
        dataForRecon = struct( ...
            'inspiration', struct( ...
                'FID', cell(1), ...
                'TRAJ', cell(1)), ...
            'expiration', struct( ...   
                'FID', cell(1), ...
                'TRAJ', cell(1)) ...
        );
    end

    for n = 1:length(rawDatafilePaths)
        for m = 1:length(configStruct.settings.echo_times)
            dataForRecon(n).inspiration.FID{m} = ...
                fullfile(char(processedFilePaths(n).GATE_PATH), ...
                strcat('fid_inspiration_', num2str(configStruct.settings.echo_times{m})));
            dataForRecon(n).inspiration.TRAJ{m} = ...
                fullfile(char(processedFilePaths(n).GATE_PATH), ...
                strcat('traj_inspiration_', num2str(configStruct.settings.echo_times{m})));
            dataForRecon(n).expiration.FID{m} = ...
                fullfile(char(processedFilePaths(n).GATE_PATH), ...
                strcat('fid_expiration_', num2str(configStruct.settings.echo_times{m})));
            dataForRecon(n).expiration.TRAJ{m} = ...
                fullfile(char(processedFilePaths(n).GATE_PATH), ...
                strcat('traj_expiration_', num2str(configStruct.settings.echo_times{m})));
        end
    end
else
    if ~exist('dataForRecon', 'var')
        dataForRecon = struct( ...
            'FID', cell(1), ...
            'TRAJ', cell(1) ...
        );
    
%         for n = 1:length(rawDatafilePaths)
%             for m = 1:length(configStruct.settings.echo_times)
%                 dataForRecon(n).FID{m}
%             end
%         end
    end
end


%% = = = = = image reconstruction = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% Input files for reconstruction functionality are the gated trajectory/FID files produced during
% the gating routine: one pair of inspiration and expiration gated files for each TE. The
% respiration mode (inspiration/expiration) is user-specified. Therefore, the reconstruction routine
% should run N times for each dataset, where N = # TE.
%
% If the data was acquired using only one echo time (TE) or no gating was performed, this routine
% should handle it without any problems.
%
%   Ex (pseudocode):
%
%       configuration:
%           Datasets:           2
%           Respiration mode:   'expiration'
%           Number of TE:       3
%
%       execution:
%           reconstruction(dataset1_expiration_TE1)
%           reconstruction(dataset1_expiration_TE2)
%           reconstruction(dataset1_expiration_TE3)
%           reconstruction(dataset2_expiration_TE1)
%           reconstruction(dataset2_expiration_TE2)
%           reconstruction(dataset2_expiration_TE3)
%
% Reconstructed images are output as *.raw files.

if configStruct.mode.reconstruct
    % record reconstruction start time
    reconStartTime = tic;
    
    % specify the gated files that will be used based upon respiration mode
    switch configStruct.settings.resp_mode
        case 'expiration'
            gatedData = dataForRecon.expiration;
        case 'inspiration'
            gatedData = dataForRecon.inspiration;
        otherwise
            warning('Respiration mode not specified or not recognized.');
    end
    
    % import from reconstruction package
    import reconstruction.readbrukerconfigs;
    import reconstruction.multitesdc;
    
    % Read Bruker output files (ACQP, METHOD) to make trajectory corrections. Note: even if the
    % acquisition was multi-TE, there will only be one set of these.
    readbrukerconfigs( ...
        char(datasetPaths(n)), ...
        char(rawDatafilePaths(n).ACQP_PATH), ...
        char(rawDatafilePaths(n).METH_PATH), ...
        length(configStruct.settings.echo_times), ...
        configStruct.settings.num_points, ...
        configStruct.settings.interleaves, ...
        configStruct.settings.recon_mode, ...
        configStruct.settings.phi, ...
        configStruct.settings.zero_filling ...
    );
    
    for n = 1:length(datasetPaths)
        fprintf('\nCurrent dataset: %s', char(datasetPaths(n)));
        for m = 1:length(configStruct.settings.echo_times)
            fprintf('\nReconstructing %f microsecond data...', configStruct.settings.echo_times{m});
        end
    end
    

    % perform image reconstruction for each set of gated FID and trajectory files
    for n = 1:length(rawDatafilePaths)
        for m = 1:length(configStruct.settings.echo_times)
            disp(gatedData(n).FID{m})
            disp(gatedData(n).TRAJ{m})
            
            multitesdc( ...
                gatedData(n).FID{m}, ...
                gatedData(n).TRAJ{m}, ...
                char(processedFilePaths(n).RECON_PATH), ...
                length(configStruct.settings.echo_times), ...
                configStruct.settings.num_points, ...
                configStruct.settings.fid_points, ...
                configStruct.settings.num_threads, ...
                configStruct.settings.num_points_shift, ...
                configStruct.settings.lead_cut_projections, ... % check this
                configStruct.settings.end_cut_projections, ... % check this
                configStruct.settings.num_iterations, ... % check this
                configStruct.settings.verbose, ... % check this
                configStruct.settings.ram_points_mod, ... % check this
                configStruct.settings.alpha, ...
                configStruct.settings.beta ... % check this
            );
        end
    end

    % record reconstruction time elapsed
    reconTimeElapsed = toc(reconStartTime);
end


%% = = = = = MR parameter mapping = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% Input files for mapping functionality are the *.raw images written during image reconstruction, 
% one for each TE. This routine should therefore be run N times for each dataset, where N = # of TE.

if configStruct.mode.map
    % record mapping start time
    mapStartTime = tic;
    
    % import from mapping package
    import mapping.T2StarMap_working
    
    % mapping(PARAM1, PARAM2, PARAM3, ...);
    
    % record mapping time elapsed
    mapTimeElapsed = toc(mapStartTime);
end


%% record all data filenames, etc. to an output file

if configStruct.mode.log
    % define log file path and open for writing
    logFilePath = fullfile(OUT_PATH, strcat(outputPrefix, '.log'));
    logFileID = fopen(logFilePath, 'w');

    % add file header
    fprintf(logFileID, '- - - MULTI-TE - - -');
    fprintf(logFileID, '%s', datestr(timeStart, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(logFileID, '\n\nINPUT PARAMS:\n\n');

    % copy YAML input file to log and add new information
    inputFileID = fopen(configFile);
    configLine = fgets(inputFileID);
    while ischar(configLine)
        fprintf(logFileID, '%s', configLine);
        configLine = fgets(inputFileID);
    end

    % separate input & output information
    fprintf(logFileID, '\n-----------------------------------------------------------------------');
    fprintf(logFileID, '\n\nOUTPUT:\n');
    fprintf(logFileID, '\nData path: %s', DATA_PATH); 
    
    if configStruct.mode.gate
        fprintf(logFileID, '\nGating execution time: %f sec', gateTimeElapsed);
    end
    
    if configStruct.mode.reconstruct
        fprintf(logFileID, '\nReconstruction execution time: %f sec', reconTimeElapsed);
    end
    
    if configStruct.mode.map
        fprintf(logFileID, '\nT2* Mapping Execution time: %f sec', mapTimeElapsed);
    end
    
    % close the output file
    fclose(logFileID);
end


%% finish execution

fprintf('\nExecution finished: << %f sec >>\n', timeElapsed);
fprintf('Output available at %s\n', OUT_PATH);

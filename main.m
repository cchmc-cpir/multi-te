%% MULTI-TE IMAGE PROCESSING: ENTRY POINT

%   Author(s): Alex Cochran
%   Email: Alexander.Cochran@cchmc.org, acochran50@gmail.com
%   Group: CCHMC CPIR
%   Date: 2018

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
%   * DATA_DIRECTORY is the top-level path for the use of this script. Note: this program does NOT
%     need to be in the same path. This script (multi-te/main.m) will prompt the user to specify the
%     directories that should be parsed.
%   * SCAN_DATA_PATH content should contain sub-directories for each set of MRI scan datafiles
%     (acqp, traj, method, fid, etc.)
%   * PROCESSED_PATH content will be created as needed during the course of the analysis
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
addpath('./control'); % checkselection.m


%% startup

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


%% Select scan data directory

while ~exist('DATA_PATH', 'var') || ~isa(DATA_PATH, 'char')
    DATA_PATH = uigetdir('', 'Choose data directory');
    if invalidselection(DATA_PATH, 'char')
        return;
    end
end

% store the top-level directory as the parent of the user-selected DATA_PATH
TOP_PATH = fileparts(DATA_PATH);


%% select datasets

% select the datasets in DATA_PATH to process
while ~exist('DATASETS', 'var') || isempty(DATASETS)
    DATASETS = uigetmult(DATA_PATH, 'Select dataset folders');
    if invalidselection(DATASETS, 'cell')
        clear DATASETS
        return;
    end
end


%% select datafiles

% file path structure preallocation
dataStruct = struct( ...
    'ACQP_PATH', cell(1, length(DATASETS)), ...
    'TRAJ_PATH', cell(1, length(DATASETS)), ...
    'METH_PATH', cell(1, length(DATASETS)), ...
    'FID_PATH', cell(1, length(DATASETS)) ...
);

while ~exist('INPUT_MODE', 'var') || isempty(INPUT_MODE)
    INPUT_MODE = questdlg('Select ACQP, METHOD, FID, and TRAJ files automatically or manually?', ...
        'Selection mode', 'Manually', 'Automatically', 'Quit', 'Quit');
    switch INPUT_MODE
        case 'Automatically'
            for n = 1:length(DATASETS)
                dataStruct(n).ACQP_PATH = fullfile(DATASETS(n), 'acqp');
                dataStruct(n).TRAJ_PATH = fullfile(DATASETS(n), 'traj');
                dataStruct(n).METH_PATH = fullfile(DATASETS(n), 'method');
                dataStruct(n).FID_PATH = fullfile(DATASETS(n), 'fid');
            end
        case 'Manually'
            for n = 1:length(DATASETS)
                dataStruct(n).ACQP_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose ACQP', DATASETS(n));
                if invalidselection(datastruct(n).ACQP_PATH, 'cell')
                    return;
                end

                dataStruct(n).TRAJ_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose TRAJ', DATASETS(n));
                if invalidselection(datastruct(n).TRAJ_PATH, 'cell')
                    return;
                end

                dataStruct(n).METH_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose METH', DATASETS(n));
                if invalidselection(datastruct(n).METH_PATH, 'cell')
                    return;
                end

                dataStruct(n).FID_PATH = uigetfile({'*.*', 'All Files (*.*)'}, ...
                    'Choose FID', DATASETS(n));
                if invalidselection(datastruct(n).FID_PATH, 'cell')
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


%% check for file existence

for n = 1:length(dataStruct)
    checkACQP = exist(char(dataStruct(n).ACQP_PATH), 'file');
    checkTraj = exist(char(dataStruct(n).TRAJ_PATH), 'file');
    checkMeth = exist(char(dataStruct(n).METH_PATH), 'file');
    checkFID = exist(char(dataStruct(n).FID_PATH), 'file');
    
    if ~checkACQP || ~checkTraj || ~checkMeth || ~checkFID
        error('One or more datafiles is not properly specified/does not exist.');
    end
end


%% define output location(s)

while ~exist('OUTPUT_MODE', 'var') || isempty(OUTPUT_MODE)
    OUTPUT_MODE = questdlg('Define output location and prefix automatically or manually?', ...
        'Selection mode', 'Manually', 'Automatically', 'Quit', 'Quit');
    switch OUTPUT_MODE
        case 'Automatically'
            pathParts = strsplit(DATA_PATH, filesep); % filesep should make this platform agnostic
            TOP_PATH = strjoin(pathParts(1:end-1), filesep);
            OUT_PREFIX = datestr(timeStart, 'yyyy-mm-dd_HH-MM-SS'); % date prefix
        case 'Manually'
            TOP_PATH = uigetdir('', 'Choose output directory');
            OUT_PREFIX = inputdlg('Enter a prefix for output files:');
        case 'Quit'
            return
        otherwise % if the user closes the window
            if invalidselection(DATA_PATH, 'char')
                return;
            end
    end
end

% define top-level output path in proper locations
OUT_PATH = fullfile(TOP_PATH, 'processed_data');

% safely create top-level output directory for this execution
if ~exist(OUT_PATH, 'dir')
    mkdir(OUT_PATH);
end

% preallocate
SCAN_PATHS = cell(length(dataStruct));

% define output paths for each dataset
for n = 1:length(dataStruct)
    SCAN = strsplit(char(DATASETS(n)), filesep);
    SCAN_PATHS(n) = fullfile(OUT_PATH, strcat(SCAN(end), '_processed'));
    
    % safely create output directories for each dataset
    if ~exist(char(SCAN_PATHS(n)), 'dir')
        mkdir(char(SCAN_PATHS(n)));
    end
end


%% retrospective gating

if configStruct.mode.gate
    % record gating start time
    gateStartTime = tic;
    
    % import from gating package
    import gating.retrogatingleadmag
    
    for n = 1:length(dataStruct)
        % gating operation
        retrogatingleadmag( ...
            configStruct.settings.num_projections, ...
            configStruct.settings.num_cut_projections, ...
            configStruct.settings.num_points, ...
            configStruct.settings.num_sep, ...
            configStruct.settings.exp_threshold, ...
            configStruct.settings.insp_threshold, ...
            configStruct.settings.echo_times, ...
            char(DATASETS(n)), ...
            char(dataStruct(n).FID_PATH), ...
            char(SCAN_PATHS(n)), ...
            OUT_PREFIX ...
        );
    end
    
    % record gating time elapsed
    gateTimeElapsed = toc(gateStartTime);
end


%% image reconstruction

if configStruct.mode.reconstruct
    % record reconstruction start time
    reconStartTime = tic;
    
    % import from reconstruction package
    import reconstruction.readbrukerconfigs
    import reconstruction.multitesdc
    
    % read Bruker output files (ACQP, METHOD) to make trajectory corrections
    readbrukerconfigs( ...
        DATA_PATH, ...
        dataStruct(n).ACQP_PATH, ...
        dataStruct(n).METH_PATH, ...
        length(configStruct.settings.echo_times), ...
        configStruct.settings.num_points, ...
        configStruct.settings.interleaves, ...
        configStruct.settings.recon_mode, ...
        configStruct.settings.phi, ...
        configStruct.settings.zero_filling ...
    );
    
    % perform image reconstruction
    multitesdc( ...
        DATA_PATH, ...
        filename, ...
        length(configStruct.settings.echo_times), ...
        configStruct.num_proj ...
    );

    % record reconstruction time elapsed
    reconTimeElapsed = toc(reconStartTime);
end


%% parameter mapping

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
    logFilePath = fullfile(OUT_PATH, strcat(OUT_PREFIX, '.log'));
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
    fprintf(logFileID, '\nGating execution time: %f sec', gateTimeElapsed);
    fprintf(logFileID, '\nReconstruction execution time: %f sec', reconTimeElapsed);
    fprintf(logFileID, '\nT2* Mapping Execution time: %f sec', mapTimeElapsed);

    % close the output file
    fclose(logFileID);
end


%% finish execution

fprintf('\nExecution finished: << %f sec >>\n', timeElapsed);
fprintf('Output available at %s\n', OUT_PATH);

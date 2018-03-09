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


%% ask to clear workspace if already populated

if ~isempty(who)
    clearPrompt = questdlg('Clear workspace?', 'Clear?', 'Yes', 'No', 'No');
    if strcmp(clearPrompt, 'Yes')
        clear;
    end
end
    

%% add paths to 3rd party utility classes/functions

addpath('./tools/yaml-matlab');
addpath('./tools/uigetmult');


%% capture program start time

timeStart = datetime('now');


%% read YAML input file (input.yml)

% add paths to use and test YAML input
addpath('./tools/yaml-matlab');

while ~exist('configStruct', 'var')
    configFile = './input.yml';
    configStruct = ReadYaml(configFile);
end


%% Select top-level data directory

while ~exist('DATA_PATH', 'var') || ~isa(DATA_PATH, 'char')
    % notify user that having all data files in the same directories is a good idea
    fprintf('\nBEST RESULTS: have FID, ACQP, trajectory, and method files in the same folders.\n')
    DATA_PATH = uigetdir('', 'Choose data directory');
    if ~isa(DATA_PATH, 'char') % catches exit state of 0 (if action is cancelled)
        QUIT = questdlg('No path selected. Quit or continue?', 'No path selected', ...
            'Continue', 'Quit', 'Continue');
        switch QUIT
            case 'Quit'
                return;
            case 'Continue'
                clear DATA_PATH;
        end
    end
end

% store the top-level directory as the parent of the user-selected DATA_PATH
TOP_PATH = fileparts(DATA_PATH);


%% select datasets

% select the datasets in DATA_PATH to process
while ~exist('DATASETS', 'var') || isempty(DATA_SETS)
    DATASETS = uigetmult
end

%% select data files

% either choose a directory and allow automatic selection of ACQP, FID, and TRAJ files, or select
% each of them manually

while ~exist('INPUT_MODE', 'var') || isempty(INPUT_MODE)
    INPUT_MODE = questdlg('Select ACQP, METHOD, FID, and TRAJ files automatically or manually?', ...
        'Selection mode', 'Manually', 'Automatically', 'Quit');
    switch INPUT_MODE
        case 'Automatically'
            METH_FILE = fullfile(DATA_PATH, 'method');
            ACQP_FILE = fullfile(DATA_PATH, 'acqp');
            TRAJ_FILE = fullfile(DATA_PATH, 'traj');
            FID_FILE = fullfile(DATA_PATH, 'fid');

        case 'Manually'
            % use UI to choose ACQP file
            while ~exist('ACQP_FILE', 'var')
                ACQP_FILE = uigetfile({'*.*', 'All Files (*.*)'}, 'Choose ACQP file');
                if ~isa(ACQP_FILE, 'char') % could look for more robust methods
                    QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
                        'Continue', 'Quit', 'Continue');
                    switch QUIT
                        case 'Quit';
                            return;
                        case 'Continue'
                            clear ACQP_FILE;
                    end
                end
            end

            % use UI to choose trajectory file
            while ~exist('TRAJ_FILE', 'var')
                TRAJ_FILE = uigetfile({'*.*', 'All Files (*.*)'}, 'Choose trajectories', DATA_PATH);
                if ~isa(TRAJ_FILE, 'char') % could look for more robust methods
                    QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
                        'Continue', 'Quit', 'Continue');
                    switch QUIT
                        case 'Quit'
                            return
                        case 'Continue'
                            clear TRAJ_FILE;
                    end
                end
            end

            % use UI to choose method file
            while ~exist('METH_FILE', 'var')
                METH_FILE = uigetfile({'*.*', 'All Files (*.*)'}, 'Choose method file', DATA_PATH);
                if ~isa(METH_FILE, 'char') % could look for more robust methods
                    QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
                        'Continue', 'Quit', 'Continue');
                    switch QUIT
                        case 'Quit'
                            return
                        case 'Continue'
                            clear METH_FILE;
                    end
                end
            end

            % use UI to choose FID file
            while ~exist('FID_FILE', 'var')
                FID_FILE = uigetfile({'*.*', 'All Files (*.*)'}, 'Choose FID', DATA_PATH);
                if ~isa(FID_FILE, 'char') % could look for more robust methods
                    QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
                        'Continue', 'Quit', 'Continue');
                    switch QUIT
                        case 'Quit';
                            return;
                        case 'Continue'
                            clear FID_FILE;
                    end
                end
            end

        case 'Quit'
            return
    end
end


%% define output location(s)

while ~exist('OUTPUT_MODE', 'var') || isempty(OUTPUT_MODE)
    OUTPUT_MODE = questdlg('Define output location and file prefix automatically or manually?', ...
        'Selection mode', 'Manually', 'Automatically', 'Quit');
    switch OUTPUT_MODE
        case 'Automatically'
            OUT_PATH = fullfile(DATA_PATH, '/data/output/');
            OUT_PREFIX = datestr(timeStart, 'yyyy-mm-dd_HH-MM-SS'); % date prefix for output file names
        case 'Manually'
            OUT_PATH = uigetdir('', 'Choose output directory');
            OUT_PREFIX = inputdlg('Enter a prefix for output files:');
        case 'Quit'
            return
    end
end

fullOutputPath = strcat(OUT_PATH, '/', OUT_PREFIX);

% safely create output directory for this execution
if ~exist(fullOutputPath, 'dir')
    mkdir(fullOutputPath);
end


%for n = 1:length(
%% retrospective gating

if configStruct.mode.gate
    % record gating start time
    gateStartTime = tic;
    
    % import from gating package
    import gating.retrogatingleadmag
    
    % gating operation
    retrogatingleadmag( ...
        configStruct.settings.num_projections, ...
        configStruct.settings.num_cut_projections, ...
        configStruct.settings.num_points, ...
        configStruct.settings.num_sep, ...
        configStruct.settings.exp_threshold, ...
        configStruct.settings.insp_threshold, ...
        configStruct.settings.echo_times, ...
        DATA_PATH, ...
        FID_FILE, ...
        OUT_PATH, ...
        OUT_PREFIX ...
    );
    
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
        ACQP_FILE, ...
        METH_FILE, ...
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
    logFilePath = fullfile(fullOutputPath, strcat(OUT_PREFIX, '.log'));
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
fprintf('Output available at %s\n', fullOutputPath);

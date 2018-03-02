%% MULTI-TE IMAGE PROCESSING: ENTRY POINT

%{
    Author(s): Alex Cochran
    Email: Alexander.Cochran@cchmc.org, acochran50@gmail.com
    Group: CCHMC CPIR
    Date: 2018
%}

% This is the entry point for multi-TE image processing. From here, retrospective gating, image
% reconstruction, and parameter mapping can be done. All configuration options should be entered in
% the input.yml file found in the top-level directory.

% NOTE: This script will prompt the user for input data (in this case, an appropriately sized FID
% file), which can be selected from ~any~ directory. The output files are sent to the ./data/output
% directory, where they are further organized by the time the program's execution is started. The
% trajectory file ('traj') is also assumed to be in the same directory as the selected FID.


%% ask to clear workspace if already populated

if ~isempty(who)
    clearPrompt = questdlg('Clear workspace?', 'Clear?', 'Yes', 'No', 'No');
    if strcmp(clearPrompt, 'Yes')
        clear;
    end
end
    

%% start program timer

timeNow = datetime('now');


%% read YAML input file (input.yml)

% add yaml-matlab tool file path
addpath('./yaml-matlab');

while ~exist('configStruct', 'var')
    configFile = './input.yml';
    configStruct = ReadYaml(configFile);
end

% (ROUTINE NEEDED: examine YAML file for any missing entries that will lead to program malfunction)
%       ...structure as unit tests?


%% select data directory

while ~exist('DATA_PATH', 'var')
    DATA_PATH = uigetdir('', 'Choose data directory');
    if ~isa(DATA_PATH, 'char') % catches exit state of 0 (if action is cancelled)
        QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
            'Continue', 'Quit', 'Continue');
        switch QUIT
            case 'Quit'
                return;
            case 'Continue'
                clear DATA_PATH;
        end
    end
end


%% select data files

% either choose a directory and allow automatic selection of ACQP, FID, and TRAJ files, or select
% each of them manually

MODE = questdlg('Select ACQP, FID, and TRAJ files automatically or manually?', 'Selection mode', ...
    'Manually', 'Automatically', 'Quit');
switch MODE
    case 'Automatically'
        ACQP_FILE = fullfile(DATA_PATH, 'acqp');
        TRAJ_FILE = fullfile(DATA_PATH, 'traj');
        METH_FILE = fullfile(DATA_PATH, 'meth');
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
end


%% define output location(s)

OUT_PATH = './data/output';
OUT_PREFIX = datestr(timeNow, 'yyyy-mm-dd_HH-MM-SS'); % prefix for output file names
fullOutputPath = strcat(OUT_PATH, '/', OUT_PREFIX);

% safely create output directory for this execution
if ~exist(fullOutputPath, 'dir')
    mkdir(fullOutputPath);
end


%% retrospective gating

if configStruct.mode.gate
    % add gating folder path
    addpath('./gating');

    % perform gating operation
    gateStartTime = tic;
    retrogatingleadmag(configStruct, DATA_PATH, FID_FILE, OUT_PATH, OUT_PREFIX);
    
    retrogatingleadmag( ...
        configStruct.num_projections, ...
        configStruct.num_cut_projections, ...
        configStruct.num_points, ...
        configStruct.num_sep, ...
        configStruct.exp_threshold, ...
        configStruct.insp_threshold, ...
        configStruct.echo_times, ...
        DATA_PATH, ...
        FID_FILE, ...
        OUT_PATH, ...
        OUT_PREFIX ...
    )
    
    gateTimeElapsed = toc(gateStartTime);
end


%% image reconstruction

if configStruct.mode.reconstruct
    % add reconstruction folder path
    addpath('./reconstruction');

    % perform image reconstruction
    reconStartTime = tic;
    
    % read Bruker output files (ACQP, METHOD) to make trajectory corrections
    readbrukerconfigs( ...
        DATA_PATH, ...
        ACQP_FILE, ...
        METH_FILE, ...
        length(configStruct.settings.echo_times), ...
        configStruct.settings.num_points, ...
        configStruct.settings.interleaves, ...
        configStruct.settings.recon_mode, ...
        configStruct.settings.phi ...
    )
    
    readbrukerconfigs(DATA_PATH, ACQP_FILE, METH_FILE, ...
        length(configStruct.settings.echo_times), configStruct.settings.num_points, ...
        configStruct.)
    % reconstruction(PARAM1, PARAM2, PARAM3, ...);
    reconTimeElapsed = toc(reconStartTime);
end


%% parameter mapping

if configStruct.mode.map
    % add mapping folder path
    addpath('./mapping');

    % perform image mapping
    mapStartTime = tic;
    % mapping(PARAM1, PARAM2, PARAM3, ...);
    mapTimeElapsed = toc(mapStartTime);
end


%% record all data filenames, etc. to an output file

if configStruct.mode.log
    % define log file path and open for writing
    logFilePath = fullfile(fullOutputPath, strcat(OUT_PREFIX, '.log'));
    logFileID = fopen(logFilePath, 'w');

    % add file header
    fprintf(logFileID, '- - - MULTI-TE - - - ');
    fprintf(logFileID, '%s', datestr(timeNow, 'yyyy-mm-dd HH:MM:SS'));
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


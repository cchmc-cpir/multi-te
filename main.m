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
%
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

timeStart = tic;
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

%% select data files

% use UI to choose FID
while ~exist('DATA_FILE', 'var')
    [DATA_FILE, DATA_PATH] = uigetfile({'*.*', 'All Files (*.*)'}, 'Choose FID');
    if ~isa(DATA_FILE, 'char') % could look for more robust methods
        QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
            'Continue', 'Quit', 'Continue');
        switch QUIT
            case 'Quit'
                return
            case 'Continue'
                clear DATA_FILE;
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

% add gating folder path
addpath('./gating');

% perform gating operation
retrogatingleadmag(configStruct, DATA_PATH, DATA_FILE, OUT_PATH, OUT_PREFIX);


%% image reconstruction

% add reconstruction folder path
addpath('./reconstruction');

% perform image reconstruction
% reconstruction(PARAM1, PARAM2, PARAM3, ...);


%% parameter mapping

% add mapping folder path
addpath('./mapping');

% perform image mapping
% mapping(PARAM1, PARAM2, PARAM3, ...);


%% stop program timer

% calculate time (seconds) since execution start
timeElapsed = toc(timeStart);


%% record all data filenames, etc. to an output file

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
fprintf(logFileID, '\nExecution time: %f sec', timeElapsed);

% close the output file
fclose(logFileID);


%% finish execution

fprintf('\nExecution finished: << %f sec >>\n', timeElapsed);
fprintf('Output available at %s\n', fullOutputPath);


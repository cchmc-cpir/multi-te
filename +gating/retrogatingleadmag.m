function retrogatingleadmag(numProj, numCutProj, numPoints, numSep, threshPctExp, ...
    threshPctInsp, echoTimes, inputPath, inputFID, outputDir, outputPrefix)
    %RETROGATINGLEADMAG Separate FID data based upon inspiration/expiration.
    %   Takes a single FID and returns new FID files separated into inspiration and expiration data,
    %   organized by echo time. Works for up to three echo times.
    %
    %   Written by Jinbang Guo, Matt Freeman, Alex Cochran, 2018.


    %% constants
    
    NUM_PROJ = numProj;
    NUM_CUT_PROJ = numCutProj;
    NUM_POINTS = numPoints;
    NUM_SEP = numSep;
    THRESH_PCT_EXP = threshPctExp;
    THRESH_PCT_INSP = threshPctInsp;
    ECHO_TIMES = echoTimes;

    % additional calculated constants
    NUM_PROJ_REAL = NUM_PROJ - NUM_CUT_PROJ;
    SEPARATION = round(NUM_PROJ_REAL / NUM_SEP);


    %% set input path + file
    
    DATA_PATH = inputPath;
    DATA_FILE = inputFID;


    %% confirm program configuration

    % only prompts if the filenames have not already been confirmed
    if ~exist('CONFIRM', 'var')
        while ~exist('CONFIRM', 'var')
            CONFIRM = questdlg('Proceed with gating?', 'Confirm?', 'Yes', 'No', 'Yes');
            if isempty(CONFIRM)
                clear CONFIRM;
            end
        end

        % decide whether to proceed
        switch CONFIRM
            case 'Yes'
                disp('GATING :: CONFIGURATION SUCCESSFUL; PROCEEDING');
            case 'No'
                disp('GATING :: CONFIGURATION HALTED; ABORTING');
                return % exit script
        end
    end

    
    %% data read

    % open file and extract k-space information, set by set
    fileID = fopen(DATA_FILE);
    kData = fread(fileID, [2, inf], 'int32');
    fclose(fileID);

    % separate real and complex k-space information
    kDataCmplx = complex(kData(1, :), kData(2, :));
    kDataMag = abs(kDataCmplx);
    kDataMag = reshape(kDataMag, [128, NUM_PROJ * 3]);
    kData3Echo = kData;                                     % why assign again here...
    clear kData;                                            % and then clear here?


    %% retrospective gating subroutine

    disp('STARTING RETROSPECTIVE GATING ROUTINE');

    for echoIndex = 1:3

        tempMag = kData3Echo(:, echoIndex:3:NUM_PROJ * 3 - 3 + echoIndex);
        for index = 1:NUM_PROJ
            kData(:, (index - 1) * 128 + 1:index * 128) = ...
                kData3Echo(:, (echoIndex - 1) * 128 + 1 + (index - 1) * 128 * 3: ...
                echoIndex * 128 + (index-1) * 128 * 3);
        end

        magnitudeLeading = squeeze(tempMag(2, NUM_CUT_PROJ + 1:NUM_PROJ)); % 2 orig. == 20

        selectVectorExp = zeros(1, NUM_PROJ_REAL);
        selectVectorInsp = zeros(1, NUM_PROJ_REAL);

        subplot(3, 1, echoIndex);

        for i = 1:NUM_SEP;
            minPeakHeight = (max(magnitudeLeading((i - 1) * SEPARATION + 1:i * SEPARATION)) + ...
                min(magnitudeLeading((i - 1) * SEPARATION + 1:i * SEPARATION))) / 2;

            [peaks, ~] = findpeaks(magnitudeLeading((i - 1) * SEPARATION + 1:i * SEPARATION), ...
                'MINPEAKHEIGHT', minPeakHeight);
            meanMax = max(peaks);

            [peaks, ~] = findpeaks(-magnitudeLeading((i - 1) * SEPARATION + 1:i * SEPARATION), ...
                'MINPEAKHEIGHT', -minPeakHeight);
            meanMin = -max(peaks);

            threshold = meanMax - THRESH_PCT_EXP * (meanMax - meanMin);
            selectVectorExp(1, (i - 1) * SEPARATION + 1:i * SEPARATION) = ...
                magnitudeLeading((i - 1) * SEPARATION + 1:i * SEPARATION) > threshold;

            threshold = meanMin - THRESH_PCT_INSP * (meanMax - meanMin);
            selectVectorInsp(1, (i - 1) * SEPARATION + 1:i * SEPARATION) = ...
                magnitudeLeading((i - 1) * SEPARATION + 1:i * SEPARATION) < threshold;
        end

        selectVectorExp = logical(selectVectorExp);
        selectVectorInsp = logical(selectVectorInsp);

        plot(magnitudeLeading, 'o', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', ...
            'w', 'MarkerSize', 5);
        hold on;
        xlabel(strcat(['FID # ', num2str(echoIndex), ' [TE: ', char(ECHO_TIMES{echoIndex}), ...
            '\mus]']), 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
        ylabel('Phase [radians]', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
        title('Leading phase of each spoke', 'FontSize', 15, 'FontWeight', 'bold', 'Color', 'k');

        magnitudeExp = magnitudeLeading(selectVectorExp);
        locsExp = find(selectVectorExp);
        %plot(locsExp, magnitudeExp, 'ro');

        magnitudeInsp = magnitudeLeading(selectVectorInsp);
        locsInsp = find(selectVectorInsp);
        plot(locsInsp, magnitudeInsp, 'gs');

        hold off
        xlim([1, 1000]);

        % reshape k-space information
        kData = reshape(kData, [2 128 NUM_PROJ]);
        kData = kData(:, :, NUM_CUT_PROJ + 1:NUM_PROJ);

        % write expiration data to file
        kDataExp = kData(:, :, selectVectorExp);
        numProjExp = size(kDataExp, 3);
        fileID = fopen(fullfile(outputDir, strcat(['fid_expiration_', ...
            num2str(ECHO_TIMES{echoIndex})])), 'w');                           % CHANGED DESTINATION
        fwrite(fileID, kDataExp, 'int32');
        fclose(fileID);

        % read trajectory information (maybe move outside loop?)
        fileID = fopen(fullfile(DATA_PATH, 'traj'));                           % CHANGED DESTINATION
        trajectory = reshape(fread(fileID, [3, inf], 'double'), [3 NUM_POINTS NUM_PROJ * 3]);
        fclose(fileID);

        % extract expiration trajectory data
        trajectory3Echo = trajectory;
        clear trajectory;
        trajectory = trajectory3Echo(:, :, NUM_CUT_PROJ + echoIndex:3:NUM_PROJ * 3 - 3 + echoIndex);
        trajectoryExp = trajectory(:, :, selectVectorExp);

        % write expiration trajectory data to file
        fileID = fopen(fullfile(outputDir, strcat(['traj_expiration_', ...
            num2str(ECHO_TIMES{echoIndex})])), 'w');                           % CHANGED DESTINATION
        fwrite(fileID, trajectoryExp, 'double');
        fclose(fileID);

        % write inspiration data to file
        kDataInsp = kData(:, :, selectVectorInsp);
        numProjInsp = size(kDataInsp, 3);
        fileID = fopen(fullfile(outputDir, strcat(['fid_inspiration_', ...
            num2str(ECHO_TIMES{echoIndex})])), 'w');                           % CHANGED DESTINATION
        fwrite(fileID, kDataInsp, 'int32');
        fprintf('\nEcho time: %f\nkDataInsp size: %f', ECHO_TIMES{echoIndex}, size(kDataInsp));
        fclose(fileID);

        % extract inspiration trajectory data
        trajectoryInsp = trajectory(:, :, selectVectorInsp);

        % write inspiration trajectory data to file
        fileID = fopen(fullfile(outputDir, strcat(['traj_inspiration_', ...
            num2str(ECHO_TIMES{echoIndex})])), 'w');                           % CHANGED DESTINATION
        fwrite(fileID, trajectoryInsp, 'double');
        fclose(fileID);
    end

    % set figure position
    set(gcf, 'Position', [50 80 1420 680]);

    disp('RETROSPECTIVE GATING ROUTINE COMPLETE');
end


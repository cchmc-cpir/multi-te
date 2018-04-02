function multitesdc(fidPath, trajPath, outPath, numTE, numPoints, fidPoints, numThreads, ...
    numPointsShift, leadingCutProj, endingCutProj, numIter, verbose, ramPointsMod, alpha, beta)
    %MULTITESDC Multi-TE sampling density compensation.
    %   Appropriately weights non-uniformly sampled k-space data to ensure accurate image
    %   reconstruction after interpolation onto a Cartesian grid. For use with data from interleaved
    %   multi-TE UTE sequences.
    %
    %   This script writes the DCF (density compensation file) that is to be used during the
    %   reconstruction process.
    %
    %   fidPath:            FID file path
    %   trajPath:           trajectory file path
    %   outPath:            output path
    %   outPrefix:          output filename prefix (for organization)
    %   numTE:              number of echo tims
    %   numProj:            number of projections
    %   numPoints:          number of points on each projection
    %   fidPoints:          _____
    %   numPointsShift:     _____
    %   leadingCutProj:     number of projections cut from leading edge
    %   endingCutProj:      number of projections cut from ending edge
    %   numIter:            number of iterations (SDC)
    %   verbose:            whether the MEX functions echo output (SDC)
    %   ramPointsMod:       _____
    %   alpha:              gridding oversampling ratio (for grid3 routine)
    %   beta:               expansion factor ratio: alpha_x/alpha_z, where alpha_x = alpha_y (grid3)
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.

    
    %% respiration mode
    
    % specify respiration mode (inspiration/expiration)
    if strfind(trajPath, 'inspiration')
        respMode = 'inspiration';
    elseif strfind(trajPath, 'expiration')
        respMode = 'expiration';
    else
        respMode = 'notspec'; % WEAK POINT: need to do better handling of non-spec. resp. modes
    end

    
    %% create *.raw filename from current information
    
    % Extract echo time from an input file
    filePath = fidPath;
    filePath(strfind(filePath, '_')) = [];
    key = respMode;
    index = strfind(filePath, key);
    %echoTime = num2str(sscanf(filePath(index(1) + length(key):end), '%g', 1));
    echoTime = '10000';
    % Define *.raw filename
    outputFilename = strcat('reconstructed_img_', respMode, '_', echoTime, '.raw');
    
    
    %% setup calculated parameter(s)/other local variables
    
    realNumPoints = numPoints - numPointsShift;
    DCFPath = fullfile(outPath, strcat('DCF_', respMode));
     
    
    %% load trajectory information
    
    fileID = fopen(trajPath);

    trajData = squeeze(fread(fileID, inf, 'double'));
    fclose(fileID);

    % reshape trajectory data
    trajData = reshape(trajData, 3, numPoints, []);
    numProj = size(trajData, 3);

    % cut ending poins along one spoke
    coords = trajData(:, 1:realNumPoints, (leadingCutProj + 1):numProj - endingCutProj);
    
    r = sqrt(coords(1, realNumPoints, :) .^ 2 + coords(2, realNumPoints, :) .^ 2 ...
        + coords(3, realNumPoints, :) .^2);
    coords = coords ./ max(r(:)) / 2;
    
    disp('RECONSTRUCTION :: GENERATING DCF');
     
    
    %% SDC calculations
    
    import reconstruction.sdc3.sdc3_MAT;
    
    % define effMatrix
    ramPoints = numPoints - ramPointsMod;
    effMatrix = (realNumPoints - ramPoints) * 2 * beta;
    
    % run SDC routine
    DCF = sdc3_MAT(coords, numIter, effMatrix, verbose, alpha);
    DCF = single(DCF); % float32

    
    %% write output DCF
    
    fileID = fopen(DCFPath, 'w');
    fwrite(fileID, DCF, 'float32');
    fclose(fileID);
    
    clear temp;
    clear DCF;
    clear crds;
    clear r;
    clear trajFileName;
    clear DCFFilename;

    
    %% run reconstruction routine
    
    import reconstruction.multitegrid;
    
    disp('RECONSTRUCTION :: RECONSTRUCTING...');
    multitegrid( ...
        numPoints, ...
        numProj, ...
        ramPoints, ...
        fidPoints, ...
        leadingCutProj, ...
        endingCutProj, ...
        numPointsShift, ...
        respMode, ...
        outPath, ...
        alpha, ...
        fidPath, ...
        trajPath, ...
        numThreads, ...
        outputFilename ...
    );
end


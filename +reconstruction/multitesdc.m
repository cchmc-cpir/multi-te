function multitesdc(fidPath, trajPath, outPath, numTE, numProj, numPoints, fidPoints, numThreads, ...
    numPointsShift, leadingCutProj, endingCutProj, numIter, oSF, verbose, ramPointsMod, alpha, beta)
    %MULTITESDC Multi-TE sampling density compensation.
    %   Appropriately weights non-uniformly sampled k-space data to ensure accurate image
    %   reconstruction after interpolation onto a Cartesian grid. For use with data from interleaved
    %   multi-TE UTE sequences.
    %
    %   fidPath:            FID file path
    %   trajPath:           trajectory file path
    %   outPath:            output path
    %   outPrefix:          output filename prefix (for organization)
    %   numTE:              number of echo tims
    %   numProj:            number of projections
    %   numPoints:          number of points on each projectoin
    %   fidPoints:          _____
    %   numPointsShift:     _____
    %   leadingCutProj:     number of projections cut from leading edge
    %   endingCutProj:      number of projections cut from ending edge
    %   numIter:            number of iterations (SDC)
    %   oSF:                _____ (SDC)
    %   verbose:            _____ (SDC)
    %   ramPointsMod:       _____
    %   alpha:              gridding oversampling ratio (for grid3 routine)
    %   beta:               expansion factor ratio: alpha_x/alpha_z, where alpha_x = alpha_y (grid3)
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.

    
    %% respiration mode
    
    % specify respiration mode (inspiration/expiration)
    if strfind(trajFile, 'inspiration')
        respMode = 'inspiration';
    elseif strfind(trajFile, 'expiration')
        respMode = 'expiration';
    else
        respMode = 'notspec';
    end

    
    %% setup calculated parameter(s)/other local variables
    
    realNumPoints = numPoints - numPointsShift;
    DCFPath = fullfile(outPath, strcat('DCF_respmode'));
     
    
    %% load trajectory information
    
    fileID = fopen(trajPath);
    trajData = squeeze(fread(fileID, inf, 'double'));
    fclose(fileID);
    
    % reshape trajectory data
    trajData = reshape(trajData, [3, numPoints, numProj]);
    
    % cut ending poins along one spoke
    coords = trajData(:, 1:realNumPoints, (leadingCutProj + 1):numProj - endingCutProj);
    
    r = sqrt(coords(1, realNumPoints, :) .^ 2 + coords(2, realNumPoints, :) .^ 2 ...
        + coords(3, realNumPoints, :) .^2);
    coords = coords ./ max(r(:)) / 2;
    
    disp('Generating DCF for ', trajPath);
     
    
    %% SDC calculations
    
    % add nested SDC directory to current path
    addpath('./sdc3');
    
    % define effMatrix
    ramPoints = numPoints - ramPointsMod;
    effMatrix = (realNumPoints - ramPoints) * 2 * beta;
    
    % run SDC routine
    DCF = sdc3_MAT(coords, numIter, effMatrix, verbose, oSF);
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
    
    % add nested grid3 directory to current path
    addpath('./grid3');
    
    disp(['Reconstructing ', newFilePath]);
    multitegrid( ...
        numPoints, ...
        numProj, ...
        ramPoints, ...
        fidPoints, ...
        leadingCutProj, ...
        endingCutProj, ...
        numPointsShift, ...
        respMode, ...
        trajPath, ...
        outPath, ...
        alpha, ...
        numTE, ...
        fidPath, ...
        trajPath, ...
        numThreads ...
    );


end


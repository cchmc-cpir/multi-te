function multitesdc(trialID, fidPath, trajPath, numTE, numProj, numPoints, fidPoints, numPointsShift, leadingCutProj, endingCutProj)
    %MULTITESDC Multi-TE sampling density compensation.
    %   Appropriately weights non-uniformly sampled k-space data to ensure accurate image
    %   reconstruction after interpolation onto a Cartesian grid. For use with data from interleaved
    %   multi-TE UTE sequences.
    %
    %   trialID:            user-specific experimental ID (for output filenames)
    %   fidPath:            FID file path
    %   trajPath:           trajectory file path
    %   numTE:              number of echo tims
    %   numProj:            number of projections
    %   numPoints:          number of points on each projectoin
    %   fidPoints:          _____
    %   numPointsShift:     _____
    %   leadingCutProj:     number of projections cut from leading edge
    %   endingCutProj:      numbe rof projections cut from ending edge
    %   numIter:            number of iterations (SDC)
    %   effMatrix:          _____ (SDC)
    %   oSF:                _____ (SDC)
    %   verbose:            _____ (SDC)
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.

    
    %% respiration mode
    
    % specify respiration mode (inspiration/expiration)
    if strfind(fidFile, 'inspiration')
        respMode = 'inspiration';
    elseif strfind(fidFile, 'expiration')
        respMode = 'expiration';
    else
        respMode = 'notspec';
    end

    
    %% setup calculated parameters
    
    realNumPoints = numPoints - numPointsShift;
    realNumProj = numProj - leadingCutProj - endingCutProj;
     
    
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
    addpath('./sdc3')
    
    % run SDC routine
    DCF = sdc3_MAT(coords, numIter, effMatrix, verbose, oSF);
    DCF = single(DCF); % float32

    
    %% write output DCF
    
    temp = DCF;
    fileID = fopen(fullfile);
    clear temp;
    clear DCF;
    clear crds;
    clear r;
    clear trajFileName;
    clear DCFFilename;

    
    %% end reconstruction
    
    % add nested grid3 directory to current path
    addpath('./grid3')
    
    disp(['Reconstructing ', newFilePath])
    grid3_multiTE(numPoints)
end


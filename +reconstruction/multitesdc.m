function multitesdc(fidPath, trajPath, outPath, numTE, numProj, numPoints, fidPoints, numThreads, ...
    numPointsShift, leadingCutProj, endingCutProj, numIter, oSF, verbose, ramPointsMod, alpha, beta)
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
    %   oSF:                _____ (SDC)
    %   verbose:            _____ (SDC)
    %   ramPointsMod:       _____
    %   alpha:              gridding oversampling ratio (for grid3 routine)
    %   beta:               expansion factor ratio: alpha_x/alpha_z, where alpha_x = alpha_y (grid3)
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.

    
    %% add sdc3 and grid3 paths
    
    %addpath('.+reconstruction/sdc3');
    %addpath('.+reconstruction/grid3');

    
    %% respiration mode
    
    % specify respiration mode (inspiration/expiration)
    if strfind(trajPath, 'inspiration')
        respMode = 'inspiration';
    elseif strfind(trajPath, 'expiration')
        respMode = 'expiration';
    else
        respMode = 'notspec';
    end

    
    %% setup calculated parameter(s)/other local variables
    
    realNumPoints = numPoints - numPointsShift;
    DCFPath = fullfile(outPath, strcat('DCF_', respMode));
     
    
    %% load trajectory information
    
    fileID = fopen(trajPath);

    trajData = squeeze(fread(fileID, inf, 'double'));
    fclose(fileID);
%     fileInfo = dir(trajPath);
%     numProj = ceil(fileInfo.bytes / 1024)
%     disp(trajPath)
%     whos
    % reshape trajectory data                             ||
    trajData = reshape(trajData, 3, numPoints, []); % CHANGED B/C OF SHAPE MISMATCH [changed back]    NEW
    numProj = size(trajData, 3)                                                                     %   NEW
                                                        % ||
    % cut ending poins along one spoke
    coords = trajData(:, 1:realNumPoints, (leadingCutProj + 1):numProj - endingCutProj);
    
    r = sqrt(coords(1, realNumPoints, :) .^ 2 + coords(2, realNumPoints, :) .^ 2 ...
        + coords(3, realNumPoints, :) .^2);
    coords = coords ./ max(r(:)) / 2;
    
    disp('Generating DCF');
     
    
    %% SDC calculations
    
    disp(outPath)
    
    %addpath('multi-te/+reconstruction/sdc3/');
    import reconstruction.sdc3.sdc3_MAT;
    
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
    
    import reconstruction.multitegrid;
    
    disp('Reconstructing...');
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
        numTE, ...
        fidPath, ...
        trajPath, ...
        numThreads ...
    );
end


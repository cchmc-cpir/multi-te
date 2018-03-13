function multitegrid(numPoints, numProj, ramPoints, fidPoints, leadingCutProj, endingCutProj, ...
    numPointsShift, respMode, outPath, alpha, numTE, fidPath, trajPath, numThreads)
    %MULTITERECON Leverages 3D gridding functionality provided by the 'grid3' package by Nick Zwart.
    %   Designed to run from 'multitesdc'. Transforms k-space data to Cartesian space to complete
    %   image reconstruction. Designed for data acquired with multiple echo times.
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.
    
    
    %% setup calculated parameters
    
    realNumPoints = numPoints - numPointsShift; % actual number of points encoded
    realNumProj = numProj - leadingCutProj - endingCutProj;
    
    
    %% read trajectory information
    
    fileID = fopen(trajPath);
    trajData = squeeze(fread(fileID, inf, 'double'));
    fclose(fileID);
    
    % reshape trajectory data
    trajData = reshape(trajData, [3, numPoints, numProj * 3]);
    
    % cut ending poins along one spoke
    coords = trajData(:, 1:realNumPoints, (leadingCutProj + 1):numProj - endingCutProj);
    
    r = sqrt(coords(1, realNumPoints, :) .^ 2 + coords(2, realNumPoints, :) .^ 2 ...
        + coords(3, realNumPoints, :) .^2);
    coords = coords ./ max(r(:)) / 2;
    
    clear trajData r;
    
    
    %% read pre-weights
    
    DCFPath = fullfile(outPath, strcat('DCF_', respMode));
    fileID = fopen(DCFPath);
    DCFData = squeeze(fread(fileID, inf, 'float32'));
    fclose(fileID);
    % disp(length(DCFData))
    % disp(realNumPoints)
    % disp(realNumProj)
    DCFData = reshape(DCFData, [realNumPoints, realNumProj]);
    
    
    
    %% read k-space data
    
    fileID = fopen(fidPath);
    kData = squeeze(fread(fileID, inf, 'int32')); % step-like scaling depending on 'SW_h'
    fclose(fileID);
    
    allData = reshape(kData, [2, fidPoints, numTE, numProj]);
    
    clear kData;
    
    
    for n = 1:numTE
    
        % remove singleton dimensions from the data
        data = squeeze(allData(:, (numPointsShift + 1):numPoints, n, ...
            (leadingCutProj + 1):(numProj - endingCutProj)));
        
        %% grid3 routine

        effMatrix = (realNumPoints - ramPoints) * 2 * alpha;
        gridData = grid3_MAT(data, coords, DCFData, effMatrix, numThreads);
        
        clear data;


        %% rolloff kernel

        % import grid3_MAT from grid3 package
        import reconstruction.grid3.grid3_MAT;
        
        % should fix the variable assignments here... not good to have them in this file
        delta = [1.0, 0.0];
        k_not = [0.0, 0.0, 0.0];
        DCF_not = 1.0;
        
        rolloffKern = grid3_MAT(delta', k_not', DCF_not, effMatrix, numThreads);

        clear delta k_not DCF_not;
        
        
        %% FFT into image space

        % change to complex, FFT, then shift
        
        % DATA
        gridData = squeeze(gridData(1, :, :, :) + 1j * gridData(2, :, :, :));
        gridData = fftn(gridData);
        gridData = fftshift(gridData, 1);
        gridData = fftshift(gridData, 2);
        gridData = fftshift(gridData, 3);
        
        % ROLLOFF
        rolloffKern = squeeze(rolloffKern(1, :, :, :) + 1j * rolloffKern(2, :, :, :));
        rolloffKern = fftn(rolloffKern);
        rolloffKern = fftshift(rolloffKern, 1);
        rolloffKern = fftshift(rolloffKern, 2);
        rolloffKern = fftshift(rolloffKern, 3);
        rolloffKern = abs(rolloffKern);


        %% apply rolloff kernel and crop

        gridData(rolloffKern > 0) = gridData(rolloffKern > 0) ./ rolloffKern(rolloffKern > 0);
        xs = floor(effMatrix / 2 - effMatrix / 2 / alpha) + 1;
        xe = floor(effMatrix / 2 - effMatrix / 2 / alpha);
        gridData = gridData(xs:xe, xs:xe, xs:xe);


        %% write output to file

        dataOut = rot90(gridData, 2);

        fileID = fopen(fullfile(outPath, strcat('reconstructed_img_', respMode, '.raw')), 'w');
        fwrite(fileID, dataOut, 'float32');
        fclose(fileID);
    
        
    end
end


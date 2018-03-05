function multitesdc(fidPath, trajPath, numTE, numProj, numPoints, fidPoints, numPointsShift, leadingCutProj, endingCutProj)
    %MULTITESDC Multi-TE sampling density compensation.
    %   Appropriately weights non-uniformly sampled k-space data to ensure accurate image
    %   reconstruction after interpolation onto a Cartesian grid. For use with data from interleaved
    %   multi-TE UTE sequences.
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.

    % specify respiration mode (inspiration/expiration)
    if strfind(fidFile, 'inspiration')
        respMode = 'inspiration';
    elseif strfind(fidFile, 'expiration')
        respMode = 'expiration';
    else
        respMode = 'notspec'
    end

    realNumPoints = numPoints - numPointsShift;
    realNumProj = numProj - leadingCutProj - endingCutProj;
     
    
    %% SDC calculations
    DCF = sdc3_MAT(___, ___, ___, ___, ___);
    DCF = single(DCF); % float32

    %% write output DCF
    temp = DCF;
    fileID = fopen(fullfile)
    clear temp;
    clear DCF;
    clear crds;
    clear r;
    clear trajFileName;
    clear DCFFilename;

    %% end reconstruction

    disp(['Reconstructing ', newFilePath])
    grid3_multiTE(___, ___, ___, ___, ___, ___, ___, ___)
end


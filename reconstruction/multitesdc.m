function multitesdc(fidFile, numTE, numProj, numPoints, fidPoints, numPointsShift)
    %MULTITESDC Multi-TE sampling density compensation.
    %   Appropriately weights non-uniformly sampled k-space data to ensure accurate image
    %   reconstruction after interpolation onto a Cartesian grid. For use with data from interleaved
    %   multi-TE UTE sequences.
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.
    
    
    if strfind(fidFile, 'inspiration')
        respMode = 'inspiration';
    elseif strfind(fidFile, 'expiration')
        respMode = 'expiration';
    else
        respMode = 
    end
    
    
    
end


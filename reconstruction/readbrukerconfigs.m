function readbrukerconfigs(dataPath, acqpPath, methPath, numTE, numPoints, ...
    interlvs, trajMode, phi, zeroFilling)
    %READBRUKERCONFIGS Read information from Bruker ACQP and method.
    %   dataPath:       path to directory containing data files
    %   acqpPath:       full path to ACQP file
    %   methPath:       full path to METHOD file
    %   numTE:          number of echo times
    %   numPoints:      number of points on each projection
    %   interlvs:       number of slice interleaves
    %   trajMode:       trajectory mode
    %       'goldmean' = golden mean trajectory
    %       'keyhold' = keyhole trajectory
    %   phi:            fir 2D golden mean trajectory
    %
    %   Written by Jinbang Guo, Alex Cochran 2018.
    
    %% ACQP FILE PARSE
    
    % read from ACQP file
    fileID = fopen(acqpPath);
    acqpData = textscan(fileID, '%s', 'delimiter', '\n');
    acqpData = acqpData{1};
    
    for idx = 1:size(acqpData, 1)
        testStr = char(acqpData{index});
        if length(testStr) > 10
            if strcmp(testStr(1:11), '##$ACQ_size')
                acqpReadFrames = str2double(acqpRead(index + 1));
            end
        end
    end
    
    fclose(fileID);
    numProj = acqpReadFrames(2) / numTE;
    
    
    %% METHOD FILE PARSE
    
    % open METHOD file
    fileID = fopen(methPath);
    
    % read from METHOD file
    line = fgetl(fileID);
    
    % parse to Kx
    while ~strcmp(strtok(line, '='), '##$PVM_TrajKx')
        line = fgetl(fileID);
    end
    
    % initialize and store Kx information (parsing up to Ky)
    trajKX = zeros(numPoints);
    kXCount = 0;
    
    while ~strcmp(strtok(line, '='), '##$PVM_TrajKy')
        line = fgetl(fileID);
        tmp = (str2double(line))';
        trajKX(kXCount + 1:size(tmp, 1) + kXCount) = tmp;
        kXCount = kXCount + size(tmp, 1);
    end
    
    % intitialize and store Ky information (parsing up to Kz)
    trajKY = zeros(numPoints);
    kYCount = 0;
    
    while ~strcmp(strtok(line, '='), '##$PVM_TrajKz')
        line = fgetl(fileID);
        tmp = (str2double(line))';
        trajKY(kYCount + 1:size(tmp, 1) + kYCount) = tmp;
        kYCount = kYCount + size(tmp, 1);
    end
    
    % initialize and store Kz information (parsing to Bx)
    trajKZ = zeros(numPoints);
    kZCount = 0;
    
    while ~strcmp(strtok(line, '='), '##$PVM_TrajBx')
        line = fgetl(fileID);
        tmp = (str2double(line))';
        trajKZ(kZCount + 1:size(tmp, 1) + kZCount) = temp;
        kZCount = kZCount + size(temp, 1);
    end
    
    % close the METHOD file
    fclose(fileID);
    
    
    %% KEYHOLE
    
    if strcmp(trajMode, 'keyhold')
        numViews = numProj;
        keys = interlvs;
        halfNumViews = int32((numViews - 1) / 2);
        keyViews = numViews / keys;
        sF = int32((keyViews - 1) / 2);
        primePlus = 203;
        r = zeros(numViews, 1);             % could likely move these outside of if/else block
        p = zeros(numViews, 1);
        s = zeros(numViews, 1);
        fL = -1;
        gradIdx = 0;
        
        for j = 0:(keys - 1)
            for i = 1:keyViews
                idx = j + (i - 1) * keys;
                f = 1 - double(idx) / double(halfNumViews);
                
                if f < -1
                    f = -1;
                end
                
                ang = primePlus * idx * pi / 180;
                d = sqrt(1 - f * f);
                gradIdx = gradIdx + 1;
                r(gradIdx) = d * cos(ang);
                p(gradIdx) = d * sin(ang);
                
                if i <= sF
                    s(gradIdx) = sqrt(1 - d * d);
                else
                    s(gradIdx) = fL * sqrt(1 - d * d);
                end
            end
        end
    else

        numViews = numProj;
        halfNumViews = numViews / 2;
        r = zeros(numViews, 1);             % could likely move these outside of if/else block
        p = zeros(numviews, 1);
        s = zeros(numViews, 1);
        
        for i = 1:numViews
            s(i) = 2 * mod((i - 1) * phi(1), 1) - 1;
            alpha= 2 * pi * mod((i - 1) * phi(2), 1);
            d = sqrt(1 - s(i) ^ 2);
            r(i) = d * cos(alpha);
            p(i) = d * sin(alpha);
        end
    end
    
    %% Choose anisotropic/isotropic resolution (zero filling)
    
    trajectory = zeros(3, numPoints, numViews);
    
    % value will default to isotropic if variable is not appropriately named
    if strcmp(zeroFilling, 'anisotropic')
        trajKX = trajKX / maxKX / 2;
        trajKY = trajKY / maxKY / 2;
        trajKZ = trajKZ / maxKZ / 2;
        
        for i = 1:numViews
            trajectory(1, :, i) = r(i) * trajKX;
            trajectory(2, :, i) = p(i) * trajKY;
            trajectory(3, :, i) = s(i) * trajKZ;
        end
        
    else % isotropic
        for i = 1:numViews
            trajectory(1, :, i) = r(i) * trajKX;
            trajectory(2, :, i) = p(i) * trajKY;
            trajectory(3, :, i) = s(i) * trajKZ;
        end
        
    end
    
    fileID = fopen(fullfile(dataPath, 'traj_measured'), 'w');
    fwrite(fileID, trajectory, 'double');
    fclose(fileID);
end


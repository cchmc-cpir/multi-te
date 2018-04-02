function t2starmap(imageSize, sliceRange, imagePaths, outPath, maskMode, mapThreshHigh, ...
        mapThreshLow, respMode)
    %T2STARMAP Produces maps of reconstructed MR images according to T2* values across them.
    %   Reconstructed MR images in *.raw format are mapped according to the T2* values at each image
    %   pixel. High and low thresholds are used to limit the high and low values of the map. A
    %   custom colormap is also used in order to produce the maps with black backgrounds for
    %   increased figure contrast.
    %
    %   This function currently operates by performing a comparison between two images taken at
    %   different echo times. Because of this, it requires two image files be loaded.
    
    % Separate filename from path and store
    [~, imageFilename2] = fileparts(imagePaths{2});
    
    % Extract echo times from reconstructed images
    filePath1 = imagePaths{1};
    filePath1(strfind(filePath1, '_')) = [];
    filePath2 = imagePaths{2};
    filePath1(strfind(filePath1, '_')) = [];
    
    key = respMode;
    
    index1 = strfind(filePath1, key);
    index2 = strfind(filePath2, key);
    
    TE1 = sscanf(filePath1(index1(1) + length(key):end), '%g', 1);
    TE2 = sscanf(filePath2(index2(1) + length(key):end), '%g', 1);
    disp('MAPPING TE VALUES:')
    disp(TE1)
    disp(TE2)
    
    % Preallocate memory for the image
    imageMatrix = zeros(imageSize(1), imageSize(2), imageSize(3), 2);
    
    disp(imagePaths
    % Load the *.raw image files and collate
    for idx = 1:length(imagePaths)
        fileID = fopen(imagePaths{idx});
        loadingImage = fread(fileID, 'real*4');
        fclose(fileID);
        loadingImage = reshape(loadingImage, imageSize);
        rotatedImage = rot90(loadingImage, 3);
        imageMatrix(:, :, :, idx) = rotatedImage;
    end

    MR1 = imageMatrix(:, :, sliceRange, 1);
    MR2 = imageMatrix(:, :, sliceRange, 2);
    
    % Load binary mask OR manually segment binary mask now
    switch maskMode
        case 'load'
            error('Binary mask loading is not implemented yet.');
        case 'now'
            binMask = mansegment(MR2);
    end
    
    
    %% Calculate T2* and threshold
    
    % Calculate T2*
    T2Star = (TE2 - TE1) ./ log(MR1 ./ MR2);
    
    % Threshold T2* array
    T2Star(T2Star > mapThreshHigh) = mapThreshHigh;
    T2Star(T2Star < mapThreshLow) = mapThreshLow;


    %% Formatting and output
    
    % Custom colormap
    colormap('jet');
    customJet = colormap;
    
    % Display image
    mapFigure = figure('Name', strcat('T2* Map: ', imagePaths));
    imagesc(T2Star(:, :, 1) .* binMask);

    % Change colormap of displayed image
    customJet(1, :) = 0;
    colormap(customJet);
    
    % Save figure and associated data
    savefig(mapFigure, fullfile(outPath, strcat('t2starmap_', imageFilename2)));
end


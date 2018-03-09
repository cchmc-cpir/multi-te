%{
    T2* Mapping of Doxycycline-Induced Fibrosis in Mice
    Written by Matt Freeman, Alex Cochran, Zackary I. Cleveland
%}

clear; close all; clc;

%% config

echoTimes = [0.080; 0.400];
imageSize = [128, 128, 128];
sliceRange = 70;


%% filename definitions

% day 0 raw images
week0 = {
    'RAW_BT4_03_Day0_200us.raw', ...
    'RAW_BT4_04_Day0_400us.raw'
};

% week 4 raw images
week4 = {
    'RAW_BT4_13_4weeksOnDox_200us.raw', ...
    'RAW_BT4_14_4weeksOnDox_400us.raw'
};

% week 8 raw images
week8 = {
    'RAW_BT4_12_4weeksOnDox_080us.raw', ...
    'RAW_BT4_24_8weeksOnDox_400us.raw'
};

allFiles = [week0; week4; week8];


for n = size(allFiles, 1)
    for m = size(allFiles, 2)
        %% load files

        % preallocate for speed
        imageMatrix = zeros(128, 128, 128, length(fileNames));

        for indexScan = 1:size(allFiles
            fileID = fopen(char(fileNames(indexScan)), 'r');
            loadingImage = fread(fileID, 2097152, 'real*4');
            fclose(fileID);
            loadingImage = reshape(loadingImage, imageSize);
            rotatedImage = rot90(loadingImage, 3);
            imageMatrix(:, :, :, indexScan) = rotatedImage;
        end

        % separate images of interest and slices from full matrix
        MR1 = imageMatrix(:, :, sliceRange, 1);
        MR2 = imageMatrix(:, :, sliceRange, 2);


        %% manually segment lung volume from rest of image
        colormap gray

        MRMask = ManSegment(MR2);  % segment for the longest echo time only


        %% calculate T2* values for each element of the image matrix

        T2 = (echoTimes(2) - echoTimes(1))./log(MR1./MR2); 

        % set upper and lower T2* thresholds to trim the data range
        T2(T2 > 5) = 5;
        T2(T2 < 0) = 0;


        %% display T2* map

        % custom colormap
        colormap jet;
        customJet = colormap;

        % display
        imagesc(T2(:,:,1).*MRMask)
        customJet(1, :) = 0;
        colormap(customJet)
    end
end

%{
    Multi-Image Displaying Subroutine

    This is a simple script designed to plot out a series of images side-by-side to avoid multiple
    redundant executions of a larger program. It is not intended for any intensive data analysis.

    Written by Alex Cochran, 2018
%}


%% config

clear; close all; clc;


%% file selection

sliceIndices = [64, 65, 66];
imageSize = [128, 128, 128];


%% image reading and pre-processing

fileNames = {
    'RAW_BT4_03_Day0_200us.raw', ...
    'RAW_BT4_13_4weeksOnDox_200us.raw', ...
    'RAW_BT4_23_8weeksOnDox_200us.raw'
};

disp(fileNames)

% preallocate for speed
imageMatrix = zeros(128, 128, 128, length(fileNames));

for indexScan = 1:length(fileNames)
    fileID = fopen(char(fileNames(indexScan)), 'r');
    loadingImage = fread(fileID, 2097152, 'real*4');
    fclose(fileID);
    loadingImage = reshape(loadingImage, imageSize);
    rotatedImage = rot90(loadingImage, 3);
    imageMatrix(:, :, :, indexScan) = rotatedImage;
end

MR1 = imageMatrix(:, :, :, 1);
MR2 = imageMatrix(:, :, :, 2);
MR3 = imageMatrix(:, :, :, 3);

figure(1)
colormap gray
imagesc(MR1(:, :, 66))

figure(2)
colormap gray
imagesc(MR2(:, :, 66))

figure(3)
colormap gray
imagesc(MR3(:, :, 66))















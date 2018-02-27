%{
    T2* Mapping of Doxycycline-Induced Fibrosis in Mice
    Written by Matt Freeman, Alex Cochran
%}

%clear; close all; clc;

%% config

% parameters
%echoTimes = [0.200; 0.400];
echoTimes = [0.200; 0.400];
imageSize = [128, 128, 128];
SliceRange = 67; %ZIC can be a single value or a range of slices

%% filename definitions

% day 0 raw images
fileNames = {
    'RAW_BT4_03_Day0_200us.raw', ...
    'RAW_BT4_04_Day0_400us.raw'
};

% week 4 raw images
% fileNames = {
%     'RAW_BT4_13_4weeksOnDox_200us.raw', ...
%     'RAW_BT4_14_4weeksOnDox_400us.raw'
% };

% week 8 raw images
% fileNames = {
%     'RAW_BT4_23_8weeksOnDox_200us.raw', ...
%     'RAW_BT4_24_8weeksOnDox_400us.raw'
% };


%% load files

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

% separate images of interest and slices from full matrix
% MR1 = imageMatrix(:, :, 67:68, 1);
% MR2 = imageMatrix(:, :, 67:68, 2);

MR1 = imageMatrix(:, :, SliceRange, 1);
MR2 = imageMatrix(:, :, SliceRange, 2);

% manually segment lung volume ROIs for binary masking
colormap gray

% MR1Mask = ManSegment(MR1);
% MR2Mask = ManSegment(MR2);

%%
%%
MRMask = ManSegment(MR2);  % ZIC: You only need a single mask for each slice, 
                           % because there were acquired at the same time.
                           % Life is easier if you segment the long TE
                           % image because the contrast between parenchyma
                           % and denser tissue is greater.
%%
%%
% 
% % separate just to one slice (later, edit ManSegment to be able to handle just one slice)
% MR1 = MR1(:, :, 1);
% MR1Display = MR1;
% MR2 = MR2(:, :, 2);
% MR2Display = MR2;
% 
% 
% %% display unmasked magnitude images
% figure(1)
% colormap gray
% subplot(1, 2, 1)
% imagesc(MR1Display)
% subplot(1, 2, 2)
% imagesc(MR2Display)
% 
% 
% %% image masking
% 
% % multiply binary ROI masks by the image arrays
% MR1 = MR1 .* MR1Mask(:, :, 1);
% MR2 = MR2 .* MR2Mask(:, :, 2);
% 
% 
% %% generate T2* map
% 
% % preallocate T2* map array for speed

%%
%%
% T2Array = zeros(128,128, length(fileNames)); % ZIC: if you bothered semgenting it, 
                                             % you might as well generate
                                             % the data. However, there is
                                             % not need for the loop below.
                                             % Element by element math is
                                             % faster.
%%
%%
% % calculate T2* values by linear fitting of the log of exponential decay using parallel pool
% tic
% parfor index = 1:(numel(MR1))
%     T2Array(index) = (0.400 - 0.200) / log(MR1(index) ./ MR2(index))
% end
% toc
%%
%%
T2 = (echoTimes(2) - echoTimes(1))./log(MR1./MR2); % ZIC: Easier to 
                                                        % just to the entire array

%%
%%
% 
% % reshape T2 matrix
% T2 = reshape(T2Array, [128, 128, 1]); %ZIC: No need to reshape if with
                                        % the current matric element math.
T2(T2 > 3) = 3;
T2(T2 < 0) = 0;

% custom colormap
colormap jet;
customJet = colormap;

%imslice(T2.*MRMask)
imagesc(T2(:,:,1).*MRMask)
customJet(1, :) = 0;
colormap(customJet)

% 
% % display image
% figure(2)
% imagesc(T2)
% colorbar
% title(fileNames)
% axis square
% axis off
% 
% 
% %% image display
% 
% T2(T2 > 5) = 5;
% T2(T2 < 0) = 0;
% 
% %%
% % display map images
% rows = 1; cols = 2;
% gapH = 0.00; gapW = 0.00; gapB = 0.00; gapT = 0.00; gapL = 0.00; gapR = 0.00;
% tsp = tight_subplot(rows, cols, [gapH gapW], [gapB gapT], [gapL gapR]);
% 
% % define area for display
% displayMatrix = T2(20:110, 23:108, 66:67);
% 
% for imageIndex = 1:2
%     axes(tsp(imageIndex));
%     imagesc(displayMatrix(:, :, imageIndex)); colormap customJet; axis square; axis off;
% end
% 
% set(gcf, 'Position', [50 50 1420 720]);
% 
% 
% 
% 
% 
% 









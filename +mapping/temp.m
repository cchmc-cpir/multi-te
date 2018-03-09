%{
    T2* Mapping of Doxycycline-Induced Fibrosis in Mice
    Written by Matt Freeman, Alex Cochran
%}


%% config

fileNames = {
    %'RAW_BT1_01_Day0_alpha14.raw', ...
    %'RAW_BT1_02_Day0_080us.raw', ...
    %'RAW_BT1_03_Day0_200us.raw', ...
    %'RAW_BT1_04_Day0_400us.raw', ...
    %'RAW_BT1_11_4weeksOnDox_alpha14.raw', ...
    'RAW_BT1_12_4weeksOnDox_080us.raw', ...
    'RAW_BT1_13_4weeksOnDox_200us.raw', ...
    'RAW_BT1_14_4weeksOnDox_400us.raw', ...
    %'RAW_BT1_21_8weeksOnDox_alpha14.raw', ...
    %'RAW_BT1_22_8weeksOnDox_080us.raw', ...
    %'RAW_BT1_23_8weeksOnDox_200us.raw', ...
    %'RAW_BT1_24_8weeksOnDox_400us.raw', ...
    %'RAW_BT1_32_7weeksOffDox_080us.raw', ...
    %'RAW_BT1_33_7weeksOffDox_200us.raw', ...
    %'RAW_BT1_34_7weeksOffDox_4000us.raw'
    };

echoTimes = [0.080; 0.200; 0.400];
imageSize = [128, 128, 128];


%% load files

% preallocate for speed
imageMatrix = zeros(128, 128, 128, length(fileNames));

for indexScan = 1:length(fileNames)                         % updated to read any number of files
    fileID = fopen(char(fileNames(indexScan)), 'r');
    loadingImage = fread(fileID, 2097152, 'real*4');        % size & precision choices?
    fclose(fileID);
    loadingImage = reshape(loadingImage, imageSize);
    rotatedImage = rot90(loadingImage, 3);
    imageMatrix(:, :, :, indexScan) = rotatedImage;
end

MR1 = imageMatrix(:, :, :, 1);
MR2 = imageMatrix(:, :, :, 2);                              % find a way to do this dynamically
MR3 = imageMatrix(:, :, :, 3);


%% image masking

% preallocate binary mask data structures
binaryMask = zeros(128, 128, 128);

% generate binary mask
binaryMask(MR2 > 20000) = 1;
binaryMask(MR2 > 60000) = 0;

% create morphological structuring element
se = strel('disk', 2, 0);

% erosions and dilations with the structuring element
erodedMask=imerode(binaryMask,se);
dilatedMask=imdilate(erodedMask,se);
binaryMask=dilatedMask;

dilatedMask=imdilate(binaryMask,se);
erodedMask=imerode(dilatedMask,se);
binaryMask=erodedMask;

% multiply by the binary mask to mask the T2 image
T2Unmasked = T2;
T2 = T2Unmasked .* binaryMask;


%% display images after binary mask

% display map images
rows = 4; cols = 7;
gapH = 0.00; gapW = 0.00; gapB = 0.00; gapT = 0.00; gapL = 0.00; gapR = 0.00;
tsp = tight_subplot(rows, cols, [gapH gapW], [gapB gapT], [gapL gapR]);

T2(T2 > 10) = 10;
T2(T2 < 0) = 0;

displayMatrix = T2(20:110, 23:108, 53:80);

for index = 1:28
    axes(tsp(index));
    imagesc(displayMatrix(:,:,index)); colormap hot; axis square; axis off;
end

set(gcf, 'Position', [50 50 1420 720]);


%% generate T2* map

% preallocate matrix for pixel-by-pixel T2* calculation
T2Array = zeros(128^3, 1);

% calculate T2* values by linear fitting of the log of exponential decay using parallel pool
tic
parfor index = 1:(numel(imageMatrix) / 3)
    s = [MR1(index); MR2(index); MR3(index)];
    p = polyfit(echoTimes, log(s), 1);
    T2Array(index) = 1 / (-p(1));
end
toc

% reshape T2 matrix
T2 = reshape(T2Array, imageSize);


%% image display

% display map images
rows = 4; cols = 7;
gapH = 0.00; gapW = 0.00; gapB = 0.00; gapT = 0.00; gapL = 0.00; gapR = 0.00;
tsp = tight_subplot(rows, cols, [gapH gapW], [gapB gapT], [gapL gapR]);

% eliminate anomalies
T2(T2 > 10) = 10;
T2(T2 < 0) = 0;

displayMatrix = T2(20:110, 23:108, 53:80);

for index = 1:28
    axes(tsp(index));
    imagesc(displayMatrix(:,:,index)); colormap hot; axis square; axis off;
end

set(gcf, 'Position', [50 50 1420 720]);





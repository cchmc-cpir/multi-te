function mask = ManSegment(img);
% function to segment ROIs from an image
%
szimg = size(img);
mask = zeros(szimg);

if length(szimg)==2
    indx =1;
else
    indx = szimg(3);
end
%for slice_num = 1:szimg(3)
for slice_num = 1:indx
   
    ROICount = 1;
    slice_mask = zeros(szimg(1),szimg(2));

    while ROICount == 1

        imshow(img(:,:,slice_num), 'InitialMagnification', 1000, 'DisplayRange', []);
        title(gca,['Image Slice ', int2str(slice_num)])  
        %Construct a quest with three options
        choice = questdlg('Is there a stucture of interest present?', ...
        'ROI Choice','Yes','No','No');

        % Handle response
        switch choice
            case 'Yes'
            disp([choice '. Segmenting region containing structure of interest.'])
            BW = roipoly;
            roi_mask = ones(szimg(1),szimg(2))-BW;
            slice_mask = slice_mask + BW;
            img(:,:,slice_num)= roi_mask.*double(img(:,:,slice_num));  

            case 'No'    
            ROICount = 0;       
            break
        end 
     end

    close
    
    % generate mask for current slice
    slice_mask(slice_mask>0)=1; 
    mask(:,:,slice_num) = slice_mask;
    
    %if slice_num == szimg(3)
    if slice_num == indx
        disp('Segmenting complete.'); 
    end
    
end
end


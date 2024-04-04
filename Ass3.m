clear;
clc;
close all;
% initialization of the parameters for the function
numFrame=18;
position=cell(1,numFrame);
%initialize the image array
frame=zeros(512,512,numFrame-1);

denoisedFrame=zeros(512,512,numFrame);
denoisedFrame2=zeros(512,512,numFrame);
comparison=zeros(1, 12,numFrame);
L = zeros(512,512,18);
coord = zeros(12,2,18);
objectCrop = cell(numFrame,12);
prevObjects = cell(numFrame-1,12);


for i=1:numFrame
    frame(:,:,i)=imread("Simulate_movie_hw2.tif",i);
    figure(i)
    denoisedFrame(:,:,i)=medfilt2(frame(:,:,i), [5,5]);
    % h = [-1 -1 -1;-1 8 -1;-1 -1 -1];
    % denoisedFrame2(:,:,i) = imfilter(denoisedFrame(:,:,i),h);
    denoisedFrame2(:,:,i) = imbinarize(denoisedFrame(:,:,i)./255, 'global');
    
    imshow(denoisedFrame2(:,:,i))
    center(:,:,i) = regionprops(denoisedFrame2(:,:,i), 'centroid');
    s = regionprops(logical(denoisedFrame2(:,:,i)), 'Centroid');
    bounding = regionprops(logical(denoisedFrame2(:,:,i)), 'BoundingBox');
    centroids(:,:,i) = cat(1,s.Centroid);
    hold on
    plot(centroids(:,1,i),centroids(:,2,i),'*b')
    hold off
    L(:,:,i) = bwlabel(logical(denoisedFrame2(:,:,i)),8);

    
    for j = 1:height(centroids)
        objectCrop{i,j} = num2cell(imcrop(denoisedFrame2(:,:,i), bounding(j,:).BoundingBox));
        
        if i > 1 
            prevObjects{i,j} = objectCrop{i-1,j};

                for k = 1:height(centroids)
                    size1 = size(cell2mat(objectCrop{i,k}));
                    size0 =size(cell2mat(prevObjects{i,j}));
                    padded1 = padarray(cell2mat(objectCrop{i,k}), ceil(([15 15]-size1)/2) , 0,'pre');
                    padded1= padarray(padded1, floor(([15 15]-size1)/2), 0,'post');
                    padded2 = padarray(cell2mat(prevObjects{i,j}), ceil(([15 15]-size0)/2) , 0,'pre');
                    padded2 = padarray(padded2, floor(([15 15]-size0)/2), 0,'post');
                    comparison(k,j,i) = corr2(padded1,padded2);
                end
        end
    end



end



%for finding peaks
% exampleFrame=denoisedFrame(:,:,1);
% p=FastPeakFind(exampleFrame);
% imagesc(exampleFrame); hold on;
% plot(p(1:2:end),p(2:2:end),'r+');
% position=[p(1:2:end),p(2:2:end)];

% frame_exp=frame(:,:,1);
% figure;
% imshow(uint8(frame(:,:,1)));
% figure;
% imshow(uint8(denoisedFrame(:,:,1)));
% figure;
% imshow(uint8(frame(:,:,2)));
% figure;
% imshow(uint8(denoisedFrame(:,:,2)))
% 








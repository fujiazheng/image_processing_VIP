tic
clear;
clc;
close all;
% initialization of the parameters for the function
numFrame=18;
position=cell(1,numFrame);
%initialize the image array
frame=zeros(512,512,numFrame-1);
%index variable copy the index in different frames
index=zeros(numFrame,12);

numObjects = 12;

denoisedFrame=zeros(512,512,numFrame);
denoisedFrame2=zeros(512,512,numFrame);
comparison=zeros(1, 12,numFrame);
L = zeros(512,512,18);
coord = zeros(12,2,18);
objectCrop = cell(numFrame,12);
prevObjects = cell(numFrame-1,12);
GT_table = readtable("ground_truth_positions.xlsx");

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
    ss = regionprops(logical(denoisedFrame2(:,:,i)),'BoundingBox');
    sizes(:,:,i) = cat(1,ss.BoundingBox);
    centroids(:,:,i) = cat(1,s.Centroid);


    % hold on
    % plot(centroids(:,1,i),centroids(:,2,i),'*b')
    % plot(table2array(GT_table(i*1:18:216,4)),table2array(GT_table(i*1:18:216,3)), '*r')
    % hold off
    L(:,:,i) = bwlabel(logical(denoisedFrame2(:,:,i)),8);

    
    for j = 1:height(centroids)
        objectCrop{i,j} = num2cell(imcrop(denoisedFrame2(:,:,i), bounding(j,:).BoundingBox));
        
        if i == 1
            order = [2, 5, 6, 8, 10, 9, 7, 12, 11, 4, 3, 1];
            orderedCentroids(order,:,i) = centroids(:,:,i);
            index(i,j)=j;
            list = orderedCentroids;
        end
        IDvector(:,:,i) = horzcat(centroids(:,:,i),sizes(:,3:4,i)); % create ID vector with centroids (x,y pos) and sizes (x,y pos of bounding box and x,y size)
        if i > 1 
        %% Compare the distance
        
            for k = 1:height(centroids)
                dist(j,k,i)= sqrt((centroids(j,1,i)-centroids(k,1,i-1)).^2 + (centroids(j,2,i)-centroids(k,2,i-1)).^2);
                oldIDobject = IDvector(k,:,i-1);
                newIDobject = IDvector(j,:,i);
                temp = corrcoef(newIDobject,oldIDobject);
                correlation_coeffs(k,j,i) = temp(1,2);
                k=find(correlation_coeffs(j,:,i)==max(correlation_coeffs(j,:,i)))
                
            end
            index(i,j)=index(i-1,k);
            
            
        %% Ignore
            % prevObjects{i,j} = objectCrop{i-1,j};
            %     for k = 1:height(centroids)
            %         size1 = size(cell2mat(objectCrop{i,k}));
            %         size0 =size(cell2mat(prevObjects{i,j}));
            %         padded1 = padarray(cell2mat(objectCrop{i,k}), ceil(([15 15]-size1)/2) , 0,'pre');
            %         padded1= padarray(padded1, floor(([15 15]-size1)/2), 0,'post');
            %         padded2 = padarray(cell2mat(prevObjects{i,j}), ceil(([15 15]-size0)/2) , 0,'pre');
            %         padded2 = padarray(padded2, floor(([15 15]-size0)/2), 0,'post');
            %         comparison(k,j,i) = corr2(padded1,padded2);
            %     end
        end
    end   
    if i>1
        orderedCentroids(order,:,i) = centroids(index(i,:),:,i);
        list = cat(1,list, orderedCentroids(:,:,i));
    end
end


%% Error
reorder = list(1:12:end,:);
for z=2:12
reorder = cat(1, reorder, list(z:12:end,:));
end

IDvector(:,:,i) = horzcat(orderedCentroids(:,:,i),sizes(:,3:4,i)); % create ID vector with centroids (x,y pos) and sizes (x,y pos of bounding box and x,y size)

errorX = ((reorder(:,1)-GT_table(:,4))./GT_table(:,4)).*100;
errorY = ((reorder(:,2)-GT_table(:,3))./GT_table(:,3)).*100;

% Initialize false negative count
false_negative_count = 0;
false_positive_count = 0;
distance = zeros(12,1);

% Iterate through each frame
for i = 1:numFrame
    % Iterate through each object in the current frame
    for j = 1:numObjects
        % Get position and size of the current object
        obj_x = IDvector(:, 1, i);
        obj_y = IDvector(:, 2, i);
        for k = 1:numObjects
            other_obj_x(k,1) = GT_table{1*i+(k-1)*18,4};
            other_obj_y(k,1) = GT_table{1*i+(k-1)*18,3};
        end
        % Iterate through other objects in the same frame
        % Compute distance between the objects
        distance(:,:,i) = sqrt((obj_x - other_obj_x).^2 + (obj_y - other_obj_y).^2);
        
        %Compute error
        error_pixel(:,:,i) = diag(distance(:,:,i));
        
        % Check if the distance exceeds a threshold
        

    end
end
if any(any(any(error_pixel > 2))) && (height(obj_y) > height(other_obj_y))
    % Increment false negative count and display message
    false_positive_count = height(other_object_y)-height(obj_y);
    disp(['There are ', num2str(false_positive_count), ' false positives']);
elseif any(any(any(error_pixel > 2))) && (height(obj_y) < height(other_obj_y))
    false_negative_count = false_negative_count +1;
    disp(['There are ', num2str(false_negative_count), ' false negatives']);
end
% Display total false negatives
disp(['Total false negatives: ', num2str(false_negative_count)]);


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
toc

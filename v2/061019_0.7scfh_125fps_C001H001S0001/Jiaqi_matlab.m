
Create the background.
workingDir = 'F:\Exp-data\09072019';
vfilename = '0718-backgournd-768_C001H001S0001.mp4';


%read the background.
workingDir = 'F:\Exp-data\09072019';
cd(workingDir);
clear refer_img
refer_img = imread('refer_img.jpg');
imshow(refer_img)

%write the images
cd(workingDir);
mkdir(workingDir,'images');

ii = 1;
vidObj = VideoReader(vfilename);
while hasFrame(vidObj)
img = readFrame(vidObj);
filename = [sprintf('%04d',ii) '.jpg'];
fullname = fullfile(workingDir,'images',filename);
imwrite(img,fullname)    % Write out to a JPEG file (img1.jpg, img2.jpg, etc.)
ii = ii+1;
end

%write the images- 768
cd(workingDir);
mkdir(workingDir,'images-c');

ii = 1;
vidObj = VideoReader(vfilename);
while hasFrame(vidObj)
img = readFrame(vidObj);
img = img(93:730,265:580);
filename = [sprintf('%04d',ii) '.jpg'];
fullname = fullfile(workingDir,'images-c',filename);
imwrite(img,fullname)    % Write out to a JPEG file (img1.jpg, img2.jpg, etc.)
ii = ii+1;
end

%write the images
cd(workingDir);
mkdir(workingDir,'images-c');

ii = 1;
vidObj = VideoReader(vfilename);
while hasFrame(vidObj)
img = readFrame(vidObj);
img = img(139:820,271:610);
filename = [sprintf('%04d',ii) '.jpg'];
fullname = fullfile(workingDir,'images-c',filename);
imwrite(img,fullname)    % Write out to a JPEG file (img1.jpg, img2.jpg, etc.)
ii = ii+1;
end


%get the names for all the images.
imageNames = dir(fullfile(workingDir,'images','*.jpg'));
imageNames = {imageNames.name}';

%for cutting the images. Need to be changed based on the picture.

% for 0610-hori
% ymin = 380;
% ymax = 712;
% xmin = 1;
% xmax = 632;

%for 0605
xmin = 1;
xmax = 896;
ymin = 224;
ymax = 644;

% for 768 PIV
%xmin = 93;
%xmax = 730;
%ymin = 265;
%ymax = 580;

% for 0907 Repeatability
xmin = 153;
xmax = 856;
ymin = 256;
ymax = 609;

refer_img = refer_img(xmin:xmax,ymin:ymax);

%create a reference image or background.
refer_img = zeros([xmax-xmin+1,ymax-ymin+1]);
n_frames = length(imageNames);

for ii = 1:n_frames
   img = imread(fullfile(workingDir,'images',imageNames{ii}));
   img = rgb2gray(img);
   img = img(xmin:xmax,ymin:ymax);
   refer_img = refer_img + double(img)/n_frames;
end
refer_img = uint8(refer_img);
imshow(refer_img);
imwrite(refer_img,'refer_img.jpg');

Write frames to the folder for all videos


workingDir = 'F:\Exp-data\09072019';
cd(workingDir);
vfile = dir('**/*.mp4');
vfilename = {vfile.name}';
vfilefolder = {vfile.folder}';
vfullname = cell(size(vfile));
for i = 1 : length(vfile)
    vfullname{i} = fullfile(vfilefolder{i},vfilename{i});
end

for i = 1:length(vfile)
    
cd(vfilefolder{i});
ii = 1;
vidObj = VideoReader(vfilename{i});
mkdir(vfilefolder{i},'images');

while hasFrame(vidObj)
img = readFrame(vidObj);
filename = [sprintf('%04d',ii) '.jpg'];
fullname = fullfile(vfilefolder{i},'images',filename);
imwrite(img,fullname);    % Write out to a JPEG file (img1.jpg, img2.jpg, etc.)
ii = ii+1;
end

end


Remove the background - Instance
%i =1;
%workingDir = vfilefolder{i};
workingDir = 'F:\Exp-data\09072019\1SCFH-1_C001H001S0001';
%vfilename1 = vfilename{i};

%cd(vfilefolder{i});
cd(workingDir)
imageNames = dir(fullfile(vfilefolder{i},'images','*.jpg'));
%imageNames = dir(fullfile(workingDir,'images-c','*.jpg'));
imageNames = {imageNames.name}';

ii = 176;
img = imread(fullfile(workingDir,'images',imageNames{ii}));
img = rgb2gray(img);
img = img(xmin:xmax,ymin:ymax);
imshow(img);
title('Original');
imshow(refer_img);
title('Background')
% modified_img = img;
% modified_img(img>250)=80;
% imshow(modified_img)
% title('modifided')
% img = medfilt2(modified_img);


clear reversed_img reversed_ref
reversed_img = abs(double(img)-255);
reversed_ref = abs(double(refer_img)-255);

index_enhance = reversed_ref>0;
reversed_ref(index_enhance) = reversed_ref(index_enhance)+5;%maybe this 20 is crutial
index_reduce = reversed_ref>255;
reversed_ref(index_reduce) = 255;


reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;


% check the first frame

clean_img = abs(reversed_clean-255);
clean_img = uint8(clean_img);
clean_img = imadjust(clean_img);


imshow(reversed_img)
title('Reversed Image')
imshow(reversed_ref);
title('Reversed_background')
imshow(reversed_clean);
title('Background-removed-reversed')

imshow(clean_img);
title('background removed')

%binarize the figure and fill the bubble. 
%filted_img = imgaussfilt(clean_img,1);
filted_img = clean_img;



imshow(filted_img);
title('filted');
reversed_img = abs(double(filted_img)-255);
imshow(reversed_img);
title('filted reversed')
indexrm = reversed_img<=2;
reversed_img1 = reversed_img;
reversed_img1(indexrm) = 0;
reversed_img1 = imfill(reversed_img1);
reversed_img1(1:618,:) = reversed_img1(1:618,:)-30;
indexpo = reversed_img1<0;
reversed_img1(indexpo) = 0;
Kmedian = medfilt2(reversed_img1(619:end,:));
reversed_img1(619:end,:) = Kmedian;

imshow(reversed_img1)
title('filted reversed1')
filted_img = uint8(abs(double(reversed_img1)-255));
bw_img = imbinarize(filted_img);
imshow(bw_img);
title('Binarized')

%aparently, no enhancing is better for sparger case.
 enhanced_fimg = adapthisteq(filted_img,'NumTiles',[30,15],'ClipLimit',0.9);
 imshow(enhanced_fimg);
 title('Enhanced after filting')
 bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
 imshow(bw_img);
 title('Binarize after enhancing')

bw_fill_img = imfill(~bw_img,'holes');
imshow(~bw_fill_img);
title('filled')

% %get the vof
% 
% %pre-process the reference_img
% %refer_img = imread('refer_img.jpg');
% %refer_img = rgb2gray(refer_img);
% reversed_ref = abs(double(refer_img)-255);
% index_enhance = reversed_ref>0;
% reversed_ref(index_enhance) = reversed_ref(index_enhance) + 20;
% index_reduce = reversed_ref>255;
% reversed_ref(index_reduce) = 255;


%for i = 1:length(vfile)
i =1;
cd(vfilefolder{i});
imageNames = dir(fullfile(vfilefolder{i},'images','*.jpg'));
imageNames = {imageNames.name}';
clear vof_img
vof_img = zeros([xmax-xmin+1,ymax-ymin+1]);
n_frames = length(imageNames);

%enhance refer image
reversed_ref = abs(double(refer_img)-255);
index_enhance = reversed_ref>0;
reversed_ref(index_enhance) = reversed_ref(index_enhance) + 20;%maybe this 20 is crutial
index_reduce = reversed_ref>255;
reversed_ref(index_reduce) = 255;

for ii = 1:n_frames

    
    img = imread(fullfile(vfilefolder{i},'images',imageNames{ii}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;
    



reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
    clean_img = abs(reversed_clean-255);
    clean_img = uint8(clean_img);
    clean_img = imadjust(clean_img);
    
    filted_img = imgaussfilt(clean_img,1);
    
    %enhanced_fimg = adapthisteq(filted_img);
    enhanced_fimg = filted_img;
    bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
    bw_fill_img = imfill(~bw_img,'holes');
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
    S = regionprops(CC,'Centroid');
    S1 = regionprops(CC,'Area');
    A = {S.Centroid}'; A = cell2mat(A);
    B = {S1.Area}'; B = cell2mat(B);
    %Sort the centroids based on y coordinates.
    [SortA,Index] = sort(A(:,2));
    A = A(Index,:);B = B(Index);
    
    if ii == 2
        for k = 1:length(B)
            %check +-2 pixels
            yupper = min(A(k,2)+2,xmax-xmin+1);
            ylower = max(0,A(k,2)-2);
            Index = SortA1>ylower & SortA1<yupper;
            % Assume a std for centroids of 0.5, a combined deviation
            Range = vecnorm(A1(Index,:)-A(k,:),2,2)./0.5 + abs(B1(Index)-B(k))./B1(Index);
            if min(Range)<5
                bw_fill_img = bw_fill_img - bwselect(bw_fill_img,A(k,1),A(k,2),8);
            end
        end
        A2 = A1;
        B2 = B1;
        SortA2 = SortA1;
    elseif ii >2
        for k = 1:length(B)
            %check +-2 pixels
            yupper = min(A(k,2)+2,xmax-xmin+1);
            ylower = max(0,A(k,2)-2);
            Index = SortA1>ylower & SortA1<yupper;
            Index1 = SortA2>ylower & SortA2<yupper;
            % Assume a std for centroids of 0.5, a combined deviation
            Range = vecnorm(A1(Index,:)-A(k,:),2,2)./0.5 + abs(B1(Index)-B(k))./B1(Index);
            Range1 = vecnorm(A2(Index1,:)-A(k,:),2,2)./0.5 + abs(B2(Index1)-B(k))./B2(Index1);
            if min(Range)<3
                bw_fill_img = bw_fill_img - bwselect(bw_fill_img,A(k,1),A(k,2),8);
            elseif min(Range1)<3
                bw_fill_img = bw_fill_img - bwselect(bw_fill_img,A(k,1),A(k,2),8);
            end
        end
        A2 = A1;
        B2 = B1;
        SortA2 = SortA1;
    end
    A1 = A;
    B1 = B;
    SortA1 = SortA;
    vof_img = vof_img + double(bw_fill_img)*255/n_frames;
    
end


vof_img = uint8(vof_img);
%final process the vof
%imshow(vof_img);
imwrite(vof_img,'reversed-vof4-nf.jpg')
reversed_vof = abs(double(vof_img)-255);
reversed_vof = uint8(reversed_vof);

imwrite(reversed_vof,'vof4-nf.jpg')
%imshow(reversed_vof)

%end

%A version with only 1 time series.

vofn = zeros(size(vfile));
for i = 1:length(vfile)
    
cd(vfilefolder{i});
imageNames = dir(fullfile(vfilefolder{i},'images','*.jpg'));
imageNames = {imageNames.name}';
clear vof_img
vof_img = zeros([xmax-xmin+1,ymax-ymin+1]);
n_frames = length(imageNames);

%enhance refer image
reversed_ref = abs(double(refer_img)-255);
index_enhance = reversed_ref>0;
reversed_ref(index_enhance) = reversed_ref(index_enhance) + 20;%maybe this 20 is crutial
index_reduce = reversed_ref>255;
reversed_ref(index_reduce) = 255;

%Deal with the first frame

ii=1;
 img = imread(fullfile(vfilefolder{i},'images',imageNames{ii}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;
    



reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
    clean_img = abs(reversed_clean-255);
    clean_img = uint8(clean_img);
    clean_img = imadjust(clean_img);
    
    filted_img = imgaussfilt(clean_img,1);
    enhanced_fimg = adapthisteq(filted_img);
    bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
    bw_fill_img = imfill(~bw_img,'holes');
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
    S = regionprops(CC,'Centroid');
    S1 = regionprops(CC,'Area');
    A = {S.Centroid}'; A = cell2mat(A);
    B = {S1.Area}'; B = cell2mat(B);
    %Sort the centroids based on y coordinates.
    [SortA,Index] = sort(A(:,2));
    A = A(Index,:);B = B(Index);
    [Height,Diameter] = size(refer_img);
    
    V_total = pi*Diameter.^2.*Height/4;
    vofn(i) = vofn(i) + (sum((B./pi).^(1.5)*4/3*pi)./n_frames)./V_total;
    
A1 = A;
    B1 = B;
    SortA1 = SortA;
    vof_img = vof_img + double(bw_fill_img)*255/n_frames;
    
for ii = 2:n_frames

    
    img = imread(fullfile(vfilefolder{i},'images',imageNames{ii}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;
    



reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
    clean_img = abs(reversed_clean-255);
    clean_img = uint8(clean_img);
    clean_img = imadjust(clean_img);
    
    filted_img = imgaussfilt(clean_img,1);
    enhanced_fimg = adapthisteq(filted_img);
    bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
    bw_fill_img = imfill(~bw_img,'holes');
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
    S = regionprops(CC,'Centroid');
    S1 = regionprops(CC,'Area');
    A = {S.Centroid}'; A = cell2mat(A);
    B = {S1.Area}'; B = cell2mat(B);
    %Sort the centroids based on y coordinates.
    [SortA,Index] = sort(A(:,2));
    A = A(Index,:);B = B(Index);
    vofn(i) = vofn(i) + (sum((B./pi).^(1.5)*4/3*pi)./n_frames)./V_total;
    
    
        for k = 1:length(B)
            %check +-2 pixels
            yupper = min(A(k,2)+2,xmax-xmin+1);
            ylower = max(0,A(k,2)-2);
            Index = SortA1>ylower & SortA1<yupper;
            % Assume a std for centroids of 0.5, a combined deviation
            Range = vecnorm(A1(Index,:)-A(k,:),2,2)./0.5 + abs(B1(Index)-B(k))./B1(Index);
            if min(Range)<5
                bw_fill_img = bw_fill_img - bwselect(bw_fill_img,A(k,1),A(k,2),8);
            end
        end

    A1 = A;
    B1 = B;
    SortA1 = SortA;
    vof_img = vof_img + double(bw_fill_img)*255/n_frames;
    
end


vof_img = uint8(vof_img);
%final process the vof
%imshow(vof_img);
imwrite(vof_img,'reversed-vof3.jpg')
reversed_vof = abs(double(vof_img)-255);
reversed_vof = uint8(reversed_vof);

imwrite(reversed_vof,'vof3.jpg')
%imshow(reversed_vof)

end

%With edited bubble
vofn = zeros(size(vfile));

vof_process = zeros(length(vfile),n_frames);
%vofn = zeros(size(vfile));

%vof_process = zeros(length(vfile),n_frames);

for i = 1:4


cd(vfilefolder{i});
mkdir(vfilefolder{i},'images_vofp');
mkdir(vfilefolder{i},'images_bgrm');
mkdir(vfilefolder{i},'images_filled');

imageNames = dir(fullfile(vfilefolder{i},'images','*.jpg'));


clear vof_img
vof_img = zeros([xmax-xmin+1,ymax-ymin+1]);
vof_img_temp = vof_img;
vof_img1 = vof_img;
n_frames = length(imageNames);




%%enhance refer image
% reversed_ref = abs(double(refer_img)-255);
% index_enhance = reversed_ref>0;
% reversed_ref(index_enhance) = reversed_ref(index_enhance) + 5;%maybe this 20 is crutial
% index_reduce = reversed_ref>255;
% reversed_ref(index_reduce) = 255;

%Deal with the first frame
imageNames = {imageNames.name};
ii=1;
 img = imread(fullfile(vfilefolder{i},'images',imageNames{ii}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;
    



reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
%     clean_img = abs(reversed_clean-255);
%     clean_img = uint8(clean_img);
%     clean_img = imadjust(clean_img);
%     fullname = fullfile(vfilefolder{i},'images_bgrm',imageNames{ii});
%     imwrite(clean_img,fullname);
%     
%     filted_img = imgaussfilt(clean_img,1);
%     enhanced_fimg = adapthisteq(filted_img);
%     bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
%     bw_fill_img = imfill(~bw_img,'holes');
%     fullname = fullfile(vfilefolder{i},'images_filled',imageNames{ii});
%     imwrite(bw_fill_img,fullname);
    
    
clean_img = abs(reversed_clean-255);
clean_img = uint8(clean_img);
clean_img = imadjust(clean_img);
fullname = fullfile(vfilefolder{i},'images_bgrm',imageNames{ii});
imwrite(clean_img,fullname);
reversed_img = abs(double(clean_img)-255);
indexrm = reversed_img<=2;
reversed_img(indexrm) = 0;
reversed_img = imfill(reversed_img);
reversed_img(1:618,:) = reversed_img(1:618,:)-30;
indexpo = reversed_img<0;
reversed_img(indexpo) = 0;
Kmedian = medfilt2(reversed_img(619:end,:));
reversed_img(619:end,:) = Kmedian;
filted_img = uint8(abs(double(reversed_img)-255));
enhanced_fimg = adapthisteq(filted_img,'NumTiles',[30,15],'ClipLimit',0.9);
bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
bw_fill_img = imfill(~bw_img,'holes');
fullname = fullfile(vfilefolder{i},'images_filled',imageNames{ii});
imwrite(bw_fill_img,fullname);
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
    S = regionprops(CC,'Centroid');
    S1 = regionprops(CC,'Area');
    A = {S.Centroid}'; A = cell2mat(A);
    B = {S1.Area}'; B = cell2mat(B);
    
    
    %Sort the centroids based on y coordinates.
    [SortA,Index] = sort(A(:,2));
    A = A(Index,:);B = B(Index);
    [Height,Diameter] = size(refer_img);
    
    R = sqrt(B./pi);
    
    V_total = pi*Diameter.^2.*Height/4;
    Radius = Diameter/2;
    
    for k = 1:length(B)
        vof_img1 = vof_img1 + double(bwselect(bw_fill_img,A(k,1),A(k,2),8)).*R(k)*255./max(10,sqrt(Radius.^2-(Radius-A(k,1)).^2))./n_frames;
    end
    
    vofn(i) = vofn(i) + (sum((B./pi).^(1.5)*4/3*pi)./n_frames)./V_total;
    vof_process(i,ii) = vofn(i)./ii*n_frames;
    
    A1 = A;
    B1 = B;
    SortA1 = SortA;
    vof_img = vof_img + double(bw_fill_img)*255/n_frames;
    %evolving vof
    vof_img_temp = vof_img1./(max(max(vof_img1)))*255;
    filename = [sprintf('%04d',ii) '.jpg'];
    fullname = fullfile(vfilefolder{i},'images_vofp',filename);
    imwrite(uint8(vof_img_temp),fullname);
    %filename = [sprintf('%03d',ii) '.jpg'];
    %fullname = fullfile(vfilefolder{i},'images_process',filename);
    %imwrite(bw_fill_img,fullname)
    
    
for ii = 2:n_frames

    
    img = imread(fullfile(vfilefolder{i},'images',imageNames{ii}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;
    



reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
clean_img = abs(reversed_clean-255);
clean_img = uint8(clean_img);
clean_img = imadjust(clean_img);
fullname = fullfile(vfilefolder{i},'images_bgrm',imageNames{ii});
imwrite(clean_img,fullname);
reversed_img = abs(double(clean_img)-255);
indexrm = reversed_img<=2;
reversed_img(indexrm) = 0;
reversed_img = imfill(reversed_img);
reversed_img(1:618,:) = reversed_img(1:618,:)-30;
indexpo = reversed_img<0;
reversed_img(indexpo) = 0;
Kmedian = medfilt2(reversed_img(619:end,:));
reversed_img(619:end,:) = Kmedian;
filted_img = uint8(abs(double(reversed_img)-255));
enhanced_fimg = adapthisteq(filted_img,'NumTiles',[30,15],'ClipLimit',0.9);
bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
bw_fill_img = imfill(~bw_img,'holes');
fullname = fullfile(vfilefolder{i},'images_filled',imageNames{ii});
imwrite(bw_fill_img,fullname);
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
    S = regionprops(CC,'Centroid');
    S1 = regionprops(CC,'Area');
    A = {S.Centroid}'; A = cell2mat(A);
    B = {S1.Area}'; B = cell2mat(B);
    %Sort the centroids based on y coordinates.
    [SortA,Index] = sort(A(:,2));
    A = A(Index,:);B = B(Index);
    R = sqrt(B./pi);
    vofn(i) = vofn(i) + (sum((B./pi).^(1.5)*4/3*pi)./n_frames)./V_total;
    
    
        for k = 1:length(B)
            %check +-2 pixels
            yupper = min(A(k,2)+2,xmax-xmin+1);
            ylower = max(0,A(k,2)-2);
            Index = SortA1>ylower & SortA1<yupper;
            % Assume a std for centroids of 0.5, a combined deviation
            Range = vecnorm(A1(Index,:)-A(k,:),2,2)./0.5 + abs(B1(Index)-B(k))./B1(Index);
            if min(Range)<5
                bw_fill_img = bw_fill_img - bwselect(bw_fill_img,A(k,1),A(k,2),8);
            else
                vof_img1 = vof_img1 + double(bwselect(bw_fill_img,A(k,1),A(k,2),8)).*R(k)*255./max(10,sqrt(Radius.^2-(Radius-A(k,1)).^2))./n_frames;
            end
        end
    
    
    %filename = [sprintf('%03d',ii) '.jpg'];
    %fullname = fullfile(vfilefolder{i},'images_process',filename);
    %imwrite(bw_fill_img,fullname)
    
    A1 = A;
    B1 = B;
    SortA1 = SortA;
    vof_img = vof_img + double(bw_fill_img)*255/n_frames;
    vof_process(i,ii) = vofn(i)./ii*n_frames;
    
    vof_img_temp = vof_img1*255./(max(max(vof_img1)));
    filename = [sprintf('%04d',ii) '.jpg'];
    fullname = fullfile(vfilefolder{i},'images_vofp',filename);
    imwrite(uint8(vof_img_temp),fullname);
    
end
save vofdouble vof_img1

vof_img = uint8(vof_img);

disp([i,max(max(vof_img1))]);

vof_img1 = vof_img1./(max(max(vof_img1)))*255;

vof_img1 = uint8(vof_img1);
%final process the vof
%imshow(vof_img);
imwrite(vof_img,'reversed-vof4.jpg')
imwrite(vof_img1,'vof_projection.jpg')
reversed_vof = abs(double(vof_img)-255);
reversed_vof = uint8(reversed_vof);

imwrite(reversed_vof,'vof4.jpg')
%imshow(reversed_vof)

end

%get bubble diameter



rDist = [];

i=6;

cd(vfilefolder{i});

imageNames = dir(fullfile(vfilefolder{i},'images','*.jpg'));
imageDate = {imageNames.datenum};
imageDate = cell2mat(imageDate);
imageNames = {imageNames.name}';
[X,Y] = sort(imageDate);
imageNames = imageNames(Y)';
n_frames = length(imageNames);



%enhance refer image
reversed_ref = abs(double(refer_img)-255);
index_enhance = reversed_ref>0;
reversed_ref(index_enhance) = reversed_ref(index_enhance) + 5;%maybe this 20 is crutial
index_reduce = reversed_ref>255;
reversed_ref(index_reduce) = 255;

%Deal with the first frame

ii=1;
 img = imread(fullfile(vfilefolder{i},'images',imageNames{ii*10-9}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;
    



reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
    clean_img = abs(reversed_clean-255);
    clean_img = uint8(clean_img);
    clean_img = imadjust(clean_img);
    
    filted_img = imgaussfilt(clean_img,1);
    enhanced_fimg = adapthisteq(filted_img);
    bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
    bw_fill_img = imfill(~bw_img,'holes');
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
   
    S1 = regionprops(CC,'Area');
    B = {S1.Area}'; B = cell2mat(B);
    R = sqrt(B./pi);
    rDist = [rDist;R];
for ii = 2:(n_frames/10)

    
    img = imread(fullfile(vfilefolder{i},'images',imageNames{ii*10-9}));
    img = rgb2gray(img);
    img = img(xmin:xmax,ymin:ymax);
    reversed_img = abs(double(img)-255);  
    reversed_clean = reversed_img-reversed_ref;
    tempindex = reversed_clean<0;
    reversed_clean(tempindex) = 0;

reversed_clean = reversed_img-reversed_ref;
tempindex = reversed_clean<0;
reversed_clean(tempindex) = 0;
    
    clean_img = abs(reversed_clean-255);
    clean_img = uint8(clean_img);
    clean_img = imadjust(clean_img);
    
    filted_img = imgaussfilt(clean_img,1);
    enhanced_fimg = adapthisteq(filted_img);
    bw_img = imbinarize(enhanced_fimg,'adaptive','ForegroundPolarity','dark');
    bw_fill_img = imfill(~bw_img,'holes');
    
    %Remove the objects that does not move. Include background and stationary bubble.
    CC = bwconncomp(bw_fill_img,8);
    S1 = regionprops(CC,'Area'); 
    B = {S1.Area}'; B = cell2mat(B);
    R = sqrt(B./pi);
    rDist = [rDist;R];
  
end

%Calculation According to the image, translate to metric
dDist = rDist*2.5*25.4./333*2;
d_meanA = sum(dDist.*dDist.^2)./sum(dDist.^2);
d_meanV = sum(dDist.*dDist.^3)./sum(dDist.^3);
% Take away the small bubble.
dDist(dDist<1.3) = [];
d_meanA_filted = sum(dDist.*dDist.^2)./sum(dDist.^2);
d_meanV_filted = sum(dDist.*dDist.^3)./sum(dDist.^3);
%Normalization
dN = 4*sqrt(0.0728/9.8/998.2)*1000;
histogram(dDist./dN,30);

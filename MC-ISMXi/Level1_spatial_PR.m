addpath('.\func\')
% original filepath
filepath_ALN = [filepath, '\pinhole_ALN'];
fileinfo_ALN = dir(filepath_ALN);
filename = [filepath_ALN,'\',fileinfo_ALN(3).name];
imginfo = imfinfo(filename);
Width = imginfo.Width * upfactor;
Height = imginfo.Height * upfactor;
count = length(fileinfo_ALN)-2;

% predefine empty matrix
MaxLength = max(Height, Width);
peakloc = cell(count,1);
Img = zeros(MaxLength, MaxLength, count);

%% 1. The original image is read and the center point is fixed spatially
tic,
% define preprocessing kernel
sigma = 3;
h3 = fspecial('gaussian', MaxLength, sigma); % Adjustable parameters
H3 = fft2(h3);
isGPU = 0;
for imgIndex = 3:count+2
    filename = [filepath_ALN,'\',fileinfo_ALN(imgIndex).name];
    temp = double(imread(filename));
    if isGPU
        temp = gpuArray(temp);
    end
    if upfactor == 2
        temp = imresize(temp, 2, 'bilinear');
    elseif upfactor == 4
        temp = imresize(temp, 2, 'bilinear');
        temp = imresize(temp, 2, 'bilinear');
    elseif upfactor == 8
        temp = imresize(temp, 2, 'bilinear');
        temp = imresize(temp, 2, 'bilinear'); 
        temp = imresize(temp, 2, 'bilinear'); 
    end
% padding raw images so that they have the same width and height 
    if Width > Height
        temp = padarray(temp, [(Width-Height)/2,0], 'both');
        MinH = (Width-Height)/2;
        MaxH = Width - (Width - Height)/2;
        MinW = 0;
        MaxW = Width;
    elseif Width < Height
        temp = padarray(temp, [0,(Height-Width)/2], 'both');
        MinH = 0;
        MaxH = Height;
        MinW = (Height - Width)/2;
        MaxW = Height - (Height - Width)/2;
    else
        MinH = 0;
        MaxH = Height;
        MinW = 0;
        MaxW = Width;
    end

    Img(:,:,imgIndex-2) = temp;
    % Image preprocessing without changing the original data
    temp2 = temp;

    temp = medfilt2(temp);
    temp = ifftshift(ifft2(fft2(temp).*H3));
    logipoint = ((temp(1:end-2, 1:end-2) < temp(2:end-1, 2:end-1)) & ...
        (temp(1:end-2, 2:end-1) < temp(2:end-1, 2:end-1)) & ...
        (temp(1:end-2, 3:end) < temp(2:end-1, 2:end-1)) & ...
        (temp(2:end-1, 1:end-2) < temp(2:end-1, 2:end-1)) & ...
        (temp(2:end-1, 3:end) < temp(2:end-1, 2:end-1)) & ...
        (temp(3:end, 1:end-2) < temp(2:end-1, 2:end-1)) & ...
        (temp(3:end, 2:end-1) < temp(2:end-1, 2:end-1)) & ...
        (temp(3:end, 3:end) < temp(2:end-1, 2:end-1)));
    logipoint2 = logipoint & (temp2(2:end-1,2:end-1)>bg);
    [xx,yy] = find(logipoint2==1);
    x = xx; y = yy;
    x(((xx<MinH+ws2/2+1) | (xx>MaxH-ws2/2-1)) & ((yy<MinW+ws2/2+1) | (yy>MaxW-ws2/2-1))) = [];
    y(((xx<MinH+ws2/2+1) | (xx>MaxH-ws2/2-1)) & ((yy<MinW+ws2/2+1) | (yy>MaxW-ws2/2-1))) = [];
    if isGPU
        peakloc{imgIndex-2} = gather([x+1,y+1]);
    else
        peakloc{imgIndex-2} = [x+1,y+1];
    end
%     figure; imshow(temp,[]);
%     hold on;
%     plot(peakloc{imgIndex-2}(:,2),peakloc{imgIndex-2}(:,1),'o');
end
toc
% Calculate the OLID image
if isLiWF
    LiWF_image = sum(Img,3)/size(Img,3);
end

%% 2. read subimage
tic,
Img3 = cell(count,1);
maxS = 0;
minS = 0;
for imgIndex = 1:count
    loc = peakloc{imgIndex};
    wn = size(loc,1);
    temp = Img(:,:,imgIndex);
    substack = zeros(ws2, ws2, wn);

    for ii = 1:wn 
        target = loc(ii,:);
        locx = round(target(1)-(ws2-1)/2);
        locy = round(target(2)-(ws2-1)/2);
        if (locx>MinH) & (locx<MaxH-ws2) & (locy>MinW) & (locy<MaxW-ws2)
            temp2 = temp(locx:locx+ws2-1, locy:locy+ws2-1);
            substack(:,:,ii) = temp2;
        end
%         sumS = sum(sum(substack, 1),2);
%         tmp = max(sumS, [], 3);
%         maxS = max(maxS, tmp);
%         tmp = min(sumS, [], 3);
%         minS = min(minS, tmp);
    end
    Img3{imgIndex} = substack;
end
clear subimage
toc
%% 3. ISM and Confocal
tic,
ISM_image = zeros(2 * MaxLength - 1); 
confocal_image = zeros(MaxLength); 

% % Calculate ISM coordinates
sigma1 = 2;
h2 = fspecial('gaussian', ws2, sigma1);
H2 = fft2(h2);
sigma2 = hole*pinholefactor;


parfor imgIndex = 1:count
    tempISM = zeros(2*MaxLength - 1); 
    tempconfocal = zeros(MaxLength);
    substack = Img3{imgIndex};
    loc = peakloc{imgIndex};
    wn = size(loc,1);
    for ii = 1:wn
        temp = substack(:,:,ii);
        center = loc(ii,:);
        if sum(temp(:)) >0 && (center(1)<MaxH-ws2-1) && (center(1)>MinH+ws2)... 
            && (center(2)<MaxW-ws2-1) && (center(2)>MinW+ws2) 
%             temp = ifftshift(ifft2(fft2(temp).*H2)); 
            if isEdge
                temp2 = temp;
                temp2(temp2<Edgefactor*max(temp2(:))) = 0;
            else
                temp2 = temp;
            end
            if ispinhole
                temp2_subregion = zeros(size(temp));
                temp2_subregion((ws2+1)/2-2:(ws2+1)/2+2,(ws2+1)/2-2:(ws2+1)/2+2) = ...
                    temp2((ws2+1)/2-2:(ws2+1)/2+2,(ws2+1)/2-2:(ws2+1)/2+2);
                new_center = SubstackCenter(temp2_subregion, center);
                delta = new_center - round(center);
                h = my2Dgaussian(delta, ws2, sigma2);
                h = h./max(h(:));
                apertured_image = temp2.*h;
            else
                apertured_image = temp2;
            end

            if isconfocal
                locx = round(center(1)-(ws2-1)/2);
                locy = round(center(2)-(ws2-1)/2);
                tempconfocal(locx:locx+ws2-1, locy:locy+ws2-1) = ...
                    tempconfocal(locx:locx+ws2-1, locy:locy+ws2-1)+apertured_image;
            end

            if isISM
                center_ISM = 2 * center - 1;
                locx = round(center_ISM(1)-(ws2-1)/2);
                locy = round(center_ISM(2)-(ws2-1)/2);
                tempISM (locx:locx+ws2-1, locy:locy+ws2-1) = apertured_image ...
                    + tempISM (locx:locx+ws2-1, locy:locy+ws2-1);
            end
        end
    end
    
    if isconfocal
        confocal_image = confocal_image + tempconfocal;
    end
    if isISM
        ISM_image = ISM_image + tempISM;
    end
end
if isDeconv
    I_deconv = deconvlucy(ISM_image, PSF_con, 5);
end
toc
%% 5. save results

if ispinhole
    temp_filename = strcat(filepath,'\S2_recon_ws',num2str(ws2),'_up',...
        num2str(upfactor),'_bg',num2str(bg),'_pinhole',num2str(pinholefactor));
else
    temp_filename = strcat(filepath,'\S2_recon_ws',num2str(ws2),'_up',...
        num2str(upfactor),'_bg',num2str(bg));
end
if isEdge
    temp_filename = strcat(temp_filename, '_Edge', num2str(Edgefactor));
end
filename_LiWF = strcat(temp_filename,'_LiWF.tif');
filename_confocal = strcat(temp_filename,'_confocal.tif');
filename_ISM = strcat(temp_filename,'_PR.tif');
filename_ISM_deconv = strcat(temp_filename,'_PRdeconv.tif');

if isLiWF
imwrite(uint16(2^16*LiWF_image./max(LiWF_image(:))),filename_LiWF);
end
if isconfocal
    imwrite(uint16(2^16*confocal_image./max(confocal_image(:))),filename_confocal);
end
if isISM
    imwrite(uint16(2^16*ISM_image./max(ISM_image(:))),filename_ISM);
end
if isDeconv
    imwrite(uint16(2^16*I_deconv./max(I_deconv(:))),filename_ISM_deconv);
end
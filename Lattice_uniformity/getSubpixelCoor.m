function [peakloc_subpixel, img] = getSubpixelCoor(filename, ws, upfactor, bg)
% get Subpixel level Coordination by spatial method

if upfactor==1
    ws2 = ws;
else
    ws2 = ws*upfactor+1;
end

%% 1. get all point's coordination (8 neighbourhood)
img = double(imread(filename));
Height = size(img, 1) * upfactor;
Width = size(img, 2) * upfactor;
sigma = 3;
h3 = fspecial('gaussian', Height, sigma); 
H3 = fft2(h3);
temp = img;
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
temp = ifftshift(ifft2(fft2(temp).*H3));
logipoint = ((temp(1:end-2, 1:end-2) < temp(2:end-1, 2:end-1)) & ...
    (temp(1:end-2, 2:end-1) < temp(2:end-1, 2:end-1)) & ...
    (temp(1:end-2, 3:end) < temp(2:end-1, 2:end-1)) & ...
    (temp(2:end-1, 1:end-2) < temp(2:end-1, 2:end-1)) & ...
    (temp(2:end-1, 3:end) < temp(2:end-1, 2:end-1)) & ...
    (temp(3:end, 1:end-2) < temp(2:end-1, 2:end-1)) & ...
    (temp(3:end, 2:end-1) < temp(2:end-1, 2:end-1)) & ...
    (temp(3:end, 3:end) < temp(2:end-1, 2:end-1)));
logipoint2 = logipoint & (temp(2:end-1,2:end-1)>bg);
[xx,yy] = find(logipoint2==1);
x = xx; y = yy;
x(((xx<ws2/2+1) | (xx>Height-ws2/2-1)) & ((yy<ws2/2+1) | (yy>Width-ws2/2-1))) = [];
y(((xx<ws2/2+1) | (xx>Height-ws2/2-1)) & ((yy<ws2/2+1) | (yy>Width-ws2/2-1))) = [];
peakloc = [x+1,y+1];


%% 2. exact subimages based on peakloc
wn = size(peakloc,1);
substack = zeros(ws2, ws2, wn);
for ii = 1:wn 
    target = peakloc(ii,:);
    locx = round(target(1)-(ws2-1)/2);
    locy = round(target(2)-(ws2-1)/2);
    if (locx>0) && (locx<Height-ws2) && (locy>0) && (locy<Width-ws2)
            temp2 = temp(locx:locx+ws2-1, locy:locy+ws2-1);
    substack(:,:,ii) = temp2;
    end
end


%% 3. get subpixel coordinations
sigma1 = 1.5;
h2 = fspecial('gaussian', ws2, sigma1); 
H2 = fft2(h2);
idx = 1;
% peakloc_subpixel = cell(wn, 1);
for ii = 1:wn
    temp = substack(:,:,ii);
    center = peakloc(ii,:);
    if sum(temp(:)) >1 && (center(1)<Height-ws2-1) && (center(1)>ws2) && (center(2)<Width-ws2-1) && (center(2)>ws2)
        temp(temp < 0.3 * max(temp(:))) = 0;
        temp = ifftshift(ifft2(fft2(temp).*H2));
        new_center = SubstackCenter(temp, center);
        peakloc_subpixel(idx, :) = new_center;
        idx = idx + 1;
    end
end

end
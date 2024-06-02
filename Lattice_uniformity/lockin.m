function lockin(filepath, mode)
%% parameter estimation of MSIM
fileinfo = dir(filepath);
mkdir(strcat(filepath, '..\pinhole_ALN'))

n = length(fileinfo) - 2;
for idx = 3:length(fileinfo)
    temp = double(imread(strcat(filepath, fileinfo(idx).name)));
    if idx == 3
        [height, width] = size(temp);
        rawimg = zeros(height, width, n);
    end

    rawimg(:,:,idx-2) = temp;

end
if mode == "DeDC"
    fft_img = fft(rawimg,[],3);
    fft_img(:,:,1) = 0;
    img_pre = ifft(fft_img,[],3);
    for ImgCount = 1:n
        temp = img_pre(:,:,ImgCount);
        temp(temp<0) = 0;
        temp = abs(temp);
        imwrite(uint16(temp), strcat(filepath,'..\pinhole_ALN\', num2str(ImgCount, '%03d'), '.tif'));
    end
end

if mode == "min"
    minRawimg = min(rawimg, [], 3);
    rawimg = rawimg - repmat(minRawimg, 1, 1, n);
    for ImgCount = 1:n
        temp = rawimg(:,:,ImgCount);
        imwrite(uint16(temp), strcat(filepath,'..\pinhole_ALN\', num2str(ImgCount, '%03d'), '.tif'));
    end
end

end


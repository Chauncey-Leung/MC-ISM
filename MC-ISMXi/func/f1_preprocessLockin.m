%% parameter estimation of MSIM
function f1_preprocessLockin(filepath)
    %% 1. read image
    filepathread = [filepath, '\pinhole_ALN_raw\'];
    filepathsave = [filepath, '\pinhole_ALN\'];
    fileinfo = dir(filepathread);
    mkdir(filepathsave)

    n = length(fileinfo) - 2;
    for idx = 3:length(fileinfo)
        temp = double(imread(strcat(filepathread, fileinfo(idx).name)));
        if idx == 3
            [height, width] = size(temp);
            rawimg = zeros(height, width, n);
        end
        rawimg(:,:,idx-2) = temp;
    end
    
% % Apo is the employed gaussian window employ to suppress high-frequency 
% % components for denoise. However, the effect is not obvious, 
% % often as long as the suppression of zero frequency to achieve the 
% % effect of de-focusing.
%     sigma = 3 * sqrt(n);
%     sigma = 3 * sqrt(n);
%     mu = round(n/2);
%     x = 1 : n;
%     apo = fftshift(1/(sqrt(2*pi)*sigma)*exp(-(x-mu).^2/(2*sigma^2)));
%     apo = reshape(apo/max(apo(:)),[1,1,n]);

% 1 and 2 are different levels of suppression of zero-frequency component
% 1. deDC
    fft_img = fft(rawimg,[],3);
    fft_img2 = fft_img(:,:,2:end);
    fft_img0 = sum(fft_img2,3);
    fft_img(:,:,1) = zeros(height, width);
%     fft_img = fft_img .* repmat(apo,size(rawimg,1),size(rawimg,2));
    img_pre = ifft(fft_img,[],3);
    for ImgCount = 1:n
        temp = img_pre(:,:,ImgCount);
        temp(temp<0) = 0;
        temp = abs(temp);
        imwrite(uint16(temp), strcat(filepathsave, num2str(ImgCount, '%03d'), '.tif'));
    end

% %     % 2 deDC: -min
    minRawimg = min(rawimg, [], 3);
    rawimg = rawimg - repmat(minRawimg, 1, 1, n);
%     fft_img = fft(rawimg,[],3);
%     fft_img = fft_img .* repmat(apo,size(rawimg,1),size(rawimg,2));
%     img_pre = ifft(fft_img,[],3);
    for ImgCount = 1:n
%         temp = img_pre(:,:,ImgCount);
%         temp(temp<0) = 0;
%         temp = abs(temp);
        temp = rawimg(:,:,ImgCount);
        imwrite(uint16(temp), strcat(filepathsave, num2str(ImgCount, '%03d'), '.tif'));
    end

end
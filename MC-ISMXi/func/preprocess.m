function img_pre2 = preprocess(img_raw, disksize)

h = fspecial('gaussian',21, 4);
h = h./sum(h(:));
img_raw = conv2(img_raw, h, 'same');

% 1. ButterWorth high-pass filter
D0fac = 0.1;
n = 2; % 2 order
% The high-pass filter ranges from 0 to 1. To prevent all background zeroes, set the coefficient
filterfac = 0.8;  
img_pre = imButterWorth(img_raw, D0fac, filterfac, n);

% 2. open operator
th = graythresh(img_pre/max(img_pre(:)));
mask = imbinarize(img_pre/max(img_pre(:)), 0.5*th);
se = strel('disk',disksize);
mask2 = imopen(mask, se);
mask2 = imdilate(mask2, se);
img_pre2 = mask2 .* img_pre;

% i1 = imbinarize(img_pre/max(img_pre(:)));
% img_pre2 = bwmorph(i1, 'open');


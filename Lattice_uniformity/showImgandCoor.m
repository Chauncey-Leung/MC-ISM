function  showImgandCoor(imgIndex, img_upfactor, peakloc_subpixel)
%此函数的作用就是展示第imgIndex张图片以及叠加了定位后的坐标的结果
    figure;
    imshow(img_upfactor{imgIndex}, []);
    hold on;
    plot(peakloc_subpixel{imgIndex}(:,2), peakloc_subpixel{imgIndex}(:,1), 'o');
end
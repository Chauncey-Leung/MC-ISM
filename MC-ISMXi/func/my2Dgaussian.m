function h = my2Dgaussian(delta, ws2, sigma)
[xx,yy] = meshgrid(-(ws2-1)/2:(ws2-1)/2, -(ws2-1)/2:(ws2-1)/2);
h = 1./(2*pi*sigma^2)*exp(-((yy-delta(1)).^2+(xx-delta(2)).^2)/2/sigma^2);

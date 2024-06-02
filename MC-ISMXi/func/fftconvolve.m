function tmp1 = fftconvolve(g, psf, mode)
    MM = size(g, 1) + size(psf,1) - 1;
    NN = size(g, 2) + size(psf, 2) - 1;
    G = fft2(g, MM,NN);
    PSF = fft2(psf, MM, NN);
    tmp1 = ifft2(G.*PSF);
    if mode == 'full'
    elseif mode == 'same'
        startpoint1 = ceil(size(psf,1)/2);
        startpoint2 = ceil(size(psf,2)/2);
        tmp2 = tmp1(startpoint1 : startpoint1 + size(g,1) - 1,...
                    startpoint2 : startpoint2 + size(g,2) - 1);
        tmp1 = tmp2;
    end
end